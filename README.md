# Faros Events CLI
CLI for reporting events to Faros platform

## Example Emits

```sh
# You need not replace any
./faros_emit.sh full -k "<api_key>" -a "<app_name>" -e "<environmnet>" -c "<commit_sha>" --build_status "<build_status>" --deploy_status "<deploy_status>" --repo "<vcs_repo>" -p "<ci_pipeline>" --ci_org "<ci_organization>" --vcs_source "<vcs_source>" --vcs_org "<vcs_organization>" --dry_run
./faros_emit.sh deployment -k "<api_key>" -a "<app_name>" -e "<environmnet>" -c "<commit_sha>" --deploy_status "<deploy_status>" -p "<ci_pipeline>" --ci_org "<ci_organization>" --dry_run
./faros_emit.sh build -k "<api_key>" -a "<app_name>" -c "<commit_sha>" --build_status "<build_status>" --ci_org "<ci_organization>" --repo "<vcs_repo>" -p "<ci_pipeline>" --vcs_source "<vcs_source>" --vcs_org "<vcs_organization>" --dry_run
```

```sh
# You need only replace <api_key>
./faros_emit.sh full -k "<api_key>" -a "<app_name>" -e "Prod" -c "<commit_sha>" --build_status "Success" --deploy_status "Success" --repo "<vcs_repo>" -p "<ci_pipeline>" --ci_org "<ci_organization>" --vcs_source "<vcs_source>" --vcs_org "<vcs_organization>" --print_event
./faros_emit.sh deployment -k "<api_key>" -a "<app_name>" -e "Prod" -c "<commit_sha>" --deploy_status "Success" -p "<ci_pipeline>" --ci_org "<ci_organization>" --print_event
./faros_emit.sh build -k "<api_key>" -a "<app_name>" -c "<commit_sha>" --build_status "Success" --ci_org "<ci_organization>" --repo "<vcs_repo>" -p "<ci_pipeline>" --vcs_source "<vcs_source>" --vcs_org "<vcs_organization>" --print_event
```
