# :computer: Faros Events CLI

CLI for reporting events to Faros platform.

The purpose of this script is to abstract away the schema structure of the various CI/CD Faros canonical models. When attempting to send a deployment or build event to Faros, only the field values need to be specified and the script takes care of structuring and sending the request.

## :zap: Usage

### Requirements

Please make sure the following are installed before running the script:

- curl
- jq

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

An event type (e.g. `CI`, `CD`) corresponds to the step of your CI/CD process that you are instrumenting. Each event type represents a set of arguments (required and optional) that are used to populate a specific set of Faros' canonical models which are then sent to Faros. The event types are the main arguments passed to the cli. Below are the supported event types with their required and optional arguments.

There are two ways that arguments can be passed into the script. The first, is via flags. The second is via environment variables. You may use a combination of these two options. If both are set, flags will take precedence over environment variables.

:pencil: **Note**: By convention, you can switch between using a flag or an environment variable by simply capitalizing the argument name and prefixing it with `FAROS_`. For example, `--vcs` becomes `FAROS_VCS`, `--artifact` becomes `FAROS_ARTIFACT`.

| Argument                   | Description                                                                                                                                                   | Required                               | Default                     | Allowed Value |
| -------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------- | -------------------------------------- | --------------------------- | ------------- |
| &#x2011;&#x2011;api_key    | Your Faros api key. See the documentation for more information on [obtaining an api key](https://docs.faros.ai/#/api?id=getting-access).                      | Yes                                    |                             |               |
| &#x2011;&#x2011;build      | The resource URI of the build that is being executed. (`<ci_source>://<ci_organization>/<ci_pipeline>/<build_id>` e.g. `Jenkins://faros-ai/my-pipeline/1234`) | If &#x2011;&#x2011;write_build present |                             |               |
| &#x2011;&#x2011;url        | The Faros url to send the event to.                                                                                                                           |                                        | `https://prod.api.faros.ai` |               |
| &#x2011;&#x2011;graph      | The graph that the event should be sent to.                                                                                                                   |                                        | "default"                   |               |
| &#x2011;&#x2011;origin     | The origin of the event that is being sent to faros.                                                                                                          |                                        | "Faros_Script_Event"        |               |
| &#x2011;&#x2011;start_time | That start time of the build in milliseconds since the epoch. (e.g. `1626804346019`)                                                                          |                                        | Now                         |               |
| &#x2011;&#x2011;end_time   | That end time of the build in milliseconds since the epoch. (e.g. `1626804346019`)                                                                            |                                        | Now                         |               |

---

### CI Event - `CI`

A `CI` event communicates to Faros that an artifact has been created, where it was created, and where it is stored.

#### CI Arguments

In addition to the general required and optional arguments, the following arguments are `CI` event specific.

| Argument                 | Description                                                                                                                                                                                 | Required | Default | Allowed Value |
| ------------------------ | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | -------- | ------- | ------------- |
| &#x2011;&#x2011;vcs      | The resource URI of the commit. (`<vcs_source>://<vcs_organization>/<vcs_repo>/<commit_sha>` e.g. `GitHub://faros-ai/my-repo/da500aa4f54cbf8f3eb47a1dc2c136715c9197b9`)                     | Yes      |         |               |
| &#x2011;&#x2011;artifact | The resource URI of the artifact. (`<artifact_source>://<artifact_organization>/<artifact_repo>/<artifact_id>` e.g. `DockerHub://farosai/my-repo/da500aa4f54cbf8f3eb47a1dc2c136715c9197b9`) |          | vcs     |               |

#### :mega: Sending a `CI` event examples

Using flags

```sh
$ ./faros_event.sh CI -k "<api_key>" \
    --vcs "<vcs_source>://<vcs_organization>/<vcs_repo>/<commit_sha>" \
    --artifact "<artifact_source>://<artifact_org>/<artifact_repo>/<artifact>"
```

Or using environment variables

```sh
$ FAROS_API_KEY="<api_key>" \
FAROS_VCS="<vcs_source>://<vcs_organization>/<vcs_repo>/<commit_sha>" \
FAROS_ARTIFACT="<artifact_source>://<artifact_org>/<artifact_repo>/<artifact>" \
./faros_event.sh CI
```

Omitting Artifact information

```sh
$ ./faros_event.sh CI -k "<api_key>" \
    --vcs "<vcs_source>://<vcs_organization>/<vcs_repo>/<commit_sha>"
```

Including build information

```sh
$ ./faros_event.sh CI -k "<api_key>" \
    --build "<cicd_source>://<cicd_organization>/<cicd_pipeline>/<build_uid>" \
    --vcs "<vcs_source>://<vcs_organization>/<vcs_repo>/<commit_sha>" \
    --artifact "<artifact_source>://<artifact_org>/<artifact_repo>/<artifact>"
```

---

### CD Event - `CD`

A `CD` event communicates to Faros that a specific application was deployed, the deployment's status, destination environment, build that triggered the deployment as well as the artifact being deployed.

#### CD Arguments

In addition to the general required and optional arguments, the following arguments are `CD` event specific.

