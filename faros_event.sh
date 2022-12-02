#!/usr/bin/env bash

# This is used for testing purposes. It is a noop unless under testing with shellspec
# See https://github.com/shellspec/shellspec#intercepting for details.
test || __() { :; }

set -eo pipefail

version="0.6.6"
canonical_model_version="0.12.14"
github_url="https://github.com/faros-ai/faros-events-cli"

declare -a arr=("curl" "jq" "sed" "awk")
for i in "${arr[@]}"; do
    which "$i" &> /dev/null ||
        { echo "Error: $i is required." && missing_require=1; }
done

if ((${missing_require:-0})); then
    echo "Please ensure curl, jq, sed, and an implementation of awk (we recommend gawk) are available before running the script."
    exit 1
fi

# Allows the event body to be piped to the scripts
if [ -p /dev/stdin ]; then
    request_body=$(cat)
fi

# Defaults
FAROS_GRAPH_DEFAULT="default"
FAROS_URL_DEFAULT="https://prod.api.faros.ai"
FAROS_ORIGIN_DEFAULT="Faros_Script_Event"
FAROS_MAX_TIME_DEFAULT="10"
FAROS_RETRY_DEFAULT="3"
FAROS_RETRY_DELAY_DEFAULT="1"
FAROS_RETRY_MAX_TIME_DEFAULT="40"
HASURA_URL_DEFAULT="http://localhost:8080"
HASURA_ADMIN_SECRET_DEFAULT="admin"

declare -a ENVS=("Prod" "Staging" "QA" "Dev" "Sandbox" "Canary" "Custom")
envs=$(printf '%s\n' "$(IFS=,; printf '%s' "${ENVS[*]}")")
declare -a BUILD_STATUSES=("Success" "Failed" "Canceled" "Queued" "Running" "Unknown" "Custom")
run_statuses=$(printf '%s\n' "$(IFS=,; printf '%s' "${BUILD_STATUSES[*]}")")
declare -a DEPLOY_STATUSES=("Success" "Failed" "Canceled" "Queued" "Running" "RolledBack" "Custom")
deploy_statuses=$(printf '%s\n' "$(IFS=,; printf '%s' "${DEPLOY_STATUSES[*]}")")
declare -a TEST_TYPES=("Functional" "Integration" "Manual" "Performance" "Regression" "Security" "Unit" "Custom")
test_types=$(printf '%s\n' "$(IFS=,; printf '%s' "${TEST_TYPES[*]}")")
declare -a TEST_STATUSES=("Custom" "Failure" "Skipped" "Success" "Unknown")
test_statuses=$(printf '%s\n' "$(IFS=,; printf '%s' "${TEST_STATUSES[*]}")")

commit_uri_form="source://organization/repository/commit_sha"
artifact_uri_form="source://organization/repository/artifact_id"
run_uri_form="source://organization/pipeline/run_id"
deploy_uri_form="source://application/environment/deploy_id"

# Script settings' defaults
dry_run=${FAROS_DRY_RUN:-0}
silent=${FAROS_SILENT:-0}
debug=${FAROS_DEBUG:-0}
no_format=${FAROS_NO_FORMAT:-0}
community_edition=${FAROS_COMMUNITY_EDITION:-0}

# Theme
RED='\033[0;31m'
BLUE='\033[0;34m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

