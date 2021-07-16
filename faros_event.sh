#!/bin/bash

set -euo pipefail

version="0.0.1"
canonical_model_version="0.8.9"
github_url="https://github.com/faros-ai/faros-events-cli"

declare -a arr=("curl" "jq" "uuidgen")
for i in "${arr[@]}"; do
    which $i &> /dev/null || 
        { echo "Error: $i is required." && missing_require=1; }
done

if ((${missing_require:-0})); then
    echo "Please ensure curl, jq and uuidgen are available before running the script."
    exit 1
fi

# Defaults
FAROS_GRAPH_DEFAULT="default"
FAROS_URL_DEFAULT="https://prod.api.faros.ai"
FAROS_ORIGIN_DEFAULT="Faros_Script_Event"
FAROS_SOURCE_DEFAULT="Faros_Script"
FAROS_APP_PLATFORM_DEFAULT="NA"
FAROS_DEPLOYMENT_ENV_DETAILS_DEFAULT=""
FAROS_DEPLOYMENT_STATUS_DETAILS_DEFAULT=""
FAROS_BUILD_STATUS_DETAILS_DEFAULT=""
FAROS_START_TIME_DEFAULT=$(date +%s000000000 | cut -b1-13) # Now
FAROS_END_TIME_DEFAULT=$(date +%s000000000 | cut -b1-13) # Now
FAROS_DEPLOYMENT_DEFAULT=$(uuidgen)  # Random UUID
print_event=0
dry_run=0
silent=0
debug=0
no_format=0

# Theme
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

function help() {
    printf "${BLUE}  _____                          ${RED}  _     ___\\n"
    printf "${BLUE} |  ___|__ _  _ __  ___   ___    ${RED} / \\   |_ _| (v$version)\\n"
    printf "${BLUE} | |_  / _\` || '__|/ _ \\ / __| ${RED}  / _ \\   | |\\n"
    printf "${BLUE} |  _|| (_| || |  | (_) |\\__ \\ ${RED} / ___ \\  | |\\n"
    printf "${BLUE} |_|   \\__,_||_|   \\___/ |___/ ${RED}/_/   \\_\\|___|\\n"
    printf "${NC}\\n"
    echo
    echo "Sends deployment and/or build information to Faros."
    echo "Depending on if you are sending a deployment, build, or both, different flags will"
    echo "be required."
    echo
    printf "${RED}Canonical Model Version: v$canonical_model_version ${NC}\\n"
    echo
    printf "${RED}Required Args:${NC}\\n"
    echo "Event type (i.e. \"deployment\", \"build\", \"build_deployment\")"
    echo 
    printf "${RED}Fields:${NC} (Can be provided as flag or environment variable)\\n"
    echo "---------------------------------------------------------------------------------------------------"
    echo "Flag                                  | Environment Variable"
    echo "---------------------------------------------------------------------------------------------------"
    printf "${RED}(Required fields)${NC}\\n"
    echo "-k / --api_key <api_key>              | FAROS_API_KEY"
    echo "--app <app>                           | FAROS_APP"
    echo "--commit_sha <commit_sha>             | FAROS_COMMIT_SHA"
    echo "--pipeline <pipeline>                 | FAROS_PIPELINE"
    echo "--ci_org <ci_org>                     | FAROS_CI_ORG"
    printf "${RED}(Required deployment fields)${NC}\\n"
    echo "--deployment_env <env>                | FAROS_DEPLOYMENT_ENV"
    echo "--deployment_status <status>          | FAROS_DEPLOYMENT_STATUS"
    echo "--build <build>                       | FAROS_BUILD"
    printf "${RED}(Required build fields)${NC}\\n"
    echo "--build_status <status>               | FAROS_BUILD_STATUS"
    echo "--repo <repo>                         | FAROS_REPO"
    echo "--vcs_org <vcs_org>                   | FAROS_VCS_ORG"
    echo "--vcs_source <vcs_source>             | FAROS_VCS_SOURCE"
    echo
    echo "---------------------------------------------------------------------------------------------------"
    echo "Flag                                  | Environment Variable            | Default"
    echo "---------------------------------------------------------------------------------------------------"
    printf "${BLUE}(Optional fields)${NC}\\n"
    echo "-u / --url <url>                      | FAROS_URL                       | $FAROS_URL_DEFAULT"
    echo "-g / --graph <graph>                  | FAROS_GRAPH                     | \"$FAROS_GRAPH_DEFAULT\""
    echo "--origin <origin>                     | FAROS_ORIGIN                    | \"$FAROS_ORIGIN_DEFAULT\""
    echo "--source <source>                     | FAROS_SOURCE                    | \"$FAROS_SOURCE_DEFAULT\""
    echo "--start_time <start>                  | FAROS_START_TIME                | Now"
    echo "--end_time <end>                      | FAROS_END_TIME                  | Now"
    printf "${BLUE}(Optional deployment fields)${NC}\\n"
    echo "--deployment <deployment>             | FAROS_DEPLOYMENT                | Random UUID"
    echo "--app_platform <platform>             | FAROS_APP_PLATFORM              | \"$FAROS_APP_PLATFORM_DEFAULT\""
    echo "--deployment_env_details <details>    | FAROS_DEPLOYMENT_ENV_DETAILS    | \"$FAROS_DEPLOYMENT_ENV_DETAILS_DEFAULT\""
    echo "--deployment_status_details <details> | FAROS_DEPLOYMENT_STATUS_DETAILS | \"$FAROS_DEPLOYMENT_STATUS_DETAILS_DEFAULT\""
    echo "--deployment_start_time <start>       | FAROS_DEPLOYMENT_START_TIME     | FAROS_START_TIME"
    echo "--deployment_end_time <end>           | FAROS_DEPLOYMENT_END_TIME       | FAROS_END_TIME"
    printf "${BLUE}(Optional build fields)${NC}\\n"
    echo "--build <build>                       | FAROS_BUILD                     | FAROS_COMMIT_SHA"
    echo "--build_status_details <details>      | FAROS_BUILD_STATUS_DETAILS      | \"$FAROS_BUILD_STATUS_DETAILS_DEFAULT\""
    echo "--build_start_time <start>            | FAROS_BUILD_START_TIME          | FAROS_START_TIME"
    echo "--build_end_time <end>                | FAROS_BUILD_END_TIME            | FAROS_END_TIME"
    echo
    printf "${BLUE}Additional settings flags:${NC}\\n"
    echo "--dry_run     Print the event instead of sending."
    echo "--silent      Unexceptional output will be silenced."
    echo "--debug       Helpful information will be printed."
    echo "--no_format   Log formatting will be turned off."
    echo
    echo "For more usage information please visit:"
    printf "${RED}$github_url"
    echo
    exit 0
}

