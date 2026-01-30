#!/usr/bin/env python3
"""
Import historical deployments from a CSV file and report them to Faros via the events-cli.

CSV Format (columns):
  Required:
    - deploy_id: Unique deployment identifier
    - deploy_app: Application name
    - deploy_env: Environment (Prod, Staging, QA, Dev, Sandbox, Canary, Custom)
    - deploy_status: Status (Success, Failed, Canceled, Queued, Running, RolledBack, Custom)

  Required (at least one):
    - artifact: Artifact URI (format: source://org/repo/artifact_id)
    - commit: Commit URI (format: source://org/repo/sha)

  Optional:
    - deploy_source: Source system for deployments (default: CSV_Import)
    - deploy_url: URL to the deployment
    - deploy_start_time: Start time (ISO-8601 or Unix ms)
    - deploy_end_time: End time (ISO-8601 or Unix ms)
    - deploy_requested_at: Request time (ISO-8601 or Unix ms)
    - deploy_status_details: Additional status details
    - deploy_env_details: Environment details
    - deploy_app_platform: Platform (Kubernetes, ECS, Lambda, etc.)
    - deploy_app_tags: Application tags (format: key:value,key:value)
    - deploy_tags: Deployment tags (format: key:value,key:value)

Example CSV:
  deploy_id,deploy_app,deploy_env,deploy_status,artifact,deploy_start_time,deploy_end_time
  dep-001,my-service,Prod,Success,Docker://myorg/myrepo/v1.0.0,2024-01-15T10:00:00Z,2024-01-15T10:05:00Z
  dep-002,my-service,Staging,Failed,Docker://myorg/myrepo/v1.0.1,2024-01-16T14:00:00Z,2024-01-16T14:02:00Z

Usage:
  python import_historical_deployments.py deployments.csv --api_key YOUR_API_KEY
  python import_historical_deployments.py deployments.csv --api_key YOUR_API_KEY --dry_run
  python import_historical_deployments.py deployments.csv --community_edition
"""

import argparse
import csv
import os
import subprocess
import sys
from pathlib import Path


# Default values
DEFAULT_DEPLOY_SOURCE = "CSV_Import"
SCRIPT_DIR = Path(__file__).parent.parent
FAROS_EVENT_SCRIPT = SCRIPT_DIR / "faros_event.sh"

# CSV column to CLI argument mapping
COLUMN_TO_ARG = {
    "deploy_id": "--deploy_id",
    "deploy_app": "--deploy_app",
    "deploy_env": "--deploy_env",
    "deploy_source": "--deploy_source",
    "deploy_status": "--deploy_status",
    "deploy_url": "--deploy_url",
    "deploy_start_time": "--deploy_start_time",
    "deploy_end_time": "--deploy_end_time",
    "deploy_requested_at": "--deploy_requested_at",
    "deploy_status_details": "--deploy_status_details",
    "deploy_env_details": "--deploy_env_details",
    "deploy_app_platform": "--deploy_app_platform",
    "deploy_app_tags": "--deploy_app_tags",
    "deploy_tags": "--deploy_tags",
    "artifact": "--artifact",
    "commit": "--commit",
    # Artifact individual fields (alternative to URI)
    "artifact_id": "--artifact_id",
    "artifact_repo": "--artifact_repo",
    "artifact_org": "--artifact_org",
    "artifact_source": "--artifact_source",
    # Commit individual fields (alternative to URI)
    "commit_sha": "--commit_sha",
    "commit_repo": "--commit_repo",
    "commit_org": "--commit_org",
    "commit_source": "--commit_source",
}


def validate_row(row: dict, row_num: int) -> list[str]:
    """Validate a CSV row and return list of errors."""
    errors = []

    # Check required fields
    required = ["deploy_id", "deploy_app", "deploy_env", "deploy_status"]
    for field in required:
        if not row.get(field):
            errors.append(f"Row {row_num}: Missing required field '{field}'")

    # Check that at least artifact or commit is provided
    has_artifact = row.get("artifact") or (
        row.get("artifact_id") and row.get("artifact_repo") and
        row.get("artifact_org") and row.get("artifact_source")
    )
    has_commit = row.get("commit") or (
        row.get("commit_sha") and row.get("commit_repo") and
        row.get("commit_org") and row.get("commit_source")
    )

    if not has_artifact and not has_commit:
        errors.append(
            f"Row {row_num}: Must provide either 'artifact' or 'commit' "
            "(as URI or individual fields)"
        )

    # Validate deploy_status
    valid_statuses = ["Success", "Failed", "Canceled", "Queued", "Running", "RolledBack", "Custom"]
    if row.get("deploy_status") and row["deploy_status"] not in valid_statuses:
        errors.append(
            f"Row {row_num}: Invalid deploy_status '{row['deploy_status']}'. "
            f"Must be one of: {', '.join(valid_statuses)}"
        )

    # Validate deploy_env
    valid_envs = ["Prod", "Staging", "QA", "Dev", "Sandbox", "Canary", "Custom"]
    if row.get("deploy_env") and row["deploy_env"] not in valid_envs:
        errors.append(
            f"Row {row_num}: Invalid deploy_env '{row['deploy_env']}'. "
            f"Must be one of: {', '.join(valid_envs)}"
        )

    return errors


