# Shared AWS Credentials Design

## Goal

Use one AWS credential configuration for every independent Terraform practice
folder, including EC2, S3, and future examples, without storing access keys or
secret keys in this Git repository.

## Architecture

AWS credentials will be stored once in the standard AWS shared credentials
file under a named profile called `terraform-practice`. Terraform projects will
select that profile through their AWS provider configuration. The default AWS
region remains configurable per project and defaults to `ap-south-1`.

Terraform practice folders remain independent root modules. This is important
because Terraform does not inherit provider files or variable files from a
parent directory.

## Repository Changes

- Remove the duplicate AWS provider block from the EC2 resource file.
- Remove access-key and secret-key variables from the EC2 project.
- Configure the EC2 provider to use the `terraform-practice` profile.
- Replace the credential-bearing `terraform.tfvars` example with a safe,
  committable example containing only non-secret settings.
- Strengthen `.gitignore` rules for local Terraform state and secret files.
- Document how to create the shared AWS profile and reuse the provider pattern
  in new practice folders.

## Credential Flow

1. The user creates the `terraform-practice` profile using `aws configure`.
2. AWS CLI stores the access key and secret key outside this repository.
3. A Terraform project's AWS provider selects `terraform-practice`.
4. The AWS provider SDK reads credentials from the standard shared credentials
   file at runtime.

No credential value is passed through Terraform variables or saved in
Terraform configuration.

## Validation

- Run `terraform fmt -check -recursive` on repository Terraform files.
- Run `terraform init -backend=false` and `terraform validate` for the EC2
  project when the AWS provider is already available or can be downloaded.
- Search tracked project files to confirm no access-key or secret-key variables
  remain.

## Security Boundaries

The repository will never create or write the user's real AWS credentials.
Creating the external profile requires the user to run `aws configure
--profile terraform-practice` interactively. The AWS shared credentials file
must not be committed.
