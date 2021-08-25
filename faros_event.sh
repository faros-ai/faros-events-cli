#!/bin/bash

set -euo pipefail

version="0.2.0"
canonical_model_version="0.8.10"
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
FAROS_APP_PLATFORM_DEFAULT=""
FAROS_DEPLOYMENT_ENV_DETAILS_DEFAULT=""
FAROS_DEPLOYMENT_STATUS_DETAILS_DEFAULT=""
FAROS_BUILD_NAME_DEFAULT=""
FAROS_BUILD_STATUS_DETAILS_DEFAULT=""
FAROS_START_TIME_DEFAULT=$(date +%s000000000 | cut -b1-13) # Now
FAROS_END_TIME_DEFAULT=$(date +%s000000000 | cut -b1-13) # Now

declare -a ENVS=("Prod" "Staging" "QA" "Dev" "Sandbox" "Custom")
envs=$(printf '%s\n' "$(IFS=,; printf '%s' "${ENVS[*]}")")
declare -a BUILD_STATUSES=("Success" "Failed" "Canceled" "Queued" "Running" "Unknown" "Custom")
build_statuses=$(printf '%s\n' "$(IFS=,; printf '%s' "${BUILD_STATUSES[*]}")")
declare -a DEPLOYMENT_STATUSES=("Success" "Failed" "Canceled" "Queued" "Running" "RolledBack" "Custom")
deployment_statuses=$(printf '%s\n' "$(IFS=,; printf '%s' "${DEPLOYMENT_STATUSES[*]}")")

dry_run=0
silent=0
debug=0
no_format=0

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
    echo "There are multiple event types that can be used, each with a set of required and optional fields."
    echo
    printf "${RED}Args:${NC}\\n"
    echo "Event type (\"CI\", \"CD\")"
    echo 
    printf "${RED}Fields:${NC} (Can be provided as flag or environment variable)\\n"
    echo "---------------------------------------------------------------------------------------------------"
    echo "Flag                                    | Environment Variable            | Allowed Values"
    echo "---------------------------------------------------------------------------------------------------"
    printf "${RED}(Required fields)${NC}\\n"
    echo "-k / --api_key <api_key>                | FAROS_API_KEY                   |"
    echo "--build <source://org/pipeline/build>   | FAROS_BUILD                     |"
    printf "${RED}(Required CI fields)${NC}\\n"
    echo "--vcs <source://org/repo/commit>        | FAROS_VCS                       |"
    printf "${RED}(Required CD fields) - must include Artifact or VCS information${NC}\\n"
    echo "--deployment <source://app/env/deploy>  | FAROS_DEPLOY                    |"
    echo "--deployment_status <status>            | FAROS_DEPLOY_STATUS             | ${deployment_statuses}"
    printf "${GREY}Artifact information:${NC}\\n"
    echo "--artifact <source://org/repo/artifact> | FAROS_ARTIFACT                  |"
    printf "${GREY}VCS information:${NC}\\n"
    echo "--vcs <source://org/repo/commit>        | FAROS_VCS                       |"
    printf "${RED}(Required fields if --write_build flag set)${NC}\\n"
    echo "--build_status <status>                 | FAROS_BUILD_STATUS              | ${build_statuses}"
    echo
    echo "---------------------------------------------------------------------------------------------------"
    echo "Flag                                    | Environment Variable            | Default"
    echo "---------------------------------------------------------------------------------------------------"
    printf "${BLUE}(Optional fields)${NC}\\n"
    echo "-u / --url <url>                        | FAROS_URL                       | $FAROS_URL_DEFAULT"
    echo "-g / --graph <graph>                    | FAROS_GRAPH                     | \"$FAROS_GRAPH_DEFAULT\""
    echo "--origin <origin>                       | FAROS_ORIGIN                    | \"$FAROS_ORIGIN_DEFAULT\""
    echo "--start_time <start>                    | FAROS_START_TIME                | Now"
    echo "--end_time <end>                        | FAROS_END_TIME                  | Now"
    printf "${BLUE}(Optional CI fields)${NC}\\n"
    echo "--artifact <source://org/repo/artifact> | FAROS_ARTIFACT                  | FAROS_VCS"
    printf "${BLUE}(Optional CD fields)${NC}\\n"
    echo "--deployment_app_platform <platform>    | FAROS_APP_PLATFORM              | \"$FAROS_APP_PLATFORM_DEFAULT\""
    echo "--deployment_env_details <details>      | FAROS_DEPLOY_ENV_DETAILS        | \"$FAROS_DEPLOYMENT_ENV_DETAILS_DEFAULT\""
    echo "--deployment_status_details <details>   | FAROS_DEPLOY_STATUS_DETAILS     | \"$FAROS_DEPLOYMENT_STATUS_DETAILS_DEFAULT\""
    echo "--deployment_start_time <start>         | FAROS_DEPLOY_START_TIME         | FAROS_START_TIME"
    echo "--deployment_end_time <end>             | FAROS_DEPLOY_END_TIME           | FAROS_END_TIME"
    printf "${BLUE}(Optional fields if --write_build flag set)${NC}\\n"
    echo "--build_name <build_name>               | FAROS_BUILD_NAME                | \"$FAROS_BUILD_NAME_DEFAULT\""
    echo "--build_status_details <details>        | FAROS_BUILD_STATUS_DETAILS      | \"$FAROS_BUILD_STATUS_DETAILS_DEFAULT\""
    echo "--build_start_time <start>              | FAROS_BUILD_START_TIME          | FAROS_START_TIME"
    echo "--build_end_time <end>                  | FAROS_BUILD_END_TIME            | FAROS_END_TIME"
    echo
    printf "${BLUE}Additional settings flags:${NC}\\n"
    echo "--write_build         Include cicd_Build in the event."
    echo "--write_cicd_objects  Include cicd_Organization & cicd_Pipeline in the event."
    echo "--dry_run             Print the event instead of sending."
    echo "--silent              Unexceptional output will be silenced."
    echo "--debug               Helpful information will be printed."
    echo "--no_format           Log formatting will be turned off."
    echo
    echo "For more usage information please visit: $github_url"
    echo
    exit 0
}

