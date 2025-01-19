#!/bin/bash

# Configurare variabile
DB_NAME="conta_development"
DB_USER="postgres"
DB_HOST="localhost"
BACKUP_DIR="/Users/ldragne/Desktop/licenta-backend/backup-dir"
DATE=$(date +\%Y-\%m-\%d_\%H-\%M)
BACKUP_FILE="$BACKUP_DIR/${DB_NAME}_$DATE.dump"

# Creare director backup (dacă nu există)
mkdir -p $BACKUP_DIR

# Executare backup
PGPASSWORD="postgres" pg_dump -U $DB_USER -h $DB_HOST -F c -b -v -f $BACKUP_FILE $DB_NAME

