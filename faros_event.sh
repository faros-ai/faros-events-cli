#!/bin/bash

set -euo pipefail

which curl &> /dev/null || 
    { echo "Error: curl is required." && missing_require=1; }
which jq &> /dev/null || 
    { echo "Error: jq is required." && missing_require=1; }

if ((${missing_require:-0}))
then
    echo "Please ensure curl, and jq are available before running the script."
    exit 1
fi

# Sends deployment and/or build information to Faros.
# Depending on if you are sending a deployment, build, or both different flags
# will be required.
#
# Canonical Model Version: v0.8.9
# https://github.com/faros-ai/canonical-models/tree/v0.8.9
#
# Required args:
# Arg  | Description
# -----------------------------------------------------------------------------
# arg1 | Emit type: "deployment", "build", "full" (must be first arg)
# 
# Required fields:
# Flag                           | Env Var
# -----------------------------------------------------------------------------
# -k / --api_key <api_key>       | FAROS_API_KEY
# -a / --application <app_name>  | APPLICATION_NAME
# -c / --commit <commit_sha>     | COMMIT_SHA
# -p / --pipeline <pipeline>     | PIPELINE_UID
# --ci_org <ci_org>              | CI_ORG_UID
#
# (Required deployment fields)
# -e / --environment <env>       | DEPLOYMENT_ENV
# -ds / --deploy_status <status> | DEPLOYMENT_STATUS (e.g. Success, Failed, etc)
#
# (Required build fields)
# -bs / --build_status <status>  | BUILD_STATUS (e.g. Success, Failed, etc)
# -r / --repo <repo>             | REPOSITORY
# --vcs_org <vcs_org>            | VCS_ORG_UID
# --vcs_source <vcs_source>      | VCS_SOURCE
#
# Optional fields:
# Flag                  | Env Var                  | Default
# -----------------------------------------------------------------------------
# -g / --graph <graph>  | FAROS_GRAPH              | "default"
# -url <url>            | FAROS_API_URL            | https://prod.api.faros.ai
#                       | ORIGIN                   | "Faros_Script_Event"
#                       | SOURCE                   | "Faros_Script"
#                       | START_TIME               | Now (e.g. 1549932180000)
#                       | END_TIME                 | Now (e.g. 1549932180000)
#
# (Optional deployment fields)
#                       | DEPLOYMENT_UID           | Random UUID
#                       | APPLICATION_PLATFORM     | "NA"
#                       | DEPLOYMENT_ENV_DETAIL    | ""
#                       | DEPLOYMENT_STATUS_DETAIL | ""
#                       | DEPLOYMENT_START_TIME    | START_TIME
#                       | DEPLOYMENT_END_TIME      | END_TIME
#
# (Optional build fields)
#                       | BUILD_UID                | Commit Sha
#                       | BUILD_STATUS_DETAIL      | ""
#                       | BUILD_START_TIME         | START_TIME
#                       | BUILD_END_TIME           | END_TIME
#
# Optional Script Flags:
# Flag          | Description
# -----------------------------------------------------------------------------
# --dry_run     | If present, the event will be printed instead of emitted.
# --print_event | If present, the event will be printed.
# --debug       | If present, helpful information will be printed.
main() {
    EVENT_TYPE=$1
    shift

    parseArgs "$@"  
    validateInput

    if ((debug))
    then
        echo "Faros url: $faros_api_url"
        echo "Faros graph: $faros_graph"
        echo "Dry run: $dry_run"
        echo "Print event: $print_event"
        echo "Debug: $debug"
    fi

    if [ $EVENT_TYPE = "deployment" ]
    then
        validateDeploymentInput
        makeDeploymentEvent
    elif [ $EVENT_TYPE = "build" ]
    then
        validateBuildInput
        makeBuildEvent
    elif [ $EVENT_TYPE = "full" ]
    then
        validateBuildInput
        validateDeploymentInput
        makeFullEvent
    else
        echo "Unrecognized event type: $EVENT_TYPE"
        echo "Valid event types: deployment, build, full."
        exit 1
    fi

    if (($print_event)) || (($dry_run))
    then
        echo "Request:"
        echo $request_body | jq
    fi

    if !(($dry_run))
    then
        sendEventToFaros
    else
        echo "Dry run: Event NOT sent to Faros."
    fi

    if (($print_event))
    then
        echo "Response:"
        echo $response_json | jq
    fi

    echo "Done."
    exit 0
}