function help() {
    printf "${BLUE}  _____                          ${RED}  _     ___\\n"
    printf "${BLUE} |  ___|__ _  _ __  ___   ___    ${RED} / \\   |_ _| (v$version)\\n"
    printf "${BLUE} | |_  / _\` || '__|/ _ \\ / __| ${RED}  / _ \\   | |\\n"
    printf "${BLUE} |  _|| (_| || |  | (_) |\\__ \\ ${RED} / ___ \\  | |\\n"
    printf "${BLUE} |_|   \\__,_||_|   \\___/ |___/ ${RED}/_/   \\_\\|___|\\n"
    printf "${NC}\\n"
    printf "${RED}Canonical Model Version: v$canonical_model_version ${NC}\\n"
    echo
    echo "This script sends information to Faros."
    echo "There are multiple event types that can be used, each with a set of required"
    echo "and optional fields."
    echo
    printf "${RED}Event Types:${NC}\\n"
    echo "CI"
    echo "CD"
    echo "TestExecution"
    echo
    printf "${BLUE}Example Event:${NC}\\n"
    echo "./faros_event.sh CD -k \"<faros_api_key>\" \\"
    echo "--artifact \"$artifact_uri_form\" \\"
    echo "--deploy \"$deploy_uri_form\" \\"
    echo "--deploy_status \"Success\""
    echo
    printf "${RED}Arguments:${NC}\\n"
    echo "Arguments can be provided either by flag or by environment variable."
    echo "By convention, you can switch to using environment variables by prefixing the"
    echo "flag name with 'FAROS_'. For example, --commit becomes FAROS_COMMIT and"
    echo "--deploy becomes FAROS_DEPLOY"
    echo "-----------------------------------------------------------------------------"
    echo "Argument                | Req |  Default Value"
    echo "-----------------------------------------------------------------------------"
    echo "-k / --api_key          | *1  |"
    echo "-u / --url              |     | $FAROS_URL_DEFAULT ($HASURA_URL_DEFAULT if --community_edition specified)"
    echo "--hasura_admin_secret   |     | \"$HASURA_ADMIN_SECRET_DEFAULT\" (only used if --community_edition specified)"
    echo "-g / --graph            |     | \"$FAROS_GRAPH_DEFAULT\""
    echo "--origin                |     | \"$FAROS_ORIGIN_DEFAULT\""
    echo "*1 Unless --community_edition specified"
    echo
    printf "${BLUE}CI Event Arguments:${NC}\\n"
    echo "-----------------------------------------------------------------------------"
    echo "Argument                | Req | Allowed Values / URI form"
    echo "-----------------------------------------------------------------------------"
    echo "--commit                | Yes | $commit_uri_form"
    echo "--pull_request_number   |     | e.g. 123 (should be a number)"
    echo "--artifact              |     | $artifact_uri_form"
    echo "--run                   |     | $run_uri_form"
    echo "--run_status            | *1  | $run_statuses"
    echo "--run_status_details    |     |"
    echo "--run_name              |     |"
    echo "--run_start_time        |     | e.g. 1626804346019 (milliseconds since epoch)"
    echo "--run_end_time          |     | e.g. 1626804346019 (milliseconds since epoch)"
    echo "*1 If --run included"
    echo
    printf "${BLUE}CD Event Arguments:${NC}\\n"
    echo "-----------------------------------------------------------------------------"
    echo "Argument                | Req | Allowed Values / URI form"
    echo "-----------------------------------------------------------------------------"
    echo "--deploy                | Yes | $deploy_uri_form *1"
    echo "--deploy_status         | Yes | $deploy_statuses"
    echo "--artifact              | *2  | $artifact_uri_form"
    echo "--commit                | *2  | $commit_uri_form"
    echo "--deploy_url            |     |"
    echo "--deploy_status_details |     |"
    echo "--deploy_env_details    |     |"
    echo "--deploy_app_platform   |     |"
    echo "--deploy_app_tags       |     | e.g. key1:value1,key2:value2"
    echo "--deploy_app_paths      |     | e.g. path1,path2"
    echo "--deploy_requested_at   |     | e.g. 1626804346019 (milliseconds since epoch)"
    echo "--deploy_start_time     |     | e.g. 1626804346019 (milliseconds since epoch)"
    echo "--deploy_end_time       |     | e.g. 1626804346019 (milliseconds since epoch)"
    echo "--pull_request_number   |     | *3 e.g. 123 (should be a number)"
    echo "--run                   |     | $run_uri_form"
    echo "--run_status            | *4  | $run_statuses"
    echo "--run_status_details    |     |"
    echo "--run_name              |     |"
    echo "--run_start_time        |     | e.g. 1626804346019 (milliseconds since epoch)"
    echo "--run_end_time          |     | e.g. 1626804346019 (milliseconds since epoch)"
    echo "*1 environment must be: $envs"
    echo "*2 Either --artifact or --commit required"
    echo "*3 Used only if --commit is included"
    echo "*4 If --run included"
    echo
    printf "${BLUE}Test Execution Event Arguments:${NC}\\n"
    echo "-----------------------------------------------------------------------------"
    echo "Argument                | Req | Allowed Values / URI form"
    echo "-----------------------------------------------------------------------------"
    echo "--commit                | Yes | $commit_uri_form"
    echo "--pull_request_number   |     | e.g. 123 (should be a number)"
    echo "--test_id               | Yes |"
    echo "--test_source           | Yes |"
    echo "--test_type             | Yes | $test_types"
    echo "--test_type_details     |     |"
    echo "--test_status           | Yes | $test_statuses"
    echo "--test_status_details   |     |"
    echo "--test_suite            | Yes | e.g. My test suite name"
    echo "--test_stats            |     | e.g. failure=N,success=N,skipped=N,unknown=N,custom=N,total=N"
    echo "--test_tags             |     | e.g. tag1,tag2,tag3"
    echo "--environments          |     | e.g. env1,env2,env3"
    echo "--device_name           |     | e.g. MacBook"
    echo "--device_os             |     | e.g. OSX"
    echo "--device_browser        |     | e.g. Chrome"
    echo "--device_type           |     |"
    echo "--test_start_time       |     | e.g. 1626804346019 (milliseconds since epoch)"
    echo "--test_end_time         |     | e.g. 1626804346019 (milliseconds since epoch)"
    echo "--test_task             |     | e.g. TEST-123=Success,TEST-456 *2"
    echo "--defect_task           |     | e.g. TEST-123"
    echo "--test_suite_task       |     | e.g. TEST-123"
    echo "--test_execution_task   |     | e.g. TEST-123"
    echo "--task_source           | *1  | e.g. Jira"
    echo "*1 If --test_task, --defect_task, --test_suite_task, or --test_execution_task included"
    echo "*2 Allowed statuses: $test_statuses"
    echo
    echo "Additional Settings:"
    echo "--dry_run           Do not send the event."
    echo "--silent            Unexceptional output will be silenced."
    echo "--debug             Helpful information will be printed."
    echo "--no_format         Log formatting will be turned off."
    echo "--request_body      The explicit request body to send to the event API."
    echo "--full              Event should be validated as a full event."
    echo "--skip-saving-run   Do not include a cicd_Build in event."
    echo "--validate_only     Only validate event body against event api."
    echo "--community_edition Format and send event to Faros Community Edition."
    echo "--max-time          The time in seconds allowed for each retry attempt"
    echo "--retry             The number of allowed retry attempts"
    echo "--retry-delay       The delay in seconds between each retry attempt"
    echo "--retry-max-time    The total time in seconds the request with retries can take"
    echo
    echo "For more usage information please visit: $github_url"
    exit 0
}

