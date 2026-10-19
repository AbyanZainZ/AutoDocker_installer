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
HOST_NAME=$(hostname)
echo "[*] Arsitektur Sistem: $ARCH"
echo "[*] Hostname Mesin: $HOST_NAME"
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

# 4. Clone Repository VidBot ke Folder Mandiri
echo ""
echo "⏳ [4/5] Mengunduh repository VidBot..."
if [ "$(id -u)" -eq 0 ]; then
    TARGET_DIR="/VidBot"
else
    TARGET_DIR="$HOME/VidBot"
fi
echo "[*] Lokasi Folder Bot: $TARGET_DIR"

if [ ! -d "$TARGET_DIR" ]; then
    git clone https://github.com/AbyanZainZ/Vibot.git "$TARGET_DIR"
    echo "✅ Repository VidBot berhasil di-clone ke: $TARGET_DIR"
else
    echo "ℹ️ Folder $TARGET_DIR sudah ada, melakukan git pull terbaru..."
    cd "$TARGET_DIR" && git pull || true
fi

# Buat symlink agar mudah diakses di Desktop maupun Home
ln -s "$TARGET_DIR" "$HOME/VidBot" 2>/dev/null || true
ln -s "$TARGET_DIR" "/VidBot" 2>/dev/null || true

# 5. Pasang Library Python & Browser Engine di VENV Mandiri
echo ""
echo "⏳ [5/5] Memasang library Python di $TARGET_DIR/venv ..."
cd "$TARGET_DIR"

if [ ! -d "$TARGET_DIR/venv" ]; then
    python3 -m venv "$TARGET_DIR/venv"
fi

"$TARGET_DIR/venv/bin/pip" install -U pip 2>/dev/null || true
"$TARGET_DIR/venv/bin/pip" install -r requirements.txt

echo "[*] Menyiapkan browser engine (Playwright & Camoufox)..."
"$TARGET_DIR/venv/bin/playwright" install chromium firefox 2>/dev/null || true
"$TARGET_DIR/venv/bin/python" -m camoufox fetch 2>/dev/null || true

# Berikan izin eksekusi script launcher
chmod +x "$TARGET_DIR/start_bot.sh" 2>/dev/null || true
chmod +x "$TARGET_DIR/start_proxyScrape.sh" 2>/dev/null || true

# 6. Deteksi Otomatis URL Web Desktop & Buat Command 'cek_link'
if [[ "$HOST_NAME" =~ ^sbx[-_](.+) ]]; then
    SBX_ID="${BASH_REMATCH[1]}"
    DESKTOP_URL="https://3000-${SBX_ID}.sbx.sandboxes-cloud.docker.com/"
    ENV_DESC="Docker Cloud Sandbox"
else
    SERVER_IP=$(curl -s https://api.ipify.org || echo "IP_SERVER_KAMU")
    DESKTOP_URL="http://${SERVER_IP}:3000"
    ENV_DESC="Standar VPS / Server Linux"
fi

# Buat script bantuan 'cek_link' dan 'check_link' yang bisa dipanggil kapan saja
cat << 'EOF' > /usr/local/bin/cek_link
#!/usr/bin/env bash
HOST_NAME=$(hostname)
if [[ "$HOST_NAME" =~ ^sbx[-_](.+) ]]; then
    SBX_ID="${BASH_REMATCH[1]}"
    echo "======================================================================"
    echo " 🖥️ LINK WEB DESKTOP (DOCKER CLOUD SANDBOX):"
    echo " 👉 https://3000-${SBX_ID}.sbx.sandboxes-cloud.docker.com/"
    echo "======================================================================"
else
    SERVER_IP=$(curl -s https://api.ipify.org || echo "IP_SERVER_KAMU")
    echo "======================================================================"
    echo " 🖥️ LINK WEB DESKTOP (VPS):"
    echo " 👉 http://${SERVER_IP}:3000"
    echo "======================================================================"
fi
EOF
chmod +x /usr/local/bin/cek_link 2>/dev/null || true
cp /usr/local/bin/cek_link /usr/local/bin/check_link 2>/dev/null || true
cp /usr/local/bin/cek_link /usr/local/bin/check-link 2>/dev/null || true

echo ""
echo "======================================================================"
echo " 🎉 INSTALASI AUTODOCKER & VIBOT SUKSES BESAR!"
echo "======================================================================"
echo " [*] Tipe Lingkungan: $ENV_DESC"
echo ""
echo " 🖥️ Link Akses Web Desktop (GUI Browser):"
echo "    👉 $DESKTOP_URL"
echo "    (Buka link di atas pada browser untuk melihat tampilan desktop!)"
echo ""
echo " 💡 Cek Link Kapan Saja:"
echo "    Ketik perintah: cek_link"
echo ""
echo " 📁 Lokasi Bot:"
echo "    $TARGET_DIR (Tersedia juga di Desktop: HostHome/VidBot)"
echo ""
echo " 🚀 Cara Menjalankan Bot di Terminal:"
echo "    cd $TARGET_DIR"
echo "    ./start_bot.sh"
echo "======================================================================"
