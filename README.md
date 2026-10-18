# 🚀 AutoDocker Installer: Cloud Web Desktop & Vibot Suite

Script instalasi otomatis **1 baris perintah (One-Line Command)** untuk menyiapkan **Web Desktop GUI (noVNC / Webtop XFCE)** beserta bot **Vibot (Vidara & DoodStream Multi-Proxy Viewer Bot)** di VPS Linux (Ubuntu / Debian) atau Docker Cloud Sandbox.

---

## ⚡ Perintah Cepat untuk Install (One-Line Command)

Cukup copy-paste perintah ini ke terminal Linux / VPS / Sandbox kamu:

```bash
curl -fsSL https://raw.githubusercontent.com/AbyanZainZ/AutoDocker_installer/main/install.sh | bash
```

---

## 🛠️ Apa Saja yang Dikerjakan Otomatis oleh Script Ini?
1. **Pemeriksaan Arsitektur & Dependensi Sistem:** Mendukung `x86_64` (AMD64) dan `aarch64` (ARM64).
2. **Instalasi Docker Engine Otomatis:** Jika Docker belum terpasang, script akan memasang Docker resmi.
3. **Peluncuran Web Desktop (Webtop XFCE):** Menjalankan container desktop di **Port 3000** dengan RAM shared memory 2 GB dan automount folder `$HOME` ke Desktop (`HostHome`).
4. **Download Otomatis Bot Vibot:** Meng-clone repository [Vibot](https://github.com/AbyanZainZ/Vibot) ke dalam folder `$HOME/Vibot`.
5. **Instalasi Python, Browser & Headless Drivers:** Memasang `playwright`, `camoufox`, binary Chromium & Firefox.

---

## 🖥️ Cara Akses Web Desktop
Setelah instalasi selesai:
* **Jika di VPS Biasa:** Buka browser dan kunjungi:
  `http://IP_VPS_KAMU:3000`
* **Jika di Docker Cloud Sandbox:** Buka URL publik dari Port 3000 yang sudah di-expose:
  `https://3000-<SANDBOX_ID>.sbx.sandboxes-cloud.docker.com/`

---

## 🤖 Cara Menjalankan Bot di Dalam Desktop / Terminal
1. Buka terminal atau folder `HostHome/Vibot` di Desktop:
   ```bash
   cd ~/Vibot
   ./start_bot.sh
   ```
2. Untuk mengedit target URL atau ganti protokol proxy (`http` / `socks5`), cukup edit file `config.json`.

---

## 🐳 Opsi Alternatif Menggunakan Docker Compose
```bash
docker compose up -d
```