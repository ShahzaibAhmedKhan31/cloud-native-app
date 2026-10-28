output "certificate_arn" {
  description = "ARN of validated ACM SSL Certificate"
  value       = aws_acm_certificate_validation.cert.certificate_arn
}

output "fqdn" {
  description = "Fully Qualified Domain Name of the application"
  value       = aws_route53_record.alb_alias.fqdn
}

output "name_servers" {
  description = "COPY THESE 4 NAMESERVERS TO HOSTINGER"
  value       = aws_route53_zone.main.name_servers
}