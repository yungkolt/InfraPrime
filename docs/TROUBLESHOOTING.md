# InfraPrime Docker Troubleshooting Guide

## Table of Contents
1. [Common Issues](#common-issues)
2. [Docker Problems](#docker-problems)
3. [Application Issues](#application-issues)
4. [Database Problems](#database-problems)
5. [Networking Issues](#networking-issues)
6. [Performance Problems](#performance-problems)
7. [Debugging Tools](#debugging-tools)
8. [Log Analysis](#log-analysis)

## Common Issues

### 1. Docker Not Running
**Problem**: `Cannot connect to the Docker daemon`

**Solutions**:
```bash
# Start Docker Desktop
# On Windows: Start Docker Desktop application
# On macOS: Start Docker Desktop application
# On Linux: sudo systemctl start docker

# Check Docker status
docker info

# Restart Docker service (Linux)
sudo systemctl restart docker
```

### 2. Port Already in Use
**Problem**: `Bind for 0.0.0.0:5000 failed: port is already allocated`

**Solutions**:
```bash
# Check what's using the port
netstat -tulpn | grep :5000
lsof -i :5000

# Kill the process using the port
sudo kill -9 <PID>

# Or change the port in docker-compose.yml
ports:
  - "5001:5000"  # Use port 5001 instead
```

### 3. Permission Denied Errors
**Problem**: `Permission denied` when accessing files or Docker

**Solutions**:
```bash
# Fix file permissions
sudo chown -R $USER:$USER .

# Fix Docker socket permissions (Linux)
sudo chmod 666 /var/run/docker.sock

# Add user to docker group (Linux)
sudo usermod -aG docker $USER
# Log out and back in
```

## Docker Problems

### 1. Container Won't Start
**Problem**: Container exits immediately or fails to start

**Solutions**:
```bash
# Check container logs
docker-compose logs <service-name>

# Check container status
docker-compose ps

# Inspect container
docker-compose exec <service-name> bash

# Check if image exists
docker images | grep infraprime

# Rebuild image
docker-compose build <service-name>
```

### 2. Image Build Failures
**Problem**: `docker build` fails with errors

**Solutions**:
```bash
# Check Dockerfile syntax
docker build --no-cache -t test-image .

# Check for syntax errors
docker build --progress=plain .

# Clean build cache
docker builder prune

# Check disk space
df -h
docker system df
```

### 3. Volume Mount Issues
**Problem**: Files not syncing between host and container

**Solutions**:
```bash
# Check volume mounts
docker-compose config

# Verify file permissions
ls -la application/backend/

# Check if volume exists
docker volume ls

# Recreate volumes
docker-compose down -v
docker-compose up -d
```

## Application Issues

### 1. Backend API Not Responding
**Problem**: API calls return connection refused or timeout

**Solutions**:
```bash
# Check if backend is running
docker-compose ps backend

# Check backend logs
docker-compose logs backend

# Test backend directly
curl http://localhost:5000/health

# Check if port is exposed
docker-compose port backend 5000

# Restart backend
docker-compose restart backend
```

### 2. Frontend Not Loading
**Problem**: Frontend shows blank page or connection errors

**Solutions**:
```bash
# Check frontend logs
docker-compose logs frontend

# Check if frontend is built
docker-compose exec frontend ls -la /app

# Rebuild frontend
docker-compose build frontend

# Check API URL configuration
docker-compose exec frontend env | grep REACT_APP
```

### 3. Database Connection Issues
**Problem**: Backend can't connect to database

**Solutions**:
```bash
# Check database status
docker-compose ps database

# Check database logs
docker-compose logs database

# Test database connection
docker-compose exec database pg_isready -U admin

# Check network connectivity
docker-compose exec backend ping database

# Verify database URL
docker-compose exec backend env | grep DATABASE_URL
```

## Database Problems

### 1. Database Won't Start
**Problem**: PostgreSQL container fails to start

**Solutions**:
```bash
# Check database logs
docker-compose logs database

# Check if port is available
netstat -tulpn | grep :5432

# Check volume permissions
ls -la postgres_data/

# Remove corrupted volume
docker-compose down -v
docker volume rm infraprime_postgres_data
docker-compose up -d database
```

### 2. Database Connection Refused
**Problem**: `connection refused` when connecting to database

**Solutions**:
```bash
# Check if database is ready
docker-compose exec database pg_isready -U admin

# Check database configuration
docker-compose exec database cat /var/lib/postgresql/data/postgresql.conf

# Restart database
docker-compose restart database

# Check network
docker network ls
docker network inspect infraprime_infraprime-network
```

### 3. Data Loss or Corruption
**Problem**: Database data is missing or corrupted

**Solutions**:
```bash
# Check if volume exists
docker volume ls | grep postgres

# Backup current data
docker-compose exec database pg_dump -U admin infraprime > backup.sql

# Restore from backup
docker-compose exec -T database psql -U admin -d infraprime < backup.sql

# Reset database (WARNING: Data loss)
docker-compose down -v
docker-compose up -d database
```

## Networking Issues

### 1. Services Can't Communicate
**Problem**: Containers can't reach each other

**Solutions**:
```bash
# Check network configuration
docker network ls
docker network inspect infraprime_infraprime-network

# Test connectivity
docker-compose exec backend ping database
docker-compose exec frontend ping backend

# Recreate network
docker-compose down
docker network prune
docker-compose up -d
```

### 2. External Access Issues
**Problem**: Can't access application from browser

**Solutions**:
```bash
# Check if ports are exposed
docker-compose ps

# Test local connectivity
curl http://localhost:8080
curl http://localhost:5000/health

# Check firewall settings
sudo ufw status
sudo iptables -L

# Check Docker port mapping
docker port infraprime-nginx
```

### 3. DNS Resolution Problems
**Problem**: Containers can't resolve service names

**Solutions**:
```bash
# Check DNS resolution
docker-compose exec backend nslookup database
docker-compose exec backend nslookup redis

# Check /etc/hosts
docker-compose exec backend cat /etc/hosts

# Restart with clean network
docker-compose down
docker network prune
docker-compose up -d
```

## Performance Problems

### 1. Slow Application Response
**Problem**: Application is slow or unresponsive

**Solutions**:
```bash
# Check resource usage
docker stats

# Check container limits
docker-compose exec backend cat /sys/fs/cgroup/memory/memory.limit_in_bytes

# Monitor logs for errors
docker-compose logs | grep -i error

# Check database performance
docker-compose exec database psql -U admin -d infraprime -c "SELECT * FROM pg_stat_activity;"
```

### 2. High Memory Usage
**Problem**: Containers using too much memory

**Solutions**:
```bash
# Check memory usage
docker stats --no-stream

# Set memory limits
# In docker-compose.yml:
services:
  backend:
    deploy:
      resources:
        limits:
          memory: 512M

# Restart with limits
docker-compose up -d
```

### 3. Disk Space Issues
**Problem**: Running out of disk space

**Solutions**:
```bash
# Check disk usage
df -h
docker system df

# Clean up unused resources
docker system prune -a

# Remove unused volumes
docker volume prune

# Clean up logs
docker-compose logs --tail=0 -f | head -n 0
```

## Debugging Tools

### 1. Container Inspection
```bash
# Enter running container
docker-compose exec backend bash
docker-compose exec frontend sh

# Check container environment
docker-compose exec backend env

# Check container processes
docker-compose exec backend ps aux

# Check container network
docker-compose exec backend ip addr
```

### 2. Log Analysis
```bash
# View all logs
docker-compose logs

# View specific service logs
docker-compose logs backend
docker-compose logs frontend

# Follow logs in real-time
docker-compose logs -f backend

# View logs with timestamps
docker-compose logs -t backend

# Search logs for specific text
docker-compose logs | grep -i error
docker-compose logs | grep -i "connection refused"
```

### 3. Network Debugging
```bash
# Check network configuration
docker network inspect infraprime_infraprime-network

# Test connectivity between services
docker-compose exec backend ping database
docker-compose exec backend telnet database 5432

# Check port mappings
docker-compose port backend 5000
docker-compose port nginx 80
```

### 4. Health Checks
```bash
# Check service health
docker-compose ps

# Test health endpoints
curl http://localhost:8080/health
curl http://localhost:5000/health

# Check individual service health
docker-compose exec backend curl localhost:5000/health
docker-compose exec database pg_isready -U admin
```

## Log Analysis

### 1. Common Log Patterns

#### Backend Logs
```bash
# Application errors
docker-compose logs backend | grep -i error

# Database connection issues
docker-compose logs backend | grep -i "database\|postgres"

# API request logs
docker-compose logs backend | grep -i "GET\|POST\|PUT\|DELETE"
```

#### Frontend Logs
```bash
# Build errors
docker-compose logs frontend | grep -i "error\|failed"

# Network errors
docker-compose logs frontend | grep -i "network\|connection"

# Module errors
docker-compose logs frontend | grep -i "module\|import"
```

#### Database Logs
```bash
# Connection errors
docker-compose logs database | grep -i "connection\|refused"

# Query errors
docker-compose logs database | grep -i "error\|failed"

# Startup issues
docker-compose logs database | grep -i "startup\|init"
```

### 2. Log Monitoring
```bash
# Monitor logs in real-time
docker-compose logs -f | tee application.log

# Filter logs by service and level
docker-compose logs backend | grep -E "(ERROR|WARN|INFO)"

# Export logs to file
docker-compose logs > full_logs_$(date +%Y%m%d_%H%M%S).log
```

## Quick Fixes

### 1. Complete Reset
```bash
# Stop and remove everything
docker-compose down -v
docker system prune -a

# Rebuild and start
docker-compose build
docker-compose up -d
```

### 2. Service-Specific Reset
```bash
# Reset specific service
docker-compose stop backend
docker-compose rm -f backend
docker-compose up -d backend
```

### 3. Volume Reset
```bash
# Reset database
docker-compose down
docker volume rm infraprime_postgres_data
docker-compose up -d database
```

## Getting Help

### 1. Collect Information
```bash
# System information
docker version
docker-compose version
docker system info

# Service status
docker-compose ps
docker-compose logs --tail=50

# Resource usage
docker stats --no-stream
```

### 2. Common Commands for Support
```bash
# Full system report
docker-compose logs > logs.txt
docker-compose ps > status.txt
docker system info > system.txt

# Create support bundle
tar -czf support_bundle.tar.gz logs.txt status.txt system.txt
```

### 3. Documentation References
- [Docker Documentation](https://docs.docker.com/)
- [Docker Compose Documentation](https://docs.docker.com/compose/)
- [PostgreSQL Documentation](https://www.postgresql.org/docs/)
- [React Documentation](https://reactjs.org/docs/)

---

For additional help:
- Check the [Docker Guide](DOCKER.md)
- Review the [Deployment Guide](DEPLOYMENT.md)
- See the [Security Documentation](SECURITY.md)