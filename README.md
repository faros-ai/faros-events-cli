# Faros Events CLI
CLI for reporting events to Faros platform

## `./faros_event.sh` Usage Examples

### Sending a Build Event

```sh
./faros_event.sh build -k "<api_key>" \
    --application "<app_name>" \
    --build_status "<build_status>" \
    --ci_org "<ci_organization>" \
    --commit "<commit_sha>" \
    --repo "<vcs_repo>" \
    --pipeline "<ci_pipeline>" \
    --vcs_source "<vcs_source>" \
    --vcs_org "<vcs_organization>" \
    --print_event
```

### Sending a Deployment Event

```sh
./faros_event.sh deployment -k "<api_key>" \
    --application "<app_name>" \
    --ci_org "<ci_organization>" \
    --commit "<commit_sha>" \
    --deploy_status "<deploy_status>" \
    --environment "<environment>" \
    --pipeline "<ci_pipeline>" \
    --print_event
```

### Sending a Full (Build + Deploy) Event

```sh
./faros_event.sh full -k "<api_key>" \
    --application "<app_name>" \
    --build_status "<build_status>" \
    --ci_org "<ci_organization>" \
    --commit "<commit_sha>" \
    --deploy_status "<deploy_status>" \
    --environment "<environment>" \
    --pipeline "<ci_pipeline>" \
    --repo "<vcs_repo>" \
    --vcs_source "<vcs_source>" \
    --vcs_org "<vcs_organization>" \
    --print_event
```
