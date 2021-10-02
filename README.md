# :computer: Faros Events CLI [![CI](https://github.com/faros-ai/faros-events-cli/actions/workflows/ci.yml/badge.svg)](https://github.com/faros-ai/faros-events-cli/actions/workflows/ci.yml) [![Release](https://github.com/faros-ai/faros-events-cli/actions/workflows/release.yml/badge.svg)](https://github.com/faros-ai/faros-events-cli/actions/workflows/release.yml)

[![Latest Release](https://img.shields.io/github/v/release/faros-ai/faros-events-cli?label=latest%20version&logo=latest%20version&style=plastic)](https://github.com/faros-ai/faros-events-cli/releases/latest)

CLI for reporting events to Faros platform.

The script provides all the necessary instrumentation for CI/CD pipelines by sending events to Faros platform

## :zap: Usage

### Execute with Bash

**Requirements**: Please make sure the following are installed before running the script - `curl`, `jq`, `sed` and an implementation of `awk` (we recommend `gawk`).

1. [Download the script manually](https://raw.githubusercontent.com/faros-ai/faros-events-cli/v0.2.3/faros_event.sh) and execute it:

```sh
$ ./faros_event.sh help
```

2. Or download it with `curl` and invoke it in one command:

```sh
$ export FAROS_CLI_VERSION="v0.2.3"
$ curl -s https://raw.githubusercontent.com/faros-ai/faros-events-cli/$FAROS_CLI_VERSION/faros_event.sh | bash -s help
```

### Execute with Docker

**Requirements**: Docker client and runtime.

1. Pull the image:

```sh
$ docker pull farosai/faros-events-cli:v0.2.3
```

2. Run it:

```sh
$ docker run farosai/faros-events-cli:v0.2.3 help
```

### :book: Event Types

An event type (e.g. `CI`, `CD`) corresponds to the step of your CI/CD pipeline that you are instrumenting.

- Use `CI` events to instrument code build pipelines. For example, you can report the result of a successful code build:

```sh
$ ./faros_event.sh CI -k "<faros_api_key>" \
    --run "<ci_source>://<ci_organization>/<ci_pipeline>/<run_id>" \
    --commit "<vcs_source>://<vcs_organization>/<vcs_repo>/<commit_sha>" \
    --artifact "<artifact_source>://<artifact_org>/<artifact_repo>/<artifact_id>" \
    --run_status Success \
    --run_start_time "1626804346000" \
    --run_end_time "1626804358000"
```

- Use `CD` events to instrument deployment pipelines. For example, you can report the result of a successful deployment:

```sh
$ ./faros_event.sh CD -k "<faros_api_key>" \
    --artifact "<artifact_source>://<artifact_org>/<artifact_repo>/<artifact_id>" \
    --deploy "<deploy_source>://<application>/<deploy_env>/<deploy_id>" \
    --deploy_status Success \
    --deploy_start_time "1626804356000" \
    --deploy_end_time "1626804357000"
```

### Arguments

There are two ways that arguments can be passed into the script. The first, is via flags. The second is via environment variables. You may use a combination of these two options. If both are set, flags will take precedence over environment variables.

:pencil: **Note**: By convention, you can switch between using a flag or an environment variable by simply capitalizing the argument name and prefixing it with `FAROS_`. For example, `--commit` becomes `FAROS_COMMIT`, `--artifact` becomes `FAROS_ARTIFACT`.

| Argument                         | Description                                                                                                                              | Required | Default                     |
| -------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------- | -------- | --------------------------- |
| &#x2011;&#x2011;api_key          | Your Faros API key. See the documentation for more information on [obtaining an api key](https://docs.faros.ai/#/api?id=getting-access). | Yes      |                             |
| &#x2011;&#x2011;url              | The Faros API url to send the event to.                                                                                                  |          | `https://prod.api.faros.ai` |
| &#x2011;&#x2011;graph            | The graph that the event should be sent to.                                                                                              |          | "default"                   |
| &#x2011;&#x2011;origin           | The origin of the event that is being sent to Faros.                                                                                     |          | "Faros_Script_Event"        |
| &#x2011;&#x2011;dry_run          | Print the event instead of sending. (no value accepted, true if flag is present)                                                         |          | False                       |
| &#x2011;&#x2011;silent           | Unexceptional output will be silenced. (no value accepted, true if flag is present)                                                      |          | False                       |
| &#x2011;&#x2011;debug            | Helpful information will be printed. (no value accepted, true if flag is present)                                                        |          | False                       |
| &#x2011;&#x2011;no_build_object  | Do not include cicd_Build in the event. (no value accepted, true if flag is present)                                                     |          | False                       |
| &#x2011;&#x2011;no_lowercase_vcs | Do not lowercase vcs_organization and vcs_repo. (no value accepted, true if flag is present)                                             |          | False                       |

#### CI Event - `CI`

A `CI` event communicates the outcome of a code build pipeline execution, and its artifact.

#### CI Arguments

> You may need to scroll to the right to view the entire table.

| Argument                           | Description                                                                                                                                                                        | Required                        | Default | Allowed Value                                               |
| ---------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------- | ------- | ----------------------------------------------------------- |
| &#x2011;&#x2011;commit             | The URI of the commit. (`<vcs_source>://<vcs_organization>/<vcs_repo>/<commit_sha>` e.g. `GitHub://faros-ai/my-repo/da500aa4f54cbf8f3eb47a1dc2c136715c9197b9`)                     | Yes                             |         |                                                             |
| &#x2011;&#x2011;artifact           | The URI of the artifact. (`<artifact_source>://<artifact_organization>/<artifact_repo>/<artifact_id>` e.g. `DockerHub://farosai/my-repo/da500aa4f54cbf8f3eb47a1dc2c136715c9197b9`) |                                 |         |                                                             |
| &#x2011;&#x2011;run                | The URI of the job run that built the code. (`<ci_source>://<ci_organization>/<ci_pipeline>/<run_id>` e.g. `Jenkins://faros-ai/my-pipeline/1234`)                                  |                                 |         |                                                             |
| &#x2011;&#x2011;run_status         | The status of the job run that built the code.                                                                                                                                     | If &#x2011;&#x2011;run provided |         | Success, Failed, Canceled, Queued, Running, Unknown, Custom |
| &#x2011;&#x2011;run_name           | The name of the job run that built the code.                                                                                                                                       |                                 | ""      |                                                             |
| &#x2011;&#x2011;run_status_details | Any extra details about the status of the job run.                                                                                                                                 |                                 | ""      |                                                             |
| &#x2011;&#x2011;run_start_time     | The start time of the job run in milliseconds since the epoch. (e.g. `1626804346019`)                                                                                              |                                 | Now     |                                                             |
| &#x2011;&#x2011;run_end_time       | The end time of the job run in milliseconds since the epoch. (e.g. `1626804346019`)                                                                                                |                                 | Now     |                                                             |

#### CD Event - `CD`

A `CD` event communicates the outcome of an application deployment pipeline execution, and the environment (e.g. QA, Prod).

#### CD Arguments

> You may need to scroll to the right to view the entire table.

| Argument                              | Description                                                                                                                                                                        | Required                                                  | Default | Allowed Value                                                  |
| ------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | --------------------------------------------------------- | ------- | -------------------------------------------------------------- |
| &#x2011;&#x2011;deploy                | The URI of the deployment. (`<deploy_source>://<application>/<deploy_env>/<deploy_id>` e.g. `ECS://my-app/Prod/1234`)                                                              | Yes                                                       |         | `deploy_env`: Prod, Staging, QA, Dev, Sandbox, Custom          |
| &#x2011;&#x2011;deploy_status         | The status of the deployment.                                                                                                                                                      | Yes                                                       |         | Success, Failed, Canceled, Queued, Running, RolledBack, Custom |
| &#x2011;&#x2011;artifact              | The URI of the artifact. (`<artifact_source>://<artifact_organization>/<artifact_repo>/<artifact_id>` e.g. `DockerHub://farosai/my-repo/da500aa4f54cbf8f3eb47a1dc2c136715c9197b9`) | Either &#x2011;&#x2011;commit or &#x2011;&#x2011;artifact |         |                                                                |
| &#x2011;&#x2011;commit                | The URI of the commit. (`<vcs_source>://<vcs_organization>/<vcs_repo>/<commit_sha>` e.g. `GitHub://faros-ai/my-repo/da500aa4f54cbf8f3eb47a1dc2c136715c9197b9`)                     | Either &#x2011;&#x2011;commit or &#x2011;&#x2011;artifact |         |                                                                |
| &#x2011;&#x2011;deploy_app_platform   | The compute platform that runs the application.                                                                                                                                    |                                                           | ""      |                                                                |
| &#x2011;&#x2011;deploy_env_details    | Any extra details about the deployment environment.                                                                                                                                |                                                           | ""      |                                                                |
| &#x2011;&#x2011;deploy_status_details | Any extra details about the status of the deployment.                                                                                                                              |                                                           | ""      |                                                                |
| &#x2011;&#x2011;deploy_start_time     | The start time of the deployment in milliseconds since the epoch. (e.g. `1626804346019`)                                                                                           |                                                           | Now     |                                                                |
| &#x2011;&#x2011;deploy_end_time       | The end time of the deployment in milliseconds since the epoch. (e.g. `1626804346019`)                                                                                             |                                                           | Now     |                                                                |
| &#x2011;&#x2011;run                   | The URI of the job run executing the deployment. (`<ci_source>://<ci_organization>/<ci_pipeline>/<run_id>` e.g. `Jenkins://faros-ai/my-pipeline/1234`)                             |                                                           |         |                                                                |
| &#x2011;&#x2011;run_status            | The status of the job run executing the deployment.                                                                                                                                | If &#x2011;&#x2011;run provided                           |         | Success, Failed, Canceled, Queued, Running, Unknown, Custom    |
| &#x2011;&#x2011;run_name              | The name of the job run executing the deployment.                                                                                                                                  |                                                           | ""      |                                                                |
| &#x2011;&#x2011;run_status_details    | Any extra details about the status of the job run executing the deployment.                                                                                                        |                                                           | ""      |                                                                |
| &#x2011;&#x2011;run_start_time        | The start time of the job run in milliseconds since the epoch. (e.g. `1626804346019`)                                                                                              |                                                           | Now     |                                                                |
| &#x2011;&#x2011;run_end_time          | The end time of the job run in milliseconds since the epoch. (e.g. `1626804346019`)                                                                                                |                                                           | Now     |                                                                |

### :herb: Real life examples

The following sends an event that communicates that a deployment pipeline that is run by `Buildkite` which is called `payments-service-deploy-prod` was successful. It communicated that the application `payments-service` was successfully deployed with `ECS` to the `Prod` environment. It communicates that the artifact that was deployed is stored in `DockerHub` in the `my-app-repo` repository. And Finally it communicates the timestamps for the start and end of both the job run and the deployment.

```sh
$ ./faros_event.sh CD -k "<api_key>" \
    --run "Buildkite://faros-ai/payments-service-deploy-prod/4206ac01-9d2f-437d-992d-8f6857b68378" \
    --run_status "Success" \
    --run_start_time "1626804346000" \
    --run_end_time "1626804358000" \
    --deploy "ECS://payments-service/Prod/d-CGAKEHE8S" \
    --deploy_status "Success" \
    --deploy_start_time "1626804356000" \
    --deploy_end_time "1626804357000" \
    --artifact "DockerHub://farosai/my-app-repo/285071b4d36c49fa699ae87345c3f4e61abba01b" \
```

---

## :hammer: Development

### :white_check_mark: Testing

We use [ShellSpec](https://github.com/shellspec/shellspec) to test our scripts.

#### Install using Homebrew

```sh
brew tap shellspec/shellspec
brew install shellspec
```

#### Running the tests

Move to the `/test` directory and execute `shellspec`

```sh
cd test && shellspec
```
