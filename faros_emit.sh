#!/bin/bash

set -euo pipefail

# Requires curl
which curl &> /dev/null || { echo "curl required" & exit 1; }
# Requires jq
which jq &> /dev/null || { echo "jq required" & exit 1; }

# Emits deployment or build information to Faros.
# Depending on if you are emitting a deployment or a build, different flags
# will be required.
#
# Canonical Model Version: v0.8.9
# https://github.com/faros-ai/canonical-models/tree/v0.8.9
#
# Required args:
# Arg  | Description
# -----------------------------------------------------------------------------
# arg1 | Emit type: "deployment" and coming soon: "build" (must be first arg)
# 
# Required fields:
# Flag                          | Env Var
# -----------------------------------------------------------------------------
# -k / --api_key <api_key>      | FAROS_API_KEY
# -a / --application <app_name> | APPLICATION_NAME
# -c / --commit <commit_sha>    | COMMIT_SHA
# -s / --status <status>        | DEPLOYMENT_STATUS
# -e / --environment <env>      | DEPLOYMENT_ENV
#
# Optional fields:
# Flag                 | Env Var                  | Default
# -----------------------------------------------------------------------------
# -g / --graph <graph> | FAROS_GRAPH              | "default"
#                      | ORIGIN                   | "Faros_Script_Event"
#                      | SOURCE                   | "Faros_Script"
#                      | DEPLOYMENT_UID           | Random UUID
#                      | APPLICATION_PLATFORM     | "NA"
#                      | DEPLOYMENT_ENV_DETAIL    | ""
#                      | DEPLOYMENT_STATUS_DETAIL | ""
#                      | START_TIME               | Now
#                      | END_TIME                 | Now
#
# Optional Script Flags:
# Flag          | Description
# -----------------------------------------------------------------------------
# --dry_run     | If present, the event will be printed instead of emitted.
# --print_event | If present, the event will be printed.
# --debug       | If present, helpful information will be printed.
#
# Example deployment emit:
# ./faros_emit.sh deployment -k <api_key> -a <application_name> \ 
# -e <environment> -c <commit_sha> -s <status>
main() {
    EMIT_TYPE=$1
    shift

    parseArgs "$@"

    if [ $EMIT_TYPE = "deployment" ]
    then
        makeDeploymantEvent
    elif [ $EMIT_TYPE = "build" ]
    then
        echo "Not implemented yet."
        exit 1
    else
        echo "Unrecognized emit type: $1"
        echo "Valid types: deployment, build"
        exit 1
    fi

    if (($print_event)) || (($dry_run))
    then
        echo $request_body | jq .
    fi

    if !(($dry_run))
    then
        emitToFaros
    else
        echo "Dry run: Event NOT emitted to Faros"
    fi
    exit 0
}

function parseArgs() {
    # Loop through arguments and process them
    while (($#));
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
            -e|--environment)
                deployment_env="$2"
                shift 2
                ;;
            -s|--status)
                deployment_status="$2"
                shift 2
                ;;
            -g|--graph)
                faros_graph="$2"
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

    # Required: If flag missing fall back to env var
    faros_api_key=${faros_api_key:-$FAROS_API_KEY}
    application_name=${application_name:-$APPLICATION_NAME}
    commit_sha=${commit_sha:-$COMMIT_SHA}

    # Required deployment fields:
    if [ $EMIT_TYPE == "deployment" ]
    then
        deployment_env=${deployment_env:-$DEPLOYMENT_ENV}
        deployment_status=${deployment_status:-$DEPLOYMENT_STATUS}
    fi

    # Optional: If flag missing fall back to env var then defualt
    FAROS_GRAPH=${FAROS_GRAPH:-"default"}
    faros_graph=${faros_graph:-$FAROS_GRAPH}

    # Optional: No flags offered. If unset use default
    FAROS_API_URL=${FAROS_API_URL:-"https://prod.api.faros.ai"}
    ORIGIN=${ORIGIN:-"Faros_Script_Event"}
    SOURCE=${SOURCE:-"Faros_Script"}
    DEPLOYMENT_UID=${DEPLOYMENT_UID:-$(uuidgen)} # default Random UUID
    APPLICATION_PLATFORM=${APPLICATION_PLATFORM:-"NA"}
    DEPLOYMENT_ENV_DETAIL=${DEPLOYMENT_ENV_DETAIL:-""}
    DEPLOYMENT_STATUS_DETAIL=${DEPLOYMENT_STATUS_DETAIL:-""}
    START_TIME=${START_TIME:-$( date +%s000000000 | cut -b1-13 )} # default now
    END_TIME=${END_TIME:-$( date +%s000000000 | cut -b1-13 )} # default now

    # Optional script settings: Fall back to env var then default
    print_event=${print_event:-0} # default 0
    dry_run=${dry_run:-0} # default 0
    debug=${debug:-0} # default 0

    if ((debug))
    then
        echo "Faros url: $FAROS_API_URL"
        echo "Faros graph: $faros_graph"
        echo "Dry run: $dry_run"
        echo "Print event: $print_event"
        echo "Debug: $debug"
    fi
}

# TODO: Figure out commit sha vs artifact
function makeDeploymantEvent() {
    cicd_deployment=$( jq -n \
        --arg s "$SOURCE" \
        --arg deployment_uid "$DEPLOYMENT_UID" \
        --arg deployment_status "$deployment_status" \
        --arg start_time "$START_TIME" \
        --arg end_time "$END_TIME" \
        --arg deployment_env "$deployment_env" \
        --arg application_name "$application_name" \
        --arg application_platform "$APPLICATION_PLATFORM" \
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
                }
            }
        }'
    )

    request_body=$( jq -n \
        --arg origin "$ORIGIN" \
        --argjson deployment "$cicd_deployment" \
        '{ 
            "origin": $origin,
            "entries": [
                $deployment
            ]
        }')
}

function emitToFaros() {
    echo "Emitting event to Faros..."

    curl -s $FAROS_API_URL/graphs/$faros_graph/revisions \
    --retry 5 --retry-delay 5 \
    -X POST \
    -H "authorization: $faros_api_key" \
    -H "content-type: application/json" \
    -d "$request_body"
}

FAROS_API_URL="https://dev.api.faros.ai"
FAROS_GRAPH="will-test"
main "$@"; exit
