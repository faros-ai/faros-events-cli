# :computer: Faros Events CLI [![CI](https://github.com/faros-ai/faros-events-cli/actions/workflows/ci.yml/badge.svg)](https://github.com/faros-ai/faros-events-cli/actions/workflows/ci.yml) [![Latest Release](https://img.shields.io/github/v/release/faros-ai/faros-events-cli?label=latest%20version&logo=latest%20version&style=plastic)](https://github.com/faros-ai/faros-events-cli/releases/latest)

CLI for reporting events to Faros platform.

- [Installation](#installation)
  - [Using Docker](#using-docker)
  - [Using Bash](#using-bash)
- [Instrumenting CI pipelines](#instrumenting-ci-pipelines)
  - [Reporting builds and build steps in parts](#reporting-builds-and-build-steps-in-parts)
- [Reporting test execution results](#reporting-test-execution-results)
- [Reporting deployments](#reporting-deployments)
- [Arguments](#arguments)
  - [Passing arguments: flags or environment variables](#passing-arguments-flags-or-environment-variables)
  - [General arguments](#general-arguments)
  - [CI arguments](#ci-arguments)
  - [CD arguments](#cd-arguments)
  - [Test Execution arguments](#test-execution-arguments)
  - [URI arguments alternative](#uri-arguments-alternative)
  - [Additional arguments](#additional-arguments)
- [Tips](#tips)
  - [Validating your command](#validating-your-command)
  - [Usage with Faros Community Edition](#usage-with-faros-community-edition)
- [Development](#hammer-development)

## Installation

### Using Docker

**Requirements**: `docker`

```sh
docker pull farosai/faros-events-cli:v0.6.11 && docker run farosai/faros-events-cli:v0.6.11 help
```

### Using Bash

**Requirements**: `curl`, `jq` (1.6+), `sed`, `awk` (we recommend `gawk`).

Either [download the script manually](https://raw.githubusercontent.com/faros-ai/faros-events-cli/v0.6.11/faros_event.sh) or invoke the script directly with curl:

```sh
bash <(curl -s https://raw.githubusercontent.com/faros-ai/faros-events-cli/v0.6.11/faros_event.sh) help
```


## Instrumenting CI pipelines
Report CI events to the Faros platform if you would like to analyze success/failure rates of your CI pipelines and how long different stages take.

This CI event reports a successful build event where an artifact is built from a commit: 
```sh
./faros_event.sh CI -k "<faros_api_key>" \
    --commit "<commit_source>://<commit_organization>/<commit_repository>/<commit_sha>" \
    --artifact "<artifact_source>://<artifact_organization>/<artifact_repository>/<artifact_id>" \
    --run "<run_source>://<run_organization>/<run_pipeline>/<run_id>" \
    --run_status "Success" \
    --run_start_time "2021-07-20T18:05:46.019Z" \
    --run_end_time "2021-07-20T18:08:42.024Z"
```

Example usage: 

```sh
./faros_event.sh CI -k "<faros_api_key>" \
    --commit "GitHub://faros-ai/faros-events-cli/4414ad2b3b13b17055171678437a92e5d788cad1" \
    --artifact "Docker://farosai/faros-events-cli/v0.6.11" \
    --run "Jenkins://faros-ai/faros-events-cli/168_1700016590" \
    --run_status "Success" \
    --run_start_time "2023-11-14T18:05:46.019Z" \
    --run_end_time "2023-11-14T18:08:42.024Z"
```

> :exclamation: The `run_status` is an enum. Read the documentation on arguments [here](#ci-arguments) for accepted values. 

> :exclamation: If your CI pipeline does not build artifacts, omit the `--artifact` parameter, and be sure to add the `--no-artifact` flag. 

### Reporting builds and build steps in parts

In addition to tracking build outcomes, you can also instrument specific steps in your build processes, and report on information in parts, as it becomes available.

For example, after reporting the start of a build:

```sh
./faros_event.sh CI -k "<faros_api_key>" \
    --commit "<commit_source>://<commit_organization>/<commit_repository>/<commit_sha>" \
    --artifact "<artifact_source>://<artifact_organization>/<artifact_repository>/<artifact_id>" \
    --run "<run_source>://<run_organization>/<run_pipeline>/<run_id>" \
    --run_start_time "Now"
```

You can report the start of a specific build step:

```sh
./faros_event.sh CI -k "<faros_api_key>" \
    --run "<run_source>://<run_organization>/<run_pipeline>/<run_id>" \
    --run_step_id "<run_step_id>" \
    --run_step_start_time "Now"
```

Then report its outcome and end time:

```sh
./faros_event.sh CI -k "<faros_api_key>" \
    --run "<run_source>://<run_organization>/<run_pipeline>/<run_id>" \
    --run_step_id "<run_step_id>" \
    --run_step_status "Success" \
    --run_step_end_time "Now"
```

Don't forget to report the end of the build itself!

```sh
./faros_event.sh CI -k "<faros_api_key>" \
    --run "<run_source>://<run_organization>/<run_pipeline>/<run_id>" \
    --run_status "Success" \
    --run_end_time "Now"
```


## Reporting test execution results

Use this event type if you would like to analyze success/failure rates and execution times of Test Suites 

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
    --test_stats "failure=0,success=18,skipped=3,unknown=0,custom=2,total=23" \
    --test_start_time "2021-07-20T18:05:46.019Z" \
    --test_end_time "2021-07-20T18:08:42.024Z" \
    --full
```

## Reporting deployments

Send CD events to the Faros platform if you would like to analyze your deploy frequency and lead time metrics. 

**Option 1**:
If information about the specific commit that is being deployed is available at the time of deployment, use this CD event to report the successful deployment of an application to an environment:

```sh
./faros_event.sh CD -k "<faros_api_key>" \
    --commit "<commit_source>://<commit_organization>/<commit_repository>/<commit_sha>" \
    --deploy "<deploy_source>://<deploy_application>/<deploy_environment>/<deploy_id>" \
    --deploy_status "Success" \
    --deploy_start_time "2021-07-20T18:05:46.019Z" \
    --deploy_end_time "2021-07-20T18:08:42.024Z"
```

**Option 2**:
If commit information is not readily available at the time of deployment, but you do have artifact information, you can reference the artifact instead of the commit. 
In such a scenario, you must also spearately report CI events as described [above](#instrumenting-ci-pipelines), and the Faros Platform will do the work of figuring out what commit got deployed. 

```sh
./faros_event.sh CD -k "<faros_api_key>" \
    --artifact "<artifact_source>://<artifact_organization>/<artifact_repository>/<artifact_id>" \
    --deploy "<deploy_source>://<deploy_application>/<deploy_environment>/<deploy_id>" \
    --deploy_status "Success" \
    --deploy_start_time "2021-07-20T18:05:46.019Z" \
    --deploy_end_time "2021-07-20T18:08:42.024Z"
```

> :exclamation: If choosing Option 2 to report your deployment events, the  `--artifact` parameter in the CD event should exactly match the artifact parameter in the CI event.

> :exclamation: The `deploy_status` is an enum. Read the documentation on arguments [here](#cd-arguments) for accepted values. 

> :exclamation: The `deploy_environment` is also an enum. Read the documentation on arguments [here](#cd-arguments) for accepted values. 


## Arguments

### Passing arguments: flags or environment variables

There are two ways that arguments can be passed into the script. The first, is via flags. The second is via environment variables. You may use a combination of these two options. If both are set, flags will take precedence over environment variables.

:pencil: **Note**: By convention, you can switch between using a flag or an environment variable by simply capitalizing the argument name and prefixing it with `FAROS_`. For example, `--commit` becomes `FAROS_COMMIT`, `--artifact` becomes `FAROS_ARTIFACT`.

### General arguments

| Argument            | Description                                                                                                                                                   | Required                                                      | Default                                                                           |
|---------------------|---------------------------------------------------------------------------------------------------------------------------------------------------------------|---------------------------------------------------------------|-----------------------------------------------------------------------------------|
| -k, --api_key       | Your Faros API key. See the documentation for more information on [obtaining an api key](https://docs.faros.ai/#/api?id=getting-access).                      | Yes (not required when `--community_edition` flag is present) |                                                                                   |
| -u, --url           | The Faros API url to send the event to.                                                                                                                       |                                                               | `https://prod.api.faros.ai` (`http://localhost:8080` for Faros Community Edition) |
| -g, --graph         | The graph(s) that the event should be sent to. If specifying more than one graph, they should be provided as a comma separated array (e.g. `graph_1,graph_2`) |                                                               | "default"                                                                         |
| --validate_only     | Event will not be consumed but instead will only be validated against event schema.                                                                           |                                                               |                                                                                   |
| --dry_run           | Print the event instead of sending.                                                                                                                           |                                                               |                                                                                   |
| --community_edition | Events will be formatted and sent to [Faros Community Edition](https://github.com/faros-ai/faros-community-edition).                                          |                                                               |                                                                                   |

### CI arguments

| Argument                  | Description                                                                                                                                | Dependency |
|---------------------------|--------------------------------------------------------------------------------------------------------------------------------------------|------------|
| --run                     | The URI of the job run that built the code. (`<source>://<organization>/<pipeline>/<run_id>`)                                              |            |
| --run_status              | The status of the job run that built the code. (Allowed values: `Success`, `Failed`, `Canceled`, `Queued`, `Running`, `Unknown`, `Custom`) | --run      |
| --run_status_details      | Any extra details about the status of the job run.                                                                                         | --run      |
| --run_start_time          | The start time of the job run in milliseconds since the epoch, ISO-8601, or `Now`. (e.g. `1626804346019`, `2021-07-20T18:05:46.019Z`)      | --run      |
| --run_end_time            | The end time of the job run in milliseconds since the epoch, ISO-8601, or `Now`. (e.g. `1626804346019`, `2021-07-20T18:05:46.019Z`)        | --run      |
| --run_name                | The name of the job run that built the code.                                                                                               | --run      |
| --commit                  | The URI of the commit. (`<commit_source>://<commit_organization>/<commit_repository>/<commit_sha>`)                                        | --run      |
| --artifact                | The URI of the artifact. (`<source>://<organization>/<repository>/<artifact_id>`)                                                          | --commit   |
| --pull_request_number     | The pull request number of the commit. (e.g. `123`).                                                                                       | --commit   |
| --run_step_id             | The id of the job run step. (e.g. `123`).                                                                                                  | --run      |
| --run_step_name           | The name of the job run step (e.g. `Lint`).                                                                                                | --run      |
| --run_step_status         | The status of the job run step. (Allowed values: `Success`, `Failed`, `Canceled`, `Queued`, `Running`, `Unknown`, `Custom`)                | --run      |
| --run_step_status_details | Any extra details about the status of the job run step.                                                                                    | --run      |
| --run_step_type           | The type of the job run step. (Allowed values: `Script`, `Manual`, `Custom`)                                                               | --run      |
| --run_step_type_details   | Any extra details about the type of the job run step.                                                                                      | --run      |
| --run_step_start_time     | The start time of the job run step in milliseconds since the epoch, ISO-8601, or `Now`. (e.g. `1626804346019`, `2021-07-20T18:05:46.019Z`) | --run      |
| --run_step_end_time       | The end time of the job run step in milliseconds since the epoch, ISO-8601, or `Now`. (e.g. `1626804346019`, `2021-07-20T18:05:46.019Z`)   | --run      |
| --run_step_command        | The command executed by the job run step.                                                                                                  | --run      |
| --run_step_url            | The url to the job run step.                                                                                                               | --run      |

### CD arguments

| Argument                | Description                                                                                                                                                                                                                           | Dependency |
|-------------------------|---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|------------|
| --deploy                | The URI of the deployment. (`<deploy_source>://<application>/<environment>/<deploy_id>`) (`<environment>` allowed values: `Prod`, `Staging`, `QA`, `Dev`, `Sandbox`, `Canary`, `Custom`)                                              |            |
| --deploy_start_time     | The start time of the deployment in milliseconds since the epoch, ISO-8601, or `Now`. (e.g. `1626804346019`, `2021-07-20T18:05:46.019Z`)                                                                                              | --deploy   |
| --deploy_end_time       | The end time of the deployment in milliseconds since the epoch, ISO-8601, or `Now`. (e.g. `1626804346019`, `2021-07-20T18:05:46.019Z`)                                                                                                | --deploy   |
| --deploy_requested_at   | The time the deployment was requested in milliseconds since the epoch, ISO-8601, or `Now`. (e.g. `1626804346019`, `2021-07-20T18:05:46.019Z`)                                                                                         | --deploy   |
| --deploy_status         | The status of the deployment. (Allowed values: `Success`, `Failed`, `Canceled`, `Queued`, `Running`, `RolledBack`, `Custom`)                                                                                                          | --deploy   |
| --deploy_status_details | Any extra details about the status of the deployment.                                                                                                                                                                                 | --deploy   |
| --deploy_url            | The url of the deployment.                                                                                                                                                                                                            | --deploy   |
| --deploy_app_platform   | The compute platform that runs the application.                                                                                                                                                                                       | --deploy   |
| --deploy_app_tags       | A comma separated array of `key:value` application tags. (e.g. `key1:value1,key2:value2`)                                                                                                                                             | --deploy   |
| --deploy_app_paths      | A comma separated array of application slash separated paths. (e.g. `aws/us-east-1/eks-001,aws/us-west-2/eks-002`)                                                                                                                    | --deploy   |
| --deploy_env_details    | Any extra details about the deployment environment.                                                                                                                                                                                   | --deploy   |
| --commit                | The URI of the commit. If you specify `--artifact` in your CI events, you should use `--artifact` in your CD events. Otherwise, use `--commit`. (`<source>://<organization>/<repository>/<commit_sha>`)                               | --deploy   |
| --artifact              | The URI of the artifact. If you specify `--artifact` in your CI events, you should use `--artifact` in your CD events. Otherwise, use `--commit`. (`<artifact_source>://<artifact_organization>/<artifact_repository>/<artifact_id>`) | --deploy   |
| --pull_request_number   | The pull request number of the commit. (e.g. 123). Used only if --commit is included                                                                                                                                                  | --commit   |
| --run                   | The URI of the job run executing the deployment. (`<source>://<organization>/<pipeline>/<run_id>` e.g. `Jenkins://faros-ai/my-pipeline/1234`)                                                                                         |            |
| --run_status            | The status of the job run executing the deployment. (Allowed values: `Success`, `Failed`, `Canceled`, `Queued`, `Running`, `Unknown`, `Custom`)                                                                                       | --run      |
| --run_status_details    | Any extra details about the status of the job run executing the deployment.                                                                                                                                                           | --run      |
| --run_start_time        | The start time of the job run in milliseconds since the epoch, ISO-8601, or `Now`. (e.g. `1626804346019`, `2021-07-20T18:05:46.019Z`)                                                                                                 | --run      |
| --run_end_time          | The end time of the job run in milliseconds since the epoch, ISO-8601, or `Now`. (e.g. `1626804346019`, `2021-07-20T18:05:46.019Z`)                                                                                                   | --run      |

### Test Execution arguments

| Argument              | Description                                                                                                                                                | Required |
|-----------------------|------------------------------------------------------------------------------------------------------------------------------------------------------------|----------|
| --commit              | The URI of the commit. (`<source>://<organization>/<repository>/<commit_sha>` e.g. `GitHub://faros-ai/my-repo/da500aa4f54cbf8f3eb47a1dc2c136715c9197b9`)   | Yes      |
| --pull_request_number | The pull request number of the commit. (e.g. 123).                                                                                                         |          |
| --test_id             | The unique identifier of the test within the test source system.                                                                                           | Yes      |
| --test_source         | The test source system. (e.g. `Jenkins`)                                                                                                                   | Yes      |
| --test_type           | The type of the test that was executed: (Allowed values: `Functional`, `Integration`, `Manual`, `Performance`, `Regression`, `Security`, `Unit`, `Custom`) | Yes      |
| --test_type_details   | Additional details about the type of the test that was executed.                                                                                           |          |
| --test_status         | The outcome status of the test execution. (Allowed values: `Success`, `Failure`, `Custom`, `Skipped`, `Unknown`)                                           | Yes      |
| --test_status_details | Additional details about the status of the outcome status of the test.                                                                                     |          |
| --test_suite          | The name of the test suite.                                                                                                                                | Yes      |
| --test_stats          | The stats of the test outcome as a string of comma separated `key=value` pairs. (e.g. `failure=0,success=18,skipped=3,unknown=0,custom=2,total=23`)        |          |
| --test_start_time     | The start time of the test in milliseconds since the epoch, ISO-8601, or `Now`. (e.g. `1626804346019`, `2021-07-20T18:05:46.019Z`)                         |          |
| --test_end_time       | The end time of the test in milliseconds since the epoch, ISO-8601, or `Now`. (e.g. `1626804346019`, `2021-07-20T18:05:46.019Z`)                           |          |
| --test_tags           | A string of comma separated tags to associate with the test. (e.g. `tag1,tag2`)                                                                            |          |
| --environments        | A string of comma separated environments to associate with the test. (e.g. `env1,env2`)                                                                    |          |
| --device_name         | The name of the device on which the test was executed. (e.g. `MacBook`)                                                                                    |          |
| --device_os           | The operating system of the device on which the test was executed. (e.g. `OSX`)                                                                            |          |
| --device_browser      | The browser on which the test was executed. (e.g. `Chrome`)                                                                                                |          |
| --device_type         | The type of the device on which the test was executed.                                                                                                                                                                                                                                                                           |
| --task_source         | The type of TMS (Task Management System). (e.g. `Jira`, `Shortcut`, `GitHub`)                                                                                                                                                                                                                                                    | If --test_task, --defect_task, --test_suite_task, or --test_execution_task provided |
| --test_task           | A comma separated array of one or many unique identifiers of test tasks within the TMS (Task Management System). The outcome of a specific test for this execution can be provided as a `key=value` pair (e.g. `TEST-123=Success,TEST-456=Failure` with allowed statuses: `Success`, `Failure`, `Custom`, `Skipped`, `Unknown` ) |                                                                                     |
| --defect_task         | The unique identifier of the defect task within the TMS (Task Management System).                                                                                                                                                                                                                                                |                                                                                     |
| --test_suite_task     | The unique identifier of the test suite task within the TMS (Task Management System).                                                                                                                                                                                                                                            |                                                                                     |
| --test_execution_task | The unique identifier of the test execution task within the TMS (Task Management System).                                                                                                                                                                                                                                        |                                                                                     |
| --run                   | The URI of the job run executing the test. (`<source>://<organization>/<pipeline>/<run_id>` e.g. `Jenkins://faros-ai/my-pipeline/1234`)                                                                                         |            |
| --run_status            | The status of the job run executing the test. (Allowed values: `Success`, `Failed`, `Canceled`, `Queued`, `Running`, `Unknown`, `Custom`)                                                                                       | --run      |
| --run_status_details    | Any extra details about the status of the job run executing the test.                                                                                                                                                           | --run      |
| --run_start_time        | The start time of the job run in milliseconds since the epoch, ISO-8601, or `Now`. (e.g. `1626804346019`, `2021-07-20T18:05:46.019Z`)                                                                                                 | --run      |
| --run_end_time          | The end time of the job run in milliseconds since the epoch, ISO-8601, or `Now`. (e.g. `1626804346019`, `2021-07-20T18:05:46.019Z`)                                                                                                   | --run      |

### URI arguments alternative

Sometimes using the URI format required by `--run`, `--commit`, `--artifact`, or `--deploy` arguments gets in the way. For example when your commit repository has a `/` in the name. Here is how you can supply the required information as individual fields instead. Each alternative requires **all** listed fields.

#### `--run` argument alternative (**all** listed fields are required)

| Argument       | Description                  |
|----------------|------------------------------|
| --run_id       | The id of the run            |
| --run_pipeline | The pipeline of the run      |
| --run_org      | The organization of the run  |
| --run_source   | The source system of the run |

#### `--deploy` argument alternative (**all** listed fields are required)

| Argument        | Description                                                                                                       |
|-----------------|-------------------------------------------------------------------------------------------------------------------|
| --deploy_id     | The id of the deployment                                                                                          |
| --deploy_env    | The environment of the deployment (allowed values: `Prod`, `Staging`, `QA`, `Dev`, `Sandbox`, `Canary`, `Custom`) |
| --deploy_app    | The application being deployed                                                                                    |
| --deploy_source | The source system of the deployment                                                                               |

#### `--commit` argument alternative (**all** listed fields are required)

| Argument        | Description                          |
|-----------------|--------------------------------------|
| --commit_sha    | The SHA of the commit                |
| --commit_repo   | The repository of the commit         |
| --commit_org    | The organization of the commit       |
| --commit_source | The source system storing the commit |

#### `--artifact` argument alternative (**all** listed fields are required)

| Argument          | Description                            |
|-------------------|----------------------------------------|
| --artifact_id     | The id of the artifact                 |
| --artifact_repo   | The repository of the artifact         |
| --artifact_org    | The organization of the artifact       |
| --artifact_source | The source system storing the artifact |

### Additional arguments

| Argument              | Description                                                         | Default              |
|-----------------------|---------------------------------------------------------------------|----------------------|
| --origin              | The origin of the event that is being sent to Faros.                | "Faros_Script_Event" |
| --full                | The event being sent should be validated as a full event.           |                      |
| --silent              | Unexceptional output will be silenced.                              |                      |
| --debug               | Helpful information will be printed.                                |                      |
| --skip_saving_run     | Do not include `cicd_Build` in the event.                           |                      |
| --no_lowercase_vcs    | Do not lowercase commit_organization and commit_repo.               |                      |
| --hasura_admin_secret | The Hasura Admin Secret. Only used with `‑‑community_edition` flag. | "admin"              |
| --max_time            | The time in seconds allowed for each retry attempt.                 | 10                   |
| --retry               | The number of allowed retry attempts.                               | 3                    |
| --retry_delay         | The delay in seconds between each retry attempt.                    | 1                    |
| --retry_max_time      | The total time in seconds the request with retries can take.        | 40                   |

---

## Tips

### Validating your command

As you are iterating on instrumentation you can use the `--validate_only` flag to test before you are ready to send actual data:

```sh
./faros_event.sh <...your command arguments...> --validate_only
```

### Usage with Faros Community Edition

> :exclamation: Sending events in parts is not currently supported
> :exclamation: Build steps in CI events are not currently supported
> :exclamation: Test Execution events are not currently supported

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
