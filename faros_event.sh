#!/bin/bash

set -euo pipefail

version="0.2.0"
canonical_model_version="0.8.10"
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
FAROS_APP_PLATFORM_DEFAULT=""
FAROS_DEPLOYMENT_ENV_DETAILS_DEFAULT=""
FAROS_DEPLOYMENT_STATUS_DETAILS_DEFAULT=""
FAROS_BUILD_NAME_DEFAULT=""
FAROS_BUILD_STATUS_DETAILS_DEFAULT=""
FAROS_START_TIME_DEFAULT=$(date +%s000000000 | cut -b1-13) # Now
FAROS_END_TIME_DEFAULT=$(date +%s000000000 | cut -b1-13) # Now
FAROS_DEPLOYMENT_DEFAULT=$(uuidgen) # Random UUID
FAROS_ARTIFACT_DEFAULT=${FAROS_ARTIFACT_DEFAULT:-$(uuidgen)} # Random UUID

declare -a ENVS=("Prod" "Staging" "QA" "Dev" "Sandbox" "Custom")
envs=$(printf '%s\n' "$(IFS=,; printf '%s' "${ENVS[*]}")")
declare -a BUILD_STATUSES=("Success" "Failed" "Canceled" "Queued" "Running" "Unknown" "Custom")
build_statuses=$(printf '%s\n' "$(IFS=,; printf '%s' "${BUILD_STATUSES[*]}")")
declare -a DEPLOYMENT_STATUSES=("Success" "Failed" "Canceled" "Queued" "Running" "RolledBack" "Custom")
deployment_statuses=$(printf '%s\n' "$(IFS=,; printf '%s' "${DEPLOYMENT_STATUSES[*]}")")

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
    printf "${RED}Canonical Model Version: v$canonical_model_version ${NC}\\n"
    echo
    echo "This script sends information to Faros."
    echo "There are multiple event types that can be used, each with a set of required and optional fields."
    echo "More than one event type can be used at the same time."
    echo
    printf "${RED}Args:${NC}\\n"
    echo "Event type (\"deployment\", \"build\", \"artifact\")"
    echo 
    printf "${RED}Fields:${NC} (Can be provided as flag or environment variable)\\n"
    echo "---------------------------------------------------------------------------------------------------"
    echo "Flag                                  | Environment Variable            | Allowed Values"
    echo "---------------------------------------------------------------------------------------------------"
    printf "${RED}(Required fields)${NC}\\n"
    echo "-k / --api_key <api_key>              | FAROS_API_KEY                   |"
    echo "--build <build>                       | FAROS_BUILD                     |"
    echo "--pipeline <pipeline>                 | FAROS_PIPELINE                  |"
    echo "--cicd_org <cicd_org>                 | FAROS_CICD_ORG                  |"
    echo "--cicd_source <cicd_source>           | FAROS_CICD_SOURCE               |"
    printf "${RED}(Required deployment fields)${NC}\\n"
    echo "--app <app>                           | FAROS_APP                       |"
    echo "--deployment_source <source>          | FAROS_DEPLOYMENT_SOURCE         |"
    echo "--deployment_env <env>                | FAROS_DEPLOYMENT_ENV            | ${envs}"
    echo "--deployment_status <status>          | FAROS_DEPLOYMENT_STATUS         | ${deployment_statuses}"
    printf "${RED}(Required build fields)${NC}\\n"
    echo "--build_status <status>               | FAROS_BUILD_STATUS              | ${build_statuses}"
    printf "${RED}(Required artifact fields)${NC}\\n"
    echo "--artifact <artifact>                 | FAROS_ARTIFACT                  |"
    echo "--artifact_repo <artifact_repo>       | FAROS_ARTIFACT_REPO             |"
    echo "--artifact_org <artifact_org>         | FAROS_ARTIFACT_ORG              |"
    echo "--artifact_source <artifact_source>   | FAROS_ARTIFACT_SOURCE           |"
    echo "--commit_sha <commit_sha>             | FAROS_COMMIT_SHA                |"
    echo "--vcs_repo <vcs_repo>                 | FAROS_VCS_REPO                  |"
    echo "--vcs_org <vcs_org>                   | FAROS_VCS_ORG                   |"
    echo "--vcs_source <vcs_source>             | FAROS_VCS_SOURCE                |"
    echo
    echo "---------------------------------------------------------------------------------------------------"
    echo "Flag                                  | Environment Variable            | Default"
    echo "---------------------------------------------------------------------------------------------------"
    printf "${BLUE}(Optional fields)${NC}\\n"
    echo "-u / --url <url>                      | FAROS_URL                       | $FAROS_URL_DEFAULT"
    echo "-g / --graph <graph>                  | FAROS_GRAPH                     | \"$FAROS_GRAPH_DEFAULT\""
    echo "--origin <origin>                     | FAROS_ORIGIN                    | \"$FAROS_ORIGIN_DEFAULT\""
    echo "--start_time <start>                  | FAROS_START_TIME                | Now"
    echo "--end_time <end>                      | FAROS_END_TIME                  | Now"
    printf "${BLUE}(Optional deployment fields)${NC}\\n"
    echo "--deployment <deployment>             | FAROS_DEPLOYMENT                | Random UUID"
    echo "--deployment_env_details <details>    | FAROS_DEPLOYMENT_ENV_DETAILS    | \"$FAROS_DEPLOYMENT_ENV_DETAILS_DEFAULT\""
    echo "--deployment_status_details <details> | FAROS_DEPLOYMENT_STATUS_DETAILS | \"$FAROS_DEPLOYMENT_STATUS_DETAILS_DEFAULT\""
    echo "--deployment_start_time <start>       | FAROS_DEPLOYMENT_START_TIME     | FAROS_START_TIME"
    echo "--deployment_end_time <end>           | FAROS_DEPLOYMENT_END_TIME       | FAROS_END_TIME"
    echo "--app_platform <platform>             | FAROS_APP_PLATFORM              | \"$FAROS_APP_PLATFORM_DEFAULT\""
    printf "${BLUE}(Optional build fields)${NC}\\n"
    echo "--build_name <build_name>             | FAROS_BUILD_NAME                | \"$FAROS_BUILD_NAME_DEFAULT\""
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
    echo "For more usage information please visit: $github_url"
    echo
    exit 0
}

