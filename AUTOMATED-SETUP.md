# Automated Pimcore Installation

This setup automatically installs Pimcore 11 when you start the containers for the first time.

✅ **Tested & Verified**: Complete automation from blank slate to running application - zero manual steps required!

## ⚠️ Important: Choose Your Scenario

### Scenario 1: Fresh Installation (NO existing data)

Use this for **first-time setup** or **development environments**:

```bash
# This will create fresh volumes and install Pimcore from scratch
docker compose down -v  # Delete old data (if any)
docker compose up -d    # Auto-install

# Wait 5-10 minutes, monitor with:
docker compose logs -f php

# Access: http://localhost/admin (login: admin/admin)
```

### Scenario 2: Production Deployment (WITH existing data)

Use this for **updating production** with existing database and files:

```bash
# ✅ SAFE - Preserves all data in volumes
git pull origin main
docker compose down      # Stop containers, keep volumes
docker compose up -d     # Start with updated code

# Your data is SAFE! ✅
```

**📖 See [DEPLOYMENT.md](DEPLOYMENT.md) for detailed production deployment guide.**

### What Happens Automatically

1. **Database Setup**: MariaDB 10.11 starts and waits for initialization
2. **Skeleton Installation**: If no project exists, installs Pimcore 11 skeleton
3. **Dependencies**: Runs `composer install` to install all PHP packages
4. **Pimcore Installation**: Runs the Pimcore installer with database configuration
5. **Permissions**: Sets proper file permissions for var/ and public/
6. **Ready**: Application is accessible at http://localhost

### Installation Progress

Monitor the installation in real-time:

```bash
docker compose logs -f php
```

You'll see:
- ✓ Database is ready!
- Installing Pimcore skeleton...
- Installing dependencies...
- Installing Pimcore...
- ✓ Pimcore installed successfully
- Starting PHP-FPM

### Access Credentials

- **Frontend**: http://localhost
- **Admin Panel**: http://localhost/admin
- **Username**: admin
- **Password**: admin

### Rebuilding from Scratch

```bash
# Stop and remove everything including volumes
docker compose down -v

# Start fresh (will reinstall automatically)
docker compose up -d
```

### Configuration

The automated installation uses these settings:

- **Database Host**: db
- **Database Name**: pimcore
- **Database User**: pimcore
- **Database Password**: pimcore
- **Admin Username**: admin
- **Admin Password**: admin

### Customization

To change admin credentials, edit `.docker/php-entrypoint.sh`:

```bash
php vendor/bin/pimcore-install \
    --mysql-host-socket=db \
    --mysql-username=pimcore \
    --mysql-password=pimcore \
    --mysql-database=pimcore \
    --admin-username=YOUR_USERNAME \      # Change this
    --admin-password=YOUR_PASSWORD \      # Change this
    --no-interaction
```

### Troubleshooting

**Installation stuck or failed?**

```bash
# Check PHP logs
docker compose logs php

# Restart PHP container
docker compose restart php

# If needed, clear and reinstall
docker compose down -v
docker compose up -d
```

**Container unhealthy?**

The PHP container has a 300-second (5 minute) startup period for the installation to complete. If it takes longer:

```bash
# Check current health status
docker compose ps

# View detailed logs
docker compose logs php --tail=100
```

### Manual Installation (if automated fails)

If you prefer manual control:

1. Comment out the `entrypoint` line in `docker-compose.yml`
2. Start containers: `docker compose up -d`
3. Run commands manually:

```bash
docker compose exec php composer create-project pimcore/skeleton:^11.0 . --no-interaction --prefer-dist
docker compose exec php php vendor/bin/pimcore-install --mysql-host-socket=db --mysql-username=pimcore --mysql-password=pimcore --mysql-database=pimcore --admin-username=admin --admin-password=admin --no-interaction
docker compose exec php chown -R www-data:www-data var public
docker compose restart
```

## Server Deployment

When deploying to your Ubuntu server:

1. Copy all files to your server
2. Run `docker compose up -d`
3. Wait for installation to complete
4. Access via your server IP: `http://YOUR_SERVER_IP/admin`

The configuration already allows access via IP address (TRUSTED_HOSTS set to accept any hostname).