function parseFlags() {
    while (($#)); do
        case "$1" in
            -k|--api_key)              api_key="$2"                 && shift 2 ;;
            --artifact)                artifact_uri="$2"            && shift 2 ;;
            --artifact_id)             artifact_id="$2"             && shift 2 ;;
            --artifact_repo)           artifact_repo="$2"           && shift 2 ;;
            --artifact_org)            artifact_org="$2"            && shift 2 ;;
            --artifact_source)         artifact_source="$2"         && shift 2 ;;
            --commit)                  commit_uri="$2"              && shift 2 ;;
            --commit_sha)              commit_sha="$2"              && shift 2 ;;
            --commit_repo)             commit_repo="$2"             && shift 2 ;;
            --commit_org)              commit_org="$2"              && shift 2 ;;
            --commit_source)           commit_source="$2"           && shift 2 ;;
            --branch)                  branch="$2"                  && shift 2 ;;
            --pull_request_number)     pull_request_number="$2"     && shift 2 ;;
            --deploy)                  deploy_uri="$2"              && shift 2 ;;
            --deploy_id)               deploy_id="$2"               && shift 2 ;;
            --deploy_env)              deploy_env="$2"              && shift 2 ;;
            --deploy_app)              deploy_app="$2"              && shift 2 ;;
            --deploy_source)           deploy_source="$2"           && shift 2 ;;
            --deploy_app_platform)     deploy_app_platform="$2"     && shift 2 ;;
            --deploy_app_tags)         deploy_app_tags="$2"         && shift 2 ;;
            --deploy_app_paths)        deploy_app_paths="$2"        && shift 2 ;;
            --deploy_url)              deploy_url="$2"              && shift 2 ;;
            --deploy_env_details)      deploy_env_details="$2"      && shift 2 ;;
            --deploy_status)           deploy_status="$2"           && shift 2 ;;
            --deploy_status_details)   deploy_status_details="$2"   && shift 2 ;;
            --deploy_requested_at)     deploy_requested_at="$2"     && shift 2 ;;
            --deploy_start_time)       deploy_start_time="$2"       && shift 2 ;;
            --deploy_end_time)         deploy_end_time="$2"         && shift 2 ;;
            --test_id)                 test_id="$2"                 && shift 2 ;;
            --test_source)             test_source="$2"             && shift 2 ;;
            --test_type)               test_type="$2"               && shift 2 ;;
            --test_type_details)       test_type_details="$2"       && shift 2 ;;
            --test_status)             test_status="$2"             && shift 2 ;;
            --test_status_details)     test_status_details="$2"     && shift 2 ;;
            --test_suite)              test_suite="$2"              && shift 2 ;;
            --test_stats)              test_stats="$2"              && shift 2 ;;
            --test_tags)               test_tags="$2"               && shift 2 ;;
            --environments)            environments="$2"            && shift 2 ;;
            --device_name)             device_name="$2"             && shift 2 ;;
            --device_os)               device_os="$2"               && shift 2 ;;
            --device_browser)          device_browser="$2"          && shift 2 ;;
            --device_type)             device_type="$2"             && shift 2 ;;
            --test_start_time)         test_start_time="$2"         && shift 2 ;;
            --test_end_time)           test_end_time="$2"           && shift 2 ;;
            --test_task)               test_task="$2"               && shift 2 ;;
            --defect_task)             defect_task="$2"             && shift 2 ;;
            --test_suite_task)         test_suite_task="$2"         && shift 2 ;;
            --test_execution_task)     test_execution_task="$2"     && shift 2 ;;
            --task_source)             task_source="$2"             && shift 2 ;;
            --run)                     run_uri="$2"                 && shift 2 ;;
            --run_id)                  run_id="$2"                  && shift 2 ;;
            --run_pipeline)            run_pipeline="$2"            && shift 2 ;;
            --run_org)                 run_org="$2"                 && shift 2 ;;
            --run_source)              run_source="$2"              && shift 2 ;;
            --run_name)                run_name="$2"                && shift 2 ;;
            --run_status)              run_status="$2"              && shift 2 ;;
            --run_status_details)      run_status_details="$2"      && shift 2 ;;
            --run_start_time)          run_start_time="$2"          && shift 2 ;;
            --run_end_time)            run_end_time="$2"            && shift 2 ;;
            --run_step_id)             run_step_id="$2"             && shift 2 ;;
            --run_step_name)           run_step_name="$2"           && shift 2 ;;
            --run_step_type)           run_step_type="$2"           && shift 2 ;;
            --run_step_type_details)   run_step_type_details="$2"   && shift 2 ;;
            --run_step_command)        run_step_command="$2"        && shift 2 ;;
            --run_step_start_time)     run_step_start_time="$2"     && shift 2 ;;
            --run_step_end_time)       run_step_end_time="$2"       && shift 2 ;;
            --run_step_status)         run_step_status="$2"         && shift 2 ;;
            --run_step_status_details) run_step_status_details="$2" && shift 2 ;;
            --run_step_url)            run_step_url="$2"            && shift 2 ;;
            -g|--graph)                graph="$2"                   && shift 2 ;;
            --origin)                  origin="$2"                  && shift 2 ;;
            -u|--url)                  url="$2"                     && shift 2 ;;
            --request_body)            request_body="$2"            && shift 2 ;;
            --hasura_admin_secret)     hasura_admin_secret="$2"     && shift 2 ;;
            --dry_run)                 dry_run=1                    && shift ;;
            --full)                    full="true"                  && shift ;;
            --no_build_object)
                warn "no_build_object flag is deprecated, use skip_saving_run"
                skip_saving_run="true"
                shift ;;
            --skip_saving_run)          skip_saving_run="true"      && shift ;;
            --validate_only)            validate_only="true"        && shift ;;
            -s|--silent)                silent=1                    && shift ;;
            --max_time)                 max_time="$2"               && shift 2 ;;
            --retry)                    retry="$2"                  && shift 2 ;;
            --retry_delay)              retry_delay="$2"            && shift 2 ;;
            --retry_max_time)           retry_max_time="$2"         && shift 2 ;;
            --debug)                    debug=1                     && shift ;;
            --no_format)                no_format=1                 && shift ;;
            --community_edition)        community_edition=1         && shift ;;
            --help)                     help ;;
            -v|--version)               echo "$version" exit 0 ;;
            *)
                POSITIONAL+=("$1") # save it in an array for later
                shift ;;
        esac
    done
}

# Determine which event types are present
function processArgs() {
    # No positional arg passed - show help
    if ! (($#)) || [ "$1" == "help" ]; then
        help
        exit 0
    fi

    ci_event=0
    cd_event=0
    test_execution_event=0

    # loop through positional args
    while (($#)); do
        case "$1" in
            CI)
                ci_event=1
                shift ;;
            CD)
                cd_event=1
                shift ;;
            TestExecution)
                test_execution_event=1
                shift ;;
            help)
                help
                exit 0 ;;
            *)
                UNRECOGNIZED+=("$1")
                shift ;;
        esac
    done

    if [ -n "${UNRECOGNIZED:-}" ]; then
        err "Unrecognized arg(s): ${UNRECOGNIZED[*]}"
        fail
    fi
}

# Resolve input and populate event depending on present event types
# Only one event should be considered per execution
function processEventTypes() {
    if ((ci_event)); then
        event_type="CI"
        makeEvent
        resolveCIInput
        addArtifactToData
        addCommitToData
        addRunToData
        addRunStepToData
    elif ((cd_event)); then
        event_type="CD"
        makeEvent
        resolveCDInput
        addDeployToData
        addArtifactToData
        addCommitToData
        addRunToData
    elif ((test_execution_event)); then
        event_type="TestExecution"
        makeEvent
        resolveTestExecutionInput
        addTestToData
        addCommitToData
    else
        err "Event type must be provided"
        fail
    fi
}

function now_as_iso8601() {
    jq -nr 'now | todate'
}

