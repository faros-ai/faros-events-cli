#!/bin/bash

set -eo pipefail

version="0.3.0"
canonical_model_version="0.10.6"
github_url="https://github.com/faros-ai/faros-events-cli"

declare -a arr=("curl" "jq" "sed" "awk")
for i in "${arr[@]}"; do
    which $i &> /dev/null || 
        { echo "Error: $i is required." && missing_require=1; }
done

if ((${missing_require:-0})); then
    echo "Please ensure curl, jq, sed, and an implementation of awk (we recommend gawk) are available before running the script."
    exit 1
fi

# Defaults
FAROS_GRAPH_DEFAULT="default"
FAROS_URL_DEFAULT="https://prod.api.faros.ai"
FAROS_ORIGIN_DEFAULT="Faros_Script_Event"

declare -a ENVS=("Prod" "Staging" "QA" "Dev" "Sandbox" "Custom")
envs=$(printf '%s\n' "$(IFS=,; printf '%s' "${ENVS[*]}")")
declare -a BUILD_STATUSES=("Success" "Failed" "Canceled" "Queued" "Running" "Unknown" "Custom")
run_statuses=$(printf '%s\n' "$(IFS=,; printf '%s' "${BUILD_STATUSES[*]}")")
declare -a DEPLOY_STATUSES=("Success" "Failed" "Canceled" "Queued" "Running" "RolledBack" "Custom")
deploy_statuses=$(printf '%s\n' "$(IFS=,; printf '%s' "${DEPLOY_STATUSES[*]}")")

commit_uri_form="source://organization/repository/commit_sha"
artifact_uri_form="source://organization/repository/artifact_id"
run_uri_form="source://organization/pipeline/run_id"
deploy_uri_form="source://application/environment/deploy_id"

# Script settings' defaults
dry_run=${FAROS_DRY_RUN:-0}
silent=${FAROS_SILENT:-0}
debug=${FAROS_DEBUG:-0}
no_format=${FAROS_NO_FORMAT:-0}

# Theme
RED='\033[0;31m'
BLUE='\033[0;34m'
GREY='\033[30;1m'
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
    echo
    printf "${BLUE}Example Event:${NC}\\n"
    echo "./faros_event.sh CD -k \"<faros_api_key>\" \\"
    echo "--artifact \"$artifact_uri_form\" \\"
    echo "--deploy \"$deploy_uri_form\" \\"
    echo "--deploy_status \"Success\""
    echo 
    printf "${RED}Arguments:${NC}\\n"
    echo "Arguments can be provided either by flag or by environment variable."
    echo "By convension, you can switch to using environment variables by prefixing the"
    echo "flag name with 'FAROS_'. For example, --commit becomes FAROS_COMMIT and" 
    echo "--deploy becomes FAROS_DEPLOY"
    echo "-----------------------------------------------------------------------------"
    echo "Argument                | Req |  Default Value"
    echo "-----------------------------------------------------------------------------"
    echo "-k / --api_key          | Yes |"
    echo "-u / --url              |     | $FAROS_URL_DEFAULT"
    echo "-g / --graph            |     | \"$FAROS_GRAPH_DEFAULT\""
    echo "--origin                |     | \"$FAROS_ORIGIN_DEFAULT\""
    echo
    printf "${BLUE}CI Event Arguments:${NC}\\n"
    echo "-----------------------------------------------------------------------------"
    echo "Argument                | Req | Allowed Values / URI form"
    echo "-----------------------------------------------------------------------------"
    echo "--commit                | Yes | $commit_uri_form"
    echo "--artifact              | Yes | $artifact_uri_form"
    echo "--run                   |     | $run_uri_form"
    echo "--run_status            | *1  | $run_statuses"
    echo "--run_status_details    |     |"
    echo "--run_name              |     |"
    echo "--run_start_time        |     | e.g. 1626804346019"
    echo "--run_end_time          |     | e.g. 1626804346019"
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
    echo "--deploy_status_details |     |"
    echo "--deploy_env_details    |     |"
    echo "--deploy_app_platform   |     |"
    echo "--deploy_start_time     |     | e.g. 1626804346019"
    echo "--deploy_end_time       |     | e.g. 1626804346019"
    echo "--run                   |     | $run_uri_form"
    echo "--run_status            | *3  | $run_statuses"
    echo "--run_status_details    |     |"
    echo "--run_name              |     |"
    echo "--run_start_time        |     | e.g. 1626804346019"
    echo "--run_end_time          |     | e.g. 1626804346019"
    echo "*1 env must be: $envs"
    echo "*2 Either --artifact or --commit required"
    echo "*3 If --run included"
    echo
    echo "Additional Settings:"
    echo "--dry_run           Do not send the event."
    echo "--silent            Unexceptional output will be silenced."
    echo "--debug             Helpful information will be printed."
    echo "--no_format         Log formatting will be turned off."
    echo "--no_lowercase_vcs  Do not lowercase VCS org and repo."
    echo "--no_build_object   Do not include a cicd_Build in event."
    echo "--validate_only     Only validate event body against event api."
    echo
    echo "For more usage information please visit: $github_url"
    exit 0
}

