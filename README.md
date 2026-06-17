# aws-ecs-ghcr-demo

A learning project: deploy a container to AWS with Terraform, running on **ECS-on-EC2**
(free-tier `t3.micro`) and pulling a **image from GHCR**.


## Free tier / cost notes

- **EC2 `t3.micro`** - free-tier eligible (750 hrs/mo on 12-month accounts). The container host.
- **ECR** - not used here (pulling from GHCR instead).
- **Secrets Manager** - ~$0.40/secret/month, NOT free. Used to hold the GHCR creds. Don't need if image is public.
- Verify your account's free-tier status in the Billing console first.
- Run `terraform destroy` when done so nothing keeps accruing.

## Files

| File | Contents |
|---|---|
| `versions.tf` | provider plumbing |
| `variables.tf` | inputs |
| `network.tf` | default VPC/subnets + security group |
| `secrets.tf` | GHCR creds in Secrets Manager |
| `iam.tf` | 2 roles (EC2 instance + ECS task execution) + GHCR secret read |
| `ecs.tf` | AMI lookup, cluster, launch template, ASG, log group, task def, service |
| `outputs.tf` | cluster name + public-IP fetch command |
| `terraform.tfvars.example` | copy → `terraform.tfvars`, fill secrets |


## How it fits together

```
ASG ──launches──> t3.micro (ECS-optimised AMI)
                    │  user_data writes ECS_CLUSTER=<name> into /etc/ecs/ecs.config
                    └──registers──> ECS cluster
ECS service ──schedules──> task ──pulls──> ghcr.io/<you>/<app>
                                  (private? uses repositoryCredentials -> Secrets Manager)
container port ──exposed via──> security group ──> public IP on the host
```

## Run it

```bash
cp terraform.tfvars.example terraform.tfvars   # fill in image, github user/token, your IP
terraform init
terraform plan      # read this carefully before applying
terraform apply
# ...test the public IP on the container port...
terraform destroy   # when done
```

## Gotchas to watch for

- **`user_data`** must write `ECS_CLUSTER=<cluster name>` into `/etc/ecs/ecs.config`,
  base64-encoded. This is what makes the host join the cluster - if blank,
  service has nowhere to place tasks (it'll sit at 0 running, no obvious error).
- **Private GHCR** needs `repositoryCredentials.credentialsParameter` in the task
  definition pointing at the Secrets Manager ARN, and the task *execution* role needs
  `secretsmanager:GetSecretValue` on it. Both halves required.
- The secret value must be JSON: `{ "username": "...", "password": "<PAT>" }`.
  The PAT needs `read:packages` scope.
- The container runs on the ASG's host, so there's no direct `public_ip` attribute -
- If public image then delete/comment out resources
  fetch it with the CLI one-liner in `outputs.tf`.

## Next step (the actual goal)

Once this applies cleanly by hand, wire a **GitHub Actions** workflow to do the deploy:
matrix build → push image → **OIDC-auth'd** `terraform apply` (no stored AWS keys).
