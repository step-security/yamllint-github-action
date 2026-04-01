#!/bin/bash

# validate subscription status
REPO_PRIVATE=$(jq -r '.repository.private | tostring' "$GITHUB_EVENT_PATH" 2>/dev/null || echo "")
UPSTREAM="karancode/yamllint-github-action"
ACTION_REPO="${GITHUB_ACTION_REPOSITORY:-}"
DOCS_URL="https://docs.stepsecurity.io/actions/stepsecurity-maintained-actions"

echo ""
echo -e "\033[1;36mStepSecurity Maintained Action\033[0m"
echo "Secure drop-in replacement for $UPSTREAM"
if [ "$REPO_PRIVATE" = "false" ]; then
    echo -e "\033[32m✓ Free for public repositories\033[0m"
fi
echo -e "\033[36mLearn more:\033[0m $DOCS_URL"
echo ""

if [ "$REPO_PRIVATE" != "false" ]; then
    SERVER_URL="${GITHUB_SERVER_URL:-https://github.com}"

    if [ "$SERVER_URL" != "https://github.com" ]; then
    BODY=$(printf '{"action":"%s","ghes_server":"%s"}' "$ACTION_REPO" "$SERVER_URL")
    else
    BODY=$(printf '{"action":"%s"}' "$ACTION_REPO")
    fi

    API_URL="https://agent.api.stepsecurity.io/v1/github/$GITHUB_REPOSITORY/actions/maintained-actions-subscription"

    RESPONSE=$(curl --max-time 3 -s -w "%{http_code}" \
    -X POST \
    -H "Content-Type: application/json" \
    -d "$BODY" \
    "$API_URL" -o /dev/null) && CURL_EXIT_CODE=0 || CURL_EXIT_CODE=$?

    if [ $CURL_EXIT_CODE -ne 0 ]; then
    echo "Timeout or API not reachable. Continuing to next step."
    elif [ "$RESPONSE" = "403" ]; then
    echo -e "::error::\033[1;31mThis action requires a StepSecurity subscription for private repositories.\033[0m"
    echo -e "::error::\033[31mLearn how to enable a subscription: $DOCS_URL\033[0m"
    exit 1
    fi
fi

function parse_inputs {
    
    yamllint_file_or_dir=""
    if [ "${INPUT_YAMLLINT_FILE_OR_DIR}" != "" ] || [ "${INPUT_YAMLLINT_FILE_OR_DIR}" != "." ]; then
        yamllint_file_or_dir="${INPUT_YAMLLINT_FILE_OR_DIR}"
    fi

    yamllint_strict=''
    if [ "${INPUT_YAMLLINT_STRICT}" == "1" ] || [ "${INPUT_YAMLLINT_STRICT}" == "true" ]; then
        yamllint_strict="--strict"
    fi

    yamllint_config_filepath=''
    if [ ! -z "${INPUT_YAMLLINT_CONFIG_FILEPATH}" ]; then
        yamllint_config_filepath="${INPUT_YAMLLINT_CONFIG_FILEPATH}"
    fi

    yamllint_config_datapath=''
    if [ ! -z "${INPUT_YAMLLINT_CONFIG_DATAPATH}" ]; then
        yamllint_config_datapath="${INPUT_YAMLLINT_CONFIG_DATAPATH}"
    fi

    yamllint_format=''
    if [ ! -z "${INPUT_YAMLLINT_FORMAT}" ]; then
        yamllint_format="${INPUT_YAMLLINT_FORMAT}"
    fi

    yamllint_comment=0
    if [[ "${INPUT_YAMLLINT_COMMENT}" == "0" || "${INPUT_YAMLLINT_COMMENT}" == "false" ]]; then
        yamllint_comment="0"
    fi

    if [[ "${INPUT_YAMLLINT_COMMENT}" == "1" || "${INPUT_YAMLLINT_COMMENT}" == "true" ]]; then
        yamllint_comment="1"
    fi

}

function main {

    scriptDir=$(dirname "${0}")
    source "${scriptDir}/yaml_lint.sh"
    parse_inputs
    
    yaml_lint
    
}

main "${*}"