function parseArgs() {
    # Loop through arguments and process them
    while (($#))
    do
        case "$1" in
            -k|--api_key)
                faros_api_key="$2"
                shift 2
                ;;
            -a|--application)
                application_name="$2"
                shift 2
                ;;
            -c|--commit)
                commit_sha="$2"
                shift 2 
                ;;
            -p|--pipeline)
                pipeline_uid="$2"
                shift 2
                ;;
            -e|--environment)
                deployment_env="$2"
                shift 2
                ;;
            -ds|--deploy_status)
                deployment_status="$2"
                shift 2
                ;;
            -bs|--build_status)
                build_status="$2"
                shift 2
                ;;
            --ci_org)
                ci_org_uid="$2"
                shift 2
                ;;
            --vcs_source)
                vcs_source="$2"
                shift 2
                ;;
            --vcs_org)
                vcs_org_uid="$2"
                shift 2
                ;;
            -r|--repo)
                repository="$2"
                shift 2
                ;;
            -g|--graph)
                faros_graph="$2"
                shift 2
                ;;
            --url)
                faros_api_url="$2"
                shift 2
                ;;
            --dry_run)
                dry_run=1
                shift
                ;;
            --print_event)
                print_event=1
                shift
                ;;
            --debug)
                debug=1
                shift
                ;;
            *)
                echo "Unrecognized flag: $1"
                exit 1
        esac
    done
}

function validateInput() {
    # Required fields: If flag missing fall back to env var
    faros_api_key=${faros_api_key:-$FAROS_API_KEY}
    application_name=${application_name:-$APPLICATION_NAME}
    commit_sha=${commit_sha:-$COMMIT_SHA}
    pipeline_uid=${pipeline_uid:-$PIPELINE_UID}
    ci_org_uid=${ci_org_uid:-$CI_ORG_UID}

    # Optional fields: If flag missing fall back to env var then defualt
    FAROS_GRAPH=${FAROS_GRAPH:-"default"}
    faros_graph=${faros_graph:-$FAROS_GRAPH}

    FAROS_API_URL=${FAROS_API_URL:-"https://prod.api.faros.ai"}
    faros_api_url=${faros_api_url:-$FAROS_API_URL}

    # Optional fields (No flag offered): If unset use default
    ORIGIN=${ORIGIN:-"Faros_Script_Event"}
    SOURCE=${SOURCE:-"Faros_Script"}
    APPLICATION_PLATFORM=${APPLICATION_PLATFORM:-"NA"}
    START_TIME=${START_TIME:-$( date +%s000000000 | cut -b1-13 )} # default now
    END_TIME=${END_TIME:-$( date +%s000000000 | cut -b1-13 )} # default now

    # Optional script settings: If unset use default
    print_event=${print_event:-0}
    dry_run=${dry_run:-0}
    debug=${debug:-0}
}

function validateDeploymentInput() {
    # Required fields:
    deployment_env=${deployment_env:-$DEPLOYMENT_ENV}
    deployment_status=${deployment_status:-$DEPLOYMENT_STATUS}
    
    # A build field needed
    BUILD_UID=${BUILD_UID:-$commit_sha} # default Commit Sha

    # Optional fields (No flag offered): If unset use default
    DEPLOYMENT_UID=${DEPLOYMENT_UID:-$(uuidgen)} # default Random UUID
    DEPLOYMENT_ENV_DETAIL=${DEPLOYMENT_ENV_DETAIL:-""}
    DEPLOYMENT_STATUS_DETAIL=${DEPLOYMENT_STATUS_DETAIL:-""}
    DEPLOYMENT_START_TIME=${DEPLOYMENT_START_TIME:-$START_TIME}
    DEPLOYMENT_END_TIME=${DEPLOYMENT_END_TIME:-$END_TIME}
}

function validateBuildInput() {
    # Required fields:
    build_status=${build_status:-$BUILD_STATUS}
    repository=${repository:-$REPOSITORY}
    vcs_source=${vcs_source:-$VCS_SOURCE}
    vcs_org_uid=${vcs_org_uid:-$VCS_ORG_UID}

    # Optional fields (no flag offered): If unset use default
    BUILD_UID=${BUILD_UID:-$commit_sha} # default Commit Sha
    BUILD_START_TIME=${BUILD_START_TIME:-$START_TIME}
    BUILD_END_TIME=${BUILD_END_TIME:-$END_TIME}
    BUILD_STATUS_DETAIL=${BUILD_STATUS_DETAIL:-""}
}

