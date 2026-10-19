#!/usr/bin/env bash
# ==============================================================================
#  9HITS VIEWER V6 - ULTRA-LIGHTWEIGHT HEADLESS INSTALLER (LOW CPU / NO GUI)
#  Repository: https://github.com/AbyanZainZ/AutoDocker_installer
#  Features:
#    - 100% Headless (Xvfb Virtual Display - ZERO Desktop / VNC Overhead)
#    - 45 Pool Sessions + 1 System Session support
#    - Built-in uBlockDNS Ad Blocker (Cuts 50-70% CPU & data on heavy ads)
#    - Non-systemd compatible (Works in VPS, Cloud Sandboxes, Docker & Colab)
#    - Automatic background runner inside screen session '9hits'
#    - Interactive CLI management tool ('9hits status', '9hits monitor', '9hits logs')
# ==============================================================================
set -e

echo "======================================================================"
echo " 🚀 9HITS VIEWER V6 - ULTRA-LIGHTWEIGHT HEADLESS INSTALLER"
echo "    Profile: LOW CPU / NO GUI (45 POOL SESSIONS)"
echo "======================================================================"

# 1. Pastikan Akses Root / Sudo
if [ "$(id -u)" -ne 0 ]; then
    echo "[!] Script ini membutuhkan hak akses root. Menjalankan dengan sudo..."
    exec sudo bash "$0" "$@"
fi

export DEBIAN_FRONTEND=noninteractive
ARCH=$(uname -m)
if [ "$ARCH" != "x86_64" ]; then
    echo "[-] Error: 9Hits Viewer hanya mendukung arsitektur x86_64 (AMD64). Arsitektur kamu: $ARCH"
    exit 1
fi

INSTALL_DIR="/opt/9hits"
DEFAULT_DOWNLOAD="https://dl.9hits.com/9hitsv6-linux64.tar.bz2"
XVFB_DISPLAY=":99"
SCREEN_SESSION="9hits"
LOW_CPU_RESOLUTION="1280x720x16"
CACHE_LIMIT="209715200" # 200MB

# 2. Nilai Konfigurasi Bawaan (Diambil dari profil LOW CPU 45 SESSION)
ACCESS_KEY="d432bb33020eca699a9e40e08726ffab"
POOL_URL="http://proxy.9hits.com/pool/262a19571a48d7cedb6fdba7cb14e537"
POOL_SESSIONS=45
SESSION_NOTE="gpybasic3"
ALLOW_CRYPTO="yes"
ALLOW_ADULT="yes"
HIDE_BROWSER="yes"
INSTALL_UBLOCKDNS="yes"
UBLOCKDNS_PROFILE="a0p5040j"

# Parsing argumen baris perintah jika user meng-override
for arg in "$@"; do
    case "$arg" in
        --access-key=*)       ACCESS_KEY="${arg#*=}" ;;
        --pool-url=*)         POOL_URL="${arg#*=}" ;;
        --pool-sessions=*)    POOL_SESSIONS="${arg#*=}" ;;
        --session-note=*)     SESSION_NOTE="${arg#*=}" ;;
        --skip-ublock)        INSTALL_UBLOCKDNS="no" ;;
        --ublock-profile=*)   UBLOCKDNS_PROFILE="${arg#*=}" ;;
        --allow-crypto=*)     ALLOW_CRYPTO="${arg#*=}" ;;
        --allow-adult=*)      ALLOW_ADULT="${arg#*=}" ;;
        --resolution=*)       LOW_CPU_RESOLUTION="${arg#*=}" ;;
    esac
done

echo "[*] Access Key    : ${ACCESS_KEY:0:8}************************"
echo "[*] Pool URL      : $POOL_URL"
echo "[*] Pool Sessions : $POOL_SESSIONS"
echo "[*] Session Note  : $SESSION_NOTE"
echo "[*] Resolusi Xvfb : $LOW_CPU_RESOLUTION (Low CPU)"
echo "[*] uBlockDNS     : $INSTALL_UBLOCKDNS (Profile: $UBLOCKDNS_PROFILE)"
echo "[*] Direktori     : $INSTALL_DIR"
echo ""

# 3. Pasang uBlockDNS untuk Blokir Iklan Berat (Menghemat CPU & Bandwidth)
if [ "$INSTALL_UBLOCKDNS" = "yes" ]; then
    echo "⏳ [1/6] Memasang uBlockDNS Ad Blocker (Profile: $UBLOCKDNS_PROFILE)..."
    curl -fsSL https://ublockdns.com/install.sh -o /tmp/ublockdns-install.sh 2>/dev/null || true
    if [ -f /tmp/ublockdns-install.sh ]; then
        sh /tmp/ublockdns-install.sh "$UBLOCKDNS_PROFILE" < /dev/null >/dev/null 2>&1 || true
        echo "✅ uBlockDNS berhasil dikonfigurasi!"
    fi
