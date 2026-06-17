# GHCR pull credentials in Secrets Manager.
# ECS reads this via the task definition's repositoryCredentials to pull a PRIVATE
# image. Skip this whole file if you make the GHCR package PUBLIC instead.
# NOTE: Secrets Manager is ~$0.40/secret/month - not free tier.

# # The secret container.
# resource "aws_secretsmanager_secret" "ghcr" {
# }

# # The secret value - ECS expects JSON: { "username": "...", "password": "..." }
# resource "aws_secretsmanager_secret_version" "ghcr" {
# }
