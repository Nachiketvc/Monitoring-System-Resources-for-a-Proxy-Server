#!/bin/bash

# Function to refresh current case only
refresh_case() {
    echo "Refreshing this case in 100 seconds..."
    sleep 100
    exec "$0" "$1"
}

# 2. Network Monitoring Functions
INTERFACE=$(ip route | grep default | awk '{print $5}')

get_concurrent_connections() {
    echo "Concurrent connections: $(netstat -an | grep ESTABLISHED | wc -l)"
}

get_packet_drops() {
    echo "Total packet drops: $(cat /proc/net/snmp | grep 'Tcp:' | tail -n 1 | awk '{print $14}')"
}

get_packets_transferred() {
    RX_BYTES=$(grep "$INTERFACE" /proc/net/dev | awk '{print $2}')
    TX_BYTES=$(grep "$INTERFACE" /proc/net/dev | awk '{print $10}')
    RX_MB=$(echo "scale=2; $RX_BYTES / 1048576" | bc)
    TX_MB=$(echo "scale=2; $TX_BYTES / 1048576" | bc)
    echo "Data received: ${RX_MB} MB"
    echo "Data transmitted: ${TX_MB} MB"
}

get_active_connections() {
    echo "Active Connections:"
    netstat -tunapl | grep ESTABLISHED
}

# Function to generate progress bars
generate_bar() {
    usage=$1
    total_blocks=10
    used_blocks=$((usage * total_blocks / 100))
    empty_blocks=$((total_blocks - used_blocks))
    echo -n "["
    printf '#%.0s' $(seq 1 $used_blocks)
    printf ' %.0s' $(seq 1 $empty_blocks)
    echo -n "]"
}

# Updated function to prevent clearing for case 8
display_dashboard() {
    if [ "$1" != "no_clear" ]; then
        clear
    fi
    echo "===== System Monitoring Dashboard ====="
    get_concurrent_connections
    get_packet_drops
    get_packets_transferred
    get_active_connections
    echo "======================================="
}


# 3. Display memory usage

display_memory_usage() {
    echo "| Disks:                                        |"

    # Get all available disks (even if not mounted)
    available_disks=$(lsblk -d -o NAME | grep '^sd')

    warning_shown=false  # Track if any warning is displayed

    # Iterate over each disk
    for disk in $available_disks; do
        disk_path="/dev/$disk"
        mountpoint=$(findmnt -n -o TARGET $disk_path 2>/dev/null)
        
        # Check if disk is mounted
        if [[ -z "$mountpoint" ]]; then
            echo "| $disk_path: Not Mounted                      |"
        else
            usage=$(df -h | grep $disk_path | awk '{print $5}' | sed 's/%//')
            echo -n "| $disk_path ($mountpoint): "
            echo -n "$(generate_bar $usage)"
            echo "  ${usage}%"

            # Warning if usage is above 80%
            if [[ $usage -gt 80 ]]; then
                echo "| WARNING: $disk_path is above 80% usage!      |"
                warning_shown=true
            fi
        fi
    done

    # Check /var usage separately
    var_usage=$(df -h /var 2>/dev/null | awk 'NR==2 {print $5}' | sed 's/%//')
    if [[ -n "$var_usage" ]]; then
        echo -n "| /var:      "
        echo -n "$(generate_bar $var_usage)"
        echo "  ${var_usage}%"
        
        if [[ $var_usage -gt 80 ]]; then
            echo "| WARNING: /var is above 80% usage!           |"
            warning_shown=true
        fi
    fi

    # If no warnings were shown, print "WARNING: None"
    if [[ "$warning_shown" == false ]]; then
        echo "| WARNING: None                                |"
    fi

    echo "+------------------------------------------------+"
}


