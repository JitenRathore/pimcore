# Automated Pimcore Setup

This Docker Compose configuration automatically installs and configures Pimcore 11 on first startup.

## What happens automatically:

1. **Database initialization** - MariaDB creates the pimcore database
2. **Dependency installation** - Composer installs all required packages
3. **Pimcore installation** - Runs pimcore-install with default credentials
4. **Permission setup** - Sets correct ownership for var/ and public/ directories
5. **Health checks** - Ensures all services are ready before starting dependent services

## Quick Start

```bash
# Start all services (first time will auto-install Pimcore)
docker compose up -d

# Watch the installation progress
docker compose logs -f php

# Once complete, access:
# - Frontend: http://localhost
# - Admin: http://localhost/admin
#   Username: admin
#   Password: admin
```

## Default Credentials

- **Admin Username**: admin
- **Admin Password**: admin
- **Database**: pimcore / pimcore / pimcore

**⚠️ Change these credentials after first login!**

## Services

- **nginx**: Web server (port 80)
- **php**: PHP 8.1 with Pimcore
- **db**: MariaDB 10.11
- **redis**: Redis cache

## Installation Time

First startup takes **5-10 minutes** depending on your system:
- Downloading images: 2-3 min
- Installing dependencies: 3-5 min
- Running Pimcore installer: 2-3 min

## Subsequent Startups

After initial installation, containers start in **10-15 seconds**.

## Troubleshooting

### Check installation progress
```bash
docker compose logs -f php
```

### Reinstall Pimcore
```bash
docker compose down -v  # WARNING: Deletes all data!
docker compose up -d
```

### Manual installation
If automatic installation fails, you can run manually:
```bash
docker compose exec php vendor/bin/pimcore-install \
  --mysql-host-socket=db \
  --mysql-username=pimcore \
  --mysql-password=pimcore \
  --mysql-database=pimcore \
  --admin-username=admin \
  --admin-password=admin \
  --no-interaction
```

### Fix permissions
```bash
docker compose exec --user=root php chown -R www-data:www-data /var/www/html/var /var/www/html/public
```

## Health Checks

All services have health checks:
- Database: Checks MySQL connection
- Redis: Pings Redis server
- PHP: Checks PHP-FPM status
- Nginx: Checks web server response

View health status:
```bash
docker compose ps
```

## Volumes

- `pimcore-app`: Application files and uploads
- `db-data`: Database storage

## Restart Policy

All containers use `unless-stopped` restart policy:
- Auto-restart on crash
- Auto-start on system reboot
- Manual stop prevents auto-restart
