#!/bin/bash

# Define the log file
LOG_FILE="/var/log/ssh_installation.log"

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

# Update the package list and install OpenSSH Server
log_command "apt update"
log_command "apt install -y openssh-server"

# Start the SSH server
log_command "systemctl start ssh"

# Enable SSH at boot
log_command "systemctl enable ssh"

# Check the status of SSH and log the result
ssh_status=$(systemctl is-active ssh)
echo "SSH Status: $ssh_status" >> "$LOG_FILE"

if [ "$ssh_status" = "active" ]; then
    echo "OpenSSH installation and configuration completed. SSH is active."
else
    echo "OpenSSH installation completed, but SSH is not active. Please check the log file for details: $LOG_FILE"
fi

#create directory for keygen
log_command "mkdir /home/sandboxadmin/.ssh"

#generate ssh key
log_command "ssh-keygen -t ed25519 -f /home/sandboxadmin/.ssh/goose4"
