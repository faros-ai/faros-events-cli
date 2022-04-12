Describe 'faros_event.sh'
  export FAROS_DRY_RUN=1
  export FAROS_NO_FORMAT=1
  Describe 'CD event'
    CDWithArtifactExpectedOutput='{"type":"CD","version":"0.0.1","origin":"Faros_Script_Event","data":{"deploy":{"id":"<deploy_uid>","environment":"QA","application":"<app_name>","source":"<deploy_source>","status":"Success","applicationPlatform":"<deploy_app_platform>","statusDetails":"<deploy_status_details>","environmentDetails":"<deploy_env_details>","startTime":"3","endTime":"4"},"artifact":{"id":"<artifact>","repository":"<artifact_repo>","organization":"<artifact_org>","source":"<artifact_source>"},"run":{"id":"<build_uid>","pipeline":"<cicd_pipeline>","organization":"<cicd_organization>","source":"<cicd_source>","status":"Success","statusDetails":"<run_status_details>","startTime":"1","endTime":"2"}}}'

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

    CDWithCommitExpectedOutput='{"type":"CD","version":"0.0.1","origin":"Faros_Script_Event","data":{"deploy":{"id":"<deploy_uid>","environment":"QA","application":"<app_name>","source":"<deploy_source>","status":"Success","applicationPlatform":"<deploy_app_platform>","statusDetails":"<deploy_status_details>","environmentDetails":"<deploy_env_details>","startTime":"3","endTime":"4"},"commit":{"sha":"<commit_sha>","repository":"<vcs_repo>","organization":"<vcs_organization>","source":"<vcs_source>"},"run":{"id":"<build_uid>","pipeline":"<cicd_pipeline>","organization":"<cicd_organization>","source":"<cicd_source>","status":"Success","statusDetails":"<run_status_details>","startTime":"1","endTime":"2"}}}'

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

    CDWithPullRequestExpectedOutput='{"type":"CD","version":"0.0.1","origin":"Faros_Script_Event","data":{"deploy":{"id":"<deploy_uid>","environment":"QA","application":"<app_name>","source":"<deploy_source>","status":"Success","applicationPlatform":"<deploy_app_platform>","statusDetails":"<deploy_status_details>","environmentDetails":"<deploy_env_details>","startTime":"3","endTime":"4"},"commit":{"sha":"<commit_sha>","repository":"<vcs_repo>","organization":"<vcs_organization>","source":"<vcs_source>","pullRequestNumber":101},"run":{"id":"<build_uid>","pipeline":"<cicd_pipeline>","organization":"<cicd_organization>","source":"<cicd_source>","status":"Success","statusDetails":"<run_status_details>","startTime":"1","endTime":"2"}}}'

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

    CIWithoutArtifactExpectedOutput='{"type":"CI","version":"0.0.1","origin":"Faros_Script_Event","data":{"commit":{"sha":"<commit_sha>","repository":"<vcs_repo>","organization":"<vcs_organization>","source":"<vcs_source>"},"run":{"id":"<build_uid>","pipeline":"<cicd_pipeline>","organization":"<cicd_organization>","source":"<cicd_source>","status":"Success","statusDetails":"<run_status_details>","startTime":"1","endTime":"2"}}}'

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
  Describe 'Community edition CI event'
    cicd_organization_from_run='Calling Hasura rest endpoint cicd_organization_from_run with payload { "data_run_organization": "<run_organization>", "data_run_source": "<run_source>", "data_origin": "Faros_Script_Event" }'
    cicd_pipeline='Calling Hasura rest endpoint cicd_pipeline with payload { "data_run_pipeline": "<run_pipeline>", "data_run_organization": "<run_organization>", "data_run_source": "<run_source>", "data_origin": "Faros_Script_Event" }'
    cicd_build_with_start_end='Calling Hasura rest endpoint cicd_build_with_start_end with payload { "run_status": { "category": "Success", "detail": "Some extra details" }, "run_start_time": "1970-01-01T00:00:01Z", "run_end_time": "1970-01-01T00:00:02Z", "data_run_id": "<run_id>", "data_run_pipeline": "<run_pipeline>", "data_run_organization": "<run_organization>", "data_run_source": "<run_source>", "data_origin": "Faros_Script_Event" }'
    cicd_artifact_with_build='Calling Hasura rest endpoint cicd_artifact_with_build with payload { "data_artifact_id": "<artifact_id>", "data_artifact_repository": "<artifact_repository>", "data_artifact_organization": "<artifact_organization>", "data_artifact_source": "<artifact_source>", "data_run_id": "<run_id>", "data_run_pipeline": "<run_pipeline>", "data_run_organization": "<run_organization>", "data_run_source": "<run_source>", "data_origin": "Faros_Script_Event" }'
    cicd_organization='Calling Hasura rest endpoint cicd_organization with payload { "data_artifact_organization": "<artifact_organization>", "data_artifact_source": "<artifact_source>", "data_origin": "Faros_Script_Event" }'
    cicd_repository='Calling Hasura rest endpoint cicd_repository with payload { "data_artifact_repository": "<artifact_repository>", "data_artifact_organization": "<artifact_organization>", "data_artifact_source": "<artifact_source>", "data_origin": "Faros_Script_Event" }'
    cicd_artifact_commit_association='Calling Hasura rest endpoint cicd_artifact_commit_association with payload { "data_artifact_id": "<artifact_id>", "data_artifact_repository": "<artifact_repository>", "data_artifact_organization": "<artifact_organization>", "data_artifact_source": "<artifact_source>", "data_commit_sha": "<commit_sha>", "data_commit_repository": "<commit_repository>", "data_commit_organization": "<commit_organization>", "data_commit_source": "<commit_source>", "data_origin": "Faros_Script_Event" }'
    cicd_artifact='Calling Hasura rest endpoint cicd_artifact with payload { "data_artifact_id": "<artifact_id>", "data_artifact_repository": "<artifact_repository>", "data_artifact_organization": "<artifact_organization>", "data_artifact_source": "<artifact_source>", "data_origin": "Faros_Script_Event" }'
    cicd_build='Calling Hasura rest endpoint cicd_build with payload { "run_status": { "category": "Success", "detail": "Some extra details" }, "data_run_id": "<run_id>", "data_run_pipeline": "<run_pipeline>", "data_run_organization": "<run_organization>", "data_run_source": "<run_source>", "data_origin": "Faros_Script_Event" }'

    It 'All data present'
      ci_event_test() {
        echo $(
          ../faros_event.sh CI \
          --run "<run_source>://<run_organization>/<run_pipeline>/<run_id>" \
          --commit "<commit_source>://<commit_organization>/<commit_repository>/<commit_sha>" \
          --artifact "<artifact_source>://<artifact_organization>/<artifact_repository>/<artifact_id>" \
          --run_status "Success" \
          --run_status_details "Some extra details" \
          --run_start_time "1000" \
          --run_end_time "2000" \
          --community_edition
        )
      }
      When call ci_event_test
      The output should include "$cicd_organization_from_run"
      The output should include "$cicd_pipeline"
      The output should include "$cicd_build_with_start_end"
      The output should include "$cicd_artifact_with_build"
      The output should include "$cicd_organization"
      The output should include "$cicd_repository"
      The output should include "$cicd_artifact_commit_association"
    End
    It 'No run data'
      ci_event_test() {
        echo $(
          ../faros_event.sh CI \
          --commit "<commit_source>://<commit_organization>/<commit_repository>/<commit_sha>" \
          --artifact "<artifact_source>://<artifact_organization>/<artifact_repository>/<artifact_id>" \
          --community_edition
        )
      }
      When call ci_event_test
      The output should include "$cicd_organization"
      The output should include "$cicd_repository"
      The output should include "$cicd_artifact_commit_association"
      The output should include "$cicd_artifact"
    End
    It 'No run start/end time'
      ci_event_test() {
        echo $(
          ../faros_event.sh CI \
          --run "<run_source>://<run_organization>/<run_pipeline>/<run_id>" \
          --commit "<commit_source>://<commit_organization>/<commit_repository>/<commit_sha>" \
          --artifact "<artifact_source>://<artifact_organization>/<artifact_repository>/<artifact_id>" \
          --run_status "Success" \
          --run_status_details "Some extra details" \
          --community_edition
        )
      }
      When call ci_event_test
      The output should include "$cicd_organization_from_run"
      The output should include "$cicd_pipeline"
      The output should include "$cicd_build"
      The output should include "$cicd_artifact_with_build"
      The output should include "$cicd_organization"
      The output should include "$cicd_repository"
      The output should include "$cicd_artifact_commit_association"
    End
