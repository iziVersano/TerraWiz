#!/bin/bash
# TerraWiz pre-bash guard: block aws CLI write commands
# Enforces the "Terraform only" rule — no aws CLI resource creation/modification
# Claude Code passes the tool input as JSON on stdin.

INPUT=$(cat)
CMD=$(echo "$INPUT" | python3 -c "
import sys, json
try:
    d = json.load(sys.stdin)
    print(d.get('command', ''))
except:
    print('')
" 2>/dev/null)

# Match: aws <service> <write-verb>
if echo "$CMD" | grep -qE 'aws[[:space:]]+(ec2|ecs|ecr|iam|s3|rds|elb|elbv2|cloudformation|route53|autoscaling|logs)[[:space:]]+(create|run|put|attach|associate|allocate|register|add|modify|update|delete|remove|detach|deregister|terminate|stop|reboot|reset|revoke|grant|tag|untag|enable|disable|set|import|push|start)'; then
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "  BLOCKED: Direct aws CLI writes are not allowed."
    echo "  TerraWiz rule: Use Terraform for all AWS resources."
    echo ""
    echo "  Attempted command: $CMD"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    exit 2
fi
