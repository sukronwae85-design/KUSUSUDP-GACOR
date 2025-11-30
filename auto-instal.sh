#!/bin/bash

# ==========================================
# KUSUSUDP-GACOR - Auto Installer Lengkap
# UDP Unlimited Speed - All Ports 1-65535
# Support All Ubuntu Versions
# ==========================================

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

# Repository Info
REPO_NAME="KUSUSUDP-GACOR"
REPO_URL="https://github.com/sukronwae85-design/KUSUSUDP-GACOR"
VERSION="2.0.0"

# Server Config
SERVER_IP=""
INSTALL_DIR="/etc/kususudp"
LOG_DIR="/var/log/kususudp"
USERS_FILE="$INSTALL_DIR/users.json"

# Banner ramah
show_banner() {
    clear
    echo -e "${PURPLE}"
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║                   🚀 SELAMAT DATANG! 🚀                     ║"
    echo "║                 KUSUSUDP-GACOR INSTALLER                    ║"
    echo "║           Server UDP Super Cepat & Stabil                   ║"
    echo "║             Support Semua Ubuntu (18-24)                    ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    echo -e "${CYAN}📁 Repository: ${REPO_URL}${NC}"
    echo -e "${CYAN}🛠️  Version: ${VERSION} | Support: Semua OS Ubuntu${NC}"
    echo -e "${CYAN}⚡ Fitur: Unlimited Speed, All Ports Terbuka${NC}"
    echo "================================================================"
    echo
}

# Fungsi untuk tampilan ramah
print_success() { echo -e "${GREEN}✅ $1${NC}"; }
print_warning() { echo -e "${YELLOW}⚠️  $1${NC}"; }
print_error() { echo -e "${RED}❌ $1${NC}"; }
print_info() { echo -e "${BLUE}ℹ️  $1${NC}"; }
print_loading() { echo -e "${CYAN}⏳ $1${NC}"; }

# Check OS
check_os() {
    print_loading "Memeriksa sistem operasi..."
    
    if [[ -f /etc/os-release ]]; then
        source /etc/os-release
        if [[ "$ID" == "ubuntu" ]]; then
            print_success "Ubuntu $VERSION_ID terdeteksi - DIDUKUNG"
            return 0
        else
            print_error "Hanya Ubuntu yang didukung"
            exit 1
        fi
    else
        print_error "Tidak bisa mendeteksi OS"
        exit 1
    fi
}

# Check root
check_root() {
    if [[ $EUID -ne 0 ]]; then
        print_error "Script harus dijalankan sebagai root"
        echo -e "${YELLOW}Gunakan: ${GREEN}sudo bash auto-install.sh${NC}"
        exit 1
    fi
}

