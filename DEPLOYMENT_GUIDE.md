# Pimcore 11 Deployment Guide for AWS EC2 Ubuntu

## Prerequisites on EC2 Ubuntu Instance
- Ubuntu 20.04 or 22.04 LTS
- Minimum 2GB RAM, 2 vCPUs recommended
- At least 10GB free disk space

## Installation Steps

### 1. Connect to your EC2 instance
```bash
ssh -i your-key.pem ubuntu@your-ec2-ip
```

### 2. Install Docker and Docker Compose
```bash
# Update system
sudo apt update && sudo apt upgrade -y

# Install Docker
sudo apt install -y docker.io
sudo systemctl start docker
sudo systemctl enable docker

# Add user to docker group
sudo usermod -aG docker $USER
newgrp docker

# Install Docker Compose
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
```

### 3. Upload and extract the deployment package
```bash
# On your local machine, upload the zip file
scp -i your-key.pem pimcore-deployment.zip ubuntu@your-ec2-ip:~/

# On EC2 instance
sudo apt install -y unzip
unzip pimcore-deployment.zip -d ~/pimcore
cd ~/pimcore
```

### 4. Configure Security Group
Open these ports in AWS EC2 Security Group:
- Port 80 (HTTP)
- Port 443 (HTTPS - optional, for SSL)
- Port 22 (SSH)

### 5. Start Pimcore
```bash
cd ~/pimcore
docker-compose up -d
```

### 6. Check containers are running
```bash
docker-compose ps
```

You should see 4 containers running:
- nginx
- php
- db (MariaDB)
- redis

### 7. Access Pimcore
- Frontend: http://your-ec2-public-ip/
- Admin Panel: http://your-ec2-public-ip/admin
  - Username: admin
  - Password: admin

**IMPORTANT:** Change the admin password immediately after first login!

## Post-Deployment Steps

### Change Admin Password
1. Login to http://your-ec2-public-ip/admin
2. Go to Settings → Users
3. Edit admin user and change password

### Set up Domain (Optional)
1. Point your domain DNS to EC2 public IP
2. Update nginx.conf with your domain name
3. Install SSL certificate (Let's Encrypt recommended)

### Backup Database
```bash
# Create backup
docker exec pimcore-db-1 mysqldump -u pimcore -ppimcore pimcore > backup.sql

# Restore backup
docker exec -i pimcore-db-1 mysql -u pimcore -ppimcore pimcore < backup.sql
```

## Useful Commands

### View Logs
```bash
docker-compose logs -f
docker-compose logs -f php    # PHP logs only
docker-compose logs -f nginx  # Nginx logs only
```

### Restart Services
```bash
docker-compose restart
docker-compose restart php    # Restart PHP only
```

### Stop Services
```bash
docker-compose stop
```

### Start Services
```bash
docker-compose start
```

### Update Pimcore
```bash
docker-compose exec php composer update
docker-compose exec php bin/console pimcore:deployment:classes-rebuild
docker-compose exec php bin/console cache:clear
```

## Troubleshooting

### Container won't start
```bash
docker-compose logs
docker ps -a
```

### Permission issues
```bash
docker exec pimcore-php-1 chown -R www-data:www-data /var/www/html/var
docker exec pimcore-php-1 chown -R www-data:www-data /var/www/html/public
```

### Clear cache
```bash
docker exec pimcore-php-1 bin/console cache:clear
```

### Database connection issues
Check database credentials in docker-compose.yml match the Pimcore configuration.

## Security Recommendations

1. ✅ Change default admin password immediately
2. ✅ Use strong passwords for database
3. ✅ Enable firewall (UFW)
4. ✅ Install SSL certificate
5. ✅ Keep Docker images updated
6. ✅ Regular backups
7. ✅ Restrict SSH access to specific IPs

## Performance Optimization

### Enable OPcache
Already configured in PHP container.

### Configure Redis Cache
Already configured and connected.

### Optimize Database
```bash
docker exec pimcore-db-1 mysql -u root -pROOT -e "OPTIMIZE TABLE pimcore.assets;"
```

## Files Included in Package

- `docker-compose.yml` - Container orchestration
- `nginx.conf` - Web server configuration
- All Pimcore application files in the volume

## Support

For Pimcore documentation: https://pimcore.com/docs/11.x/
For Docker issues: Check logs with `docker-compose logs`

---

**Deployment Package Created:** December 3, 2025
**Pimcore Version:** 11.0.4
**PHP Version:** 8.1
**Database:** MariaDB 10.11
