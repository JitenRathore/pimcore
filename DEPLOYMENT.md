# Safe Deployment Guide

## ⚠️ CRITICAL: Protecting Your Data

Your Pimcore data is stored in two places:
1. **Database** - In the `pimcore_db-data` Docker volume
2. **Files/Assets** - In the `pimcore_pimcore-app` Docker volume (under `/var/www/html/var` and `/var/www/html/public`)

## Safe Deployment Process

### For Existing Production Application (WITH DATA)

```bash
# 1. Pull latest code
git pull origin main

# 2. Stop containers (keeps volumes intact)
docker compose down

# 3. Start with updated code
docker compose up -d

# 4. Check logs to ensure everything started correctly
docker compose logs -f
```

**✅ SAFE**: This preserves all your data, database, and uploaded files.

### What NOT to Do on Production

```bash
# ❌ DANGER: This will DELETE ALL DATA
docker compose down -v

# ❌ DANGER: This will DELETE ALL DATA
docker volume rm pimcore_db-data pimcore_pimcore-app
```

The `-v` flag removes volumes, which means **permanent data loss**.

## Deployment Scenarios

### Scenario 1: Code/Configuration Updates Only
**What changed**: PHP code, templates, config files, Docker compose settings  
**Data impact**: None - your data is safe in volumes

```bash
git pull
docker compose down
docker compose up -d
```

### Scenario 2: Fresh Installation on New Server
**Use case**: First-time deployment with no existing data

```bash
git clone <your-repo>
cd pimcore
docker compose up -d
# Wait 5-10 minutes for automatic installation
```

### Scenario 3: Database Schema Changes
**Use case**: Pimcore version upgrade that requires migrations

```bash
git pull
docker compose down
docker compose up -d
# Wait for containers to start
docker compose exec php php bin/console doctrine:migrations:migrate --no-interaction
```

## Data Backup Before Deployment

### 1. Backup Database
```bash
# Create backup directory
mkdir -p backups

# Export database
docker compose exec db mysqldump -upimcore -ppimcore pimcore > backups/pimcore_backup_$(date +%Y%m%d_%H%M%S).sql

# Verify backup was created
ls -lh backups/
```

### 2. Backup Files/Assets
```bash
# Backup var directory (sessions, cache, logs, assets)
docker compose exec php tar -czf /tmp/var_backup.tar.gz /var/www/html/var
docker compose cp php:/tmp/var_backup.tar.gz backups/var_backup_$(date +%Y%m%d_%H%M%S).tar.gz

# Backup public directory (uploaded files, thumbnails)
docker compose exec php tar -czf /tmp/public_backup.tar.gz /var/www/html/public
docker compose cp php:/tmp/public_backup.tar.gz backups/public_backup_$(date +%Y%m%d_%H%M%S).tar.gz
```

### 3. Full Volume Backup (Alternative)
```bash
# Backup database volume
docker run --rm -v pimcore_db-data:/data -v $(pwd)/backups:/backup alpine tar -czf /backup/db_volume_$(date +%Y%m%d_%H%M%S).tar.gz -C /data .

# Backup application volume
docker run --rm -v pimcore_pimcore-app:/data -v $(pwd)/backups:/backup alpine tar -czf /backup/app_volume_$(date +%Y%m%d_%H%M%S).tar.gz -C /data .
```

## Restore from Backup

### Restore Database
```bash
# Copy backup into container
docker compose cp backups/pimcore_backup_YYYYMMDD_HHMMSS.sql php:/tmp/restore.sql

# Import database
docker compose exec db mysql -upimcore -ppimcore pimcore < /tmp/restore.sql
# Or from inside container:
docker compose exec php mysql -hdb -upimcore -ppimcore pimcore < /tmp/restore.sql
```

### Restore Files
```bash
# Restore var directory
docker compose cp backups/var_backup_YYYYMMDD_HHMMSS.tar.gz php:/tmp/var_backup.tar.gz
docker compose exec php tar -xzf /tmp/var_backup.tar.gz -C /

# Restore public directory
docker compose cp backups/public_backup_YYYYMMDD_HHMMSS.tar.gz php:/tmp/public_backup.tar.gz
docker compose exec php tar -xzf /tmp/public_backup.tar.gz -C /

# Fix permissions
docker compose exec php chown -R www-data:www-data /var/www/html/var /var/www/html/public
```