main() {
    parseFlags "$@"
    set -- ${POSITIONAL[@]:-} # Restore positional args
    processArgs "$@" # Determine which event types are present
    resolveInput # Resolve general fields
    makeEvent # Create the event that objects will be added to
    processEventTypes # Per present event types, resolve input and populate event

    if ((write_build)); then
        resolveBuildInput
        addBuildToEvent
    fi

    if ((write_cicd_objects)); then
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

        if [ ! $http_response_status -eq 200 ]; then
            err "[HTTP status: $http_response_status]"
            err "Response Body:"
            err "$http_response_body"
            fail
        else
            log "[HTTP status: $http_response_status]"
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
            --build)
                build_uri="$2"
                shift 2 ;;
            --deployment)
                deployment_uri="$2"
                shift 2 ;;
            --vcs)
                vcs_uri="$2"
                shift 2 ;;
            --artifact)
                artifact_uri="$2"
                shift 2 ;;
            --app_platform)
                app_platform="$2"
                shift 2 ;;
            --deployment_env_details)
                deployment_env_details="$2"
                shift 2 ;;
            --deployment_status)
                deployment_status="$2"
                shift 2 ;;
            --deployment_status_details)
                deployment_status_details="$2"
                shift 2 ;;
            --deployment_start_time)
                deployment_start_time="$2"
                shift 2 ;;
            --deployment_end_time)
                deployment_end_time="$2"
                shift 2 ;;
            --build_name)
                build_name="$2"
                shift 2 ;;
            --build_status)
                build_status="$2"
                shift 2 ;;
            --build_status_details)
                build_status_details="$2"
                shift 2 ;;
            --build_start_time)
                build_start_time="$2"
                shift 2 ;;
            --build_end_time)
                build_end_time="$2"
                shift 2 ;;
            --start_time)
                start_time="$2"
                shift 2 ;;
            --end_time)
                end_time="$2"
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
            --write_cicd_objects)
                write_cicd_objects=1
                shift ;;
            --write_build)
                write_build=1
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
# Each distict event type should be considered only once
function processEventTypes() {
    if ((ci_event)); then
        resolveCIInput
        addCIObjectsToEvent
    fi

    if ((cd_event)); then
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
# arg2: The env var name in which to store value_A
# arg3: The env var name in which to store value_B
# arg4: The env var name in whcih to store value_C
# arg5: The env var name in which to store value_D
function parseUri() {
    valid_chars="a-zA-Z0-9_.<>-"
    uri_regex="^[$valid_chars]+:\/\/[$valid_chars]+\/[$valid_chars]+\/[$valid_chars]+$"
    if [[ "$1" =~ $uri_regex ]]; then
        export "$2"=$(sed 's/:.*//' <<< $1)
        export "$3"=$(sed 's/.*:\/\/\(.*\)\/.*\/.*/\1/' <<< $1)
        export "$4"=$(sed 's/.*:\/\/.*\/\(.*\)\/.*/\1/' <<< $1)
        export "$5"=$(sed 's/.*:\/\/.*\/.*\///' <<< $1)
    else
        err "Resource URI could not be parsed: $1"
        fail
    fi
}

function resolveInput() {
    # Required fields:
    api_key=${api_key:-$FAROS_API_KEY}
    
    parseUri "${build_uri:-$FAROS_BUILD}" "cicd_source" "cicd_org" "pipeline" "build"

    # Optional fields:
    resolveDefaults
    graph=${graph:-$FAROS_GRAPH}
    url=${url:-$FAROS_URL}
    origin=${origin:-$FAROS_ORIGIN}
    start_time=${start_time:-$FAROS_START_TIME}
    end_time=${end_time:-$FAROS_END_TIME}
    
    # Optional script settings: If unset then false
    write_cicd_objects=${make_cicd_objects:-0}
    write_build=${write_build:-0}
    dry_run=${dry_run:-0}
    silent=${silent:-0}
    debug=${debug:-0}
}

function resolveDefaults() {
    FAROS_GRAPH=${FAROS_GRAPH:-$FAROS_GRAPH_DEFAULT}
    FAROS_URL=${FAROS_URL:-$FAROS_URL_DEFAULT}
    FAROS_ORIGIN=${FAROS_ORIGIN:-$FAROS_ORIGIN_DEFAULT}
    # Default start time and end time to now
    FAROS_START_TIME=${FAROS_START_TIME:-$FAROS_START_TIME_DEFAULT}
    FAROS_END_TIME=${FAROS_END_TIME:-$FAROS_END_TIME_DEFAULT}
}

function resolveCDInput() {
    # Required fields:
    deployment_status=${deployment_status:-$FAROS_DEPLOYMENT_STATUS}

    parseUri "${deployment_uri:-$FAROS_DEPLOYMENT}" "deployment_source" "app" "deployment_env" "deployment"

    # Artifact or VCS required for Deployment:
    use_commit=0
    if ! [ -z ${artifact_uri+x} ] || ! [ -z ${FAROS_ARTIFACT+x} ]; then
        parseUri "${artifact_uri:-$FAROS_ARTIFACT}" "artifact_source" "artifact_org" "artifact_repo" "artifact"
    elif ! [ -z ${vcs_uri+x} ] || ! [ -z ${FAROS_VCS+x} ]; then
        parseUri "${vcs_uri:-$FAROS_VCS}" "vcs_source" "vcs_org" "vcs_repo" "commit_sha"

        # Populate dummy Artifact with commit information
        artifact=$commit_sha
        artifact_repo=$vcs_repo
        artifact_org=$vcs_org
        artifact_source=$vcs_source
        use_commit=1
    else
        err "CD event requires artifact or vcs information"
        fail
    fi 

    # Optional fields:
    resolveCDDefaults
    app_platform=${app_platform:-$FAROS_APP_PLATFORM}
    deployment_env_details=${deployment_env_details:-$FAROS_DEPLOYMENT_ENV_DETAILS}
    deployment_status_details=${deploymant_status_details:-$FAROS_DEPLOYMENT_STATUS_DETAILS}
    deployment_start_time=${deployment_start_time:-$FAROS_DEPLOYMENT_START_TIME}
    deployment_end_time=${deployment_end_time:-$FAROS_DEPLOYMENT_END_TIME}

    if ! [[ ${ENVS[*]} =~ (^|[[:space:]])"$deployment_env"($|[[:space:]]) ]] ; then
      err "Invalid deployment environment: $deployment_env. Allowed values: ${envs}";
      fail
    fi
    if ! [[ ${DEPLOYMENT_STATUSES[*]} =~ (^|[[:space:]])"$deployment_status"($|[[:space:]]) ]] ; then
      err "Invalid deployment status: $deployment_status. Allowed values: ${deployment_statuses}";
      fail
    fi
}

function resolveCDDefaults() {
    FAROS_APP_PLATFORM=${FAROS_APP_PLATFORM:-$FAROS_APP_PLATFORM_DEFAULT}
    FAROS_DEPLOYMENT_ENV_DETAILS=${FAROS_DEPLOYMENT_ENV_DETAILS:-$FAROS_DEPLOYMENT_ENV_DETAILS_DEFAULT}
    FAROS_DEPLOYMENT_STATUS_DETAILS=${FAROS_DEPLOYMENT_STATUS_DETAILS:-$FAROS_DEPLOYMENT_STATUS_DETAILS_DEFAULT}
    FAROS_DEPLOYMENT_START_TIME=${FAROS_DEPLOYMENT_START_TIME:-$start_time}
    FAROS_DEPLOYMENT_END_TIME=${FAROS_DEPLOYMENT_END_TIME:-$end_time}
}

function resolveCIInput() {
    parseUri "${vcs_uri:-$FAROS_VCS}" "vcs_source" "vcs_org" "vcs_repo" "commit_sha"

    if ! [ -z ${artifact_uri+x} ] || ! [ -z ${FAROS_ARTIFACT+x} ]; then
        parseUri "${artifact_uri:-$FAROS_ARTIFACT}" "artifact_source" "artifact_org" "artifact_repo" "artifact"
    else
        # Populate dummy artifact with vcs information
        artifact=$commit_sha
        artifact_repo=$vcs_repo
        artifact_org=$vcs_org
        artifact_source=$vcs_source
    fi 
}

function resolveBuildInput() {
    # Required fields:
    build_status=${build_status:-$FAROS_BUILD_STATUS}

    # Optional fields:
    resolveBuildDefaults
    build_name=${build_name:-$FAROS_BUILD_NAME}
    build_status_details=${build_status_details:-$FAROS_BUILD_STATUS_DETAILS}
    build_start_time=${build_start_time:-$FAROS_BUILD_START_TIME}
    build_end_time=${build_end_time:-$FAROS_BUILD_END_TIME}

    if ! [[ ${BUILD_STATUSES[*]} =~ (^|[[:space:]])"$build_status"($|[[:space:]]) ]] ; then
      err "Invalid build status $build_status. Allowed values: ${build_statuses}";
      fail
    fi
}

function resolveBuildDefaults() {
    FAROS_BUILD_NAME=${FAROS_BUILD_NAME:-$FAROS_BUILD_NAME_DEFAULT}
    FAROS_BUILD_STATUS_DETAILS=${FAROS_BUILD_STATUS_DETAILS:-$FAROS_BUILD_STATUS_DETAILS_DEFAULT}
    FAROS_BUILD_START_TIME=${FAROS_BUILD_START_TIME:-$start_time}
    FAROS_BUILD_END_TIME=${FAROS_BUILD_END_TIME:-$end_time}
}

function makeDeployment() {
    cicd_Deployment=$( jq -n \
        --arg deployment "$deployment" \
        --arg deployment_source "$deployment_source" \
        --arg deployment_status "$deployment_status" \
        --arg deployment_status_details "$deployment_status_details" \
        --arg start_time "$deployment_start_time" \
        --arg end_time "$deployment_end_time" \
        --arg deployment_env "$deployment_env" \
        --arg deployment_env_details "$deployment_env_details" \
        --arg app "$app" \
        --arg app_platform "$app_platform" \
        --arg build "$build" \
        --arg pipeline "$pipeline" \
        --arg cicd_org "$cicd_org" \
        --arg cicd_source "$cicd_source" \
        '{
            "cicd_Deployment": {
                "uid": $deployment,
                "source": $deployment_source,
                "status": {
                    "category": $deployment_status,
                    "detail": $deployment_status_details
                },
                "startedAt": $start_time|tonumber,
                "endedAt": $end_time|tonumber,
                "env": {
                    "category": $deployment_env,
                    "detail": $deployment_env_details
                },
                "application" : {
                    "name": $app,
                    "platform": $app_platform
                },
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
            }
        }'
    )
}

