#!/bin/bash
# Complex Real-World Bash Script Example
# A comprehensive deployment script with mixed control structures

# Configuration
DEPLOY_DIR="/var/www/app"
BACKUP_DIR="/var/backups/webapp"
LOG_FILE="/var/log/deployment.log"
MAX_RETRIES=3
ENVIRONMENT="production"

# Function to log messages
log_message() {
    local level="$1"
    local message="$2"
    echo "$(date '+%Y-%m-%d %H:%M:%S') [$level] $message" | tee -a "$LOG_FILE"
}

# Main deployment function
deploy_application() {
    local success=false
    local attempt=1
    
    log_message "INFO" "Starting deployment of application to $ENVIRONMENT"
    
    # Check prerequisites
    if test ! -d "$DEPLOY_DIR"; then
        log_message "ERROR" "Deployment directory $DEPLOY_DIR not found"
        exit 1
    fi
    
    # Check if we need to backup current version
    if [ -d "$DEPLOY_DIR/live" ]; then
        log_message "INFO" "Backing up current version"
        
        # Create backup directory with timestamp
        TIMESTAMP=$(date +%Y%m%d_%H%M%S)
        BACKUP_PATH="$BACKUP_DIR/$TIMESTAMP"
        
        if ! mkdir -p "$BACKUP_PATH"; then
            log_message "ERROR" "Failed to create backup directory"
            exit 1
        fi
        
        # Backup current version
        for file in config.yml app.js index.html
        do
            if test -f "$DEPLOY_DIR/live/$file"; then
                cp "$DEPLOY_DIR/live/$file" "$BACKUP_PATH/"
            fi
        done
        
        # Create backup manifest
        echo "$TIMESTAMP" > "$DEPLOY_DIR/backup_timestamp"
        log_message "INFO" "Backup completed at $BACKUP_PATH"
    fi
    
    # Main deployment loop with retry logic
    while test $attempt -le $MAX_RETRIES
    do
        log_message "INFO" "Deployment attempt $attempt of $MAX_RETRIES"
        attempt_failed=false
        
        # Check disk space
        AVAILABLE_SPACE=$(df -BK "$DEPLOY_DIR" | tail -1 | awk '{print $4}' | sed 's/K//')
        if test "$AVAILABLE_SPACE" -lt 10000; then
            log_message "ERROR" "Insufficient disk space. Available: ${AVAILABLE_SPACE}KB, Required: 10GB"
            attempt_failed=true
        fi
        
        # Main deployment logic
        if test "$attempt_failed" = "false"; then
            # Create staging area
            STAGING_DIR="$DEPLOY_DIR/staging_$$"
            mkdir -p "$STAGING_DIR"
            
            # Download and extract new version
            log_message "INFO" "Downloading new application version"
            
            # Process different file types
            for archive in *.tar.gz *.zip; do
                if test -f "$archive"; then
                    log_message "INFO" "Processing archive: $archive"
                    
                    if [[ "$archive" == *.tar.gz ]]; then
                        tar -xzf "$archive" -C "$STAGING_DIR"
                    elif [[ "$archive" == *.zip ]]; then
                        unzip -q "$archive" -d "$STAGING_DIR"
                    fi
                fi
            done
            
            # Validate configuration files
            config_files=("config.yml" "database.yml" "secrets.yml")
            for config in "${config_files[@]}"
            do
                if ! test -f "$STAGING_DIR/$config"; then
                    log_message "ERROR" "Required config file $config not found"
                    attempt_failed=true
                    break
                fi
            done
            
            # Check application dependencies
            if test -f "$STAGING_DIR/package.json"; then
                log_message "INFO" "Installing npm dependencies"
                cd "$STAGING_DIR" && npm install --production
                if test $? -ne 0; then
                    log_message "ERROR" "npm install failed"
                    attempt_failed=true
                fi
            fi
            
            # Run application tests if available
            if test -f "$STAGING_DIR/test.sh"; then
                log_message "INFO" "Running application tests"
                cd "$STAGING_DIR" && ./test.sh > test_results.log 2>&1
                if test $? -ne 0; then
                    log_message "ERROR" "Application tests failed"
                    attempt_failed=true
                fi
            fi
            
            # Deploy verified version to staging
            if test "$attempt_failed" = "false"; then
                log_message "INFO" "Moving to staging directory"
                
                # Create new staging version
                mv "$STAGING_DIR" "$DEPLOY_DIR/staging"
                
                # Atomic swap: switch staging to live
                if test -d "$DEPLOY_DIR/live"; then
                    mv "$DEPLOY_DIR/live" "$DEPLOY_DIR/live_old_$$"
                fi
                
                ln -s "$DEPLOY_DIR/staging" "$DEPLOY_DIR/live"
                
                # Clean up old version
                if test -d "$DEPLOY_DIR/live_old_$$"; then
                    rm -rf "$DEPLOY_DIR/live_old_$$"
                fi
                
                # Restart services that depend on this version
                systemd_services=("nginx" "php-fpm" "app")
                for service in "${systemd_services[@]}"
                do
                    if systemctl list-unit-files | grep -q "^${service}.service"; then
                        log_message "INFO" "Restarting systemd service: $service"
                        systemctl restart "$service" 2>&1 | tee -a "$LOG_FILE"
                    fi
                done
                
                log_message "INFO" "Deployment completed successfully"
                success=true
                break
            fi
        fi
        
        if test "$attempt_failed" = "true"; then
            log_message "WARNING" "Deployment attempt $attempt failed"
            rm -rf "$STAGING_DIR" 2>/dev/null
            attempt=$((attempt + 1))
            
            # Exponential backoff
            if test $attempt -le $MAX_RETRIES; then
                sleep $((attempt * 5))
            fi
        fi
    done
    
    # Final status reporting
    if test "$success" = "true"; then
        log_message "INFO" "Application successfully deployed to $ENVIRONMENT"
        
        # Cleanup staging directories older than 7 days
        find "$DEPLOY_DIR" -type d -name "staging_*" -mtime +7 -exec rm -rf {} \; 2>/dev/null || true
        
        # Update deployment metrics
        echo "deployment_success" > "$DEPLOY_DIR/deploy_status"
        return 0
    else
        log_message "ERROR" "Deployment failed after $MAX_RETRIES attempts"
        echo "deployment_failed" > "$DEPLOY_DIR/deploy_status"
        exit 1
    fi
}

# Execute main deployment
deploy_application

# Cleanup function
cleanup() {
    # Remove temporary files and staging directories
    find /tmp/deployment_* -mtime +1 -delete 2>/dev/null || true
    log_message "INFO" "Cleanup completed"
}

# Set trap for cleanup on exit
trap cleanup EXIT

# Main execution with error handling
main() {
    # Check if running as root or with sufficient privileges
    if test "$(id -u)" -ne 0; then
        log_message "WARNING" "Not running as root, some operations may fail"
    fi
    
    # Validate environment
    case "$ENVIRONMENT" in
        "production"|"staging"|"development")
            log_message "INFO" "Environment validated: $ENVIRONMENT"
            ;;
        *)
            log_message "ERROR" "Invalid environment: $ENVIRONMENT"
            exit 1
            ;;
    esac
    
    # Start deployment with timeout
    timeout 600s deploy_application
    
    local exit_code=$?
    
    # Final report
    case $exit_code in
        0)
            log_message "INFO" "Deployment completed successfully!"
            ;;
        124)
            log_message "ERROR" "Deployment timed out after 10 minutes"
            exit 1
            ;;
        *)
            log_message "ERROR" "Deployment failed with exit code: $exit_code"
            exit 1
            ;;
    esac
}

# Run main function
main "$@"