## Production Deployment Checklist

Before deploying to production:

- [ ] 1. **Backup database** (mysqldump)
- [ ] 2. **Backup files** (var/ and public/ directories)
- [ ] 3. **Test in staging** (if available)
- [ ] 4. **Pull latest code** (`git pull`)
- [ ] 5. **Stop containers** (`docker compose down` - NO `-v` flag!)
- [ ] 6. **Start containers** (`docker compose up -d`)
- [ ] 7. **Check logs** (`docker compose logs -f`)
- [ ] 8. **Verify application** (access admin panel)
- [ ] 9. **Test critical features** (login, content access)
- [ ] 10. **Monitor for errors** (check logs for 10-15 minutes)

## Rollback Plan

If something goes wrong:

```bash
# 1. Stop new version
docker compose down

# 2. Checkout previous working version
git log --oneline  # Find previous commit
git checkout <previous-commit-hash>

# 3. Start previous version
docker compose up -d

# 4. If needed, restore database backup
docker compose exec php mysql -hdb -upimcore -ppimcore pimcore < backups/pimcore_backup_YYYYMMDD_HHMMSS.sql
```

## Volume Management

### Check Volume Usage
```bash
# List volumes
docker volume ls

# Inspect volume
docker volume inspect pimcore_db-data
docker volume inspect pimcore_pimcore-app

# Check volume size
docker system df -v
```

### Copy Data Between Servers
```bash
# On source server - create backup
docker run --rm -v pimcore_db-data:/data -v $(pwd):/backup alpine tar -czf /backup/db-data.tar.gz -C /data .
docker run --rm -v pimcore_pimcore-app:/data -v $(pwd):/backup alpine tar -czf /backup/app-data.tar.gz -C /data .

# Transfer to new server (use scp, rsync, or cloud storage)
scp db-data.tar.gz app-data.tar.gz user@newserver:/path/to/pimcore/

# On destination server - restore backup
docker volume create pimcore_db-data
docker volume create pimcore_pimcore-app
docker run --rm -v pimcore_db-data:/data -v $(pwd):/backup alpine tar -xzf /backup/db-data.tar.gz -C /data
docker run --rm -v pimcore_pimcore-app:/data -v $(pwd):/backup alpine tar -xzf /backup/app-data.tar.gz -C /data
```

## Zero-Downtime Deployment (Advanced)

For production environments requiring zero downtime:

1. **Use Blue-Green Deployment**: Run two environments and switch traffic
2. **Use Docker Swarm or Kubernetes**: Rolling updates with health checks
3. **Use Load Balancer**: Route traffic away during updates

## Monitoring After Deployment

```bash
# Watch logs in real-time
docker compose logs -f

# Check container health
docker compose ps

# Monitor resource usage
docker stats

# Check PHP-FPM status
docker compose exec php php-fpm -t

# Check database connectivity
docker compose exec php php -r "new PDO('mysql:host=db', 'pimcore', 'pimcore');" && echo "DB OK"

# Check Symfony environment
docker compose exec php php bin/console about
```

## Common Issues and Solutions

### Issue: "Container exits immediately after deployment"
```bash
# Check logs
docker compose logs php

# Check entrypoint script permissions
docker compose exec php ls -la /usr/local/bin/custom-entrypoint.sh

# Manually test entrypoint
docker compose exec php sh /usr/local/bin/custom-entrypoint.sh
```

### Issue: "Permission denied errors"
```bash
# Fix permissions
docker compose exec php chown -R www-data:www-data /var/www/html/var /var/www/html/public
```

### Issue: "Database connection refused"
```bash
# Check if database is ready
docker compose exec db mysqladmin ping -h localhost -upimcore -ppimcore

# Restart database
docker compose restart db

# Wait for health check
docker compose ps
```

## Summary

✅ **SAFE for production with data**:
```bash
docker compose down
docker compose up -d
```

❌ **DANGEROUS - deletes all data**:
```bash
docker compose down -v  # Never use on production!
```

🔒 **Best practice**: Always backup before deployment!
