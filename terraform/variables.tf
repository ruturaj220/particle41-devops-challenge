# AWS Region where the infrastructure will be deployed.
variable "aws_region" {
  description = "The AWS region to deploy resources in."
  type        = string
  default     = "us-east-2" # You can change this default to your preferred region (e.g., "ap-south-1")
}

# Project name to be used as a prefix for resource naming.
variable "project_name" {
  description = "A unique name for the project, used as a prefix for resource names."
  type        = string
  default     = "particle41-devops-challenge"
}

# CIDR block for the VPC.
variable "vpc_cidr_block" {
  description = "The CIDR block for the VPC."
  type        = string
  default     = "10.0.0.0/16"
}

# CIDR blocks for public subnets.
# We'll create two public subnets across two availability zones.
variable "public_subnet_cidr_blocks" {
  description = "A list of CIDR blocks for the public subnets."
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

# CIDR blocks for private subnets.
# We'll create two private subnets across two availability zones.
variable "private_subnet_cidr_blocks" {
  description = "A list of CIDR blocks for the private subnets."
  type        = list(string)
  default     = ["10.0.101.0/24", "10.0.102.0/24"]
}

# Name of the Docker image to deploy.
variable "docker_image_name" {
  description = "The full name of the Docker image to deploy (e.g., your-dockerhub-username/image-name:tag)."
  type        = string
  default     = "ruturaj21/simpletimeservice:latest"
}

# Number of desired tasks for the ECS service.
variable "ecs_desired_count" {
  description = "The desired number of running tasks for the ECS service."
  type        = number
  default     = 1
}

# CPU units for the ECS task. (1024 units = 1 vCPU)
variable "ecs_task_cpu" {
  description = "The number of CPU units for the ECS task (e.g., 256 for 0.25 vCPU, 512 for 0.5 vCPU, 1024 for 1 vCPU)."
  type        = number
  default     = 256 # Minimum for Fargate tasks
}

# Memory (in MiB) for the ECS task.
variable "ecs_task_memory" {
  description = "The amount of memory (in MiB) for the ECS task (e.g., 512 MiB, 1024 MiB)."
  type        = number
  default     = 512 # Minimum for Fargate tasks
}

# Application port exposed by the Docker container.
variable "app_port" {
  description = "The port on which the application inside the Docker container listens."
  type        = number
  default     = 5000 # Your FastAPI app listens on 5000
}