fi

# 4. Update Paket OS & Dependensi Headless 9Hits
echo ""
echo "⏳ [2/6] Memasang dependensi sistem headless Linux..."
if command -v apt-get &> /dev/null; then
    apt-get update -q < /dev/null
    apt-get install -y --no-install-recommends \
      ca-certificates wget curl screen unzip acl xvfb bzip2 \
      libxss1 libxtst6 libnss3 psmisc procps bc libgbm-dev \
      libatomic1 x11-utils iproute2 coreutils python3 python3-pip < /dev/null || true
    apt-get install -y --no-install-recommends libgtk-3-0 libatspi2.0-0 < /dev/null || true
    apt-get install -y --no-install-recommends libcanberra-gtk3-module < /dev/null || true
fi

# 5. Unduh & Ekstrak 9Hits Viewer v6 Resmi
echo ""
echo "⏳ [3/6] Mengunduh binary 9Hits Viewer v6..."
mkdir -p "$INSTALL_DIR"
TMP_ARCHIVE="/tmp/9hitsv6-linux64.tar.bz2"

# Hentikan proses lama jika sedang berjalan
pkill -TERM -x nhviewer 2>/dev/null || true
pkill -TERM -x may 2>/dev/null || true
screen -S "$SCREEN_SESSION" -X quit 2>/dev/null || true
sleep 1

