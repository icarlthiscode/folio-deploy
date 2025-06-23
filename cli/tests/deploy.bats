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

terraform() {
    if [[ "$1" == "init" ]]; then
        shift
        log_mock_call "terraform_init" "$@"
    elif [[ "$1" == "plan" ]]; then
        shift
        log_mock_call "terraform_plan" "$@"
    elif [[ "$1" == "apply" ]]; then
        shift
        log_mock_call "terraform_apply" "$@"
        if [[ "$(get_mock_call_count "terraform_plan")" -gt 0 ]]; then
            set_mock_state "plan_before_apply" "true"
        else
            set_mock_state "plan_before_apply" "false"
        fi
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

setup_local_env() {
    export GITHUB_NAMESPACE="test-namespace"
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

@test "deploys remotely" {
    export ENVIRONMENT="production"
    setup_remote_env
    run ./deploy <<< "y"
    assert_success
    assert_output --partial "Deployment of $ENVIRONMENT completed successfully."
}

@test "requires namespace to deploy remotely" {
    setup_remote_env
    unset GITHUB_NAMESPACE
    run ./deploy <<< "y"
    assert_failure
    assert_output --partial \
        "Error: GitHub namespace required to target remote environment."
}

@test "requires domain to deploy remotely" {
    setup_remote_env
    unset APPLICATION_DOMAIN
    run ./deploy <<< "y"
    assert_failure
    assert_output --partial \
        "Error: Domain required to target remote environment."
}

@test "requires Cloudflare DNS zone to deploy remotely" {
    setup_remote_env
    unset CF_DNS_ZONE
    run ./deploy <<< "y"
    assert_failure
    assert_output --partial \
        "Error: Cloudflare DNS zone required to target remote environment."
}

@test "requires public key file to deploy remotely" {
    setup_remote_env
    unset PUBLIC_KEY_FILE
    run ./deploy <<< "y"
    assert_failure
    assert_output --partial \
        "Error: Public key file required to target remote environment."
}

@test "requires Cloudflare API token to deploy remotely" {
    setup_remote_env
    unset CF_TOKEN
    run ./deploy <<< "y"
    assert_failure
    assert_output --partial \
        "Error: Cloudflare token required to target remote environment."
}

@test "requires DigitalOcean API token to deploy remotely" {
    setup_remote_env
    unset DO_TOKEN
    run ./deploy <<< "y"
    assert_failure
    assert_output --partial \
        "Error: DigitalOcean token required to target remote environment."
}

@test "accepts namespace as option" {
    setup_remote_env
    unset GITHUB_NAMESPACE
    run ./deploy <<< "y" --namespace "test-namespace"
    assert_success
    assert_output --partial "Deployment of $ENVIRONMENT completed successfully."
}

@test "accepts domain as option" {
    setup_remote_env
    unset APPLICATION_DOMAIN
    run ./deploy <<< "y" --domain "example.com"
    assert_success
    assert_output --partial "Deployment of $ENVIRONMENT completed successfully."
}

@test "accepts Cloudflare DNS zone as option" {
    setup_remote_env
    unset CF_DNS_ZONE
    run ./deploy <<< "y" --dns-zone "example.com"
    assert_success
    assert_output --partial "Deployment of $ENVIRONMENT completed successfully."
}

@test "accepts public key file as option" {
    setup_remote_env
    unset PUBLIC_KEY_FILE
    run ./deploy <<< "y" --public-key "/path/to/public_key.pub"
    assert_success
    assert_output --partial "Deployment of $ENVIRONMENT completed successfully."
}

@test "accepts Cloudflare API token as option" {
    setup_remote_env
    unset CF_TOKEN
    run ./deploy <<< "y" --cf-token "cf_token"
    assert_success
    assert_output --partial "Deployment of $ENVIRONMENT completed successfully."
}

@test "accepts DigitalOcean API token as option" {
    setup_remote_env
    unset DO_TOKEN
    run ./deploy <<< "y" --do-token "do_token"
    assert_success
    assert_output --partial "Deployment of $ENVIRONMENT completed successfully."
}

@test "initializes Terraform" {
    setup_remote_env
    run ./deploy <<< "y"
    assert_success
    assert_mock_called_once "terraform_init"
}

@test "creates Terraform plan from environment variables" {
    setup_remote_env
    run ./deploy <<< "y"
    assert_success
    assert_mock_called_once "terraform_plan"
    assert_mock_called_with "terraform_plan" \
        "-out=tfplan" \
        "-var" "namespace=$GITHUB_NAMESPACE" \
        "-var" "domain=$APPLICATION_DOMAIN" \
        "-var" "dns_zone=$CF_DNS_ZONE" \
        "-var" "ssh_port=$SSH_PORT" \
        "-var" "ssh_public_key_file=$PUBLIC_KEY_FILE" \
        "-var" "cf_token=$CF_TOKEN" \
        "-var" "do_token=$DO_TOKEN"
}

@test "creates Terraform plan from options" {
    run ./deploy <<< "y" \
        --namespace "test-namespace" \
        --domain "example.com" \
        --dns-zone "abc123" \
        --ssh-port "2222" \
        --public-key "/path/to/public_key.pub" \
        --cf-token "cf_token" \
        --do-token "do_token"
    assert_success
    assert_mock_called_once "terraform_plan"
    assert_mock_called_with "terraform_plan" \
        "-out=tfplan" \
        "-var" "namespace=test-namespace" \
        "-var" "domain=example.com" \
        "-var" "dns_zone=abc123" \
        "-var" "ssh_port=2222" \
        "-var" "ssh_public_key_file=/path/to/public_key.pub" \
        "-var" "cf_token=cf_token" \
        "-var" "do_token=do_token"
}

@test "applies Terraform plan" {
    setup_remote_env
    run ./deploy <<< "y"
    assert_success
    assert_mock_called_once "terraform_apply"
    assert_mock_called_with "terraform_apply" "tfplan"
}

@test "aborts if plan not approved" {
    setup_remote_env
    run ./deploy <<< "n"
    assert_success
    assert_output --partial "Deployment aborted."
    assert_mock_not_called "terraform_apply"
}

@test "automatically approves plan" {
    setup_remote_env
    run ./deploy --approve
    assert_success
    assert_mock_called_once "terraform_apply"
    assert_mock_called_with "terraform_apply" "tfplan"
}
