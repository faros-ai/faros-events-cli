#!/bin/bash

set -euo pipefail

version="0.2.0"
canonical_model_version="0.8.11"
github_url="https://github.com/faros-ai/faros-events-cli"

declare -a arr=("curl" "jq")
for i in "${arr[@]}"; do
    which $i &> /dev/null || 
        { echo "Error: $i is required." && missing_require=1; }
done

if ((${missing_require:-0})); then
    echo "Please ensure curl and jq are available before running the script."
    exit 1
fi

# Defaults
FAROS_GRAPH_DEFAULT="default"
FAROS_URL_DEFAULT="https://prod.api.faros.ai"
FAROS_ORIGIN_DEFAULT="Faros_Script_Event"
FAROS_DEPLOY_APP_PLATFORM_DEFAULT=""
FAROS_DEPLOY_ENV_DETAILS_DEFAULT=""
FAROS_DEPLOY_STATUS_DETAILS_DEFAULT=""
FAROS_BUILD_NAME_DEFAULT=""
FAROS_BUILD_STATUS_DETAILS_DEFAULT=""
FAROS_START_TIME_DEFAULT=${FAROS_START_TIME_DEFAULT:-$(date +%s000000000 | cut -b1-13)} # Now
FAROS_END_TIME_DEFAULT=${FAROS_END_TIME_DEFAULT:-$(date +%s000000000 | cut -b1-13)} # Now

declare -a ENVS=("Prod" "Staging" "QA" "Dev" "Sandbox" "Custom")
envs=$(printf '%s\n' "$(IFS=,; printf '%s' "${ENVS[*]}")")
declare -a BUILD_STATUSES=("Success" "Failed" "Canceled" "Queued" "Running" "Unknown" "Custom")
build_statuses=$(printf '%s\n' "$(IFS=,; printf '%s' "${BUILD_STATUSES[*]}")")
declare -a DEPLOY_STATUSES=("Success" "Failed" "Canceled" "Queued" "Running" "RolledBack" "Custom")
deploy_statuses=$(printf '%s\n' "$(IFS=,; printf '%s' "${DEPLOY_STATUSES[*]}")")

dry_run=${FAROS_DRY_RUN:-0}
silent=0
debug=0
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
    echo "--artifact \"<artifact_source>://<org>/<repo>/<artifact_uid>\" \\"
    echo "--deploy \"<deploy_source>://<app_name>/<environment>/<deploy_uid>\" \\"
    echo "--deploy_status \"Success\" \\"
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
    echo "Argument                | Req | Allowed Values"
    echo "-----------------------------------------------------------------------------"
    echo "--commit                | Yes | URI of the form: source://org/repo/commit"
    echo "--artifact              | Yes | URI of the form: source://org/repo/artifact"
    echo "--run                   |     | URI of the form: source://org/pipeline/run"
    echo "--run_status            | *1  | ${build_statuses}"
    echo "--run_status_details    |     |"
    echo "--run_name              |     |"
    echo "--run_start_time        |     | e.g. 1626804346019"
    echo "--run_end_time          |     | e.g. 1626804346019"
    echo "*1 If --run included"
    echo   
    printf "${BLUE}CD Event Arguments:${NC}\\n"
    echo "-----------------------------------------------------------------------------"
    echo "Argument                | Req | Allowed Values"
    echo "-----------------------------------------------------------------------------"
    echo "--deploy                | Yes | URI of the form: source://app/env/deploy *1"
    echo "--deploy_status         | Yes | ${deploy_statuses}"
    echo "--artifact              | *2  | URI of the form: source://org/repo/artifact"
    echo "--commit                | *2  | URI of the form: source://org/repo/commit"
    echo "--deploy_status_details |     |"
    echo "--deploy_env_details    |     |"
    echo "--deploy_app_platform   |     |"
    echo "--deploy_start_time     |     | e.g. 1626804346019"
    echo "--deploy_end_time       |     | e.g. 1626804346019"
    echo "--run                   |     | URI of the form: source://org/pipeline/run"
    echo "--run_status            | *3  | ${build_statuses}"
    echo "--run_status_details    |     |"
    echo "--run_name              |     |"
    echo "--run_start_time        |     | e.g. 1626804346019"
    echo "--run_end_time          |     | e.g. 1626804346019"
    echo "*1 env must be: ${envs}"
    echo "*2 Either --artifact or --commit required"
    echo "*3 If --run included"
    echo
    echo "Additional Settings:"
    echo "--dry_run          Do not send the event."
    echo "--silent           Unexceptional output will be silenced."
    echo "--debug            Helpful information will be printed."
    echo "--no_format        Log formatting will be turned off."
    echo "--no_build_object  Do not include cicd_Build in the event."
    echo
    echo "For more usage information please visit: $github_url"
    exit 0
}

