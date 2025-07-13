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

## 👤 Author

**Ruturaj**
- GitHub: [@ruturaj220](https://github.com/ruturaj220)
- DockerHub: [ruturaj21](https://hub.docker.com/u/ruturaj21)