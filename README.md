# Pimcore Project - Developer Setup Guide

A comprehensive Pimcore 11 application built on Symfony framework for content and digital asset management.

## Table of Contents
- [Project Overview](#project-overview)
- [System Requirements](#system-requirements)
- [Quick Start with Docker](#quick-start-with-docker)
- [Local Development Setup](#local-development-setup)
- [Project Structure](#project-structure)
- [Configuration](#configuration)
- [Running Tests](#running-tests)
- [Useful Commands](#useful-commands)
- [Development Workflow](#development-workflow)
- [Troubleshooting](#troubleshooting)

---

## Project Overview

This is a Pimcore project skeleton designed for enterprise content management, digital asset management (DAM), and product information management (PIM). Built on:

- **Pimcore**: v11.x
- **PHP**: 8.1, 8.2, or 8.3
- **Symfony**: 6.2+
- **Database**: MariaDB 10.11
- **Cache**: Redis
- **Message Queue**: RabbitMQ

### Key Features
- Admin UI Classic Bundle for content management
- Quill Bundle for rich text editing
- Web2Print functionality
- Symfony Messenger with AMQP transport
- Codeception testing framework

---

## System Requirements

### For Docker Setup (Recommended)
- **Docker**: 20.10 or higher
- **Docker Compose**: 2.0 or higher
- **Disk Space**: Minimum 10GB free
- **RAM**: Minimum 4GB (8GB recommended)
- **OS**: Windows 10/11, macOS 10.15+, or Linux

### For Local Setup (Without Docker)
- **PHP**: 8.1, 8.2, or 8.3
- **Composer**: 2.0+
- **MariaDB/MySQL**: 10.3+ with utf8mb4 support
- **Redis**: Latest stable
- **Node.js**: 16+ (for asset building)
- **Web Server**: Nginx or Apache 2.4+
- **PHP Extensions**: 
  - pdo_mysql
  - redis
  - gd or imagick
  - intl
  - opcache
  - zip
  - mbstring
  - curl

---

## Quick Start with Docker

### Step 1: Clone the Repository
```bash
git clone <repository-url>
cd pimcore
```

### Step 2: Configure Docker User (Linux/macOS)
For Linux/macOS, set the correct user permissions:
```bash
sed -i "s|#user: '1000:1000'|user: '$(id -u):$(id -g)'|g" docker-compose.yaml
```

For Windows, you can skip this step.

### Step 3: Start Docker Services
```bash
docker compose up -d
```

This will start:
- **nginx**: Web server (port 80)
- **php**: PHP-FPM application server
- **db**: MariaDB database
- **redis**: Cache server
- **rabbitmq**: Message queue
- **supervisord**: Background job processor

### Step 4: Install Pimcore
```bash
docker compose exec php vendor/bin/pimcore-install
```

Follow the interactive prompts:
- **Admin username**: Choose your username (default: admin)
- **Admin password**: Choose a secure password
- **Installation**: Wait 10-20 minutes for completion

### Step 5: Access the Application
- **Frontend**: http://localhost
- **Admin Panel**: http://localhost/admin

---

## Local Development Setup

### Step 1: Install Dependencies
```bash
# Install Composer dependencies
composer install

# If you encounter memory issues
COMPOSER_MEMORY_LIMIT=-1 composer install
```

### Step 2: Configure Database
Create a `.env.local` file for local configuration:
```bash
cp .env .env.local
```

Edit `.env.local`:
```env
DATABASE_URL="mysql://pimcore:pimcore@127.0.0.1:3306/pimcore?serverVersion=10.11"
REDIS_HOST=127.0.0.1
RABBITMQ_HOST=127.0.0.1
```

### Step 3: Create Database
```bash
mysql -u root -p
CREATE DATABASE pimcore CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_520_ci;
CREATE USER 'pimcore'@'localhost' IDENTIFIED BY 'pimcore';
GRANT ALL PRIVILEGES ON pimcore.* TO 'pimcore'@'localhost';
FLUSH PRIVILEGES;
EXIT;
```

### Step 4: Install Pimcore
```bash
./vendor/bin/pimcore-install
```

### Step 5: Configure Web Server
Point your web server document root to `public/` directory.

**For Nginx**: Use the provided `nginx.conf` as reference
**For Apache**: Create `.htaccess` in `public/` directory

---

## Project Structure

```
pimcore/
├── bin/                    # Console commands
├── config/                 # Configuration files
│   ├── packages/          # Bundle configurations
│   ├── pimcore/           # Pimcore-specific config
│   ├── routes/            # Routing definitions
│   └── services.yaml      # Service container
├── public/                # Web root (document root)
│   ├── index.php         # Front controller
│   └── var/              # Public assets
├── src/                   # Application code
│   ├── Command/          # Console commands
│   ├── Controller/       # Controllers
│   ├── EventSubscriber/  # Event subscribers
│   └── Kernel.php        # Application kernel
├── templates/             # Twig templates
├── tests/                 # Test suites
│   ├── Functional/       # Functional tests
│   └── Unit/             # Unit tests
├── translations/          # Translation files
├── var/                   # Generated files
│   ├── cache/            # Application cache
│   ├── classes/          # Generated data object classes
│   ├── config/           # Runtime configuration
│   └── log/              # Log files
└── vendor/               # Composer dependencies
```

---

## Configuration

### Environment Variables
Create a `.env.local` file for environment-specific configuration:

```env
# Application Environment
APP_ENV=dev
APP_DEBUG=1

# Database
DATABASE_URL="mysql://user:password@host:3306/database?serverVersion=10.11"

# Redis Cache
REDIS_HOST=redis
REDIS_PORT=6379

# RabbitMQ
RABBITMQ_HOST=rabbitmq
RABBITMQ_PORT=5672

# Pimcore Admin
PIMCORE_ADMIN_URL=/admin
```

### Pimcore Configuration
- **Constants**: `config/pimcore/constants.php` (copy from `constants.example.php`)
- **System Settings**: Configured via admin panel at Settings → System Settings
- **Services**: `config/services.yaml`

---

## Running Tests

### Setup Test Environment
```bash
# With Docker
docker compose run --rm test-php vendor/bin/pimcore-install -n
docker compose run --rm test-php vendor/bin/codecept run -vv

# Without Docker
./vendor/bin/pimcore-install -n --env=test
./vendor/bin/codecept run -vv
```

### Run Specific Test Suites
```bash
# Unit tests only
./vendor/bin/codecept run Unit

# Functional tests only
./vendor/bin/codecept run Functional

# Run specific test
./vendor/bin/codecept run Unit ReadmeTest
```

---

## Useful Commands

### Pimcore Commands
```bash
# Clear cache
./bin/console cache:clear

# Rebuild classes
./bin/console pimcore:deployment:classes-rebuild

# Run maintenance
./bin/console pimcore:maintenance

# Create admin user
./bin/console pimcore:user:create <username> <password>

# Asset thumbnails generation
./bin/console pimcore:thumbnails:image
```

### Docker Commands
```bash
# View logs
docker compose logs -f php
docker compose logs -f nginx

# Access PHP container
docker compose exec php bash

# Restart services
docker compose restart

# Stop all services
docker compose down

# Stop and remove volumes (WARNING: deletes database)
docker compose down -v
```

### Database Commands
```bash
# Export database (Docker)
docker compose exec db mysqldump -u pimcore -ppimcore pimcore > backup.sql

# Import database (Docker)
docker compose exec -T db mysql -u pimcore -ppimcore pimcore < backup.sql

# Access database shell
docker compose exec db mysql -u pimcore -ppimcore pimcore
```

---

## Development Workflow

### 1. Working with Data Objects
Create data objects in the admin panel (Settings → Data Objects → Classes)

Generated classes will be in: `var/classes/DataObject/`

### 2. Creating Controllers
```bash
# Create new controller in src/Controller/
./bin/console make:controller YourController
```

### 3. Creating Templates
Templates go in `templates/` directory using Twig syntax.

### 4. Working with Assets
Upload assets via admin panel (Assets section)

Assets are stored in: `public/var/assets/`

### 5. Translations
Add translations in `translations/` directory:
- `messages.en.yaml`
- `admin.en.yaml`

### 6. Event Subscribers
Create event subscribers in `src/EventSubscriber/` to hook into Pimcore events.

---

## Troubleshooting

### Issue: Permission Denied Errors
```bash
# Fix permissions (Linux/macOS)
sudo chown -R www-data:www-data var/ public/var/
sudo chmod -R 775 var/ public/var/

# Docker
docker compose exec --user=root php chown -R www-data:www-data var/ public/var/
```

### Issue: Port 80 Already in Use
Edit `docker-compose.yaml` and change the port mapping:
```yaml
nginx:
  ports:
    - "8080:80"  # Changed from 80:80
```
Then access at http://localhost:8080

### Issue: Database Connection Failed
Check database is running:
```bash
docker compose ps db
docker compose logs db
```

### Issue: Composer Memory Limit
```bash
COMPOSER_MEMORY_LIMIT=-1 composer install
```

### Issue: Admin Panel Not Loading
1. Clear cache: `./bin/console cache:clear`
2. Check file permissions
3. Check PHP error logs: `var/log/`

### Getting Help
- **Documentation**: https://pimcore.com/docs/
- **GitHub Issues**: https://github.com/pimcore/pimcore/issues
- **Community**: https://github.com/pimcore/pimcore/discussions

---

## Additional Resources

- **Pimcore Platform Version**: [Platform Version Documentation](https://github.com/pimcore/platform-version)
- **Pimcore Demo**: [Basic Demo Project](https://github.com/pimcore/demo)
- **Deployment Guide**: See `DEPLOYMENT_GUIDE.md` for production deployment
- **Security**: See `SECURITY.md` for security policies

---

## License

This project is proprietary. See `LICENSE.md` for details.

---

**Happy Coding! 🚀**
