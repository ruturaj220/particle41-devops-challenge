terraform {
  required_version = ">= 1.0.0, < 2.0.0" # Compatible with Terraform 1.x

  # We are using the AWS provider.
  required_providers {
    aws = {
      source  = "hashicorp/aws" # Official AWS provider from HashiCorp
      version = "~> 5.0"        # Compatible with AWS provider version 5.x
    }
  }
}

# Configures the AWS provider.
# The 'region' will be sourced from the 'aws_region' variable.
provider "aws" {
  region = var.aws_region
}

# --- Security Groups ---

# Resource: Security Group for the Application Load Balancer (ALB)
# Allows inbound HTTP (port 80) and HTTPS (port 443) traffic from anywhere.
resource "aws_security_group" "alb" {
  name        = "${var.project_name}-alb-sg"
  description = "Allow HTTP/HTTPS inbound traffic to ALB"
  vpc_id      = aws_vpc.main.id

  # Inbound rule for HTTP
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Allow from anywhere
  }

  # Inbound rule for HTTPS (if you were to add TLS, though not required by challenge)
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Allow from anywhere
  }

  # Outbound rule: Allow all outbound traffic (ALB needs to reach ECS tasks)
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1" # All protocols
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.project_name}-alb-sg"
    Environment = "dev"
  }
}

# Resource: Security Group for ECS Fargate Tasks
# Allows inbound traffic from the ALB on the application port (5000).
# Allows outbound traffic to the internet (e.g., to pull Docker image).
resource "aws_security_group" "ecs_tasks" {
  name        = "${var.project_name}-ecs-tasks-sg"
  description = "Allow inbound traffic from ALB to ECS tasks on app port and all outbound"
  vpc_id      = aws_vpc.main.id

  # Inbound rule: Allow traffic from the ALB security group on the application port.
  ingress {
    from_port       = var.app_port # Port 5000 for your FastAPI app
    to_port         = var.app_port
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id] # Only allow traffic from the ALB
  }

  # Outbound rule: Allow all outbound traffic (needed for pulling images, logging, etc.)
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1" # All protocols
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.project_name}-ecs-tasks-sg"
    Environment = "dev"
  }
}

# --- IAM Roles for ECS ---

# Resource: IAM Role for ECS Task Execution
# This role grants ECS permission to pull Docker images from ECR (if used)
# and publish container logs to CloudWatch.
resource "aws_iam_role" "ecs_task_execution_role" {
  name = "${var.project_name}-ecs-task-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      },
    ]
  })

  tags = {
    Name        = "${var.project_name}-ecs-task-execution-role"
    Environment = "dev"
  }
}

# Resource: IAM Policy Attachment for ECS Task Execution Role
# Attaches the AWS-managed policy for ECS task execution to the role.
resource "aws_iam_role_policy_attachment" "ecs_task_execution_role_policy" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# Resource: IAM Role for ECS Task (Optional, but good practice for application-level permissions)
# This role is assumed by the container itself. Not strictly needed for this simple app,
# but essential if your app needs to interact with other AWS services (e.g., S3, DynamoDB).
resource "aws_iam_role" "ecs_task_role" {
  name = "${var.project_name}-ecs-task-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      },
    ]
  })

  tags = {
    Name        = "${var.project_name}-ecs-task-role"
    Environment = "dev"
  }
}


# --- ECS Cluster ---

# Resource: AWS ECS Cluster
# Creates an ECS cluster where our services and tasks will run.
resource "aws_ecs_cluster" "main" {
  name = "${var.project_name}-cluster"

  tags = {
    Name        = "${var.project_name}-cluster"
    Environment = "dev"
  }
}

# --- Application Load Balancer (ALB) ---

# Resource: AWS ALB (Application Load Balancer)
# Creates an ALB to distribute traffic to our ECS tasks.
resource "aws_lb" "main" {
  name               = "${var.project_name}-alb"
  internal           = false # Public-facing ALB
  load_balancer_type = "application"
  # ALB needs to be in public subnets to receive internet traffic.
  subnets            = [for s in aws_subnet.public : s.id]
  security_groups    = [aws_security_group.alb.id] # Attaches the ALB security group.

  tags = {
    Name        = "${var.project_name}-alb"
    Environment = "dev"
  }
}

