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
# ./faros_event.sh --help

# # CI Event 
# ./faros_event.sh CI \
#     --artifact "artifact_source://artifact_org/artifact_repo/artifact_id" \
#     --commit "vcs_source://vcs_org/vcs_repo/commit_sha" \
#     --build "build_source://build_org/build_pipeline/build_id"

# # CI Event (without artifact information)
# ./faros_event.sh CI \
#     --commit "vcs_source://vcs_org/vcs_repo/commit_sha" \
#     --build "build_source://build_org/build_pipeline/build_id"

# # CD Event
# ./faros_event.sh CD \
#     --deployment_status "Success"
#     --deployment "deploy_source://app/QA/deploy_id" \
#     --artifact "artifact_source://artifact_org/artifact_repo/artifact_id"

# # CD Event (using artifact)
# ./faros_event.sh CD \
#     --artifact "artifact_source://artifact_org/artifact_repo/artifact_id" \
#     --build "build_source://build_org/build_pipeline/build_id" \
#     --deployment "deploy_source://app/QA/deploy_id" \
#     --deployment_status "Success"

# # CD Event (using commit)
# ./faros_event.sh CD \
#     --deployment_status "Success" \
#     --deployment "deploy_source://app/QA/deploy_id" \
#     --commit "vcs_source://vcs_org/vcs_repo/commit_sha" \
#     --build "build_source://build_org/build_pipeline/build_id"

# # CD Event (with --write_build)
# ./faros_event.sh CD \
#     --commit "vcs_source://vcs_org/vcs_repo/commit_sha" \
#     --build "build_source://build_org/build_pipeline/build_id" \
#     --deployment "deploy_source://app/QA/deploy_id" \
#     --deployment_status "Success" \
#     --build_status "Success" \
#     --write_build

# CI CD event (including build information)
# ./faros_event.sh CI CD \
#     --commit "vcs_source://vcs_org/vcs_repo/commit_sha" \
#     --artifact "artifact_source://artifact_org/artifact_repo/artifact_id" \
#     --deployment "deploy_source://app/QA/deploy_id" \
#     --build "build_source://build_org/build_pipeline/build_id" \
#     --deployment_status "Success"

# # CI CD event (excluding artifact)
# ./faros_event.sh CI CD \
#     --commit "vcs_source://vcs_org/vcs_repo/commit_sha" \
#     --deployment "deploy_source://app/QA/deploy_id" \
#     --deployment_status "Success"
