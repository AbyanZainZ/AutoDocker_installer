#!/usr/bin/env bash
# ==============================================================================
#  AUTODOCKER: ULTRA-LIGHTWEIGHT TIGHTVNC / TIGERVNC + NOVNC DUAL MODE EDITION
#  Repository: https://github.com/AbyanZainZ/AutoDocker_installer
#  Features:
#    1. Web Browser (noVNC HTML5 canvas - super light RFB protocol)
#    2. Native VNC Viewer (TightVNC / RealVNC / TigerVNC - Zero Lag)
#    3. Preconfigured VidBot Suite (Playwright, Camoufox, Proxy Scraper)
# ==============================================================================
set -e

echo "======================================================================"
echo " 🚀 MEMULAI AUTODOCKER (TIGHTVNC & NOVNC DUAL MODE EDITION)"
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

# 4. Hentikan container lama yang berat (Webtop/KasmVNC) jika ada
if docker ps -a | grep -q "webtop"; then
    echo "[*] Menghentikan container Webtop lama yang berat..."
    docker stop webtop 2>/dev/null || true
    docker rm webtop 2>/dev/null || true
fi

# 5. Jalankan TightVNC + noVNC Container (accetto/ubuntu-vnc-xfce-g3)
echo ""
echo "⏳ [3/5] Meluncurkan Desktop Ultra-Ringan (TigerVNC / TightVNC + noVNC)..."
VNC_PASS="vidbot123"

if ! docker ps -a | grep -q "tightvnc-desktop"; then
    docker run -d \
      --name=tightvnc-desktop \
      -p 3000:6901 \
      -p 5901:5901 \
      -e VNC_PW="$VNC_PASS" \
      -e VNC_RESOLUTION="1280x720" \
      -v "$TARGET_DIR":/home/headless/Desktop/VidBot \
      -v "$TARGET_DIR":/VidBot \
      --shm-size=1gb \
      --restart unless-stopped \
      accetto/ubuntu-vnc-xfce-g3
    echo "✅ Container TightVNC Desktop berhasil berjalan!"
else
    echo "ℹ️ Container tightvnc-desktop sudah ada, memastikan status running..."
    docker start tightvnc-desktop || true
fi

# 6. Clone Repository VidBot
echo ""
echo "⏳ [4/5] Mengunduh repository VidBot..."
echo "[*] Lokasi Folder Bot: $TARGET_DIR"

if [ ! -f "$TARGET_DIR/main.py" ] && [ ! -d "$TARGET_DIR/.git" ]; then
    git clone https://github.com/AbyanZainZ/Vibot.git "$TARGET_DIR"
    echo "✅ Repository VidBot berhasil di-clone ke: $TARGET_DIR"
else
    echo "ℹ️ Folder $TARGET_DIR sudah ada, melakukan git pull terbaru..."
    cd "$TARGET_DIR" && git pull || true
fi

# Buat symlink agar mudah diakses di Desktop maupun Home
ln -s "$TARGET_DIR" "$HOME/VidBot" 2>/dev/null || true
ln -s "$TARGET_DIR" "/VidBot" 2>/dev/null || true

# 7. Pasang Library Python & Browser Engine di VENV Mandiri
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

# 8. Deteksi Otomatis URL & Perintah 'cek_link'
if [[ "$HOST_NAME" =~ ^sbx[-_](.+) ]]; then
    SBX_ID="${BASH_REMATCH[1]}"
    WEB_URL="https://3000-${SBX_ID}.sbx.sandboxes-cloud.docker.com/vnc.html?autoconnect=true&password=${VNC_PASS}"
    WEB_BASE="https://3000-${SBX_ID}.sbx.sandboxes-cloud.docker.com/"
    NATIVE_INFO="Gunakan SSH Tunnel: ssh -N -L 5901:127.0.0.1:5901 <user>@sbx_cloud lalu buka TightVNC Viewer ke 127.0.0.1:5901"
    ENV_DESC="Docker Cloud Sandbox"
