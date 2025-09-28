# Docker Development Guide

## Quick Start

1. **Start the full development environment:**
   ```bash
   docker-compose -f docker-compose.yml -f docker-compose.dev.yml up --build -d
   ```

2. **Start basic services only:**
   ```bash
   docker-compose -f docker-compose.yml up -d database redis
   ```

3. **View logs:**
   ```bash
   docker-compose -f docker-compose.yml -f docker-compose.dev.yml logs -f backend frontend
   ```

4. **Check service status:**
   ```bash
   docker-compose -f docker-compose.yml -f docker-compose.dev.yml ps
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

### Core Services (Always Running)
| Service | URL | Credentials | Status |
|---------|-----|-------------|--------|
| **Frontend** | http://localhost:3000 | - | ✅ Active |
| **Backend API** | http://localhost:5000 | - | ✅ Active |
| **Nginx Proxy** | http://localhost:8080 | - | ✅ Active |
| **Database** | localhost:5432 | admin / dev_password_123 | ✅ Active |
| **Redis** | localhost:6379 | - | ✅ Active |

### Optional Services (Require Profiles)
| Service | URL | Credentials | Command to Start |
|---------|-----|-------------|------------------|
| **pgAdmin** | http://localhost:5050 | admin@infraprime.local / admin123 | `--profile tools` |
| **MailHog** | http://localhost:8025 | - | `--profile dev-tools` |
| **MinIO** | http://localhost:9001 | minioadmin / minioadmin123 | `--profile dev-tools` |
| **Trivy** | Container | Security scanner | `--profile security` |

> **Important:** The PostgreSQL database runs automatically with core services. pgAdmin is a web-based database administration tool that provides a GUI to manage the database - you only need it for database administration tasks like browsing tables, running SQL queries, or monitoring performance.

## 🔗 API Endpoints

### Backend API (Direct Access - http://localhost:5000)
| Endpoint | Method | Description |
|----------|--------|-------------|
| `/health` | GET | Health check and system status |
| `/api/data` | GET | Application data and server info |
| `/api/users` | GET | List all users |
| `/api/users` | POST | Create new user |
| `/api/stats` | GET | API usage statistics |
| `/api/test-db` | GET | Database connection test |

### Through Nginx Proxy (http://localhost:8080)
| Endpoint | Method | Description |
|----------|--------|-------------|
| `/api/*` | All | All backend API endpoints |
| `/health` | GET | Nginx health check |

## 🔒 Security Scanning

### Automated Security Scanning
```bash
# Start Trivy security scanner
docker-compose -f docker-compose.yml -f docker-compose.dev.yml --profile security up -d

# Run comprehensive security scan
./scripts/scan-security.sh

# Manual Trivy commands
docker-compose exec trivy trivy image infraprime-backend:latest
docker-compose exec trivy trivy image --severity HIGH,CRITICAL infraprime-backend:latest
docker-compose exec trivy trivy image --format json infraprime-backend:latest
```

### Security Scan Features
- **Vulnerability Detection**: Scans for known CVEs in base images and dependencies
- **Severity Filtering**: Focus on HIGH and CRITICAL vulnerabilities
- **Multiple Formats**: Table, JSON output for different use cases
- **CI/CD Ready**: Exit codes for automated security gates
- **Cached Results**: Faster subsequent scans with Trivy cache

## Common Commands

### Development Workflow
```bash
# Start development environment
docker-compose -f docker-compose.yml -f docker-compose.dev.yml up --build -d

# Rebuild after code changes
docker-compose -f docker-compose.yml -f docker-compose.dev.yml build backend frontend

# View service logs
docker-compose -f docker-compose.yml -f docker-compose.dev.yml logs -f backend

# Execute commands in containers
docker-compose -f docker-compose.yml -f docker-compose.dev.yml exec backend python src/app.py
docker-compose -f docker-compose.yml -f docker-compose.dev.yml exec database psql -U admin -d infraprime

# Stop services
docker-compose -f docker-compose.yml -f docker-compose.dev.yml down

# Stop and remove volumes (clean slate)
docker-compose -f docker-compose.yml -f docker-compose.dev.yml down -v
```

### Database Operations
```bash
# Connect to database
docker-compose -f docker-compose.yml -f docker-compose.dev.yml exec database psql -U admin -d infraprime

# Test database connection
docker-compose -f docker-compose.yml -f docker-compose.dev.yml exec database pg_isready -U admin

# Backup database
docker-compose -f docker-compose.yml -f docker-compose.dev.yml exec database pg_dump -U admin infraprime > backup.sql

# Restore database
docker-compose -f docker-compose.yml -f docker-compose.dev.yml exec -T database psql -U admin -d infraprime < backup.sql
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