# Get server IP
get_server_ip() {
    print_loading "Mendeteksi alamat IP server..."
    SERVER_IP=$(curl -s https://api.ipify.org || hostname -I | awk '{print $1}')
    print_success "IP Server: $SERVER_IP"
}

# Update system
update_system() {
    print_loading "Memperbarui sistem..."
    apt update && apt upgrade -y
    apt install -y curl wget git
    print_success "Sistem diperbarui"
}

# Install dependencies lengkap
install_dependencies() {
    print_loading "Menginstall dependencies..."
    
    apt install -y \
        build-essential net-tools iptables-persistent \
        nginx certbot python3-certbot-nginx \
        iftop htop jq bc openssh-server \
        python3 python3-pip dos2unix \
        netcat socat

    print_success "Dependencies terinstall"
}

# Install UDP Custom
install_udp_custom() {
    print_loading "Menginstall UDP Custom..."
    
    # Download UDP Custom
    if wget -q -O /usr/bin/udp-custom "https://github.com/loadfile1/udp-custom/releases/latest/download/udp-custom-linux-amd64"; then
        chmod +x /usr/bin/udp-custom
        print_success "UDP Custom terinstall"
    else
        print_warning "Gagal download, mencoba build dari source..."
        build_udp_custom_from_source
    fi
}

# Build UDP Custom dari source
build_udp_custom_from_source() {
    apt install -y golang-go
    git clone https://github.com/loadfile1/udp-custom.git /tmp/udp-custom
    cd /tmp/udp-custom
    go build -o udp-custom
    cp udp-custom /usr/bin/
    chmod +x /usr/bin/udp-custom
    cd ~
    rm -rf /tmp/udp-custom
    print_success "UDP Custom built dari source"
}

# Buat direktori
create_directories() {
    print_loading "Membuat struktur direktori..."
    
    mkdir -p $INSTALL_DIR/{config,modules,tools,backups}
    mkdir -p $LOG_DIR
    mkdir -p /var/www/html
    
    print_success "Direktori dibuat"
}

# Konfigurasi sistem lengkap
configure_system() {
    print_loading "Mengkonfigurasi sistem..."
    
    # Set timezone ke Jakarta
    timedatectl set-timezone Asia/Jakarta
    print_success "Timezone diatur ke Asia/Jakarta"
    
    # Optimasi kernel untuk UDP
    cat >> /etc/sysctl.conf << EOF

# KUSUSUDP-GACOR Optimizations
net.core.rmem_max = 134217728
net.core.wmem_max = 134217728
net.ipv4.udp_mem = 134217728 134217728 134217728
net.ipv4.tcp_congestion_control = bbr
net.core.default_qdisc = fq
net.ipv4.tcp_fastopen = 3
fs.file-max = 1000000
net.core.netdev_max_backlog = 300000
EOF
    
    sysctl -p
    print_success "Optimasi kernel diterapkan"
}

# Buka semua port UDP
configure_firewall() {
    print_loading "Membuka semua port UDP 1-65535..."
    
    # Reset iptables
    iptables -F
    iptables -X
    iptables -t nat -F
    iptables -t nat -X
    
    # Buka SEMUA port UDP - UNLIMITED SPEED
    iptables -A INPUT -p udp -m udp --dport 1:65535 -j ACCEPT
    iptables -A OUTPUT -p udp -m udp --dport 1:65535 -j ACCEPT
    iptables -A FORWARD -p udp -m udp --dport 1:65535 -j ACCEPT
    
    # Buka port TCP penting
    for port in 22 80 443 7300 53 1194; do
        iptables -A INPUT -p tcp --dport $port -j ACCEPT
    done
    
    # Save rules
    iptables-save > /etc/iptables/rules.v4
    ip6tables-save > /etc/iptables/rules.v6
    
    print_success "Semua port UDP 1-65535 terbuka - UNLIMITED SPEED"
}

# Install modul-modul lengkap
install_modules() {
    print_loading "Menginstall modul management..."
    
    # User Manager Module LENGKAP
    cat > $INSTALL_DIR/modules/user-manager.sh << 'EOF'
#!/bin/bash

USERS_FILE="/etc/kususudp/users.json"
LOG_FILE="/var/log/kususudp/user.log"

# Inisialisasi file users
init_users_file() {
    if [ ! -f "$USERS_FILE" ]; then
        echo '[]' > $USERS_FILE
    fi
}

# Log action
log_action() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> $LOG_FILE
}

# Buat user SSH
create_ssh_user() {
    echo "🧑‍💼 BUAT AKUN SSH BARU"
    echo "────────────────────"
    
    read -p "Username: " username
    read -s -p "Password: " password
    echo
    read -p "Masa aktif (hari): " expiry_days
    
    # Validasi input
    if [[ -z "$username" || -z "$password" || -z "$expiry_days" ]]; then
        echo "❌ Semua field harus diisi!"
        return 1
    fi
    
    # Cek apakah user sudah ada
    if id "$username" &>/dev/null; then
        echo "❌ Username sudah ada!"
        return 1
    fi
    
    # Buat user system
    useradd -m -s /bin/false $username
    echo "$username:$password" | chpasswd
    
    # Hitung tanggal expiry
    expiry_date=$(date -d "+$expiry_days days" +%Y-%m-%d)
    
    # Tambah ke JSON
    init_users_file
    current_data=$(cat $USERS_FILE)
    new_user=$(jq -n \
        --arg user "$username" \
        --arg pass "$password" \
        --arg expiry "$expiry_date" \
        --arg created "$(date +%Y-%m-%d)" \
        '{username: $user, password: $pass, expiry: $expiry, created: $created, status: "active"}')
    
    echo $current_data | jq ". += [$new_user]" > $USERS_FILE
    
    echo "✅ User $username berhasil dibuat!"
    echo "📅 Berakhir pada: $expiry_date"
    log_action "Created user: $username"
}

# Hapus user SSH
delete_ssh_user() {
    echo "🗑️  HAPUS AKUN SSH"
    echo "────────────────"
    
    read -p "Username yang akan dihapus: " username
    
    if ! id "$username" &>/dev/null; then
        echo "❌ User tidak ditemukan!"
        return 1
    fi
    
    # Hapus user system
    userdel -r $username
    
    # Hapus dari JSON
    init_users_file
    current_data=$(cat $USERS_FILE)
    echo $current_data | jq "map(select(.username != \"$username\"))" > $USERS_FILE
    
    echo "✅ User $username berhasil dihapus!"
    log_action "Deleted user: $username"
}

# List semua user
list_all_users() {
    echo "📋 DAFTAR SEMUA USER"
    echo "───────────────────"
    
    init_users_file
    users_data=$(cat $USERS_FILE)
    user_count=$(echo $users_data | jq length)
    
    if [ "$user_count" -eq 0 ]; then
        echo "😔 Belum ada user"
        return
    fi
    
    echo "$users_data" | jq -r '.[] | "👤 \(.username) | 📅 Exp: \(.expiry) | 🟢 \(.status)"'
    echo "───────────────────"
    echo "Total: $user_count user"
}

# Lihat user aktif
view_active_users() {
    echo "👥 USER AKTIF SEKARANG"
    echo "─────────────────────"
    
    echo "SSH Connections:"
    who
    
    echo "─────────────────────"
    echo "UDP Connections:"
    netstat -u -n | grep ESTABLISHED 2>/dev/null || echo "Tidak ada koneksi UDP aktif"
}

# Kick user
kick_user() {
    echo "👢 KICK USER"
    echo "────────────"
    
    read -p "Username yang akan di-kick: " username
    
    # Dapatkan PID user
    pids=$(ps -u $username -o pid= 2>/dev/null)
    
    if [ -z "$pids" ]; then
        echo "ℹ️  User $username tidak aktif"
        return
    fi
    
    # Kill semua proses user
    echo "$pids" | while read pid; do
        kill -9 $pid 2>/dev/null
    done
    
    echo "✅ User $username berhasil di-kick!"
    log_action "Kicked user: $username"
}

# Batasi multi login
limit_multi_login() {
    echo "🛡️  CEK MULTI LOGIN"
    echo "─────────────────"
    
    # Cek user dengan multiple connections
    multi_users=$(who | awk '{print $1}' | sort | uniq -c | awk '$1 > 1')
    
    if [ -z "$multi_users" ]; then
        echo "✅ Tidak ada multi-login"
    else
        echo "⚠️  Multi-login terdeteksi:"
        echo "$multi_users" | while read count user; do
            echo "👤 $user: $count koneksi"
        done
        
        read -p "Kick semua multi-login? (y/n): " confirm
        if [[ $confirm == "y" ]]; then
            echo "$multi_users" | while read count user; do
                if [ $count -gt 2 ]; then
                    kick_user $user
                fi
            done
        fi
    fi
}
EOF

    # Port Manager Module
    cat > $INSTALL_DIR/modules/port-manager.sh << 'EOF'
#!/bin/bash

open_all_udp_ports() {
    echo "🔓 MEMBUKA SEMUA PORT UDP"
    echo "────────────────────────"
    
    iptables -F
    iptables -A INPUT -p udp --dport 1:65535 -j ACCEPT
    iptables -A OUTPUT -p udp --dport 1:65535 -j ACCEPT
    iptables -A FORWARD -p udp --dport 1:65535 -j ACCEPT
    
    iptables-save > /etc/iptables/rules.v4
    echo "✅ Semua port UDP 1-65535 terbuka!"
}

check_open_ports() {
    echo "🔍 CEK PORT TERBUKA"
    echo "──────────────────"
    
    echo "Port UDP terbuka:"
    netstat -u -ln | grep udp
    
    echo "──────────────────"
    echo "Port TCP terbuka:"
    netstat -t -ln | grep tcp
}
EOF

    # Monitor Module LENGKAP
    cat > $INSTALL_DIR/modules/monitor.sh << 'EOF'
#!/bin/bash

monitor_bandwidth() {
    echo "📊 MONITOR BANDWIDTH REAL-TIME"
    echo "─────────────────────────────"
    
    if ! command -v iftop &> /dev/null; then
        echo "Menginstall iftop..."
        apt install -y iftop
    fi
    
    interface=$(ip route | grep default | awk '{print $5}' | head -1)
    echo "Monitoring interface: $interface"
    iftop -i $interface
}

show_bandwidth_stats() {
    echo "📈 STATISTIK BANDWIDTH"
    echo "─────────────────────"
    
    echo "Interface Statistics:"
    cat /proc/net/dev | grep -v lo
    
    echo "─────────────────────"
    echo "Connection Summary:"
    netstat -i
}

backup_system() {
    echo "💾 BACKUP SYSTEM"
    echo "───────────────"
    
    backup_file="/root/kususudp-backup-$(date +%Y%m%d-%H%M%S).tar.gz"
    
    echo "Membackup konfigurasi..."
    tar -czf $backup_file /etc/kususudp /etc/nginx /etc/ssh /var/www/html 2>/dev/null
    
    if [ $? -eq 0 ]; then
        echo "✅ Backup berhasil: $backup_file"
    else
        echo "❌ Backup gagal!"
    fi
}

restore_backup() {
    echo "🔄 RESTORE BACKUP"
    echo "────────────────"
    
    read -p "File backup yang akan di-restore: " backup_file
    
    if [ ! -f "$backup_file" ]; then
        echo "❌ File backup tidak ditemukan!"
        return 1
    fi
    
    echo "Merestore backup..."
    tar -xzf $backup_file -C /
    
    if [ $? -eq 0 ]; then
        echo "✅ Restore berhasil!"
        echo "🔄 Restarting services..."
        systemctl restart ssh nginx
    else
        echo "❌ Restore gagal!"
    fi
}
EOF

    # SSL Manager Module LENGKAP
    cat > $INSTALL_DIR/modules/ssl-manager.sh << 'EOF'
#!/bin/bash

setup_ssl_certificate() {
    echo "🔒 SETUP SSL CERTIFICATE"
    echo "───────────────────────"
    
    read -p "Domain Anda (contoh: example.com): " domain
    read -p "Email untuk SSL: " email
    
    if [[ -z "$domain" || -z "$email" ]]; then
        echo "❌ Domain dan email harus diisi!"
        return 1
    fi
    
    echo "Menginstall SSL certificate untuk $domain..."
    
    # Install certbot jika belum ada
    if ! command -v certbot &> /dev/null; then
        apt install -y certbot python3-certbot-nginx
    fi
    
    # Dapatkan certificate
    certbot certonly --standalone -d $domain --preferred-challenges http --agree-tos -m $email -n
    
    if [ $? -eq 0 ]; then
        echo "✅ SSL Certificate berhasil diinstall!"
        
        # Konfigurasi Nginx dengan SSL
        configure_nginx_ssl $domain
        setup_domain_pointing $domain
    else
        echo "❌ Gagal install SSL certificate!"
    fi
}

configure_nginx_ssl() {
    local domain=$1
    
    echo "🔧 MENGKONFIGURASI NGINX DENGAN SSL"
    
    # Buat config nginx untuk domain
    cat > /etc/nginx/sites-available/$domain << CONF
server {
    listen 80;
    listen [::]:80;
    server_name $domain;
    return 301 https://\$server_name\$request_uri;
}

server {
    listen 443 ssl http2;
    listen [::]:443 ssl http2;
    server_name $domain;
    
    ssl_certificate /etc/letsencrypt/live/$domain/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/$domain/privkey.pem;
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers ECDHE-RSA-AES256-GCM-SHA512:DHE-RSA-AES256-GCM-SHA512;
    
    # Web interface
    location / {
        root /var/www/html;
        index index.html;
    }
    
    # SSH over WebSocket (optional)
    location /ssh/ {
        proxy_pass http://127.0.0.1:8080;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
    }
}
CONF

    # Enable site
    ln -sf /etc/nginx/sites-available/$domain /etc/nginx/sites-enabled/
    
    # Test nginx config
    nginx -t
    if [ $? -eq 0 ]; then
        systemctl restart nginx
        echo "✅ Nginx dikonfigurasi dengan SSL untuk $domain"
    else
        echo "❌ Konfigurasi Nginx error!"
    fi
}

setup_domain_pointing() {
    local domain=$1
    local server_ip=$(curl -s https://api.ipify.org)
    
    echo "🌐 KONFIGURASI DOMAIN POINTING"
    echo "────────────────────────────"
    echo "Langkah-langkah pointing domain:"
    echo ""
    echo "1. Login ke panel domain Anda"
    echo "2. Buat A record atau edit existing record:"
    echo "   Name: @ atau $domain"
    echo "   Type: A"
    echo "   Value: $server_ip"
    echo "   TTL: 3600"
    echo ""
    echo "3. Untuk www subdomain (optional):"
    echo "   Name: www"
    echo "   Type: A" 
    echo "   Value: $server_ip"
    echo "   TTL: 3600"
    echo ""
    echo "4. Tunggu propagasi DNS (bisa 5 menit - 24 jam)"
    echo "5. Test dengan: ping $domain"
    echo ""
    read -p "Tekan Enter setelah selesai..."
}

renew_ssl_certificates() {
    echo "🔄 PERBARUI SSL CERTIFICATES"
    echo "──────────────────────────"
    
    certbot renew --quiet
    systemctl reload nginx
    echo "✅ SSL certificates diperbarui!"
}

fix_nginx_config() {
    echo "🔧 MEMPERBAIKI KONFIGURASI NGINX"
    echo "──────────────────────────────"
    
    # Test config
    echo "Testing nginx configuration..."
    nginx -t
    
    if [ $? -eq 0 ]; then
        echo "✅ Konfigurasi Nginx valid"
        systemctl restart nginx
        echo "✅ Nginx berhasil di-restart"
    else
        echo "❌ Konfigurasi Nginx error, memperbaiki..."
        # Backup config salah
        cp /etc/nginx/nginx.conf /etc/nginx/nginx.conf.backup.$(date +%Y%m%d)
        
        # Reset ke config default
        cat > /etc/nginx/nginx.conf << 'NGINX_CONF'
user www-data;
worker_processes auto;
pid /run/nginx.pid;

events {
    worker_connections 768;
    multi_accept on;
}

http {
    sendfile on;
    tcp_nopush on;
    tcp_nodelay on;
    keepalive_timeout 65;
    types_hash_max_size 2048;

    include /etc/nginx/mime.types;
    default_type application/octet-stream;

    access_log /var/log/nginx/access.log;
    error_log /var/log/nginx/error.log;

    gzip on;

    include /etc/nginx/conf.d/*.conf;
    include /etc/nginx/sites-enabled/*;
}
NGINX_CONF
        
        nginx -t
        systemctl restart nginx
        echo "✅ Nginx berhasil diperbaiki"
    fi
}
EOF

    # System Manager Module
    cat > $INSTALL_DIR/modules/system-manager.sh << 'EOF'
#!/bin/bash

show_system_status() {
    echo "🖥️  STATUS SISTEM"
    echo "───────────────"
    
    echo "CPU Usage:"
    top -bn1 | grep "Cpu(s)" | awk '{print "💻 " $2 "%"}'
    
    echo "Memory Usage:"
    free -h | awk 'NR==2{print "🧠 " $3 " / " $2 " used"}'
    
    echo "Disk Usage:"
    df -h / | awk 'NR==2{print "💾 " $3 " / " $2 " used (" $5 ")"}'
    
    echo "Uptime:"
    uptime -p
}

show_service_status() {
    echo "🔧 STATUS SERVICE"
    echo "───────────────"
    
    services=("ssh" "nginx" "kususudp")
    
    for service in "${services[@]}"; do
        if systemctl is-active --quiet $service; then
            echo "✅ $service: AKTIF"
        else
            echo "❌ $service: NON-AKTIF"
        fi
    done
}

restart_all_services() {
    echo "🔄 RESTART SEMUA SERVICE"
    echo "─────────────────────"
    
    systemctl restart ssh
    systemctl restart nginx
    systemctl restart kususudp
    
    echo "✅ Semua service di-restart"
}

update_script() {
    echo "📥 UPDATE SCRIPT"
    echo "──────────────"
    
    echo "Mengecek update..."
    cd /etc/kususudp
    git pull origin main
    
    if [ $? -eq 0 ]; then
        echo "✅ Script berhasil di-update"
        echo "🔄 Mengupdate modul..."
        chmod +x modules/*.sh
    else
        echo "❌ Gagal update script"
    fi
}
EOF

    chmod +x $INSTALL_DIR/modules/*.sh
    print_success "Semua modul terinstall"
}

# Buat menu management yang RAMAH
create_friendly_menu() {
    print_loading "Membuat menu management..."
    
    cat > /usr/bin/kususudp-menu << 'EOF'
#!/bin/bash

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

# Source modules
source /etc/kususudp/modules/user-manager.sh
source /etc/kususudp/modules/port-manager.sh
source /etc/kususudp/modules/monitor.sh
source /etc/kususudp/modules/ssl-manager.sh
source /etc/kususudp/modules/system-manager.sh

show_header() {
    clear
    echo -e "${PURPLE}"
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║                   🎯 KUSUSUDP-GACOR MENU                    ║"
    echo "║               Management Server Yang Mudah                  ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

user_management_menu() {
    while true; do
        show_header
        echo -e "${BLUE}👤 MANAGEMENT USER${NC}"
        echo "────────────────────"
        echo "1. 🧑‍💼 Buat User Baru"
        echo "2. 🗑️  Hapus User"
        echo "3. 📋 Lihat Semua User"
        echo "4. 👥 Lihat User Aktif"
        echo "5. 🛡️  Cek Multi Login"
        echo "6. 👢 Kick User"
        echo "7. ↩️  Kembali"
        echo
        
        read -p "Pilih menu [1-7]: " choice
        
        case $choice in
            1) create_ssh_user ;;
            2) delete_ssh_user ;;
            3) list_all_users ;;
            4) view_active_users ;;
            5) limit_multi_login ;;
            6) kick_user ;;
            7) break ;;
            *) echo -e "${RED}Pilihan tidak valid!${NC}" ;;
        esac
        
        echo
        read -p "Tekan Enter untuk melanjutkan..."
    done
}

ssl_management_menu() {
    while true; do
        show_header
        echo -e "${GREEN}🔒 MANAGEMENT SSL & DOMAIN${NC}"
        echo "──────────────────────"
        echo "1. 📝 Setup SSL Certificate"
        echo "2. 🔧 Setup Domain Pointing"
        echo "3. 🔄 Renew SSL Certificates"
        echo "4. 🛠️  Perbaiki Nginx"
        echo "5. ↩️  Kembali"
        echo
        
        read -p "Pilih menu [1-5]: " choice
        
        case $choice in
            1) setup_ssl_certificate ;;
            2) read -p "Domain Anda: " domain && setup_domain_pointing $domain ;;
            3) renew_ssl_certificates ;;
            4) fix_nginx_config ;;
            5) break ;;
            *) echo -e "${RED}Pilihan tidak valid!${NC}" ;;
        esac
        
        echo
        read -p "Tekan Enter untuk melanjutkan..."
    done
}

monitor_menu() {
    while true; do
        show_header
        echo -e "${YELLOW}📊 MONITORING & BACKUP${NC}"
        echo "────────────────────"
        echo "1. 📈 Monitor Bandwidth Real-time"
        echo "2. 📊 Lihat Statistik Bandwidth"
        echo "3. 💾 Backup System"
        echo "4. 🔄 Restore Backup"
        echo "5. 🖥️  Status Sistem"
        echo "6. ↩️  Kembali"
        echo
        
        read -p "Pilih menu [1-6]: " choice
        
        case $choice in
            1) monitor_bandwidth ;;
            2) show_bandwidth_stats ;;
            3) backup_system ;;
            4) restore_backup ;;
            5) show_system_status ;;
            6) break ;;
            *) echo -e "${RED}Pilihan tidak valid!${NC}" ;;
        esac
        
        echo
        read -p "Tekan Enter untuk melanjutkan..."
    done
}

system_menu() {
    while true; do
        show_header
        echo -e "${CYAN}⚙️  SYSTEM MANAGEMENT${NC}"
        echo "──────────────────"
        echo "1. 🔧 Status Service"
        echo "2. 🔄 Restart Semua Service"
        echo "3. 📥 Update Script"
        echo "4. 🔓 Buka Semua Port UDP"
        echo "5. 🔍 Cek Port Terbuka"
        echo "6. ↩️  Kembali"
        echo
        
        read -p "Pilih menu [1-6]: " choice
        
        case $choice in
            1) show_service_status ;;
            2) restart_all_services ;;
            3) update_script ;;
            4) open_all_udp_ports ;;
            5) check_open_ports ;;
            6) break ;;
            *) echo -e "${RED}Pilihan tidak valid!${NC}" ;;
        esac
        
        echo
        read -p "Tekan Enter untuk melanjutkan..."
    done
}

# Main menu
while true; do
    show_header
    echo -e "${PURPLE}📋 MENU UTAMA${NC}"
    echo "──────────"
    echo "1. 👤 Management User"
    echo "2. 🔒 SSL & Domain"
    echo "3. 📊 Monitoring & Backup"
    echo "4. ⚙️  System Management"
    echo "5. 🚪 Keluar"
    echo
    
    read -p "Pilih menu utama [1-5]: " main_choice
    
    case $main_choice in
        1) user_management_menu ;;
        2) ssl_management_menu ;;
        3) monitor_menu ;;
        4) system_menu ;;
        5)
            echo -e "${GREEN}Terima kasih telah menggunakan KUSUSUDP-GACOR! 👋${NC}"
            exit 0
            ;;
        *) echo -e "${RED}Pilihan tidak valid!${NC}" ;;
    esac
    
    echo
done
EOF

    chmod +x /usr/bin/kususudp-menu
    print_success "Menu management dibuat"
}

# Buat systemd service
create_service() {
    print_loading "Membuat service UDP..."
    
    cat > /etc/systemd/system/kususudp.service << EOF
[Unit]
Description=KUSUSUDP-GACOR UDP Server - Unlimited Speed
After=network.target

[Service]
Type=simple
User=root
ExecStart=/usr/bin/udp-custom server -l 0.0.0.0:1-65535 --mode fast --buffer 65535
Restart=always
RestartSec=3
StandardOutput=file:/var/log/kususudp/udp.log
StandardError=file:/var/log/kususudp/udp-error.log

[Install]
WantedBy=multi-user.target
EOF

    systemctl daemon-reload
    systemctl enable kususudp.service
    systemctl start kususudp.service
    
    print_success "Service UDP berjalan"
}

# Buat web interface
create_web_interface() {
    print_loading "Membuat web interface..."
    
    cat > /var/www/html/index.html << EOF
<!DOCTYPE html>
<html lang="id">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>KUSUSUDP-GACOR Server</title>
    <style>
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }
        body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            min-height: 100vh;
            padding: 20px;
        }
        .container {
            max-width: 1000px;
            margin: 0 auto;
            background: white;
            border-radius: 15px;
            box-shadow: 0 20px 40px rgba(0,0,0,0.1);
            overflow: hidden;
        }
        .header {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            padding: 40px 30px;
            text-align: center;
        }
        .header h1 {
            font-size: 2.5em;
            margin-bottom: 10px;
        }
        .header p {
            font-size: 1.2em;
            opacity: 0.9;
        }
        .content {
            padding: 30px;
        }
        .status-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(300px, 1fr));
            gap: 20px;
            margin-bottom: 30px;
        }
        .status-card {
            background: #f8f9fa;
            padding: 25px;
            border-radius: 10px;
            border-left: 5px solid #667eea;
        }
        .status-card.success {
            border-left-color: #28a745;
        }
        .status-card.warning {
            border-left-color: #ffc107;
        }
        .status-card.info {
            border-left-color: #17a2b8;
        }
        .status-card h3 {
            color: #2d3748;
            margin-bottom: 15px;
            font-size: 1.3em;
        }
        .status-card p {
            color: #4a5568;
            line-height: 1.6;
        }
        .command-box {
            background: #2d3748;
            color: #e2e8f0;
            padding: 20px;
            border-radius: 8px;
            font-family: 'Courier New', monospace;
            margin: 10px 0;
        }
        .feature-list {
            list-style: none;
            padding: 0;
        }
        .feature-list li {
            padding: 8px 0;
            border-bottom: 1px solid #e2e8f0;
        }
        .feature-list li:before {
            content: "✅ ";
            margin-right: 10px;
        }
        .btn {
            display: inline-block;
            background: #667eea;
            color: white;
            padding: 12px 25px;
            border-radius: 6px;
            text-decoration: none;
            font-weight: bold;
            transition: all 0.3s ease;
        }
        .btn:hover {
            background: #5a6fd8;
            transform: translateY(-2px);
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>🚀 KUSUSUDP-GACOR</h1>
            <p>Server UDP Unlimited Speed & Super Stabil</p>
        </div>
        
        <div class="content">
            <div class="status-grid">
                <div class="status-card success">
                    <h3>✅ STATUS SERVER</h3>
                    <p><strong>Server berjalan dengan baik!</strong></p>
                    <p>Semua sistem beroperasi normal.</p>
                </div>
                
                <div class="status-card info">
                    <h3>📊 INFORMASI SERVER</h3>
                    <p><strong>IP:</strong> $SERVER_IP</p>
                    <p><strong>UDP Ports:</strong> 1-65535</p>
                    <p><strong>Speed:</strong> Unlimited</p>
                    <p><strong>Timezone:</strong> Asia/Jakarta</p>
                </div>
                
                <div class="status-card warning">
                    <h3>🎯 MANAGEMENT</h3>
                    <p>Akses menu management melalui SSH:</p>
                    <div class="command-box">
                        kususudp-menu
                    </div>
                </div>
            </div>
            
            <div class="status-card">
                <h3>✨ FITUR UNGGULAN</h3>
                <ul class="feature-list">
                    <li>Unlimited UDP Speed - Tanpa Batas</li>
                    <li>Semua Port UDP Terbuka 1-65535</li>
                    <li>Management User Mudah</li>
                    <li>Auto SSL Certificate</li>
                    <li>Monitoring Real-time</li>
                    <li>Backup & Restore System</li>
                    <li>Multi-Login Detection</li>
                    <li>Web Interface Responsif</li>
                </ul>
            </div>
            
            <div style="text-align: center; margin-top: 30px;">
                <p><strong>Need help?</strong> Gunakan menu management atau baca dokumentasi.</p>
                <p style="margin-top: 10px; color: #718096;">
                    &copy; 2024 KUSUSUDP-GACOR - Server UDP Terbaik
                </p>
            </div>
        </div>
    </div>
</body>
</html>
EOF

    systemctl restart nginx
    print_success "Web interface dibuat"
}

# Final setup
final_setup() {
    print_loading "Menyelesaikan instalasi..."
    
    # Inisialisasi file users
    echo '[]' > $USERS_FILE
    
    # Buat info instalasi
    cat > $INSTALL_DIR/install.info << EOF
KUSUSUDP-GACOR Installation
===========================
Install Date: $(date)
Server IP: $SERVER_IP
Version: $VERSION
Ubuntu: $(lsb_release -ds)

Management Commands:
- kususudp-menu    : Menu management utama
- systemctl status kususudp : Cek service UDP

Important Locations:
- Config: $INSTALL_DIR
- Logs: $LOG_DIR
- Web: /var/www/html
- Users: $USERS_FILE

Support: $REPO_URL
EOF

    # Set permissions
    chmod -R 755 $INSTALL_DIR
    chmod 600 $USERS_FILE
    chmod 644 $LOG_DIR/*.log 2>/dev/null || true
    
    print_success "Setup final selesai"
}

# Tampilan completion yang ramah
show_completion() {
    echo
    echo -e "${GREEN}"
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║                   🎉 INSTALASI SELESAI! 🎉                  ║"
    echo "║           Server UDP Anda Sudah Siap Digunakan!             ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    echo
    echo -e "${CYAN}✨ KUSUSUDP-GACOR berhasil diinstall!${NC}"
    echo
    echo -e "${YELLOW}📊 INFORMASI SERVER:${NC}"
    echo -e "  🌐 IP Address: ${GREEN}$SERVER_IP${NC}"
    echo -e "  🖥️  Web Interface: ${GREEN}http://$SERVER_IP${NC}"
    echo -e "  🚀 UDP Ports: ${GREEN}1-65535 (UNLIMITED SPEED)${NC}"
    echo -e "  ⏰ Timezone: ${GREEN}Asia/Jakarta${NC}"
    echo
    echo -e "${YELLOW}🎯 CARA MENGGUNAKAN:${NC}"
    echo -e "  Jalankan: ${GREEN}kususudp-menu${NC}"
    echo
    echo -e "${YELLOW}📝 FITUR YANG SUDAH AKTIF:${NC}"
    echo -e "  ✅ Buat/Hapus User SSH"
    echo -e "  ✅ Monitor Bandwidth Real-time"  
    echo -e "  ✅ Backup & Restore System"
    echo -e "  ✅ SSL Certificate Auto"
    echo -e "  ✅ Domain Pointing Guide"
    echo -e "  ✅ Perbaikan Nginx Otomatis"
    echo -e "  ✅ Multi-Login Detection"
    echo -e "  ✅ Unlimited UDP Speed"
    echo
    echo -e "${YELLOW}🔗 REPOSITORY:${NC}"
    echo -e "  ${BLUE}$REPO_URL${NC}"
    echo
    echo -e "${GREEN}Selamat! Server UDP Anda sudah ready dengan semua fitur lengkap! 🚀${NC}"
    echo "================================================================"
}

# Main installation
main() {
    show_banner
    check_root
    check_os
    get_server_ip
    
    # Eksekusi semua step instalasi
    update_system
    install_dependencies
    install_udp_custom
    create_directories
    configure_system
    configure_firewall
    install_modules
    create_friendly_menu
    create_service
    create_web_interface
    final_setup
    
    show_completion
}

# Jalankan instalasi
main "$@"