# Docker Development Guide

## Quick Start

1. **Start the full development environment:**
   ```bash
   docker-compose -f docker-compose.yml -f docker-compose.dev.yml up -d
   ```

2. **Start basic services only:**
   ```bash
   docker-compose up -d database redis
   ```

3. **View logs:**
   ```bash
   docker-compose logs -f backend frontend
   ```

## Service Profiles

### Core Services (default)
- `database` - PostgreSQL database
- `redis` - Redis cache
- `backend` - Flask API server
- `frontend` - Node.js development server
- `nginx` - Reverse proxy

### Development Tools Profile (`--profile tools`)
```bash
docker-compose --profile tools up -d
```
- `devtools` - Development utilities container
- `pgadmin` - Database administration interface

### Monitoring Profile (`--profile monitoring`)
```bash
docker-compose --profile monitoring up -d
```
- `pgadmin` - Database administration interface

### Extended Dev Tools (`--profile dev-tools`)
```bash
docker-compose -f docker-compose.yml -f docker-compose.dev.yml --profile dev-tools up -d
```
- `mailhog` - Email testing
- `minio` - S3-compatible storage

## Access Points

| Service | URL | Credentials |
|---------|-----|-------------|
| Frontend | http://localhost:3000 | - |
| Backend API | http://localhost:5000 | - |
| Nginx Proxy | http://localhost:8080 | - |
| Database | localhost:5432 | admin / dev_password_123 |
| Redis | localhost:6379 | - |
| pgAdmin | http://localhost:5050 | admin@infraprime.local / admin123 |
| MailHog | http://localhost:8025 | - |
| MinIO | http://localhost:9001 | minioadmin / minioadmin123 |

## Common Commands

### Development Workflow
```bash
# Start development environment
docker-compose -f docker-compose.yml -f docker-compose.dev.yml up -d

# Rebuild after code changes
docker-compose build backend frontend

# View service logs
docker-compose logs -f backend

# Execute commands in containers
docker-compose exec backend python -m flask shell
docker-compose exec database psql -U admin -d infraprime

# Stop services
docker-compose down

# Stop and remove volumes (clean slate)
docker-compose down -v
```

### Database Operations
```bash
# Connect to database
docker-compose exec database psql -U admin -d infraprime

# Run database migrations
docker-compose exec backend python -m flask db upgrade

# Backup database
docker-compose exec database pg_dump -U admin infraprime > backup.sql

# Restore database
docker-compose exec -T database psql -U admin -d infraprime < backup.sql
```

### SSL Certificate Generation (for HTTPS testing)
```bash
cd docker/nginx
chmod +x generate-ssl.sh
./generate-ssl.sh
```

## Environment Variables

### Backend
- `FLASK_ENV` - development/production
- `DATABASE_URL` - PostgreSQL connection string
- `REDIS_URL` - Redis connection string
- `SECRET_KEY` - Application secret key

### Frontend
- `NODE_ENV` - development/production
- `REACT_APP_API_URL` - Backend API URL
- `CHOKIDAR_USEPOLLING` - Enable file watching in containers

## Volume Mounts

### Development Mounts
- `./application/backend:/app` - Backend source code
- `./application/frontend:/app` - Frontend source code
- `./docker/nginx/conf.d:/etc/nginx/conf.d` - Nginx configuration

### Persistent Data
- `postgres_data` - Database files
- `redis_data` - Redis persistence
- `pgadmin_data` - Database administration settings

## Troubleshooting

### Common Issues

1. **Port conflicts:**
   ```bash
   # Check what's using a port
   netstat -tulpn | grep :5000
   
   # Change ports in docker-compose.yml if needed
   ```

2. **Permission issues:**
   ```bash
   # Fix file permissions
   sudo chown -R $USER:$USER .
   ```

3. **Database connection issues:**
   ```bash
   # Check database health
   docker-compose exec database pg_isready -U admin
   
   # Restart database
   docker-compose restart database
   ```

4. **Node modules issues:**
   ```bash
   # Remove and rebuild node_modules
   docker-compose down
   docker volume rm infraprime_frontend_node_modules
   docker-compose up -d frontend
   ```

### Log Locations
- Application logs: `docker-compose logs [service_name]`
- Nginx logs: `docker/logs/nginx/`
- Database logs: `docker-compose logs database`

### Performance Tips
1. Use Docker Desktop's resource limits appropriately
2. Enable Docker Desktop's experimental features for better performance
3. Consider using Docker volumes instead of bind mounts for node_modules
4. Use `--profile` flags to start only needed services
