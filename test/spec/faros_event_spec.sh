Describe 'faros_event.sh'
  export FAROS_DRY_RUN=1
  export FAROS_NO_FORMAT=1
  export FAROS_START_TIME_DEFAULT=10
  export FAROS_END_TIME_DEFAULT=10
  Describe 'CD event'
    CDWithArtifactExpectedOutput='{ "origin": "Faros_Script_Event", "entries": [ { "cicd_Deployment": { "uid": "<deploy_uid>", "source": "<deploy_source>", "status": { "category": "Success", "detail": "" }, "startedAt": 10, "endedAt": 10, "env": { "category": "QA", "detail": "" }, "application": { "name": "<app_name>", "platform": "<deploy_app_platform>" }, "build": { "uid": "<build_uid>", "pipeline": { "uid": "<cicd_pipeline>", "organization": { "uid": "<cicd_organization>", "source": "<cicd_source>" } } } } }, { "cicd_ArtifactDeployment": { "artifact": { "uid": "<artifact>", "repository": { "uid": "<artifact_repo>", "organization": { "uid": "<artifact_org>", "source": "<artifact_source>" } } }, "deployment": { "uid": "<deploy_uid>", "source": "<deploy_source>" } } }, { "compute_Application": { "name": "<app_name>", "platform": "<deploy_app_platform>" } }, { "cicd_Build": { "uid": "<build_uid>", "name": "", "startedAt": 10, "endedAt": 10, "status": { "category": "Success", "detail": "" }, "pipeline": { "uid": "<cicd_pipeline>", "organization": { "uid": "<cicd_organization>", "source": "<cicd_source>" } } } }, { "cicd_Organization": { "uid": "<cicd_organization>", "source": "<cicd_source>" } }, { "cicd_Pipeline": { "uid": "<cicd_pipeline>", "organization": { "uid": "<cicd_organization>", "source": "<cicd_source>" } } } ] }'

    It 'constructs correct event when artifact included using flags'
      cd_event_test() {
        echo $(
          ../faros_event.sh CD -k "<api_key>" \
          --artifact "<artifact_source>://<artifact_org>/<artifact_repo>/<artifact>" \
          --run "<cicd_source>://<cicd_organization>/<cicd_pipeline>/<build_uid>" \
          --run_status "Success" \
          --deploy "<deploy_source>://<app_name>/QA/<deploy_uid>" \
          --deploy_app_platform "<deploy_app_platform>" \
          --deploy_status "Success"
        )
      }
      When call cd_event_test
      The output should include "$CDWithArtifactExpectedOutput"
    End

    It 'constructs correct event when artifact included using environment variables'
      cd_event_test() {
        echo $(
          FAROS_API_KEY="<api_key>" \
          FAROS_ARTIFACT="<artifact_source>://<artifact_org>/<artifact_repo>/<artifact>" \
          FAROS_RUN="<cicd_source>://<cicd_organization>/<cicd_pipeline>/<build_uid>" \
          FAROS_RUN_STATUS="Success" \
          FAROS_DEPLOY="<deploy_source>://<app_name>/QA/<deploy_uid>" \
          FAROS_DEPLOY_APP_PLATFORM="<deploy_app_platform>" \
          FAROS_DEPLOY_STATUS="Success" \
          ../faros_event.sh CD
        )
      }
      When call cd_event_test
      The output should include "$CDWithArtifactExpectedOutput"
    End

    CDWithCommitExpectedOutput='{ "origin": "Faros_Script_Event", "entries": [ { "cicd_Deployment": { "uid": "<deploy_uid>", "source": "<deploy_source>", "status": { "category": "Success", "detail": "" }, "startedAt": 10, "endedAt": 10, "env": { "category": "QA", "detail": "" }, "application": { "name": "<app_name>", "platform": "<deploy_app_platform>" }, "build": { "uid": "<build_uid>", "pipeline": { "uid": "<cicd_pipeline>", "organization": { "uid": "<cicd_organization>", "source": "<cicd_source>" } } } } }, { "cicd_ArtifactDeployment": { "artifact": { "uid": "<commit_sha>", "repository": { "uid": "<vcs_repo>", "organization": { "uid": "<vcs_organization>", "source": "<vcs_source>" } } }, "deployment": { "uid": "<deploy_uid>", "source": "<deploy_source>" } } }, { "compute_Application": { "name": "<app_name>", "platform": "<deploy_app_platform>" } }, { "cicd_Artifact": { "uid": "<commit_sha>", "repository": { "uid": "<vcs_repo>", "organization": { "uid": "<vcs_organization>", "source": "<vcs_source>" } }, "build": { "uid": "<build_uid>", "pipeline": { "uid": "<cicd_pipeline>", "organization": { "uid": "<cicd_organization>", "source": "<cicd_source>" } } } } }, { "cicd_ArtifactCommitAssociation": { "artifact": { "uid": "<commit_sha>", "repository": { "uid": "<vcs_repo>", "organization": { "uid": "<vcs_organization>", "source": "<vcs_source>" } } }, "commit": { "sha": "<commit_sha>", "repository": { "name": "<vcs_repo>", "organization": { "uid": "<vcs_organization>", "source": "<vcs_source>" } } } } }, { "cicd_Build": { "uid": "<build_uid>", "name": "", "startedAt": 10, "endedAt": 10, "status": { "category": "Success", "detail": "" }, "pipeline": { "uid": "<cicd_pipeline>", "organization": { "uid": "<cicd_organization>", "source": "<cicd_source>" } } } }, { "cicd_Organization": { "uid": "<cicd_organization>", "source": "<cicd_source>" } }, { "cicd_Pipeline": { "uid": "<cicd_pipeline>", "organization": { "uid": "<cicd_organization>", "source": "<cicd_source>" } } } ] }'
    
    It 'constructs correct event when commmit included using flags'
      cd_event_test() {
        echo $(
          ../faros_event.sh CD -k "<api_key>" \
          --deploy "<deploy_source>://<app_name>/QA/<deploy_uid>" \
          --commit "<vcs_source>://<vcs_organization>/<vcs_repo>/<commit_sha>" \
          --run "<cicd_source>://<cicd_organization>/<cicd_pipeline>/<build_uid>" \
          --run_status "Success" \
          --deploy_status "Success" \
          --deploy_app_platform "<deploy_app_platform>"
        )
      }
      When call cd_event_test
      The output should include "$CDWithCommitExpectedOutput"
    End

    It 'constructs correct event when commit included using environment variables'
      cd_event_test() {
        echo $(
          FAROS_API_KEY="<api_key>" \
          FAROS_COMMIT="<vcs_source>://<vcs_organization>/<vcs_repo>/<commit_sha>" \
          FAROS_RUN="<cicd_source>://<cicd_organization>/<cicd_pipeline>/<build_uid>" \
          FAROS_RUN_STATUS="Success" \
          FAROS_DEPLOY="<deploy_source>://<app_name>/QA/<deploy_uid>" \
          FAROS_DEPLOY_STATUS="Success" \
          FAROS_DEPLOY_APP_PLATFORM="<deploy_app_platform>" \
          ../faros_event.sh CD
        )
      }
      When call cd_event_test
      The output should include "$CDWithCommitExpectedOutput"
    End

    It 'constructs correct event when run is excluded'
      cd_event_test() {
        echo $(
          ../faros_event.sh CD -k "<api_key>" \
          --artifact "<artifact_source>://<artifact_org>/<artifact_repo>/<artifact>" \
          --deploy "<deploy_source>://<app_name>/QA/<deploy_uid>" \
          --deploy_status "Success"
        )
      }
      When call cd_event_test
      The output should include '{ "origin": "Faros_Script_Event", "entries": [ { "cicd_Deployment": { "uid": "<deploy_uid>", "source": "<deploy_source>", "status": { "category": "Success", "detail": "" }, "startedAt": 10, "endedAt": 10, "env": { "category": "QA", "detail": "" }, "application": { "name": "<app_name>", "platform": "" } } }, { "cicd_ArtifactDeployment": { "artifact": { "uid": "<artifact>", "repository": { "uid": "<artifact_repo>", "organization": { "uid": "<artifact_org>", "source": "<artifact_source>" } } }, "deployment": { "uid": "<deploy_uid>", "source": "<deploy_source>" } } }, { "compute_Application": { "name": "<app_name>", "platform": "" } } ] }'
    End

    It 'fails when artifact and commit missing'
      cd_event_test() {
        echo $(
          ../faros_event.sh CD -k "<api_key>" \
          --run "<cicd_source>://<cicd_organization>/<cicd_pipeline>/<build_uid>" \
          --run_status Success \
          --deploy "<deploy_source>://<app_name>/QA/<deploy_uid>" \
          --deploy_status "Success"
        )
      }
      When call cd_event_test
      The output should equal 'CD event requires --artifact or --commit information Failed.'
    End

    It 'requires --deploy'
      cd_event_test() {
        echo $(
          ../faros_event.sh CD -k "<api_key>" \
          --run "<cicd_source>://<cicd_organization>/<cicd_pipeline>/<build_uid>" \
          --deploy_status "Success"
        )
      }
      When call cd_event_test
      The output should eq ""
      The stderr should include "FAROS_DEPLOY: unbound variable"
    End
  End

  Describe 'CI event'

    CIWithArtifactExpectedOutput='{ "origin": "Faros_Script_Event", "entries": [ { "cicd_Artifact": { "uid": "<artifact>", "repository": { "uid": "<artifact_repo>", "organization": { "uid": "<artifact_org>", "source": "<artifact_source>" } }, "build": { "uid": "<build_uid>", "pipeline": { "uid": "<cicd_pipeline>", "organization": { "uid": "<cicd_organization>", "source": "<cicd_source>" } } } } }, { "cicd_ArtifactCommitAssociation": { "artifact": { "uid": "<artifact>", "repository": { "uid": "<artifact_repo>", "organization": { "uid": "<artifact_org>", "source": "<artifact_source>" } } }, "commit": { "sha": "<commit_sha>", "repository": { "name": "<vcs_repo>", "organization": { "uid": "<vcs_organization>", "source": "<vcs_source>" } } } } }, { "cicd_Build": { "uid": "<build_uid>", "name": "", "startedAt": 10, "endedAt": 10, "status": { "category": "Success", "detail": "" }, "pipeline": { "uid": "<cicd_pipeline>", "organization": { "uid": "<cicd_organization>", "source": "<cicd_source>" } } } }, { "cicd_Organization": { "uid": "<cicd_organization>", "source": "<cicd_source>" } }, { "cicd_Pipeline": { "uid": "<cicd_pipeline>", "organization": { "uid": "<cicd_organization>", "source": "<cicd_source>" } } } ] }'

    It 'constructs correct event when artifact included using flags'
      ci_event_test() {
        echo $(
          ../faros_event.sh CI -k "<api_key>" \
          --artifact "<artifact_source>://<artifact_org>/<artifact_repo>/<artifact>" \
          --commit "<vcs_source>://<vcs_organization>/<vcs_repo>/<commit_sha>" \
          --run "<cicd_source>://<cicd_organization>/<cicd_pipeline>/<build_uid>" \
          --run_status "Success"
        )
      }
      When call ci_event_test
      The output should include "$CIWithArtifactExpectedOutput"
    End

    It 'constructs correct event when artifact included using environment variables'
      ci_event_test() {
        echo $(
          FAROS_API_KEY="<api_key>" \
          FAROS_ARTIFACT="<artifact_source>://<artifact_org>/<artifact_repo>/<artifact>" \
          FAROS_COMMIT="<vcs_source>://<vcs_organization>/<vcs_repo>/<commit_sha>" \
          FAROS_RUN="<cicd_source>://<cicd_organization>/<cicd_pipeline>/<build_uid>" \
          FAROS_RUN_STATUS="Success" \
          ../faros_event.sh CI
        )
      }
      When call ci_event_test
      The output should include "$CIWithArtifactExpectedOutput"
    End

    CIWithoutArtifactExpectedOutput='{ "origin": "Faros_Script_Event", "entries": [ { "cicd_Artifact": { "uid": "<commit_sha>", "repository": { "uid": "<vcs_repo>", "organization": { "uid": "<vcs_organization>", "source": "<vcs_source>" } }, "build": { "uid": "<build_uid>", "pipeline": { "uid": "<cicd_pipeline>", "organization": { "uid": "<cicd_organization>", "source": "<cicd_source>" } } } } }, { "cicd_ArtifactCommitAssociation": { "artifact": { "uid": "<commit_sha>", "repository": { "uid": "<vcs_repo>", "organization": { "uid": "<vcs_organization>", "source": "<vcs_source>" } } }, "commit": { "sha": "<commit_sha>", "repository": { "name": "<vcs_repo>", "organization": { "uid": "<vcs_organization>", "source": "<vcs_source>" } } } } }, { "cicd_Build": { "uid": "<build_uid>", "name": "", "startedAt": 10, "endedAt": 10, "status": { "category": "Success", "detail": "" }, "pipeline": { "uid": "<cicd_pipeline>", "organization": { "uid": "<cicd_organization>", "source": "<cicd_source>" } } } }, { "cicd_Organization": { "uid": "<cicd_organization>", "source": "<cicd_source>" } }, { "cicd_Pipeline": { "uid": "<cicd_pipeline>", "organization": { "uid": "<cicd_organization>", "source": "<cicd_source>" } } } ] }'

    It 'constructs correct event when artifact excluded using flags'
      ci_event_test() {
        echo $(
          ../faros_event.sh CI -k "<api_key>" \
          --commit "<vcs_source>://<vcs_organization>/<vcs_repo>/<commit_sha>" \
          --run "<cicd_source>://<cicd_organization>/<cicd_pipeline>/<build_uid>" \
          --run_status "Success"
        )
      }
      When call ci_event_test
      The output should include "$CIWithoutArtifactExpectedOutput"
    End

    It 'constructs correct event when artifact excluded using environment variables'
      ci_event_test() {
        echo $(
          FAROS_API_KEY="<api_key>" \
          FAROS_COMMIT="<vcs_source>://<vcs_organization>/<vcs_repo>/<commit_sha>" \
          FAROS_RUN="<cicd_source>://<cicd_organization>/<cicd_pipeline>/<build_uid>" \
          FAROS_RUN_STATUS="Success" \
          ../faros_event.sh CI
        )
      }
      When call ci_event_test
      The output should include "$CIWithoutArtifactExpectedOutput"
    End

    It 'constructs correct event when run is excluded'
      ci_event_test() {
        echo $(
          ../faros_event.sh CI -k "<api_key>" \
          --artifact "<artifact_source>://<artifact_org>/<artifact_repo>/<artifact>" \
          --commit "<vcs_source>://<vcs_organization>/<vcs_repo>/<commit_sha>"
        )
      }
      When call ci_event_test
      The output should include '{ "origin": "Faros_Script_Event", "entries": [ { "cicd_Artifact": { "uid": "<artifact>", "repository": { "uid": "<artifact_repo>", "organization": { "uid": "<artifact_org>", "source": "<artifact_source>" } } } }, { "cicd_ArtifactCommitAssociation": { "artifact": { "uid": "<artifact>", "repository": { "uid": "<artifact_repo>", "organization": { "uid": "<artifact_org>", "source": "<artifact_source>" } } }, "commit": { "sha": "<commit_sha>", "repository": { "name": "<vcs_repo>", "organization": { "uid": "<vcs_organization>", "source": "<vcs_source>" } } } } } ] }'
    End
  End

  Describe '--no_build_object'
    It 'constructs correct CD event when present'
      cd_event_test() {
        echo $(
          ../faros_event.sh CD -k "<api_key>" \
          --artifact "<artifact_source>://<artifact_org>/<artifact_repo>/<artifact>" \
          --run "<cicd_source>://<cicd_organization>/<cicd_pipeline>/<build_uid>" \
          --deploy "<deploy_source>://<app_name>/QA/<deploy_uid>" \
          --deploy_status "Success" \
          --no_build_object
        )
      }
      When call cd_event_test
      The output should include '{ "origin": "Faros_Script_Event", "entries": [ { "cicd_Deployment": { "uid": "<deploy_uid>", "source": "<deploy_source>", "status": { "category": "Success", "detail": "" }, "startedAt": 10, "endedAt": 10, "env": { "category": "QA", "detail": "" }, "application": { "name": "<app_name>", "platform": "" }, "build": { "uid": "<build_uid>", "pipeline": { "uid": "<cicd_pipeline>", "organization": { "uid": "<cicd_organization>", "source": "<cicd_source>" } } } } }, { "cicd_ArtifactDeployment": { "artifact": { "uid": "<artifact>", "repository": { "uid": "<artifact_repo>", "organization": { "uid": "<artifact_org>", "source": "<artifact_source>" } } }, "deployment": { "uid": "<deploy_uid>", "source": "<deploy_source>" } } }, { "compute_Application": { "name": "<app_name>", "platform": "" } }, { "cicd_Organization": { "uid": "<cicd_organization>", "source": "<cicd_source>" } }, { "cicd_Pipeline": { "uid": "<cicd_pipeline>", "organization": { "uid": "<cicd_organization>", "source": "<cicd_source>" } } } ] }'
    End
  End

  Describe '--no_lowercase_vcs'
    It 'constructs correct commit object when present'
      ci_event_test() {
        echo $(
          ../faros_event.sh CI -k "<api_key>" \
          --artifact "<artifact_source>://<artifact_org>/<artifact_repo>/<artifact>" \
          --commit "<vcs_source>://<VCS_ORGANIZATION>/<VCS_REPO>/<commit_sha>" \
          --no_lowercase_vcs
        )
      }
      When call ci_event_test
      The output should include '"commit": { "sha": "<commit_sha>", "repository": { "name": "<VCS_REPO>", "organization": { "uid": "<VCS_ORGANIZATION>", "source": "<vcs_source>" } } }'
    End

    It 'constructs correct commit object when absent'
      ci_event_test() {
        echo $(
          ../faros_event.sh CI -k "<api_key>" \
          --artifact "<artifact_source>://<artifact_org>/<artifact_repo>/<artifact>" \
          --commit "<vcs_source>://<VCS_ORGANIZATION>/<VCS_REPO>/<commit_sha>"
        )
      }
      When call ci_event_test
      The output should include '"commit": { "sha": "<commit_sha>", "repository": { "name": "<vcs_repo>", "organization": { "uid": "<vcs_organization>", "source": "<vcs_source>" } } }'
    End
  End

  Describe 'bad input'
    It 'responds with bad input'
      bad_input_test() {
        echo $(
          ../faros_event.sh $1 \
          -k "<key>" \
          --run "<build>" \
          $2
        )
      }
      When call bad_input_test "Bad_Input" "Also_Bad"
      The output should equal 'Unrecognized arg(s): Bad_Input Also_Bad Failed.'
    End

    It 'with malformed URI responds with parsing error'
      bad_input_test() {
        echo $(
          ../faros_event.sh CD -k "<key>" \
          --run "$1"
        )
      }
      When call bad_input_test "bad://uri"
      The output should equal 'Resource URI could not be parsed: bad://uri The URI should be of the form: source://org/pipeline/run Failed.'
    End
  End
End