# 4. System Load and CPU Breakdown
display_system_load() {
    echo "| System Load: $(cat /proc/loadavg | awk '{print $1, $2, $3}') |"
    cpu_data=$(top -bn1 | grep "Cpu(s)" | awk '{print $2, $4, $6, $8, $10}')
    cpu_user=$(echo $cpu_data | awk '{print $1}')
    cpu_system=$(echo $cpu_data | awk '{print $2}')
    cpu_idle=$(echo $cpu_data | awk '{print $3}')
    cpu_iowait=$(echo $cpu_data | awk '{print $4}')
    cpu_steal=$(echo $cpu_data | awk '{print $5}')
    echo "| CPU Breakdown:                                 |"
    echo "| User: $cpu_user%   System: $cpu_system%        |"
    echo "| Idle: $cpu_idle%   I/O Wait: $cpu_iowait%      |"
    echo "| Steal: $cpu_steal%                             |"
    mem_info=$(free -m | awk 'NR==2 {printf "%d %d", $3, $2}')
    mem_used=$(echo $mem_info | cut -d ' ' -f1)
    mem_total=$(echo $mem_info | cut -d ' ' -f2)
    mem_percent=$((mem_used * 100 / mem_total))
    echo -n "| Memory:    "
    echo -n "$(generate_bar $mem_percent)"
    echo "  ${mem_percent}%   Swap: $(free -m | awk '/Swap/ {print $3 "MB / " $2 "MB"}') |"
}


# 5. Memory Usage Monitoring Module
memory_usage_monitoring() {
    mem_total=$(free -m | awk 'NR==2 {print $2}')
    mem_used=$(free -m | awk 'NR==2 {print $3}')
    mem_free=$(free -m | awk 'NR==2 {print $4}')
    mem_percent=$((mem_used * 100 / mem_total))

    echo "| Memory Usage:                                  |"
    echo "| Total: ${mem_total}MB   Used: ${mem_used}MB   Free: ${mem_free}MB |"
    echo -n "| RAM:       "
    echo -n "$(generate_bar $mem_percent)"
    echo "  ${mem_percent}%"

    # Swap Memory Usage
    swap_total=$(free -m | awk 'NR==3 {print $2}')
    swap_used=$(free -m | awk 'NR==3 {print $3}')
    swap_free=$(free -m | awk 'NR==3 {print $4}')
    swap_percent=0
    if [ "$swap_total" -gt 0 ]; then
        swap_percent=$((swap_used * 100 / swap_total))
    fi

    echo "| Swap Memory:                                  |"
    echo "| Total: ${swap_total}MB   Used: ${swap_used}MB   Free: ${swap_free}MB |"
    echo -n "| Swap:      "
    echo -n "$(generate_bar $swap_percent)"
    echo "  ${swap_percent}%"
}


# 6. Process_Monitoring

process_monitoring() {
    echo "+------------------------------------------------+"
    echo "|                Process Monitoring             |"
    echo "+------------------------------------------------+"

    # Total Active Processes
    total_processes=$(ps aux --no-heading | wc -l)
    printf "| %-44s |\n" "Active Processes: $total_processes"

    # Function to get top processes
    get_top_processes() {
        local sort_by=$1
        local header=$2

        echo "| $header                                      |"
        echo "| PID   USER     CPU%  MEM%  COMMAND            |"
        echo "|------------------------------------------------|"
        ps -eo pid,user,pcpu,pmem,comm --sort=-%$sort_by | head -6 | awk '{printf "| %-5s %-8s %-5s %-5s %-15s |\n", $1, $2, $3"%", $4"%", $5}'
        echo "|------------------------------------------------|"
    }

    # Top 5 CPU-Consuming Processes
    get_top_processes "cpu" "Top 5 CPU-Consuming Processes"

    # Top 5 Memory-Consuming Processes
    get_top_processes "mem" "Top 5 Memory-Consuming Processes"

    echo "+------------------------------------------------+"
}


# 7. service monitoring

service_monitoring() {
    echo "+------------------------------------------------+"
    echo "|                Service Monitoring             |"
    echo "+------------------------------------------------+"

    services=("sshd" "nginx" "apache2" "iptables")

    printf "| %-15s | %-20s |\n" "Service" "Status"
    echo "|-----------------|----------------------|"

    for service in "${services[@]}"; do
        if systemctl is-active --quiet "$service"; then
            status="Running ✅"
        elif systemctl is-enabled --quiet "$service"; then
            status="Stopped ❌ (Enabled)"
        else
            status="Not Installed ⛔"
        fi
        printf "| %-15s | %-20s |\n" "$service" "$status"
    done
}


