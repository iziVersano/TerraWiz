# free-tier-guard

Before any `terraform apply`, scan the plan output for resources that incur AWS costs and warn the user.

## Resources that always cost money (flag these)

| Resource | Approx. cost |
|---|---|
| `aws_ecs_service` / `aws_ecs_task_definition` (Fargate) | ~$0.01–$0.05/hr (NO free tier) |
| `aws_nat_gateway` | ~$0.045/hr + $0.045/GB data |
| `aws_eip` (Elastic IP, unattached) | ~$0.005/hr |
| `aws_lb` / `aws_alb` (Load Balancer) | ~$0.008/hr + LCUs |
| `aws_rds_instance` | Free tier: db.t3.micro 750 hrs/month (first 12 months only) |

## Resources that are free tier eligible (note but don't block)
- `aws_vpc`, `aws_subnet`, `aws_internet_gateway`, `aws_route_table` — free
- `aws_security_group` — free
- `aws_ecr_repository` — free tier: 500 MB/month storage
- `aws_iam_role`, `aws_iam_policy` — free
- `aws_ecs_cluster` — free (you pay for the tasks, not the cluster itself)

## Output format

Print this warning block before asking for confirmation:

```
⚠️  COST WARNING — review before applying
──────────────────────────────────────────────────────
 Resource                          Est. Cost
 aws_ecs_service (Fargate)         ~$0.01–$0.05/hr
──────────────────────────────────────────────────────
 Estimated total while running:    ~$X.XX/hr
 Remember: run /destroy when done!
──────────────────────────────────────────────────────
```

Then ask: "Do you want to proceed with `terraform apply`?"

Do NOT apply without explicit user confirmation.