# Attempt to convert to iso8601 format
# Converts from Unix millis or the literal 'Now'
# Anything else is returned unchanged
function convert_to_iso8601() {
    if [[ "$1" =~ ^[0-9]+$ ]]; then
        jq -r '. / 1000 | todate' <<< "$1"
    elif [[ "$1" =~ ^Now$ ]]; then
        __ begin __
        now_as_iso8601
    else
        echo "$1"
    fi
}

function make_commit_key() {
    jq '{data_commit_sha,data_commit_repository,data_commit_organization,data_commit_source}' <<< "$flat"
}

function make_artifact_key() {
    if ! [ -z "$has_artifact" ]; then
        keys_matching "$flat" "data_artifact_(id|repository|organization|source)"
    else
        jq -n \
          --arg commit_sha "$commit_sha" \
          --arg commit_repo "$commit_repo" \
          --arg commit_org "$commit_org" \
          --arg commit_source "$commit_source" \
          '{
              "data_artifact_id": $commit_sha,
              "data_artifact_repository": $commit_repo,
              "data_artifact_organization": $commit_org,
              "data_artifact_source": $commit_source,
          }'
    fi
}

function doPullRequestCommitMutation() {
    if ! [ -z "$has_commit" ] && ! [ -z "$pull_request_number" ]; then
        pull_request=$(jq -n \
            --arg pull_request_number "$pull_request_number" \
            '{
                "data_pull_request_uid": $pull_request_number,
                "data_pull_request_number": $pull_request_number|tonumber,
            }'
        )
        pull_request_commit=$(concat "$pull_request" "$commit_key")
        make_mutation vcs_pull_request_commit "$pull_request_commit"
    fi
}

function doCDMutations() {
    flat=$(flatten "$request_body")

    app_platform="${deploy_app_platform:-}"
    if [ -z "${app_platform}" ]; then
        app_uid="$deploy_app"
    else
        app_uid="${deploy_app}_${app_platform}"
    fi

    compute_Application=$(jq -n \
        --arg name "$deploy_app" \
        --arg platform "${app_platform}" \
        --arg app_uid "${app_uid}" \
        '{
            "name": $name,
            "platform": $platform,
            "uid": $app_uid
        }'
    )
    make_mutation compute_application "$compute_Application"

    cicd_Deployment_base=$(keys_matching "$flat" "data_deploy_(id|source)")
    status_env=$(jq -n \
        --arg status_category "$deploy_status" \
        --arg status_detail "${deploy_status_details:-}" \
        --arg env_category "$deploy_env" \
        --arg env_detail "${deploy_env_details:-}" \
        --arg app_uid "${app_uid}" \
        '{
            "status": {"category" : $status_category, "detail" : $status_detail},
            "env": {"category" : $env_category, "detail" : $env_detail},
            "compute_Application": $app_uid
        }'
    )
    cicd_Deployment_base=$(concat "$cicd_Deployment_base" "$status_env")
    if ! [ -z "$deploy_start_time" ] && ! [ -z "$deploy_end_time" ]; then
        start_end=$(jq -n \
            --arg start_time "$deploy_start_time" \
            --arg end_time "$deploy_end_time" \
            '{
                "deploy_start_time": $start_time,
                "deploy_end_time": $end_time,
            }'
        )
    else
        start_end=$(jq -n \
            '{
                "deploy_start_time": null,
                "deploy_end_time": null,
            }'
        )
    fi
    cicd_Deployment_with_start_end=$(concat "$cicd_Deployment_base" "$start_end")

    artifact_key=$(make_artifact_key)

    cicd_ArtifactDeployment=$(keys_matching "$flat" "data_deploy_(id|source)")
    cicd_ArtifactDeployment=$(concat "$cicd_ArtifactDeployment" "$artifact_key")
    make_mutation cicd_artifact_deployment "$cicd_ArtifactDeployment"

    if ! [ -z "$has_run" ]; then
        make_mutations_from_run

        cicd_Deployment=$(concat "$cicd_Deployment_with_start_end" "$buildKey")
        make_mutation cicd_deployment_with_build "$cicd_Deployment"
    else
        make_mutation cicd_deployment "$cicd_Deployment_with_start_end"
    fi

    if [ -z "$has_artifact" ]; then
        if ! [ -z "$has_run" ]; then
            cicd_Artifact_with_build=$(concat "$artifact_key" "$buildKey")
            make_mutation cicd_artifact_with_build "$cicd_Artifact_with_build"
        else
            make_mutation cicd_artifact "$artifact_key"
        fi

        commit_key=$(make_commit_key)
        cicd_ArtifactCommitAssociation=$(concat "$artifact_key" "$commit_key")
        make_mutation cicd_artifact_commit_association "$cicd_ArtifactCommitAssociation"
    fi

    doPullRequestCommitMutation
}

function make_mutations_from_run {
    buildKey=$(jq \
        '{data_run_id,data_run_pipeline,data_run_organization,data_run_source}' <<< "$flat"
    )
    if ! (($skip_saving_run)); then
        if [ -z "$has_run_status" ]; then
            err "Please provided --run_status"
            fail
        fi
        if ! [ -z "$has_run_start_time" ] && ! [ -z "$has_run_end_time" ]; then
            cicd_Build_with_start_end=$(jq -n \
                --arg run_status "$run_status" \
                --arg run_status_details "$run_status_details" \
                --arg run_start_time "$run_start_time" \
                --arg run_end_time "$run_end_time" \
                '{
                    "run_status": {"category": $run_status, "detail": $run_status_details},
                    "run_start_time": $run_start_time,
                    "run_end_time": $run_end_time,
                }'
            )
            cicd_Build_with_start_end=$(concat "$cicd_Build_with_start_end" "$buildKey")
            make_mutation cicd_build_with_start_end "$cicd_Build_with_start_end"
        else
            cicd_Build=$(jq -n \
                --arg run_status "$run_status" \
                --arg run_status_details "$run_status_details" \
                '{
                    "run_status": {"category": $run_status, "detail": $run_status_details},
                }'
            )
            cicd_Build=$(concat "$cicd_Build" "$buildKey")
            make_mutation cicd_build "$cicd_Build"
        fi

        cicd_Pipeline=$(jq \
            '{data_run_pipeline,data_run_organization,data_run_source}' <<< "$flat"
        )
        make_mutation cicd_pipeline "$cicd_Pipeline"

        cicd_Organization_from_run=$(jq \
            '{data_run_organization,data_run_source}' <<< "$flat"
        )
        make_mutation cicd_organization_from_run "$cicd_Organization_from_run"
    fi
}

