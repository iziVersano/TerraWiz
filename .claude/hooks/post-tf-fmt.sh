#!/bin/bash
# TerraWiz post-edit hook: auto-format and validate .tf files
# Runs after every Edit tool call. Checks if the edited file is .tf, then formats it.

INPUT=$(cat)
FILE=$(echo "$INPUT" | python3 -c "
import sys, json
try:
    d = json.load(sys.stdin)
    # PostToolUse wraps input under tool_input key
    tool_input = d.get('tool_input', d)
    print(tool_input.get('file_path', ''))
except:
    print('')
" 2>/dev/null)

if [[ "$FILE" == *.tf ]]; then
    echo ""
    if command -v terraform &>/dev/null; then
        echo "[ tf-fmt ] Auto-formatting $FILE..."
        terraform fmt "$FILE" 2>&1 && echo "[ tf-fmt ] OK"

        # Only validate if terraform init has been run (checks for .terraform dir)
        ROOT_TF_DIR="/home/dci-student/TerraWiz/terraform"
        if [[ -d "$ROOT_TF_DIR/.terraform" ]]; then
            echo "[ tf-validate ] Validating..."
            terraform validate "$ROOT_TF_DIR" 2>&1
        fi
    else
        echo "[ tf-fmt ] terraform not found in PATH — install it to enable auto-formatting"
    fi
fi