main() {
    parseFlags "$@"
    set -- ${POSITIONAL[@]:-}   # Restore positional args
    processArgs "$@"            # Determine which event types are present
    resolveInput                # Resolve general fields
    processEventTypes           # Resolve input and populate event

    if ((debug)); then
        echo "Faros url: $url"
        echo "Faros graph: $graph"
        echo "Dry run: $dry_run"
        echo "Silent: $silent"
        echo "Debug: $debug"
    fi

    log "Request Body:"
    log "$request_body"

    if !(($dry_run)); then
        sendEventToFaros

        # Log error response as an error and fail
        if [ ! $http_response_status -eq 202 ]; then
            err "[HTTP status: $http_response_status]"
            err "Response Body:"
            err "$http_response_body"
            fail
        else
            log "[HTTP status ACCEPTED: $http_response_status]"
            log "Response Body:"
            log "$http_response_body"
        fi
    else
        log "Dry run: Event NOT sent to Faros."
    fi

    log "Done."
    exit 0
}

function parseFlags() {
    # Loop through flags and process them
    while (($#)); do
        case "$1" in
            -k|--api_key)
                api_key="$2"
                shift 2 ;;
            --run) # Externally build is referred to as run
                run_uri="$2"
                shift 2 ;;
            --deploy)
                deploy_uri="$2"
                shift 2 ;;
            --commit)
                commit_uri="$2"
                shift 2 ;;
            --artifact)
                artifact_uri="$2"
                shift 2 ;;
            --deploy_app_platform)
                deploy_app_platform="$2"
                shift 2 ;;
            --deploy_env_details)
                deploy_env_details="$2"
                shift 2 ;;
            --deploy_status)
                deploy_status="$2"
                shift 2 ;;
            --deploy_status_details)
                deploy_status_details="$2"
                shift 2 ;;
            --deploy_start_time)
                deploy_start_time="$2"
                shift 2 ;;
            --deploy_end_time)
                deploy_end_time="$2"
                shift 2 ;;
            --run_name)
                run_name="$2"
                shift 2 ;;
            --run_status)
                run_status="$2"
                shift 2 ;;
            --run_status_details)
                run_status_details="$2"
                shift 2 ;;
            --run_start_time)
                run_start_time="$2"
                shift 2 ;;
            --run_end_time)
                run_end_time="$2"
                shift 2 ;;
            -g|--graph)
                graph="$2"
                shift 2 ;;
            --origin)
                origin="$2"
                shift 2 ;;
            -u|--url)
                url="$2"
                shift 2 ;;
            --no_lowercase_vcs)
                no_lowercase_vcs=1
                shift ;;
            --dry_run)
                dry_run=1
                shift ;;
            --no_build_object)
                no_build_object="true"
                shift ;;
            --validate_only)
                validate_only="true"
                shift ;;
            -s|--silent)
                silent=1
                shift ;;
            --debug)
                debug=1
                shift ;;
            --no_format)
                no_format=1
                shift ;;
            --help)
                help ;;
            -v|--version)
                echo "$version"
                exit 0 ;;
            *)
                POSITIONAL+=("$1") # save it in an array for later
                shift ;;
        esac
    done
}