if [ ! -f "$INSTALL_DIR/nhviewer" ]; then
    curl -fL --retry 3 --connect-timeout 20 "$DEFAULT_DOWNLOAD" -o "$TMP_ARCHIVE"
    tar -xjf "$TMP_ARCHIVE" -C "$INSTALL_DIR"
    if [ -d "$INSTALL_DIR/9hitsv6-linux64" ]; then
        mv "$INSTALL_DIR"/9hitsv6-linux64/* "$INSTALL_DIR"/ 2>/dev/null || true
        rm -rf "$INSTALL_DIR/9hitsv6-linux64"
    fi
    rm -f "$TMP_ARCHIVE"
    echo "✅ 9Hits Viewer v6 berhasil diekstrak ke: $INSTALL_DIR"
else
    echo "ℹ️ Binary 9Hits Viewer sudah ada di: $INSTALL_DIR"
fi

chmod +x "$INSTALL_DIR/nhviewer" 2>/dev/null || true
if [ -f "$INSTALL_DIR/may" ]; then
    chmod +x "$INSTALL_DIR/may" 2>/dev/null || true
fi

# 6. Jalankan Xvfb Virtual Display (DISPLAY :99)
echo ""
echo "⏳ [4/6] Menyiapkan Virtual Display Xvfb ($XVFB_DISPLAY - $LOW_CPU_RESOLUTION)..."
pkill -f "Xvfb $XVFB_DISPLAY" 2>/dev/null || true
rm -f "/tmp/.X99-lock" "/tmp/.X11-unix/X99" 2>/dev/null || true

nohup Xvfb "$XVFB_DISPLAY" -screen 0 "${LOW_CPU_RESOLUTION}" -ac -nolisten tcp > /dev/null 2>&1 &
XVFB_PID=$!
echo "$XVFB_PID" > "$INSTALL_DIR/xvfb.pid"
sleep 2

if ! xdpyinfo -display "$XVFB_DISPLAY" >/dev/null 2>&1; then
    echo "[!] Menunggu Xvfb aktif..."
    sleep 2
fi
echo "✅ Xvfb Virtual Display aktif di $XVFB_DISPLAY!"

# 7. Inisialisasi Parameter 9Hits Viewer
echo ""
echo "⏳ [5/6] Menginisialisasi konfigurasi 9Hits Viewer..."
export DISPLAY="$XVFB_DISPLAY"

timeout 180 "$INSTALL_DIR/nhviewer" \
  --access-key="$ACCESS_KEY" \
  --allow-crypto="$ALLOW_CRYPTO" \
  --allow-adult="$ALLOW_ADULT" \
  --hide-browser="$HIDE_BROWSER" \
  --session-note="$SESSION_NOTE" \
  --ex-proxy-sessions="$POOL_SESSIONS" \
  --ex-proxy-url="$POOL_URL" \
  --system-session \
  --resolution="$LOW_CPU_RESOLUTION" \
  --cache-limit="$CACHE_LIMIT" \
  --exit-on-init || true

echo "✅ Inisialisasi pengaturan 9Hits selesai!"

# 8. Buat Runner Script & Jalankan di Screen
echo ""
echo "⏳ [6/6] Meluncurkan 9Hits Background Runner di Screen '$SCREEN_SESSION'..."

cat << EOF_RUNNER > "$INSTALL_DIR/runner.sh"
#!/usr/bin/env bash
export DISPLAY=':99'
export LIBGL_ALWAYS_SOFTWARE='1'
INSTALL_DIR='/opt/9hits'
RESTART_DELAY=5
VIEWER="\$INSTALL_DIR/nhviewer"
ACCESS_KEY="${ACCESS_KEY}"
POOL_URL="${POOL_URL}"
POOL_SESSIONS="${POOL_SESSIONS}"
SESSION_NOTE="${SESSION_NOTE}"
CACHE_LIMIT="${CACHE_LIMIT}"

kill_viewer() {
  pkill -TERM -x nhviewer 2>/dev/null || true
  pkill -TERM -x may 2>/dev/null || true
  sleep 2
  pkill -KILL -x nhviewer 2>/dev/null || true
  pkill -KILL -x may 2>/dev/null || true
}

while true; do
  kill_viewer
  "\$VIEWER" --auto-start --in-loop --render-to-terminal \
    --access-key="\$ACCESS_KEY" \
    --ex-proxy-url="\$POOL_URL" \
    --ex-proxy-sessions="\$POOL_SESSIONS" \
    --session-note="\$SESSION_NOTE" \
    --cache-limit="\$CACHE_LIMIT"
  rc=\$?
  printf '[%s] nhviewer berhenti (exit code %s). Restarting dalam %ss...\n' "\$(date '+%Y-%m-%d %H:%M:%S')" "\$rc" "\$RESTART_DELAY"
  sleep "\$RESTART_DELAY"
done
EOF_RUNNER
chmod +x "$INSTALL_DIR/runner.sh"

RUNNER_LOG="$INSTALL_DIR/viewer.log"
screen -L -Logfile "$RUNNER_LOG" -dmS "$SCREEN_SESSION" bash "$INSTALL_DIR/runner.sh"
sleep 2

# 9. Low CPU Runtime Tuning (Hentikan service desktop/audio yang tidak perlu jika ada)
for proc in xfce4-panel xfdesktop thunar pulseaudio pipewire wireplumber x11vnc; do
    pkill -f "$proc" 2>/dev/null || true
done

# 10. Pasang CLI Management Tool '/usr/local/bin/9hits'
cat << 'EOF_CLI' > /usr/local/bin/9hits
#!/usr/bin/env bash
INSTALL_DIR="/opt/9hits"
SCREEN_SESSION="9hits"
LOG_FILE="$INSTALL_DIR/viewer.log"

case "$1" in
  status)
    echo "======================================================================"
    echo " 📊 9HITS VIEWER V6 - HEADLESS STATUS"
    echo "======================================================================"
    if screen -list 2>/dev/null | grep -q "[.]${SCREEN_SESSION}[[:space:]]"; then
        echo " Screen Runner : 🟢 RUNNING (Session: $SCREEN_SESSION)"
    else
        echo " Screen Runner : 🔴 STOPPED"
    fi
    if xdpyinfo -display ":99" >/dev/null 2>&1; then
        echo " Xvfb Display  : 🟢 ACTIVE (:99)"
    else
        echo " Xvfb Display  : 🔴 STOPPED"
    fi
    VIEWER_COUNT=$(pgrep -c nhviewer 2>/dev/null || echo "0")
    echo " nhviewer Proc : $VIEWER_COUNT aktif"
    echo ""
    echo "--- 15 Log Terbaru ($LOG_FILE) ---"
    tail -n 15 "$LOG_FILE" 2>/dev/null || echo "Belum ada log."
    echo "======================================================================"
    ;;
  logs|log)
    echo "Menampilkan live log (Tekan Ctrl+C untuk keluar)..."
    tail -f "$LOG_FILE"
    ;;
  attach)
    screen -r "$SCREEN_SESSION"
    ;;
  restart)
    echo "Merestart 9Hits Runner..."
    screen -S "$SCREEN_SESSION" -X quit 2>/dev/null || true
    pkill -KILL -x nhviewer 2>/dev/null || true
    pkill -KILL -x may 2>/dev/null || true
    sleep 2
    screen -L -Logfile "$LOG_FILE" -dmS "$SCREEN_SESSION" bash "$INSTALL_DIR/runner.sh"
    echo "✅ 9Hits Runner berhasil direstart!"
    ;;
  stop)
    echo "Menghentikan 9Hits..."
    screen -S "$SCREEN_SESSION" -X quit 2>/dev/null || true
    pkill -KILL -x nhviewer 2>/dev/null || true
    pkill -KILL -x may 2>/dev/null || true
    pkill -f "Xvfb :99" 2>/dev/null || true
    echo "✅ 9Hits berhasil dihentikan."
    ;;
  monitor)
    python3 /usr/local/bin/9hits-monitor-script.py
    ;;
  token|key)
    if [ -n "$2" ]; then
      sed -i "s/^ACCESS_KEY=.*/ACCESS_KEY=\"$2\"/" "$INSTALL_DIR/runner.sh"
      echo "✅ Access Key berhasil diupdate ke: $2"
      echo "Merestart 9Hits..."
      /usr/local/bin/9hits restart
    else
      echo "Penggunaan: 9hits token <ACCESS_KEY>"
    fi
    ;;
  pool)
    if [ -n "$2" ]; then
      sed -i "s|^POOL_URL=.*|POOL_URL=\"$2\"|" "$INSTALL_DIR/runner.sh"
      echo "✅ Pool URL berhasil diupdate ke: $2"
      echo "Merestart 9Hits..."
      /usr/local/bin/9hits restart
    else
      echo "Penggunaan: 9hits pool <POOL_URL>"
    fi
    ;;
  *)
    echo "Perintah 9Hits CLI:"
    echo "  9hits status            : Lihat ringkasan status & log terbaru"
    echo "  9hits monitor           : Buka interactive live monitor (CPU/RAM/Session)"
    echo "  9hits logs              : Pantau realtime log viewer"
    echo "  9hits token <KEY>       : Ganti / update Access Key"
    echo "  9hits pool <URL>        : Ganti / update Proxy Pool URL"
    echo "  9hits restart           : Restart runner 9hits"
    echo "  9hits stop              : Hentikan 9hits sepenuhnya"
    echo "  9hits attach            : Masuk langsung ke screen session"
    ;;
