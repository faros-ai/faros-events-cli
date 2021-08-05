Describe 'faros_event.sh'
  Describe 'faros_event.sh deployment'
    It 'Constructs correct deployment event'
        deployment_event_test() {
          echo $(
            FAROS_DEPLOYMENT="<deployment_uid>" \
            FAROS_START_TIME=10 \
            FAROS_END_TIME=10 \
            ../faros_event.sh deployment -k "<api_key>" \
            --app "<app_name>" \
            --ci_org "<ci_organization>" \
            --ci_source "<ci_source>" \
            --deployment_status Success \
            --deployment_env QA \
            --pipeline "<ci_pipeline>" \
            --build "<build_uid>" \
            --dry_run \
            --no_format)
        }
        When call deployment_event_test
        The output should equal 'Request Body: { "origin": "Faros_Script_Event", "entries": [ { "cicd_Deployment": { "uid": "<deployment_uid>", "source": "Faros_Script", "status": { "category": "Success", "detail": "" }, "startedAt": 10, "endedAt": 10, "env": { "category": "QA", "detail": "" }, "application": { "name": "<app_name>", "platform": "" }, "build": { "uid": "<build_uid>", "pipeline": { "uid": "<ci_pipeline>", "organization": { "uid": "<ci_organization>", "source": "<ci_source>" } } } } }, { "compute_Application": { "name": "<app_name>", "platform": "" } } ] } Dry run: Event NOT sent to Faros. Done.'
    End
  End

  Describe 'faros_event build'
    It 'Constructs correct build event'
        build_event_test() {
          echo $(
            FAROS_BUILD="<build_uid>" \
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
        When call build_event_test
        The output should equal 'Request Body: { "origin": "Faros_Script_Event", "entries": [ { "cicd_Build": { "uid": "<build_uid>", "startedAt": 10, "endedAt": 10, "status": { "category": "Success", "detail": "" }, "pipeline": { "uid": "<ci_pipeline>", "organization": { "uid": "<ci_organization>", "source": "<ci_source>" } } } }, { "cicd_BuildCommitAssociation": { "build": { "uid": "<build_uid>", "pipeline": { "uid": "<ci_pipeline>", "organization": { "uid": "<ci_organization>", "source": "<ci_source>" } } }, "commit": { "sha": "<commit_sha>", "repository": { "name": "<vcs_repo>", "organization": { "uid": "<vcs_organization>", "source": "<vcs_source>" } } } } }, { "cicd_Pipeline": { "uid": "<ci_pipeline>", "organization": { "uid": "<ci_organization>", "source": "<ci_source>" } } }, { "compute_Application": { "name": "<app_name>", "platform": "" } } ] } Dry run: Event NOT sent to Faros. Done.'
    End

    It 'Requires --build'
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
      When call build_event_test
      The output should eq ""
      The stderr should eq "../faros_event.sh: line 421: FAROS_BUILD: unbound variable"
    End
  End

  Describe 'faros_event build_deployment'
    It 'Constructs correct build_deployment event'
        build_deployment_event_test() {
          echo $(
            FAROS_DEPLOYMENT="<deployment_uid>" \
            FAROS_BUILD="<build_uid>" \
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
        When call build_deployment_event_test
        The output should equal 'Request Body: { "origin": "Faros_Script_Event", "entries": [ { "cicd_Deployment": { "uid": "<deployment_uid>", "source": "Faros_Script", "status": { "category": "Failed", "detail": "" }, "startedAt": 10, "endedAt": 10, "env": { "category": "QA", "detail": "" }, "application": { "name": "<app_name>", "platform": "" }, "build": { "uid": "<build_uid>", "pipeline": { "uid": "<ci_pipeline>", "organization": { "uid": "<ci_organization>", "source": "<ci_source>" } } } } }, { "cicd_Build": { "uid": "<build_uid>", "startedAt": 10, "endedAt": 10, "status": { "category": "Success", "detail": "" }, "pipeline": { "uid": "<ci_pipeline>", "organization": { "uid": "<ci_organization>", "source": "<ci_source>" } } } }, { "cicd_BuildCommitAssociation": { "build": { "uid": "<build_uid>", "pipeline": { "uid": "<ci_pipeline>", "organization": { "uid": "<ci_organization>", "source": "<ci_source>" } } }, "commit": { "sha": "<commit_sha>", "repository": { "name": "<vcs_repo>", "organization": { "uid": "<vcs_organization>", "source": "<vcs_source>" } } } } }, { "cicd_Pipeline": { "uid": "<ci_pipeline>", "organization": { "uid": "<ci_organization>", "source": "<ci_source>" } } }, { "compute_Application": { "name": "<app_name>", "platform": "" } } ] } Dry run: Event NOT sent to Faros. Done.'
    End
  End

  Describe 'faros_event bad input'
    It 'Responds with bad input'
        bad_input_test() {
          echo $(
            ../faros_event.sh $1 \
            --no_format
          )
        }
        When call bad_input_test "Bad_Input"
        The output should equal 'Unrecognized arg(s): Bad_Input Failed.'
    End
  End
End
