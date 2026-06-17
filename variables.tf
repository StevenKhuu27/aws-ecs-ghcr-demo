variable "region" {
  description = "AWS region. Sydney by default."
  type        = string
  default     = "ap-southeast-2"
}

variable "project" {
  description = "Name prefix for all resources."
  type        = string
  default     = "ecs-ghcr-demo"
}

variable "container_image" {
  description = "Full GHCR image reference, e.g. ghcr.io/steven/youtube-downloader:latest"
  type        = string
}

variable "container_port" {
  description = "Port the container listens on (also the port exposed on the host)."
  type        = number
  default     = 80
}

variable "github_username" {
  description = "GitHub username used to pull the private GHCR image."
  type        = string
  default     = ""
}

variable "github_token" {
  description = "GitHub Personal Access Token (classic) with read:packages scope. Only needed for PRIVATE GHCR images."
  type        = string
  sensitive   = true
  default     = ""
}

variable "ingress_cidr" {
  description = "CIDR allowed to reach the container port. Lock to your IP/32 for safety; 0.0.0.0/0 = open to the world."
  type        = string
  default     = "0.0.0.0/0"
}
