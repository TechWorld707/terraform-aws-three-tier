# Terraform bootstrap

This root configuration creates the resources required before environment infrastructure can use remote state or GitHub Actions OIDC.

It provisions:

- a private, versioned S3 state bucket;
- a rotating KMS key;
- native S3 lockfile support (configured later in each environment backend);
- GitHub's OIDC identity provider;
- separate `dev`, `staging`, and `production` roles restricted to GitHub Environments;
- a monthly AWS Budget.

## Prerequisites

Authenticate the AWS CLI locally, then confirm the intended account:

```bash
aws sts get-caller-identity
```

Never commit AWS credentials or a real `terraform.tfvars` file.

## Bootstrap locally

```bash
cd bootstrap
cp terraform.tfvars.example terraform.tfvars
terraform fmt -recursive
terraform init
terraform validate
terraform plan -out=bootstrap.tfplan
terraform apply bootstrap.tfplan
```

Record the outputs. The state bucket and KMS key have `prevent_destroy` enabled. Removing the bootstrap configuration does not authorize deleting them.

## GitHub Environments

Create `dev`, `staging`, and `production` under the repository's **Settings → Environments**. Add protection rules to production. GitHub Actions must set the matching `environment` field for its OIDC token subject to match the AWS trust policy.

## Remote backend

Environment roots use partial backend configuration. Initialize `dev` using values from the bootstrap output:

```bash
terraform init \
  -backend-config="bucket=BUCKET_FROM_OUTPUT" \
  -backend-config="key=three-tier-platform/dev/terraform.tfstate" \
  -backend-config="region=eu-west-2" \
  -backend-config="encrypt=true" \
  -backend-config="kms_key_id=KMS_ARN_FROM_OUTPUT" \
  -backend-config="use_lockfile=true"
```

Do not add the generated backend values or local state to Git.
