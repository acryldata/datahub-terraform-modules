# DataHub on ECS — Terraform templates

Terraform templates implementing the reference architecture described in
[`aws-ecs.md`](https://github.com/datahub-project/datahub/blob/master/docs/deploy/aws-ecs.md): DataHub Frontend, GMS, and Actions running as ECS Fargate
services, RDS MySQL, MSK, OpenSearch, Cloud Map for internal service discovery, and an optional ALB +
Route 53 for public access.

> ⚠️ This is a reference deployment, not a production-hardening guide. Use this as a guide but not as production-ready infrastructure.

> **Tested version.** These templates were tested with DataHub **v0.14.1**. DataHub **1.5 and later** also require
> `DATAHUB_TOKEN_SERVICE_SIGNING_KEY` and `DATAHUB_TOKEN_SERVICE_SALT` on GMS. They are safe to set on v0.14.1 as well.

## What this creates

- A new VPC with public subnets (ALB only) and private subnets (ECS tasks, RDS, MSK, OpenSearch)
  across 3 Availability Zones, with a NAT gateway.
- RDS for MySQL, an MSK cluster (TLS), and an OpenSearch domain.
- ECR repositories for the two **custom** images (Frontend, Actions) that this deployment builds per
  "Build custom DataHub images" in the guide. GMS and `datahub-upgrade` use the public DataHub images
  from Docker Hub, pinned to `var.datahub_version`.
- ECS Fargate services for Frontend, GMS, and Actions and creates task definition for System Upgrade task.
- Cloud Map private DNS for Frontend/Actions → GMS resolution, and an ALB + Route 53
  record for public or private access to Frontend (use enable_public_access env to set this).
- Secrets Manager for all Datahub secrets.

## How the templates are organized

The templates are split into modules, one per concern (`networking`, `security`, `ecr`, `secrets`, `iam`,
`data_stores`, `service_discovery`, `load_balancer`, `ecs`), wired together by the root module.

`main.tf` in the example directory is a complete example of how to call the root module (`source = "../"`).
Copy it, replace the `<placeholders>`, and set the sizing values for your environment. Run all Terraform commands
from the directory that contains this example `main.tf`.

## Secrets

All DataHub secrets live in a single AWS Secrets Manager secret that holds a **JSON object**. Each ECS task
references one key of that object, in the form `<secret-arn>:<json-key>::`, so every environment variable gets its
own value. 

The secret must contain these keys:

| JSON key | Environment variable | Used by |
|---|---|---|
| `db_password` | `EBEAN_DATASOURCE_PASSWORD` | GMS, System Update |
| `datahub_system_client_secret` | `DATAHUB_SYSTEM_CLIENT_SECRET` | GMS, Frontend, Actions |
| `datahub_secret` | `DATAHUB_SECRET` | Frontend |
| `datahub_token_service_signing_key` | `DATAHUB_TOKEN_SERVICE_SIGNING_KEY` | GMS (required on DataHub 1.5+) |
| `datahub_token_service_salt` | `DATAHUB_TOKEN_SERVICE_SALT` | GMS (required on DataHub 1.5+) |

An example secret value:

```json
{
  "db_password": "<value>",
  "datahub_system_client_secret": "<value>",
  "datahub_secret": "<value>",
  "datahub_token_service_signing_key": "<value>",
  "datahub_token_service_salt": "<value>"
}
```

If a key is missing from the secret, the task fails to start with a `ResourceInitializationError`.

## Before you run `terraform apply`

1. **Build and push the custom Frontend and Actions images.** These services will fail to start
   otherwise. First provision just the ECR repositories:

   ```bash
   terraform init
   terraform workspace select -or-create <environment>
   terraform apply -target=module.datahub_ecs.module.ecr
   ```

   Then build and push:

   ```bash
   aws ecr get-login-password --region <aws_region> \
     | docker login --username AWS --password-stdin <account-id>.dkr.ecr.<aws_region>.amazonaws.com

   docker build -f ../Dockerfile.front -t <frontend-ecr-repo-url>:<frontend_image_tag> .
   docker push <frontend-ecr-repo-url>:<frontend_image_tag>

   docker build -f ../Dockerfile.actions -t <actions-ecr-repo-url>:<actions_image_tag> .
   docker push <actions-ecr-repo-url>:<actions_image_tag>
   ```

   (`<frontend-ecr-repo-url>` / `<actions-ecr-repo-url>` are the `frontend_ecr_repository_url` /
   `actions_ecr_repository_url` outputs, available after the targeted apply above. The example `main.tf`
   re-exports them.)

2. **Request or import an ACM certificate** for your DataHub hostname if `enable_public_access = true`
   (the default), and set `acm_certificate_arn` in the example `main.tf`.

3. Fill in the values marked `<...>` in the example `main.tf`. If you prefer to keep values in a
   `terraform.tfvars` file, copy `terraform.tfvars.example` to `terraform.tfvars` and fill in the values marked
   `<required>` instead, and declare matching variables in your own wrapper.

## Deploy

```bash
terraform init
terraform validate
terraform workspace select -or-create <environment>
terraform plan
terraform apply
```

**Note:** Once everything is deployed:

1. Set the secret values in Secrets Manager, as a JSON object with the keys listed in [Secrets](#secrets).
   On DataHub 1.5 and later this includes `datahub_token_service_signing_key` and `datahub_token_service_salt`.
2. Run the System Update task (`aws ecs run-task`).
3. Restart all ECS services (`aws ecs update-service --force-new-deployment`) so they pick up the secrets.

The exact commands are in the guide's
[Run the System Update task](https://github.com/datahub-project/datahub/blob/master/docs/deploy/aws-ecs.md#run-the-system-update-task)
and
[Update and restart services](https://github.com/datahub-project/datahub/blob/master/docs/deploy/aws-ecs.md#update-and-restart-services)
sections.

## Tear down

```bash
terraform destroy
```

Note `skip_final_snapshot = true` on RDS and `recovery_window_in_days = 0` on the Secrets Manager
secrets — both reference-deployment defaults for easy teardown, not what you'd want for a real
environment holding data you care about.

## Known gaps / things to double-check for your version

- The DataHub environment variable names used in the task definitions (`EBEAN_*`,
  `ELASTICSEARCH_*`, `KAFKA_*`, `DATAHUB_SQL_SETUP_ENABLED`, etc.) reflect commonly used defaults as
  of this writing. Confirm them against the current DataHub docs for the version you're deploying.
- `db_engine_version`, `msk_kafka_version`, and `opensearch_engine_version` defaults will age; check
  current supported versions before applying in a new account/region.
- This creates a **new** VPC. If you're bringing your own VPC (allowed per the guide's
  "Prerequisites"), remove the `networking` module from the root module's `main.tf` and pass your own subnet IDs into
  the other modules instead.
- This template was built against a specific set of Terraform/AWS provider versions and DataHub configuration values, and may contain discrepancies with newer API changes, deprecated arguments, or resources that no longer match the current AWS provider schema. If you run into an error or notice something outdated, contributions are welcome — feel free to open a PR with a fix or a note describing what you found.