#!/bin/bash

DB_NAME="myapp"
DB_USER="appuser"
DB_PASSWORD="dbuser123"
DB_PORT="5000"

echo "Starting MySQL setup..."

# Check if MySQL is already running on the specified port
if sudo mysqladmin ping --socket=/var/run/mysqld/mysqld.sock --silent 2>/dev/null; then
    echo "MySQL is already running!"
    
    # Try to verify the database exists
    if sudo mysql --socket=/var/run/mysqld/mysqld.sock -e "USE ${DB_NAME};" 2>/dev/null; then
        echo "Database ${DB_NAME} is accessible."
    fi
    
    echo ""
    echo "Database: ${DB_NAME}"
    echo "Root user: root (password: ${DB_PASSWORD})"
    echo "App user: appuser (password: ${DB_PASSWORD})"
    echo "Port: ${DB_PORT}"
    echo ""
    
    # Check if connection info file exists
    if [ -f "db_connection.txt" ]; then
        echo "To connect to the database, use:"
        echo "$(cat db_connection.txt)"
    else
        echo "To connect to the database, use:"
        echo "mysql -u root -p${DB_PASSWORD} -h localhost -P ${DB_PORT} ${DB_NAME}"
    fi
    
    echo ""
    echo "Script stopped - MySQL server already running."
    exit 0
fi

# Check if there's a MySQL process running on the specified port
if pgrep -f "mysqld.*--port=${DB_PORT}" > /dev/null 2>&1; then
    echo "Found existing MySQL process on port ${DB_PORT}"
    echo "Attempting to verify connection..."
    
    # Try to connect via TCP
    if mysql -u root -p${DB_PASSWORD} -h 127.0.0.1 -P ${DB_PORT} -e "SELECT 1;" 2>/dev/null; then
        echo "MySQL is accessible on port ${DB_PORT}."
        echo "Script stopped - server already running."
        exit 0
    fi
fi

# Check if MySQL is running on default socket but different port
if [ -S /var/run/mysqld/mysqld.sock ]; then
    echo "Found MySQL socket, checking if it's using port ${DB_PORT}..."
    CURRENT_PORT=$(sudo mysql --socket=/var/run/mysqld/mysqld.sock -e "SHOW VARIABLES LIKE 'port';" 2>/dev/null | grep port | awk '{print $2}')
    if [ "$CURRENT_PORT" = "${DB_PORT}" ]; then
        echo "MySQL is already running on port ${DB_PORT}!"
        echo "Script stopped - server already running."
        exit 0
    else
        echo "MySQL is running on different port ($CURRENT_PORT), stopping it first..."
        sudo mysqladmin shutdown --socket=/var/run/mysqld/mysqld.sock
        sleep 5
    fi
fi

# Initialize MySQL data directory if it doesn't exist
if [ ! -d "/var/lib/mysql/mysql" ]; then
    echo "Initializing MySQL..."
    sudo mysqld --initialize-insecure --user=mysql --datadir=/var/lib/mysql
fi

# Start MySQL server in background using sudo
echo "Starting MySQL server..."
sudo mysqld --user=mysql --datadir=/var/lib/mysql --socket=/var/run/mysqld/mysqld.sock --pid-file=/var/run/mysqld/mysqld.pid --port=${DB_PORT} &

# Wait for MySQL to be ready
echo "Waiting for MySQL to start..."
sleep 5

# Check if MySQL is running using socket
for i in {1..15}; do
    if sudo mysqladmin ping --socket=/var/run/mysqld/mysqld.sock --silent 2>/dev/null; then
        echo "MySQL is ready!"
        break
    fi
    echo "Waiting... ($i/15)"
    sleep 2
done

# Configure database and user - Fix MySQL 8.0 authentication
echo "Setting up database and fixing authentication..."
sudo mysql --socket=/var/run/mysqld/mysqld.sock << EOF
-- Fix root user authentication for MySQL 8.0
ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY '${DB_PASSWORD}';

