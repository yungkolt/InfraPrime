# InfraPrime - Quick Start Guide

## 🚀 One-Command Setup

```bash
# Clone and start the application
git clone https://github.com/yungkolt/InfraPrime.git
cd InfraPrime
docker-compose -f docker-compose.yml -f docker-compose.dev.yml up --build -d
```

## 🌐 Access Points

| Service | URL | Description |
|---------|-----|-------------|
| **Main Application** | http://localhost:8080 | Complete app via nginx proxy |
| **Backend API** | http://localhost:5000 | Direct API access |
| **Frontend** | http://localhost:3000 | Direct React dev server |
| **Database** | localhost:5432 | PostgreSQL (admin/dev_password_123) |
| **Redis** | localhost:6379 | Cache service |

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

## 🧪 Test the Application

```bash
# Test main application
curl http://localhost:8080

# Test API health
curl http://localhost:5000/health

# Test API data endpoint
curl http://localhost:8080/api/data
```

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
