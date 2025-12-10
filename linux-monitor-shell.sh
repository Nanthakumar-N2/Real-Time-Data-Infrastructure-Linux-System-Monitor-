#!/bin/bash

#######################################
# Real-Time Linux System Monitor
# Author: Your Name
# Description: Monitor CPU, Memory, Disk, Network in real-time
#######################################

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color
BOLD='\033[1m'

# Configuration
REFRESH_RATE=2
LOG_FILE="/var/log/system_monitor.log"
ALERT_CPU_THRESHOLD=80
ALERT_MEM_THRESHOLD=85
ALERT_DISK_THRESHOLD=90

# Function to clear screen and move cursor to top
clear_screen() {
    clear
    tput cup 0 0
}

# Function to get CPU usage
get_cpu_usage() {
    # Method 1: Using top
    top -bn1 | grep "Cpu(s)" | sed "s/.*, *\([0-9.]*\)%* id.*/\1/" | awk '{print 100 - $1}'
}

# Function to get CPU info
get_cpu_info() {
    local cores=$(nproc)
    local model=$(lscpu | grep "Model name" | cut -d':' -f2 | xargs)
    echo "$cores cores | $model"
}

# Function to get CPU temperature (if available)
get_cpu_temp() {
    if [ -f /sys/class/thermal/thermal_zone0/temp ]; then
        local temp=$(cat /sys/class/thermal/thermal_zone0/temp)
        echo "scale=1; $temp/1000" | bc
    elif command -v sensors &> /dev/null; then
        sensors | grep "Core 0" | awk '{print $3}' | tr -d '+°C'
    else
        echo "N/A"
    fi
}

# Function to get memory usage
get_memory_usage() {
    free | grep Mem | awk '{printf "%.1f", $3/$2 * 100.0}'
}

# Function to get memory details
get_memory_details() {
    free -h | grep Mem | awk '{print $3 " / " $2}'
}

# Function to get swap usage
get_swap_usage() {
    free | grep Swap | awk '{if ($2 > 0) printf "%.1f", $3/$2 * 100.0; else print "0"}'
}

# Function to get disk usage
get_disk_usage() {
    df -h / | awk 'NR==2 {print $5}' | tr -d '%'
}

# Function to get disk details
get_disk_details() {
    df -h / | awk 'NR==2 {print $3 " / " $2}'
}

# Function to get all mounted filesystems
get_all_disks() {
    df -h | grep "^/dev" | awk '{printf "%-20s %8s / %-8s (%s)\n", $1, $3, $2, $5}'
}

# Function to get network usage
get_network_usage() {
    local interface=$(ip route | grep default | awk '{print $5}' | head -n1)
    if [ -z "$interface" ]; then
        echo "0 0"
        return
    fi
    
    local rx1=$(cat /sys/class/net/$interface/statistics/rx_bytes 2>/dev/null || echo 0)
    local tx1=$(cat /sys/class/net/$interface/statistics/tx_bytes 2>/dev/null || echo 0)
    sleep 1
    local rx2=$(cat /sys/class/net/$interface/statistics/rx_bytes 2>/dev/null || echo 0)
    local tx2=$(cat /sys/class/net/$interface/statistics/tx_bytes 2>/dev/null || echo 0)
    
    local rx_rate=$(( ($rx2 - $rx1) / 1024 ))
    local tx_rate=$(( ($tx2 - $tx1) / 1024 ))
    
    echo "$rx_rate $tx_rate"
}

# Function to get active network interface
get_active_interface() {
    ip route | grep default | awk '{print $5}' | head -n1
}

# Function to get system uptime
get_uptime() {
    uptime -p | sed 's/up //'
}

# Function to get load average
get_load_average() {
    uptime | awk -F'load average:' '{print $2}' | xargs
}

# Function to get running processes
get_process_count() {
    ps aux | wc -l
}

# Function to get top processes by CPU
get_top_cpu_processes() {
    ps aux --sort=-%cpu | head -n 6 | tail -n 5 | awk '{printf "%-8s %-6s %5s%% %s\n", $1, $2, $3, $11}'
}

# Function to get top processes by Memory
get_top_mem_processes() {
    ps aux --sort=-%mem | head -n 6 | tail -n 5 | awk '{printf "%-8s %-6s %5s%% %s\n", $1, $2, $4, $11}'
}

# Function to draw progress bar
draw_progress_bar() {
    local percent=$1
    local width=50
    local filled=$(printf "%.0f" $(echo "$percent * $width / 100" | bc -l))
    local empty=$((width - filled))
    
    # Color based on percentage
    local color=$GREEN
    if (( $(echo "$percent > 80" | bc -l) )); then
        color=$RED
    elif (( $(echo "$percent > 60" | bc -l) )); then
        color=$YELLOW
    fi
    
    printf "${color}["
    printf "%${filled}s" | tr ' ' '█'
    printf "%${empty}s" | tr ' ' '░'
    printf "]${NC} %.1f%%" "$percent"
}

# Function to log alerts
log_alert() {
    local message=$1
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] ALERT: $message" >> "$LOG_FILE"
}

# Function to check thresholds and alert
check_alerts() {
    local cpu=$1
    local mem=$2
    local disk=$3
    
    if (( $(echo "$cpu > $ALERT_CPU_THRESHOLD" | bc -l) )); then
        log_alert "CPU usage high: ${cpu}%"
        echo -e "${RED}⚠ CPU Alert: ${cpu}%${NC}"
    fi
    
    if (( $(echo "$mem > $ALERT_MEM_THRESHOLD" | bc -l) )); then
        log_alert "Memory usage high: ${mem}%"
        echo -e "${RED}⚠ Memory Alert: ${mem}%${NC}"
    fi
    
    if (( $(echo "$disk > $ALERT_DISK_THRESHOLD" | bc -l) )); then
        log_alert "Disk usage high: ${disk}%"
        echo -e "${RED}⚠ Disk Alert: ${disk}%${NC}"
    fi
}

