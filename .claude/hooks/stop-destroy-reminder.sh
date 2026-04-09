#!/bin/bash
# TerraWiz stop hook: remind about terraform destroy when state exists
# Fargate has NO free tier — this reminder prevents surprise charges.

STATE_FILES=$(find /home/dci-student/TerraWiz/terraform -name "terraform.tfstate" \
    -not -path "*/.terraform/*" 2>/dev/null)

if [[ -n "$STATE_FILES" ]]; then
    RESOURCE_COUNT=$(cat $STATE_FILES 2>/dev/null | python3 -c "
import sys, json
try:
    state = json.load(sys.stdin)
    resources = state.get('resources', [])
    print(len(resources))
except:
    print(0)
" 2>/dev/null)

    if [[ "${RESOURCE_COUNT:-0}" -gt 0 ]]; then
        echo ""
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo "  COST REMINDER: $RESOURCE_COUNT Terraform resource(s) may be live."
        echo ""
        echo "  Fargate has NO free tier. You may be incurring charges."
        echo "  Run /destroy when done to avoid unexpected AWS costs."
        echo ""
        echo "  Manual: cd terraform && terraform destroy"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    fi
fi