# Determine which event types are present
function processArgs() {
    # No positional arg passed - show help
    if !(($#)) || [ "$1" == "help" ]; then
        help
        exit 0
    fi

    ci_event=0
    cd_event=0

    # loop through positional args
    while (($#)); do
        case "$1" in
            CI)
                ci_event=1
                shift ;;
            CD)
                cd_event=1
                shift ;;
            help)
                help
                exit 0 ;;
            *)
                UNRECOGNIZED+=("$1")
                shift ;;
        esac
    done

    if [ ! -z "${UNRECOGNIZED:-}" ]; then
        err "Unrecognized arg(s): ${UNRECOGNIZED[@]}"
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
    elif ((cd_event)); then
        event_type="CD"
        makeEvent
        resolveCDInput
        addDeployToData
        addArtifactToData
        addCommitToData
        addRunToData
    fi
}

function resolveInput() {
    # Required fields:
    if ! [ -z ${api_key+x} ] || ! [ -z ${FAROS_API_KEY+x} ]; then
        api_key=${api_key:-$FAROS_API_KEY}
    else
        err "A Faros API key must be provided"
        fail
    fi

    # Optional fields:
    resolveDefaults
    graph=${graph:-$FAROS_GRAPH}
    url=${url:-$FAROS_URL}
    origin=${origin:-$FAROS_ORIGIN}
    
    # Optional script settings: If unset then false
    no_lowercase_vcs=${no_lowercase_vcs:-0}
    no_build_object=${no_build_object:-"false"}
    validate_only=${validate_only:-"false"}
}

function resolveDefaults() {
    FAROS_GRAPH=${FAROS_GRAPH:-$FAROS_GRAPH_DEFAULT}
    FAROS_URL=${FAROS_URL:-$FAROS_URL_DEFAULT}
    FAROS_ORIGIN=${FAROS_ORIGIN:-$FAROS_ORIGIN_DEFAULT}
}

function resolveCDInput() {
    if ! [ -z ${deploy_uri+x} ] || ! [ -z ${FAROS_DEPLOY+x} ]; then
        parseDeployUri
    fi
    if ! [ -z ${artifact_uri+x} ] || ! [ -z ${FAROS_ARTIFACT+x} ]; then
        parseArtifactUri
    fi
    if ! [ -z ${commit_uri+x} ] || ! [ -z ${FAROS_COMMIT+x} ]; then
        parseCommitUri
    fi
    deploy_status=${deploy_status:-$FAROS_DEPLOY_STATUS}
    deploy_app_platform=${deploy_app_platform:-$FAROS_DEPLOY_APP_PLATFORM}
    deploy_env_details=${deploy_env_details:-$FAROS_DEPLOY_ENV_DETAILS}
    deploy_status_details=${deploy_status_details:-$FAROS_DEPLOY_STATUS_DETAILS}
    deploy_start_time=${deploy_start_time:-$FAROS_DEPLOY_START_TIME}
    deploy_end_time=${deploy_end_time:-$FAROS_DEPLOY_END_TIME}

    resolveRunInput
}

function resolveCIInput() {
    if ! [ -z ${artifact_uri+x} ] || ! [ -z ${FAROS_ARTIFACT+x} ]; then
        parseArtifactUri
    fi
    if ! [ -z ${commit_uri+x} ] || ! [ -z ${FAROS_COMMIT+x} ]; then
        parseCommitUri
    fi

    resolveRunInput
}

function resolveRunInput() {
    if ! [ -z ${run_uri+x} ] || ! [ -z ${FAROS_RUN+x} ]; then
        parseRunUri
    fi
    
    run_status=${run_status:-$FAROS_RUN_STATUS}
    # run_name=${run_name:-$FAROS_RUN_NAME}
    run_status_details=${run_status_details:-$FAROS_RUN_STATUS_DETAILS}
    run_start_time=${run_start_time:-$FAROS_RUN_START_TIME}
    run_end_time=${run_end_time:-$FAROS_RUN_END_TIME}
}

