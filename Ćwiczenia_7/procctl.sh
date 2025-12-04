#!/bin/bash


function list_top_cpu() {
    echo "Top 5 procesów wg użycia CPU"
    ps aux --sort=-%cpu | head -n 6
}

function list_top_mem() {
    echo "Top 5 procesów wg użycia pamięci"
    ps aux --sort=-%mem | head -n 6
}

function show_process_tree() {
    echo "Drzewo procesów"
    pstree -p
}

function show_name_by_pid() {
    read -p "Podaj PID: " pid
    if ! [[ "$pid" =~ ^[0-9]+$ ]]; then
        echo "Błąd: PID musi być liczbą."
        return
    fi
    
    local proc_name=$(ps -p "$pid" -o comm= 2>/dev/null)

    if [ -n "$proc_name" ]; then
        echo "PID $pid odpowiada procesowi: $proc_name"
    else
        echo "Błąd: Proces o PID $pid nie istnieje."
    fi
}

function show_pid_by_name() {
    read -p "Podaj nazwę procesu: " name
    local pids=$(pgrep -l "$name")

    if [ -n "$pids" ]; then
        echo "Znalezione procesy dla '$name':"
        echo "$pids"
    else
        echo "Błąd: Nie znaleziono procesów o nazwie '$name'."
    fi
}

function kill_by_pid() {
    read -p "Podaj PID procesu do zabicia: " pid
    
    if ! [[ "$pid" =~ ^[0-9]+$ ]]; then
        echo "Błąd: PID musi być liczbą."
        return
    fi
    
    if kill -15 "$pid" 2>/dev/null; then
        echo "Wysłano sygnał do procesu $pid."
    else
        echo "Błąd: Nie można wysłać sygnału do procesu $pid. (Może nie istnieje lub brak uprawnień)."
    fi
}

function kill_by_name() {
    read -p "Podaj nazwę procesu do zabicia: " name
    
    if kill -15 "$name" 2>/dev/null; then
        echo "Wysłano sygnał do wszystkich procesów o nazwie '$name'."
    else
        echo "Błąd: Nie znaleziono procesów o nazwie '$name' lub brak uprawnień."
    fi
}


function show_menu() {
    echo ""
    echo "Process Control:"
    echo "1) List top 5 processes by CPU usage"
    echo "2) List top 5 processes by memory usage"
    echo "3) Show process tree"
    echo "4) Show process name by PID"
    echo "5) Show process PID(s) by name"
    echo "6) Kill process by PID"
    echo "7) Kill process by name"
    echo "q) Exit"
}

while true; do
    show_menu
    read -p "Choice: " choice

    case "$choice" in
        1)
            list_top_cpu
            ;;
        2)
            list_top_mem
            ;;
        3)
            show_process_tree
            ;;
        4)
            show_name_by_pid
            ;;
        5)
            show_pid_by_name
            ;;
        6)
            kill_by_pid
            ;;
        7)
            kill_by_name
            ;;
        [qQ])
            echo "Wychodzenie ze skryptu procctl."
            exit 0
            ;;
        *)
            echo "Nieprawidłowy wybór. Wprowadź cyfrę od 1 do 7 lub 'q' aby wyjść."
            ;;
    esac
    echo ""
    read -n 1 -s -r -p "Naciśnij dowolny klawisz, aby kontynuować..."
    echo ""
done
