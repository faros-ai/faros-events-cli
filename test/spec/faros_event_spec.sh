Describe 'faros_event.sh'
  export FAROS_NO_FORMAT=1
  export FAROS_DRY_RUN=1

  Describe 'CD event'
    CDWithArtifactExpectedOutput='{"type":"CD","version":"0.0.1","origin":"Faros_Script_Event","data":{"deploy":{"id":"<deploy_uid>","environment":"QA","application":"<app_name>","source":"<deploy_source>","status":"Success","applicationPlatform":"<deploy_app_platform>","statusDetails":"<deploy_status_details>","environmentDetails":"<deploy_env_details>","startTime":"1970-01-01T00:00:03Z","endTime":"1970-01-01T00:00:04Z"},"artifact":{"id":"<artifact>","repository":"<artifact_repo>","organization":"<artifact_org>","source":"<artifact_source>"},"run":{"id":"<build_uid>","pipeline":"<cicd_pipeline>","organization":"<cicd_organization>","source":"<cicd_source>","status":"Success","statusDetails":"<run_status_details>","startTime":"1970-01-01T00:00:01Z","endTime":"1970-01-01T00:00:02Z"}}}'

    It 'constructs correct event when artifact included using flags'
      cd_event_test() {
        echo $(
          ../faros_event.sh CD -k "<api_key>" \
          --artifact "<artifact_source>://<artifact_org>/<artifact_repo>/<artifact>" \
          --run "<cicd_source>://<cicd_organization>/<cicd_pipeline>/<build_uid>" \
          --run_status "Success" \
          --run_status_details "<run_status_details>" \
          --run_start_time "1000" \
          --run_end_time "2000" \
          --deploy "<deploy_source>://<app_name>/QA/<deploy_uid>" \
          --deploy_app_platform "<deploy_app_platform>" \
          --deploy_env_details "<deploy_env_details>" \
          --deploy_status "Success" \
          --deploy_status_details "<deploy_status_details>" \
          --deploy_start_time "3000" \
          --deploy_end_time "4000"
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
          FAROS_RUN_START_TIME="1000" \
          FAROS_RUN_END_TIME="2000" \
          FAROS_DEPLOY="<deploy_source>://<app_name>/QA/<deploy_uid>" \
          FAROS_DEPLOY_APP_PLATFORM="<deploy_app_platform>" \
          FAROS_DEPLOY_ENV_DETAILS="<deploy_env_details>" \
          FAROS_DEPLOY_STATUS="Success" \
          FAROS_DEPLOY_STATUS_DETAILS="<deploy_status_details>" \
          FAROS_DEPLOY_START_TIME="3000" \
          FAROS_DEPLOY_END_TIME="4000" \
          ../faros_event.sh CD
        )
      }
      When call cd_event_test
      The output should include "$CDWithArtifactExpectedOutput"
    End

    CDWithCommitExpectedOutput='{"type":"CD","version":"0.0.1","origin":"Faros_Script_Event","data":{"deploy":{"id":"<deploy_uid>","environment":"QA","application":"<app_name>","source":"<deploy_source>","status":"Success","applicationPlatform":"<deploy_app_platform>","statusDetails":"<deploy_status_details>","environmentDetails":"<deploy_env_details>","startTime":"1970-01-01T00:00:03Z","endTime":"1970-01-01T00:00:04Z"},"commit":{"sha":"<commit_sha>","repository":"<vcs_repo>","organization":"<vcs_organization>","source":"<vcs_source>"},"run":{"id":"<build_uid>","pipeline":"<cicd_pipeline>","organization":"<cicd_organization>","source":"<cicd_source>","status":"Success","statusDetails":"<run_status_details>","startTime":"1970-01-01T00:00:01Z","endTime":"1970-01-01T00:00:02Z"}}}'

    It 'constructs correct event when commmit included using flags'
      cd_event_test() {
        echo $(
          ../faros_event.sh CD -k "<api_key>" \
          --deploy "<deploy_source>://<app_name>/QA/<deploy_uid>" \
          --commit "<vcs_source>://<vcs_organization>/<vcs_repo>/<commit_sha>" \
          --run "<cicd_source>://<cicd_organization>/<cicd_pipeline>/<build_uid>" \
          --run_status "Success" \
          --run_status_details "<run_status_details>" \
          --run_start_time "1000" \
          --run_end_time "2000" \
          --deploy_app_platform "<deploy_app_platform>" \
          --deploy_env_details "<deploy_env_details>" \
          --deploy_status "Success" \
          --deploy_status_details "<deploy_status_details>" \
          --deploy_start_time "3000" \
          --deploy_end_time "4000"
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
          FAROS_RUN_START_TIME="1000" \
          FAROS_RUN_END_TIME="2000" \
          FAROS_DEPLOY="<deploy_source>://<app_name>/QA/<deploy_uid>" \
          FAROS_DEPLOY_APP_PLATFORM="<deploy_app_platform>" \
          FAROS_DEPLOY_ENV_DETAILS="<deploy_env_details>" \
          FAROS_DEPLOY_STATUS="Success" \
          FAROS_DEPLOY_STATUS_DETAILS="<deploy_status_details>" \
          FAROS_DEPLOY_START_TIME="3000" \
          FAROS_DEPLOY_END_TIME="4000" \
          ../faros_event.sh CD
        )
      }
      When call cd_event_test
      The output should include "$CDWithCommitExpectedOutput"
    End

    CDWithPullRequestExpectedOutput='{"type":"CD","version":"0.0.1","origin":"Faros_Script_Event","data":{"deploy":{"id":"<deploy_uid>","environment":"QA","application":"<app_name>","source":"<deploy_source>","status":"Success","applicationPlatform":"<deploy_app_platform>","statusDetails":"<deploy_status_details>","environmentDetails":"<deploy_env_details>","startTime":"1970-01-01T00:00:03Z","endTime":"1970-01-01T00:00:04Z"},"commit":{"sha":"<commit_sha>","repository":"<vcs_repo>","organization":"<vcs_organization>","source":"<vcs_source>","pullRequestNumber":101},"run":{"id":"<build_uid>","pipeline":"<cicd_pipeline>","organization":"<cicd_organization>","source":"<cicd_source>","status":"Success","statusDetails":"<run_status_details>","startTime":"1970-01-01T00:00:01Z","endTime":"1970-01-01T00:00:02Z"}}}'

    It 'constructs correct event when commmit and pull request included using flags'
      cd_event_test() {
        echo $(
          ../faros_event.sh CD -k "<api_key>" \
          --deploy "<deploy_source>://<app_name>/QA/<deploy_uid>" \
          --commit "<vcs_source>://<vcs_organization>/<vcs_repo>/<commit_sha>" \
          --pull_request_number "101" \
          --run "<cicd_source>://<cicd_organization>/<cicd_pipeline>/<build_uid>" \
          --run_status "Success" \
          --run_status_details "<run_status_details>" \
          --run_start_time "1000" \
          --run_end_time "2000" \
          --deploy_app_platform "<deploy_app_platform>" \
          --deploy_env_details "<deploy_env_details>" \
          --deploy_status "Success" \
          --deploy_status_details "<deploy_status_details>" \
          --deploy_start_time "3000" \
          --deploy_end_time "4000"
        )
      }
      When call cd_event_test
      The output should include "$CDWithPullRequestExpectedOutput"
    End

    It 'constructs correct event when commmit and pull request using environment variables'
      cd_event_test() {
        echo $(
          FAROS_API_KEY="<api_key>" \
          FAROS_COMMIT="<vcs_source>://<vcs_organization>/<vcs_repo>/<commit_sha>" \
          FAROS_PULL_REQUEST_NUMBER="101" \
          FAROS_RUN="<cicd_source>://<cicd_organization>/<cicd_pipeline>/<build_uid>" \
          FAROS_RUN_STATUS="Success" \
          FAROS_RUN_STATUS_DETAILS="<run_status_details>" \
          FAROS_RUN_START_TIME="1000" \
          FAROS_RUN_END_TIME="2000" \
          FAROS_DEPLOY="<deploy_source>://<app_name>/QA/<deploy_uid>" \
          FAROS_DEPLOY_APP_PLATFORM="<deploy_app_platform>" \
          FAROS_DEPLOY_ENV_DETAILS="<deploy_env_details>" \
          FAROS_DEPLOY_STATUS="Success" \
          FAROS_DEPLOY_STATUS_DETAILS="<deploy_status_details>" \
          FAROS_DEPLOY_START_TIME="3000" \
          FAROS_DEPLOY_END_TIME="4000" \
          ../faros_event.sh CD
        )
      }
      When call cd_event_test
      The output should include "$CDWithPullRequestExpectedOutput"
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
      The output should include '{"type":"CD","version":"0.0.1","origin":"Faros_Script_Event","data":{"deploy":{"id":"<deploy_uid>","environment":"QA","application":"<app_name>","source":"<deploy_source>","status":"Success"},"artifact":{"id":"<artifact>","repository":"<artifact_repo>","organization":"<artifact_org>","source":"<artifact_source>"}}}'
    End

    It 'Resolves literal Now and converts to iso8601 format'
      Intercept begin
      __begin__() {
        now_as_iso8601() { echo "2022-04-22T18:31:46Z"; }
      }

      When run source ../faros_event.sh CD -k "<api_key>" \
                      --artifact "<artifact_source>://<artifact_org>/<artifact_repo>/<artifact>" \
                      --run "<cicd_source>://<cicd_organization>/<cicd_pipeline>/<build_uid>" \
                      --run_status "Success" \
                      --run_status_details "<run_status_details>" \
                      --run_start_time "Now" \
                      --run_end_time "Now" \
                      --deploy "<deploy_source>://<app_name>/QA/<deploy_uid>" \
                      --deploy_app_platform "<deploy_app_platform>" \
                      --deploy_env_details "<deploy_env_details>" \
                      --deploy_status "Success" \
                      --deploy_status_details "<deploy_status_details>" \
                      --deploy_start_time "Now" \
                      --deploy_end_time "Now"
      The output should include '"startTime":"2022-04-22T18:31:46Z"'
      The output should include '"endTime":"2022-04-22T18:31:46Z"'
    End

    It 'Leaves time unchanged if not Unix millis or Now'
      ci_event_test() {
        echo $(
          ../faros_event.sh CD -k "<api_key>" \
          --artifact "<artifact_source>://<artifact_org>/<artifact_repo>/<artifact>" \
          --run "<cicd_source>://<cicd_organization>/<cicd_pipeline>/<build_uid>" \
          --run_status "Success" \
          --run_status_details "<run_status_details>" \
          --run_start_time "2022-04-22T18:36:01Z" \
          --run_end_time "2022-04-22T18:36:02Z" \
          --deploy "<deploy_source>://<app_name>/QA/<deploy_uid>" \
          --deploy_app_platform "<deploy_app_platform>" \
          --deploy_env_details "<deploy_env_details>" \
          --deploy_status "Success" \
          --deploy_status_details "<deploy_status_details>" \
          --deploy_start_time "2022-04-22T18:36:03Z" \
          --deploy_end_time "2022-04-22T18:36:04Z"
        )
      }
      When call ci_event_test
      The output should include '"startTime":"2022-04-22T18:36:01Z"'
      The output should include '"endTime":"2022-04-22T18:36:02Z"'
      The output should include '"startTime":"2022-04-22T18:36:03Z"'
      The output should include '"endTime":"2022-04-22T18:36:04Z"'
    End
  End

  Describe 'CI event'

    CIWithArtifactExpectedOutput='{"type":"CI","version":"0.0.1","origin":"Faros_Script_Event","data":{"artifact":{"id":"<artifact>","repository":"<artifact_repo>","organization":"<artifact_org>","source":"<artifact_source>"},"commit":{"sha":"<commit_sha>","repository":"<vcs_repo>","organization":"<vcs_organization>","source":"<vcs_source>"},"run":{"id":"<build_uid>","pipeline":"<cicd_pipeline>","organization":"<cicd_organization>","source":"<cicd_source>","status":"Success"}}}'

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

    CIWithoutArtifactExpectedOutput='{"type":"CI","version":"0.0.1","origin":"Faros_Script_Event","data":{"commit":{"sha":"<commit_sha>","repository":"<vcs_repo>","organization":"<vcs_organization>","source":"<vcs_source>"},"run":{"id":"<build_uid>","pipeline":"<cicd_pipeline>","organization":"<cicd_organization>","source":"<cicd_source>","status":"Success","statusDetails":"<run_status_details>","startTime":"1970-01-01T00:00:01Z","endTime":"1970-01-01T00:00:02Z"}}}'

    It 'constructs correct event when artifact excluded using flags'
      ci_event_test() {
        echo $(
          ../faros_event.sh CI -k "<api_key>" \
          --commit "<vcs_source>://<vcs_organization>/<vcs_repo>/<commit_sha>" \
          --run "<cicd_source>://<cicd_organization>/<cicd_pipeline>/<build_uid>" \
          --run_status "Success" \
          --run_status_details "<run_status_details>" \
          --run_start_time "1000" \
          --run_end_time "2000" \
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
          FAROS_RUN_START_TIME="1000" \
          FAROS_RUN_END_TIME="2000" \
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
      The output should include '{"type":"CI","version":"0.0.1","origin":"Faros_Script_Event","data":{"artifact":{"id":"<artifact>","repository":"<artifact_repo>","organization":"<artifact_org>","source":"<artifact_source>"},"commit":{"sha":"<commit_sha>","repository":"<vcs_repo>","organization":"<vcs_organization>","source":"<vcs_source>"}}}'
    End

    CIWithPullRequestExpectedOutput='{"type":"CI","version":"0.0.1","origin":"Faros_Script_Event","data":{"artifact":{"id":"<artifact>","repository":"<artifact_repo>","organization":"<artifact_org>","source":"<artifact_source>"},"commit":{"sha":"<commit_sha>","repository":"<vcs_repo>","organization":"<vcs_organization>","source":"<vcs_source>","pullRequestNumber":101},"run":{"id":"<build_uid>","pipeline":"<cicd_pipeline>","organization":"<cicd_organization>","source":"<cicd_source>","status":"Success"}}}'

    It 'constructs correct event when pull request included'
      ci_event_test() {
        echo $(
          ../faros_event.sh CI -k "<api_key>" \
          --artifact "<artifact_source>://<artifact_org>/<artifact_repo>/<artifact>" \
          --commit "<vcs_source>://<vcs_organization>/<vcs_repo>/<commit_sha>" \
          --pull_request_number "101" \
          --run "<cicd_source>://<cicd_organization>/<cicd_pipeline>/<build_uid>" \
          --run_status "Success"
        )
      }
      When call ci_event_test
      The output should include "$CIWithPullRequestExpectedOutput"
    End

    It 'constructs correct event when pull request included as number input'
      ci_event_test() {
        echo $(
          ../faros_event.sh CI -k "<api_key>" \
          --artifact "<artifact_source>://<artifact_org>/<artifact_repo>/<artifact>" \
          --commit "<vcs_source>://<vcs_organization>/<vcs_repo>/<commit_sha>" \
          --pull_request_number 101 \
          --run "<cicd_source>://<cicd_organization>/<cicd_pipeline>/<build_uid>" \
          --run_status "Success"
        )
      }
      When call ci_event_test
      The output should include "$CIWithPullRequestExpectedOutput"
    End

    It 'constructs correct event when pull request included using environment variables'
      ci_event_test() {
        echo $(
          FAROS_API_KEY="<api_key>" \
          FAROS_ARTIFACT="<artifact_source>://<artifact_org>/<artifact_repo>/<artifact>" \
          FAROS_COMMIT="<vcs_source>://<vcs_organization>/<vcs_repo>/<commit_sha>" \
          FAROS_PULL_REQUEST_NUMBER="101" \
          FAROS_RUN="<cicd_source>://<cicd_organization>/<cicd_pipeline>/<build_uid>" \
          FAROS_RUN_STATUS="Success" \
          ../faros_event.sh CI
        )
      }
      When call ci_event_test
      The output should include "$CIWithPullRequestExpectedOutput"
    End
    
    CIWithBuildStepExpectedOutput='{"type":"CI","version":"0.0.1","origin":"Faros_Script_Event","data":{"run":{"id":"<build_uid>","pipeline":"<cicd_pipeline>","organization":"<cicd_organization>","source":"<cicd_source>","step":{"id":"<run_step_id>","name":"<run_step_name>","type":"<run_step_type>","typeDetails":"<run_step_type_details>","status":"<run_step_status>","statusDetails":"<run_step_status_details>","command":"<run_step_command>","url":"<run_step_url>","startTime":"<run_step_start_time>","endTime":"<run_step_end_time>"}}}}'

    It 'constructs correct event when build step included using flags'
      ci_event_test() {
        echo $(
          ../faros_event.sh CI -k "<api_key>" \
          --run "<cicd_source>://<cicd_organization>/<cicd_pipeline>/<build_uid>" \
          --run_step_id "<run_step_id>" \
          --run_step_name "<run_step_name>" \
          --run_step_type "<run_step_type>" \
          --run_step_type_details "<run_step_type_details>" \
          --run_step_status "<run_step_status>" \
          --run_step_status_details "<run_step_status_details>" \
          --run_step_command "<run_step_command>" \
          --run_step_url "<run_step_url>" \
          --run_step_start_time "<run_step_start_time>" \
          --run_step_end_time "<run_step_end_time>"
        )
      }
      When call ci_event_test
      The output should include "$CIWithBuildStepExpectedOutput"
    End

    It 'constructs correct event when build step included using environment variables'
      ci_event_test() {
        echo $(
          FAROS_RUN="<cicd_source>://<cicd_organization>/<cicd_pipeline>/<build_uid>" \
          FAROS_RUN_STEP_ID="<run_step_id>" \
          FAROS_RUN_STEP_NAME="<run_step_name>" \
          FAROS_RUN_STEP_TYPE="<run_step_type>" \
          FAROS_RUN_STEP_TYPE_DETAILS="<run_step_type_details>" \
          FAROS_RUN_STEP_STATUS="<run_step_status>" \
          FAROS_RUN_STEP_STATUS_DETAILS="<run_step_status_details>" \
          FAROS_RUN_STEP_COMMAND="<run_step_command>" \
          FAROS_RUN_STEP_URL="<run_step_url>" \
          FAROS_RUN_STEP_START_TIME="<run_step_start_time>" \
          FAROS_RUN_STEP_END_TIME="<run_step_end_time>" \
          ../faros_event.sh CI -k "<api_key>"
        )
      }
      When call ci_event_test
      The output should include "$CIWithBuildStepExpectedOutput"
    End
  End

  Describe 'TaskExecution event'

    TestExecutionExpectedOutput='{"type":"TestExecution","version":"0.0.1","origin":"Faros_Script_Event","data":{"test":{"id":"<test_id>","source":"<test_source>","type":"<test_type>","typeDetails":"<test_type_details>","status":"<test_status>","statusDetails":"<test_status_details>","suite":"<test_suite>","tags":"<test_tags>","environments":"<environments>","deviceInfo":{"name":"<device_name>","os":"<device_os>","browser":"<device_browser>","type":"<device_type>"},"testTask":"<test_task>","defectTask":"<defect_task>","suiteTask":"<test_suite_task>","executionTask":"<test_execution_task>","taskSource":"<task_source>","stats":{"failure":1,"success":2,"skipped":3,"unknown":4,"custom":5,"total":15},"startTime":"1970-01-01T00:00:01Z","endTime":"1970-01-01T00:00:02Z"},"commit":{"sha":"<commit_sha>","repository":"<vcs_repo>","organization":"<vcs_organization>","source":"<vcs_source>","branch":"<branch>"}}}'

    It 'constructs correct event when run not included using flags'
      test_execution_event_test() {
          echo $(
            ../faros_event.sh TestExecution -k "<api_key>" \
            --test_id "<test_id>" \
            --test_source "<test_source>" \
            --test_type "<test_type>" \
            --test_type_details "<test_type_details>" \
            --test_status "<test_status>" \
            --test_status_details "<test_status_details>" \
            --test_suite "<test_suite>" \
            --test_stats "failure=1,success=2,skipped=3,unknown=4,custom=5,total=15" \
            --test_tags "<test_tags>" \
            --environments "<environments>" \
            --device_name "<device_name>" \
            --device_os "<device_os>" \
            --device_browser "<device_browser>" \
            --device_type "<device_type>" \
            --test_start_time "1000" \
            --test_end_time "2000" \
            --test_task "<test_task>" \
            --defect_task "<defect_task>" \
            --test_suite_task "<test_suite_task>" \
            --test_execution_task "<test_execution_task>" \
            --task_source "<task_source>" \
            --commit "<vcs_source>://<vcs_organization>/<vcs_repo>/<commit_sha>" \
            --branch "<branch>"
          )
      }
      When call test_execution_event_test
      The output should include $TestExecutionExpectedOutput
    End

    It 'constructs correct event when run not included using environment variables'
      test_execution_event_test() {
          echo $(
            FAROS_API_KEY="<api_key>" \
            FAROS_TEST_ID="<test_id>" \
            FAROS_TEST_SOURCE="<test_source>" \
            FAROS_TEST_TYPE="<test_type>" \
            FAROS_TEST_TYPE_DETAILS="<test_type_details>" \
            FAROS_TEST_STATUS="<test_status>" \
            FAROS_TEST_STATUS_DETAILS="<test_status_details>" \
            FAROS_TEST_SUITE="<test_suite>" \
            FAROS_TEST_STATS="failure=1,success=2,skipped=3,unknown=4,custom=5,total=15" \
            FAROS_TEST_TAGS="<test_tags>" \
            FAROS_ENVIRONMENTS="<environments>" \
            FAROS_DEVICE_NAME="<device_name>" \
            FAROS_DEVICE_OS="<device_os>" \
            FAROS_DEVICE_BROWSER="<device_browser>" \
            FAROS_DEVICE_TYPE="<device_type>" \
            FAROS_TEST_START_TIME="1000" \
            FAROS_TEST_END_TIME="2000" \
            FAROS_TEST_TASK="<test_task>" \
            FAROS_DEFECT_TASK="<defect_task>" \
            FAROS_TEST_SUITE_TASK="<test_suite_task>" \
            FAROS_TEST_EXECUTION_TASK="<test_execution_task>" \
            FAROS_TASK_SOURCE="<task_source>" \
            FAROS_COMMIT="<vcs_source>://<vcs_organization>/<vcs_repo>/<commit_sha>" \
            FAROS_BRANCH="<branch>" \
            ../faros_event.sh TestExecution
          )
      }
      When call test_execution_event_test
      The output should include $TestExecutionExpectedOutput
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
      The output should equal 'Resource URI could not be parsed: bad://uri The URI should be of the form: source://organization/repository/commit_sha Failed.'
    End
  End
End
