Real-Time Data Infrastructure: Linux System Monitor 
# 🖥️ Real-Time Linux System Monitor

A comprehensive, real-time system monitoring tool built with pure Bash shell scripts and native Linux utilities. Monitor CPU, memory, disk, network, and processes with a beautiful terminal UI.

![License](https://img.shields.io/badge/license-MIT-blue.svg)
![Bash](https://img.shields.io/badge/bash-5.0+-green.svg)
![Platform](https://img.shields.io/badge/platform-linux-lightgrey.svg)

## ✨ Features

- **Real-time Monitoring**: Live updates every 2 seconds
- **CPU Monitoring**: Usage percentage, core count, temperature
- **Memory Tracking**: RAM and Swap usage with detailed statistics
- **Disk Usage**: Monitor all mounted filesystems
- **Network Statistics**: Real-time upload/download speeds
- **Process Management**: Top CPU and memory consuming processes
- **Alert System**: Configurable thresholds with logging
- **Beautiful UI**: Colorful, organized terminal interface
- **No Dependencies**: Pure bash with standard Linux tools

## 🚀 Quick Start

### Prerequisites

- Linux-based operating system
- Bash 4.0 or higher
- Standard utilities: `top`, `free`, `df`, `ps`, `bc`

### Installation
```bash
# Clone the repository
git clone https://github.com/Nanthakumar-N2/Real-Time-Data-Infrastructure-Linux-System-Monitor.git
cd linux-system-monitor

# Make the script executable
chmod +x monitor.sh install.sh

# Run installation (optional - for system-wide installation)
sudo ./install.sh

# Run the monitor
./monitor.sh
```

### Quick Run (Without Installation)
```bash
wget https://github.com/Nanthakumar-N2/Real-Time-Data-Infrastructure-Linux-System-Monitor.git/main/monitor.sh
chmod +x monitor.sh
./monitor.sh
```

## 📖 Usage

### Basic Usage
```bash
./monitor.sh
```

### With Custom Refresh Rate
```bash
# Edit the REFRESH_RATE variable in the script
REFRESH_RATE=5  # Update every 5 seconds
```

### Configuration

Edit the configuration variables in `monitor.sh`:
```bash
REFRESH_RATE=2                  # Refresh interval in seconds
ALERT_CPU_THRESHOLD=80          # CPU alert threshold (%)
ALERT_MEM_THRESHOLD=85          # Memory alert threshold (%)
ALERT_DISK_THRESHOLD=90         # Disk alert threshold (%)
LOG_FILE="/var/log/system_monitor.log"  # Log file path
```

## 📊 Monitored Metrics

### System Information
- Hostname
- Operating System
- Kernel Version
- System Uptime
- Load Average
- Running Processes

### CPU Metrics
- Real-time CPU usage percentage
- Number of cores
- CPU temperature (if available)
- Visual progress bar

### Memory Metrics
- RAM usage (used/total)
- RAM percentage
- Swap usage
- Visual progress bars

### Disk Metrics
- Root filesystem usage
- All mounted filesystems
- Used/total space
- Visual progress bars

### Network Metrics
- Active network interface
- Download speed (KB/s)
- Upload speed (KB/s)
- Real-time statistics

### Process Information
- Top 5 CPU-consuming processes
- Top 5 Memory-consuming processes
- PID, user, and resource usage

## 🔔 Alert System

The monitor includes an alert system that:
- Monitors resource usage against configurable thresholds
- Logs alerts to `/var/log/system_monitor.log`
- Displays visual warnings in the interface
- Tracks CPU, memory, and disk usage

## 🛠️ Advanced Features

### Running as a Service

Create a systemd service for continuous monitoring:
```bash
sudo cp monitor.service /etc/systemd/system/
sudo systemctl enable monitor
sudo systemctl start monitor
```

### Remote Monitoring

Monitor remote systems via SSH:
```bash
ssh user@remote-host 'bash -s' < monitor.sh
```

### Export Data

Redirect output to file for logging:
```bash
./monitor.sh | tee system_monitor_$(date +%Y%m%d_%H%M%S).log
```

## 🎨 Screenshots