function doCIMutations() {
    flat=$(flatten "$request_body")

    artifact_key=$(make_artifact_key)
    commit_key=$(make_commit_key)

    if ! [ -z "$has_run" ]; then
        make_mutations_from_run

        cicd_Artifact_with_build=$(concat "$artifact_key" "$buildKey")
        make_mutation cicd_artifact_with_build "$cicd_Artifact_with_build"
    else
        make_mutation cicd_artifact "$artifact_key"
    fi

    cicd_ArtifactCommitAssociation=$(concat "$artifact_key" "$commit_key")
    make_mutation cicd_artifact_commit_association "$cicd_ArtifactCommitAssociation"

    cicd_Repository=$(jq \
        '{data_artifact_repository,data_artifact_organization,data_artifact_source}' <<< "$artifact_key"
    )
    make_mutation cicd_repository "$cicd_Repository"

    cicd_Organization=$(jq \
        '{data_artifact_organization,data_artifact_source}' <<< "$artifact_key"
    )
    make_mutation cicd_organization "$cicd_Organization"

    doPullRequestCommitMutation
}

function make_mutation() {
    entity_origin=$(jq -n \
        --arg data_origin "$origin" \
        '{"data_origin": $data_origin}'
    )
    data=$(concat "$2" "$entity_origin")
    log Calling Hasura rest endpoint "$1" with payload "$data"

    if ! ((dry_run)); then
        log "Sending mutation to Hasura..."

        http_response=$(curl -s -S --retry 5 --retry-delay 5 \
            --write-out "HTTPSTATUS:%{http_code}" -X POST \
            "$url/api/rest/$1" \
            -H "content-type: application/json" \
            -H "X-Hasura-Admin-Secret: $hasura_admin_secret" \
            -d "$data")

        http_response_status=$(echo "$http_response" | tr -d '\n' | sed -e 's/.*HTTPSTATUS://')
        http_response_body=$(echo "$http_response" | sed -e 's/HTTPSTATUS\:.*//g')

        if [ ! "$http_response_status" -eq 200 ]; then
            err "[HTTP status: $http_response_status]"
            err "Response Body:"
            err "$http_response_body"
            fail
        else
            log "[HTTP status OK: $http_response_status]"
            log "Response Body:"
            log "$http_response_body"
        fi
    else
        log "Dry run: Mutation NOT sent to Faros."
    fi
}

function keys_matching() {
    jq --arg regexp "$2" \
      'with_entries(if (.key|test($regexp)) then ( {key: .key, value: .value } ) else empty end )' <<< "$1"
}

function concat() {
    jq --argjson json_2 "$2" '.+=$json_2' <<< "$1"
}

function flatten() {
    jq '[paths(scalars) as $path | { ($path | map(tostring) | join("_")): getpath($path) } ] | add' <<< "$1"
}

function resolveDefaults() {
    FAROS_GRAPH=${FAROS_GRAPH:-$FAROS_GRAPH_DEFAULT}
    FAROS_URL=${FAROS_URL:-$FAROS_URL_DEFAULT}
    FAROS_ORIGIN=${FAROS_ORIGIN:-$FAROS_ORIGIN_DEFAULT}
    HASURA_URL=${HASURA_URL:-$HASURA_URL_DEFAULT}
    HASURA_ADMIN_SECRET=${HASURA_ADMIN_SECRET:-$HASURA_ADMIN_SECRET_DEFAULT}
    FAROS_MAX_TIME=${FAROS_MAX_TIME:-$FAROS_MAX_TIME_DEFAULT}
    FAROS_RETRY=${FAROS_RETRY:-$FAROS_RETRY_DEFAULT}
    FAROS_RETRY_DELAY=${FAROS_RETRY_DELAY:-$FAROS_RETRY_DELAY_DEFAULT}
    FAROS_RETRY_MAX_TIME=${FAROS_RETRY_MAX_TIME:-$FAROS_RETRY_MAX_TIME_DEFAULT}
}

function resolveInput() {
    # Required fields:
    if ! [ -z ${api_key+x} ] || ! [ -z ${FAROS_API_KEY+x} ]; then
        api_key=${api_key:-$FAROS_API_KEY}
    else
        if ! ((community_edition)); then
            err "A Faros API key must be provided"
            fail
        fi
    fi

    # Optional fields:
    resolveDefaults
    graph=${graph:-$FAROS_GRAPH}
    origin=${origin:-$FAROS_ORIGIN}
    request_body=${request_body:-$FAROS_REQUEST_BODY}
    if ! ((community_edition)); then
        url=${url:-$FAROS_URL}
    else
        url=${url:-$HASURA_URL}
        hasura_admin_secret=${hasura_admin_secret:-$HASURA_ADMIN_SECRET}
    fi

    # Curl settings
    max_time=${max_time:-$FAROS_MAX_TIME}
    retry=${retry:-$FAROS_RETRY}
    retry_delay=${retry_delay:-$FAROS_RETRY_DELAY}
    retry_max_time=${retry_max_time:-$FAROS_RETRY_MAX_TIME}

    # Optional script settings: If unset then false
    no_lowercase_vcs=${no_lowercase_vcs:-0}
    full=${full:-"false"}
    skip_saving_run=${skip_saving_run:-"false"}
    validate_only=${validate_only:-"false"}
}

function resolveCDInput() {
    resolveDeployInput
    resolveArtifactInput
    resolveCommitInput
    resolveRunInput
}

function resolveCIInput() {
    resolveArtifactInput
    resolveCommitInput
    resolveRunInput
}

function resolveTestExecutionInput() {
    resolveTestInput
    resolveCommitInput
}

