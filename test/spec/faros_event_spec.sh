Describe 'faros_event.sh'
  export FAROS_DRY_RUN=1
  export FAROS_NO_FORMAT=1
  Describe 'CD event'
    CDWithArtifactExpectedOutput='{"type":"CD","version":"0.0.1","origin":"Faros_Script_Event-0.3.0","data":{"artifact":{"uri":"<artifact_source>://<artifact_org>/<artifact_repo>/<artifact>"},"run":{"uri":"<cicd_source>://<cicd_organization>/<cicd_pipeline>/<build_uid>","status":"Success","statusDetails":"<run_status_details>","startTime":1,"endTime":2},"deploy":{"uri":"<deploy_source>://<app_name>/QA/<deploy_uid>","status":"Success","statusDetails":"<deploy_status_details>","environmentDetails":"<deploy_env_details>","startTime":3,"endTime":4}}}'

    It 'constructs correct event when artifact included using flags'
      cd_event_test() {
        echo $(
          ../faros_event.sh CD -k "<api_key>" \
          --artifact "<artifact_source>://<artifact_org>/<artifact_repo>/<artifact>" \
          --run "<cicd_source>://<cicd_organization>/<cicd_pipeline>/<build_uid>" \
          --run_status "Success" \
          --run_status_details "<run_status_details>" \
          --run_start_time "1" \
          --run_end_time "2" \
          --deploy "<deploy_source>://<app_name>/QA/<deploy_uid>" \
          --deploy_app_platform "<deploy_app_platform>" \
          --deploy_env_details "<deploy_env_details>" \
          --deploy_status "Success" \
          --deploy_status_details "<deploy_status_details>" \
          --deploy_start_time "3" \
          --deploy_end_time "4"
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
          FAROS_RUN_STATUS_DETAILS="<run_status_details>" \
          FAROS_RUN_START_TIME="1" \
          FAROS_RUN_END_TIME="2" \
          FAROS_DEPLOY="<deploy_source>://<app_name>/QA/<deploy_uid>" \
          FAROS_DEPLOY_APP_PLATFORM="<deploy_app_platform>" \
          FAROS_DEPLOY_ENV_DETAILS="<deploy_env_details>" \
          FAROS_DEPLOY_STATUS="Success" \
          FAROS_DEPLOY_STATUS_DETAILS="<deploy_status_details>" \
          FAROS_DEPLOY_START_TIME="3" \
          FAROS_DEPLOY_END_TIME="4" \
          ../faros_event.sh CD
        )
      }
      When call cd_event_test
      The output should include "$CDWithArtifactExpectedOutput"
    End

    CDWithCommitExpectedOutput='{"type":"CD","version":"0.0.1","origin":"Faros_Script_Event-0.3.0","data":{"commit":{"sha":"<commit_sha>","repository":"<vcs_repo>","organization":"<vcs_organization>","source":"<vcs_source>"},"run":{"uri":"<cicd_source>://<cicd_organization>/<cicd_pipeline>/<build_uid>","status":"Success","statusDetails":"<run_status_details>","startTime":1,"endTime":2},"deploy":{"uri":"<deploy_source>://<app_name>/QA/<deploy_uid>","status":"Success","statusDetails":"<deploy_status_details>","environmentDetails":"<deploy_env_details>","startTime":3,"endTime":4}}}'
    
    It 'constructs correct event when commmit included using flags'
      cd_event_test() {
        echo $(
          ../faros_event.sh CD -k "<api_key>" \
          --deploy "<deploy_source>://<app_name>/QA/<deploy_uid>" \
          --commit "<vcs_source>://<vcs_organization>/<vcs_repo>/<commit_sha>" \
          --run "<cicd_source>://<cicd_organization>/<cicd_pipeline>/<build_uid>" \
          --run_status "Success" \
          --run_status_details "<run_status_details>" \
          --run_start_time "1" \
          --run_end_time "2" \
          --deploy_app_platform "<deploy_app_platform>" \
          --deploy_env_details "<deploy_env_details>" \
          --deploy_status "Success" \
          --deploy_status_details "<deploy_status_details>" \
          --deploy_start_time "3" \
          --deploy_end_time "4"
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
          FAROS_RUN_STATUS_DETAILS="<run_status_details>" \
          FAROS_RUN_START_TIME="1" \
          FAROS_RUN_END_TIME="2" \
          FAROS_DEPLOY="<deploy_source>://<app_name>/QA/<deploy_uid>" \
          FAROS_DEPLOY_APP_PLATFORM="<deploy_app_platform>" \
          FAROS_DEPLOY_ENV_DETAILS="<deploy_env_details>" \
          FAROS_DEPLOY_STATUS="Success" \
          FAROS_DEPLOY_STATUS_DETAILS="<deploy_status_details>" \
          FAROS_DEPLOY_START_TIME="3" \
          FAROS_DEPLOY_END_TIME="4" \
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
      The output should include '{"type":"CD","version":"0.0.1","origin":"Faros_Script_Event-0.3.0","data":{"artifact":{"uri":"<artifact_source>://<artifact_org>/<artifact_repo>/<artifact>"},"deploy":{"uri":"<deploy_source>://<app_name>/QA/<deploy_uid>","status":"Success"}}}'
    End
  End

  Describe 'CI event'

    CIWithArtifactExpectedOutput='{"type":"CI","version":"0.0.1","origin":"Faros_Script_Event-0.3.0","data":{"artifact":{"uri":"<artifact_source>://<artifact_org>/<artifact_repo>/<artifact>"},"commit":{"sha":"<commit_sha>","repository":"<vcs_repo>","organization":"<vcs_organization>","source":"<vcs_source>"},"run":{"uri":"<cicd_source>://<cicd_organization>/<cicd_pipeline>/<build_uid>","status":"Success"}}}'

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

    CIWithoutArtifactExpectedOutput='{"type":"CI","version":"0.0.1","origin":"Faros_Script_Event-0.3.0","data":{"commit":{"sha":"<commit_sha>","repository":"<vcs_repo>","organization":"<vcs_organization>","source":"<vcs_source>"},"run":{"uri":"<cicd_source>://<cicd_organization>/<cicd_pipeline>/<build_uid>","status":"Success","statusDetails":"<run_status_details>","startTime":1,"endTime":2}}}'

    It 'constructs correct event when artifact excluded using flags'
      ci_event_test() {
        echo $(
          ../faros_event.sh CI -k "<api_key>" \
          --commit "<vcs_source>://<vcs_organization>/<vcs_repo>/<commit_sha>" \
          --run "<cicd_source>://<cicd_organization>/<cicd_pipeline>/<build_uid>" \
          --run_status "Success" \
          --run_status_details "<run_status_details>" \
          --run_start_time "1" \
          --run_end_time "2" \
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
          FAROS_RUN_STATUS_DETAILS="<run_status_details>" \
          FAROS_RUN_START_TIME="1" \
          FAROS_RUN_END_TIME="2" \
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
      The output should include '{"type":"CI","version":"0.0.1","origin":"Faros_Script_Event-0.3.0","data":{"artifact":{"uri":"<artifact_source>://<artifact_org>/<artifact_repo>/<artifact>"},"commit":{"sha":"<commit_sha>","repository":"<vcs_repo>","organization":"<vcs_organization>","source":"<vcs_source>"}}}'
    End
  End

  Describe '--no_lowercase_vcs'
    It 'constructs correct commit object when present'
      ci_event_test() {
        echo $(
          ../faros_event.sh CI -k "<api_key>" \
          --commit "<vcs_source>://<VCS_ORGANIZATION>/<VCS_REPO>/<commit_sha>" \
          --no_lowercase_vcs
        )
      }
      When call ci_event_test
      The output should include '"commit":{"sha":"<commit_sha>","repository":"<VCS_REPO>","organization":"<VCS_ORGANIZATION>","source":"<vcs_source>"}}'
    End

    It 'constructs correct commit object when absent'
      ci_event_test() {
        echo $(
          ../faros_event.sh CI -k "<api_key>" \
          --commit "<vcs_source>://<VCS_ORGANIZATION>/<VCS_REPO>/<commit_sha>"
        )
      }
      When call ci_event_test
      The output should include '"commit":{"sha":"<commit_sha>","repository":"<vcs_repo>","organization":"<vcs_organization>","source":"<vcs_source>"}}'
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
          ../faros_event.sh CI -k "<key>" \
          --commit "$1"
        )
      }
      When call bad_input_test "bad://uri"
      The output should equal 'Resource URI could not be parsed: bad://uri The URI should be of the form: source://org/repo/commit Failed.'
    End
  End
End
