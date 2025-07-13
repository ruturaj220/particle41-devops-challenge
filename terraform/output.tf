# Output: ALB DNS Name
# Provides the DNS name of the Application Load Balancer, which is the public endpoint for your service.
output "alb_dns_name" {
  description = "The DNS name of the Application Load Balancer."
  value       = aws_lb.main.dns_name
}