main() {
    parseFlags "$@"
    set -- ${POSITIONAL[@]:-} # restore positional parameters
    parsePositionalArgs "$@"
    resolveInput

    if ((debug)); then
        echo "Faros url: $api_url"
        echo "Faros graph: $graph"
        echo "Dry run: $dry_run"
        echo "Silent: $print_event"
        echo "Debug: $debug"
    fi

    if [ $EVENT_TYPE = "deployment" ]; then
        resolveDeploymentInput
        makeDeploymentEvent
    elif [ $EVENT_TYPE = "build" ]; then
        resolveBuildInput
        makeBuildEvent
    elif [ $EVENT_TYPE = "build_deployment" ]; then
        resolveBuildInput
        resolveDeploymentInput
        makeBuildDeploymentEvent
    else
        err "Unrecognized event type: $EVENT_TYPE \n
            Valid event types: deployment, build, full."
        fail
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
            --app)
                app="$2"
                shift 2 ;;
            --app_platform)
                app_platform="$2"
                shift 2 ;;
            --commit_sha)
                commit_sha="$2"
                shift 2 ;;
            --pipeline)
                pipeline="$2"
                shift 2 ;;
            --deployment)
                deployment="$2"
                shift 2 ;;
            --deployment_env)
                deployment_env="$2"
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
            --build)
                build="$2"
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
            --ci_org)
                ci_org="$2"
                shift 2 ;;
            --vcs_source)
                vcs_source="$2"
                shift 2 ;;
            --vcs_org)
                vcs_org="$2"
                shift 2 ;;
            --repo)
                repo="$2"
                shift 2 ;;
            -g|--graph)
                graph="$2"
                shift 2 ;;
            --origin)
                origin="$2"
                shift 2 ;;
            --source)
                source="$2"
                shift 2 ;;
            -u|--url)
                url="$2"
                shift 2 ;;
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

