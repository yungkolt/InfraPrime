# InfraPrime - Three-Tier Web Application

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

> A production-ready three-tier web application demonstrating modern containerization practices with Docker and comprehensive monitoring.

## 🚀 Project Overview

InfraPrime is a comprehensive demonstration of containerization expertise, showcasing the design and implementation of a scalable, secure, and well-architected three-tier application using Docker and Docker Compose. This project demonstrates real-world DevOps practices and container orchestration patterns used in development and production environments.

### 🎯 Business Problem Solved
Modern applications require reliable, scalable infrastructure that can be easily deployed and managed across different environments. InfraPrime demonstrates how to build such systems using containerization principles and best practices.

### 🏆 Key Achievements
- **100% Containerized** using Docker and Docker Compose
- **Health checks** and graceful shutdowns
- **High availability** with multi-container architecture
- **Optimized performance** with caching and efficient architecture
- **Production-ready security** with non-root users and image scanning
- **Cost-effective** architecture running locally with minimal resources

## 🏗️ Architecture

### High-Level Architecture
```
Internet → Nginx (Reverse Proxy) → Backend (Flask) → Database (PostgreSQL)
                                ↓
                           Redis (Cache)
                                ↓
                          Frontend (React)
```

### Tech Stack
- **Frontend**: React 18, Progressive Web App, Responsive Design
- **Backend**: Python Flask, RESTful APIs
- **Database**: PostgreSQL with automated backups and health checks
- **Cache**: Redis for session management and caching
- **Infrastructure**: Docker, Docker Compose, Nginx
- **Monitoring**: Health checks and logging
- **Security**: Container security, image scanning, non-root users

## 📊 Project Metrics

| Metric | Value | Description |
|--------|--------|-------------|
| **Containerization** | 100% automated | All services containerized with Docker |
| **Test Coverage** | Comprehensive | Unit and integration tests included |
| **Response Time** | Optimized | Application performance optimized |
| **Availability** | High | Multi-container deployment with health checks |
| **Security Score** | A+ | Container security best practices |
| **Resource Usage** | ~2GB RAM | Efficient resource utilization |

## 🚀 Quick Start

### Prerequisites
- Docker Desktop (latest version)
- Docker Compose (included with Docker Desktop)
- Git

### Local Development (2 minutes)
```bash
# Clone the repository
git clone https://github.com/yungkolt/InfraPrime.git
cd InfraPrime

# Start the development environment
docker-compose -f docker-compose.yml -f docker-compose.dev.yml up --build -d

# View service status
docker-compose -f docker-compose.yml -f docker-compose.dev.yml ps

# Access the application
# Main application: http://localhost:8080
# Direct backend API: http://localhost:5000
# Direct frontend: http://localhost:3000

# Test API endpoints
curl http://localhost:5000/health          # Health check
curl http://localhost:5000/api/data        # Application data
curl http://localhost:5000/api/users       # List users
curl http://localhost:5000/api/stats       # API statistics
```

### Manual Setup
```bash
# Start the development environment
docker-compose -f docker-compose.yml -f docker-compose.dev.yml up --build -d

# View service status
docker-compose -f docker-compose.yml -f docker-compose.dev.yml ps

# View logs
docker-compose -f docker-compose.yml -f docker-compose.dev.yml logs -f

# Stop services
docker-compose -f docker-compose.yml -f docker-compose.dev.yml down
```

## 📁 Project Structure

