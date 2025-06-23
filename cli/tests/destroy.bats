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

terraform() {
    if [[ "$1" == "destroy" ]]; then
        shift
        log_mock_call "terraform_destroy" "$@"
    else
        log_mock_call "terraform" "$@"
    fi
}
export -f terraform

setup() {
    bats_load_library bats-support
    bats_load_library bats-assert
    setup_mocks
}

setup_remote_env() {
    export GITHUB_NAMESPACE="test-namespace"
    export APPLICATION_DOMAIN="example.test"
    export CF_DNS_ZONE="abc123"
    export PUBLIC_KEY_FILE="/path/to/public_key.pub"
    export CF_TOKEN="cf_token"
    export DO_TOKEN="do_token"
    export SSH_PORT="2222"
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

@test "destroys remotely" {
    setup_remote_env
    run ./destroy <<< "yes"
    assert_success
    assert_output --partial "Production environment destroyed successfully."
}

@test "requires namespace for remote destroy" {
    setup_remote_env
    unset GITHUB_NAMESPACE
    run ./destroy <<< "yes"
    assert_failure
    assert_output --partial \
        "Error: GitHub namespace required to target remote environment."
}

@test "requires domain for remote destroy" {
    setup_remote_env
    unset APPLICATION_DOMAIN
    run ./destroy <<< "yes"
    assert_failure
    assert_output --partial \
        "Error: Domain required to target remote environment."
}

@test "requires Cloudflare DNS zone for remote destroy" {
    setup_remote_env
    unset CF_DNS_ZONE
    run ./destroy <<< "yes"
    assert_failure
    assert_output --partial \
        "Error: Cloudflare DNS zone required to target remote environment."
}

@test "requires public key file for remote destroy" {
    setup_remote_env
    unset PUBLIC_KEY_FILE
    run ./destroy <<< "yes"
    assert_failure
    assert_output --partial \
        "Error: Public key file required to target remote environment."
}

@test "requires Cloudflare token for remote destroy" {
    setup_remote_env
    unset CF_TOKEN
    run ./destroy <<< "yes"
    assert_failure
    assert_output --partial \
        "Error: Cloudflare token required to target remote environment."
}

@test "requires DigitalOcean token for remote destroy" {
    setup_remote_env
    unset DO_TOKEN
    run ./destroy <<< "yes"
    assert_failure
    assert_output --partial \
        "Error: DigitalOcean token required to target remote environment."
}

@test "accepts as option" {
    setup_remote_env
    run ./destroy <<< "yes" --namespace test-namespace
    assert_success
    assert_output --partial "Production environment destroyed successfully."
}

@test "accepts domain as option" {
    setup_remote_env
    run ./destroy <<< "yes" --domain example.test
    assert_success
    assert_output --partial "Production environment destroyed successfully."
}

@test "accepts Cloudflare DNS zone as option" {
    setup_remote_env
    run ./destroy <<< "yes" --dns-zone abc123
    assert_success
    assert_output --partial "Production environment destroyed successfully."
}

@test "accepts public key file as option" {
    setup_remote_env
    run ./destroy <<< "yes" --public-key /path/to/public_key.pub
    assert_success
    assert_output --partial "Production environment destroyed successfully."
}

@test "accepts Cloudflare token as option" {
    setup_remote_env
    run ./destroy <<< "yes" --cf-token cf_token
    assert_success
    assert_output --partial "Production environment destroyed successfully."
}

@test "accepts DigitalOcean token as option" {
    setup_remote_env
    run ./destroy <<< "yes" --do-token do_token
    assert_success
    assert_output --partial "Production environment destroyed successfully."
}