# Function to display header
display_header() {
    echo -e "${BOLD}${CYAN}╔═══════════════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BOLD}${CYAN}║                    REAL-TIME LINUX SYSTEM MONITOR                             ║${NC}"
    echo -e "${BOLD}${CYAN}╚═══════════════════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

# Function to display system info
display_system_info() {
    local hostname=$(hostname)
    local kernel=$(uname -r)
    local os=$(cat /etc/os-release | grep "PRETTY_NAME" | cut -d'"' -f2)
    
    echo -e "${BOLD}${BLUE}┌─ SYSTEM INFORMATION ─────────────────────────────────────────────────────────┐${NC}"
    echo -e "${BLUE}│${NC} Hostname    : $hostname"
    echo -e "${BLUE}│${NC} OS          : $os"
    echo -e "${BLUE}│${NC} Kernel      : $kernel"
    echo -e "${BLUE}│${NC} Uptime      : $(get_uptime)"
    echo -e "${BLUE}│${NC} Load Avg    : $(get_load_average)"
    echo -e "${BLUE}│${NC} Processes   : $(get_process_count)"
    echo -e "${BOLD}${BLUE}└──────────────────────────────────────────────────────────────────────────────┘${NC}"
    echo ""
}

# Function to display metrics
display_metrics() {
    local cpu=$(get_cpu_usage)
    local mem=$(get_memory_usage)
    local disk=$(get_disk_usage)
    local swap=$(get_swap_usage)
    local temp=$(get_cpu_temp)
    
    echo -e "${BOLD}${MAGENTA}┌─ CPU ────────────────────────────────────────────────────────────────────────┐${NC}"
    echo -e "${MAGENTA}│${NC} Usage  : $(draw_progress_bar $cpu)"
    echo -e "${MAGENTA}│${NC} Info   : $(get_cpu_info)"
    echo -e "${MAGENTA}│${NC} Temp   : ${temp}°C"
    echo -e "${BOLD}${MAGENTA}└──────────────────────────────────────────────────────────────────────────────┘${NC}"
    echo ""
    
    echo -e "${BOLD}${GREEN}┌─ MEMORY ─────────────────────────────────────────────────────────────────────┐${NC}"
    echo -e "${GREEN}│${NC} RAM    : $(draw_progress_bar $mem)"
    echo -e "${GREEN}│${NC} Used   : $(get_memory_details)"
    echo -e "${GREEN}│${NC} Swap   : $(draw_progress_bar $swap)"
    echo -e "${BOLD}${GREEN}└──────────────────────────────────────────────────────────────────────────────┘${NC}"
    echo ""
    
    echo -e "${BOLD}${YELLOW}┌─ DISK ───────────────────────────────────────────────────────────────────────┐${NC}"
    echo -e "${YELLOW}│${NC} Root   : $(draw_progress_bar $disk)"
    echo -e "${YELLOW}│${NC} Used   : $(get_disk_details)"
    echo -e "${BOLD}${YELLOW}└──────────────────────────────────────────────────────────────────────────────┘${NC}"
    echo ""
    
    # Check alerts
    check_alerts $cpu $mem $disk
}

# Function to display network info
display_network() {
    local net_data=$(get_network_usage)
    local rx=$(echo $net_data | awk '{print $1}')
    local tx=$(echo $net_data | awk '{print $2}')
    local interface=$(get_active_interface)
    
    echo -e "${BOLD}${CYAN}┌─ NETWORK ────────────────────────────────────────────────────────────────────┐${NC}"
    echo -e "${CYAN}│${NC} Interface : $interface"
    echo -e "${CYAN}│${NC} Download  : ${rx} KB/s"
    echo -e "${CYAN}│${NC} Upload    : ${tx} KB/s"
    echo -e "${BOLD}${CYAN}└──────────────────────────────────────────────────────────────────────────────┘${NC}"
    echo ""
}

# Function to display top processes
display_top_processes() {
    echo -e "${BOLD}${RED}┌─ TOP 5 CPU PROCESSES ────────────────────────────────────────────────────────┐${NC}"
    echo -e "${RED}│${NC} USER     PID    CPU%  COMMAND"
    get_top_cpu_processes | while read line; do
        echo -e "${RED}│${NC} $line"
    done
    echo -e "${BOLD}${RED}└──────────────────────────────────────────────────────────────────────────────┘${NC}"
    echo ""
    
    echo -e "${BOLD}${MAGENTA}┌─ TOP 5 MEMORY PROCESSES ─────────────────────────────────────────────────────┐${NC}"
    echo -e "${MAGENTA}│${NC} USER     PID    MEM%  COMMAND"
    get_top_mem_processes | while read line; do
        echo -e "${MAGENTA}│${NC} $line"
    done
    echo -e "${BOLD}${MAGENTA}└──────────────────────────────────────────────────────────────────────────────┘${NC}"
    echo ""
}

# Main monitoring loop
main() {
    # Check if running as root for some features
    if [ "$EUID" -ne 0 ]; then 
        echo -e "${YELLOW}Note: Some features may require root access${NC}"
        sleep 2
    fi
    
    while true; do
        clear_screen
        display_header
        display_system_info
        display_metrics
        display_network
        display_top_processes
        
        echo -e "${BOLD}Refreshing every ${REFRESH_RATE} seconds... Press Ctrl+C to exit${NC}"
        sleep $REFRESH_RATE
    done
}

# Handle Ctrl+C gracefully
trap 'echo -e "\n${GREEN}Monitoring stopped.${NC}"; exit 0' INT

# Run main function
main