-- Create database
CREATE DATABASE IF NOT EXISTS ${DB_NAME};

-- Create a new user for remote connections
CREATE USER IF NOT EXISTS 'appuser'@'%' IDENTIFIED BY '${DB_PASSWORD}';
GRANT ALL PRIVILEGES ON ${DB_NAME}.* TO 'appuser'@'%';

-- Grant privileges to root
GRANT ALL PRIVILEGES ON ${DB_NAME}.* TO 'root'@'localhost';

FLUSH PRIVILEGES;
EOF

# Save connection command to a file
echo "mysql -u ${DB_USER} -p${DB_PASSWORD} -h localhost -P ${DB_PORT} ${DB_NAME}" > db_connection.txt
echo "Connection command saved to db_connection.txt"

# Save environment variables to a file
cat > db_visualizer/mysql.env << EOF
export MYSQL_URL="mysql://localhost:${DB_PORT}/${DB_NAME}"
export MYSQL_USER="${DB_USER}"
export MYSQL_PASSWORD="${DB_PASSWORD}"
export MYSQL_DB="${DB_NAME}"
export MYSQL_PORT="${DB_PORT}"
EOF

echo "Applying Smart Outage MVP schema + seed data..."

# IMPORTANT:
# - Keep SQL statements one-at-a-time for robustness.
# - Use IF NOT EXISTS / ON DUPLICATE KEY UPDATE for idempotency.
MYSQL_CMD="mysql -u ${DB_USER} -p${DB_PASSWORD} -h localhost -P ${DB_PORT} ${DB_NAME}"

