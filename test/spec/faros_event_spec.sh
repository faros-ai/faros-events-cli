Describe 'faros_event.sh'
  Include lib/faros_event_test.sh
  Describe 'faros_event.sh deployment'
    It 'Constructs correct deployment event'
        When call deployment_event_test
        The output should equal 'Request Body: { "origin": "Faros_Script_Event", "entries": [ { "cicd_Deployment": { "uid": "<deployment_uid>", "source": "Faros_Script", "status": { "category": "<deploy_status>", "detail": "" }, "startedAt": 10, "endedAt": 10, "env": { "category": "<environment>", "detail": "" }, "application": { "name": "<app_name>", "platform": "NA" }, "build": { "uid": "<build_uid>", "pipeline": { "uid": "<ci_pipeline>", "organization": { "uid": "<ci_organization>", "source": "Faros_Script" } } } } } ] } Dry run: Event NOT sent to Faros. Done.'
    End
  End

  Describe 'faros_event build'
    It 'Constructs correct build event'
        When call build_event_test
        The output should equal 'Request Body: { "origin": "Faros_Script_Event", "entries": [ { "cicd_Build": { "uid": "<commit_sha>", "startedAt": 10, "endedAt": 10, "status": { "category": "<build_status>", "detail": "" }, "pipeline": { "uid": "<ci_pipeline>", "organization": { "uid": "<ci_organization>", "source": "Faros_Script" } } } }, { "cicd_BuildCommitAssociation": { "build": { "uid": "<commit_sha>", "pipeline": { "uid": "<ci_pipeline>", "organization": { "uid": "<ci_organization>", "source": "Faros_Script" } } }, "commit": { "sha": "<commit_sha>", "repository": { "name": "<vcs_repo>", "organization": { "uid": "<vcs_organization>", "source": "<vcs_source>" } } } } }, { "cicd_Pipeline": { "uid": "<ci_pipeline>", "organization": { "uid": "<ci_organization>", "source": "Faros_Script" } } }, { "compute_Application": { "name": "<app_name>", "platform": "NA" } } ] } Dry run: Event NOT sent to Faros. Done.'
    End
  End

  Describe 'faros_event build_deployment'
    It 'Constructs correct build_deployment event'
        When call build_deployment_event_test
        The output should equal 'Request Body: { "origin": "Faros_Script_Event", "entries": [ { "cicd_Deployment": { "uid": "<deployment_uid>", "source": "Faros_Script", "status": { "category": "<deploy_status>", "detail": "" }, "startedAt": 10, "endedAt": 10, "env": { "category": "<environment>", "detail": "" }, "application": { "name": "<app_name>", "platform": "NA" }, "build": { "uid": "<commit_sha>", "pipeline": { "uid": "<ci_pipeline>", "organization": { "uid": "<ci_organization>", "source": "Faros_Script" } } } } }, { "cicd_Build": { "uid": "<commit_sha>", "startedAt": 10, "endedAt": 10, "status": { "category": "<build_status>", "detail": "" }, "pipeline": { "uid": "<ci_pipeline>", "organization": { "uid": "<ci_organization>", "source": "Faros_Script" } } } }, { "cicd_BuildCommitAssociation": { "build": { "uid": "<commit_sha>", "pipeline": { "uid": "<ci_pipeline>", "organization": { "uid": "<ci_organization>", "source": "Faros_Script" } } }, "commit": { "sha": "<commit_sha>", "repository": { "name": "<vcs_repo>", "organization": { "uid": "<vcs_organization>", "source": "<vcs_source>" } } } } }, { "cicd_Pipeline": { "uid": "<ci_pipeline>", "organization": { "uid": "<ci_organization>", "source": "Faros_Script" } } }, { "compute_Application": { "name": "<app_name>", "platform": "NA" } } ] } Dry run: Event NOT sent to Faros. Done.'
    End
  End

  Describe 'faros_event bad input'
    It 'Responds with bad input'
        When call bad_input_test "Bad_Input"
        The output should equal 'Unrecognized arg(s): Bad_Input Failed.'
    End
  End
End
