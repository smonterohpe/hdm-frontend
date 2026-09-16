#!/usr/bin/env bash
# =============================================================================
# HDM — hdm-frontend
# install_frontend.sh — Instala nginx + frontend en Ubuntu 24.04
# Uso: sudo bash install_frontend.sh
# =============================================================================
set -euo pipefail

WEB_DIR="/var/www/hdm-frontend"

echo "=== HDM Frontend — Instalación ==="

apt-get update -qq
apt-get install -y nginx

mkdir -p "$WEB_DIR"
cp -r html/* "$WEB_DIR/"
chown -R www-data:www-data "$WEB_DIR"

cp nginx/hdm-frontend.conf /etc/nginx/sites-available/hdm-frontend
ln -sf /etc/nginx/sites-available/hdm-frontend /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default

nginx -t && systemctl reload nginx
systemctl enable nginx

echo "=== Frontend listo en http://0.0.0.0:8081 ==="
