#!/bin/bash
# Created by System Administrator Luciana Silvestre
# September 9, 2024
# File: check_system.sh
# Function: Check Cpu, memory, and disk space

# Set the thresholds
CPU_THRESHOLD=80
MEMORY_THRESHOLD=80
DISK_THRESHOLD=95
EMAIL=user@company

# Temp file to hold the email content
TEMP_FILE=$(mktemp)

# Function to check CPU usage
check_cpu() {
    CPU_USAGE=$(top -bn1 | grep "Cpu(s)" | sed "s/.*, *\([0-9.]*\)%* id.*/\1/" | awk '{print 100 - $1}')

    echo "CPU Usage: $CPU_USAGE%" >> $TEMP_FILE
    if (( $(echo "$CPU_USAGE > $CPU_THRESHOLD" | bc -l) )); then
        echo "WARNING: CPU usage is too high!" >> $TEMP_FILE
        echo "Top 5 CPU consuming processes:" >> $TEMP_FILE
        ps -eo pid,ppid,cmd,%mem,%cpu --sort=-%cpu | head -6 >> $TEMP_FILE
    else
        echo "CPU usage is under control." >> $TEMP_FILE
    fi
    echo "" >> $TEMP_FILE
}

# Function to check memory usage
check_memory() {
    MEMORY_USAGE=$(free | grep Mem | awk '{print $3/$2 * 100.0}')

    echo "Memory Usage: $MEMORY_USAGE%" >> $TEMP_FILE
    if (( $(echo "$MEMORY_USAGE > $MEMORY_THRESHOLD" | bc -l) )); then
        echo "WARNING: Memory usage is too high!" >> $TEMP_FILE
        echo "Top 5 memory consuming processes:" >> $TEMP_FILE
        ps -eo pid,ppid,cmd,%mem,%cpu --sort=-%mem | head -6 >> $TEMP_FILE
    else
        echo "Memory usage is under control." >> $TEMP_FILE
    fi
    echo "" >> $TEMP_FILE
}

# Function to check disk space
check_disk() {
    echo "Checking disk usage..." >> $TEMP_FILE
    DISK_USAGE=$(df -h | grep '^/dev/' | awk '{print $5 " " $1}' | sed 's/%//g')

    echo "$DISK_USAGE" | while read output; do
        usage=$(echo $output | awk '{print $1}')
        partition=$(echo $output | awk '{print $2}')

        if [ $usage -ge $DISK_THRESHOLD ]; then
            echo "WARNING: Partition $partition is $usage% full." >> $TEMP_FILE
            echo "Top 5 largest directories in $partition:" >> $TEMP_FILE
            du -ahx $partition | sort -rh | head -5 >> $TEMP_FILE
        fi
    done
    echo "" >> $TEMP_FILE
}

# Run checks
check_cpu
check_memory
check_disk

# Email the results
SUBJECT="System Resource Check Report"
{
    echo "To: $EMAIL"
    echo "Subject: $SUBJECT"
    echo "Content-Type: text/plain"
    echo ""
    cat $TEMP_FILE
} | sendmail -t

# Clean up
rm $TEMP_FILE
