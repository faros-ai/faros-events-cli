#!/bin/bash

# To run this script:
# 1) Allow this script to be executed by running the following:
# $ chmod u+x ./demo.sh
# 2) Uncomment the command you would like to demo
# 3) Run the script:
# $ ./demo.sh

set -euo pipefail

# Connecting to Faros
# =============================================================================
# visit https://docs.faros.ai/#/api?id=getting-access for api access
export FAROS_API_KEY="<api_key>"
export FAROS_DRY_RUN=1 # Set to 0 or comment out to send the event to Faros
# =============================================================================

# # help
# ../faros_event.sh --help

# # CI (minimum)
# ../faros_event.sh CI \
#     --commit "vcs_source://vcs_org/vcs_repo/commit_sha"

# # CI Event  
# ../faros_event.sh CI \
#     --artifact "artifact_source://artifact_org/artifact_repo/artifact_id" \
#     --commit "vcs_source://vcs_org/vcs_repo/commit_sha" \
#     --run "run_source://run_org/run_pipeline/run_id" \
#     --run_status "Success"

# # CI Event (without artifact information)
# ../faros_event.sh CI \
#     --commit "vcs_source://vcs_org/vcs_repo/commit_sha" \
#     --run "run_source://run_org/run_pipeline/run_id" \
#     --run_status "Success"

# # CD Event (Minimum with --artifact)
# ../faros_event.sh CD \
#     --deploy "deploy_source://app/QA/deploy_id" \
#     --artifact "artifact_source://artifact_org/artifact_repo/artifact_id" \
#     --deploy_status "Success"

# # CD Event (Minimum with --commit)
# ../faros_event.sh CD \
#     --deploy "deploy_source://app/QA/deploy_id" \
#     --artifact "artifact_source://artifact_org/artifact_repo/artifact_id" \
#     --deploy_status "Success"

# # CD Event (with run information)
# ../faros_event.sh CD \
#     --artifact "artifact_source://artifact_org/artifact_repo/artifact_id" \
#     --run "run_source://run_org/run_pipeline/run_id" \
#     --deploy "deploy_source://app/QA/deploy_id" \
#     --deploy_status "Success" \
#     --run_status "Success"

# # CD Event (using commit)
# ../faros_event.sh CD \
#     --deploy "deploy_source://app/QA/deploy_id" \
#     --commit "vcs_source://vcs_org/vcs_repo/commit_sha" \
#     --run "run_source://run_org/run_pipeline/run_id" \
#     --deploy_status "Success" \
#     --run_status "Success"

# # CD Event (with --no_build_object)
# ../faros_event.sh CD \
#     --commit "vcs_source://vcs_org/vcs_repo/commit_sha" \
#     --run "run_source://run_org/run_pipeline/run_id" \
#     --deploy "deploy_source://app/QA/deploy_id" \
#     --deploy_status "Success" \
#     --no_build_object

# # CD Event (with --no_lowercase_vcs)
# ../faros_event.sh CD \
#     --deploy "deploy_source://app/QA/deploy_id" \
#     --commit "vcs_source://VCS_ORG/VCS_REPO/commit_sha" \
#     --run "run_source://run_org/run_pipeline/run_id" \
#     --deploy_status "Success" \
#     --run_status "Success" \
#     --no_lowercase_vcs

# # CD Event (with --no_format)
# ../faros_event.sh CD \
#     --deploy "deploy_source://app/QA/deploy_id" \
#     --commit "vcs_source://VCS_ORG/VCS_REPO/commit_sha" \
#     --run "run_source://run_org/run_pipeline/run_id" \
#     --deploy_status "Success" \
#     --run_status "Success" \
#     --no_format