# Schema
${MYSQL_CMD} -e "CREATE TABLE IF NOT EXISTS organizations (id CHAR(36) NOT NULL PRIMARY KEY, name VARCHAR(200) NOT NULL, created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP) ENGINE=InnoDB"
${MYSQL_CMD} -e "CREATE TABLE IF NOT EXISTS users (id CHAR(36) NOT NULL PRIMARY KEY, organization_id CHAR(36) NOT NULL, email VARCHAR(320) NOT NULL, full_name VARCHAR(200) NOT NULL, phone VARCHAR(50) NULL, role ENUM('operator','crew','customer','admin') NOT NULL, is_active TINYINT(1) NOT NULL DEFAULT 1, created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP, UNIQUE KEY uq_users_org_email (organization_id, email), KEY ix_users_org (organization_id), CONSTRAINT fk_users_org FOREIGN KEY (organization_id) REFERENCES organizations(id) ON DELETE RESTRICT ON UPDATE CASCADE) ENGINE=InnoDB"
${MYSQL_CMD} -e "CREATE TABLE IF NOT EXISTS crews (id CHAR(36) NOT NULL PRIMARY KEY, organization_id CHAR(36) NOT NULL, name VARCHAR(200) NOT NULL, lead_user_id CHAR(36) NULL, is_active TINYINT(1) NOT NULL DEFAULT 1, created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP, KEY ix_crews_org (organization_id), KEY ix_crews_lead (lead_user_id), CONSTRAINT fk_crews_org FOREIGN KEY (organization_id) REFERENCES organizations(id) ON DELETE RESTRICT ON UPDATE CASCADE, CONSTRAINT fk_crews_lead FOREIGN KEY (lead_user_id) REFERENCES users(id) ON DELETE SET NULL ON UPDATE CASCADE) ENGINE=InnoDB"
${MYSQL_CMD} -e "CREATE TABLE IF NOT EXISTS locations (id CHAR(36) NOT NULL PRIMARY KEY, organization_id CHAR(36) NOT NULL, address_line1 VARCHAR(200) NOT NULL, address_line2 VARCHAR(200) NULL, city VARCHAR(120) NOT NULL, state VARCHAR(120) NULL, postal_code VARCHAR(30) NULL, country VARCHAR(120) NOT NULL DEFAULT 'US', latitude DECIMAL(9,6) NULL, longitude DECIMAL(9,6) NULL, created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP, KEY ix_locations_org (organization_id), KEY ix_locations_latlng (latitude, longitude), CONSTRAINT fk_locations_org FOREIGN KEY (organization_id) REFERENCES organizations(id) ON DELETE RESTRICT ON UPDATE CASCADE) ENGINE=InnoDB"
${MYSQL_CMD} -e "CREATE TABLE IF NOT EXISTS outages (id CHAR(36) NOT NULL PRIMARY KEY, organization_id CHAR(36) NOT NULL, reported_by_user_id CHAR(36) NULL, customer_user_id CHAR(36) NULL, location_id CHAR(36) NOT NULL, title VARCHAR(200) NOT NULL, description TEXT NULL, severity ENUM('low','medium','high','critical') NOT NULL DEFAULT 'medium', status ENUM('new','triaged','dispatched','in_progress','resolved','cancelled') NOT NULL DEFAULT 'new', started_at DATETIME NULL, resolved_at DATETIME NULL, created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP, updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP, KEY ix_outages_org (organization_id), KEY ix_outages_status (status), KEY ix_outages_location (location_id), CONSTRAINT fk_outages_org FOREIGN KEY (organization_id) REFERENCES organizations(id) ON DELETE RESTRICT ON UPDATE CASCADE, CONSTRAINT fk_outages_reporter FOREIGN KEY (reported_by_user_id) REFERENCES users(id) ON DELETE SET NULL ON UPDATE CASCADE, CONSTRAINT fk_outages_customer FOREIGN KEY (customer_user_id) REFERENCES users(id) ON DELETE SET NULL ON UPDATE CASCADE, CONSTRAINT fk_outages_location FOREIGN KEY (location_id) REFERENCES locations(id) ON DELETE RESTRICT ON UPDATE CASCADE) ENGINE=InnoDB"
${MYSQL_CMD} -e "CREATE TABLE IF NOT EXISTS jobs (id CHAR(36) NOT NULL PRIMARY KEY, organization_id CHAR(36) NOT NULL, outage_id CHAR(36) NOT NULL, assigned_crew_id CHAR(36) NULL, assigned_to_user_id CHAR(36) NULL, status ENUM('pending','assigned','en_route','on_site','completed','cancelled') NOT NULL DEFAULT 'pending', priority ENUM('low','normal','high','urgent') NOT NULL DEFAULT 'normal', notes TEXT NULL, created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP, updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP, KEY ix_jobs_org (organization_id), KEY ix_jobs_outage (outage_id), KEY ix_jobs_status (status), KEY ix_jobs_crew (assigned_crew_id), CONSTRAINT fk_jobs_org FOREIGN KEY (organization_id) REFERENCES organizations(id) ON DELETE RESTRICT ON UPDATE CASCADE, CONSTRAINT fk_jobs_outage FOREIGN KEY (outage_id) REFERENCES outages(id) ON DELETE CASCADE ON UPDATE CASCADE, CONSTRAINT fk_jobs_crew FOREIGN KEY (assigned_crew_id) REFERENCES crews(id) ON DELETE SET NULL ON UPDATE CASCADE, CONSTRAINT fk_jobs_user FOREIGN KEY (assigned_to_user_id) REFERENCES users(id) ON DELETE SET NULL ON UPDATE CASCADE) ENGINE=InnoDB"
${MYSQL_CMD} -e "CREATE TABLE IF NOT EXISTS job_status_events (id BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY, job_id CHAR(36) NOT NULL, status ENUM('pending','assigned','en_route','on_site','completed','cancelled') NOT NULL, changed_by_user_id CHAR(36) NULL, message VARCHAR(500) NULL, created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP, KEY ix_job_events_job (job_id), KEY ix_job_events_created (created_at), CONSTRAINT fk_job_events_job FOREIGN KEY (job_id) REFERENCES jobs(id) ON DELETE CASCADE ON UPDATE CASCADE, CONSTRAINT fk_job_events_user FOREIGN KEY (changed_by_user_id) REFERENCES users(id) ON DELETE SET NULL ON UPDATE CASCADE) ENGINE=InnoDB"
${MYSQL_CMD} -e "CREATE TABLE IF NOT EXISTS notifications (id BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY, organization_id CHAR(36) NOT NULL, user_id CHAR(36) NULL, outage_id CHAR(36) NULL, job_id CHAR(36) NULL, channel ENUM('push','sms','email','in_app') NOT NULL DEFAULT 'in_app', title VARCHAR(200) NOT NULL, body TEXT NOT NULL, status ENUM('queued','sent','failed') NOT NULL DEFAULT 'queued', created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP, sent_at DATETIME NULL, KEY ix_notifications_org (organization_id), KEY ix_notifications_user (user_id), KEY ix_notifications_status (status), CONSTRAINT fk_notifications_org FOREIGN KEY (organization_id) REFERENCES organizations(id) ON DELETE RESTRICT ON UPDATE CASCADE, CONSTRAINT fk_notifications_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE SET NULL ON UPDATE CASCADE, CONSTRAINT fk_notifications_outage FOREIGN KEY (outage_id) REFERENCES outages(id) ON DELETE SET NULL ON UPDATE CASCADE, CONSTRAINT fk_notifications_job FOREIGN KEY (job_id) REFERENCES jobs(id) ON DELETE SET NULL ON UPDATE CASCADE) ENGINE=InnoDB"
${MYSQL_CMD} -e "CREATE TABLE IF NOT EXISTS outage_updates (id BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY, outage_id CHAR(36) NOT NULL, update_type ENUM('note','status_change','system') NOT NULL DEFAULT 'note', message TEXT NOT NULL, created_by_user_id CHAR(36) NULL, created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP, KEY ix_outage_updates_outage (outage_id), KEY ix_outage_updates_created (created_at), CONSTRAINT fk_outage_updates_outage FOREIGN KEY (outage_id) REFERENCES outages(id) ON DELETE CASCADE ON UPDATE CASCADE, CONSTRAINT fk_outage_updates_user FOREIGN KEY (created_by_user_id) REFERENCES users(id) ON DELETE SET NULL ON UPDATE CASCADE) ENGINE=InnoDB"

