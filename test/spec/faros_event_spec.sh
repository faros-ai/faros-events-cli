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
            --app_platform "<app_platform>" \
            --build "<build_uid>" \
            --deployment_status Success \
            --deployment_env QA \
            --deployment_source "<deployment_source>" \
            --artifact "<artifact>" \
            --artifact_repo "<artifact_repo>" \
            --artifact_org "<artifact_org>" \
            --artifact_source "<artifact_source>" \
            --pipeline "<cicd_pipeline>" \
            --cicd_org "<cicd_organization>" \
            --cicd_source "<cicd_source>" \
            --dry_run \
            --no_format)
        }
        When call deployment_event_test
        The output should equal 'Request Body: { "origin": "Faros_Script_Event", "entries": [ { "cicd_Deployment": { "uid": "<deployment_uid>", "source": "<deployment_source>", "status": { "category": "Success", "detail": "" }, "startedAt": 10, "endedAt": 10, "env": { "category": "QA", "detail": "" }, "application": { "name": "<app_name>", "platform": "<app_platform>" }, "build": { "uid": "<build_uid>", "pipeline": { "uid": "<cicd_pipeline>", "organization": { "uid": "<cicd_organization>", "source": "<cicd_source>" } } } } }, { "cicd_ArtifactDeployment": { "artifact": { "uid": "<artifact>", "repository": { "uid": "<artifact_repo>", "organization": { "uid": "<artifact_org>", "source": "<artifact_source>" } } }, "deployment": { "uid": "<deployment_uid>", "source": "<deployment_source>" } } }, { "compute_Application": { "name": "<app_name>", "platform": "<app_platform>" } } ] } Dry run: Event NOT sent to Faros. Done.'
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
            --build_name "<build_name>" \
            --build_status Success \
            --pipeline "<cicd_pipeline>" \
            --cicd_org "<cicd_organization>" \
            --cicd_source "<cicd_source>" \
            --dry_run \
            --no_format)
        }
        When call build_event_test
        The output should equal 'Request Body: { "origin": "Faros_Script_Event", "entries": [ { "cicd_Build": { "uid": "<build_uid>", "name": "<build_name>", "startedAt": 10, "endedAt": 10, "status": { "category": "Success", "detail": "" }, "pipeline": { "uid": "<cicd_pipeline>", "organization": { "uid": "<cicd_organization>", "source": "<cicd_source>" } } } } ] } Dry run: Event NOT sent to Faros. Done.'
    End

    It 'Requires --build'
      build_event_test() {
        echo $(
            FAROS_START_TIME=10 \
            FAROS_END_TIME=10 \
            ../faros_event.sh build -k "<api_key>" \
            --build_status Success \
            --commit_sha "<commit_sha>" \
            --vcs_repo "<vcs_repo>" \
            --vcs_org "<vcs_organization>" \
            --vcs_source "<vcs_source>" \
            --pipeline "<cicd_pipeline>" \
            --cicd_org "<cicd_organization>" \
            --cicd_source "<cicd_source>" \
            --dry_run \
            --no_format)
      }
      When call build_event_test
      The output should eq ""
      The stderr should include "FAROS_BUILD: unbound variable"
    End
  End

  Describe 'faros_event artifact'
    It 'Constructs correct artifact event'
      artifact_event_test() {
        echo $(
          FAROS_BUILD="<build_uid>" \
          FAROS_START_TIME=10 \
          FAROS_END_TIME=10 \
          ../faros_event.sh artifact \
          -k "<api_key>" \
          --artifact "<artifact>" \
          --artifact_repo "<artifact_repo>" \
          --artifact_org "<artifact_org>" \
          --artifact_source "<artifact_source>" \
          --commit_sha "<commit_sha>" \
          --vcs_repo "<vcs_repo>" \
          --vcs_org "<vcs_organization>" \
          --vcs_source "<vcs_source>" \
          --pipeline "<cicd_pipeline>" \
          --cicd_org "<cicd_organization>" \
          --cicd_source "<cicd_source>" \
          --dry_run \
          --no_format
        )
      }
      When call artifact_event_test
      The output should equal 'Request Body: { "origin": "Faros_Script_Event", "entries": [ { "cicd_Artifact": { "uid": "<artifact>", "build": { "uid": "<build_uid>", "pipeline": { "uid": "<cicd_pipeline>", "organization": { "uid": "<cicd_organization>", "source": "<cicd_source>" } } }, "repository": { "uid": "<artifact_repo>", "organization": { "uid": "<artifact_org>", "source": "<artifact_source>" } } } }, { "cicd_ArtifactCommitAssociation": { "artifact": { "uid": "<artifact>", "repository": { "uid": "<artifact_repo>", "organization": { "uid": "<artifact_org>", "source": "<artifact_source>" } } }, "commit": { "sha": "<commit_sha>", "repository": { "name": "<vcs_repo>", "organization": { "uid": "<vcs_organization>", "source": "<vcs_source>" } } } } } ] } Dry run: Event NOT sent to Faros. Done.'
    End
  End

  Describe 'faros_event aggregation'
    It 'Constructs correct aggregated event'
      aggregate_event_test() {
        echo $(
          FAROS_START_TIME=10 \
          FAROS_END_TIME=10 \
          ../faros_event.sh build artifact deployment \
          -k "<api_key>" \
          --app "<app_name>" \
          --deployment "<deployment>" \
          --deployment_source "<deployment_source>" \
          --deployment_status "Success" \
          --deployment_env "QA" \
          --artifact "<artifact>" \
          --artifact_repo "<artifact_repo>" \
          --artifact_org "<artifact_org>" \
          --artifact_source "<artifact_source>" \
          --build "<build>" \
          --build_status "Success" \
          --commit_sha "<commit_sha>" \
          --vcs_repo "<vcs_repo>" \
          --vcs_org "<vcs_organization>" \
          --vcs_source "<vcs_source>" \
          --pipeline "<cicd_pipeline>" \
          --cicd_org "<cicd_organization>" \
          --cicd_source "<cicd_source>" \
          --dry_run \
          --make_cicd_objects \
          --no_format
          )
      }
      When call aggregate_event_test
      The output should equal 'Request Body: { "origin": "Faros_Script_Event", "entries": [ { "cicd_Build": { "uid": "<build>", "name": "", "startedAt": 10, "endedAt": 10, "status": { "category": "Success", "detail": "" }, "pipeline": { "uid": "<cicd_pipeline>", "organization": { "uid": "<cicd_organization>", "source": "<cicd_source>" } } } }, { "cicd_Artifact": { "uid": "<artifact>", "build": { "uid": "<build>", "pipeline": { "uid": "<cicd_pipeline>", "organization": { "uid": "<cicd_organization>", "source": "<cicd_source>" } } }, "repository": { "uid": "<artifact_repo>", "organization": { "uid": "<artifact_org>", "source": "<artifact_source>" } } } }, { "cicd_ArtifactCommitAssociation": { "artifact": { "uid": "<artifact>", "repository": { "uid": "<artifact_repo>", "organization": { "uid": "<artifact_org>", "source": "<artifact_source>" } } }, "commit": { "sha": "<commit_sha>", "repository": { "name": "<vcs_repo>", "organization": { "uid": "<vcs_organization>", "source": "<vcs_source>" } } } } }, { "cicd_Deployment": { "uid": "<deployment>", "source": "<deployment_source>", "status": { "category": "Success", "detail": "" }, "startedAt": 10, "endedAt": 10, "env": { "category": "QA", "detail": "" }, "application": { "name": "<app_name>", "platform": "" }, "build": { "uid": "<build>", "pipeline": { "uid": "<cicd_pipeline>", "organization": { "uid": "<cicd_organization>", "source": "<cicd_source>" } } } } }, { "cicd_ArtifactDeployment": { "artifact": { "uid": "<artifact>", "repository": { "uid": "<artifact_repo>", "organization": { "uid": "<artifact_org>", "source": "<artifact_source>" } } }, "deployment": { "uid": "<deployment>", "source": "<deployment_source>" } } }, { "compute_Application": { "name": "<app_name>", "platform": "" } }, { "cicd_Organization": { "uid": "<cicd_organization>", "source": "<cicd_source>" } }, { "cicd_Pipeline": { "uid": "<cicd_pipeline>", "organization": { "uid": "<cicd_organization>", "source": "<cicd_source>" } } } ] } Dry run: Event NOT sent to Faros. Done.'
    End
  End

  Describe 'faros_event bad input'
    It 'Responds with bad input'
        bad_input_test() {
          echo $(
            ../faros_event.sh $1 \
            -k "<key>" \
            --build "<build>" \
            --pipeline "<cicd_pipeline>" \
            --cicd_org "<cicd_organization>" \
            --cicd_source "<cicd_source>" \
            $2 \
            --no_format
          )
        }
        When call bad_input_test "Bad_Input" "Also_Bad"
        The output should equal 'Unrecognized arg(s): Bad_Input Also_Bad Failed.'
    End
  End
End
