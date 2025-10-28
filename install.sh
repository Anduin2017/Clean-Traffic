#!/usr/bin/env bash
set -euo pipefail

Green="\033[32m"
Red="\033[31m"
Yellow="\033[33m"
Blue="\033[36m"
Font="\033[0m"
GreenBG="\033[42;37m"
RedBG="\033[41;37m"
OK="${Green}[  OK  ]${Font}"
ERROR="${Red}[FAILED]${Font}"
WARNING="${Yellow}[ WARN ]${Font}"

function print_ok() {
  echo -e "${OK} ${Blue} $1 ${Font}"
}

function print_error() {
  echo -e "${ERROR} ${Red} $1 ${Font}"
}

function print_warn() {
  echo -e "${WARNING} ${Yellow} $1 ${Font}"
}

function judge() {
  if [[ 0 -eq $? ]]; then
    print_ok "$1 succeeded"
  else
    print_error "$1 failed"
    exit 1
  fi
}

# $1 = Download URL
# $2 = Target destination (e.g. /etc/ufw/after.init)
# $3 = File mode (e.g. 0750)
install_exe_file() {
  local url=$1 dest=$2 mode=$3 tmp
  print_ok "Installing $(basename "$dest") from $url → $dest (mode $mode)"
  tmp=$(mktemp)
  wget -qO "$tmp" "$url"
  sudo install -m "$mode" "$tmp" "$dest"
  judge "Install $(basename "$dest")"

  rm -f "$tmp"
  judge "$(basename "$dest") installed successfully"
}

print_ok "Cleaning existing installation..."
sudo rm -f /etc/ufw/after.init /etc/cron.daily/auto-blacklist-update || true
judge "Clean previous installation"

print_ok "Installing dependencies..."
sudo apt update
sudo apt install -y ufw ipset curl wget
judge "Install dependencies"

print_ok "Installing Clean-Traffic hook..."
install_exe_file \
  "https://gitlab.aiursoft.com/anduin/clean-traffic/-/raw/master/after.init" \
  /etc/ufw/after.init 0750
sudo ufw reload

print_ok "Installing auto-blacklist-update..."
install_exe_file \
  "https://gitlab.aiursoft.com/anduin/clean-traffic/-/raw/master/auto-blacklist-update" \
  /etc/cron.daily/auto-blacklist-update 0755
# 验证 cron.daily 脚本会被执行

print_ok "Verifying cron.daily script execution..."
sudo run-parts --test /etc/cron.daily
judge "Verify cron.daily script execution"

print_ok "Triggering first update…"
sudo /etc/cron.daily/auto-blacklist-update
judge "Initial blacklist update"

print_ok "Clean-Traffic status:"
sudo /etc/ufw/after.init status
judge "Check Clean-Traffic status"