main() {
    parseFlags "$@"
    set -- ${POSITIONAL[@]:-} # Restore positional args
    processArgs "$@" # Determine which event types are present
    resolveInput # Resolve general fields
    makeEvent # Create the event that objects will be added to
    processEventTypes # Per present event types, resolve input and populate event

    if ((build_present)); then
        if ! ((no_build_object)); then
            resolveBuildInput
            addBuildToEvent
        fi
        addCICDObjectsToEvent
    fi

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
        if [ ! $http_response_status -eq 200 ]; then
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
            --run)
                build_uri="$2"
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
                build_name="$2"
                shift 2 ;;
            --run_status)
                build_status="$2"
                shift 2 ;;
            --run_status_details)
                build_status_details="$2"
                shift 2 ;;
            --run_start_time)
                build_start_time="$2"
                shift 2 ;;
            --run_end_time)
                build_end_time="$2"
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
            --no_build_object)
                no_build_object=1
                shift ;;
            --dry_run)
                dry_run=1
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
        resolveCIInput
        addCIObjectsToEvent
    elif ((cd_event)); then
        resolveCDInput
        addCDObjectsToEvent
        if ((use_commit)); then
            # Dummy Artifact will be added
            addCIObjectsToEvent
        fi
    fi
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

function parseBuildUri() {
    parseUri "${build_uri:-$FAROS_RUN}" "cicd_source" "cicd_org" "pipeline" "build" "source://org/pipeline/run"
}

function parseCommitUri() {
    parseUri "${commit_uri:-$FAROS_COMMIT}" "vcs_source" "vcs_org" "vcs_repo" "commit_sha" "source://org/repo/commit"
}

function parseDeployUri() {
    parseUri "${deploy_uri:-$FAROS_DEPLOY}" "deploy_source" "app" "deploy_env" "deploy" "source://app/env/deploy"
}

function parseArtifactUri() {
    parseUri "${artifact_uri:-$FAROS_ARTIFACT}" "artifact_source" "artifact_org" "artifact_repo" "artifact" "source://org/repo/artifact"    
}

function resolveInput() {
    # Required fields:
    api_key=${api_key:-$FAROS_API_KEY}

    # Optional fields:
    # Resolve and parse build information if present
    if ! [ -z ${build_uri+x} ] || ! [ -z ${FAROS_RUN+x} ]; then
        parseBuildUri
        build_present=1
    else
        build_present=0
    fi

    resolveDefaults
    graph=${graph:-$FAROS_GRAPH}
    url=${url:-$FAROS_URL}
    origin=${origin:-$FAROS_ORIGIN}
    
    # Optional script settings: If unset then false
    no_build_object=${no_build_object:-0}
    dry_run=${dry_run:-0}
    silent=${silent:-0}
    debug=${debug:-0}
}

function resolveDefaults() {
    FAROS_GRAPH=${FAROS_GRAPH:-$FAROS_GRAPH_DEFAULT}
    FAROS_URL=${FAROS_URL:-$FAROS_URL_DEFAULT}
    FAROS_ORIGIN=${FAROS_ORIGIN:-$FAROS_ORIGIN_DEFAULT}
}

