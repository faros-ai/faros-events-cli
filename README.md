# :computer: Faros Events CLI [![CI](https://github.com/faros-ai/faros-events-cli/actions/workflows/ci.yml/badge.svg)](https://github.com/faros-ai/faros-events-cli/actions/workflows/ci.yml) [![Latest Release](https://img.shields.io/github/v/release/faros-ai/faros-events-cli?label=latest%20version&logo=latest%20version&style=plastic)](https://github.com/faros-ai/faros-events-cli/releases/latest)

CLI for reporting events to Faros platform.

- [Installation](#installation)
  - [Using Docker](#using-docker)
  - [Using Bash](#using-bash)
- [Instrumenting CI/CD pipelines](#instrumenting-cicd-pipelines)
  - [Reporting builds with commits (basic)](#reporting-builds-with-commits-basic)
  - [Reporting deployments with commits (basic)](#reporting-deployments-with-commits-basic)
  - [Reporting builds & deployments in parts (advanced)](#reporting-builds--deployments-in-parts-advanced)
  - [Reporting builds & deployments with commits & artifacts (advanced)](#reporting-builds--deployments-with-commits--artifacts-advanced)
- [Code quality](#code-quality)
  - [Reporting test execution results](#reporting-test-execution-results)
- [Arguments](#arguments)
  - [Passing arguments: flags or environment variables](#passing-arguments-flags-or-environment-variables)
  - [General arguments](#general-arguments)
  - [CI arguments](#ci-arguments)
  - [CD arguments](#cd-arguments)
  - [Test Execution arguments](#test-execution-arguments)
- [Tips](#tips)
  - [Validating your command](#validating-your-command)
  - [Usage with Faros Community Edition](#usage-with-faros-community-edition)
- [Development](#hammer-development)

## Installation

### Using Docker

**Requirements**: Docker client and runtime.

```sh
docker pull farosai/faros-events-cli:v0.5.3
```

### Using Bash

**Requirements**: `curl`, `jq`, `sed` and an implementation of `awk` (we recommend `gawk`).

Either [download the script manually](https://raw.githubusercontent.com/faros-ai/faros-events-cli/v0.5.3/faros_event.sh) or invoke the script directly with curl:

```sh
curl -s https://raw.githubusercontent.com/faros-ai/faros-events-cli/v0.5.3/faros_event.sh | bash -s help
```

## Instrumenting CI/CD pipelines

![When to send an event](resources/Faros_CI_CD_Events.png)

### Reporting builds with commits (basic)

This event reports a successful code build:

```sh
./faros_event.sh CI -k "<faros_api_key>" \
    --commit "<commit_source>://<commit_organization>/<commit_repository>/<commit_sha>" \
    --run "<run_source>://<run_organization>/<run_pipeline>/<run_id>" \
    --run_status "Success" \
    --run_start_time "2021-07-20T18:05:46.019Z" \
    --run_end_time "2021-07-20T18:08:42.024Z"
```

### Reporting deployments with commits (basic)

This event reports a successful deployment of your application to your environment:

```sh
./faros_event.sh CD -k "<faros_api_key>" \
    --commit "<commit_source>://<commit_organization>/<commit_repository>/<commit_sha>" \
    --deploy "<deploy_source>://<deploy_application>/<deploy_environment>/<deploy_id>" \
    --deploy_status "Success" \
    --deploy_start_time "2021-07-20T18:05:46.019Z" \
    --deploy_end_time "2021-07-20T18:08:42.024Z"
```

### Reporting builds & deployments in parts (advanced)

Faros events are very flexible. Information can be sent all at once in a single event, or as it becomes available using multiple events. Certain fields depend on other fields to be present for Faros to correctly link information behind the scenes. See the [argument tables](#arguments) for dependency information.

#### Sending build information in parts

You can send an event when a code build has started. And a final event, when the code build has finished successfully!

- Code build started

```sh
./faros_event.sh CI -k "<faros_api_key>" \
    --commit "<commit_source>://<commit_organization>/<commit_repository>/<commit_sha>" \
    --run "<run_source>://<run_organization>/<run_pipeline>/<run_id>" \
    --run_status "Running" \
    --run_start_time "Now"
```

- Code build finished successfully

```sh
./faros_event.sh CI -k "<faros_api_key>" \
    --run "<run_source>://<run_organization>/<run_pipeline>/<run_id>" \
    --run_status "Success" \
    --run_end_time "Now"
```

#### Sending deployment information in parts

You can send an event when an deployment has started. Then later, you can send an event when that deployment has finished successfully!

- Deployment started

```sh
./faros_event.sh CD -k "<faros_api_key>" \
    --commit "<commit_source>://<commit_organization>/<commit_repository>/<commit_sha>" \
    --deploy "<deploy_source>://<deploy_application>/<deploy_environment>/<deploy_id>" \
    --deploy_status "Running" \
    --deploy_start_time "Now"
```

- Deployment finished successfully

```sh
./faros_event.sh CD -k "<faros_api_key>" \
    --deploy "<deploy_source>://<deploy_application>/<deploy_environment>/<deploy_id>" \
    --deploy_status "Success" \
    --deploy_end_time "Now"
```

### Reporting builds & deployments with commits & artifacts (advanced)

When the commit information is not available at the time of deployment, you will need to use the `--artifact` flag. This flag lets Faros know that a commit was built into an artifact so that when you deploy that artifact, Faros knows how it all links together.

This event reports that a commit was successfully built into the specified artifact:

```sh
./faros_event.sh CI -k "<faros_api_key>" \
    --commit "<commit_source>://<commit_organization>/<commit_repository>/<commit_sha>" \
    --artifact "<artifact_source>://<artifact_organization>/<artifact_repository>/<artifact_id>" \
    --run "<run_source>://<run_organization>/<run_pipeline>/<run_id>" \
    --run_status "Success" \
    --run_start_time "2021-07-20T18:05:46.019Z" \
    --run_end_time "2021-07-20T18:08:42.024Z"
```

This event reports the successful deployment of that artifact to the Prod environment:

```sh
./faros_event.sh CD -k "<faros_api_key>" \
    --artifact "<artifact_source>://<artifact_organization>/<artifact_repository>/<artifact_id>" \
    --deploy "<deploy_source>://<deploy_application>/<deploy_environment>/<deploy_id>" \
    --deploy_status "Success" \
    --deploy_start_time "2021-07-20T18:05:46.019Z" \
    --deploy_end_time "2021-07-20T18:08:42.024Z"
```

## Code quality

### Reporting test execution results

> :exclamation: `--full` flag must be provided with TestExecution event

This event reports a successful test suite invocation:

```sh
./faros_event.sh TestExecution -k "<faros_api_key>" \
    --commit "<commit_source>://<commit_organization>/<commit_repository>/<commit_sha>" \
    --test_id "<test_id>" \
    --test_source "<test_source>" \
    --test_type "Functional" \
    --test_status "Success" \
    --test_suite "<test_suite_id>" \
    --test_stats "success=5,failure=0,total=5" \
    --test_start_time "2021-07-20T18:05:46.019Z" \
    --test_end_time "2021-07-20T18:08:42.024Z" \
    --full
```

### Arguments

#### Passing arguments: flags or environment variables

There are two ways that arguments can be passed into the script. The first, is via flags. The second is via environment variables. You may use a combination of these two options. If both are set, flags will take precedence over environment variables.

:pencil: **Note**: By convention, you can switch between using a flag or an environment variable by simply capitalizing the argument name and prefixing it with `FAROS_`. For example, `--commit` becomes `FAROS_COMMIT`, `--artifact` becomes `FAROS_ARTIFACT`.

#### General arguments

| Argument                            | Description                                                                                                                                                       | Required                                                                                                                                            | Default                                                                           |
| ----------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------- | --------------------------------------------------------------------------------- |
| &#x2011;&#x2011;api_key             | Your Faros API key. See the documentation for more information on [obtaining an api key](https://docs.faros.ai/#/api?id=getting-access).                          | Yes (not required for [Faros Community Edition](https://github.com/faros-ai/faros-community-edition), i.e when `community_edition` flag is present) |                                                                                   |
| &#x2011;&#x2011;community_edition   | Events will be formatted and sent to [Faros Community Edition](https://github.com/faros-ai/faros-community-edition). (no value accepted, true if flag is present) |                                                                                                                                                     | False                                                                             |
| &#x2011;&#x2011;dry_run             | Print the event instead of sending. (no value accepted, true if flag is present)                                                                                  |                                                                                                                                                     | False                                                                             |
| &#x2011;&#x2011;validate_only       | Event will not be consumed but instead will only be validated against event schema. (no value accepted, true if flag is present)                                  |                                                                                                                                                     | False                                                                             |
| &#x2011;&#x2011;url                 | The Faros API url to send the event to.                                                                                                                           |                                                                                                                                                     | `https://prod.api.faros.ai` (`http://localhost:8080` for Faros Community Edition) |
| &#x2011;&#x2011;graph               | The graph that the event should be sent to.                                                                                                                       |                                                                                                                                                     | "default"                                                                         |
| &#x2011;&#x2011;origin              | The origin of the event that is being sent to Faros.                                                                                                              |                                                                                                                                                     | "Faros_Script_Event"                                                              |
| &#x2011;&#x2011;silent              | Unexceptional output will be silenced. (no value accepted, true if flag is present)                                                                               |                                                                                                                                                     | False                                                                             |
| &#x2011;&#x2011;debug               | Helpful information will be printed. (no value accepted, true if flag is present)                                                                                 |                                                                                                                                                     | False                                                                             |
| &#x2011;&#x2011;full                | The event being sent should be validated as a full event. (no value accepted, true if flag is present)                                                            |                                                                                                                                                     | False                                                                             |
| &#x2011;&#x2011;skip_saving_run     | Do not include cicd_Build in the event. (no value accepted, true if flag is present)                                                                              |                                                                                                                                                     | False                                                                             |
| &#x2011;&#x2011;no_lowercase_vcs    | Do not lowercase commit_organization and commit_repo. (no value accepted, true if flag is present)                                                                |                                                                                                                                                     | False                                                                             |
| &#x2011;&#x2011;hasura_admin_secret | The Hasura Admin Secret.                                                                                                                                          |                                                                                                                                                     | "admin" (Only used in Faros Community Edition)                                    |

---

#### CI arguments

| Argument                            | Description                                                                                                                                                                                                                                  | Dependency |
| ----------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ---------- |
| &#x2011;&#x2011;run                 | The URI of the job run that built the code. (`<source>://<organization>/<pipeline>/<run_id>`)                                                                                                                                                |            |
| &#x2011;&#x2011;run_status          | The status of the job run that built the code. (Allowed Values: Success, Failed, Canceled, Queued, Running, Unknown, Custom)                                                                                                                 | --run      |
| &#x2011;&#x2011;run_status_details  | Any extra details about the status of the job run.                                                                                                                                                                                           | --run      |
| &#x2011;&#x2011;run_start_time      | The start time of the job run in milliseconds since the epoch, ISO-8601 string, or `Now`. (e.g. `1626804346019`, `2021-07-20T18:05:46.019Z`)                                                                                                 | --run      |
| &#x2011;&#x2011;run_end_time        | The end time of the job run in milliseconds since the epoch, ISO-8601 string, or `Now`. (e.g. `1626804346019`, `2021-07-20T18:05:46.019Z`)                                                                                                   | --run      |
| &#x2011;&#x2011;run_name            | The name of the job run that built the code.                                                                                                                                                                                                 | --run      |
| &#x2011;&#x2011;commit              | The URI of the commit. We recommend you only provide artifact information if you do not have access to the commit information within your deployment's context. (`<commit_source>://<commit_organization>/<commit_repository>/<commit_sha>`) | --run      |
| &#x2011;&#x2011;artifact            | The URI of the artifact. (`<source>://<organization>/<repository>/<artifact_id>`)                                                                                                                                                            | --commit   |
| &#x2011;&#x2011;pull_request_number | The pull request number of the commit. (e.g. 123). Used only if --commit is included                                                                                                                                                         | --commit   |

---

#### CD arguments

| Argument                              | Description                                                                                                                                                                                                                           | Dependency |
| ------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ---------- |
| &#x2011;&#x2011;deploy                | The URI of the deployment. (`<deploy_source>://<application>/<environment>/<deploy_id>`) (`<environment>` allowed values: `Prod`, `Staging`, `QA`, `Dev`, `Sandbox`, `Canary`, `Custom`)                                              |            |
| &#x2011;&#x2011;deploy_start_time     | The start time of the deployment in milliseconds since the epoch, ISO-8601 string, or `Now`. (e.g. `1626804346019`, `2021-07-20T18:05:46.019Z`)                                                                                       | --deploy   |
| &#x2011;&#x2011;deploy_end_time       | The end time of the deployment in milliseconds since the epoch, ISO-8601 string, or `Now`. (e.g. `1626804346019`, `2021-07-20T18:05:46.019Z`)                                                                                         | --deploy   |
| &#x2011;&#x2011;deploy_status         | The status of the deployment. (Allowed values: `Success`, `Failed`, `Canceled`, `Queued`, `Running`, `RolledBack`, `Custom`)                                                                                                          | --deploy   |
| &#x2011;&#x2011;deploy_status_details | Any extra details about the status of the deployment.                                                                                                                                                                                 | --deploy   |
| &#x2011;&#x2011;deploy_app_platform   | The compute platform that runs the application.                                                                                                                                                                                       | --deploy   |
| &#x2011;&#x2011;deploy_env_details    | Any extra details about the deployment environment.                                                                                                                                                                                   | --deploy   |
| &#x2011;&#x2011;commit                | The URI of the commit. If you specify `--artifact` in your CI events, you should use `--artifact` in your CD events. Otherwise, use `--commit`. (`<source>://<organization>/<repository>/<commit_sha>`)                               | --deploy   |
| &#x2011;&#x2011;artifact              | The URI of the artifact. If you specify `--artifact` in your CI events, you should use `--artifact` in your CD events. Otherwise, use `--commit`. (`<artifact_source>://<artifact_organization>/<artifact_repository>/<artifact_id>`) | --deploy   |
| &#x2011;&#x2011;pull_request_number   | The pull request number of the commit. (e.g. 123). Used only if --commit is included                                                                                                                                                  | --commit   |
| &#x2011;&#x2011;run                   | The URI of the job run executing the deployment. (`<source>://<organization>/<pipeline>/<run_id>` e.g. `Jenkins://faros-ai/my-pipeline/1234`)                                                                                         |            |
| &#x2011;&#x2011;run_status            | The status of the job run executing the deployment. (Allowed values: Success, Failed, Canceled, Queued, Running, Unknown, Custom)                                                                                                     | --run      |
| &#x2011;&#x2011;run_status_details    | Any extra details about the status of the job run executing the deployment.                                                                                                                                                           | --run      |
| &#x2011;&#x2011;run_start_time        | The start time of the job run in milliseconds since the epoch, ISO-8601 string, or `Now`. (e.g. `1626804346019`, `2021-07-20T18:05:46.019Z`)                                                                                          | --run      |
| &#x2011;&#x2011;run_end_time          | The end time of the job run in milliseconds since the epoch, ISO-8601 string, or `Now`. (e.g. `1626804346019`, `2021-07-20T18:05:46.019Z`)                                                                                            | --run      |

---

#### Test Execution arguments

| Argument                            | Description                                                                                                                                                                                                                       | Required                                                                                                                                    | Allowed Value                                                                    |
| ----------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------- | -------------------------------------------------------------------------------- |
| &#x2011;&#x2011;commit              | The URI of the commit. (`<source>://<organization>/<repository>/<commit_sha>` e.g. `GitHub://faros-ai/my-repo/da500aa4f54cbf8f3eb47a1dc2c136715c9197b9`)                                                                          | Yes                                                                                                                                         |                                                                                  |
| &#x2011;&#x2011;test_id             | The unique identifier of the test within the test source system.                                                                                                                                                                  | Yes                                                                                                                                         |                                                                                  |
| &#x2011;&#x2011;test_source         | The test source system. (e.g. Jenkins)                                                                                                                                                                                            | Yes                                                                                                                                         |                                                                                  |
| &#x2011;&#x2011;test_type           | The type of the test that was executed.                                                                                                                                                                                           | Yes                                                                                                                                         | Functional, Integration, Manual, Performance, Regression, Security, Unit, Custom |
| &#x2011;&#x2011;test_type_details   | Additional details about the type of the test that was executed.                                                                                                                                                                  |                                                                                                                                             |                                                                                  |
| &#x2011;&#x2011;test_status         | The outcome status of the test execution.                                                                                                                                                                                         | Yes                                                                                                                                         | Success, Failure, Custom, Skipped, Unknown                                       |
| &#x2011;&#x2011;test_status_details | Additional details about the status of the outcome status of the test.                                                                                                                                                            |                                                                                                                                             |                                                                                  |
| &#x2011;&#x2011;test_suite          | The name of the test suite.                                                                                                                                                                                                       | Yes                                                                                                                                         |                                                                                  |
| &#x2011;&#x2011;test_stats          | The stats of the test outcome as a string of comma separated `key=value` pairs. (e.g. `success=5,failure=2,total=7`)                                                                                                              |                                                                                                                                             | failure=N,success=N,skipped=N,unknown=N,custom=N,total=N                         |
| &#x2011;&#x2011;test_start_time     | The start time of the test in milliseconds since the epoch, ISO-8601 string, or `Now`. (e.g. `1626804346019`, `2021-07-20T18:05:46.019Z`)                                                                                         |                                                                                                                                             |                                                                                  |
| &#x2011;&#x2011;test_end_time       | The end time of the test in milliseconds since the epoch, ISO-8601 string, or `Now`. (e.g. `1626804346019`, `2021-07-20T18:05:46.019Z`)                                                                                           |                                                                                                                                             |                                                                                  |
| &#x2011;&#x2011;test_tags           | A string of comma separated tags to associate with the test. (e.g. `tag1,tag2`)                                                                                                                                                   |                                                                                                                                             |                                                                                  |
| &#x2011;&#x2011;environments        | A string of comma separated environments to associate with the test. (e.g. `env1,env2`)                                                                                                                                           |                                                                                                                                             |                                                                                  |
| &#x2011;&#x2011;device_name         | The name of the device on which the test was executed. (e.g. MacBook)                                                                                                                                                             |                                                                                                                                             |                                                                                  |
| &#x2011;&#x2011;device_os           | The operating system of the device on which the test was executed. (e.g. `OSX`)                                                                                                                                                   |                                                                                                                                             |                                                                                  |
| &#x2011;&#x2011;device_browser      | The browser on which the test was executed. (e.g. `Chrome`)                                                                                                                                                                       |                                                                                                                                             |                                                                                  |
| &#x2011;&#x2011;device_type         | The type of the device on which the test was executed.                                                                                                                                                                            |                                                                                                                                             |                                                                                  |
| &#x2011;&#x2011;test_task           | A comma separated array of one or many unique identifiers of test tasks within the TMS (Task Management System). The outcome of a specific test for this execution can be provided as a `key=value` pair (e.g. `TEST-123=Success) |                                                                                                                                             | Allowed Statuses: Success, Failure, Custom, Skipped, Unknown                     |
| &#x2011;&#x2011;defect_task         | The unique identifier of the defect task within the TMS (Task Management System).                                                                                                                                                 |                                                                                                                                             |                                                                                  |
| &#x2011;&#x2011;test_suite_task     | The unique identifier of the test suite task within the TMS (Task Management System).                                                                                                                                             |                                                                                                                                             |                                                                                  |
| &#x2011;&#x2011;test_execution_task | The unique identifier of the test execution task within the TMS (Task Management System).                                                                                                                                         |                                                                                                                                             |                                                                                  |
| &#x2011;&#x2011;task_source         | The TMS (Task Management System). (e.g. Jira)                                                                                                                                                                                     | If &#x2011;&#x2011;test_task, &#x2011;&#x2011;defect_task, &#x2011;&#x2011;test_suite_task, or &#x2011;&#x2011;test_execution_task provided |                                                                                  |

---

## Tips

### Validating your command

As you are iterating on instrumentation you can use the `--validate-only` flag to test before you are ready to send actual data:

```sh
./faros_event.sh <...your command arguments...> --validate_only
```

### Usage with Faros Community Edition

> :exclamation: Faros Community Edition does not currently support sending events in parts

When using Faros Community Edition, you can use the tool in exactly the same way as described above. Just include the `--community_edition` flag. The Faros API key is not needed, since the tool will call your locally deployed Hasura to perform mutations derived from the events. See the [Faros Community Edition repo](https://github.com/faros-ai/faros-community-edition) for more details.

```sh
./faros_event.sh <...your command arguments...> --community_edition
```

## :hammer: Development

### :white_check_mark: Testing & Checking for Bugs

We use [ShellSpec](https://github.com/shellspec/shellspec) to test our scripts and [ShellCheck](https://www.shellcheck.net/) to check for potential bugs.

#### Install using Homebrew

```sh
brew tap shellspec/shellspec
brew install shellspec shellcheck
```

#### Running the tests

Move to the `/test` directory and execute `shellspec`

```sh
cd test && shellspec
```

#### Checking for bugs

Go to root directory and execute:

```sh
shellcheck -s bash faros_event.sh
```
