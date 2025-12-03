#!/bin/bash

EXIT_STATUS=0

function get_cpu_info() {
    local cpu_model=$(grep -m 1 "model name" /proc/cpuinfo | awk -F': ' '{print $2}' | sed 's/  */ /g')
    echo "CPU: ${cpu_model}"
}

function get_ram_info() {
    local total_mib=$(free -m | awk '/Mem:/ {print $2}')
    local used_mib=$(free -m | awk '/Mem:/ {print $3}')
    
    if [ -n "$total_mib" ] && [ -n "$used_mib" ] && [ "$total_mib" -gt 0 ]; then
        local used_percent=$(awk "BEGIN {printf \"%.0f\", (${used_mib} / ${total_mib}) * 100}")
        echo "RAM: ${used_mib} / ${total_mib} MiB (${used_percent}% used)"
    else
        echo "RAM: N/A"
    fi
}

function get_load_info() {
    local load_avg=$(uptime | awk -F'load average: ' '{print $2}' | sed 's/,//g')
    echo "Load: ${load_avg}"
}

function get_uptime_info() {
    local uptime_str=$(uptime | awk -F', *' '{print $2}')
    echo "Uptime: ${uptime_str}"
}

function get_kernel_info() {
    local kernel_ver=$(uname -r)
    echo "Kernel: ${kernel_ver}"
}

function get_gpu_info() {
    local gpu_info=$(lspci -v | awk '/VGA compatible controller/{getline; print}' | grep -m 1 'Subsystem' | sed 's/.*Subsystem: //; s/ (rev.*//')
    
    if [ -z "$gpu_info" ]; then
        gpu_info=$(lspci -m | grep -i vga | awk '{print $NF}' | sed 's/\]//g' | head -n 1)
        full_gpu_name=$(lspci -v | awk '/VGA compatible controller/{p=1; next}/^$/{p=0}p' | grep -m 1 'Subsystem' | awk -F': ' '{print $2}' | sed 's/ (rev [0-9a-f]\+)//')
        
        if [ -n "$full_gpu_name" ]; then
            gpu_desc=$(lspci -v | grep -A 1 'VGA compatible controller' | grep -m 1 'Kernel driver in use' | awk '{print $NF}')
            gpu_name_rev=$(lspci -v | grep -A 1 'VGA compatible controller' | head -n 1 | awk -F': ' '{print $2}')
            echo "GPU: ${gpu_name_rev}"
        else
            gpu_name=$(lspci -k | awk '/VGA compatible controller/{p=1;next}p' | grep -m 1 'Subsystem:' | awk -F': ' '{print $2}')
            if [ -n "$gpu_name" ]; then
                echo "GPU: ${gpu_name}"
            else
                echo "GPU: Brak informacji lub nie znaleziono"
            fi
        fi
    else
        gpu_name_rev=$(lspci -v | grep -A 1 'VGA compatible controller' | head -n 1 | awk -F': ' '{print $2}' | sed 's/ (rev.*//')
        gpu_rev=$(lspci -v | grep -A 1 'VGA compatible controller' | head -n 1 | grep -o '(rev [0-9a-f]\+)' | sed 's/[()]//g')
        echo "GPU: ${gpu_name_rev} (${gpu_rev})"
    fi
}

function get_user_info() {
    echo "User: ${USER}"
}

function get_shell_info() {
    local current_shell=$(basename "$SHELL")
    echo "Shell: ${current_shell}"
}

function get_processes_info() {
    local num_proc=$(ps -e | wc -l)
    num_proc=$((num_proc - 1))
    echo "Processes: ${num_proc}"
}

function get_threads_info() {
    local num_threads=$(ps -eL | wc -l)
    num_threads=$((num_threads - 1))
    echo "Threads: ${num_threads}"
}

function get_ip_info() {
    local ip_list=""
    while IFS= read -r line; do
        local ip_addr=$(echo "$line" | awk '{print $2}')
        if [ -n "$ip_list" ]; then
            ip_list="${ip_list} ${ip_addr}"
        else
            ip_list="${ip_addr}"
        fi
    done < <(ip addr show | grep -E 'inet .*scope global')

    ip_list="127.0.0.1/8 ${ip_list}"
    
    echo "IP: ${ip_list}"
}

function get_dns_info() {
    local dns_server=$(grep -m 1 "nameserver" /etc/resolv.conf | awk '{print $2}')
    echo "DNS: ${dns_server}"
}

function check_internet() {
    if timeout 1 ping -c 1 8.8.8.8 > /dev/null 2>&1; then
        echo "Internet: OK"
    else
        echo "Internet: Down"
    fi
}

declare -A INFO_MAP=(
    ["cpu"]="get_cpu_info"
    ["ram"]="get_ram_info"
    ["load"]="get_load_info"
    ["uptime"]="get_uptime_info"
    ["kernel"]="get_kernel_info"
    ["gpu"]="get_gpu_info"
    ["user"]="get_user_info"
    ["shell"]="get_shell_info"
    ["processes"]="get_processes_info"
    ["threads"]="get_threads_info"
    ["ip"]="get_ip_info"
    ["dns"]="get_dns_info"
    ["internet"]="check_internet"
)

ALL_KEYS=("cpu" "ram" "load" "uptime" "kernel" "gpu" "user" "shell" "processes" "threads" "ip" "dns" "internet")

function main() {
    if [ $# -eq 0 ]; then
        for key in "${ALL_KEYS[@]}"; do
            ${INFO_MAP[${key}]}
        done
        return
    fi

    local found_one=false
    local invalid_arg_found=false
    local invalid_args=()
    local requested_keys=()

    for arg in "$@"; do
        local lower_arg=$(echo "$arg" | tr '[:upper:]' '[:lower:]')
        
        if [[ " ${ALL_KEYS[@]} " =~ " ${lower_arg} " ]]; then
            requested_keys+=("$lower_arg")
            found_one=true
        else
            invalid_arg_found=true
            invalid_args+=("$arg")
        fi
    done
    
    for key in "${requested_keys[@]}"; do
        ${INFO_MAP[${key}]}
    done
    
    if $invalid_arg_found; then
        EXIT_STATUS=1
    fi
}

main "$@"

exit $EXIT_STATUS
