# Faros Events CLI

CLI for reporting events to Faros platform

## `faros_event.sh`

The purpose of this script is to abstract away the schema structure of the various CI/CD Faros canonical models. Now when attempting to send a deployment or build event to Faros, only the field values need to be specified and the script takes care of structuring and sending the request.

### Arguments passing

There are two ways that arguments can be passed into the script. The first is via flags. The second, is via environment variables. If both are set, flags will take precedence over environment variables. By convention, you can switch between using a flag or an environment variable by simple capitalizing the argument name and prefixing it with `FAROS_`. E.g. `--commit_sha` becomes `FAROS_COMMIT_SHA`, `--vcs_org` becomes `FAROS_VCS_ORG`.

Example with mixed argument input:

```sh
FAROS_CI_ORG="<ci_org>" \
FAROS_COMMIT_SHA="<commit_sha>" \
FAROS_REPO="<vcs_repo>" \
./faros_event.sh build -k "<api_key>" \
    --app "<app_name>" \
    --build_status "<build_status>" \
    --pipeline "<ci_pipeline>" \
    --vcs_source "<vcs_source>" \
    --vcs_org "<vcs_organization>"
```

### Usage

Download and invoke the script in one line:
```sh
$(curl https://raw.githubusercontent.com/faros-ai/faros-events-cli/faros_events.sh) | bash -s deployment --help
```

### Usage Examples

#### Sending a Build Event

```sh
# Using flags
./faros_event.sh build -k "<api_key>" \
    --app "<app_name>" \
    --build_status "<build_status>" \
    --ci_org "<ci_organization>" \
    --commit_sha "<commit_sha>" \
    --repo "<vcs_repo>" \
    --pipeline "<ci_pipeline>" \
    --vcs_source "<vcs_source>" \
    --vcs_org "<vcs_organization>"

# Using environment variables
FAROS_API_KEY="<api_key>" \
FAROS_APP="<app_name>" \
FAROS_BUILD_STATUS="<build_status>" \
FAROS_CI_ORG="<ci_org>" \
FAROS_COMMIT_SHA="<commit_sha>" \
FAROS_REPO="<vcs_repo>" \
FAROS_PIPELINE="<ci_pipeline>" \
FAROS_VCS_SOURCE="<vcs_source>" \
FAROS_VCS_ORG="<vcs_org>" \
./faros_event.sh build
```

#### Sending a Deployment Event

```sh
# Using flags
./faros_event.sh deployment -k "<api_key>" \
    --app "<app_name>" \
    --ci_org "<ci_organization>" \
    --commit_sha "<commit_sha>" \
    --deployment_status "<deploy_status>" \
    --deployment_env "<environment>" \
    --pipeline "<ci_pipeline>" \
    --build "<build>"

# Using environment variables
FAROS_API_KEY="<api_key>" \
FAROS_APP="<app_name>" \
FAROS_CI_ORG="<ci_org>" \
FAROS_COMMIT_SHA="<commit_sha>" \
FAROS_DEPLOYMENT_STATUS="<deploy_status>" \
FAROS_DEPLOYMENT_ENV="<environment>" \
FAROS_PIPELINE="<pipeline>" \
FAROS_BUILD="<build>" \
./faros_event.sh deployment
```

#### Sending a Full (Build + Deployment) Event

```sh
# Using flags
./faros_event.sh full -k "<api_key>" \
    --app "<app_name>" \
    --build_status "<build_status>" \
    --ci_org "<ci_organization>" \
    --commit_sha "<commit_sha>" \
    --deployment_status "<deploy_status>" \
    --deployment_env "<environment>" \
    --pipeline "<ci_pipeline>" \
    --repo "<vcs_repo>" \
    --vcs_source "<vcs_source>" \
    --vcs_org "<vcs_organization>"

# Using environment variables
FAROS_API_KEY="<api_key>" \
FAROS_APP="<app_name>" \
FAROS_BUILD_STATUS="<build_status>" \
FAROS_CI_ORG="<ci_org>" \
FAROS_COMMIT_SHA="<commit_sha>" \
FAROS_DEPLOYMENT_STATUS="<deploy_status>" \
FAROS_DEPLOYMENT_ENV="<environment>" \
FAROS_REPO="<vcs_repo>" \
FAROS_PIPELINE="<pipeline>" \
FAROS_VCS_SOURCE="<vcs_source>" \
FAROS_VCS_ORG="<vcs_org>" \
./faros_event.sh full
```