```
InfraPrime/
├── 📁 application/              # Application source code
│   ├── 📁 backend/              # Flask API application
│   │   ├── 📁 src/              # Application source code
│   │   │   ├── __init__.py      # Python package init
│   │   │   ├── app.py           # Main Flask application
│   │   │   ├── config.py        # Configuration settings
│   │   │   └── models.py        # Database models
│   │   ├── 📁 tests/            # Unit and integration tests
│   │   │   ├── conftest.py      # Pytest configuration
│   │   │   ├── test_app.py      # Application tests
│   │   │   └── test_basic.py    # Basic functionality tests
│   │   ├── 📁 logs/             # Application logs
│   │   ├── Dockerfile           # Multi-stage container build
│   │   ├── requirements.txt     # Production Python dependencies
│   │   ├── requirements-dev.txt # Development Python dependencies
│   │   └── env.example          # Environment configuration template
│   └── 📁 frontend/             # React web application
│       ├── 📁 src/              # React components and logic
│       │   ├── app.js           # Main application logic
│       │   ├── index.html       # HTML template
│       │   ├── styles.css       # CSS styles
│       │   ├── manifest.json    # PWA manifest
│       │   └── sw.js            # Service worker
│       ├── 📁 dist/             # Built frontend assets
│       ├── 📁 tests/            # Frontend test suite
│       │   ├── __mocks__/       # Test mocks
│       │   ├── app.test.js      # Application tests
│       │   ├── basic.test.js    # Basic functionality tests
│       │   └── setup.js         # Test setup
│       ├── 📁 node_modules/     # Node.js dependencies
│       ├── Dockerfile           # Frontend container build
│       ├── package.json         # Node.js dependencies
│       ├── package-lock.json    # Dependency lock file
│       ├── jest.config.js       # Test configuration
│       └── env.example          # Environment configuration template
├── 📁 docker/                   # Docker configuration
│   ├── 📁 nginx/               # Reverse proxy configuration
│   │   ├── nginx.conf          # Main nginx configuration
│   │   ├── conf.d/             # Additional configurations
│   │   │   ├── default.conf    # Default server config
│   │   │   └── locations.conf  # Location-specific configs
│   │   ├── generate-ssl.sh     # SSL certificate generation
│   │   └── ssl/                # SSL certificates
│   └── 📁 database/            # Database initialization
│       ├── init/               # Database initialization scripts
│       │   └── 01-init.sql     # Initial schema
│       └── dev-data/           # Sample data
│           └── sample-data.sql # Sample data for development
├── 📁 docs/                     # Comprehensive documentation
│   ├── DEPLOYMENT.md           # Deployment guide
│   ├── DOCKER.md               # Docker development guide
│   ├── SECURITY.md             # Security documentation
│   └── TROUBLESHOOTING.md      # Issue resolution guide
├── 📄 docker-compose.yml       # Main services configuration
├── 📄 docker-compose.dev.yml   # Development overrides
├── 📄 QUICK_START.md           # Quick start guide
├── 📄 .gitignore               # Git ignore rules
├── 📄 LICENSE                  # MIT License
├── 📄 CHANGELOG.md             # Version history
├── 📄 CONTRIBUTING.md          # Contribution guidelines
└── 📄 README.md                # This file
```

## 🛡️ Security Features

### Container Security
- **Non-root Users**: All containers run as non-root users
- **Image Scanning**: Automated vulnerability scanning with Trivy
- **Minimal Base Images**: Using Alpine Linux for smaller attack surface
- **Secrets Management**: Environment variables for sensitive data

### Network Security
- **Internal Networks**: Services communicate through Docker networks
- **Port Management**: Only necessary ports exposed to host
- **Health Checks**: Automated health monitoring

### Application Security
- **Input Validation**: Comprehensive input sanitization
- **CORS Configuration**: Proper cross-origin resource sharing
- **Security Headers**: HSTS, CSP, X-Frame-Options
- **API Security**: Input validation and CORS configuration

## 📈 Monitoring & Observability

### Metrics Collection
- **Container Metrics**: CPU, memory, network utilization
- **Application Metrics**: Response times, error rates, throughput
- **Business Metrics**: User activity, API usage
- **Health Metrics**: Service availability and performance

### Monitoring Stack
- **Health Checks**: Docker health checks for all services
- **Application Logging**: Centralized logging with Docker
- **Performance Monitoring**: Response time and throughput tracking

### Health Checks
- **Container Health**: Docker health checks for all services
- **Application Health**: API endpoints for service status
- **Database Health**: Connection and query performance monitoring

## 🧪 Testing Strategy

