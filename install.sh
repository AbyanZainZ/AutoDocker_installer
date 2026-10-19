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

export DEBIAN_FRONTEND=noninteractive

# 1. Update OS & Paket Dasar
echo ""
echo "⏳ [1/5] Memperbarui sistem & paket dependensi dasar..."
if command -v apt-get &> /dev/null; then
    sudo DEBIAN_FRONTEND=noninteractive apt-get update -y < /dev/null
    sudo DEBIAN_FRONTEND=noninteractive apt-get install -y -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" curl wget git python3 python3-pip python3-venv xvfb ca-certificates < /dev/null
fi

# 2. Cek & Pasang Docker
echo ""
echo "⏳ [2/5] Memeriksa Docker Engine..."
if ! command -v docker &> /dev/null; then
    echo "[*] Docker belum terpasang. Mengunduh dan memasang Docker resmi..."
    curl -fsSL https://get.docker.com -o get-docker.sh
    sh get-docker.sh < /dev/null
    rm -f get-docker.sh
    sudo usermod -aG docker "$(whoami)" 2>/dev/null || true
    echo "✅ Docker Engine berhasil dipasang!"
else
    echo "✅ Docker Engine sudah aktif."
fi

# 3. Tentukan Lokasi Folder VidBot
if [ "$(id -u)" -eq 0 ]; then
    TARGET_DIR="/VidBot"
else
    TARGET_DIR="$HOME/VidBot"
fi
mkdir -p "$TARGET_DIR" 2>/dev/null || true
echo "[*] Lokasi Folder Bot: $TARGET_DIR"

# 4. Hentikan container lama jika ada (termasuk tightvnc)
if docker ps -a | grep -q "tightvnc-desktop"; then
    echo "[*] Membersihkan container tightvnc lama..."
    docker stop tightvnc-desktop 2>/dev/null || true
    docker rm tightvnc-desktop 2>/dev/null || true
fi

# 5. Clone Repository VidBot ke Folder Mandiri
echo ""
echo "⏳ [3/5] Mengunduh repository VidBot..."
if [ ! -f "$TARGET_DIR/vidara_bot.py" ] && [ ! -d "$TARGET_DIR/.git" ]; then
    git clone https://github.com/AbyanZainZ/Vibot.git "$TARGET_DIR"
    echo "✅ Repository VidBot berhasil di-clone ke: $TARGET_DIR"
else
    echo "ℹ️ Folder $TARGET_DIR sudah ada, melakukan git pull terbaru..."
    cd "$TARGET_DIR" && git pull || true
fi

# Buat symlink agar mudah diakses di Desktop maupun Home
ln -s "$TARGET_DIR" "$HOME/VidBot" 2>/dev/null || true
ln -s "$TARGET_DIR" "/VidBot" 2>/dev/null || true

# 6. Jalankan Web Desktop (Webtop XFCE) di Port 3000
echo ""
echo "⏳ [4/5] Meluncurkan Web Desktop (Webtop Ubuntu XFCE) di Port 3000..."
if ! docker ps -a | grep -q "webtop"; then
    docker run -d \
      --name=webtop \
      --security-opt seccomp=unconfined \
      -e PUID=1000 \
      -e PGID=1000 \
      -e TZ=Asia/Jakarta \
      -p 3000:3000 \
      -v "$HOME":/config/Desktop/HostHome \
      -v "$TARGET_DIR":/config/Desktop/VidBot \
      --shm-size=2gb \
      --restart unless-stopped \
      lscr.io/linuxserver/webtop:ubuntu-xfce
    echo "✅ Container Webtop Desktop berhasil berjalan di background!"
else
    echo "ℹ️ Container Webtop sudah ada, memastikan status running..."
    docker start webtop || true
fi

# 7. Pasang Library Python di Host & di Container Desktop
echo ""
echo "⏳ [5/5] Memasang dependensi Python & browser engine..."
cd "$TARGET_DIR"

# Pasang di Host
if [ ! -d "$TARGET_DIR/venv" ]; then
    python3 -m venv "$TARGET_DIR/venv"
fi
"$TARGET_DIR/venv/bin/pip" install -U pip 2>/dev/null || true
"$TARGET_DIR/venv/bin/pip" install -r requirements.txt
"$TARGET_DIR/venv/bin/playwright" install chromium firefox 2>/dev/null || true
"$TARGET_DIR/venv/bin/python" -m camoufox fetch 2>/dev/null || true

# Pasang juga di dalam container Webtop agar terminal desktop langsung bisa menjalankan bot
echo "[*] Menyiapkan environment Python di dalam Web Desktop..."
docker exec -u 0 webtop bash -c "apt-get update -y && apt-get install -y python3 python3-pip python3-venv xvfb" 2>/dev/null || true
docker exec -u 0 webtop bash -c "pip3 install --break-system-packages -r /config/Desktop/VidBot/requirements.txt || pip3 install -r /config/Desktop/VidBot/requirements.txt" 2>/dev/null || true
docker exec -u 0 webtop bash -c "echo 'abc ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers" 2>/dev/null || true

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
cat << 'EOF' | sudo tee /usr/local/bin/cek_link > /dev/null
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
sudo chmod +x /usr/local/bin/cek_link 2>/dev/null || true
sudo cp /usr/local/bin/cek_link /usr/local/bin/check_link 2>/dev/null || true
sudo cp /usr/local/bin/cek_link /usr/local/bin/check-link 2>/dev/null || true

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
