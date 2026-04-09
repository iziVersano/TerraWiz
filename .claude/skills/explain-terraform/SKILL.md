# explain-terraform

When invoked after a `.tf` file is created or modified, explain the Terraform resources to the user.

## For each resource in the file, explain:

1. **What it is** — describe the AWS resource in plain English (assume the user is new to AWS)
2. **Why it's needed** — explain its role in this specific architecture
3. **How it connects** — describe which other resources depend on it or that it depends on
4. **What happens in AWS** — what will actually be created in the AWS account when `terraform apply` runs

## Format

Use a heading per resource (`### aws_resource_type "name"`), then the four points above as short paragraphs or bullets. Keep it beginner-friendly but technically accurate.

## Example output style

### `aws_ecr_repository "terrawiz"`
- **What it is:** A private Docker image registry hosted by AWS — like a private Docker Hub that lives inside your AWS account.
- **Why it's needed:** ECS Fargate needs to pull your container image from somewhere. ECR is the AWS-native registry and works seamlessly with ECS without extra credentials.
- **How it connects:** The ECR repository URL is passed as an output to the ECS task definition, which tells Fargate where to pull the image from.
- **What happens in AWS:** A new private registry is created at `<account-id>.dkr.ecr.us-east-1.amazonaws.com/terrawiz`. You can push Docker images to it after authenticating with `aws ecr get-login-password`.