# Parses a uri of the form:
# value_A://value_B/value_C/value_D
# arg1; The uri to parse
# arg2: The env var name in which to store value_A
# arg3: The env var name in which to store value_B
# arg4: The env var name in which to store value_C
# arg5: The env var name in which to store value_D
# arg6: The form of the URI to communicate when parsing fails
function parseUri() {
    valid_chars="a-zA-Z0-9_.<>-"
    uri_regex="^[$valid_chars]+:\/\/[$valid_chars]+\/[$valid_chars]+\/[$valid_chars]+$"
    if [[ "$1" =~ $uri_regex ]]; then
        export "$2"=$(sed 's/:.*//' <<< $1)
        export "$3"=$(sed 's/.*:\/\/\(.*\)\/.*\/.*/\1/' <<< $1)
        export "$4"=$(sed 's/.*:\/\/.*\/\(.*\)\/.*/\1/' <<< $1)
        export "$5"=$(sed 's/.*:\/\/.*\/.*\///' <<< $1)
    else
        err "Resource URI could not be parsed: $1 The URI should be of the form: $6"
        fail
    fi
}

function parseCommitUri() {
    parseUri "${commit_uri:-$FAROS_COMMIT}" "commit_source" "commit_org" "commit_repo" "commit_sha" $commit_uri_form

    if !((no_lowercase_vcs)); then
        commit_org=$(echo "$commit_org" | awk '{print tolower($0)}')
        commit_repo=$(echo "$commit_repo" | awk '{print tolower($0)}')
    fi
}

function parseRunUri() {
    parseUri "${run_uri:-$FAROS_RUN}" "run_source" "run_org" "run_pipeline" "run_id" $run_uri_form
}

function parseDeployUri() {
    parseUri "${deploy_uri:-$FAROS_DEPLOY}" "deploy_source" "deploy_app" "deploy_env" "deploy_id" $deploy_uri_form
}

function parseArtifactUri() {
    parseUri "${artifact_uri:-$FAROS_ARTIFACT}" "artifact_source" "artifact_org" "artifact_repo" "artifact_id" $artifact_uri_form    
}

function makeEvent() {
    request_body=$( jq -n \
        --arg origin "$origin" \
        --arg event_type "$event_type" \
        '{ 
            "type": $event_type,
            "version": "0.0.1",
            "origin": $origin,
        }'
    )
}

function addDeployToData() {
    if ! [ -z "$deploy_id" ] &&
       ! [ -z "$deploy_env" ] &&
       ! [ -z "$deploy_app" ] &&
       ! [ -z "$deploy_source" ]; then
        request_body=$(jq \
            --arg deploy_id "$deploy_id" \
            --arg deploy_app "$deploy_app" \
            --arg deploy_env "$deploy_env" \
            --arg deploy_source "$deploy_source" \
            '.data.deploy +=
            {
                "id": $deploy_id,
                "environment": $deploy_env,
                "application": $deploy_app,
                "source": $deploy_source,
            }' <<< $request_body
        )
    fi
    if ! [ -z "$deploy_status" ]; then
        request_body=$(jq \
            --arg deploy_status "$deploy_status" \
            '.data.deploy +=
            {
                "status": $deploy_status
            }' <<< $request_body
        )
    fi
    if ! [ -z "$deploy_status_details" ]; then
        request_body=$(jq \
            --arg deploy_status_details "$deploy_status_details" \
            '.data.deploy +=
            {
                "statusDetails": $deploy_status_details
            }' <<< $request_body
        )
    fi
    if ! [ -z "$deploy_env_details" ]; then
        request_body=$(jq \
            --arg deploy_env_details "$deploy_env_details" \
            '.data.deploy +=
            {
                "environmentDetails": $deploy_env_details
            }' <<< $request_body
        )
    fi
    if ! [ -z "$deploy_start_time" ]; then
        request_body=$(jq \
            --arg deploy_start_time "$deploy_start_time" \
            '.data.deploy +=
            {
                "startTime": $deploy_start_time|tonumber
            }' <<< $request_body
        )
    fi
    if ! [ -z "$deploy_end_time" ]; then
        request_body=$(jq \
            --arg deploy_end_time "$deploy_end_time" \
            '.data.deploy +=
            {
                "endTime": $deploy_end_time|tonumber
            }' <<< $request_body
        )
    fi
}