# Seed (minimal / idempotent)
${MYSQL_CMD} -e "INSERT INTO organizations (id, name) VALUES ('00000000-0000-0000-0000-000000000001','Demo Utility') ON DUPLICATE KEY UPDATE name=VALUES(name)"
${MYSQL_CMD} -e "INSERT INTO users (id, organization_id, email, full_name, phone, role) VALUES ('00000000-0000-0000-0000-000000000101','00000000-0000-0000-0000-000000000001','operator@demo.local','Demo Operator',NULL,'operator') ON DUPLICATE KEY UPDATE full_name=VALUES(full_name), role=VALUES(role), is_active=1"
${MYSQL_CMD} -e "INSERT INTO users (id, organization_id, email, full_name, phone, role) VALUES ('00000000-0000-0000-0000-000000000201','00000000-0000-0000-0000-000000000001','crew1@demo.local','Crew Member One',NULL,'crew') ON DUPLICATE KEY UPDATE full_name=VALUES(full_name), role=VALUES(role), is_active=1"
${MYSQL_CMD} -e "INSERT INTO users (id, organization_id, email, full_name, phone, role) VALUES ('00000000-0000-0000-0000-000000000301','00000000-0000-0000-0000-000000000001','customer1@demo.local','Demo Customer',NULL,'customer') ON DUPLICATE KEY UPDATE full_name=VALUES(full_name), role=VALUES(role), is_active=1"
${MYSQL_CMD} -e "INSERT INTO crews (id, organization_id, name, lead_user_id) VALUES ('00000000-0000-0000-0000-000000000401','00000000-0000-0000-0000-000000000001','Crew Alpha','00000000-0000-0000-0000-000000000201') ON DUPLICATE KEY UPDATE name=VALUES(name), lead_user_id=VALUES(lead_user_id), is_active=1"
${MYSQL_CMD} -e "INSERT INTO locations (id, organization_id, address_line1, address_line2, city, state, postal_code, country, latitude, longitude) VALUES ('00000000-0000-0000-0000-000000000501','00000000-0000-0000-0000-000000000001','100 Main St',NULL,'Springfield','CA','90001','US',34.052235,-118.243683) ON DUPLICATE KEY UPDATE address_line1=VALUES(address_line1), city=VALUES(city), state=VALUES(state), postal_code=VALUES(postal_code), latitude=VALUES(latitude), longitude=VALUES(longitude)"
${MYSQL_CMD} -e "INSERT INTO outages (id, organization_id, reported_by_user_id, customer_user_id, location_id, title, description, severity, status, started_at) VALUES ('00000000-0000-0000-0000-000000000601','00000000-0000-0000-0000-000000000001','00000000-0000-0000-0000-000000000101','00000000-0000-0000-0000-000000000301','00000000-0000-0000-0000-000000000501','Transformer outage near Main St','Customer reported power loss in area','high','new',NOW()) ON DUPLICATE KEY UPDATE title=VALUES(title), description=VALUES(description), severity=VALUES(severity), status=VALUES(status)"
${MYSQL_CMD} -e "INSERT INTO jobs (id, organization_id, outage_id, assigned_crew_id, assigned_to_user_id, status, priority, notes) VALUES ('00000000-0000-0000-0000-000000000701','00000000-0000-0000-0000-000000000001','00000000-0000-0000-0000-000000000601','00000000-0000-0000-0000-000000000401','00000000-0000-0000-0000-000000000201','assigned','high','Investigate transformer and restore service') ON DUPLICATE KEY UPDATE assigned_crew_id=VALUES(assigned_crew_id), assigned_to_user_id=VALUES(assigned_to_user_id), status=VALUES(status), priority=VALUES(priority)"