# Display help message
display_help() {
    echo "Usage: $0 [OPTIONS]"
    echo "Options:"
    echo "  --cpu          Display CPU and System Load"
    echo "  --memory       Display Memory Usage"
    echo "  --network      Display Network Monitoring"
    echo "  --disk         Display Disk Usage"
    echo "  --process      Display Process Monitoring"
    echo "  --services     Display Service Monitoring"
    echo "  --all          Display All Metrics"
    echo "  --help         Show this help message"
}

# Check if an argument is passed
if [[ -n "$1" ]]; then
    case "$1" in
        --cpu)
            display_system_load
            exit 0
            ;;
        --memory)
            memory_usage_monitoring
            exit 0
            ;;
        --network)
            display_dashboard
            exit 0
            ;;
        --disk)
            display_memory_usage
            exit 0
            ;;
        --process)
            process_monitoring
            exit 0
            ;;
        --services)
            service_monitoring
            exit 0
            ;;
        --all)
            display_system_load
            memory_usage_monitoring
            display_dashboard
            display_memory_usage
            process_monitoring
            service_monitoring
            exit 0
            ;;
        --help)
            display_help
            exit 0
            ;;
        *)
            echo "🚨 Invalid choice. Please enter a valid option (1-8)."
            display_help
            exit 1
            ;;
    esac
fi



# If an argument is passed, use it as the case choice
if [[ -n "$1" ]]; then
    choice="$1"
else
    echo "Select an option:"
    echo "1 - Display Top 10 Applications by CPU and Memory Usage"
    echo "2 - Network Monitoring"
    echo "3 - Display Memory Usage"
    echo "4 - System Load and CPU Breakdown"
    echo "5 - Memory Usage"
    echo "6 - Process Monitoring"
    echo "7 - Service Monitoring"
    echo "8 - Display All"
    read -p "Enter your choice (1, 2, 3, 4, 5, 6, 7, 8): " choice
fi

case $choice in
    1)
        echo "Top 10 Applications by CPU Usage:"
        ps -eo pid,comm,%cpu --sort=-%cpu | head -n 11
        echo ""
        echo "Top 10 Applications by Memory Usage:"
        ps -eo pid,comm,%mem --sort=-%mem | head -n 11
        refresh_case 1
        ;;
    2)
        display_dashboard
        refresh_case 2
        ;;
    3)
        echo "+------------------------------------------------+"
        echo "|         DISPLAY DISK UDSAGE                  |"
        echo "+------------------------------------------------+"
        display_memory_usage
        echo "+------------------------------------------------+"
        refresh_case 3
        ;;
    4)
        display_system_load
        refresh_case 4
        ;;

    5) 
	memory_usage_monitoring
	refresh_case 5
	;;

    6) 
        process_monitoring
	refresh_case 6
	;;

    7) 
        service_monitoring
	refresh_case 7
	;;


        8)
        echo -e "\n====================================="
        echo "       Displaying All Metrics"
        echo "=====================================\n"

        echo "===== Top 10 CPU-Consuming Applications ====="
        ps -eo pid,comm,%cpu --sort=-%cpu | head -n 11
        echo ""

        echo "===== Top 10 Memory-Consuming Applications ====="
        ps -eo pid,comm,%mem --sort=-%mem | head -n 11
        echo ""

        echo "===== Network Monitoring ====="
        display_dashboard "no_clear"
        echo ""

        echo "===== Disk Usage ====="
        display_memory_usage
        echo ""

        echo "===== System Resource Usage ====="
        display_system_load
        echo ""

        echo "===== Memory Usage ====="
        memory_usage_monitoring
        echo ""

        echo "===== Process Monitoring ====="
        process_monitoring
        echo ""

        echo "===== Service Monitoring ====="
        service_monitoring
        echo ""

        refresh_case 8
        ;;

    *)
        echo -e "\n🚨 Invalid choice. Please enter a valid option (1-8)."
        ;;
esac