function resolveDeployInput() {
    deploy_uri=${deploy_uri:-$FAROS_DEPLOY}
    if ((community_edition)); then
        parseDeployUri
    fi
    deploy_id=${deploy_id:-$FAROS_DEPLOY_ID}
    deploy_app=${deploy_app:-$FAROS_DEPLOY_APP}
    deploy_url=${deploy_url:-$FAROS_DEPLOY_URL}
    deploy_env=${deploy_env:-$FAROS_DEPLOY_ENV}
    deploy_source=${deploy_source:-$FAROS_DEPLOY_SOURCE}
    deploy_status=${deploy_status:-$FAROS_DEPLOY_STATUS}
    deploy_app_platform=${deploy_app_platform:-$FAROS_DEPLOY_APP_PLATFORM}
    deploy_app_tags=${deploy_app_tags:-$FAROS_DEPLOY_APP_TAGS}
    deploy_app_paths=${deploy_app_paths:-$FAROS_DEPLOY_APP_PATHS}
    deploy_env_details=${deploy_env_details:-$FAROS_DEPLOY_ENV_DETAILS}
    deploy_status_details=${deploy_status_details:-$FAROS_DEPLOY_STATUS_DETAILS}
    deploy_requested_at=${deploy_requested_at:-$FAROS_DEPLOY_REQUESTED_AT}
    deploy_start_time=${deploy_start_time:-$FAROS_DEPLOY_START_TIME}
    deploy_end_time=${deploy_end_time:-$FAROS_DEPLOY_END_TIME}

    if ! [ -z "$deploy_requested_at" ]; then
        deploy_requested_at=$(convert_to_iso8601 "$deploy_requested_at")
    fi
    if ! [ -z "$deploy_start_time" ]; then
        deploy_start_time=$(convert_to_iso8601 "$deploy_start_time")
    fi
    if ! [ -z "$deploy_end_time" ]; then
        deploy_end_time=$(convert_to_iso8601 "$deploy_end_time")
    fi
}

function resolveArtifactInput() {
    artifact_uri=${artifact_uri:-$FAROS_ARTIFACT}
    if ((community_edition)); then
        parseArtifactUri
    fi
    artifact_id=${artifact_id:-$FAROS_ARTIFACT_ID}
    artifact_repo=${artifact_repo:-$FAROS_ARTIFACT_REPO}
    artifact_org=${artifact_org:-$FAROS_ARTIFACT_ORG}
    artifact_source=${artifact_source:-$FAROS_ARTIFACT_SOURCE}
}

function resolveCommitInput() {
    commit_uri=${commit_uri:-$FAROS_COMMIT}
    if ((community_edition)); then
        parseCommitUri
    fi
    commit_sha=${commit_sha:-$FAROS_COMMIT_SHA}
    commit_repo=${commit_repo:-$FAROS_COMMIT_REPO}
    commit_org=${commit_org:-$FAROS_COMMIT_ORG}
    commit_source=${commit_source:-$FAROS_COMMIT_SOURCE}
    branch=${branch:-$FAROS_BRANCH}
    pull_request_number=${pull_request_number:-$FAROS_PULL_REQUEST_NUMBER}
}

function resolveRunInput() {
    run_uri=${run_uri:-$FAROS_RUN}
    if ((community_edition)); then
        parseRunUri
    fi
    run_id=${run_id:-$FAROS_RUN_ID}
    run_pipeline=${run_pipeline:-$FAROS_RUN_PIPELINE}
    run_org=${run_org:-$FAROS_RUN_ORG}
    run_source=${run_source:-$FAROS_RUN_SOURCE}
    run_status=${run_status:-$FAROS_RUN_STATUS}
    run_name=${run_name:-$FAROS_RUN_NAME}
    run_status_details=${run_status_details:-$FAROS_RUN_STATUS_DETAILS}
    run_start_time=${run_start_time:-$FAROS_RUN_START_TIME}
    run_end_time=${run_end_time:-$FAROS_RUN_END_TIME}
    run_step_id=${run_step_id:-$FAROS_RUN_STEP_ID}
    run_step_name=${run_step_name:-$FAROS_RUN_STEP_NAME}
    run_step_type=${run_step_type:-$FAROS_RUN_STEP_TYPE}
    run_step_type_details=${run_step_type_details:-$FAROS_RUN_STEP_TYPE_DETAILS}
    run_step_status=${run_step_status:-$FAROS_RUN_STEP_STATUS}
    run_step_status_details=${run_step_status_details:-$FAROS_RUN_STEP_STATUS_DETAILS}
    run_step_command=${run_step_command:-$FAROS_RUN_STEP_COMMAND}
    run_step_url=${run_step_url:-$FAROS_RUN_STEP_URL}
    run_step_start_time=${run_step_start_time:-$FAROS_RUN_STEP_START_TIME}
    run_step_end_time=${run_step_end_time:-$FAROS_RUN_STEP_END_TIME}

    if ! [ -z "$run_status" ]; then
        has_run_status=1
    fi
    if ! [ -z "$run_start_time" ]; then
        has_run_start_time=1
        run_start_time=$(convert_to_iso8601 "$run_start_time")
    fi
    if ! [ -z "$run_end_time" ]; then
        has_run_end_time=1
        run_end_time=$(convert_to_iso8601 "$run_end_time")
    fi
    if ! [ -z "$run_step_start_time" ]; then
        run_step_start_time=$(convert_to_iso8601 "$run_step_start_time")
    fi
    if ! [ -z "$run_step_end_time" ]; then
        run_step_end_time=$(convert_to_iso8601 "$run_step_end_time")
    fi
}

function resolveTestInput() {
    test_id=${test_id:-$FAROS_TEST_ID}
    test_source=${test_source:-$FAROS_TEST_SOURCE}
    test_type=${test_type:-$FAROS_TEST_TYPE}
    test_type_details=${test_type_details:-$FAROS_TEST_TYPE_DETAILS}
    test_status=${test_status:-$FAROS_TEST_STATUS}
    test_status_details=${test_status_details:-$FAROS_TEST_STATUS_DETAILS}
    test_suite=${test_suite:-$FAROS_TEST_SUITE}
    test_stats=${test_stats:-$FAROS_TEST_STATS}
    test_tags=${test_tags:-$FAROS_TEST_TAGS}
    environments=${environments:-$FAROS_ENVIRONMENTS}
    device_name=${device_name:-$FAROS_DEVICE_NAME}
    device_os=${device_os:-$FAROS_DEVICE_OS}
    device_browser=${device_browser:-$FAROS_DEVICE_BROWSER}
    device_type=${device_type:-$FAROS_DEVICE_TYPE}
    test_start_time=${test_start_time:-$FAROS_TEST_START_TIME}
    test_end_time=${test_end_time:-$FAROS_TEST_END_TIME}
    test_task=${test_task:-$FAROS_TEST_TASK}
    defect_task=${defect_task:-$FAROS_DEFECT_TASK}
    test_suite_task=${test_suite_task:-$FAROS_TEST_SUITE_TASK}
    test_execution_task=${test_execution_task:-$FAROS_TEST_EXECUTION_TASK}
    task_source=${task_source:-$FAROS_TASK_SOURCE}

    if ! [ -z "$test_start_time" ]; then
        test_start_time=$(convert_to_iso8601 "$test_start_time")
    fi
    if ! [ -z "$test_end_time" ]; then
        test_end_time=$(convert_to_iso8601 "$test_end_time")
    fi
}

