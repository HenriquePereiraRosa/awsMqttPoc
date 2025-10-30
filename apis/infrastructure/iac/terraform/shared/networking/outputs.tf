output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.main.id
}

output "vpc_cidr_block" {
  description = "VPC CIDR block"
  value       = aws_vpc.main.cidr_block
}

output "public_subnet_ids" {
  description = "Public subnet IDs"
  value       = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  description = "Private subnet IDs"
  value       = aws_subnet.private[*].id
}

output "internet_gateway_id" {
  description = "Internet Gateway ID"
  value       = aws_internet_gateway.main.id
}

output "mqtt_security_group_id" {
  description = "MQTT security group ID"
  value       = aws_security_group.mqtt.id
}

output "kafka_security_group_id" {
  description = "Kafka security group ID"
  value       = aws_security_group.kafka.id
}

output "springboot_security_group_id" {
  description = "Spring Boot security group ID"
  value       = aws_security_group.springboot.id
}

