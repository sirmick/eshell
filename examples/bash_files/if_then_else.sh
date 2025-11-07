#!/bin/bash
# If/Then/Else Conditionals Example

# Basic if-then
echo "=== Basic If-Then ==="
if test -f /etc/passwd
then
    echo "Password file exists"
fi

# If-then-else with file check
echo "=== If-Then-Else File Check ==="
config_file="config.yml"
if test -f "$config_file"
then
    echo "Configuration file exists"
    chmod 644 "$config_file"
else
    echo "Configuration file not found, creating default"
    echo "# Default configuration" > "$config_file"
    echo "debug: false" >> "$config_file"
fi

# Numeric comparison
echo "=== Numeric Comparison ==="
age=25
if test $age -ge 18
then
    echo "Adult user detected"
else
    echo "Minor user detected"
fi

# Complex boolean logic
echo "=== Complex Boolean Logic ==="
file="document.txt"
if [ -r "$file" ] && [ -w "$file" ]
then
    echo "File $file is both readable and writable"
elif [ -r "$file" ]
then
    echo "File $file is readable only"
elif [ -w "$file" ]
then
    echo "File $file is writable only" 
else
    echo "File $file has no read/write access"
fi

# Multiple conditions
echo "=== Multiple Conditions ==="
space_available=15000
disk_type="ssd"
if test $space_available -gt 10000 && test "$disk_type" = "ssd"
then
    echo "Sufficient space available for SSD optimization"
    echo "Optimizing for SSD performance"
else
    echo "Standard optimization will be applied"
fi

# Nested conditionals
echo "=== Nested Conditionals ==="
environment="production"
maintenance_mode="false"
if test "$environment" = "production"
then
    echo "Production environment detected"
    if test "$maintenance_mode" = "true"
    then
        echo "System is in maintenance mode"
        echo "Redirecting to maintenance page"
    else
        echo "System is operational"
        if [ -f "maintenance.flag" ]
        then
            echo "Switching to maintenance mode from flag file"
        fi
    fi
fi

# String comparison with case sensitivity
echo "=== String Comparison ==="
input="yEs"
if test "$input" = "yes" || test "$input" = "YES" || test "$input" = "Yes"
then
    echo "User confirmed with yes"
else
    echo "User declined or invalid input"
fi

# File existence with pattern matching
echo "=== Pattern Matching ==="
for config in config.* project.yml app.json
do
    if test -f "$config"
    then
        echo "Found configuration file: $config"
        if [[ "$config" == *.yml ]]
        then
            echo "YAML configuration detected"
        elif [[ "$config" == *.json ]]
        then
            echo "JSON configuration detected"
        fi
    fi
done

# Comparing command output
echo "=== Command Output Comparison ==="
if [ $(ps aux | grep -c myapp) -gt 1 ]
then
    echo "Application is already running"
else
    echo "Application is not running, starting now..."
    nohup myapp &>/dev/null &
fi

# Exit code checking
echo "=== Exit Code Checking ==="
some-command-that-might-fail || {
    echo "Command failed, trying alternative..."
    alternative-command || {
        echo "Alternative also failed, giving up"
        exit 1
    }
}
echo "Command completed successfully"