def build_command(row: dict, args: argparse.Namespace) -> list[str]:
    """Build the faros_event.sh command for a deployment row."""
    cmd = [str(FAROS_EVENT_SCRIPT), "CD"]

    # Add API key or community edition flag
    if args.community_edition:
        cmd.append("--community_edition")
    else:
        cmd.extend(["--api_key", args.api_key])

    # Add URL if provided
    if args.url:
        cmd.extend(["--url", args.url])

    # Add graph if provided
    if args.graph:
        cmd.extend(["--graph", args.graph])

    # Add dry_run flag if set
    if args.dry_run:
        cmd.append("--dry_run")

    # Add validate_only flag if set
    if args.validate_only:
        cmd.append("--validate_only")

    # Set default deploy_source if not in row
    if not row.get("deploy_source"):
        row["deploy_source"] = DEFAULT_DEPLOY_SOURCE

    # Add all CSV columns as arguments
    for column, arg in COLUMN_TO_ARG.items():
        value = row.get(column, "").strip()
        if value:
            cmd.extend([arg, value])

    return cmd


def process_csv(csv_path: str, args: argparse.Namespace) -> tuple[int, int]:
    """
    Process the CSV file and send deployment events.
    Returns tuple of (success_count, failure_count).
    """
    success_count = 0
    failure_count = 0

    with open(csv_path, "r", newline="", encoding="utf-8") as f:
        reader = csv.DictReader(f)

        # Validate header
        if reader.fieldnames is None:
            print("Error: CSV file is empty or has no header row", file=sys.stderr)
            return 0, 1

        print(f"CSV columns found: {', '.join(reader.fieldnames)}")
        print("-" * 60)

        for row_num, row in enumerate(reader, start=2):  # Start at 2 (1 is header)
            # Validate row
            errors = validate_row(row, row_num)
            if errors:
                for error in errors:
                    print(f"Validation error: {error}", file=sys.stderr)
                failure_count += 1
                continue

            # Build and execute command
            cmd = build_command(row, args)

            deploy_id = row.get("deploy_id", "unknown")
            deploy_app = row.get("deploy_app", "unknown")
            deploy_env = row.get("deploy_env", "unknown")

            print(f"Processing: {deploy_app}/{deploy_env}/{deploy_id}")

            if args.verbose:
                print(f"  Command: {' '.join(cmd)}")

            try:
                result = subprocess.run(
                    cmd,
                    capture_output=True,
                    text=True,
                    timeout=30
                )

                if result.returncode == 0:
                    success_count += 1
                    print(f"  ✓ Success")
                    if args.verbose and result.stdout:
                        print(f"  Output: {result.stdout.strip()}")
                else:
                    failure_count += 1
                    print(f"  ✗ Failed (exit code {result.returncode})", file=sys.stderr)
                    if result.stderr:
                        print(f"  Error: {result.stderr.strip()}", file=sys.stderr)
                    if result.stdout:
                        print(f"  Output: {result.stdout.strip()}", file=sys.stderr)

            except subprocess.TimeoutExpired:
                failure_count += 1
                print(f"  ✗ Timeout after 30 seconds", file=sys.stderr)
            except Exception as e:
                failure_count += 1
                print(f"  ✗ Error: {e}", file=sys.stderr)

    return success_count, failure_count


def main():
    parser = argparse.ArgumentParser(
        description="Import historical deployments from CSV and report to Faros",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog=__doc__
    )

    parser.add_argument(
        "csv_file",
        help="Path to CSV file containing deployment data"
    )

    parser.add_argument(
        "-k", "--api_key",
        help="Faros API key (required unless using --community_edition)"
    )

    parser.add_argument(
        "-u", "--url",
        help="Faros API URL (default: https://prod.api.faros.ai)"
    )

    parser.add_argument(
        "-g", "--graph",
        help="Graph name for the events (default: 'default')"
    )

    parser.add_argument(
        "--community_edition",
        action="store_true",
        help="Format events for Faros Community Edition"
    )

    parser.add_argument(
        "--dry_run",
        action="store_true",
        help="Print events instead of sending them"
    )

    parser.add_argument(
        "--validate_only",
        action="store_true",
        help="Validate events without sending"
    )

    parser.add_argument(
        "-v", "--verbose",
        action="store_true",
        help="Print verbose output including commands"
    )

    args = parser.parse_args()

    # Validate arguments
    if not args.community_edition and not args.api_key:
        # Check environment variable
        args.api_key = os.environ.get("FAROS_API_KEY")
        if not args.api_key:
            parser.error("--api_key is required (or set FAROS_API_KEY env var) unless using --community_edition")

    # Check CSV file exists
    if not os.path.isfile(args.csv_file):
        parser.error(f"CSV file not found: {args.csv_file}")

    # Check faros_event.sh exists
    if not FAROS_EVENT_SCRIPT.exists():
        parser.error(f"faros_event.sh not found at: {FAROS_EVENT_SCRIPT}")

    print(f"Importing deployments from: {args.csv_file}")
    if args.dry_run:
        print("Mode: DRY RUN (events will not be sent)")
    elif args.validate_only:
        print("Mode: VALIDATE ONLY")
    print("-" * 60)

    success, failure = process_csv(args.csv_file, args)

    print("-" * 60)
    print(f"Import complete: {success} succeeded, {failure} failed")

    # Exit with error code if any failures
    sys.exit(1 if failure > 0 else 0)


if __name__ == "__main__":
    main()
