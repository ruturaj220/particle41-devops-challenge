# Particle41 DevOps Team Challenge

Welcome to my submission for the Particle41 DevOps Challenge!  
This repository demonstrates modern DevOps practices, focusing on containerization and infrastructure-as-code.

---

## 📦 Part 1: Minimalist Application & Docker

### SimpleTimeService Overview

A minimal FastAPI-based web service that returns a JSON response at `/` with:

```json
{
  "timestamp": "<current UTC timestamp>",
  "ip": "<client IP address>"
}
```

### Project Structure

```
.
├── app/
│   ├── app.py             # FastAPI app
│   ├── requirements.txt   # Python dependencies
│   └── Dockerfile         # Container build config
├── terraform/             # Contains Terraform configuration files for AWS infrastructure            
│   ├── main.tf           # Defines VPC, subnets, NAT Gateway, ALB, ECS cluster, tasks, services, security groups
│   ├── variables.tf      # Input variables for Terraform configuration
│   ├── outputs.tf        # Output values
│   ├── versions.tf       # Specifies Terraform and provider versions
│   └── terraform.tfstate # Terraform state file (managed locally by default)

└── README.md             # This file
```

### Technologies Used

- **Python 3.11**
- **FastAPI** - Modern, fast web framework
- **Docker** - Containerization (non-root container for security)
- **Uvicorn** - ASGI server

---

## 🚀 Quick Start

### Option 1: Using Pre-built Docker Image (Recommended)

The easiest way to run the application is using the pre-built Docker image:

```bash
# Pull the image from DockerHub
docker pull ruturaj21/simpletimeservice:latest

# Run the container
docker run -p 5000:5000 ruturaj21/simpletimeservice:latest
```

**DockerHub Repository:** `ruturaj21/simpletimeservice:latest`

Visit [http://localhost:5000](http://localhost:5000) to see the output.

### Option 2: Local Build & Run

If you prefer to build the image locally:

#### 1. Clone the Repository

```bash
git clone https://github.com/ruturaj220/particle41-devops-challenge.git
cd particle41-devops-challenge/app
```

#### 2. Build the Docker Image

```bash
docker build -t simpletimeservice:latest .
```

#### 3. Run the Container

```bash
docker run -d -p 5000:5000 --name simpletimeservice_app simpletimeservice:latest
```

#### 4. Test the API

```bash
curl http://localhost:5000/
```

**Expected Output:**
```json
{
  "timestamp": "2025-07-12T12:00:00.123456",
  "ip": "172.17.0.1"
}
```

---

## 🧪 Testing the Application

### Health Check
```bash
curl -X GET http://localhost:5000/
```

### Using Browser
Navigate to [http://localhost:5000](http://localhost:5000) in your web browser.

### Response Format
The API returns a JSON object with:
- `timestamp`: Current UTC timestamp in ISO format
- `ip`: Client IP address as seen by the server

---

## 🐳 Docker Configuration

### Container Features
- **Non-root user**: Runs as user `appuser` for security
- **Minimal base image**: Uses Python 3.11-slim
- **Health checks**: Built-in container health monitoring
- **Port exposure**: Exposes port 5000

### Docker Commands Reference

```bash
# Build image
docker build -t simpletimeservice:latest .

# Run container (detached)
docker run -d -p 5000:5000 --name simpletimeservice_app simpletimeservice:latest

# View logs
docker logs simpletimeservice_app

# Stop container
docker stop simpletimeservice_app

# Remove container
docker rm simpletimeservice_app

# Remove image
docker rmi simpletimeservice:latest
```

---

## Cleanup

To clean up all resources:

```bash
# Stop and remove container
docker stop simpletimeservice_app
docker rm simpletimeservice_app

# Remove local image (optional)
docker rmi simpletimeservice:latest

# Remove pulled image (optional)
docker rmi ruturaj21/simpletimeservice:latest
```

# Part 2: Terraform AWS Deployment

Deploy the SimpleTimeService to AWS using Terraform with ECS Fargate, VPC, and Application Load Balancer.

---

## 🚀 Quick Start

### Prerequisites
- AWS Account with programmatic access
- [AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/install-cliv2.html) installed
- [Terraform](https://learn.hashicorp.com/tutorials/terraform/install-cli) installed

### Step 1: Configure AWS
```bash
aws configure
```
Enter your:
- AWS Access Key ID
- AWS Secret Access Key  
- Default region (e.g., `us-east-2`)
- Default output format: `json`

### Step 2: Deploy Infrastructure
```bash
# Navigate to terraform directory
cd terraform/

# Initialize Terraform
terraform init

# Review what will be created
terraform plan

# Deploy (takes 5-10 minutes)
terraform apply --auto-approve
```

### Step 3: Get Application URL
After deployment completes, copy the ALB DNS name from the output:
```
Outputs:
alb_dns_name = "your-alb-dns-name.us-east-2.elb.amazonaws.com"
```

### Step 4: Test Application
```bash
# Test the endpoint
curl http://your-alb-dns-name.us-east-2.elb.amazonaws.com/
```

**Expected Response:**
```json
{
  "timestamp": "2025-07-13T11:15:07.224215",
  "ip": "10.0.1.124"
}
```

### Step 5: Cleanup (Important!)
```bash
# Destroy infrastructure to avoid charges
terraform destroy --auto-approve
```

---

## 📋 What Gets Created

### AWS Resources
- **VPC** with public/private subnets
- **ECS Fargate Cluster** running the container
- **Application Load Balancer** for public access
- **Security Groups** for network security
- **IAM Roles** for ECS permissions
- **CloudWatch Logs** for monitoring

### Network Setup
- Public subnets: Load balancer
- Private subnets: ECS containers
- NAT Gateway: Outbound internet access
- Internet Gateway: Inbound public access

---

## 🔍 Troubleshooting

### If Application Doesn't Load
1. Wait 2-3 minutes after `terraform apply` completes
2. Check ECS service in AWS Console:
   - Go to **ECS > Clusters > particle41-devops-challenge-cluster**
   - Verify tasks are running and healthy

### If Terraform Fails
- Ensure AWS credentials are configured correctly
- Check you have required IAM permissions
- Verify region is consistent

### Common Issues
- **Service unhealthy**: Wait for ECS tasks to start
- **Connection timeout**: Check security group rules
- **404 errors**: Verify ALB target group health

---

## 📝 Testing Checklist

- [ ] AWS CLI configured with valid credentials
- [ ] Terraform installed and working
- [ ] `terraform init` successful
- [ ] `terraform plan` shows resources to create
- [ ] `terraform apply` completes without errors
- [ ] ALB DNS name returned in output
- [ ] Application responds with JSON at the URL
- [ ] `terraform destroy` cleans up resources

---

**Need help?** Check the AWS Console for ECS service status and CloudWatch logs for any errors.
## 👤 Author

**Ruturaj**
- GitHub: [@ruturaj220](https://github.com/ruturaj220)
- DockerHub: [ruturaj21](https://hub.docker.com/u/ruturaj21)