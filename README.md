# :computer: Faros Events CLI

CLI for reporting events to Faros platform.

The purpose of this script is to abstract away the schema structure of the various CI/CD Faros canonical models. When attempting to send a deployment or build event to Faros, only the field values need to be specified and the script takes care of structuring and sending the request.

## :zap: Usage

### Requirements

Please make sure the following are installed before running the script:

- curl
- jq
- uuidgen

### Execution

You can download and execute the script:

```sh
./faros_event.sh help
```

Or with `curl`:

```sh
# set to the latest version - https://github.com/faros-ai/faros-events-cli/releases/latest 
export FAROS_CLI_VERSION="v0.0.1" 
curl -s https://raw.githubusercontent.com/faros-ai/faros-events-cli/$FAROS_CLI_VERSION/faros_event.sh | bash -s help
```

### :book: Event Types

An event type (i.e. `deployment`) corresponds to the step of your CI/CD process that you are instrumenting. Each event type represents a set of fields (required and optional) that are used to populate a specific set of Faros' canonical models which are then sent to Faros. The event type is the main argument passed to the cli. Below are the supported event types with their required and optional fields.

> :exclamation: Important: Every event type requires the "General Required Fields" and can optionally set the "General Optional Fields".

There are two ways that fields can be passed into the script. The first, is via environment variables. The second is via flags. You may use a combination of these two options. If both are set, flags will take precedence over environment variables.

By convention, you can switch between using a flag or an environment variable by simple capitalizing the argument name and prefixing it with FAROS_. For example, --commit_sha becomes FAROS_COMMIT_SHA, --vcs_org becomes FAROS_VCS_ORG.

> General Required Fields

