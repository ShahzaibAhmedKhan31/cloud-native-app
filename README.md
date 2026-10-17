# Cloud-Native App — End to End

A cloud-native REST API deployed to AWS using ECS Fargate, with full CI/CD, monitoring, and infrastructure as code.

## Tech Stack
- **App**: FastAPI (Python 3.11)
- **Database**: PostgreSQL 16
- **Container**: Docker
- **Infra**: Terraform
- **Cloud**: AWS (ECS Fargate, RDS, ALB, ECR, CloudWatch, etc.)
- **CI/CD**: GitHub Actions

## Local Development

### Prerequisites
- Docker & Docker Compose
- Git

### Run Locally
```bash
docker compose up --build