else
    SERVER_IP=$(curl -s https://api.ipify.org || echo "IP_SERVER_KAMU")
    WEB_URL="http://${SERVER_IP}:3000/vnc.html?autoconnect=true&password=${VNC_PASS}"
    WEB_BASE="http://${SERVER_IP}:3000"
    NATIVE_INFO="Buka TightVNC / RealVNC Viewer ke: ${SERVER_IP}:5901"
    ENV_DESC="Standar VPS / Server Linux"
fi

# Buat script bantuan 'cek_link'
cat << EOF | sudo tee /usr/local/bin/cek_link > /dev/null
#!/usr/bin/env bash
HOST_NAME=\$(hostname)
VNC_PASS="${VNC_PASS}"
if [[ "\$HOST_NAME" =~ ^sbx[-_](.+) ]]; then
    SBX_ID="\${BASH_REMATCH[1]}"
    echo "======================================================================"
    echo " 🖥️ AKSES TIGHTVNC / NOVNC DESKTOP (DOCKER CLOUD SANDBOX):"
    echo "======================================================================"
    echo " 1. 🌐 VIA WEB BROWSER (noVNC HTML5):"
    echo "    👉 https://3000-\${SBX_ID}.sbx.sandboxes-cloud.docker.com/vnc.html?autoconnect=true&password=\${VNC_PASS}"
    echo "    (Atau: https://3000-\${SBX_ID}.sbx.sandboxes-cloud.docker.com/)"
    echo "    Password: \${VNC_PASS}"
    echo ""
    echo " 2. ⚡ VIA APLIKASI TIGHTVNC VIEWER DI LAPTOP (ZERO LAG):"
    echo "    Jalankan SSH tunnel di PC: ssh -N -L 5901:127.0.0.1:5901 <user>@sbx_cloud"
    echo "    Lalu buka TightVNC Viewer ke: 127.0.0.1:5901 (Password: \${VNC_PASS})"
    echo "======================================================================"
else
    SERVER_IP=\$(curl -s https://api.ipify.org || echo "IP_SERVER_KAMU")
    echo "======================================================================"
    echo " 🖥️ AKSES TIGHTVNC / NOVNC DESKTOP (VPS):"
    echo "======================================================================"
    echo " 1. 🌐 VIA WEB BROWSER (noVNC HTML5):"
    echo "    👉 http://\${SERVER_IP}:3000/vnc.html?autoconnect=true&password=\${VNC_PASS}"
    echo "    Password: \${VNC_PASS}"
    echo ""
    echo " 2. ⚡ VIA APLIKASI TIGHTVNC VIEWER DI LAPTOP (ZERO LAG):"
    echo "    Host VNC: \${SERVER_IP}:5901"
    echo "    Password: \${VNC_PASS}"
    echo "======================================================================"
fi
EOF
sudo chmod +x /usr/local/bin/cek_link 2>/dev/null || true
sudo cp /usr/local/bin/cek_link /usr/local/bin/check_link 2>/dev/null || true
sudo cp /usr/local/bin/cek_link /usr/local/bin/check-link 2>/dev/null || true

echo ""
echo "======================================================================"
echo " 🎉 INSTALASI TIGHTVNC & VIDBOT SUKSES BESAR!"
echo "======================================================================"
echo " [*] Tipe Lingkungan: $ENV_DESC"
echo ""
echo " 🌐 1. AKSES WEB BROWSER (noVNC - Ringan & Tanpa Install Apapun):"
echo "    👉 $WEB_URL"
echo "    Password VNC: $VNC_PASS"
echo ""
echo " ⚡ 2. AKSES APLIKASI TIGHTVNC VIEWER (Paling Kencang & Responsif):"
echo "    Port VNC: 5901"
echo "    Password: $VNC_PASS"
echo "    $NATIVE_INFO"
echo ""
echo " 💡 Cek Link Kapan Saja:"
echo "    Ketik: cek_link"
echo ""
echo " 📁 Lokasi Bot: $TARGET_DIR (Tersedia juga di Desktop: VidBot)"
echo " 🚀 Jalankan Bot: cd $TARGET_DIR && ./start_bot.sh"
echo "======================================================================"