# Parses a uri of the form:
# value_A://value_B/value_C/value_D
# arg1: The env var name in which to store value_A
# arg2: The env var name in which to store value_B
# arg3: The env var name in which to store value_C
# arg4: The env var name in which to store value_D
# arg5: The form of the URI to communicate when parsing fails
# arg6: The uri to parse
function parseUri() {
    valid_chars="a-zA-Z0-9_.<>-"
    uri_regex="^[$valid_chars]+:\/\/[$valid_chars]+\/[$valid_chars]+\/[$valid_chars]+$"
    if ! [ -z "$6" ]; then
        if [[ "$6" =~ $uri_regex ]]; then
            export "$1"="$(sed 's/:.*//' <<< "$6")"
            export "$2"="$(sed 's/.*:\/\/\(.*\)\/.*\/.*/\1/' <<< "$6")"
            export "$3"="$(sed 's/.*:\/\/.*\/\(.*\)\/.*/\1/' <<< "$6")"
            export "$4"="$(sed 's/.*:\/\/.*\/.*\///' <<< "$6")"
        else
            err "Resource URI could not be parsed: [$6] The URI should be of the form: $5"
            fail
        fi
    fi
}

function parseCommitUri() {
    parseUri "commit_source" "commit_org" "commit_repo" "commit_sha" "$commit_uri_form" "$commit_uri"
    if ! [ -z "$commit_source" ] && ! [ -z "$commit_org" ] && ! [ -z "$commit_repo" ] && ! [ -z "$commit_sha" ]; then
        has_commit=1
    fi
}

function parseRunUri() {
    parseUri "run_source" "run_org" "run_pipeline" "run_id" "$run_uri_form" "$run_uri"
    if ! [ -z "$run_source" ] && ! [ -z "$run_org" ] && ! [ -z "$run_pipeline" ] && ! [ -z "$run_id" ]; then
        has_run=1
    fi
}

function parseDeployUri() {
    parseUri "deploy_source" "deploy_app" "deploy_env" "deploy_id" $deploy_uri_form "$deploy_uri"
}

function parseArtifactUri() {
    parseUri "artifact_source" "artifact_org" "artifact_repo" "artifact_id" "$artifact_uri_form" "$artifact_uri"
    if ! [ -z "$artifact_source" ] && ! [ -z "$artifact_org" ] && ! [ -z "$artifact_repo" ] && ! [ -z "$artifact_id" ]; then
        has_artifact=1
    fi
}

function makeEvent() {
    request_body=$(jq -n \
        --arg origin "$origin" \
        --arg event_type "$event_type" \
        '{
            "type": $event_type,
            "version": "0.0.1",
            "origin": $origin,
        }'
    )
}

function tryAddToEvent() {
    if ! [ -z "$2" ]; then
        request_body=$(jq \
            --argjson path "$1" \
            --arg val "$2" \
            'getpath($path) += $val' <<< "$request_body"
        )
    fi
}

function addDeployToData() {
    tryAddToEvent '["data","deploy","uri"]' "$deploy_uri"
    tryAddToEvent '["data","deploy","id"]' "$deploy_id"
    tryAddToEvent '["data","deploy","url"]' "$deploy_url"
    tryAddToEvent '["data","deploy","environment"]' "$deploy_env"
    tryAddToEvent '["data","deploy","application"]' "$deploy_app"
    tryAddToEvent '["data","deploy","source"]' "$deploy_source"
    tryAddToEvent '["data","deploy","status"]' "$deploy_status"
    tryAddToEvent '["data","deploy","applicationPlatform"]' "$deploy_app_platform"
    tryAddToEvent '["data","deploy","statusDetails"]' "$deploy_status_details"
    tryAddToEvent '["data","deploy","environmentDetails"]' "$deploy_env_details"
    tryAddToEvent '["data","deploy","requestedAt"]' "$deploy_requested_at"
    tryAddToEvent '["data","deploy","startTime"]' "$deploy_start_time"
    tryAddToEvent '["data","deploy","endTime"]' "$deploy_end_time"
    tryAddToEvent '["data","deploy","applicationTags"]' "$deploy_app_tags"
    tryAddToEvent '["data","deploy","applicationPaths"]' "$deploy_app_paths"
}

function addCommitToData() {
    tryAddToEvent '["data","commit","uri"]' "$commit_uri"
    tryAddToEvent '["data","commit","sha"]' "$commit_sha"
    tryAddToEvent '["data","commit","repository"]' "$commit_repo"
    tryAddToEvent '["data","commit","organization"]' "$commit_org"
    tryAddToEvent '["data","commit","source"]' "$commit_source"
    tryAddToEvent '["data","commit","branch"]' "$branch"
    if ! [ -z "$pull_request_number" ]; then
        request_body=$(jq \
            --arg pull_request_number "$pull_request_number" \
            '.data.commit +=
            {
                "pullRequestNumber": $pull_request_number|tonumber,
            }' <<< "$request_body"
        )
    fi
}

function addArtifactToData() {
    tryAddToEvent '["data","artifact","uri"]' "$artifact_uri"
    tryAddToEvent '["data","artifact","id"]' "$artifact_id"
    tryAddToEvent '["data","artifact","repository"]' "$artifact_repo"
    tryAddToEvent '["data","artifact","organization"]' "$artifact_org"
    tryAddToEvent '["data","artifact","source"]' "$artifact_source"
}

function addRunToData() {
    tryAddToEvent '["data","run","uri"]' "$run_uri"
    tryAddToEvent '["data","run","id"]' "$run_id"
    tryAddToEvent '["data","run","pipeline"]' "$run_pipeline"
    tryAddToEvent '["data","run","organization"]' "$run_org"
    tryAddToEvent '["data","run","source"]' "$run_source"
    tryAddToEvent '["data","run","name"]' "$run_name"
    tryAddToEvent '["data","run","status"]' "$run_status"
    tryAddToEvent '["data","run","statusDetails"]' "$run_status_details"
    tryAddToEvent '["data","run","startTime"]' "$run_start_time"
    tryAddToEvent '["data","run","endTime"]' "$run_end_time"
}

