#!/bin/bash

# Configurare variabile
DB_NAME="conta_development"
DB_USER="postgres"
DB_HOST="localhost"
BACKUP_DIR="/Users/ldragne/Desktop/licenta-backend/db/backups"
DATE=$(date +\%Y-\%m-\%d_\%H-\%M)
BACKUP_FILE="$BACKUP_DIR/${DB_NAME}_$DATE.dump"

# Creare director backup (dacă nu există)
mkdir -p $BACKUP_DIR

# Executare backup
PGPASSWORD="postgres" pg_dump -U $DB_USER -h $DB_HOST -F c -b -v -f $BACKUP_FILE $DB_NAME

# Șterge backup-urile mai vechi de 7 zile
find $BACKUP_DIR -type f -name "*.dump" -mtime +90 -exec rm {} \;