It 'All data present and skip_saving_run'
      ci_event_test() {
        echo $(
          ../faros_event.sh CI \
          --run "<run_source>://<run_organization>/<run_pipeline>/<run_id>" \
          --commit "<commit_source>://<commit_organization>/<commit_repository>/<commit_sha>" \
          --artifact "<artifact_source>://<artifact_organization>/<artifact_repository>/<artifact_id>" \
          --run_status "Success" \
          --run_status_details "Some extra details" \
          --run_start_time "1" \
          --run_end_time "2" \
          --community_edition \
          --skip_saving_run
        )
      }
      When call ci_event_test
      The output should include "$cicd_artifact_with_build"
      The output should include "$cicd_organization"
      The output should include "$cicd_repository"
      The output should include "$cicd_artifact_commit_association"
    End
  End
  Describe 'Community edition CD event'
    compute_application='Calling Hasura rest endpoint compute_application with payload { "name": "<application>", "platform": "", "uid": "{"name":"<application>","platform":""}", "data_origin": "Faros_Script_Event" }'
    cicd_artifact_deployment='Calling Hasura rest endpoint cicd_artifact_deployment with payload { "data_deploy_id": "<deploy_id>", "data_deploy_source": "<deploy_source>", "data_artifact_id": "<artifact_id>", "data_artifact_repository": "<artifact_repository>", "data_artifact_organization": "<artifact_organization>", "data_artifact_source": "<artifact_source>", "data_origin": "Faros_Script_Event" }'
    cicd_build_with_start_end='Calling Hasura rest endpoint cicd_build_with_start_end with payload { "run_status": { "category": "Success", "detail": "Some extra details" }, "run_start_time": "1970-01-01T00:00:01Z", "run_end_time": "1970-01-01T00:00:02Z", "data_run_id": "<run_id>", "data_run_pipeline": "<run_pipeline>", "data_run_organization": "<run_organization>", "data_run_source": "<run_source>", "data_origin": "Faros_Script_Event" }'
    cicd_pipeline='Calling Hasura rest endpoint cicd_pipeline with payload { "data_run_pipeline": "<run_pipeline>", "data_run_organization": "<run_organization>", "data_run_source": "<run_source>", "data_origin": "Faros_Script_Event" }'
    cicd_organization_from_run='Calling Hasura rest endpoint cicd_organization_from_run with payload { "data_run_organization": "<run_organization>", "data_run_source": "<run_source>", "data_origin": "Faros_Script_Event" }'
    cicd_deployment_with_build='Calling Hasura rest endpoint cicd_deployment_with_build with payload { "data_deploy_id": "<deploy_id>", "data_deploy_source": "<deploy_source>", "status": { "category": "Success", "detail": "" }, "env": { "category": "<environment>", "detail": "" }, "compute_Application": "{"name":"<application>","platform":""}", "deploy_start_time": "1970-01-01T00:00:03Z", "deploy_end_time": "1970-01-01T00:00:04Z", "data_run_id": "<run_id>", "data_run_pipeline": "<run_pipeline>", "data_run_organization": "<run_organization>", "data_run_source": "<run_source>", "data_origin": "Faros_Script_Event" }'
    cicd_deployment='Calling Hasura rest endpoint cicd_deployment with payload { "data_deploy_id": "<deploy_id>", "data_deploy_source": "<deploy_source>", "status": { "category": "Success", "detail": "" }, "env": { "category": "<environment>", "detail": "" }, "compute_Application": "{"name":"<application>","platform":""}", "deploy_start_time": "1970-01-01T00:00:03Z", "deploy_end_time": "1970-01-01T00:00:04Z", "data_origin": "Faros_Script_Event" }'
    cicd_artifact_from_commit_info='Calling Hasura rest endpoint cicd_artifact_with_build with payload { "data_artifact_id": "<commit_sha>", "data_artifact_repository": "<commit_repository>", "data_artifact_organization": "<commit_organization>", "data_artifact_source": "<commit_source>", "data_run_id": "<run_id>", "data_run_pipeline": "<run_pipeline>", "data_run_organization": "<run_organization>", "data_run_source": "<run_source>", "data_origin": "Faros_Script_Event" }'
    cicd_artifact_commit_association='Calling Hasura rest endpoint cicd_artifact_commit_association with payload { "data_artifact_id": "<commit_sha>", "data_artifact_repository": "<commit_repository>", "data_artifact_organization": "<commit_organization>", "data_artifact_source": "<commit_source>", "data_commit_sha": "<commit_sha>", "data_commit_repository": "<commit_repository>", "data_commit_organization": "<commit_organization>", "data_commit_source": "<commit_source>", "data_origin": "Faros_Script_Event" }'
    cicd_artifact_deployment_from_commit='Calling Hasura rest endpoint cicd_artifact_deployment with payload { "data_deploy_id": "<deploy_id>", "data_deploy_source": "<deploy_source>", "data_artifact_id": "<commit_sha>", "data_artifact_repository": "<commit_repository>", "data_artifact_organization": "<commit_organization>", "data_artifact_source": "<commit_source>", "data_origin": "Faros_Script_Event" }'

    It 'All data present'
      cd_event_test() {
        echo $(
          ../faros_event.sh CD \
          --run "<run_source>://<run_organization>/<run_pipeline>/<run_id>" \
          --artifact "<artifact_source>://<artifact_organization>/<artifact_repository>/<artifact_id>" \
          --run_status "Success" \
          --run_status_details "Some extra details" \
          --run_start_time "1000" \
          --run_end_time "2000" \
          --deploy "<deploy_source>://<application>/<environment>/<deploy_id>" \
          --deploy_status "Success" \
          --deploy_start_time "3000" \
          --deploy_end_time "4000" \
          --community_edition
        )
      }
      When call cd_event_test
      The output should include "$compute_application"
      The output should include "$cicd_artifact_deployment"
      The output should include "$cicd_build_with_start_end"
      The output should include "$cicd_pipeline"
      The output should include "$cicd_organization_from_run"
      The output should include "$cicd_deployment_with_build"
    End
    It 'No run data'
      cd_event_test() {
        echo $(
          ../faros_event.sh CD \
          --artifact "<artifact_source>://<artifact_organization>/<artifact_repository>/<artifact_id>" \
          --deploy "<deploy_source>://<application>/<environment>/<deploy_id>" \
          --deploy_status "Success" \
          --deploy_start_time "3000" \
          --deploy_end_time "4000" \
          --community_edition
        )
      }
      When call cd_event_test
      The output should include "$compute_application"
      The output should include "$cicd_artifact_deployment"
      The output should include "$cicd_deployment"
    End
    It 'All data present and skip_saving_run'
      cd_event_test() {
        echo $(
          ../faros_event.sh CD \
          --run "<run_source>://<run_organization>/<run_pipeline>/<run_id>" \
          --artifact "<artifact_source>://<artifact_organization>/<artifact_repository>/<artifact_id>" \
          --run_status "Success" \
          --run_status_details "Some extra details" \
          --run_start_time "1000" \
          --run_end_time "2000" \
          --deploy "<deploy_source>://<application>/<environment>/<deploy_id>" \
          --deploy_status "Success" \
          --deploy_start_time "3000" \
          --deploy_end_time "4000" \
          --skip_saving_run \
          --community_edition
        )
      }
      When call cd_event_test
      The output should include "$compute_application"
      The output should include "$cicd_artifact_deployment"
      The output should include "$cicd_deployment_with_build"
    End
    It 'Creates dummy cicd_Artifact from commit info'
      cd_event_test() {
        echo $(
          ../faros_event.sh CD \
          --commit "<commit_source>://<commit_organization>/<commit_repository>/<commit_sha>" \
          --run "<run_source>://<run_organization>/<run_pipeline>/<run_id>" \
          --run_status "Success" \
          --run_status_details "Some extra details" \
          --run_start_time "1000" \
          --run_end_time "2000" \
          --deploy "<deploy_source>://<application>/<environment>/<deploy_id>" \
          --deploy_status "Success" \
          --deploy_start_time "3000" \
          --deploy_end_time "4000" \
          --community_edition
        )
      }
      When call cd_event_test
      The output should include "$compute_application"
      The output should include "$cicd_artifact_deployment_from_commit"
      The output should include "$cicd_deployment_with_build"
      The output should include "$cicd_artifact_commit_association"
      The output should include "$cicd_artifact_from_commit_info"
    End
  End
End