function resolveCDInput() {
    # Required fields:
    parseDeployUri
    deploy_status=${deploy_status:-$FAROS_DEPLOY_STATUS}

    # Artifact or Commit required for CD event
    use_commit=0
    if ! [ -z ${artifact_uri+x} ] || ! [ -z ${FAROS_ARTIFACT+x} ]; then
        parseArtifactUri
    elif ! [ -z ${commit_uri+x} ] || ! [ -z ${FAROS_COMMIT+x} ]; then
        parseCommitUri

        # Populate dummy Artifact with commit information
        artifact=$commit_sha
        artifact_repo=$vcs_repo
        artifact_org=$vcs_org
        artifact_source=$vcs_source
        use_commit=1
    else
        err "CD event requires --artifact or --commit information"
        fail
    fi 

    # Optional fields:
    resolveCDDefaults
    deploy_app_platform=${deploy_app_platform:-$FAROS_DEPLOY_APP_PLATFORM}
    deploy_env_details=${deploy_env_details:-$FAROS_DEPLOY_ENV_DETAILS}
    deploy_status_details=${deploymant_status_details:-$FAROS_DEPLOY_STATUS_DETAILS}
    deploy_start_time=${deploy_start_time:-$FAROS_DEPLOY_START_TIME}
    deploy_end_time=${deploy_end_time:-$FAROS_DEPLOY_END_TIME}

    if ! [[ ${ENVS[*]} =~ (^|[[:space:]])"$deploy_env"($|[[:space:]]) ]] ; then
      err "Invalid deployment environment: $deploy_env. Allowed values: ${envs}";
      fail
    fi
    if ! [[ ${DEPLOY_STATUSES[*]} =~ (^|[[:space:]])"$deploy_status"($|[[:space:]]) ]] ; then
      err "Invalid --deploy_status: $deploy_status. Allowed values: ${deploy_statuses}";
      fail
    fi
}

function resolveCDDefaults() {
    FAROS_DEPLOY_APP_PLATFORM=${FAROS_DEPLOY_APP_PLATFORM:-$FAROS_DEPLOY_APP_PLATFORM_DEFAULT}
    FAROS_DEPLOY_ENV_DETAILS=${FAROS_DEPLOY_ENV_DETAILS:-$FAROS_DEPLOY_ENV_DETAILS_DEFAULT}
    FAROS_DEPLOY_STATUS_DETAILS=${FAROS_DEPLOY_STATUS_DETAILS:-$FAROS_DEPLOY_STATUS_DETAILS_DEFAULT}
    FAROS_DEPLOY_START_TIME=${FAROS_DEPLOY_START_TIME:-$FAROS_START_TIME_DEFAULT}
    FAROS_DEPLOY_END_TIME=${FAROS_DEPLOY_END_TIME:-$FAROS_END_TIME_DEFAULT}
}

function resolveCIInput() {
    # Required fields:
    parseCommitUri

    if ! [ -z ${artifact_uri+x} ] || ! [ -z ${FAROS_ARTIFACT+x} ]; then
        parseArtifactUri
    else
        # Populate dummy artifact with commit information
        artifact=$commit_sha
        artifact_repo=$vcs_repo
        artifact_org=$vcs_org
        artifact_source=$vcs_source
    fi 
}

function resolveBuildInput() {
    # Required fields:
    build_status=${build_status:-$FAROS_RUN_STATUS}

    # Optional fields:
    resolveBuildDefaults
    build_name=${build_name:-$FAROS_RUN_NAME}
    build_status_details=${build_status_details:-$FAROS_RUN_STATUS_DETAILS}
    build_start_time=${build_start_time:-$FAROS_RUN_START_TIME}
    build_end_time=${build_end_time:-$FAROS_RUN_END_TIME}

    if ! [[ ${BUILD_STATUSES[*]} =~ (^|[[:space:]])"$build_status"($|[[:space:]]) ]] ; then
      err "Invalid build status $build_status. Allowed values: ${build_statuses}";
      fail
    fi
}

