#!/bin/bash

# Define the log file
LOG_FILE="/var/log/slurm_worker_installation.log"

# Check if the script is being run as root
if [ "$EUID" -ne 0 ]; then
    echo "Please run this script as root or using sudo."
    exit 1
fi

# Function to log command output to the log file
log_command() {
    local command="$1"
    echo "Running: $command" >> "$LOG_FILE"
    eval "$command" >> "$LOG_FILE" 2>&1
    local exit_code=$?
    if [ $exit_code -ne 0 ]; then
        echo "Error running: $command" >> "$LOG_FILE"
        echo "Exit code: $exit_code" >> "$LOG_FILE"
    fi
}

# Create Munge user and group
log_command "groupadd munge"
log_command "useradd -r -g munge -c \"Munge Group\" -d /var/lib/munge -p \"sandboxmunge\" munge_user"

# Update the package list and install Munge
log_command "apt update"
log_command "apt-get install munge libmunge-dev -y"

# Start the Munge service
log_command "systemctl start munge"

# Enable Munge at boot
log_command "systemctl enable munge"

#Create Slurm user and group
log_command "groupadd slurm"
log_command "useradd -r -g slurm -c \"Slurm Group\" -d /var/spool/slurm -p \"sandboxslurm\" slurm_user"

#Install Slurm Worker Components
log_command "apt install -y slurmd slurm-client"

#Copy slurm conf from master node
log_command "scp -P 1337 -i /home/sandboxadmin/goose3 sandboxadmin@**.**.*.***:/etc/slurm/slurm.conf /etc/slurm/slurm.conf"

#Change permission of conf file
log_command "chmod 777 /etc/slurm/slurm.conf"

#Changes in conf file
log_command "sed -i \"s/goose1/goose3/g\" /etc/slurm/slurm.conf"

#Create slurm directory
log_command "mkdir -p -m 777 /var/spool/slurm/d"

# Start the Slurm Worker service
log_command "systemctl start slurmd"

# Enable Slurm Worker at boot
log_command "systemctl enable slurmd"

# Check the status of Slurm Worker and log the result
slurm_status=$(systemctl is-active slurmd)
echo "Slurm Worker Status: $slurm_status" >> "$LOG_FILE"

if [ "$slurm_status" = "active" ]; then
    echo "Slurm Worker installation and configuration completed. Slurm Worker is active."
else
    echo "Slurm Worker installation completed, but Slurm Worker is not active. Please check the log file for details: $LOG_FILE"
fi