# Resource: AWS ALB Target Group
# Defines a target group for the ALB, where ECS tasks will be registered.
resource "aws_lb_target_group" "main" {
  name                 = "${var.project_name}-tg"
  port                 = var.app_port # Target group listens on the application port (5000).
  protocol             = "HTTP"
  vpc_id               = aws_vpc.main.id
  target_type          = "ip" # Fargate uses IP-based targets.
  deregistration_delay = 30   # Time in seconds to wait before deregistering a target.

  health_check {
    path                = "/" # Health check endpoint for your FastAPI app.
    protocol            = "HTTP"
    matcher             = "200" # Expect HTTP 200 OK
    interval            = 30    # Check every 30 seconds
    timeout             = 5     # Timeout after 5 seconds
    healthy_threshold   = 2     # 2 consecutive successful health checks for healthy state
    unhealthy_threshold = 2     # 2 consecutive failed health checks for unhealthy state
  }

  tags = {
    Name        = "${var.project_name}-tg"
    Environment = "dev"
  }
}

# Resource: AWS ALB Listener
# Defines a listener for the ALB on port 80 (HTTP) that forwards traffic to the target group.
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.main.arn
  }

  tags = {
    Name        = "${var.project_name}-http-listener"
    Environment = "dev"
  }
}

# --- ECS Task Definition ---

# Resource: AWS ECS Task Definition (Fargate)
# Describes how our Docker container should run on Fargate.
resource "aws_ecs_task_definition" "app" {
  family                   = "${var.project_name}-task" # A logical name for the task definition.
  cpu                      = var.ecs_task_cpu           # CPU units (e.g., 256 for 0.25 vCPU).
  memory                   = var.ecs_task_memory        # Memory in MiB (e.g., 512 MiB).
  network_mode             = "awsvpc"                   # Required for Fargate.
  requires_compatibilities = ["FARGATE"]                # Specifies Fargate launch type.
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn # Role for ECS agent.
  task_role_arn            = aws_iam_role.ecs_task_role.arn           # Role for the application inside the container.

  # Container definitions in JSON format.
  container_definitions = jsonencode([
    {
      name        = var.project_name
      image       = var.docker_image_name # Your Docker Hub image!
      cpu         = var.ecs_task_cpu
      memory      = var.ecs_task_memory
      essential   = true # If true, the task stops if this container stops.
      portMappings = [
        {
          containerPort = var.app_port # Port 5000 inside the container.
          hostPort      = var.app_port # Not directly used by Fargate, but required for definition.
          protocol      = "tcp"
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.ecs_logs.name
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "ecs"
        }
      }
    }
  ])

  tags = {
    Name        = "${var.project_name}-task-definition"
    Environment = "dev"
  }
}

# Resource: AWS CloudWatch Log Group
# Creates a CloudWatch Log Group for ECS task logs.
resource "aws_cloudwatch_log_group" "ecs_logs" {
  name              = "/ecs/${var.project_name}-app"
  retention_in_days = 7 # Retain logs for 7 days.

  tags = {
    Name        = "${var.project_name}-ecs-logs"
    Environment = "dev"
  }
}

# --- ECS Service ---

# Resource: AWS ECS Service
# Creates an ECS service that runs and maintains the desired number of tasks.
resource "aws_ecs_service" "app" {
  name            = "${var.project_name}-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.app.arn
  desired_count   = var.ecs_desired_count # Number of tasks to run.
  launch_type     = "FARGATE"             # Specifies Fargate launch type.

  # Network configuration for the ECS tasks.
  # Tasks will be placed in the private subnets.
  network_configuration {
    subnets         = [for s in aws_subnet.private : s.id]
    security_groups = [aws_security_group.ecs_tasks.id]
    assign_public_ip = false # Fargate tasks in private subnets should NOT have public IPs.
  }

  # Load balancer configuration for the service.
  load_balancer {
    target_group_arn = aws_lb_target_group.main.arn
    container_name   = var.project_name # Name of the container in the task definition.
    container_port   = var.app_port     # Port exposed by the container.
  }

  # Ensures the service is created after the ALB listener is ready.
  depends_on = [aws_lb_listener.http]

  tags = {
    Name        = "${var.project_name}-service"
    Environment = "dev"
  }
}