function makeArtifact() {
    cicd_Artifact=$( jq -n \
        --arg artifact "$artifact" \
        --arg artifact_repo "$artifact_repo" \
        --arg artifact_org "$artifact_org" \
        --arg artifact_source "$artifact_source" \
        --arg build "$build" \
        --arg pipeline "$pipeline" \
        --arg cicd_org "$cicd_org" \
        --arg cicd_source "$cicd_source" \
        '{
            "cicd_Artifact": {
                "uid": $artifact,
                "build": {
                    "uid": $build,
                    "pipeline": {
                        "uid": $pipeline,
                        "organization": {
                            "uid": $cicd_org,
                            "source": $cicd_source
                        }
                    }
                },
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
}

function makeArtifactDeployment() {
    cicd_ArtifactDeployment=$( jq -n \
        --arg artifact "$artifact" \
        --arg deployment "$deployment" \
        --arg deployment_source "$deployment_source" \
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
                    "uid": $deployment,
                    "source": $deployment_source
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
        --arg build_name "$build_name" \
        --arg build_status "$build_status" \
        --arg build_status_details "$build_status_details" \
        --arg start_time "$build_start_time" \
        --arg end_time "$build_end_time" \
        --arg build "$build" \
        --arg pipeline "$pipeline" \
        --arg cicd_org "$cicd_org" \
        --arg cicd_source "$cicd_source" \
        '{
            "cicd_Build": {
                "uid": $build,
                "name": $build_name,
                "startedAt": $start_time|tonumber,
                "endedAt": $end_time|tonumber,
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
        --arg app_platform "$app_platform" \
        '{
            "compute_Application": {
                "name": $app,
                "platform": $app_platform
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
