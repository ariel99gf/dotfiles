#!/bin/bash
LOG="$HOME/Work/logs/health-$(date +%Y-%m-%d_%H-%M).log"
chk() { echo -e "\n=== $1 ===" >> "$LOG"; eval "$2" >> "$LOG" 2>&1; }
echo "Relatório de Saúde - $(date)" > "$LOG"
chk "Uptime" "uptime"
chk "Disco" "df -h / /home | grep -v loop"
chk "RAM" "free -h"
chk "Falhas Systemd" "systemctl --failed"
chk "Erros Kernel (24h)" "journalctl -k -p 3 --since '24 hours ago'"
chk "Docker" "docker ps --format 'table {{.Names}}\t{{.Status}}'"
find "$HOME/Work/logs" -name "health-*.log" -mtime +30 -delete
! systemctl --failed | grep -q "0 loaded units" && notify-send "⚠️ Alerta de Saúde" "Verifique $LOG" -u critical