| Argument                                  | Description                                                                                                                                                                                 | Required                       | Default      | Allowed Value                                                  |
| ----------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------ | ------------ | -------------------------------------------------------------- |
| &#x2011;&#x2011;deployment                | The resource URI of the deployment. (`<deployment_source>://<application>/<deployment_env>/<deployment_id>` e.g. `ECS://my-app/Prod/1234`)                                                  | Yes                            |              | `deployment_env`: Prod, Staging, QA, Dev, Sandbox, Custom      |
| &#x2011;&#x2011;artifact                  | The resource URI of the artifact. (`<artifact_source>://<artifact_organization>/<artifact_repo>/<artifact_id>` e.g. `DockerHub://farosai/my-repo/da500aa4f54cbf8f3eb47a1dc2c136715c9197b9`) | If `vcs` **not** included      |              |                                                                |
| &#x2011;&#x2011;vcs                       | The resource URI of the commit. (`<vcs_source>://<vcs_organization>/<vcs_repo>/<commit_sha>` e.g. `GitHub://faros-ai/my-repo/da500aa4f54cbf8f3eb47a1dc2c136715c9197b9`)                     | If `artifact` **not** included |              |                                                                |
| &#x2011;&#x2011;deployment_status         | The status of the deployment.                                                                                                                                                               | Yes                            |              | Success, Failed, Canceled, Queued, Running, RolledBack, Custom |
| &#x2011;&#x2011;deployment_app_platform   | The compute platform that runs the application.                                                                                                                                             |                                | ""           |                                                                |
| &#x2011;&#x2011;deployment_env_details    | Any additional details about the deployment environment that you wish to provide.                                                                                                           |                                | ""           |                                                                |
| &#x2011;&#x2011;deployment_status_details | Any additional details about the status of the deployment that you wish to provide.                                                                                                         |                                | ""           |                                                                |
| &#x2011;&#x2011;deployment_start_time     | The start time of the deployment in milliseconds since the epoch. (e.g. `1626804346019`)                                                                                                    |                                | `start_time` |                                                                |
| &#x2011;&#x2011;deployment_end_time       | The end time of the deployment in milliseconds since the epoch. (e.g. `1626804346019`)                                                                                                      |                                | `end_time`   |                                                                |

#### :mega: Sending a `CD` event using artifact information examples

Using flags

```sh
$ ./faros_event.sh CD -k "<api_key>" \
    --deployment "<deployment_source>://<app_name>/QA/<deployment_uid>" \
    --artifact "<artifact_source>://<artifact_org>/<artifact_repo>/<artifact>" \
    --deployment_status Success
```

Or using environment variables

```sh
$ FAROS_API_KEY="<api_key>" \
FAROS_DEPLOYMENT="<deployment_source>://<app_name>/QA/<deployment_uid>" \
FAROS_ARTIFACT="<artifact_source>://<artifact_org>/<artifact_repo>/<artifact>" \
FAROS_DEPLOYMENT_STATUS="Success" \
./faros_event.sh CD
```

Including build information

```sh
$ ./faros_event.sh CD -k "<api_key>" \
    --build "<cicd_source>://<cicd_organization>/<cicd_pipeline>/<build_uid>" \
    --deployment "<deployment_source>://<app_name>/QA/<deployment_uid>" \
    --artifact "<artifact_source>://<artifact_org>/<artifact_repo>/<artifact>" \
    --deployment_status Success
```

#### :mega: Sending a `CD` event using vcs information examples

Using flags

```sh
$ ./faros_event.sh CD -k "<api_key>" \
    --deployment "<deployment_source>://<app_name>/QA/<deployment_uid>" \
    --vcs "<vcs_source>://<vcs_organization>/<vcs_repo>/<commit_sha>" \
    --deployment_status Success
```

Or using environment variables

```sh
$ FAROS_API_KEY="<api_key>" \
FAROS_DEPLOYMENT="<deployment_source>://<app_name>/QA/<deployment_uid>" \
FAROS_VCS="<vcs_source>://<vcs_organization>/<vcs_repo>/<commit_sha>" \
FAROS_DEPLOYMENT_STATUS="Success" \
./faros_event.sh CD
```

Including build information

```sh
$ ./faros_event.sh CD -k "<api_key>" \
    --build "<cicd_source>://<cicd_organization>/<cicd_pipeline>/<build_uid>" \
    --deployment "<deployment_source>://<app_name>/QA/<deployment_uid>" \
    --vcs "<vcs_source>://<vcs_organization>/<vcs_repo>/<commit_sha>" \
    --deployment_status Success
```

#### In case you want to send everything at once :wink:

```sh
$ ./faros_event.sh CI CD -k "<api_key>" \
    --vcs "<vcs_source>://<vcs_organization>/<vcs_repo>/<commit_sha>" \
    --artifact "<artifact_source>://<artifact_org>/<artifact_repo>/<artifact>"
    --deployment "<deployment_source>://<app_name>/QA/<deployment_uid>" \
    --build "<cicd_source>://<cicd_organization>/<cicd_pipeline>/<build_uid>" \
    --deployment_status Success
```

#### :wrench: Additional Settings Flags

| Flag                 | Description                                                        |
| -------------------- | ------------------------------------------------------------------ |
| --write_build        | Include `cicd_Build` in the sent event.                            |
| --write_cicd_objects | Include `cicd_Organization` and `cicd_Pipeline` in the sent event. |
| --dry_run            | Print the event instead of sending.                                |
| --silent             | Unexceptional output will be silenced.                             |
| --debug              | Helpful information will be printed.                               |

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
