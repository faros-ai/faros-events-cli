faros_deployment_event_test() {
    echo $(
        FAROS_DEPLOYMENT="<deployment_uid>" \
        FAROS_START_TIME=10 \
        FAROS_END_TIME=10 \
        ../faros_event.sh deployment -k "<api_key>" \
        --app "<app_name>" \
        --ci_org "<ci_organization>" \
        --commit_sha "<commit_sha>" \
        --deployment_status "<deploy_status>" \
        --deployment_env "<environment>" \
        --pipeline "<ci_pipeline>" \
        --build "<build_uid>" \
        --dry_run)
}

faros_build_event_test() {
    echo $(
        FAROS_START_TIME=10 \
        FAROS_END_TIME=10 \
        ../faros_event.sh build -k "<api_key>" \
        --app "<app_name>" \
        --build_status "<build_status>" \
        --ci_org "<ci_organization>" \
        --commit_sha "<commit_sha>" \
        --repo "<vcs_repo>" \
        --pipeline "<ci_pipeline>" \
        --vcs_source "<vcs_source>" \
        --vcs_org "<vcs_organization>" \
        --dry_run)
}

faros_full_event_test() {
    echo $(
        FAROS_DEPLOYMENT="<deployment_uid>" \
        FAROS_START_TIME=10 \
        FAROS_END_TIME=10 \
        ../faros_event.sh full -k "<api_key>" \
        --app "<app_name>" \
        --build_status "<build_status>" \
        --ci_org "<ci_organization>" \
        --commit_sha "<commit_sha>" \
        --deployment_status "<deploy_status>" \
        --deployment_env "<environment>" \
        --pipeline "<ci_pipeline>" \
        --repo "<vcs_repo>" \
        --vcs_source "<vcs_source>" \
        --vcs_org "<vcs_organization>" \
        --dry_run)
}
