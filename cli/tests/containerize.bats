#!/usr/bin/env bats

TEST_DIR="$(realpath "$(dirname "$BATS_TEST_FILENAME")")"
source "$TEST_DIR/mocks"

VERSION=$(grep '"version"' folio/package.json \
    | head -1 \
    | sed -E 's/.*"version": *"([^"]+)".*/\1/')

npm() {
    if [[ "$1" == "install" ]]; then
        shift
        echo "npm install $*"
        log_mock_call "npm_install" "$@"
    elif [[ "$1" == "run" && "$2" == "build" ]]; then
        shift 2
        log_mock_call "npm_build" "$@"
        if [[ "$(get_mock_call_count "npm_install")" -gt 0 ]]; then
            set_mock_state "install_before_build" "true"
        else
            set_mock_state "install_before_build" "false"
        fi
    else
        log_mock_call "npm" "$@"
    fi
}
export -f npm

docker() {
    local image_name
    local call_with_tag
    if [[ "$1" == "build" ]]; then
        shift
        log_mock_call "docker_build" "$@"
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

@test "builds container image" {
    unset GITHUB_NAMESPACE
    run ./containerize
    assert_success
}

@test "installs npm dependencies" {
    run ./containerize
    assert_success
    assert_mock_called_once "npm_install"
    assert_mock_called_in_dir "npm_install" "folio"
}

@test "builds SvelteKit application" {
    run ./containerize
    assert_success
    assert_mock_called_once "npm_build"
    assert_mock_called_in_dir "npm_install" "folio"
}

@test "installs npm dependencies before building" {
    run ./containerize
    assert_success
    assert_mock_state_equal "install_before_build" "true"
}

@test "builds local container image" {
    run ./containerize
    assert_success
    assert_mock_called_once "docker_build"
    assert_mock_called_with "docker_build" \
        "-t" "folio:latest"
}
