Describe 'faros_event.sh'
  export FAROS_DRY_RUN=1
  export FAROS_NO_FORMAT=1
  export FAROS_START_TIME=10
  export FAROS_END_TIME=10
  Describe 'CD event'
    CDWithArtifactExpectedOutput='{ "origin": "Faros_Script_Event", "entries": [ { "cicd_Deployment": { "uid": "<deployment_uid>", "source": "<deployment_source>", "status": { "category": "Success", "detail": "" }, "startedAt": 10, "endedAt": 10, "env": { "category": "QA", "detail": "" }, "application": { "name": "<app_name>", "platform": "<deployment_app_platform>" }, "build": { "uid": "<build_uid>", "pipeline": { "uid": "<cicd_pipeline>", "organization": { "uid": "<cicd_organization>", "source": "<cicd_source>" } } } } }, { "cicd_ArtifactDeployment": { "artifact": { "uid": "<artifact>", "repository": { "uid": "<artifact_repo>", "organization": { "uid": "<artifact_org>", "source": "<artifact_source>" } } }, "deployment": { "uid": "<deployment_uid>", "source": "<deployment_source>" } } }, { "compute_Application": { "name": "<app_name>", "platform": "<deployment_app_platform>" } } ] }'

    It 'constructs correct event when artifact included using flags'
      cd_event_test() {
        echo $(
          ../faros_event.sh CD -k "<api_key>" \
          --artifact "<artifact_source>://<artifact_org>/<artifact_repo>/<artifact>" \
          --build "<cicd_source>://<cicd_organization>/<cicd_pipeline>/<build_uid>" \
          --deployment "<deployment_source>://<app_name>/QA/<deployment_uid>" \
          --deployment_app_platform "<deployment_app_platform>" \
          --deployment_status Success
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
          FAROS_BUILD="<cicd_source>://<cicd_organization>/<cicd_pipeline>/<build_uid>" \
          FAROS_DEPLOYMENT="<deployment_source>://<app_name>/QA/<deployment_uid>" \
          FAROS_APP_PLATFORM="<deployment_app_platform>" \
          FAROS_DEPLOYMENT_STATUS="Success" \
          ../faros_event.sh CD
        )
      }
      When call cd_event_test
      The output should include "$CDWithArtifactExpectedOutput"
    End

    CDWithCommitExpectedOutput='{ "origin": "Faros_Script_Event", "entries": [ { "cicd_Deployment": { "uid": "<deployment_uid>", "source": "<deployment_source>", "status": { "category": "Success", "detail": "" }, "startedAt": 10, "endedAt": 10, "env": { "category": "QA", "detail": "" }, "application": { "name": "<app_name>", "platform": "<deployment_app_platform>" }, "build": { "uid": "<build_uid>", "pipeline": { "uid": "<cicd_pipeline>", "organization": { "uid": "<cicd_organization>", "source": "<cicd_source>" } } } } }, { "cicd_ArtifactDeployment": { "artifact": { "uid": "<commit_sha>", "repository": { "uid": "<vcs_repo>", "organization": { "uid": "<vcs_organization>", "source": "<vcs_source>" } } }, "deployment": { "uid": "<deployment_uid>", "source": "<deployment_source>" } } }, { "compute_Application": { "name": "<app_name>", "platform": "<deployment_app_platform>" } }, { "cicd_Artifact": { "uid": "<commit_sha>", "repository": { "uid": "<vcs_repo>", "organization": { "uid": "<vcs_organization>", "source": "<vcs_source>" } }, "build": { "uid": "<build_uid>", "pipeline": { "uid": "<cicd_pipeline>", "organization": { "uid": "<cicd_organization>", "source": "<cicd_source>" } } } } }, { "cicd_ArtifactCommitAssociation": { "artifact": { "uid": "<commit_sha>", "repository": { "uid": "<vcs_repo>", "organization": { "uid": "<vcs_organization>", "source": "<vcs_source>" } } }, "commit": { "sha": "<commit_sha>", "repository": { "name": "<vcs_repo>", "organization": { "uid": "<vcs_organization>", "source": "<vcs_source>" } } } } } ] }'
    
    It 'constructs correct event when commmit included using flags'
      cd_event_test() {
        echo $(
          ../faros_event.sh CD -k "<api_key>" \
          --build "<cicd_source>://<cicd_organization>/<cicd_pipeline>/<build_uid>" \
          --deployment "<deployment_source>://<app_name>/QA/<deployment_uid>" \
          --commit "<vcs_source>://<vcs_organization>/<vcs_repo>/<commit_sha>" \
          --deployment_status Success \
          --deployment_app_platform "<deployment_app_platform>" \
        )
      }
      When call cd_event_test
      The output should include "$CDWithCommitExpectedOutput"
    End

    It 'constructs correct event when commit included using environment variables'
      cd_event_test() {
        echo $(
          FAROS_API_KEY="<api_key>" \
          FAROS_BUILD="<cicd_source>://<cicd_organization>/<cicd_pipeline>/<build_uid>" \
          FAROS_DEPLOYMENT="<deployment_source>://<app_name>/QA/<deployment_uid>" \
          FAROS_COMMIT="<vcs_source>://<vcs_organization>/<vcs_repo>/<commit_sha>" \
          FAROS_DEPLOYMENT_STATUS="Success" \
          FAROS_APP_PLATFORM="<deployment_app_platform>" \
          ../faros_event.sh CD
        )
      }
      When call cd_event_test
      The output should include "$CDWithCommitExpectedOutput"
    End

    It 'constructs correct event when build is excluded'
      cd_event_test() {
        echo $(
          ../faros_event.sh CD -k "<api_key>" \
          --artifact "<artifact_source>://<artifact_org>/<artifact_repo>/<artifact>" \
          --deployment "<deployment_source>://<app_name>/QA/<deployment_uid>" \
          --deployment_status Success
        )
      }
      When call cd_event_test
      The output should include '{ "origin": "Faros_Script_Event", "entries": [ { "cicd_Deployment": { "uid": "<deployment_uid>", "source": "<deployment_source>", "status": { "category": "Success", "detail": "" }, "startedAt": 10, "endedAt": 10, "env": { "category": "QA", "detail": "" }, "application": { "name": "<app_name>", "platform": "" } } }, { "cicd_ArtifactDeployment": { "artifact": { "uid": "<artifact>", "repository": { "uid": "<artifact_repo>", "organization": { "uid": "<artifact_org>", "source": "<artifact_source>" } } }, "deployment": { "uid": "<deployment_uid>", "source": "<deployment_source>" } } }, { "compute_Application": { "name": "<app_name>", "platform": "" } } ] }'
    End

    It 'fails when artifact and commit missing'
      cd_event_test() {
        echo $(
          ../faros_event.sh CD -k "<api_key>" \
          --build "<cicd_source>://<cicd_organization>/<cicd_pipeline>/<build_uid>" \
          --deployment "<deployment_source>://<app_name>/QA/<deployment_uid>" \
          --deployment_status Success
        )
      }
      When call cd_event_test
      The output should equal 'CD event requires artifact or commit information Failed.'
    End

    It 'requires --deployment'
      cd_event_test() {
        echo $(
          ../faros_event.sh CD -k "<api_key>" \
          --build "<cicd_source>://<cicd_organization>/<cicd_pipeline>/<build_uid>" \
          --deployment_status Success
        )
      }
      When call cd_event_test
      The output should eq ""
      The stderr should include "FAROS_DEPLOYMENT: unbound variable"
    End
  End

  Describe 'CI event'

    CIWithArtifactExpectedOutput='{ "origin": "Faros_Script_Event", "entries": [ { "cicd_Artifact": { "uid": "<artifact>", "repository": { "uid": "<artifact_repo>", "organization": { "uid": "<artifact_org>", "source": "<artifact_source>" } }, "build": { "uid": "<build_uid>", "pipeline": { "uid": "<cicd_pipeline>", "organization": { "uid": "<cicd_organization>", "source": "<cicd_source>" } } } } }, { "cicd_ArtifactCommitAssociation": { "artifact": { "uid": "<artifact>", "repository": { "uid": "<artifact_repo>", "organization": { "uid": "<artifact_org>", "source": "<artifact_source>" } } }, "commit": { "sha": "<commit_sha>", "repository": { "name": "<vcs_repo>", "organization": { "uid": "<vcs_organization>", "source": "<vcs_source>" } } } } } ] }'

    It 'constructs correct event when artifact included using flags'
      ci_event_test() {
        echo $(
          ../faros_event.sh CI -k "<api_key>" \
          --artifact "<artifact_source>://<artifact_org>/<artifact_repo>/<artifact>" \
          --build "<cicd_source>://<cicd_organization>/<cicd_pipeline>/<build_uid>" \
          --commit "<vcs_source>://<vcs_organization>/<vcs_repo>/<commit_sha>"
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
          FAROS_BUILD="<cicd_source>://<cicd_organization>/<cicd_pipeline>/<build_uid>" \
          FAROS_COMMIT="<vcs_source>://<vcs_organization>/<vcs_repo>/<commit_sha>" \
          ../faros_event.sh CI
        )
      }
      When call ci_event_test
      The output should include "$CIWithArtifactExpectedOutput"
    End

    CIWithoutArtifactExpectedOutput='{ "origin": "Faros_Script_Event", "entries": [ { "cicd_Artifact": { "uid": "<commit_sha>", "repository": { "uid": "<vcs_repo>", "organization": { "uid": "<vcs_organization>", "source": "<vcs_source>" } }, "build": { "uid": "<build_uid>", "pipeline": { "uid": "<cicd_pipeline>", "organization": { "uid": "<cicd_organization>", "source": "<cicd_source>" } } } } }, { "cicd_ArtifactCommitAssociation": { "artifact": { "uid": "<commit_sha>", "repository": { "uid": "<vcs_repo>", "organization": { "uid": "<vcs_organization>", "source": "<vcs_source>" } } }, "commit": { "sha": "<commit_sha>", "repository": { "name": "<vcs_repo>", "organization": { "uid": "<vcs_organization>", "source": "<vcs_source>" } } } } } ] }'

    It 'constructs correct event when artifact excluded using flags'
      ci_event_test() {
        echo $(
          ../faros_event.sh CI -k "<api_key>" \
          --build "<cicd_source>://<cicd_organization>/<cicd_pipeline>/<build_uid>" \
          --commit "<vcs_source>://<vcs_organization>/<vcs_repo>/<commit_sha>"
        )
      }
      When call ci_event_test
      The output should include "$CIWithoutArtifactExpectedOutput"
    End

    It 'constructs correct event when artifact excluded using environment variables'
      ci_event_test() {
        echo $(
          FAROS_API_KEY="<api_key>" \
          FAROS_BUILD="<cicd_source>://<cicd_organization>/<cicd_pipeline>/<build_uid>" \
          FAROS_COMMIT="<vcs_source>://<vcs_organization>/<vcs_repo>/<commit_sha>" \
          ../faros_event.sh CI
        )
      }
      When call ci_event_test
      The output should include "$CIWithoutArtifactExpectedOutput"
    End

    It 'constructs correct event when build is excluded'
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

  Describe '--write_build'
    It 'correctly adds a cicd_Build to the event'
       write_build_test() {
        echo $(
          ../faros_event.sh CI -k "<key>" \
          --build "<cicd_source>://<cicd_organization>/<cicd_pipeline>/<build_uid>" \
          --commit "<vcs_source>://<vcs_organization>/<vcs_repo>/<commit_sha>" \
          --build_status "Success" \
          --write_build
        )
      }
      When call write_build_test
      The output should include '{ "origin": "Faros_Script_Event", "entries": [ { "cicd_Artifact": { "uid": "<commit_sha>", "repository": { "uid": "<vcs_repo>", "organization": { "uid": "<vcs_organization>", "source": "<vcs_source>" } }, "build": { "uid": "<build_uid>", "pipeline": { "uid": "<cicd_pipeline>", "organization": { "uid": "<cicd_organization>", "source": "<cicd_source>" } } } } }, { "cicd_ArtifactCommitAssociation": { "artifact": { "uid": "<commit_sha>", "repository": { "uid": "<vcs_repo>", "organization": { "uid": "<vcs_organization>", "source": "<vcs_source>" } } }, "commit": { "sha": "<commit_sha>", "repository": { "name": "<vcs_repo>", "organization": { "uid": "<vcs_organization>", "source": "<vcs_source>" } } } } }, { "cicd_Build": { "uid": "<build_uid>", "name": "", "startedAt": 10, "endedAt": 10, "status": { "category": "Success", "detail": "" }, "pipeline": { "uid": "<cicd_pipeline>", "organization": { "uid": "<cicd_organization>", "source": "<cicd_source>" } } } } ] }'
    End

    It 'fails when --build missing'
      missing_build_test() {
        echo $(
          ../faros_event.sh CI -k "<key>" \
          --commit "<vcs_source>://<vcs_organization>/<vcs_repo>/<commit_sha>" \
          --write_build
        )
      }
      When call missing_build_test
      The output should include "Build information must be passed to use the --write_build flag Failed."
    End
  End

  Describe '--write_cicd_objects'
    It 'correctly adds a cicd_Organization and cicd_Pipeline to the event'
       write_build_test() {
        echo $(
          ../faros_event.sh CI -k "<key>" \
          --build "<cicd_source>://<cicd_organization>/<cicd_pipeline>/<build_uid>" \
          --commit "<vcs_source>://<vcs_organization>/<vcs_repo>/<commit_sha>" \
          --build_status "Success" \
          --write_cicd_objects
        )
      }
      When call write_build_test
      The output should include '{ "origin": "Faros_Script_Event", "entries": [ { "cicd_Artifact": { "uid": "<commit_sha>", "repository": { "uid": "<vcs_repo>", "organization": { "uid": "<vcs_organization>", "source": "<vcs_source>" } }, "build": { "uid": "<build_uid>", "pipeline": { "uid": "<cicd_pipeline>", "organization": { "uid": "<cicd_organization>", "source": "<cicd_source>" } } } } }, { "cicd_ArtifactCommitAssociation": { "artifact": { "uid": "<commit_sha>", "repository": { "uid": "<vcs_repo>", "organization": { "uid": "<vcs_organization>", "source": "<vcs_source>" } } }, "commit": { "sha": "<commit_sha>", "repository": { "name": "<vcs_repo>", "organization": { "uid": "<vcs_organization>", "source": "<vcs_source>" } } } } }, { "cicd_Organization": { "uid": "<cicd_organization>", "source": "<cicd_source>" } }, { "cicd_Pipeline": { "uid": "<cicd_pipeline>", "organization": { "uid": "<cicd_organization>", "source": "<cicd_source>" } } } ] }'
    End

    It 'fails when --build missing'
      missing_build_test() {
        echo $(
          ../faros_event.sh CI -k "<key>" \
          --commit "<vcs_source>://<vcs_organization>/<vcs_repo>/<commit_sha>" \
          --write_cicd_objects
        )
      }
      When call missing_build_test
      The output should include "Build information must be passed to use the --write_cicd_objects flag Failed."
    End
  End

  Describe 'bad input'
    It 'responds with bad input'
      bad_input_test() {
        echo $(
          ../faros_event.sh $1 \
          -k "<key>" \
          --build "<build>" \
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
          --build "$1"
        )
      }
      When call bad_input_test "bad://uri"
      The output should equal 'Resource URI could not be parsed: bad://uri Failed.'
    End
  End
End
