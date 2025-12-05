#!/bin/sh
set -e

echo "=== Starting Pimcore Auto-Setup ==="

# Wait for database
echo "Waiting for database..."
until php -r "new PDO('mysql:host=db;port=3306', 'pimcore', 'pimcore');" 2>/dev/null; do
    echo "Database not ready, waiting..."
    sleep 2
done
echo "✓ Database is ready!"

# Check if this is a fresh installation
if [ ! -f "/var/www/html/composer.json" ]; then
    echo "No project found. Installing Pimcore skeleton..."
    
    # Create project in temp directory
    composer create-project pimcore/skeleton:^11.0 /tmp/pimcore-skeleton --no-interaction --prefer-dist
    
    # Move files to working directory
    mv /tmp/pimcore-skeleton/* /tmp/pimcore-skeleton/.* /var/www/html/ 2>/dev/null || true
    rm -rf /tmp/pimcore-skeleton
    
    echo "✓ Pimcore skeleton installed"
fi

# Check if composer.json exists now
if [ -f "/var/www/html/composer.json" ]; then
    echo "✓ Project files found"
    
    # Install dependencies if vendor doesn't exist
    if [ ! -d "/var/www/html/vendor" ]; then
        echo "Installing dependencies..."
        composer install --no-interaction --optimize-autoloader --prefer-dist
        echo "✓ Dependencies installed"
    fi
    
    # Check if Pimcore needs installation
    if [ -f "/var/www/html/vendor/bin/pimcore-install" ]; then
        # Check if installation was already completed (var/installer directory exists after install)
        if [ ! -d "/var/www/html/var/installer" ]; then
            echo "Installing Pimcore..."
            
            # Remove lock file if it exists
            rm -f /var/www/html/var/config/needs-install.lock
            
            # Run Pimcore installation
            php vendor/bin/pimcore-install \
                --mysql-host-socket=db \
                --mysql-username=pimcore \
                --mysql-password=pimcore \
                --mysql-database=pimcore \
                --admin-username=admin \
                --admin-password=admin \
                --no-interaction || {
                echo "⚠ Installation command failed, but continuing..."
            }
            
            echo "✓ Pimcore installed successfully"
        else
            echo "✓ Pimcore already configured"
        fi
    fi
fi

# Set permissions
echo "Setting permissions..."
chown -R www-data:www-data /var/www/html/var /var/www/html/public 2>/dev/null || true

echo "=== Starting PHP-FPM ==="
exec docker-php-entrypoint php-fpm
