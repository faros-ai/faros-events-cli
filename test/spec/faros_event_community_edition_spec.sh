Describe 'faros_event.sh (Community edition)'
  export FAROS_NO_FORMAT=1
  export FAROS_DRY_RUN=1

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
      vcs_pull_request_commit='Calling Hasura rest endpoint vcs_pull_request_commit with payload { "data_pull_request_uid": "1", "data_pull_request_number": 1, "data_commit_sha": "<commit_sha>", "data_commit_repository": "<commit_repository>", "data_commit_organization": "<commit_organization>", "data_commit_source": "<commit_source>", "data_origin": "Faros_Script_Event" }'

      It 'All data present'
        ci_event_test() {
          echo $(
            ../faros_event.sh CI \
            --run "<run_source>://<run_organization>/<run_pipeline>/<run_id>" \
            --commit "<commit_source>://<commit_organization>/<commit_repository>/<commit_sha>" \
            --pull_request_number 1 \
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
        The output should include "$vcs_pull_request_commit"
      End
      vcs_pull_request_commit='Calling Hasura rest endpoint vcs_pull_request_commit with payload { "data_pull_request_uid": "1", "data_pull_request_number": 1, "data_commit_sha": "<commit_sha>", "data_commit_repository": "<commit_repository>", "data_commit_organization": "<commit_organization>", "data_commit_source": "<commit_source>", "data_origin": "my_origin" }'

      It 'Uses origin from flag'
        ci_event_test() {
          echo $(
            ../faros_event.sh CI \
            --run "<run_source>://<run_organization>/<run_pipeline>/<run_id>" \
            --commit "<commit_source>://<commit_organization>/<commit_repository>/<commit_sha>" \
            --pull_request_number 1 \
            --artifact "<artifact_source>://<artifact_organization>/<artifact_repository>/<artifact_id>" \
            --run_status "Success" \
            --run_status_details "Some extra details" \
            --run_start_time "1000" \
            --run_end_time "2000" \
            --origin my_origin \
            --community_edition
          )
        }
        When call ci_event_test
        The output should include "$vcs_pull_request_commit"
      End
      It 'Resolves literal Now and converts to iso8601 format'
        Intercept begin
        __begin__() {
          now_as_iso8601() { echo "2022-04-22T18:31:46Z"; }
        }

        When run source ../faros_event.sh CI \
                        --run "<run_source>://<run_organization>/<run_pipeline>/<run_id>" \
                        --commit "<commit_source>://<commit_organization>/<commit_repository>/<commit_sha>" \
                        --artifact "<artifact_source>://<artifact_organization>/<artifact_repository>/<artifact_id>" \
                        --run_status "Success" \
                        --run_status_details "Some extra details" \
                        --run_start_time "Now" \
                        --run_end_time "2000" \
                        --community_edition
        The output should include '"run_start_time": "2022-04-22T18:31:46Z"'
      End
      It 'Leaves time unchanged if not Unix millis or Now'
        ci_event_test() {
          echo $(
            ../faros_event.sh CI \
            --run "<run_source>://<run_organization>/<run_pipeline>/<run_id>" \
            --commit "<commit_source>://<commit_organization>/<commit_repository>/<commit_sha>" \
            --artifact "<artifact_source>://<artifact_organization>/<artifact_repository>/<artifact_id>" \
            --run_status "Success" \
            --run_status_details "Some extra details" \
            --run_start_time "2022-04-22T18:36:28Z" \
            --run_end_time "2000" \
            --community_edition
          )
        }
        When call ci_event_test
        The output should include '"run_start_time": "2022-04-22T18:36:28Z"'
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
            --run_start_time "1000" \
            --run_end_time "2000" \
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
    vcs_pull_request_commit='Calling Hasura rest endpoint vcs_pull_request_commit with payload { "data_pull_request_uid": "1", "data_pull_request_number": 1, "data_commit_sha": "<commit_sha>", "data_commit_repository": "<commit_repository>", "data_commit_organization": "<commit_organization>", "data_commit_source": "<commit_source>", "data_origin": "Faros_Script_Event" }'

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
    It 'Resolves literal Now and converts to iso8601 format'
      Intercept begin
      __begin__() {
        now_as_iso8601() { echo "2022-04-22T18:31:46Z"; }
      }

      When run source ../faros_event.sh CD \
                      --run "<run_source>://<run_organization>/<run_pipeline>/<run_id>" \
                      --artifact "<artifact_source>://<artifact_organization>/<artifact_repository>/<artifact_id>" \
                      --run_status "Success" \
                      --run_status_details "Some extra details" \
                      --run_start_time "1000" \
                      --run_end_time "2000" \
                      --deploy "<deploy_source>://<application>/<environment>/<deploy_id>" \
                      --deploy_status "Success" \
                      --deploy_start_time "Now" \
                      --deploy_end_time "4000" \
                      --community_edition
      The output should include '"deploy_start_time": "2022-04-22T18:31:46Z"'
    End
    It 'Leaves time unchanged if not Unix millis or Now'
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
          --deploy_start_time "2022-04-22T18:31:46Z" \
          --deploy_end_time "4000" \
          --community_edition
        )
      }
      When call cd_event_test
      The output should include '"deploy_start_time": "2022-04-22T18:31:46Z"'
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
    It 'Creates PR/commit association if PR number and commit data present'
      cd_event_test() {
        echo $(
          ../faros_event.sh CD \
          --commit "<commit_source>://<commit_organization>/<commit_repository>/<commit_sha>" \
          --pull_request_number 1 \
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
      The output should include "$vcs_pull_request_commit"
    End
    It 'Fails with malformed URI responds with parsing error'
      bad_input_test() {
        echo $(
          ../faros_event.sh CI -k "<key>" \
          --commit "$1" \
          --community_edition
        )
      }
      When call bad_input_test "bad://uri"
      The output should equal 'Resource URI could not be parsed: [bad://uri] The URI should be of the form: source://organization/repository/commit_sha Failed.'
    End
  End
End
