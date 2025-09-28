# InfraPrime - Quick Start Guide

## 🚀 One-Command Setup

```bash
# Clone and start the application
git clone https://github.com/yungkolt/InfraPrime.git
cd InfraPrime
docker-compose -f docker-compose.yml -f docker-compose.dev.yml up --build -d
```

## 🌐 Access Points

### Core Services (Always Available)
| Service | URL | Description | Status |
|---------|-----|-------------|--------|
| **Main Application** | http://localhost:8080 | Complete app via nginx proxy | ✅ Active |
| **Backend API** | http://localhost:5000 | Direct API access | ✅ Active |
| **Frontend** | http://localhost:3000 | Direct React dev server | ✅ Active |
| **Database** | localhost:5432 | PostgreSQL (admin/dev_password_123) | ✅ Active |
| **Redis** | localhost:6379 | Cache service | ✅ Active |

### Optional Services (Require Additional Commands)
| Service | URL | Description | Command |
|---------|-----|-------------|---------|
| **pgAdmin** | http://localhost:5050 | Database admin GUI (admin@infraprime.local/admin123) | `--profile tools` |
| **MailHog** | http://localhost:8025 | Email testing | `--profile dev-tools` |
| **MinIO** | http://localhost:9001 | S3 storage (minioadmin/minioadmin123) | `--profile dev-tools` |
| **Trivy** | Container | Security vulnerability scanner | `--profile security` |

> **Note:** The PostgreSQL database runs automatically with core services. pgAdmin is just a web interface to manage it - you only need it for database administration tasks.

## 🔧 Essential Commands

```bash
# Check status
docker-compose -f docker-compose.yml -f docker-compose.dev.yml ps

# View logs
docker-compose -f docker-compose.yml -f docker-compose.dev.yml logs -f

# Stop services
docker-compose -f docker-compose.yml -f docker-compose.dev.yml down

# Fresh start (if issues)
docker-compose -f docker-compose.yml -f docker-compose.dev.yml down -v
docker system prune -a
docker-compose -f docker-compose.yml -f docker-compose.dev.yml up --build -d
```

## 🛠️ Optional Services

```bash
# Start with database admin (pgAdmin)
docker-compose -f docker-compose.yml -f docker-compose.dev.yml --profile tools up -d

# Start with development tools (MailHog + MinIO)
docker-compose -f docker-compose.yml -f docker-compose.dev.yml --profile dev-tools up -d

# Start everything (core + optional)
docker-compose -f docker-compose.yml -f docker-compose.dev.yml --profile tools --profile dev-tools up -d

# Start security scanner
docker-compose -f docker-compose.yml -f docker-compose.dev.yml --profile security up -d

# Run security scan
./scripts/scan-security.sh
```

## 🧪 Test the Application

```bash
# Test main application
curl http://localhost:8080

# Test API health
curl http://localhost:5000/health

# Test API data endpoint
curl http://localhost:8080/api/data
```

## 🔗 Available API Endpoints

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

## 🛠️ Troubleshooting

### If ports aren't accessible:
1. Check Windows firewall settings
2. Restart Docker Desktop
3. Use http://localhost:8080 as main entry point

### If build fails:
1. Run complete cleanup: `docker system prune -a`
2. Rebuild: `docker-compose -f docker-compose.yml -f docker-compose.dev.yml up --build -d`

### If services won't start:
1. Check logs: `docker-compose -f docker-compose.yml -f docker-compose.dev.yml logs`
2. Verify Docker is running: `docker info`

## 📚 Full Documentation

- [Complete README](README.md)
- [Docker Guide](docs/DOCKER.md)
- [Troubleshooting](docs/TROUBLESHOOTING.md)
- [Deployment Guide](docs/DEPLOYMENT.md)

---

**Ready to go in under 2 minutes!** 🎉
