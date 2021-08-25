Describe 'faros_event.sh'
  Describe 'CD event'

    CDWithArtifactExpectedOutput='{ "origin": "Faros_Script_Event", "entries": [ { "cicd_Deployment": { "uid": "<deployment_uid>", "source": "<deployment_source>", "status": { "category": "Success", "detail": "" }, "startedAt": 10, "endedAt": 10, "env": { "category": "QA", "detail": "" }, "application": { "name": "<app_name>", "platform": "<app_platform>" }, "build": { "uid": "<build_uid>", "pipeline": { "uid": "<cicd_pipeline>", "organization": { "uid": "<cicd_organization>", "source": "<cicd_source>" } } } } }, { "cicd_ArtifactDeployment": { "artifact": { "uid": "<artifact>", "repository": { "uid": "<artifact_repo>", "organization": { "uid": "<artifact_org>", "source": "<artifact_source>" } } }, "deployment": { "uid": "<deployment_uid>", "source": "<deployment_source>" } } }, { "compute_Application": { "name": "<app_name>", "platform": "<app_platform>" } } ] }'

    It 'constructs correct event when artifact included using flags'
      cd_event_test() {
        echo $(
          ../faros_event.sh CD --dry_run --no_format \
          -k "<api_key>" \
          --artifact "<artifact_source>://<artifact_org>/<artifact_repo>/<artifact>" \
          --build "<cicd_source>://<cicd_organization>/<cicd_pipeline>/<build_uid>" \
          --deployment "<deployment_source>://<app_name>/QA/<deployment_uid>" \
          --app_platform "<app_platform>" \
          --deployment_status Success \
          --deployment_start_time 10 \
          --deployment_end_time 10
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
          FAROS_APP_PLATFORM="<app_platform>" \
          FAROS_DEPLOYMENT_STATUS="Success" \
          FAROS_DEPLOYMENT_START_TIME=10 \
          FAROS_DEPLOYMENT_END_TIME=10 \
          ../faros_event.sh CD --dry_run --no_format
        )
      }
      When call cd_event_test
      The output should include "$CDWithArtifactExpectedOutput"
    End

    CDWithCommitExpectedOutput='{ "origin": "Faros_Script_Event", "entries": [ { "cicd_Deployment": { "uid": "<deployment_uid>", "source": "<deployment_source>", "status": { "category": "Success", "detail": "" }, "startedAt": 10, "endedAt": 10, "env": { "category": "QA", "detail": "" }, "application": { "name": "<app_name>", "platform": "<app_platform>" }, "build": { "uid": "<build_uid>", "pipeline": { "uid": "<cicd_pipeline>", "organization": { "uid": "<cicd_organization>", "source": "<cicd_source>" } } } } }, { "cicd_ArtifactDeployment": { "artifact": { "uid": "<commit_sha>", "repository": { "uid": "<vcs_repo>", "organization": { "uid": "<vcs_organization>", "source": "<vcs_source>" } } }, "deployment": { "uid": "<deployment_uid>", "source": "<deployment_source>" } } }, { "compute_Application": { "name": "<app_name>", "platform": "<app_platform>" } }, { "cicd_Artifact": { "uid": "<commit_sha>", "build": { "uid": "<build_uid>", "pipeline": { "uid": "<cicd_pipeline>", "organization": { "uid": "<cicd_organization>", "source": "<cicd_source>" } } }, "repository": { "uid": "<vcs_repo>", "organization": { "uid": "<vcs_organization>", "source": "<vcs_source>" } } } }, { "cicd_ArtifactCommitAssociation": { "artifact": { "uid": "<commit_sha>", "repository": { "uid": "<vcs_repo>", "organization": { "uid": "<vcs_organization>", "source": "<vcs_source>" } } }, "commit": { "sha": "<commit_sha>", "repository": { "name": "<vcs_repo>", "organization": { "uid": "<vcs_organization>", "source": "<vcs_source>" } } } } } ] }'
    
    It 'constructs correct event when commmit included using flags'
      cd_event_test() {
        echo $(
          ../faros_event.sh CD --dry_run --no_format \
          -k "<api_key>" \
          --build "<cicd_source>://<cicd_organization>/<cicd_pipeline>/<build_uid>" \
          --deployment "<deployment_source>://<app_name>/QA/<deployment_uid>" \
          --vcs "<vcs_source>://<vcs_organization>/<vcs_repo>/<commit_sha>" \
          --deployment_status Success \
          --app_platform "<app_platform>" \
          --deployment_start_time 10 \
          --deployment_end_time 10 \
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
          FAROS_VCS="<vcs_source>://<vcs_organization>/<vcs_repo>/<commit_sha>" \
          FAROS_DEPLOYMENT_STATUS="Success" \
          FAROS_APP_PLATFORM="<app_platform>" \
          ../faros_event.sh CD --dry_run --no_format \
          --start_time 10 \
          --end_time 10
        )
      }
      When call cd_event_test
      The output should include "$CDWithCommitExpectedOutput"
    End

    It 'fails when artifact and vcs missing'
      cd_event_test() {
        echo $(
          FAROS_START_TIME=10 \
          FAROS_END_TIME=10 \
          ../faros_event.sh CD --dry_run --no_format \
          -k "<api_key>" \
          --build "<cicd_source>://<cicd_organization>/<cicd_pipeline>/<build_uid>" \
          --deployment "<deployment_source>://<app_name>/QA/<deployment_uid>" \
          --deployment_status Success
        )
      }
      When call cd_event_test
      The output should include 'CD event requires artifact or vcs information Failed.'
    End

    It 'requires --deployment'
      cd_event_test() {
        echo $(
          FAROS_START_TIME=10 \
          FAROS_END_TIME=10 \
          ../faros_event.sh CD --dry_run --no_format \
          -k "<api_key>" \
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

    CIWithArtifactExpectedOutput='{ "origin": "Faros_Script_Event", "entries": [ { "cicd_Artifact": { "uid": "<artifact>", "build": { "uid": "<build_uid>", "pipeline": { "uid": "<cicd_pipeline>", "organization": { "uid": "<cicd_organization>", "source": "<cicd_source>" } } }, "repository": { "uid": "<artifact_repo>", "organization": { "uid": "<artifact_org>", "source": "<artifact_source>" } } } }, { "cicd_ArtifactCommitAssociation": { "artifact": { "uid": "<artifact>", "repository": { "uid": "<artifact_repo>", "organization": { "uid": "<artifact_org>", "source": "<artifact_source>" } } }, "commit": { "sha": "<commit_sha>", "repository": { "name": "<vcs_repo>", "organization": { "uid": "<vcs_organization>", "source": "<vcs_source>" } } } } } ] }'

    It 'constructs correct event when artifact included using flags'
      ci_event_test() {
        echo $(
          ../faros_event.sh CI --dry_run --no_format \
          -k "<api_key>" \
          --artifact "<artifact_source>://<artifact_org>/<artifact_repo>/<artifact>" \
          --build "<cicd_source>://<cicd_organization>/<cicd_pipeline>/<build_uid>" \
          --vcs "<vcs_source>://<vcs_organization>/<vcs_repo>/<commit_sha>"
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
          FAROS_VCS="<vcs_source>://<vcs_organization>/<vcs_repo>/<commit_sha>" \
          ../faros_event.sh CI --dry_run --no_format
        )
      }
      When call ci_event_test
      The output should include "$CIWithArtifactExpectedOutput"
    End

    CIWithoutArtifactExpectedOutput='{ "origin": "Faros_Script_Event", "entries": [ { "cicd_Artifact": { "uid": "<commit_sha>", "build": { "uid": "<build_uid>", "pipeline": { "uid": "<cicd_pipeline>", "organization": { "uid": "<cicd_organization>", "source": "<cicd_source>" } } }, "repository": { "uid": "<vcs_repo>", "organization": { "uid": "<vcs_organization>", "source": "<vcs_source>" } } } }, { "cicd_ArtifactCommitAssociation": { "artifact": { "uid": "<commit_sha>", "repository": { "uid": "<vcs_repo>", "organization": { "uid": "<vcs_organization>", "source": "<vcs_source>" } } }, "commit": { "sha": "<commit_sha>", "repository": { "name": "<vcs_repo>", "organization": { "uid": "<vcs_organization>", "source": "<vcs_source>" } } } } } ] }'

    It 'constructs correct event when artifact excluded using flags'
      ci_event_test() {
        echo $(
          ../faros_event.sh CI --dry_run --no_format \
          -k "<api_key>" \
          --build "<cicd_source>://<cicd_organization>/<cicd_pipeline>/<build_uid>" \
          --vcs "<vcs_source>://<vcs_organization>/<vcs_repo>/<commit_sha>"
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
          FAROS_VCS="<vcs_source>://<vcs_organization>/<vcs_repo>/<commit_sha>" \
          ../faros_event.sh CI --dry_run --no_format
        )
      }
      When call ci_event_test
      The output should include "$CIWithoutArtifactExpectedOutput"
    End
  End

  Describe 'bad input'
    It 'responds with bad input'
        bad_input_test() {
          echo $(
            ../faros_event.sh $1 \
            -k "<key>" \
            --build "<build>" \
            $2 \
            --no_format
          )
        }
        When call bad_input_test "Bad_Input" "Also_Bad"
        The output should equal 'Unrecognized arg(s): Bad_Input Also_Bad Failed.'
    End

    It 'with malformed URI responds with parsing error'
        bad_input_test() {
          echo $(
            ../faros_event.sh CD \
            -k "<key>" \
            --build "$1" \
            --no_format
          )
        }
        When call bad_input_test "bad://uri"
        The output should equal 'Resource URI could not be parsed: bad://uri Failed.'
    End
  End
End