function addCommitToData() {
    if ! [ -z "$commit_sha" ] && 
       ! [ -z "$commit_repo" ] &&
       ! [ -z "$commit_org" ] && 
       ! [ -z "$commit_source" ]; then
        request_body=$(jq \
            --arg commit_sha "$commit_sha" \
            --arg commit_repo "$commit_repo" \
            --arg commit_org "$commit_org" \
            --arg commit_source "$commit_source" \
            '.data.commit +=
            {
                "sha": $commit_sha,
                "repository": $commit_repo,
                "organization": $commit_org,
                "source": $commit_source
            }' <<< $request_body
        )
    fi
}

function addArtifactToData() {
    if ! [ -z "$artifact_id" ] &&
       ! [ -z "$artifact_repo" ] &&
       ! [ -z "$artifact_org" ] &&
       ! [ -z "$artifact_source" ]; then
        request_body=$(jq \
            --arg artifact_id "$artifact_id" \
            --arg artifact_repo "$artifact_repo" \
            --arg artifact_org "$artifact_org" \
            --arg artifact_source "$artifact_source" \
            '.data.artifact +=
            {
                "id": $artifact_id,
                "repository": $artifact_repo,
                "organization": $artifact_org,
                "source": $artifact_source

            }' <<< $request_body
        )
    fi
}

function addRunToData() {
    if ! [ -z "$run_id" ] &&
       ! [ -z "$run_org" ] &&
       ! [ -z "$run_pipeline" ] &&
       ! [ -z "$run_source" ]; then
        request_body=$(jq \
            --arg run_id "$run_id" \
            --arg run_pipeline "$run_pipeline" \
            --arg run_org "$run_org" \
            --arg run_source "$run_source" \
            '.data.run +=
            {
                "id": $run_id,
                "pipeline": $run_pipeline,
                "organization": $run_org,
                "source": $run_source
            }' <<< $request_body
        )
    fi
    if ! [ -z "$run_status" ]; then
        request_body=$(jq \
            --arg run_status "$run_status" \
            '.data.run +=
            {
                "status": $run_status
            }' <<< $request_body
        )
    fi
    if ! [ -z "$run_status_details" ]; then
        request_body=$(jq \
            --arg run_status_details "$run_status_details" \
            '.data.run +=
            {
                "statusDetails": $run_status_details,
            }' <<< $request_body
        )
    fi
    if ! [ -z "$run_start_time" ]; then
        request_body=$(jq \
            --arg run_start_time "$run_start_time" \
            '.data.run +=
            {
                "startTime": $run_start_time|tonumber
            }' <<< $request_body
        )
    fi
    if ! [ -z "$run_end_time" ]; then
        request_body=$(jq \
            --arg run_end_time "$run_end_time" \
            '.data.run +=
            {
                "endTime": $run_end_time|tonumber
            }' <<< $request_body
        )
    fi
}

function sendEventToFaros() {
    log "Sending event to Faros..."

    http_response=$(curl --retry 5 --retry-delay 5 \
        --silent --write-out "HTTPSTATUS:%{http_code}" -X POST \
        "$url/graphs/$graph/events?validateOnly=$validate_only&noBuild=$no_build_object" \
        -H "authorization: $api_key" \
        -H "content-type: application/json" \
        -d "$request_body") 

    http_response_status=$(echo $http_response | tr -d '\n' | sed -e 's/.*HTTPSTATUS://')
    http_response_body=$(echo $http_response | sed -e 's/HTTPSTATUS\:.*//g')
}

function fmtLog(){
    if ((no_format)); then
        fmtLog=""
    else 
        fmtTime="[$(date +"%Y-%m-%d %T"])"
        if [ $1 == "error" ]; then
            fmtLog="$fmtTime ${RED}ERROR${NC} "
        else
            fmtLog="$fmtTime ${BLUE}INFO${NC} "
        fi
    fi
}

function printLog() {
    if jq -e . >/dev/null 2>&1 <<< "$1"; then
        if !((no_format)); then
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
    if !((silent)); then
        fmtLog "info"
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

main "$@"; exit
