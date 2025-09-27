# Contributing to InfraPrime

Thank you for your interest in contributing to InfraPrime! This document provides guidelines and information for contributors.

## 🚀 Getting Started

### Prerequisites
- Docker Desktop (v4.0+)
- Git
- Basic knowledge of Docker and containerization

### Development Setup
1. Fork the repository
2. Clone your fork:
   ```bash
   git clone https://github.com/yourusername/InfraPrime.git
   cd InfraPrime
   ```
3. Run the setup script:
   ```bash
   ./scripts/setup.sh
   ```
4. Start the development environment:
   ```bash
   ./scripts/docker-dev.sh start
   ```

## 📝 Development Guidelines

### Code Style
- **Python**: Follow PEP 8, use Black for formatting
- **JavaScript**: Follow ESLint configuration
- **Docker**: Use multi-stage builds, minimal base images
- **Documentation**: Update relevant docs for any changes

### Testing
- Write tests for new features
- Ensure all tests pass before submitting PR
- Run tests with: `./scripts/docker-dev.sh test`

### Docker Best Practices
- Use specific image tags (not `latest`)
- Create non-root users in containers
- Use `.dockerignore` files
- Optimize layer caching

## 🔄 Pull Request Process

1. Create a feature branch: `git checkout -b feature/amazing-feature`
2. Make your changes
3. Test your changes thoroughly
4. Update documentation if needed
5. Commit with descriptive messages
6. Push to your fork
7. Create a Pull Request

### PR Requirements
- [ ] Code follows style guidelines
- [ ] Tests pass
- [ ] Documentation updated
- [ ] Docker images build successfully
- [ ] No security vulnerabilities (run Trivy scan)

## 🐛 Bug Reports

When reporting bugs, please include:
- Clear description of the issue
- Steps to reproduce
- Expected vs actual behavior
- Environment details (OS, Docker version)
- Relevant logs

## 💡 Feature Requests

For feature requests:
- Describe the feature clearly
- Explain the use case
- Consider implementation complexity
- Check if it aligns with project goals

## 🔒 Security

- Report security issues privately to maintainers
- Don't include sensitive data in issues/PRs
- Follow security best practices in code

## 📚 Documentation

- Update README.md for major changes
- Add/update relevant docs in `docs/` directory
- Include code comments for complex logic
- Update API documentation if applicable

## 🏷️ Release Process

Releases are managed by maintainers. Version numbers follow semantic versioning.

## 🤝 Code of Conduct

- Be respectful and inclusive
- Focus on constructive feedback
- Help others learn and grow
- Follow professional communication standards

## 📞 Getting Help

- Check existing issues and discussions
- Review documentation in `docs/` directory
- Ask questions in issues (use appropriate labels)

## 🙏 Recognition

Contributors will be recognized in:
- CONTRIBUTORS.md file
- Release notes
- Project documentation

Thank you for contributing to InfraPrime! 🎉
