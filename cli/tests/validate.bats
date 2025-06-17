#!/usr/bin/env bats

TEST_DIR="$(realpath "$(dirname "$BATS_TEST_FILENAME")")"
source "$TEST_DIR/mocks"

npm() {
    if [[ "$1" == "install" ]]; then
        shift
        echo "npm install $*"
        log_mock_call "npm_install" "$@"
    elif [[ "$1" == "run" && "$2" == "test" ]]; then
        log_mock_call "npm_test" "$@"
        if [[ "$(get_mock_call_count "npm_install")" -gt 0 ]]; then
            set_mock_state "install_before_test" "true"
        else
            set_mock_state "install_before_test" "false"
        fi
    else
        log_mock_call "npm" "$@"
    fi
}
export -f npm

setup() {
    bats_load_library bats-support
    bats_load_library bats-assert
    setup_mocks
}

teardown() {
    teardown_mocks
}

@test "installs npm dependencies" {
    run ./validate
    assert_success
    assert_mock_called_once "npm_install"
    assert_mock_called_in_dir "npm_install" "folio"
}

@test "installs npm dependencies before testing" {
    run ./validate
    assert_mock_state_equal "install_before_test" "true"
}

@test "runs tests" {
    run ./validate
    assert_success
    assert_mock_called_once "npm_test"
    assert_mock_called_in_dir "npm_install" "folio"
}
