deployment_event_test() {
    echo $(
        FAROS_DEPLOYMENT="<deployment_uid>" \
        FAROS_START_TIME=10 \
        FAROS_END_TIME=10 \
        ../faros_event.sh deployment -k "<api_key>" \
        --app "<app_name>" \
        --ci_org "<ci_organization>" \
        --ci_source "<ci_source>" \
        --commit_sha "<commit_sha>" \
        --deployment_status Success \
        --deployment_env QA \
        --pipeline "<ci_pipeline>" \
        --build "<build_uid>" \
        --dry_run \
        --no_format)
}

build_event_test() {
    echo $(
        FAROS_START_TIME=10 \
        FAROS_END_TIME=10 \
        ../faros_event.sh build -k "<api_key>" \
        --app "<app_name>" \
        --build_status Success \
        --ci_org "<ci_organization>" \
        --ci_source "<ci_source>" \
        --commit_sha "<commit_sha>" \
        --repo "<vcs_repo>" \
        --pipeline "<ci_pipeline>" \
        --vcs_source "<vcs_source>" \
        --vcs_org "<vcs_organization>" \
        --dry_run \
        --no_format)
}

build_deployment_event_test() {
    echo $(
        FAROS_DEPLOYMENT="<deployment_uid>" \
        FAROS_START_TIME=10 \
        FAROS_END_TIME=10 \
        ../faros_event.sh build_deployment -k "<api_key>" \
        --app "<app_name>" \
        --build_status Success \
        --ci_org "<ci_organization>" \
        --ci_source "<ci_source>" \
        --commit_sha "<commit_sha>" \
        --deployment_status Failed \
        --deployment_env QA \
        --pipeline "<ci_pipeline>" \
        --repo "<vcs_repo>" \
        --vcs_source "<vcs_source>" \
        --vcs_org "<vcs_organization>" \
        --dry_run \
        --no_format)
}

bad_input_test() {
    echo $(
        ../faros_event.sh $1 \
        --no_format
    )
}
