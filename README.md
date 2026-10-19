# 🚀 AutoDocker Installer: Cloud Web Desktop & Vibot Suite

Script instalasi otomatis **1 baris perintah (One-Line Command)** untuk menyiapkan **Desktop GUI (TightVNC / noVNC / Webtop XFCE)** beserta bot **Vibot (Vidara & Multi-Proxy Bot)** di VPS Linux (Ubuntu / Debian) atau Docker Cloud Sandbox.

---

## ⚡ 1. Edisi Rekomendasi: Ultra-Lightweight TightVNC & noVNC (Dual-Mode)
> **Paling Cepat & Ringan:** Menggunakan protokol RFB murni (hanya mengirim pixel yang berubah). Jauh lebih enteng di CPU dan RAM ($\sim$150 MB RAM). Bisa dibuka langsung via Web Browser (noVNC HTML5) dan/atau aplikasi TightVNC Viewer di laptop!

```bash
sudo su
curl -fsSL https://raw.githubusercontent.com/AbyanZainZ/AutoDocker_installer/main/install_vnc.sh -o /tmp/install_vnc.sh && bash /tmp/install_vnc.sh
```

### 🖥️ Cara Akses TightVNC Edition:
1. **🌐 Web Browser (noVNC):**
   - Buka link: `https://3000-<SANDBOX_ID>.sbx.sandboxes-cloud.docker.com/vnc.html?autoconnect=true&password=vidbot123`
   - Password VNC: `vidbot123`
2. **⚡ Aplikasi TightVNC / RealVNC Viewer (Zero Lag):**
   - Port VNC: `5901`
   - Password: `vidbot123`
   - Di Docker Cloud Sandbox: Buat SSH tunnel dari PC:
     `ssh -N -L 5901:127.0.0.1:5901 <user>@sbx_cloud`
     lalu buka TightVNC Viewer ke `127.0.0.1:5901`.

---

## 🖥️ 2. Edisi Klasik: Webtop (KasmVNC)
> Menggunakan streaming video berbasis web langsung di browser (Port 3000).

```bash
sudo su
curl -fsSL https://raw.githubusercontent.com/AbyanZainZ/AutoDocker_installer/main/install.sh -o /tmp/install.sh && bash /tmp/install.sh
```

---

## 💡 Perintah Cepat 'cek_link'
Kapan saja kamu lupa alamat link Web Desktop atau info VNC kamu, cukup ketik di terminal:
```bash
cek_link
```

---

## 🤖 Cara Menjalankan Bot di Dalam Server / Desktop
1. Masuk ke folder bot:
   ```bash
   cd /VidBot
   ```
2. Isi link target di `link.txt`:
   ```bash
   nano link.txt
   ```
3. Scrape & Check proxy terbaru:
   ```bash
   ./start_proxyScrape.sh
   ```
4. Jalankan bot:
   ```bash
   ./start_bot.sh
   ```
   *(Atau jalankan di background: `nohup ./start_bot.sh > bot.log 2>&1 &`)*