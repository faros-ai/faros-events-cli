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
$ ./faros_event.sh help
```

Or with `curl`:

```sh
# set to the latest version - https://github.com/faros-ai/faros-events-cli/releases/latest
$ export FAROS_CLI_VERSION="v0.2.0"
$ curl -s https://raw.githubusercontent.com/faros-ai/faros-events-cli/$FAROS_CLI_VERSION/faros_event.sh | bash -s help
```

### :book: Event Types

An event type (e.g. `deployment`, `build`, `artifact`) corresponds to the step of your CI/CD process that you are instrumenting. Each event type represents a set of arguments (required and optional) that are used to populate a specific set of Faros' canonical models which are then sent to Faros. The event type is the main argument passed to the cli. Below are the supported event types with their required and optional arguments. More than one event type may be used at a time. If you wish to aggregate both a `build` and `deployment` event into a single call the the script you can do so by listing the event types one after another in any order.

There are two ways that arguments can be passed into the script. The first, is via flags. The second is via environment variables. You may use a combination of these two options. If both are set, flags will take precedence over environment variables.

:pencil: **Note**: By convention, you can switch between using a flag or an environment variable by simply capitalizing the argument name and prefixing it with `FAROS_`. For example, `--commit_sha` becomes `FAROS_COMMIT_SHA`, `--vcs_org` becomes `FAROS_VCS_ORG`.

| Argument                    | Description                                                                                                                                                                                                                       | Required | Default                     | Allowed Value |
| --------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | -------- | --------------------------- | ------------- |
| &#x2011;&#x2011;api_key     | Your Faros api key. See the documentation for more information on [obtaining an api key](https://docs.faros.ai/#/api?id=getting-access).                                                                                          | Yes      |                             |               |
| &#x2011;&#x2011;build       | The unique identifier of the build that is being executed.                                                                                                                                                                        | Yes      |                             |               |
| &#x2011;&#x2011;pipeline    | The name of the pipeline that contains the build.                                                                                                                                                                                 | Yes      |                             |               |
| &#x2011;&#x2011;cicd_org    | The unique organization within the CI source system that contains the build.                                                                                                                                                      | Yes      |                             |               |
| &#x2011;&#x2011;cicd_source | The CI source system that contains the build. (e.g. `Jenkins`). Please note that this field is case sensitive. If you have a feed that connects to one of these sources, this name must match exactly to be correctly associated. | Yes      |                             |               |
| &#x2011;&#x2011;url         | The Faros url to send the event to.                                                                                                                                                                                               |          | `https://prod.api.faros.ai` |               |
| &#x2011;&#x2011;graph       | The graph that the event should be sent to.                                                                                                                                                                                       |          | "default"                   |               |
| &#x2011;&#x2011;origin      | The origin of the event that is being sent to faros.                                                                                                                                                                              |          | "Faros_Script_Event"        |               |
| &#x2011;&#x2011;start_time  | That start time of the build in milliseconds since the epoch. (e.g. `1626804346019`)                                                                                                                                              |          | Now                         |               |
| &#x2011;&#x2011;end_time    | That end time of the build in milliseconds since the epoch. (e.g. `1626804346019`)                                                                                                                                                |          | Now                         |               |

---

### Build Event - `build`

A `build` event is used to communicate a specific build's status, the code being built, and where the build is taking place.

#### Build Arguments

| Argument                             | Description                                                                                                                                                                                                                                                                    | Required | Default | Allowed Value                                               |
| ------------------------------------ | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ | -------- | ------- | ----------------------------------------------------------- |
| &#x2011;&#x2011;build_status         | The status of the build.                                                                                                                                                                                                                                                       | Yes      |         | Success, Failed, Canceled, Queued, Running, Unknown, Custom |
| &#x2011;&#x2011;vcs_source           | The version control source system that stores the code that is being built. (e.g. GitHub, GitLab, Bitbucket) Please note that this field is case sensitive. If you have a feed that connects to one of these sources, this name must match exactly to be correctly associated. | Yes      |         |                                                             |
| &#x2011;&#x2011;vcs_org              | The unique organization within the version control source system that contains the code that is being built. (e.g. faros-ai)                                                                                                                                                   | Yes      |         |                                                             |
| &#x2011;&#x2011;vcs_repo             | The repository within the version control organization that stores the code associated to the provided commit sha.                                                                                                                                                             | Yes      |         |                                                             |
| &#x2011;&#x2011;commit_sha           | The commit sha of the code that is being built.                                                                                                                                                                                                                                | Yes      |         |                                                             |
| &#x2011;&#x2011;build_status_details | Any additional details about the status of the build that you wish to provide.                                                                                                                                                                                                 |          | ""      |                                                             |

#### :mega: Sending a build event examples

Using flags

```sh
$ ./faros_event.sh build -k "<api_key>" \
    --build_status "<build_status>" \
    --commit_sha "<commit_sha>" \
    --vcs_repo "<vcs_repo>" \
    --vcs_org "<vcs_organization>"
    --vcs_source "<vcs_source>" \
    --build "<build>" \
    --pipeline "<cicd_pipeline>" \
    --cicd_org "<cicd_organization>" \
    --cicd_source "<cicd_source>" \
```

Or using environment variables

```sh
$ FAROS_API_KEY="<api_key>" \
FAROS_BUILD_STATUS="<build_status>" \
FAROS_COMMIT_SHA="<commit_sha>" \
FAROS_VCS_REPO="<vcs_repo>" \
FAROS_VCS_ORG="<vcs_org>" \
FAROS_VCS_SOURCE="<vcs_source>" \
FAROS_BUILD="<build>" \
FAROS_PIPELINE="<cicd_pipeline>" \
FAROS_CICD_ORG="<cicd_org>" \
FAROS_CICD_SOURCE="<cicd_source>" \
./faros_event.sh build
```