function resolveBuildDefaults() {
    FAROS_RUN_NAME=${FAROS_RUN_NAME:-$FAROS_BUILD_NAME_DEFAULT}
    FAROS_RUN_STATUS_DETAILS=${FAROS_RUN_STATUS_DETAILS:-$FAROS_BUILD_STATUS_DETAILS_DEFAULT}
    FAROS_RUN_START_TIME=${FAROS_RUN_START_TIME:-$FAROS_START_TIME_DEFAULT}
    FAROS_RUN_END_TIME=${FAROS_RUN_END_TIME:-$FAROS_END_TIME_DEFAULT}
}

function makeDeployment() {
    cicd_Deployment=$( jq -n \
        --arg deploy "$deploy" \
        --arg deploy_source "$deploy_source" \
        --arg deploy_status "$deploy_status" \
        --arg deploy_status_details "$deploy_status_details" \
        --arg start_time "$deploy_start_time" \
        --arg end_time "$deploy_end_time" \
        --arg deploy_env "$deploy_env" \
        --arg deploy_env_details "$deploy_env_details" \
        --arg app "$app" \
        --arg deploy_app_platform "$deploy_app_platform" \
        '{
            "cicd_Deployment": {
                "uid": $deploy,
                "source": $deploy_source,
                "status": {
                    "category": $deploy_status,
                    "detail": $deploy_status_details
                },
                "startedAt": $start_time|tonumber,
                "endedAt": $end_time|tonumber,
                "env": {
                    "category": $deploy_env,
                    "detail": $deploy_env_details
                },
                "application" : {
                    "name": $app,
                    "platform": $deploy_app_platform
                }
            }
        }'
    )
    
    # Add build to cicd_Deployment if fields are present
    if ((build_present)); then
        cicd_Deployment=$(jq \
            --arg build "$build" \
            --arg pipeline "$pipeline" \
            --arg cicd_org "$cicd_org" \
            --arg cicd_source "$cicd_source" \
            '.cicd_Deployment +=
            {
                "build": {
                    "uid": $build,
                    "pipeline": {
                        "uid": $pipeline,
                        "organization": {
                            "uid": $cicd_org,
                            "source": $cicd_source
                        }
                    }
                }
            }' <<< $cicd_Deployment
        )
    fi
}

function makeArtifact() {
    cicd_Artifact=$( jq -n \
        --arg artifact "$artifact" \
        --arg artifact_repo "$artifact_repo" \
        --arg artifact_org "$artifact_org" \
        --arg artifact_source "$artifact_source" \
        '{
            "cicd_Artifact": {
                "uid": $artifact,
                "repository": {
                    "uid": $artifact_repo,
                    "organization": {
                        "uid": $artifact_org,
                        "source": $artifact_source
                    }
                }
            }
        }'
    )

    # Add build to cicd_Artifact if fields are present
    if ((build_present)); then
        cicd_Artifact=$(jq \
            --arg build "$build" \
            --arg pipeline "$pipeline" \
            --arg cicd_org "$cicd_org" \
            --arg cicd_source "$cicd_source" \
            '.cicd_Artifact +=
            {
                "build": {
                    "uid": $build,
                    "pipeline": {
                        "uid": $pipeline,
                        "organization": {
                            "uid": $cicd_org,
                            "source": $cicd_source
                        }
                    }
                }
            }' <<< $cicd_Artifact
        )
    fi
}

function makeArtifactDeployment() {
    cicd_ArtifactDeployment=$( jq -n \
        --arg artifact "$artifact" \
        --arg deploy "$deploy" \
        --arg deploy_source "$deploy_source" \
        --arg artifact_repo "$artifact_repo" \
        --arg artifact_org "$artifact_org" \
        --arg artifact_source "$artifact_source" \
        '{
            "cicd_ArtifactDeployment": {
                "artifact": {
                    "uid": $artifact,
                    "repository": {
                        "uid": $artifact_repo,
                        "organization": {
                            "uid": $artifact_org,
                            "source": $artifact_source
                        }
                    }
                },
                "deployment": {
                    "uid": $deploy,
                    "source": $deploy_source
                }
            }
        }'
    )
}