main() {
    parseFlags "$@"
    set -- ${POSITIONAL[@]:-} # restore positional args
    resolveInput

    makeEvent # create the event that objects will be added to
    processArgs "$@" # populate event depending on passed event types

    if ((make_cicd_objects)); then
        addCICDObjectsToEvent
    fi

    if ((debug)); then
        echo "Faros url: $url"
        echo "Faros graph: $graph"
        echo "Dry run: $dry_run"
        echo "Silent: $print_event"
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
            --deployment_source)
                deployment_source="$2"
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
            --cicd_org)
                cicd_org="$2"
                shift 2 ;;
            --cicd_source)
                cicd_source="$2"
                shift 2 ;;
            --artifact)
                artifact="$2"
                shift 2 ;;
            --artifact_repo)
                artifact_repo="$2"
                shift 2 ;;
            --artifact_org)
                artifact_org="$2"
                shift 2 ;;
            --artifact_source)
                artifact_source="$2"
                shift 2 ;;
            --vcs_repo)
                vcs_repo="$2"
                shift 2 ;;
            --vcs_org)
                vcs_org="$2"
                shift 2 ;;
            --vcs_source)
                vcs_source="$2"
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
            --make_cicd_objects)
                make_cicd_objects=1
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

# Depending on passed event type resolve input and populate event
function processArgs() {
    # No positional arg passed - show help
    if !(($#)); then
        help
        exit 0
    fi

    # Loop through positional arguments and process them
    while (($#)); do
        case "$1" in
            deployment)
                resolveDeploymentInput
                addDeploymentToEvent
                if ((use_commit)); then
                    # Dummy Artifact will be used
                    addArtifactCommitToDeployment
                fi
                shift ;;
            build)
                resolveBuildInput
                addBuildToEvent
                shift ;;
            artifact)
                resolveArtifactInput
                addArtifactToEvent
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
    build=${build:-$FAROS_BUILD}
    pipeline=${pipeline:-$FAROS_PIPELINE}
    cicd_org=${cicd_org:-$FAROS_CICD_ORG}
    cicd_source=${cicd_source:-$FAROS_CICD_SOURCE}

    # Optional fields:
    resolveDefaults
    graph=${graph:-$FAROS_GRAPH}
    url=${url:-$FAROS_URL}
    origin=${origin:-$FAROS_ORIGIN}
    start_time=${start_time:-$FAROS_START_TIME}
    end_time=${end_time:-$FAROS_END_TIME}
    
    # Optional script settings: If unset then false
    make_cicd_objects=${make_cicd_objects:-0}
    print_event=${print_event:-0}
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

function resolveDeploymentInput() {
    # Required fields:
    app=${app:-$FAROS_APP}
    deployment=${deployment:-$FAROS_DEPLOYMENT}
    deployment_source=${deployment_source:-$FAROS_DEPLOYMENT_SOURCE}
    deployment_env=${deployment_env:-$FAROS_DEPLOYMENT_ENV}
    deployment_status=${deployment_status:-$FAROS_DEPLOYMENT_STATUS}

    # Artifact or Commit required for Deployment:
    use_commit=0
    if ! [ -z ${artifact+x} ] || ! [ -z ${ARTIFACT+x} ]; then
        artifact=${artifact:-$ARTIFACT}
        artifact_repo=${artifact_repo:-$ARTIFACT_REPO}
        artifact_org=${artifact_org:-$ARTIFACT_ORG}
        artifact_source=${artifact_source:-$ARTIFACT_SOURCE}
    elif ! [ -z ${commit_sha+x} ] || ! [ -z ${FAROS_COMMIT_SHA+x} ]; then
        commit_sha=${commit_sha:-$FAROS_COMMIT_SHA}
        vcs_repo=${vcs_repo:-$FAROS_REPO}
        vcs_org=${vcs_org:-$FAROS_VCS_ORG}
        vcs_source=${vcs_source:-$FAROS_VCS_SOURCE}
        # Populate dummy Artifact
        artifact=$FAROS_ARTIFACT_DEFAULT
        artifact_repo=""
        artifact_org=""
        artifact_source=""
        use_commit=1
    else
        err "Deployment event requires artifact or commit information"
        fail
    fi 

    # Optional fields:
    resolveDeploymentDefaults
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

function resolveDeploymentDefaults() {
    FAROS_APP_PLATFORM=${FAROS_APP_PLATFORM:-$FAROS_APP_PLATFORM_DEFAULT}
    FAROS_DEPLOYMENT=${FAROS_DEPLOYMENT:-$FAROS_DEPLOYMENT_DEFAULT}
    FAROS_DEPLOYMENT_ENV_DETAILS=${FAROS_DEPLOYMENT_ENV_DETAILS:-$FAROS_DEPLOYMENT_ENV_DETAILS_DEFAULT}
    FAROS_DEPLOYMENT_STATUS_DETAILS=${FAROS_DEPLOYMENT_STATUS_DETAILS:-$FAROS_DEPLOYMENT_STATUS_DETAILS_DEFAULT}
    FAROS_DEPLOYMENT_START_TIME=${FAROS_DEPLOYMENT_START_TIME:-$start_time}
    FAROS_DEPLOYMENT_END_TIME=${FAROS_DEPLOYMENT_END_TIME:-$end_time}
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

function resolveArtifactInput() {
    artifact=${artifact:-$ARTIFACT}
    artifact_repo=${artifact_repo:-$ARTIFACT_REPO}
    artifact_org=${artifact_org:-$ARTIFACT_ORG}
    artifact_source=${artifact_source:-$ARTIFACT_SOURCE}
    commit_sha=${commit_sha:-$FAROS_COMMIT_SHA}
    vcs_repo=${vcs_repo:-$FAROS_REPO}
    vcs_org=${vcs_org:-$FAROS_VCS_ORG}
    vcs_source=${vcs_source:-$FAROS_VCS_SOURCE}
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

function addDeploymentToEvent() {
    makeDeployment
    makeArtifactDeployment
    makeApplication
    request_body=$(jq ".entries += [
        $cicd_Deployment,
        $cicd_ArtifactDeployment,
        $compute_Application
    ]" <<< $request_body)
}

function addArtifactToEvent() {
    makeArtifact
    makeArtifactCommitAssociation
    request_body=$(jq ".entries += [
        $cicd_Artifact,
        $cicd_ArtifactCommitAssociation
    ]" <<< $request_body)
}

function addArtifactCommitToDeployment() {
    makeArtifactCommitAssociation
    request_body=$(jq ".entries += [
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
