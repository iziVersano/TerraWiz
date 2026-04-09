Run `terraform plan` in the TerraWiz terraform directory.

Steps:
1. Change into `/home/dci-student/TerraWiz/terraform/`
2. If `.terraform/` does not exist, run `terraform init` first and explain what it does
3. Run `terraform plan -out=tfplan`
4. Show the full plan output
5. Explain in plain English what will be created, modified, or destroyed
6. Flag any resources that cost money (especially Fargate tasks, NAT gateways, public IPs)
7. Tell the user the next step: run `/apply` to apply, or ask questions first
