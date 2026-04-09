Run `terraform apply` in the TerraWiz terraform directory.

Steps:
1. First, invoke the `free-tier-guard` skill to show a cost warning
2. Run `terraform plan -out=tfplan` to get a fresh plan
3. Show a summary of what will be created
4. Ask the user to explicitly confirm before proceeding — do NOT apply automatically
5. Once confirmed, run `terraform apply tfplan`
6. Show the Terraform outputs (public IP or URL)
7. Tell the user how to hit the endpoint to verify it works
8. Remind the user to run `/destroy` when done reviewing to avoid charges