1. `FAROS_API_KEY` / `--api_key "<api_key>"`   / `-k "<api_key>"`  
    Your Faros api key. See [documentation](https://docs.faros.ai/#/api?id=getting-access) for more information on obtaining an api key.
  
1. `FAROS_APP` / `--app "<app>"`  
    The name of the application that is being built. If this application does not already exist within Faros it will be created. [Here](https://app.faros.ai/default/teams/ownership/application) you can view your applications in Faros.
  
1. `FAROS_CI_SOURCE` / `--ci_source "<ci_source>"`  
    The CI source system that contains the build. (i.e. `Jenkins`). Please note that this field is case sensitive. If you have a feed that connects to one of these sources, this name must match exactly to be correctly associated.
  
1. `FAROS_CI_ORG` / `ci_org "<ci_org>"`  
    The unique organization within the CI source system that contains the build.  
  
1. `FAROS_PIPELINE` / `--pipeline "<pipeline>"`  
    The name of the pipeline that contains the build. If this pipeline does not already exist within Faros it will be created.

> General Optional Fields

6. `FAROS_URL` / `--url "<url>"`   / `-u "<url>"`  
    The Faros url to send the event to.  
    __Default__: <https://prod.api.faros.ai>  
  
1. `FAROS_GRAPH` / `--graph "<graph>"`   / `-g "<graph>"`  
    The graph that the event should be sent to.  
    __Default__: "default"  
  
1. `FAROS_ORIGIN` / `--origin "<origin>"`  
    The origin of the event that is sent to faros.  
    __Default__: Faros_Script_Event  
  
1. `FAROS_START_TIME` / `--start_time "<start_time>"`  
    That start time of the build in milliseconds since the epoch. (i.e. `1626804346019`)  
    __Default__: Now  
  
1. `FAROS_END_TIME` / `--end_time "<end_time>"`  
    That end time of the build in milliseconds since the epoch. (i.e. `1626804346019`)  
    __Default__: Now  
  
1. `FAROS_APP_PLATFORM` / `--app_platform "<platform>"`  
    The compute platform that runs the application.  
    __Default__: "NA"  

---

#### Build Event - `build`

A `build` event is used to communicate a specific builds status, the code being built, and where the build is taking place.

> Build Required Fields

1. `FAROS_BUILD_STATUS` / `--build_status "<build_status>"`  
    The status of the build.
    __Allowed Values:__ Success, Failed, Canceled, Queued, Running, Unknown, Custom
  
1. `FAROS_VCS_SOURCE` / `--vcs_source "<vcs_source>"`  
    The version control source system that stores the code that is being built. (i.e. GitHub, GitLab, Bitbucket) Please note that this field is case sensitive. If you have a feed that connects to one of these sources, this name must match exactly to be correctly associated.
  
1. `FAROS_VCS_ORG` / `--vcs_org "<vcs_org>"`  
    The unique organization within the version control source system that contains the code that is being built. (i.e. faros-ai)
  
1. `FAROS_REPO` / `--repo "<repo>"`  
    The repository within the version control organization that stores the code associated to the provided commit sha.  
  
1. `FAROS_COMMIT_SHA` / `--commit_sha "<commit_sha>"`  
    The commit sha of the code that is being built.

> Build Optional Fields

6. `FAROS_BUILD` / `--build "<build>"`  
    The unique id for the build.  
    __Default__: Random UUID  
  
1. `FAROS_BUILD_STATUS_DETAILS` / `--build_status_details "<details>"`  
    Any additional details about the status of the build that you wish to provide.  
    __Default__: ""  
  
##### :mega: Sending a build event examples

Using flags

```sh
./faros_event.sh build -k "<api_key>" \
    --app "<app_name>" \
    --build_status "<build_status>" \
    --ci_org "<ci_organization>" \
    --ci_source "<ci_source>" \
    --commit_sha "<commit_sha>" \
    --repo "<vcs_repo>" \
    --pipeline "<ci_pipeline>" \
    --vcs_source "<vcs_source>" \
    --vcs_org "<vcs_organization>"
```

Or using environment variables

```sh
FAROS_API_KEY="<api_key>" \
FAROS_APP="<app_name>" \
FAROS_BUILD_STATUS="<build_status>" \
FAROS_CI_ORG="<ci_org>" \
FAROS_CI_SOURCE="<ci_source>" \
FAROS_COMMIT_SHA="<commit_sha>" \
FAROS_REPO="<vcs_repo>" \
FAROS_PIPELINE="<ci_pipeline>" \
FAROS_VCS_SOURCE="<vcs_source>" \
FAROS_VCS_ORG="<vcs_org>" \
./faros_event.sh build
```

---

#### Deployment Event - `deployment`

A `deployment` event communicates a deployments status, destination environment as well as the associated build to Faros.

> Deployment Required Fields

1. `FAROS_DEPLOYMENT_ENV` / `--deployment_env "<environment>"`  
    The environment that the application is being deployed to.  
    __Allowed Values:__ Prod, Staging, QA, Dev, Sandbox, Custom  
  
1. `FAROS_DEPLOYMENT_STATUS` / `--deployment_status "<status>"`  
    The status of the deployment.  
    __Allowed Values:__ Success, Failed, Canceled, Queued, Running, RolledBack, Custom  
  
1. `FAROS_BUILD` / `--build <build>`  
    The unique identifier of the build that constructed the artifact being deployed.

> Deployment Optional Fields

4. `FAROS_DEPLOYMENT` / `--deployment "<deployment>"`  
    The unique id of the deployment.  
    __Default__: Random UUID  
  
1. `FAROS_DEPLOYMENT_ENV_DETAILS` / `--deployment_env_details "<details>"`  
    Any additional details about the deployment environment that you wish to provide.  
    __Default__: ""  
  
1. `FAROS_DEPLOYMENT_STATUS_DETAILS` / `--deployment_status_details "<details>"`  
    Any additional details about the status of the deployment that you wish to provide.  
    __Default__: ""  
  
1. `FAROS_SOURCE` / `--source "<source>"`  
    The source that will be associate with the deployment  
    __Default__: "Faros_Script"  

##### :mega: Sending a deployment event examples

Using flags

```sh
./faros_event.sh deployment -k "<api_key>" \
    --app "<app_name>" \
    --ci_org "<ci_organization>" \
    --ci_source "<ci_source>" \
    --deployment_status "<deploy_status>" \
    --deployment_env "<environment>" \
    --pipeline "<ci_pipeline>" \
    --build "<build>"
```

Or using environment variables

```sh
FAROS_API_KEY="<api_key>" \
FAROS_APP="<app_name>" \
FAROS_CI_ORG="<ci_org>" \
FAROS_CI_SOURCE="<ci_source>" \
FAROS_DEPLOYMENT_STATUS="<deploy_status>" \
FAROS_DEPLOYMENT_ENV="<environment>" \
FAROS_PIPELINE="<pipeline>" \
FAROS_BUILD="<build>" \
./faros_event.sh deployment
```

---

#### Build and Deployment Event - `build_deployment`

The `build_deployment` should be used when there is not a distinct build that created the artifact that is being deployed. In order for Faros to associate the code that is being deployed, a build that links a commit sha to the deployment will be created.

> Build and Deployment Required Fields

1. `FAROS_DEPLOYMENT_ENV` / `--deployment_env "<environment>"`  
    The environment that the application is being deployed to.  
    __Allowed Values:__ Prod, Staging, QA, Dev, Sandbox, Custom
  
1. `FAROS_DEPLOYMENT_STATUS` / `--deployment_status "<status>"`  
    The status of the deployment.  
    __Allowed Values:__ Success, Failed, Canceled, Queued, Running, RolledBack, Custom
  
1. `FAROS_BUILD_STATUS` / `--build_status "<build_status>"`  
    The status of the build.  
    __Allowed Values:__ Success, Failed, Canceled, Queued, Running, Unknown, Custom
  
1. `FAROS_VCS_SOURCE` / `--vcs_source "<vcs_source>"`  
    The version control source system that stores the code that is being built (i.e. GitHub, GitLab, Bitbucket) Please note that this field is case sensitive. If you have a feed that connects to one of these sources, this name must match exactly to be correctly associated.
  
1. `FAROS_VCS_ORG` / `--vcs_org "<vcs_org>"`  
    The unique organization within the version control source system that contains the code that is being built. (i.e. faros-ai)
  
1. `FAROS_REPO` / `--repo "<repo>"`  
    The repository within the version control organization that stores the code associated to the provided commit sha.  
  
1. `FAROS_COMMIT_SHA` / `--commit_sha "<commit_sha>"`  
    The commit sha of the code that is being built.

> Build and Deployment Optional Fields

8. `FAROS_DEPLOYMENT_START_TIME` / `--deployment_start_time "<start_time>"`  
    That start time of the deployment in milliseconds since the epoch. (i.e. `1626804346019`)  
    __Default__: FAROS_START_TIME  
  
1. `FAROS_DEPLOYMENT_END_TIME` / `--deployment_end_time "<end_time>"`  
    That end time of the deployment in milliseconds since the epoch. (i.e. `1626804346019`)  
    __Default__: FAROS_END_TIME  
  
1. `FAROS_BUILD_START_TIME` / `--build_start_time "<start_time>"`  
    That start time of the build in milliseconds since the epoch. (i.e. `1626804346019`)  
    __Default__: FAROS_START_TIME  
  
1. `FAROS_BUILD_END_TIME` / `--build_end_time "<end_time>"`  
    That end time of the build in milliseconds since the epoch. (i.e. `1626804346019`)  
    __Default__: FAROS_END_TIME  
  
1. `FAROS_DEPLOYMENT` / `--deployment "<deployment>"`  
    The unique id of the deployment.  
    __Default__: Random UUID  
  
1. `FAROS_DEPLOYMENT_ENV_DETAILS` / `--deployment_env_details "<details>"`  
    Any additional details about the deployment environment that you wish to provide.  
    __Default__: ""  
  
1. `FAROS_DEPLOYMENT_STATUS_DETAILS` / `--deployment_status_details "<details>"`  
    Any additional details about the status of the deployment that you wish to provide.
    __Default__: ""
  
1. `FAROS_SOURCE` / `--source "<source>"`  
    The source that will be associate with the deployment.  
    __Default__: "Faros_Script"  
  
1. `FAROS_BUILD` / `--build "<build>"`  
    The unique id for the build.  
    __Default__: Random UUID  
  
1. `FAROS_BUILD_STATUS_DETAILS` / `--build_status_details "<details>"`  
    Any additional details about the status of the build that you wish to provide.  
    __Default__: ""  

##### :mega: Sending a build_deployment event examples

Using flags

```sh
./faros_event.sh build_deployment -k "<api_key>" \
    --app "<app_name>" \
    --build_status "<build_status>" \
    --ci_org "<ci_organization>" \
    --ci_source "<ci_source>" \
    --commit_sha "<commit_sha>" \
    --deployment_status "<deploy_status>" \
    --deployment_env "<environment>" \
    --pipeline "<ci_pipeline>" \
    --repo "<vcs_repo>" \
    --vcs_source "<vcs_source>" \
    --vcs_org "<vcs_organization>"
```

Or using environment variables

```sh
FAROS_API_KEY="<api_key>" \
FAROS_APP="<app_name>" \
FAROS_BUILD_STATUS="<build_status>" \
FAROS_CI_ORG="<ci_org>" \
FAROS_CI_SOURCE="<ci_source>" \
FAROS_COMMIT_SHA="<commit_sha>" \
FAROS_DEPLOYMENT_STATUS="<deploy_status>" \
FAROS_DEPLOYMENT_ENV="<environment>" \
FAROS_REPO="<vcs_repo>" \
FAROS_PIPELINE="<pipeline>" \
FAROS_VCS_SOURCE="<vcs_source>" \
FAROS_VCS_ORG="<vcs_org>" \
./faros_event.sh build_deployment
```

#### :wrench: Additional Settings Flags

| Flag      | Description            |
| ------------- | -------------------------------------- |
| --dry_run     | Print the event instead of sending.    |
| -s / --silent | Unexceptional output will be silenced. |
| --debug   | Helpful information will be printed.   |

## :white_check_mark: Testing

We use [ShellSpec](https://github.com/shellspec/shellspec) to test our scripts.

### Install using Homebrew

```sh
brew tap shellspec/shellspec
brew install shellspec
```

### Running the tests

Move to the `/test` directory and execute `shellspec`

```sh
cd test && shellspec
```
