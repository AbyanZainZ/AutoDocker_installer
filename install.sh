#!/usr/bin/env bash
# ==============================================================================
#  AUTODOCKER INSTALLER: CLOUD WEB DESKTOP & VIBOT SUITE
#  Repository: https://github.com/AbyanZainZ/AutoDocker_installer
#  Supports: Ubuntu, Debian, Docker Cloud Sandboxes, VPS (x86_64 & aarch64/arm64)
# ==============================================================================
set -e

echo "======================================================================"
echo " 🚀 MEMULAI AUTODOCKER INSTALLER (CLOUD WEB DESKTOP & VIBOT)"
echo "======================================================================"

ARCH=$(uname -m)
echo "[*] Arsitektur Sistem: $ARCH"
echo "[*] User: $(whoami)"
echo "[*] Direktori Home: $HOME"

# 1. Update OS & Paket Dasar
echo ""
echo "⏳ [1/5] Memperbarui sistem & paket dependensi dasar..."
if command -v apt-get &> /dev/null; then
    sudo apt-get update -y
    sudo apt-get install -y curl wget git python3 python3-pip python3-venv xvfb ca-certificates
fi

# 2. Cek & Pasang Docker
echo ""
echo "⏳ [2/5] Memeriksa Docker Engine..."
if ! command -v docker &> /dev/null; then
    echo "[*] Docker belum terpasang. Mengunduh dan memasang Docker resmi..."
    curl -fsSL https://get.docker.com -o get-docker.sh
    sh get-docker.sh
    rm -f get-docker.sh
    sudo usermod -aG docker "$(whoami)" 2>/dev/null || true
    echo "✅ Docker Engine berhasil dipasang!"
else
    echo "✅ Docker Engine sudah aktif."
fi

# 3. Jalankan Web Desktop (Webtop XFCE) di Port 3000
echo ""
echo "⏳ [3/5] Meluncurkan Web Desktop (Webtop Ubuntu XFCE) di Port 3000..."
if ! docker ps -a | grep -q "webtop"; then
    docker run -d \
      --name=webtop \
      --security-opt seccomp=unconfined \
      -e PUID=1000 \
      -e PGID=1000 \
      -e TZ=Asia/Jakarta \
      -p 3000:3000 \
      -v "$HOME":/config/Desktop/HostHome \
      --shm-size=2gb \
      --restart unless-stopped \
      lscr.io/linuxserver/webtop:ubuntu-xfce
    echo "✅ Container Webtop Desktop berhasil berjalan di background!"
else
    echo "ℹ️ Container Webtop sudah ada, memastikan status running..."
    docker start webtop || true
fi

# 4. Clone Repository Vibot ke Folder Host
echo ""
echo "⏳ [4/5] Mengunduh repository Vibot..."
TARGET_DIR="$HOME/Vibot"
if [ ! -d "$TARGET_DIR" ]; then
    git clone https://github.com/AbyanZainZ/Vibot.git "$TARGET_DIR"
    echo "✅ Repository Vibot berhasil di-clone ke: $TARGET_DIR"
else
    echo "ℹ️ Folder Vibot sudah ada, melakukan git pull terbaru..."
    cd "$TARGET_DIR" && git pull || true
fi

# 5. Pasang Library Python & Headless Browser
echo ""
echo "⏳ [5/5] Memasang library Python (Playwright, Camoufox, curl_cffi)..."
cd "$TARGET_DIR"

# Bypass PEP 668 globally in host and webtop
pip config set global.break-system-packages true 2>/dev/null || true
python3 -m pip config set global.break-system-packages true 2>/dev/null || true
docker exec webtop pip config set global.break-system-packages true 2>/dev/null || true

pip install --break-system-packages -r requirements.txt 2>/dev/null || \
python3 -m pip install --break-system-packages -r requirements.txt 2>/dev/null || \
pip install -r requirements.txt

echo "[*] Mengunduh binary browser Playwright..."
python3 -m playwright install chromium firefox 2>/dev/null || playwright install chromium firefox 2>/dev/null || true

# Berikan izin eksekusi script launcher
chmod +x "$TARGET_DIR/start_bot.sh" 2>/dev/null || true

SERVER_IP=$(curl -s https://api.ipify.org || echo "IP_SERVER_KAMU")

echo ""
echo "======================================================================"
echo " 🎉 INSTALASI AUTODOCKER & VIBOT SUKSES BESAR!"
echo "======================================================================"
echo " 🖥️ Akses Web Desktop (GUI Browser):"
echo "    http://$SERVER_IP:3000 (atau URL Expose Port Sandbox Docker kamu)"
echo ""
echo " 📁 Lokasi Bot:"
echo "    $TARGET_DIR (Tersedia juga di Desktop: HostHome/Vibot)"
echo ""
echo " 🚀 Cara Menjalankan Bot di Terminal:"
echo "    cd $TARGET_DIR"
echo "    ./start_bot.sh"
echo "======================================================================"
