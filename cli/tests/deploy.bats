#!/usr/bin/env bats

TEST_DIR="$(realpath "$(dirname "$BATS_TEST_FILENAME")")"
source "$TEST_DIR/mocks"

docker() {
    if [[ "$1" == "image" ]]; then
        shift
        local image_name="$2"
        local has_image="$(get_mock_state "has_image_$image_name")"
        log_mock_call "docker_image" "$@"
        if [[ "$has_image" != "true" ]]; then
            return 1
        fi
    elif [[ "$1" == "pull" ]]; then
        shift
        log_mock_call "docker_pull" "$@"
        set_mock_state "has_image_$1" "true"
    elif [[ "$1" == "run" ]]; then
        shift
        log_mock_call "docker_run" "$@"
        local image_name="${@: -1}"
        local has_image=$(get_mock_state "has_image_$image_name")
        if [[ -z "$has_image" ]]; then
            echo "No image available for $image_name"
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

setup_local_env() {
    export GITHUB_NAMESPACE="test-namespace"
}

teardown() {
    teardown_mocks
}

@test "deploys locally" {
    setup_local_env
    run ./deploy --local
    assert_success
    assert_output --partial \
        "Folio application is running on http://localhost:3000"
}

@test "deploys local Docker image to local container" {
    setup_local_env
    set_mock_state "has_image_folio:latest" "true"
    run ./deploy --local
    assert_success
    assert_mock_called_once "docker_image"
    assert_mock_called_with "docker_image" "inspect" "folio:latest"
    assert_mock_called_once "docker_run"
    assert_mock_called_with "docker_run" \
        "-d" \
        "--name" "folio" \
        "-p" "3000:3000" \
        "folio:latest"
}

@test "deploys remote Docker image to local container requires namespace" {
    run ./deploy --local
    assert_failure
    assert_output --partial \
        "Error: GitHub namespace is required to retrieve image."
    assert_mock_not_called "docker_pull"
}

@test "deploys remote Docker image to local container" {
    setup_local_env
    set_mock_state "has_image_folio:latest" "false"
    run ./deploy --local
    assert_success
    assert_mock_called_once "docker_pull"
    assert_mock_called_with "docker_pull" \
        "ghcr.io/$GITHUB_NAMESPACE/folio:latest"
    assert_mock_called_once "docker_run"
    assert_mock_called_with "docker_run" \
        "-d" \
        "--name" "folio" \
        "-p" "3000:3000" \
        "ghcr.io/$GITHUB_NAMESPACE/folio:latest"
}
