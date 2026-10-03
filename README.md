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



# AWS RDS MySQL with Terraform
## 1. Configure AWS access

Install Terraform >= 1.5 and AWS CLI. Use an AWS identity authorized to manage VPC networking, RDS, and RDS-managed Secrets Manager credentials. First-time accounts may also need permission to create the RDS service-linked IAM role.

From the repository root, load your existing AWS configuration:

```bash
source .env
cd rds
aws sts get-caller-identity
```

Alternatively, use an AWS CLI profile (including an SSO profile) and set `AWS_PROFILE` and `AWS_DEFAULT_REGION`. The provider uses your environment/profile region; set `export AWS_DEFAULT_REGION=ap-south-1` if you want Mumbai. Never put AWS keys into `.tf` files.

## 2. Choose access and settings

```bash
cp terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars`. For **private access**, keep the defaults and attach the output `application_security_group_id` to an application instance deployed in the output VPC/subnets. This configuration does not create an application server, VPN, or bastion. The existing EC2 example uses a different VPC and cannot connect automatically. CIDR rules alone do not establish routing between networks.

For **direct laptop access**, set `publicly_accessible = true` and `allowed_client_cidrs = ["YOUR_ACTUAL_PUBLIC_IPV4/32"]`. Replace the placeholder with your internet-facing IPv4 address, not a local `192.168.x.x` address. Terraform creates the internet gateway/routes only in this mode. Update the allowlist and apply again if your public IP changes. Port 3306 is limited to the configured ranges and application security group.

Set `multi_az = true` if you need a standby, at additional cost. Instance class/engine availability varies by region; optionally check it before deploying:

```bash
aws rds describe-orderable-db-instance-options \
  --engine mysql --db-instance-class db.t3.micro \
  --query 'OrderableDBInstanceOptions[].EngineVersion' --output text
```

## 3. Create the infrastructure

```bash
terraform init
terraform fmt -check
terraform validate
terraform plan -out=mysql.tfplan
terraform apply mysql.tfplan
terraform output
```

Review the plan before running apply. Creation can take several minutes. Commit `.terraform.lock.hcl` for repeatable provider versions. Keep local state safe: it tracks the resources and is needed for updates/deletion; for shared use, configure a secured remote backend with locking.

## 4. Connect to MySQL

Use AWS Console → Secrets Manager → the secret identified by `terraform output -raw master_password_secret_arn` → Retrieve secret value. Your identity needs `secretsmanager:GetSecretValue`. Retrieve the current password when connecting because AWS rotates it.

Install a MySQL client and download the RDS CA bundle:

```bash
curl --fail --output /tmp/rds-global-bundle.pem \
  https://truststore.pki.rds.amazonaws.com/global/global-bundle.pem

mysql --host="$(terraform output -raw mysql_host)" \
  --port=3306 --user=dbadmin --password \
  --ssl-mode=VERIFY_IDENTITY --ssl-ca=/tmp/rds-global-bundle.pem \
  "$(terraform output -raw database_name)"
```

Enter the password at the prompt. For a private deployment, run the client from a machine with network access to the VPC, supplying the hostname/database outputs from the Terraform machine. The TLS bundle must also be present on that client machine.

Verify in the MySQL prompt:

```sql
SELECT VERSION(), DATABASE();
SHOW SESSION STATUS LIKE 'Ssl_cipher';
```

Use the administrator for initial setup; create a dedicated database user with the permissions your application needs.

## 5. Clean up

Set `deletion_protection = false` in `terraform.tfvars`, then apply that change before destroying:

```bash
terraform apply
terraform destroy
```