function addRunStepToData() {
    tryAddToEvent '["data","run","step","id"]' "$run_step_id"
    tryAddToEvent '["data","run","step","name"]' "$run_step_name"
    tryAddToEvent '["data","run","step","type"]' "$run_step_type"
    tryAddToEvent '["data","run","step","typeDetails"]' "$run_step_type_details"
    tryAddToEvent '["data","run","step","status"]' "$run_step_status"
    tryAddToEvent '["data","run","step","statusDetails"]' "$run_step_status_details"
    tryAddToEvent '["data","run","step","command"]' "$run_step_command"
    tryAddToEvent '["data","run","step","url"]' "$run_step_url"
    tryAddToEvent '["data","run","step","startTime"]' "$run_step_start_time"
    tryAddToEvent '["data","run","step","endTime"]' "$run_step_end_time"
}

function addTestToData() {
    tryAddToEvent '["data","test","id"]' "$test_id"
    tryAddToEvent '["data","test","source"]' "$test_source"
    tryAddToEvent '["data","test","type"]' "$test_type"
    tryAddToEvent '["data","test","typeDetails"]' "$test_type_details"
    tryAddToEvent '["data","test","status"]' "$test_status"
    tryAddToEvent '["data","test","statusDetails"]' "$test_status_details"
    tryAddToEvent '["data","test","suite"]' "$test_suite"
    tryAddToEvent '["data","test","tags"]' "$test_tags"
    tryAddToEvent '["data","test","environments"]' "$environments"
    tryAddToEvent '["data","test","deviceInfo","name"]' "$device_name"
    tryAddToEvent '["data","test","deviceInfo","os"]' "$device_os"
    tryAddToEvent '["data","test","deviceInfo","browser"]' "$device_browser"
    tryAddToEvent '["data","test","deviceInfo","type"]' "$device_type"
    tryAddToEvent '["data","test","testTask"]' "$test_task"
    tryAddToEvent '["data","test","defectTask"]' "$defect_task"
    tryAddToEvent '["data","test","suiteTask"]' "$test_suite_task"
    tryAddToEvent '["data","test","executionTask"]' "$test_execution_task"
    tryAddToEvent '["data","test","taskSource"]' "$task_source"
    if ! [ -z "$test_stats" ]; then
        IFS=',' read -ra ADDR <<< "$test_stats"
        for i in "${ADDR[@]}"; do
            IFS='=' read -r key value <<< "$i"
            request_body=$(jq \
                --arg key "$key" \
                --arg value "$value" \
                '.data.test.stats[$key] += ($value|tonumber)' <<< "$request_body"
            )
        done        
    fi
    tryAddToEvent '["data","test","startTime"]' "$test_start_time"
    tryAddToEvent '["data","test","endTime"]' "$test_end_time"
}

function sendEventToFaros() {
    log "Sending event to Faros..."

    http_response=$(curl -s -S \
        --max-time "$max_time" \
        --retry "$retry" \
        --retry-delay "$retry_delay" \
        --retry-max-time "$retry_max_time" \
        --write-out "HTTPSTATUS:%{http_code}" -X POST \
        "$url/graphs/$graph/events?validateOnly=$validate_only&skipSavingRun=$skip_saving_run&full=$full" \
        -H "authorization: $api_key" \
        -H "content-type: application/json" \
        -d "$request_body"
    )

    http_response_status=$(echo "$http_response" | tr -d '\n' | sed -e 's/.*HTTPSTATUS://')
    http_response_body=$(echo "$http_response" | sed -e 's/HTTPSTATUS\:.*//g')
}

function fmtLog(){
    if ((no_format)); then
        fmtLog=""
    else
        fmtTime="[$(jq -r -n 'now|strflocaltime("%Y-%m-%d %T")')]"
        if [ "$1" == "error" ]; then
            fmtLog="$fmtTime ${RED}ERROR${NC} "
        elif [ "$1" == "warn" ]; then
            fmtLog="$fmtTime ${YELLOW}WARN${NC} "
        else
            fmtLog="$fmtTime ${BLUE}INFO${NC} "
        fi
    fi
}

function printLog() {
    if jq -e . >/dev/null 2>&1 <<< "$1"; then
        if ! ((no_format)); then
            printf "$fmtLog \n"
            echo "$*" | jq .
        else
            # Minify JSON
            echo "$*" | jq -c .
        fi
    else
        printf "$fmtLog"
        printf "$* \n"
    fi
}

function log() {
    if ! ((silent)); then
        fmtLog "info"
        printLog "$*"
    fi
}

function warn() {
    if ! ((silent)); then
        fmtLog "warn"
        printLog "$*"
    fi
}

function err() {
    fmtLog "error"
    printLog "$*"
}

function fail() {
    err "Failed."
    exit 1
}

main() {
    parseFlags "$@"
    set -- "${POSITIONAL[@]:-}" # Restore positional args
    processArgs "$@"            # Determine which event types are present
    resolveInput                # Resolve general fields

    # Event body explicitly provided. Bypass event construction
    if [ -z "$request_body" ]; then
        processEventTypes       # Resolve input and populate event
    fi

    if ((debug)); then
        echo "Faros url: $url"
        echo "Faros graph: $graph"
        echo "Dry run: $dry_run"
        echo "Silent: $silent"
        echo "Skip Saving Run: $skip_saving_run"
        echo "Debug: $debug"
        echo "Community edition: $community_edition"
    fi

    if ! (($community_edition)); then
        log "Request Body:"
        log "$request_body"

        if ! (($dry_run)); then
            sendEventToFaros

            # Log error response as an error and fail
            if [ ! "$http_response_status" -eq 202 ]; then
                err "[HTTP status: $http_response_status]"
                err "Response Body:"
                err "$http_response_body"
                fail
            else
                log "[HTTP status ACCEPTED: $http_response_status]"
            fi
        else
            log "Dry run: Event NOT sent to Faros."
        fi
    else
        if ((ci_event)); then
            doCIMutations
        elif ((cd_event)); then
            doCDMutations
        else
            err "Event type not support for community edition."
            fail
        fi
    fi

    log "Done."
    exit 0
}

main "$@"; exit