# Append-only demo timeline entries (safe if duplicated in dev; avoids brittle de-dup logic)
${MYSQL_CMD} -e "INSERT INTO job_status_events (job_id, status, changed_by_user_id, message) VALUES ('00000000-0000-0000-0000-000000000701','assigned','00000000-0000-0000-0000-000000000101','Job assigned to Crew Alpha')"
${MYSQL_CMD} -e "INSERT INTO outage_updates (outage_id, update_type, message, created_by_user_id) VALUES ('00000000-0000-0000-0000-000000000601','note','Outage logged via call center intake','00000000-0000-0000-0000-000000000101')"
${MYSQL_CMD} -e "INSERT INTO notifications (organization_id, user_id, outage_id, job_id, channel, title, body, status, sent_at) VALUES ('00000000-0000-0000-0000-000000000001','00000000-0000-0000-0000-000000000201','00000000-0000-0000-0000-000000000601','00000000-0000-0000-0000-000000000701','in_app','New job assigned','You have been assigned a new outage job near 100 Main St.','sent',NOW())"

echo "Smart Outage MVP schema + seed data applied."

echo "MySQL setup complete!"
echo "Database: ${DB_NAME}"
echo "Root user: root (password: ${DB_PASSWORD})"
echo "App user: appuser (password: ${DB_PASSWORD})"
echo "Port: ${DB_PORT}"
echo ""

echo "Environment variables saved to db_visualizer/mysql.env"
echo "To use with Node.js viewer, run: source db_visualizer/mysql.env"

echo "To connect to the database, use the following command:"
echo "$(cat db_connection.txt)"

echo ""
echo "MySQL is running in the background."
echo "You can now start your application."
