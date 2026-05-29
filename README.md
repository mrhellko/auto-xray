# auto-xray

Автоматическая установка Xray VLESS REALITY + fallback HTTPS сайта.

---

# Требования

На сервере должны быть установлены:

- docker compose

Порты:

- 80/tcp
- 443/tcp

должны быть открыты.

---

# Установка

```bash
git clone https://github.com/mrhellko/auto-xray.git

cd auto-xray

chmod +x install.sh

SITE_DOMAIN=your-domain.ru EMAIL=admin@your-domain.ru ./install.sh
```
Если нет домена, можно использовать ip адрес. Почта любая, для сертификата для сайта.

---

# Что делает install.sh

- генерирует UUID;
- генерирует REALITY private/public keys;
- генерирует shortId;
- получает Let's Encrypt сертификат;
- генерирует config.json;
- генерирует nginx.conf;
- запускает docker compose.

---

## Firewall

Скрипт автоматически пытается открыть:

- 80/tcp
- 443/tcp

Поддерживаются:

- ufw
- firewalld
- iptables

---

# Проверка

Проверка контейнеров:

```bash
docker compose ps
```

Логи:

```bash
docker compose logs -f
```

---

# Проверка сайта

```bash
curl -I https://your-domain.ru
```

---

# Клиенты

Поддерживаются:

- NekoBox
- v2rayNG
- Hiddify
- Streisand
- Shadowrocket

---

# Удаление

```bash
docker rm -f xray_vpn xray_fallback_site
```


# FAQ
Q: При использовании VPN на некоторых сайтах возникает ошибка про невалидный сертфикат.  
A: Отключить FakeDNS и маршрутизацию DNS на vpn клиенте.
