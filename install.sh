#!/usr/bin/env bash
set -euo pipefail

SITE_DOMAIN="${SITE_DOMAIN:-yourdomain.ru}"
EMAIL="${EMAIL:-admin@${SITE_DOMAIN}}"

XRAY_PORT="${XRAY_PORT:-443}"
FALLBACK_PORT="${FALLBACK_PORT:-7443}"

if ! command -v docker >/dev/null 2>&1; then
  echo "docker not found"
  exit 1
fi

if ! command -v openssl >/dev/null 2>&1; then
  echo "openssl not found"
  exit 1
fi

if ! command -v curl >/dev/null 2>&1; then
  echo "curl not found"
  exit 1
fi

if docker compose version >/dev/null 2>&1; then
  COMPOSE="docker compose"
elif command -v docker-compose >/dev/null 2>&1; then
  COMPOSE="docker-compose"
else
  echo "docker compose not found"
  exit 1
fi

echo
echo "=================================================="
echo "AUTO XRAY REALITY INSTALLER"
echo "=================================================="
echo

echo "SITE_DOMAIN=${SITE_DOMAIN}"
echo "EMAIL=${EMAIL}"
echo "XRAY_PORT=${XRAY_PORT}"
echo "FALLBACK_PORT=${FALLBACK_PORT}"
echo

echo "Generating UUID and REALITY keys..."

UUID="$(docker run --rm ghcr.io/xtls/xray-core uuid)"

KEYS="$(docker run --rm ghcr.io/xtls/xray-core x25519)"

PRIVATE_KEY="$(echo "${KEYS}" | awk -F': ' '/Private key/ {print $2}')"
PUBLIC_KEY="$(echo "${KEYS}" | awk -F': ' '/Public key/ {print $2}')"

SHORT_ID="$(openssl rand -hex 8)"

if [ -z "${UUID}" ] || [ -z "${PRIVATE_KEY}" ] || [ -z "${PUBLIC_KEY}" ] || [ -z "${SHORT_ID}" ]; then
  echo "failed to generate UUID or REALITY keys"
  exit 1
fi

echo
echo "Configuring firewall..."

if command -v ufw >/dev/null 2>&1; then
  ufw allow 80/tcp || true
  ufw allow 443/tcp || true
elif command -v firewall-cmd >/dev/null 2>&1; then
  firewall-cmd --permanent --add-port=80/tcp || true
  firewall-cmd --permanent --add-port=443/tcp || true
  firewall-cmd --reload || true
elif command -v iptables >/dev/null 2>&1; then
  iptables -I INPUT -p tcp --dport 80 -j ACCEPT || true
  iptables -I INPUT -p tcp --dport 443 -j ACCEPT || true
fi

echo
echo "Requesting Let's Encrypt certificate..."

docker run --rm \
  -p 80:80 \
  -v /etc/letsencrypt:/etc/letsencrypt \
  -v /var/lib/letsencrypt:/var/lib/letsencrypt \
  certbot/certbot certonly \
  --standalone \
  --non-interactive \
  --agree-tos \
  --email "${EMAIL}" \
  -d "${SITE_DOMAIN}"

echo
echo "Generating config.json..."

sed \
  -e "s|__XRAY_PORT__|${XRAY_PORT}|g" \
  -e "s|__FALLBACK_PORT__|${FALLBACK_PORT}|g" \
  -e "s|__UUID__|${UUID}|g" \
  -e "s|__PRIVATE_KEY__|${PRIVATE_KEY}|g" \
  -e "s|__SHORT_ID__|${SHORT_ID}|g" \
  -e "s|__SITE_DOMAIN__|${SITE_DOMAIN}|g" \
  config.template.json > config.json

echo
echo "Generating nginx.conf..."

sed \
  -e "s|__FALLBACK_PORT__|${FALLBACK_PORT}|g" \
  -e "s|__SITE_DOMAIN__|${SITE_DOMAIN}|g" \
  nginx.template.conf > nginx.conf

echo
echo "Starting containers..."

${COMPOSE} pull
${COMPOSE} up -d

SERVER_IP="$(curl -4 -s https://ifconfig.me || true)"

if [ -z "${SERVER_IP}" ]; then
  SERVER_IP="$(hostname -I | awk '{print $1}')"
fi

echo
echo "=================================================="
echo "INSTALLATION COMPLETE"
echo "=================================================="
echo
echo "SITE:"
echo "https://${SITE_DOMAIN}"
echo
echo "VLESS LINK:"
echo
echo "vless://${UUID}@${SERVER_IP}:${XRAY_PORT}?encryption=none&security=reality&sni=${SITE_DOMAIN}&fp=chrome&pbk=${PUBLIC_KEY}&sid=${SHORT_ID}&type=tcp&flow=xtls-rprx-vision#auto-xray"
echo
echo "LOGS:"
echo "${COMPOSE} logs -f"
echo