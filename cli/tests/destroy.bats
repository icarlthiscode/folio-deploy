#!/usr/bin/env bats

TEST_DIR="$(realpath "$(dirname "$BATS_TEST_FILENAME")")"
source "$TEST_DIR/mocks"

docker() {
    if [[ "$1" == "ps" ]]; then
        shift
        log_mock_call "docker_ps" "$@"
        if [[ $(get_mock_state "folio_container_running") != "false" ]]; then
            echo "123456789abc"
        fi
    elif [[ "$1" == "stop" ]]; then
        shift
        log_mock_call "docker_stop" "$@"
    elif [[ "$1" == "rm" ]]; then
        shift
        log_mock_call "docker_rm" "$@"
        local container_stopped=$(get_mock_call_args_matching \
            "docker_stop" "$@")
        if [[ -z "$container_stopped" ]]; then
            return 1
        fi
    else
        log_mock_call "docker" "$@"
    fi
}
export -f docker

setup() {
    bats_load_library bats-support
    bats_load_library bats-assert
    setup_mocks
}

teardown() {
    teardown_mocks
}

@test "destroys locally" {
    run ./destroy --local
    assert_success
    assert_output --partial "Folio container stopped and removed successfully."
}

@test "skips if no local container" {
    set_mock_state "folio_container_running" "false"
    run ./destroy --local
    assert_success
    assert_mock_not_called "docker_stop"
    assert_mock_not_called "docker_rm"
    assert_output --partial "No running Folio container found."
}

@test "stops and removes local container" {
    run ./destroy --local
    assert_success
    assert_mock_called_once "docker_stop"
    assert_mock_called_with "docker_stop" "folio"
    assert_mock_called_once "docker_rm"
    assert_mock_called_with "docker_rm" "folio"
}
