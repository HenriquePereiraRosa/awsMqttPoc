output "jenkins_instance_id" {
  description = "EC2 instance ID for Jenkins"
  value       = aws_instance.jenkins.id
}

output "jenkins_public_ip" {
  description = "Public IP address of Jenkins server"
  value       = var.assign_elastic_ip ? aws_eip.jenkins[0].public_ip : aws_instance.jenkins.public_ip
}

output "jenkins_private_ip" {
  description = "Private IP address of Jenkins server"
  value       = aws_instance.jenkins.private_ip
}

output "jenkins_url" {
  description = "Jenkins web UI URL"
  value       = "http://${var.assign_elastic_ip ? aws_eip.jenkins[0].public_ip : aws_instance.jenkins.public_ip}:8080"
}

output "jenkins_security_group_id" {
  description = "Security group ID for Jenkins"
  value       = aws_security_group.jenkins.id
}

output "jenkins_iam_role_arn" {
  description = "IAM role ARN for Jenkins EC2 instance"
  value       = aws_iam_role.jenkins_ec2_role.arn
}

output "jenkins_initial_admin_password_command" {
  description = "Command to get initial Jenkins admin password"
  value       = "aws ssm start-session --target ${aws_instance.jenkins.id} --document-name AWS-StartInteractiveCommand --parameters command='cat /var/lib/jenkins/secrets/initialAdminPassword' || ssh -i YOUR_KEY.pem ubuntu@${var.assign_elastic_ip ? aws_eip.jenkins[0].public_ip : aws_instance.jenkins.public_ip} 'sudo cat /var/lib/jenkins/secrets/initialAdminPassword'"
}