function parsePositionalArgs() {
    # No positional arg passed - show help
    if !(($#)); then
        help
        exit 0
    fi

    # Loop through positional arguments and process them
    while (($#)); do
        case "$1" in
            deployment)
                EVENT_TYPE="deployment"
                shift ;;
            build)
                EVENT_TYPE="build"
                shift ;;
            build_deployment)
                EVENT_TYPE="build_deployment"
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

function resolveInput() {
    # Required fields:
    api_key=${api_key:-$FAROS_API_KEY}
    app=${app:-$FAROS_APP}
    commit_sha=${commit_sha:-$FAROS_COMMIT_SHA}
    pipeline=${pipeline:-$FAROS_PIPELINE}
    ci_org=${ci_org:-$FAROS_CI_ORG}

    # Optional fields:
    resolveDefaults
    graph=${graph:-$FAROS_GRAPH}
    url=${url:-$FAROS_URL}
    origin=${origin:-$FAROS_ORIGIN}
    source=${source:-$FAROS_SOURCE}
    app_platform=${app_platform:-$FAROS_APP_PLATFORM}
    start_time=${start_time:-$FAROS_START_TIME}
    end_time=${end_time:-$FAROS_END_TIME}
    
    # Optional script settings: If unset then false
    print_event=${print_event:-0}
    dry_run=${dry_run:-0}
    silent=${silent:-0}
    debug=${debug:-0}
}

function resolveDefaults() {
    FAROS_GRAPH=${FAROS_GRAPH:-$FAROS_GRAPH_DEFAULT}
    FAROS_URL=${FAROS_URL:-$FAROS_URL_DEFAULT}
    FAROS_ORIGIN=${FAROS_ORIGIN:-$FAROS_ORIGIN_DEFAULT}
    FAROS_SOURCE=${FAROS_SOURCE:-$FAROS_SOURCE_DEFAULT}
    FAROS_APP_PLATFORM=${FAROS_APP_PLATFORM:-$FAROS_APP_PLATFORM_DEFAULT}
    # Default start time and end time to now
    FAROS_START_TIME=${FAROS_START_TIME:-$FAROS_START_TIME_DEFAULT}
    FAROS_END_TIME=${FAROS_END_TIME:-$FAROS_END_TIME_DEFAULT}
}

function resolveDeploymentInput() {
    # Required fields:
    deployment_env=${deployment_env:-$FAROS_DEPLOYMENT_ENV}
    deployment_status=${deployment_status:-$FAROS_DEPLOYMENT_STATUS}
    
    # build required for deployment (Allow build to resolve input first)
    build=${build:-$FAROS_BUILD}

    # Optional fields:
    resolveDeploymentDefaults
    deployment=${deployment:-$FAROS_DEPLOYMENT}
    deployment_env_details=${deployment_env_details:-$FAROS_DEPLOYMENT_ENV_DETAILS}
    deployment_status_details=${deploymant_status_details:-$FAROS_DEPLOYMENT_STATUS_DETAILS}
    deployment_start_time=${deployment_start_time:-$FAROS_DEPLOYMENT_START_TIME}
    deployment_end_time=${deployment_end_time:-$FAROS_DEPLOYMENT_END_TIME}
}

function resolveDeploymentDefaults() {
    FAROS_DEPLOYMENT=${FAROS_DEPLOYMENT:-$FAROS_DEPLOYMENT_DEFAULT}
    FAROS_DEPLOYMENT_ENV_DETAILS=${FAROS_DEPLOYMENT_ENV_DETAILS:-$FAROS_DEPLOYMENT_ENV_DETAILS_DEFAULT}
    FAROS_DEPLOYMENT_STATUS_DETAILS=${FAROS_DEPLOYMENT_STATUS_DETAILS:-$FAROS_DEPLOYMENT_STATUS_DETAILS_DEFAULT}
    FAROS_DEPLOYMENT_START_TIME=${FAROS_DEPLOYMENT_START_TIME:-$start_time}
    FAROS_DEPLOYMENT_END_TIME=${FAROS_DEPLOYMENT_END_TIME:-$end_time}
}

function resolveBuildInput() {
    # Required fields:
    build_status=${build_status:-$FAROS_BUILD_STATUS}
    repo=${repo:-$FAROS_REPO}
    vcs_source=${vcs_source:-$FAROS_VCS_SOURCE}
    vcs_org=${vcs_org:-$FAROS_VCS_ORG}

    # Optional fields:
    resolveBuildDefaults
    build=${build:-$FAROS_BUILD}
    build_status_details=${build_status_details:-$FAROS_BUILD_STATUS_DETAILS}
    build_start_time=${build_start_time:-$FAROS_BUILD_START_TIME}
    build_end_time=${build_end_time:-$FAROS_BUILD_END_TIME}
}

function resolveBuildDefaults() {
    FAROS_BUILD=${FAROS_BUILD:-$commit_sha} # default to commit sha
    FAROS_BUILD_STATUS_DETAILS=${FAROS_BUILD_STATUS_DETAILS:-$FAROS_BUILD_STATUS_DETAILS_DEFAULT}
    FAROS_BUILD_START_TIME=${FAROS_BUILD_START_TIME:-$start_time}
    FAROS_BUILD_END_TIME=${FAROS_BUILD_END_TIME:-$end_time}
}

function makeDeployment() {
    cicd_Deployment=$( jq -n \
        --arg s "$source" \
        --arg deployment "$deployment" \
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
        --arg ci_org "$ci_org" \
        '{
            "cicd_Deployment": {
                "uid": $deployment,
                "source": $s,
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
                            "uid": $ci_org,
                            "source": $s
                        }
                    }
                }
            }
        }'
    )
}

