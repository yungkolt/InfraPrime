# InfraPrime Docker Deployment Guide

## Table of Contents
1. [Prerequisites](#prerequisites)
2. [Quick Start](#quick-start)
3. [Development Deployment](#development-deployment)
4. [Production Deployment](#production-deployment)
5. [Docker Compose Profiles](#docker-compose-profiles)
6. [Environment Configuration](#environment-configuration)
7. [Monitoring and Logging](#monitoring-and-logging)
8. [Backup and Recovery](#backup-and-recovery)
9. [Security and Maintenance](#security-and-maintenance)
10. [Troubleshooting](#troubleshooting)

## Prerequisites

### Required Tools
- **Docker Desktop** (v4.0+): [Download](https://www.docker.com/products/docker-desktop)
- **Docker Compose** (v2.0+): Included with Docker Desktop
- **Git**: For cloning the repository
- **Node.js** (v18+): For frontend development (optional)
- **Python** (v3.9+): For backend development (optional)

### System Requirements
- **RAM**: Minimum 4GB, Recommended 8GB+
- **Disk Space**: 2GB for images and volumes
- **OS**: Windows 10+, macOS 10.14+, or Linux

## Quick Start

### 1. Clone and Setup
```bash
# Clone the repository
git clone https://github.com/yungkolt/InfraPrime.git
cd InfraPrime

# Run the automated setup
./scripts/setup.sh
```

### 2. Start the Application
```bash
# Start all services
./scripts/docker-dev.sh start

# Or manually with Docker Compose
docker-compose -f docker-compose.yml -f docker-compose.dev.yml up -d
```

### 3. Access the Application
- **Frontend**: http://localhost:8080
- **Backend API**: http://localhost:5000
- **Database Admin**: http://localhost:5050
- **Monitoring**: http://localhost:3001

## Development Deployment

### Full Development Environment
```bash
# Start all services with development tools
docker-compose -f docker-compose.yml -f docker-compose.dev.yml up -d

# View logs
docker-compose logs -f

# Check service status
docker-compose ps
```

### Core Services Only
```bash
# Start only essential services
docker-compose up -d database redis backend frontend nginx
```

### Development Tools
```bash
# Start with development tools
docker-compose --profile tools up -d

# Start with monitoring
docker-compose --profile monitoring up -d

# Start with all tools
docker-compose -f docker-compose.yml -f docker-compose.dev.yml --profile tools --profile monitoring up -d
```

## Production Deployment

### 1. Production Configuration
```bash
# Use production compose file
docker-compose -f docker-compose.yml up -d

# Or with custom production overrides
docker-compose -f docker-compose.yml -f docker-compose.prod.yml up -d
```

### 2. Environment Variables
Create production environment files:

**Backend (.env)**
```env
FLASK_ENV=production
FLASK_DEBUG=0
DATABASE_URL=postgresql://admin:secure_password@database:5432/infraprime
REDIS_URL=redis://redis:6379/0
SECRET_KEY=your-secure-secret-key
API_VERSION=1.0.0
ALLOWED_ORIGINS=https://yourdomain.com
LOG_LEVEL=INFO
```

**Frontend (.env)**
```env
NODE_ENV=production
REACT_APP_API_URL=https://api.yourdomain.com
REACT_APP_ENV=production
```

### 3. SSL/HTTPS Setup
```bash
# Generate SSL certificates
cd docker/nginx
chmod +x generate-ssl.sh
./generate-ssl.sh

# Update nginx configuration for HTTPS
# Edit docker/nginx/conf.d/default.conf
```

### 4. Resource Limits
```yaml
# In docker-compose.yml
services:
  backend:
    deploy:
      resources:
        limits:
          memory: 512M
          cpus: '0.5'
        reservations:
          memory: 256M
          cpus: '0.25'
```

## Docker Compose Profiles

### Core Services (default)
- `database` - PostgreSQL database
- `redis` - Redis cache
- `backend` - Flask API server
- `frontend` - React application
- `nginx` - Reverse proxy

### Development Tools (`--profile tools`)
- `devtools` - Development utilities container
- `pgadmin` - Database administration interface

### Extended Tools (`--profile dev-tools`)
- `mailhog` - Email testing
- `minio` - S3-compatible storage

### Testing (`--profile testing`)
- `test-runner` - Automated test runner

## Environment Configuration

### Backend Environment Variables
| Variable | Description | Default |
|----------|-------------|---------|
| `FLASK_ENV` | Flask environment | `development` |
| `FLASK_DEBUG` | Debug mode | `1` |
| `DATABASE_URL` | PostgreSQL connection | `postgresql://admin:dev_password_123@database:5432/infraprime` |
| `REDIS_URL` | Redis connection | `redis://redis:6379/0` |
| `SECRET_KEY` | Application secret | `dev-secret-key-change-in-production` |
| `API_VERSION` | API version | `1.0.0` |
| `ALLOWED_ORIGINS` | CORS origins | `http://localhost:3000,http://localhost:8080` |
| `LOG_LEVEL` | Logging level | `DEBUG` |

### Frontend Environment Variables
| Variable | Description | Default |
|----------|-------------|---------|
| `NODE_ENV` | Node environment | `development` |
| `REACT_APP_API_URL` | Backend API URL | `http://localhost:5000` |
| `REACT_APP_ENV` | Application environment | `development` |
| `CHOKIDAR_USEPOLLING` | File watching | `true` |

### Database Configuration
| Variable | Description | Default |
|----------|-------------|---------|
| `POSTGRES_DB` | Database name | `infraprime` |
| `POSTGRES_USER` | Database user | `admin` |
| `POSTGRES_PASSWORD` | Database password | `dev_password_123` |

## Monitoring and Logging

### Health Checks
```bash
# Check application health
curl http://localhost:8080/health

# Check individual services
curl http://localhost:5000/health
curl http://localhost:5000/api/stats
```

### Log Management
```bash
# View all logs
docker-compose logs -f

# View specific service logs
docker-compose logs -f backend
docker-compose logs -f frontend
docker-compose logs -f database

# View logs with timestamps
docker-compose logs -f -t backend

# Follow logs from specific time
docker-compose logs -f --since="2024-01-01T00:00:00" backend
```

### Metrics Collection
```bash
# Access Database Admin
open http://localhost:5050
# Default credentials: admin@infraprime.local / admin123
```

### Custom Monitoring
```bash
# Check container resource usage
docker stats

# Check container health
docker-compose ps

# Inspect container configuration
docker-compose config
```

## Backup and Recovery

### Database Backups
```bash
# Create database backup
docker-compose exec database pg_dump -U admin infraprime > backup_$(date +%Y%m%d_%H%M%S).sql

# Restore database from backup
docker-compose exec -T database psql -U admin -d infraprime < backup_20240101_120000.sql

# Automated backup script
./scripts/backup-database.sh
```

### Volume Backups
```bash
# Backup all volumes
docker run --rm -v infraprime_postgres_data:/data -v $(pwd):/backup alpine tar czf /backup/postgres_backup.tar.gz -C /data .

# Restore volumes
docker run --rm -v infraprime_postgres_data:/data -v $(pwd):/backup alpine tar xzf /backup/postgres_backup.tar.gz -C /data
```

### Application Data
```bash
# Backup application logs
docker-compose exec backend tar czf /app/logs/backup.tar.gz /app/logs/

# Backup configuration files
tar czf config_backup.tar.gz docker/nginx/conf.d/ docker/database/init/
```

## Troubleshooting

### Common Issues

#### 1. Port Conflicts
```bash
# Check what's using a port
netstat -tulpn | grep :5000
lsof -i :5000

# Change ports in docker-compose.yml
ports:
  - "5001:5000"  # Use port 5001 instead
```

#### 2. Permission Issues
```bash
# Fix file permissions
sudo chown -R $USER:$USER .

# Fix Docker socket permissions
sudo chmod 666 /var/run/docker.sock
```

#### 3. Database Connection Issues
```bash
# Check database health
docker-compose exec database pg_isready -U admin

# Check database logs
docker-compose logs database

# Restart database
docker-compose restart database
```

#### 4. Frontend Build Issues
```bash
# Clear node_modules and rebuild
docker-compose down
docker volume rm infraprime_frontend_node_modules
docker-compose up -d frontend

# Check frontend logs
docker-compose logs frontend
```

#### 5. Memory Issues
```bash
# Check Docker resource usage
docker system df
docker system prune

# Increase Docker Desktop memory limit
# Docker Desktop > Settings > Resources > Memory
```

### Debugging Commands

#### Container Inspection
```bash
# Inspect running container
docker-compose exec backend bash

# Check container environment
docker-compose exec backend env

# Check container processes
docker-compose exec backend ps aux
```

#### Network Debugging
```bash
# Check network connectivity
docker-compose exec backend ping database
docker-compose exec frontend ping backend

# Check DNS resolution
docker-compose exec backend nslookup database
```

#### Log Analysis
```bash
# Search logs for errors
docker-compose logs | grep -i error

# Count log entries
docker-compose logs backend | wc -l

# Export logs to file
docker-compose logs > application_logs.txt
```

### Performance Optimization

#### 1. Resource Limits
```yaml
# Set appropriate resource limits
services:
  backend:
    deploy:
      resources:
        limits:
          memory: 512M
          cpus: '0.5'
```

#### 2. Volume Optimization
```yaml
# Use named volumes for better performance
volumes:
  postgres_data:
    driver: local
    driver_opts:
      type: none
      o: bind
      device: /path/to/host/directory
```

#### 3. Image Optimization
```bash
# Use multi-stage builds
# Optimize Dockerfile layers
# Use .dockerignore to exclude unnecessary files
```

## Security and Maintenance

### Container Security
- Use non-root users in containers
- Scan images for vulnerabilities using Trivy
- Keep base images updated
- Use minimal base images (Alpine)

### Network Security
- Use internal Docker networks
- Limit exposed ports
- Use secrets management for sensitive data

### Data Security
- Encrypt sensitive data at rest
- Use environment variables for configuration
- Regular security scans and updates

### Manual Security Scanning
```bash
# Scan images for vulnerabilities
docker run --rm -v /var/run/docker.sock:/var/run/docker.sock \
  aquasec/trivy image infraprime-backend:latest

# Scan with specific severity levels
docker run --rm -v /var/run/docker.sock:/var/run/docker.sock \
  aquasec/trivy image --severity HIGH,CRITICAL infraprime-backend:latest
```

## Scaling and Load Balancing

### Horizontal Scaling
```bash
# Scale backend service
docker-compose up -d --scale backend=3

# Scale with load balancer
docker-compose up -d --scale backend=3 nginx
```

### Load Testing
```bash
# Install Apache Bench
sudo apt-get install apache2-utils

# Run load test
ab -n 1000 -c 10 http://localhost:8080/

# Test API endpoints
ab -n 500 -c 5 http://localhost:5000/api/data
```

## Maintenance

### Regular Tasks
- Update base images monthly
- Review and rotate secrets
- Monitor resource usage
- Clean up unused images and volumes

### Update Procedures
```bash
# Update application code
git pull origin main
docker-compose build
docker-compose up -d

# Update base images
docker-compose pull
docker-compose up -d
```

---

For additional help, see:
- [Docker Guide](DOCKER.md)
- [Troubleshooting Guide](TROUBLESHOOTING.md)
- [Security Documentation](SECURITY.md)