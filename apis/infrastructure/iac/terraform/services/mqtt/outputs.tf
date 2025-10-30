output "mqtt_endpoint" {
  description = "AWS IoT Core endpoint - get with: aws iot describe-endpoint --endpoint-type iot:Data-ATS"
  value       = data.aws_iot_endpoint.iot_endpoint.endpoint_address
}

output "mqtt_certificate_arn" {
  description = "MQTT certificate ARN"
  value       = aws_iot_certificate.mqtt_cert.arn
}

output "mqtt_thing_name" {
  description = "MQTT thing name"
  value       = aws_iot_thing.mqtt_client.name
}

output "mqtt_dashboard_url" {
  description = "MQTT CloudWatch dashboard URL"
  value       = "https://${var.aws_region}.console.aws.amazon.com/cloudwatch/home?region=${var.aws_region}#dashboards:name=${aws_cloudwatch_dashboard.mqtt.dashboard_name}"
}