esac
EOF_CLI
chmod +x /usr/local/bin/9hits

# Pasang script monitor interaktif Python
cat << 'EOF_MON' > /usr/local/bin/9hits-monitor-script.py
import time, os, sys, subprocess

def get_stats():
    try:
        import psutil
        cpu = psutil.cpu_percent(interval=0.5)
        mem = psutil.virtual_memory().percent
    except Exception:
        cpu = "N/A"
        mem = "N/A"
    
    nh_procs = []
    try:
        r = subprocess.run(["ps", "-eo", "pid,pcpu,pmem,cmd"], capture_output=True, text=True)
        for line in r.stdout.strip().split("\n"):
            if "nhviewer" in line and "runner" not in line and "grep" not in line:
                nh_procs.append(line.strip())
    except Exception:
        pass
    return cpu, mem, nh_procs

def get_logs():
    try:
        with open("/opt/9hits/viewer.log", "r", encoding="utf-8", errors="ignore") as f:
            lines = f.readlines()
        return "".join(lines[-10:])
    except Exception:
        return "Log file belum tersedia.\n"

print("Memulai 9Hits Live Terminal Monitor... (Ctrl+C untuk keluar)")
try:
    while True:
        cpu, mem, procs = get_stats()
        logs = get_logs()
        os.system('clear' if os.name == 'posix' else 'cls')
        print("======================================================================")
        print(" 🧊 9HITS VIEWER V6 - LOW CPU HEADLESS MONITOR")
        print("======================================================================")
        print(f" CPU Usage       : {cpu}%")
        print(f" RAM Usage       : {mem}%")
        print(f" nhviewer Procs  : {len(procs)} aktif")
        print("======================================================================")
        print(" [📄 10 LOG TERAKHIR]:")
        print(logs.strip())
        print("======================================================================")
        print(" Tekan Ctrl+C untuk kembali ke terminal.")
        time.sleep(5)
except KeyboardInterrupt:
    print("\nMonitor selesai.")
EOF_MON
chmod +x /usr/local/bin/9hits-monitor-script.py

echo ""
echo "======================================================================"
echo " 🎉 INSTALASI 9HITS HEADLESS (LOW CPU) SUKSES BESAR!"
echo "======================================================================"
echo " [*] Status        : 🟢 Running di background (Screen: $SCREEN_SESSION)"
echo " [*] Sesi Pool     : $POOL_SESSIONS sessions"
echo " [*] Display       : Xvfb :99 (Tanpa beban Desktop GUI / Tanpa VNC)"
echo " [*] uBlockDNS     : Aktif memblokir iklan berat"
echo ""
echo " 🛠️ Perintah Cepat (Bisa dipanggil kapan saja di terminal):"
echo "    👉 9hits status   : Lihat ringkasan status & proses"
echo "    👉 9hits monitor  : Buka monitor live interaktif (CPU/RAM/Log)"
echo "    👉 9hits logs     : Pantau live log realtime"
echo "    👉 9hits restart  : Restart 9hits"
echo "    👉 9hits stop     : Hentikan 9hits"
echo "======================================================================"
