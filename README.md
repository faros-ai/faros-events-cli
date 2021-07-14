# Faros Events CLI

CLI for reporting events to Faros platform

## `faros_event.sh` Usage Examples

### Sending a Build Event

```sh
# Using flags
./faros_event.sh build -k "<api_key>" \
    --application "<app_name>" \
    --build_status "<build_status>" \
    --ci_org "<ci_organization>" \
    --commit "<commit_sha>" \
    --repo "<vcs_repo>" \
    --pipeline "<ci_pipeline>" \
    --vcs_source "<vcs_source>" \
    --vcs_org "<vcs_organization>" \
    --print_event

# Using environment variables
FAROS_API_KEY="<api_key>" \
APPLICATION_NAME="<app_name>" \
BUILD_STATUS="<build_status>" \
CI_ORG_UID="<ci_org>" \
COMMIT_SHA="<commit_sha>" \
REPOSITORY="<vcs_repo>" \
PIPELINE_UID="<ci_pipeline>" \
VCS_SOURCE="<vcs_source>" \
VCS_ORG_UID="<vcs_org>" \
./faros_event.sh build --print_event
```

### Sending a Deployment Event

```sh
# Using flags
./faros_event.sh deployment -k "<api_key>" \
    --application "<app_name>" \
    --ci_org "<ci_organization>" \
    --commit "<commit_sha>" \
    --deploy_status "<deploy_status>" \
    --environment "<environment>" \
    --pipeline "<ci_pipeline>" \
    --print_event

# Using environment variables
FAROS_API_KEY="<api_key>" \
APPLICATION_NAME="<app_name>" \
CI_ORG_UID="<ci_org>" \
COMMIT_SHA="<commit_sha>" \
DEPLOYMENT_STATUS="<deploy_status>" \
DEPLOYMENT_ENV="<environment>" \
PIPELINE_UID="<pipeline>" \
./faros_event.sh deployment --print_event
```

### Sending a Full (Build + Deploy) Event

```sh
# Using flags
./faros_event.sh full -k "<api_key>" \
    --application "<app_name>" \
    --build_status "<build_status>" \
    --ci_org "<ci_organization>" \
    --commit "<commit_sha>" \
    --deploy_status "<deploy_status>" \
    --environment "<environment>" \
    --pipeline "<ci_pipeline>" \
    --repo "<vcs_repo>" \
    --vcs_source "<vcs_source>" \
    --vcs_org "<vcs_organization>" \
    --print_event

# Using environment variables
FAROS_API_KEY="<api_key>" \
APPLICATION_NAME="<app_name>" \
BUILD_STATUS="<build_status>" \
CI_ORG_UID="<ci_org>" \
COMMIT_SHA="<commit_sha>" \
DEPLOYMENT_STATUS="<deploy_status>" \
DEPLOYMENT_ENV="<environment>" \
REPOSITORY="<vcs_repo>" \
PIPELINE_UID="<pipeline>" \
VCS_SOURCE="<vcs_source>" \
VCS_ORG_UID="<vcs_org>" \
./faros_event.sh full --print_event
```