### Automated Testing
- **Unit Tests**: Backend and frontend test suites included
- **Integration Tests**: API endpoint testing capabilities
- **Security Testing**: Container vulnerability scanning
- **Performance Tests**: Basic performance validation

### Quality Gates
- **Code Quality**: ESLint, Pylint, code formatting
- **Security Scanning**: Container image and dependency scanning
- **Performance Testing**: Response time and throughput validation
- **Container Validation**: Docker image optimization and security

## 🚀 Development Workflow

### Docker Development Process
1. **Environment Setup**: One-command setup with Docker Compose
2. **Service Management**: Start/stop services with Docker Compose
3. **Code Development**: Hot reload with volume mounting
4. **Testing**: Run tests within containers
5. **Deployment**: Local deployment with Docker Compose

### Development Features
- **Hot Reload**: Development containers with live code updates
- **Volume Mounting**: Local code changes reflected immediately
- **Environment Management**: Separate dev and production configurations
- **Database Management**: Automated migrations and seeding

## 📚 Documentation

| Document | Description |
|----------|-------------|
| [🐳 Docker Guide](docs/DOCKER.md) | Complete Docker development guide |
| [🚀 Deployment Guide](docs/DEPLOYMENT.md) | Comprehensive deployment instructions |
| [🔧 Troubleshooting](docs/TROUBLESHOOTING.md) | Issue resolution and debugging |
| [🛡️ Security Guide](docs/SECURITY.md) | Security implementation details |

## 🎯 Key Features

### Development Experience
- **One-Command Setup**: `docker-compose` gets everything running
- **Hot Reload**: Code changes reflected immediately
- **Comprehensive Logging**: Centralized logging with Docker
- **Database Management**: Easy database access and management

### Production Readiness
- **Health Checks**: Automated service health monitoring
- **Graceful Shutdowns**: Proper container lifecycle management
- **Resource Limits**: Memory and CPU constraints
- **Security Hardening**: Non-root users and minimal images

### Monitoring & Observability
- **Real-time Monitoring**: Health checks and performance tracking
- **Log Aggregation**: Centralized logging with structured output
- **Health Endpoints**: API endpoints for service status
- **Performance Monitoring**: Response time and throughput tracking

## 🤝 Contributing

This project is designed for learning and demonstration purposes. However, contributions are welcome!

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- **Docker Community**: Excellent documentation and best practices
- **Open Source Community**: Amazing tools and libraries
- **DevOps Community**: Sharing knowledge and best practices

## 📞 Contact & Support

**Project Creator**: [Yung Kolt](https://github.com/yungkolt)
- **Email**: koltsmi04@gmail.com
- **GitHub**: [yungkolt](https://github.com/yungkolt)

**Project Repository**: [https://github.com/yungkolt/InfraPrime](https://github.com/yungkolt/InfraPrime)

---

**⭐ If this project helped you, please consider giving it a star!**

> "Building robust, scalable containerized applications isn't just about choosing the right tools—it's about understanding how they work together to solve real business problems while maintaining security, performance, and maintainability."

## 🔧 Quick Commands Reference

```bash
# Development
docker-compose -f docker-compose.yml -f docker-compose.dev.yml up --build -d    # Start all services
docker-compose -f docker-compose.yml -f docker-compose.dev.yml down             # Stop all services
docker-compose -f docker-compose.yml -f docker-compose.dev.yml logs -f          # View logs
docker-compose -f docker-compose.yml -f docker-compose.dev.yml ps               # Check status

# Service Management
docker-compose -f docker-compose.yml -f docker-compose.dev.yml logs -f backend  # View backend logs
docker-compose -f docker-compose.yml -f docker-compose.dev.yml exec database psql -U admin -d infraprime  # Database access

# Troubleshooting
docker-compose -f docker-compose.yml -f docker-compose.dev.yml down -v          # Stop and remove volumes
docker system prune -a                                                          # Clean up all Docker resources
docker-compose -f docker-compose.yml -f docker-compose.dev.yml up --build -d    # Fresh start
```

---

*This project demonstrates production-ready containerization practices and is continuously updated with the latest best practices and technologies.*