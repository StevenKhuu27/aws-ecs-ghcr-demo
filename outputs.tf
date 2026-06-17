# Handy outputs after apply.

output "cluster_name" {
  value = aws_ecs_cluster.this.name
}

# The container runs on the ASG's EC2 host, so the public IP isn't a direct
# attribute here. Output a CLI cmd to fetch it instead.
output "find_public_ip_cmd" {
  value = "aws ec2 describe-instances --filters Name=tag:aws:autoscaling:groupName,Values=${aws_autoscaling_group.ecs_host.name} Name=instance-state-name,Values=running --query 'Reservations[].Instances[].PublicIpAddress' --output text --region ${var.region}"
}