function makeDeployment() {
    cicd_Deployment=$( jq -n \
        --arg s "$SOURCE" \
        --arg deployment_uid "$DEPLOYMENT_UID" \
        --arg deployment_status "$deployment_status" \
        --arg start_time "$START_TIME" \
        --arg end_time "$END_TIME" \
        --arg deployment_env "$deployment_env" \
        --arg application_name "$application_name" \
        --arg application_platform "$APPLICATION_PLATFORM" \
        --arg build_uid "$BUILD_UID" \
        --arg pipeline_uid "$pipeline_uid" \
        --arg ci_org_uid "$ci_org_uid" \
        '{
            "cicd_Deployment": {
                "uid": $deployment_uid,
                "source": $s,
                "status": {
                    "category": $deployment_status,
                    "detail": ""
                },
                "startedAt": $start_time|tonumber,
                "endedAt": $end_time|tonumber,
                "env": {
                    "category": $deployment_env,
                    "detail": ""
                },
                "application" : {
                    "name": $application_name,
                    "platform": $application_platform
                },
                "build": {
                    "uid": $build_uid,
                    "pipeline": {
                        "uid": $pipeline_uid,
                        "organization": {
                            "uid": $ci_org_uid,
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
        --arg s "$SOURCE" \
        --arg build_uid "$BUILD_UID" \
        --arg build_status "$build_status" \
        --arg start_time "$BUILD_START_TIME" \
        --arg end_time "$BUILD_END_TIME" \
        --arg build_status_detail "$BUILD_STATUS_DETAIL" \
        --arg pipeline_uid "$pipeline_uid" \
        --arg ci_org_uid "$ci_org_uid" \
        '{
            "cicd_Build": {
                "uid": $build_uid,
                "startedAt": $start_time|tonumber,
                "endedAt": $end_time|tonumber,
                "status": {
                    "category": $build_status,
                    "detail": $build_status_detail
                },
                "pipeline": {
                    "uid": $pipeline_uid,
                    "organization": {
                        "uid": $ci_org_uid,
                        "source": $s
                    }
                }
            }
        }'
    )
}

function makeBuildCommitAssociation() {
    cicd_BuildCommitAssociation=$( jq -n \
        --arg s "$SOURCE" \
        --arg build_uid "$BUILD_UID" \
        --arg pipeline_uid "$pipeline_uid" \
        --arg ci_org_uid "$ci_org_uid" \
        --arg vcs_org_uid "$vcs_org_uid" \
        --arg vcs_source "$vcs_source" \
        --arg commit_sha "$commit_sha" \
        --arg repo "$repository" \
        '{
            "cicd_BuildCommitAssociation": {
                "build": {
                    "uid": $build_uid,
                    "pipeline": {
                        "uid": $pipeline_uid,
                        "organization": {
                            "uid": $ci_org_uid,
                            "source": $s
                        }
                    }
                },
                "commit": {
                "repository": {
                    "organization": {
                        "uid": $vcs_org_uid,
                        "source": $vcs_source
                    },
                    "name": $repo
                },
                "sha": $commit_sha
                }
            }
        }'
    )
}

function makePipeline() {
    cicd_Pipeline=$( jq -n \
        --arg s "$SOURCE" \
        --arg pipeline_uid "$pipeline_uid" \
        --arg ci_org_uid "$ci_org_uid" \
        '{
            "cicd_Pipeline": {
                "uid": $pipeline_uid,
                "organization": {
                    "uid": $ci_org_uid,
                    "source": $s
                }
            }
        }'
    )
}

function makeApplication() {
    compute_Application=$( jq -n \
        --arg app_name "$application_name" \
        --arg app_platform "$APPLICATION_PLATFORM" \
        '{
            "compute_Application": {
                "name": $app_name,
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
        --arg origin "$ORIGIN" \
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
        }')
}

function makeDeploymentEvent() {
    makeDeployment
    makeApplication
    request_body=$( jq -n \
        --arg origin "$ORIGIN" \
        --argjson deployment "$cicd_Deployment" \
        '{ 
            "origin": $origin,
            "entries": [
                $deployment
            ]
        }')
}

function makeFullEvent() {
    makeDeployment
    makeBuild
    makeBuildCommitAssociation
    makePipeline
    makeApplication
    request_body=$( jq -n \
        --arg origin "$ORIGIN" \
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
        }')
}

function sendEventToFaros() {
    echo "Sending event to Faros..."
    response_json=$(curl -s --show-error --retry 5 --retry-delay 5 \
    $faros_api_url/graphs/$faros_graph/revisions \
    -X POST \
    -H "authorization: $faros_api_key" \
    -H "content-type: application/json" \
    -d "$request_body") 
}

main "$@"; exit