function makeBuild() {
    cicd_Build=$( jq -n \
        --arg s "$source" \
        --arg build "$build" \
        --arg build_status "$build_status" \
        --arg start_time "$build_start_time" \
        --arg end_time "$build_end_time" \
        --arg build_status_details "$build_status_details" \
        --arg pipeline "$pipeline" \
        --arg ci_org "$ci_org" \
        '{
            "cicd_Build": {
                "uid": $build,
                "startedAt": $start_time|tonumber,
                "endedAt": $end_time|tonumber,
                "status": {
                    "category": $build_status,
                    "detail": $build_status_details
                },
                "pipeline": {
                    "uid": $pipeline,
                    "organization": {
                        "uid": $ci_org,
                        "source": $s
                    }
                }
            }
        }'
    )
}

function makeBuildCommitAssociation() {
    cicd_BuildCommitAssociation=$( jq -n \
        --arg s "$source" \
        --arg build "$build" \
        --arg pipeline "$pipeline" \
        --arg ci_org "$ci_org" \
        --arg vcs_org "$vcs_org" \
        --arg vcs_source "$vcs_source" \
        --arg commit_sha "$commit_sha" \
        --arg repo "$repo" \
        '{
            "cicd_BuildCommitAssociation": {
                "build": {
                    "uid": $build,
                    "pipeline": {
                        "uid": $pipeline,
                        "organization": {
                            "uid": $ci_org,
                            "source": $s
                        }
                    }
                },
                "commit": {
                    "sha": $commit_sha,
                    "repository": {
                        "name": $repo,
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

function makePipeline() {
    cicd_Pipeline=$( jq -n \
        --arg s "$source" \
        --arg pipeline "$pipeline" \
        --arg ci_org "$ci_org" \
        '{
            "cicd_Pipeline": {
                "uid": $pipeline,
                "organization": {
                    "uid": $ci_org,
                    "source": $s
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

function makeBuildEvent() {
    makeBuild
    makeBuildCommitAssociation
    makePipeline
    makeApplication
    request_body=$( jq -n \
        --arg origin "$origin" \
        --argjson build "$cicd_Build" \
        --argjson buildCommit "$cicd_BuildCommitAssociation" \
        --argjson pipeline "$cicd_Pipeline" \
        --argjson application "$compute_Application" \
        '{ 
            "origin": $origin,
            "entries": [
                $build,
                $buildCommit,
                $pipeline,
                $application
            ]
        }'
    )
}

function makeDeploymentEvent() {
    makeDeployment
    makeApplication
    request_body=$( jq -n \
        --arg origin "$origin" \
        --argjson deployment "$cicd_Deployment" \
        '{ 
            "origin": $origin,
            "entries": [
                $deployment
            ]
        }'
    )
}

function makeBuildDeploymentEvent() {
    makeDeployment
    makeBuild
    makeBuildCommitAssociation
    makePipeline
    makeApplication
    request_body=$( jq -n \
        --arg origin "$origin" \
        --argjson deployment "$cicd_Deployment" \
        --argjson build "$cicd_Build" \
        --argjson buildCommit "$cicd_BuildCommitAssociation" \
        --argjson pipeline "$cicd_Pipeline" \
        --argjson application "$compute_Application" \
        '{ 
            "origin": $origin,
            "entries": [
                $deployment,
                $build,
                $buildCommit,
                $pipeline,
                $application
            ]
        }'
    )
}

function sendEventToFaros() {
    log "Sending event to Faros..."

    http_response=$(curl --retry 5 --retry-delay 5 \
        --silent --write-out "HTTPSTATUS:%{http_code}" -X POST \
        $url/graphs/$graph/revisions \
        -H "authorization: $api_key" \
        -H "content-type: application/json" \
        -d "$request_body") 

    # extract the status
    http_response_status=$(echo $http_response | tr -d '\n' | sed -e 's/.*HTTPSTATUS://')

    # extract the body
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
            echo "$*" | jq
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
