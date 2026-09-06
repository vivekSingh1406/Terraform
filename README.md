# Terraform
Infrastructure as Code (IaC) tool created by HashiCorp 

## Common AWS configuration

The root `.env` file supplies the same AWS credentials and region to EC2, S3,
and every other Terraform practice folder. Edit `.env` once and replace the
placeholder values with your AWS access key and secret key. The file is ignored
by Git.

From the repository root, load the configuration and enter a practice folder:

```bash
source .env
cd terraform-aws-ec2
terraform init
terraform plan
```

If you are already inside a practice folder, load the same root configuration:

```bash
source ../.env
terraform plan
```

Each new practice folder only needs this provider configuration:

```hcl
provider "aws" {}
```

The AWS provider automatically reads `AWS_ACCESS_KEY_ID`,
`AWS_SECRET_ACCESS_KEY`, and `AWS_DEFAULT_REGION` from the environment. Never
commit the real `.env` file.




// terraform init

- used for initializing terraform configuration
- First command to run after making changes to terraform code
- It downloads providers specified in the configuration 
- Downloaded providers are stored in the .terraform directory