function makeArtifactCommitAssociation() {
    cicd_ArtifactCommitAssociation=$( jq -n \
        --arg artifact "$artifact" \
        --arg artifact_repo "$artifact_repo" \
        --arg artifact_org "$artifact_org" \
        --arg artifact_source "$artifact_source" \
        --arg commit_sha "$commit_sha" \
        --arg vcs_repo "$vcs_repo" \
        --arg vcs_org "$vcs_org" \
        --arg vcs_source "$vcs_source" \
        '{
            "cicd_ArtifactCommitAssociation": {
                "artifact": {
                    "uid": $artifact,
                    "repository": {
                        "uid": $artifact_repo,
                        "organization": {
                            "uid": $artifact_org,
                            "source": $artifact_source
                        }
                    }
                },
                "commit": {
                    "sha": $commit_sha,
                    "repository": {
                        "name": $vcs_repo,
                        "organization": {
                            "uid": $vcs_org,
                            "source": $vcs_source
                        }
                    }
                }
            }
        }'
    )
}

function makeBuild() {
    cicd_Build=$( jq -n \
        --arg build "$build" \
        --arg build_status "$build_status" \
        --arg build_status_details "$build_status_details" \
        --arg build_name "$build_name" \
        --arg build_start_time "$build_start_time" \
        --arg build_end_time "$build_end_time" \
        --arg pipeline "$pipeline" \
        --arg cicd_org "$cicd_org" \
        --arg cicd_source "$cicd_source" \
        '{
            "cicd_Build": {
                "uid": $build,
                "name": $build_name,
                "startedAt": $build_start_time|tonumber,
                "endedAt": $build_end_time|tonumber,
                "status": {
                    "category": $build_status,
                    "detail": $build_status_details
                },
                "pipeline": {
                    "uid": $pipeline,
                    "organization": {
                        "uid": $cicd_org,
                        "source": $cicd_source
                    }
                }
            }
        }'
    )
}

function makePipeline() {
    cicd_Pipeline=$( jq -n \
        --arg pipeline "$pipeline" \
        --arg cicd_org "$cicd_org" \
        --arg cicd_source "$cicd_source" \
        '{
            "cicd_Pipeline": {
                "uid": $pipeline,
                "organization": {
                    "uid": $cicd_org,
                    "source": $cicd_source
                }
            }
        }'
    )
}

function makeApplication() {
    compute_Application=$( jq -n \
        --arg app "$app" \
        --arg deploy_app_platform "$deploy_app_platform" \
        '{
            "compute_Application": {
                "name": $app,
                "platform": $deploy_app_platform
            }
        }'
    )
}

function makeOrganization() {
    cicd_Organization=$( jq -n \
        --arg cicd_org "$cicd_org" \
        --arg cicd_source "$cicd_source" \
        '{
            "cicd_Organization": {
                "uid": $cicd_org,
                "source": $cicd_source
            }
        }'
    )
}

function makeEvent() {
    request_body=$( jq -n \
        --arg origin "$origin" \
        '{ 
            "origin": $origin,
            "entries": []
        }'
    )
}

function addBuildToEvent() {
    makeBuild
    request_body=$(jq ".entries += [
        $cicd_Build
    ]" <<< $request_body)
}

function addCDObjectsToEvent() {
    makeDeployment
    makeArtifactDeployment
    makeApplication
    request_body=$(jq ".entries += [
        $cicd_Deployment,
        $cicd_ArtifactDeployment,
        $compute_Application
    ]" <<< $request_body)
}

function addCIObjectsToEvent() {
    makeArtifact
    makeArtifactCommitAssociation
    request_body=$(jq ".entries += [
        $cicd_Artifact,
        $cicd_ArtifactCommitAssociation
    ]" <<< $request_body)
}

function addCICDObjectsToEvent() {
    makeOrganization
    makePipeline
    request_body=$(jq ".entries += [
        $cicd_Organization,
        $cicd_Pipeline
    ]" <<< $request_body)
}

function sendEventToFaros() {
    log "Sending event to Faros..."

    http_response=$(curl --retry 5 --retry-delay 5 \
        --silent --write-out "HTTPSTATUS:%{http_code}" -X POST \
        $url/graphs/$graph/revisions \
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
            echo "$*"
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