---

### Artifact Event - `artifact`

An `artifact` event communicates to Faros that an artifact has been created, where the artifact was created, and where the artifact is stored.

#### Artifact Arguments

| Argument                        | Description                                                | Required | Default | Allowed Value |
| ------------------------------- | ---------------------------------------------------------- | -------- | ------- | ------------- |
| &#x2011;&#x2011;artifact        | The unique identifier of the artifact.                     | Yes      |         |               |
| &#x2011;&#x2011;artifact_repo   | The repository where the artifact is stored.               | Yes      |         |               |
| &#x2011;&#x2011;artifact_org    | The organization in which the artifact repository resides. | Yes      |         |               |
| &#x2011;&#x2011;artifact_source | The source system that stores the artifact.                | Yes      |         |               |

#### :mega: Sending an artifact event examples

Using flags

```sh
$ ./faros_event.sh artifact -k "<api_key>" \
    --artifact "<artifact>" \
    --artifact_repo "<artifact_repo>" \
    --artifact_org "<artifact_org>" \
    --artifact_source "<artifact_source>" \
    --build "<build>" \
    --pipeline "<cicd_pipeline>" \
    --cicd_org "<cicd_organization>" \
    --cicd_source "<cicd_source>"
```

Or using environment variables

```sh
$ FAROS_API_KEY="<api_key>" \
FAROS_ARTIFACT="<artifact>" \
FAROS_ARTIFACT_REPO="<artifact_repo>" \
FAROS_ARTIFACT_ORG="<artifact_org>" \
FAROS_ARTIFACT_SOURCE="artifact_source" \
FAROS_BUILD="<build>" \
FAROS_PIPELINE="<pipeline>" \
FAROS_CICD_ORG="<cicd_org>" \
FAROS_CICD_SOURCE="<cicd_source>" \
./faros_event.sh artifact
```

---

### Deployment Event - `deployment`

A `deployment` event communicates a deployment's status, destination environment, build that triggered the deployment as well as the artifact being deployed to Faros.

#### Deployment Arguments

| Argument                                  | Description                                                                                                                                              | Required | Default | Allowed Value                                                  |
| ----------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------- | -------- | ------- | -------------------------------------------------------------- |
| &#x2011;&#x2011;app                       | The name of the application that is being deployed. You can view your [applications in Faros](https://app.faros.ai/default/teams/ownership/application). | Yes      |         |                                                                |
| &#x2011;&#x2011;deployment                | The unique identifier of the deployment.                                                                                                                 | Yes      |         |                                                                |
| &#x2011;&#x2011;deployment_env            | The environment that the application is being deployed to.                                                                                               | Yes      |         | Prod, Staging, QA, Dev, Sandbox, Custom                        |
| &#x2011;&#x2011;deployment_status         | The status of the deployment.                                                                                                                            | Yes      |         | Success, Failed, Canceled, Queued, Running, RolledBack, Custom |
| &#x2011;&#x2011;deployment_source         | The source system executing deployment.                                                                                                                  | Yes      |         |                                                                |
| &#x2011;&#x2011;deployment_env_details    | Any additional details about the deployment environment that you wish to provide.                                                                        |          | ""      |                                                                |
| &#x2011;&#x2011;deployment_status_details | Any additional details about the status of the deployment that you wish to provide.                                                                      |          | ""      |                                                                |
| &#x2011;&#x2011;app_platform              | The compute platform that runs the application.                                                                                                          |          | ""      |                                                                |

#### :mega: Sending a deployment event examples

Using flags

```sh
$ ./faros_event.sh deployment -k "<api_key>" \
    --app "<app_name>" \
    --deployment "<deployment>" \
    --deployment_source "<deployment_source>" \
    --deployment_status "<deploy_status>" \
    --deployment_env "<environment>" \
    --artifact "<artifact>" \
    --artifact_repo "<artifact_repo>" \
    --artifact_org "<artifact_org>" \
    --artifact_source "<artifact_source>" \
    --build "<build>"
    --pipeline "<cicd_pipeline>" \
    --cicd_org "<cicd_organization>" \
    --cicd_source "<cicd_source>" \
```

Or using environment variables

```sh
$ FAROS_API_KEY="<api_key>" \
FAROS_APP="<app_name>" \
FAROS_DEPLOYMENT="<deployment>" \
FAROS_DEPLOYMENT_SOURCE="<deployment_source>" \
FAROS_DEPLOYMENT_STATUS="<deploy_status>" \
FAROS_DEPLOYMENT_ENV="<environment>" \
FAROS_ARTIFACT="<artifact>" \
FAROS_ARTIFACT_REPO="<artifact_repo>" \
FAROS_ARTIFACT_ORG="<artifact_org>" \
FAROS_ARTIFACT_SOURCE="<artifact_source>" \
FAROS_BUILD="<build>" \
FAROS_PIPELINE="<pipeline>" \
FAROS_CICD_ORG="<cicd_org>" \
FAROS_CICD_SOURCE="<cicd_source>" \
./faros_event.sh deployment
```

#### :wrench: Additional Settings Flags

| Flag                | Description                                                        |
| ------------------- | ------------------------------------------------------------------ |
| --make_cicd_objects | Include `cicd_Organization` and `cicd_Pipeline` in the sent event. |
| --dry_run           | Print the event instead of sending.                                |
| --silent            | Unexceptional output will be silenced.                             |
| --debug             | Helpful information will be printed.                               |

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
