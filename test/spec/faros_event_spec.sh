Describe 'faros_event.sh'
  Describe 'faros_event.sh deployment'

    deploymentWithArtifactExpectedOutput='Request Body: { "origin": "Faros_Script_Event", "entries": [ { "cicd_Deployment": { "uid": "<deployment_uid>", "source": "<deployment_source>", "status": { "category": "Success", "detail": "" }, "startedAt": 10, "endedAt": 10, "env": { "category": "QA", "detail": "" }, "application": { "name": "<app_name>", "platform": "<app_platform>" }, "build": { "uid": "<build_uid>", "pipeline": { "uid": "<cicd_pipeline>", "organization": { "uid": "<cicd_organization>", "source": "<cicd_source>" } } } } }, { "cicd_ArtifactDeployment": { "artifact": { "uid": "<artifact>", "repository": { "uid": "<artifact_repo>", "organization": { "uid": "<artifact_org>", "source": "<artifact_source>" } } }, "deployment": { "uid": "<deployment_uid>", "source": "<deployment_source>" } } }, { "compute_Application": { "name": "<app_name>", "platform": "<app_platform>" } } ] } Dry run: Event NOT sent to Faros. Done.'

    It 'Constructs correct deployment event when artifact included - flags'
      deployment_with_artifact_flag_test() {
        echo $(
          ../faros_event.sh deployment --dry_run --no_format \
          -k "<api_key>" \
          --app "<app_name>" \
          --app_platform "<app_platform>" \
          --deployment "<deployment_uid>" \
          --deployment_status Success \
          --deployment_env QA \
          --deployment_source "<deployment_source>" \
          --artifact "<artifact>" \
          --artifact_repo "<artifact_repo>" \
          --artifact_org "<artifact_org>" \
          --artifact_source "<artifact_source>" \
          --build "<build_uid>" \
          --pipeline "<cicd_pipeline>" \
          --cicd_org "<cicd_organization>" \
          --cicd_source "<cicd_source>" \
          --deployment_start_time 10 \
          --deployment_end_time 10
        )
      }
      When call deployment_with_artifact_flag_test
      The output should equal "$deploymentWithArtifactExpectedOutput"
    End

    It 'Constructs correct deployment event when artifact included - environment variables'
      deployment_with_artifact_environment_variable_test() {
        echo $(
          FAROS_API_KEY="<api_key>" \
          FAROS_DEPLOYMENT="<deployment_uid>" \
          FAROS_APP="<app_name>" \
          FAROS_APP_PLATFORM="<app_platform>" \
          FAROS_BUILD="<build_uid>" \
          FAROS_DEPLOYMENT_STATUS="Success" \
          FAROS_DEPLOYMENT_ENV="QA" \
          FAROS_DEPLOYMENT_SOURCE="<deployment_source>" \
          FAROS_ARTIFACT="<artifact>" \
          FAROS_ARTIFACT_REPO="<artifact_repo>" \
          FAROS_ARTIFACT_ORG="<artifact_org>" \
          FAROS_ARTIFACT_SOURCE="<artifact_source>" \
          FAROS_PIPELINE="<cicd_pipeline>" \
          FAROS_CICD_ORG="<cicd_organization>" \
          FAROS_CICD_SOURCE="<cicd_source>" \
          FAROS_DEPLOYMENT_START_TIME=10 \
          FAROS_DEPLOYMENT_END_TIME=10 \
          ../faros_event.sh deployment --dry_run --no_format
        )
      }
      When call deployment_with_artifact_environment_variable_test
      The output should equal "$deploymentWithArtifactExpectedOutput"
    End

    deploymentWithCommitExpectedOutput='Request Body: { "origin": "Faros_Script_Event", "entries": [ { "cicd_Deployment": { "uid": "<deployment_uid>", "source": "<deployment_source>", "status": { "category": "Success", "detail": "" }, "startedAt": 10, "endedAt": 10, "env": { "category": "QA", "detail": "" }, "application": { "name": "<app_name>", "platform": "<app_platform>" }, "build": { "uid": "<build_uid>", "pipeline": { "uid": "<cicd_pipeline>", "organization": { "uid": "<cicd_organization>", "source": "<cicd_source>" } } } } }, { "cicd_ArtifactDeployment": { "artifact": { "uid": "<dummy_artifact>", "repository": { "uid": "", "organization": { "uid": "", "source": "" } } }, "deployment": { "uid": "<deployment_uid>", "source": "<deployment_source>" } } }, { "compute_Application": { "name": "<app_name>", "platform": "<app_platform>" } }, { "cicd_Artifact": { "uid": "<dummy_artifact>", "build": { "uid": "<build_uid>", "pipeline": { "uid": "<cicd_pipeline>", "organization": { "uid": "<cicd_organization>", "source": "<cicd_source>" } } }, "repository": { "uid": "", "organization": { "uid": "", "source": "" } } } }, { "cicd_ArtifactCommitAssociation": { "artifact": { "uid": "<dummy_artifact>", "repository": { "uid": "", "organization": { "uid": "", "source": "" } } }, "commit": { "sha": "<commit_sha>", "repository": { "name": "<vcs_repo>", "organization": { "uid": "<vcs_organization>", "source": "<vcs_source>" } } } } } ] } Dry run: Event NOT sent to Faros. Done.'
    
    It 'Constructs correct deployment event when commmit included - flags'
      deployment_with_commit_flag_test() {
        echo $(
          FAROS_ARTIFACT_DEFAULT="<dummy_artifact>" \
          ../faros_event.sh deployment --dry_run --no_format \
          -k "<api_key>" \
          --deployment "<deployment_uid>" \
          --deployment_status Success \
          --deployment_env QA \
          --deployment_source "<deployment_source>" \
          --app "<app_name>" \
          --app_platform "<app_platform>" \
          --commit_sha "<commit_sha>" \
          --vcs_repo "<vcs_repo>" \
          --vcs_org "<vcs_organization>" \
          --vcs_source "<vcs_source>" \
          --build "<build_uid>" \
          --pipeline "<cicd_pipeline>" \
          --cicd_org "<cicd_organization>" \
          --cicd_source "<cicd_source>" \
          --deployment_start_time 10 \
          --deployment_end_time 10 \
        )
      }
      When call deployment_with_commit_flag_test
      The output should equal "$deploymentWithCommitExpectedOutput"
    End

    It 'Constructs correct deployment event when commit included - environment variables'
      deployment_with_commit_environment_variable_test() {
        echo $(
          FAROS_API_KEY="<api_key>" \
          FAROS_ARTIFACT_DEFAULT="<dummy_artifact>" \
          FAROS_DEPLOYMENT="<deployment_uid>" \
          FAROS_APP="<app_name>" \
          FAROS_APP_PLATFORM="<app_platform>" \
          FAROS_DEPLOYMENT_STATUS="Success" \
          FAROS_DEPLOYMENT_ENV="QA" \
          FAROS_DEPLOYMENT_SOURCE="<deployment_source>" \
          FAROS_COMMIT_SHA="<commit_sha>" \
          FAROS_VCS_REPO="<vcs_repo>" \
          FAROS_VCS_ORG="<vcs_organization>" \
          FAROS_VCS_SOURCE="<vcs_source>" \
          FAROS_BUILD="<build_uid>" \
          FAROS_PIPELINE="<cicd_pipeline>" \
          FAROS_CICD_ORG="<cicd_organization>" \
          FAROS_CICD_SOURCE="<cicd_source>" \
          ../faros_event.sh deployment --dry_run --no_format \
          --start_time 10 \
          --end_time 10
        )
      }
      When call deployment_with_commit_environment_variable_test
      The output should equal "$deploymentWithCommitExpectedOutput"
    End

    It 'Fails deployment event when artifact and commit missing'
      deployment_artifact_commit_missing_test() {
        echo $(
          FAROS_START_TIME=10 \
          FAROS_END_TIME=10 \
          ../faros_event.sh deployment --dry_run --no_format \
          -k "<api_key>" \
          --app "<app_name>" \
          --app_platform "<app_platform>" \
          --deployment "<deployment_uid>" \
          --deployment_status Success \
          --deployment_env QA \
          --deployment_source "<deployment_source>" \
          --build "<build_uid>" \
          --pipeline "<cicd_pipeline>" \
          --cicd_org "<cicd_organization>" \
          --cicd_source "<cicd_source>"
        )
      }
      When call deployment_artifact_commit_missing_test
      The output should equal 'Deployment event requires artifact or commit information Failed.'
    End

    It 'Requires --deployment'
      deployment_event_test() {
        echo $(
          FAROS_START_TIME=10 \
          FAROS_END_TIME=10 \
          ../faros_event.sh deployment --dry_run --no_format \
          -k "<api_key>" \
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
          --cicd_source "<cicd_source>"
        )
      }
      When call deployment_event_test
      The output should eq ""
      The stderr should include "FAROS_DEPLOYMENT: unbound variable"
    End
  End

  Describe 'faros_event build'

    buildExpectedOutput='Request Body: { "origin": "Faros_Script_Event", "entries": [ { "cicd_Build": { "uid": "<build_uid>", "name": "<build_name>", "startedAt": 10, "endedAt": 10, "status": { "category": "Success", "detail": "" }, "pipeline": { "uid": "<cicd_pipeline>", "organization": { "uid": "<cicd_organization>", "source": "<cicd_source>" } } } } ] } Dry run: Event NOT sent to Faros. Done.'

    It 'Constructs correct build event - flags'
      build_event_test() {
        echo $(
          ../faros_event.sh build --dry_run --no_format \
          -k "<api_key>" \
          --build "<build_uid>" \
          --build_name "<build_name>" \
          --build_status Success \
          --pipeline "<cicd_pipeline>" \
          --cicd_org "<cicd_organization>" \
          --cicd_source "<cicd_source>" \
          --build_start_time 10 \
          --build_end_time 10
        )
      }
      When call build_event_test
      The output should equal "$buildExpectedOutput"
    End

    It 'Constructs correct build event - environment variables'
      build_event_test() {
        echo $(
          FAROS_API_KEY="<api_key>" \
          FAROS_BUILD="<build_uid>" \
          FAROS_BUILD_NAME="<build_name>" \
          FAROS_BUILD_STATUS="Success" \
          FAROS_PIPELINE="<cicd_pipeline>" \
          FAROS_CICD_ORG="<cicd_organization>" \
          FAROS_CICD_SOURCE="<cicd_source>" \
          FAROS_BUILD_START_TIME=10 \
          FAROS_BUILD_END_TIME=10 \
          ../faros_event.sh build --dry_run --no_format
        )
      }
      When call build_event_test
      The output should equal "$buildExpectedOutput"
    End

    It 'Requires --build'
      build_event_test() {
        echo $(
          FAROS_START_TIME=10 \
          FAROS_END_TIME=10 \
          ../faros_event.sh build -k "<api_key>" --dry_run --no_format \
          --build_status Success \
          --commit_sha "<commit_sha>" \
          --vcs_repo "<vcs_repo>" \
          --vcs_org "<vcs_organization>" \
          --vcs_source "<vcs_source>" \
          --pipeline "<cicd_pipeline>" \
          --cicd_org "<cicd_organization>" \
          --cicd_source "<cicd_source>"
        )
      }
      When call build_event_test
      The output should eq ""
      The stderr should include "FAROS_BUILD: unbound variable"
    End
  End

  Describe 'faros_event artifact'

    artifactExpectedOutput='Request Body: { "origin": "Faros_Script_Event", "entries": [ { "cicd_Artifact": { "uid": "<artifact>", "build": { "uid": "<build_uid>", "pipeline": { "uid": "<cicd_pipeline>", "organization": { "uid": "<cicd_organization>", "source": "<cicd_source>" } } }, "repository": { "uid": "<artifact_repo>", "organization": { "uid": "<artifact_org>", "source": "<artifact_source>" } } } }, { "cicd_ArtifactCommitAssociation": { "artifact": { "uid": "<artifact>", "repository": { "uid": "<artifact_repo>", "organization": { "uid": "<artifact_org>", "source": "<artifact_source>" } } }, "commit": { "sha": "<commit_sha>", "repository": { "name": "<vcs_repo>", "organization": { "uid": "<vcs_organization>", "source": "<vcs_source>" } } } } } ] } Dry run: Event NOT sent to Faros. Done.'

    It 'Constructs correct artifact event - flags'
      artifact_event_test() {
        echo $(
          ../faros_event.sh artifact --dry_run --no_format \
          -k "<api_key>" \
          --artifact "<artifact>" \
          --artifact_repo "<artifact_repo>" \
          --artifact_org "<artifact_org>" \
          --artifact_source "<artifact_source>" \
          --commit_sha "<commit_sha>" \
          --vcs_repo "<vcs_repo>" \
          --vcs_org "<vcs_organization>" \
          --vcs_source "<vcs_source>" \
          --build "<build_uid>" \
          --pipeline "<cicd_pipeline>" \
          --cicd_org "<cicd_organization>" \
          --cicd_source "<cicd_source>"
        )
      }
      When call artifact_event_test
      The output should equal "$artifactExpectedOutput"
    End

    It 'Constructs correct artifact event - environment variables'
      artifact_event_test() {
        echo $(
          FAROS_API_KEY="<api_key>" \
          FAROS_ARTIFACT="<artifact>" \
          FAROS_ARTIFACT_REPO="<artifact_repo>" \
          FAROS_ARTIFACT_ORG="<artifact_org>" \
          FAROS_ARTIFACT_SOURCE="<artifact_source>" \
          FAROS_COMMIT_SHA="<commit_sha>" \
          FAROS_VCS_REPO="<vcs_repo>" \
          FAROS_VCS_ORG="<vcs_organization>" \
          FAROS_VCS_SOURCE="<vcs_source>" \
          FAROS_BUILD="<build_uid>" \
          FAROS_PIPELINE="<cicd_pipeline>" \
          FAROS_CICD_ORG="<cicd_organization>" \
          FAROS_CICD_SOURCE="<cicd_source>" \
          ../faros_event.sh artifact --dry_run --no_format
        )
      }
      When call artifact_event_test
      The output should equal "$artifactExpectedOutput"
    End
  End

  Describe 'faros_event aggregation'
    It 'Constructs correct aggregated event'
      aggregate_event_test() {
        echo $(
          FAROS_START_TIME=10 \
          FAROS_END_TIME=10 \
          ../faros_event.sh build deployment artifact --dry_run --no_format \
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
          --make_cicd_objects
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
