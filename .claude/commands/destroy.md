Destroy ALL Terraform-managed AWS resources in TerraWiz.

Steps:
1. Print a clear warning: "This will permanently destroy all AWS resources in this project."
2. Change into `/home/dci-student/TerraWiz/terraform/`
3. Run `terraform plan -destroy` and show what will be destroyed
4. Ask the user to type "yes" to confirm — do NOT proceed without this confirmation
5. Run `terraform destroy -auto-approve`
6. Confirm all resources have been destroyed (check the output for errors)
7. Note: ECR images are NOT automatically deleted by Fargate teardown.
   Remind the user to delete ECR images manually if they want to avoid storage costs:
   `aws ecr list-images --repository-name terrawiz` then delete them via the Console or CLI.
8. Confirm: "All resources destroyed. No further AWS charges from this project."
