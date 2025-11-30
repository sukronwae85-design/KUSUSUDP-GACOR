#!/bin/bash

USERS_FILE="/etc/kususudp/users.json"
LOG_FILE="/var/log/kususudp/user.log"
IPTABLES_CHAINS="/etc/kususudp/iptables_chains"

# Inisialisasi file users
init_users_file() {
    if [ ! -f "$USERS_FILE" ]; then
        echo '[]' > $USERS_FILE
    fi
}

# Buat chain iptables untuk user
create_user_iptables_chain() {
    local username=$1
    local chain_name="USER_${username}"
    
    # Buat chain khusus untuk user
    iptables -N $chain_name 2>/dev/null || true
    iptables -F $chain_name
    
    # Simpan chain name
    echo "$chain_name" >> $IPTABLES_CHAINS
}

# Limit IP untuk user tertentu
limit_user_ip() {
    echo "🛡️  LIMIT IP UNTUK USER"
    echo "─────────────────────"
    
    read -p "Username: " username
    read -p "Max IP connections: " max_ip
    
    if [[ -z "$username" || -z "$max_ip" ]]; then
        echo "❌ Username dan max IP harus diisi!"
        return 1
    fi
    
    # Cek apakah user ada
    if ! id "$username" &>/dev/null; then
        echo "❌ User tidak ditemukan!"
        return 1
    fi
    
    # Buat chain iptables untuk user
    create_user_iptables_chain $username
    
    # Rule untuk limit IP connections
    iptables -A INPUT -p tcp --dport 22 -m state --state NEW -m recent --set --name $username
    iptables -A INPUT -p tcp --dport 22 -m state --state NEW -m recent --update --seconds 60 --hitcount $max_ip --name $username -j DROP
    
    # Update user data dengan limit IP
    init_users_file
    current_data=$(cat $USERS_FILE)
    updated_data=$(echo $current_data | jq --arg user "$username" --arg max_ip "$max_ip" '
        map(if .username == $user then . + {"ip_limit": $max_ip} else . end)'
    )
    
    echo $updated_data > $USERS_FILE
    
    echo "✅ Limit IP berhasil diterapkan!"
    echo "👤 User: $username"
    echo "🔢 Max IP: $max_ip connections"
    log_action "IP Limit set: $username - $max_ip IP"
}

# Limit IP berdasarkan country (Advanced)
limit_by_country() {
    echo "🌍 LIMIT IP BY COUNTRY"
    echo "─────────────────────"
    
    read -p "Username: " username
    read -p "Allowed countries (comma separated, e.g., ID,SG,MY): " countries
    
    if [[ -z "$username" || -z "$countries" ]]; then
        echo "❌ Username dan countries harus diisi!"
        return 1
    fi
    
    echo "⚠️  Fitur advanced - butuh database IP country"
    echo "📝 Countries yang diizinkan: $countries"
    
    # Simpan setting country limit
    init_users_file
    current_data=$(cat $USERS_FILE)
    updated_data=$(echo $current_data | jq --arg user "$username" --arg countries "$countries" '
        map(if .username == $user then . + {"allowed_countries": $countries} else . end)'
    )
    
    echo $updated_data > $USERS_FILE
    echo "✅ Country limit disimpan (butuh implementasi lebih lanjut)"
}

# View IP limits for all users
view_ip_limits() {
    echo "📋 DAFTAR LIMIT IP USER"
    echo "─────────────────────"
    
    init_users_file
    users_data=$(cat $USERS_FILE)
    
    echo "$users_data" | jq -r '.[] | select(.ip_limit) | "👤 \(.username) | 🛡️  Max IP: \(.ip_limit) | 🌍 Countries: \(.allowed_countries // "All")"'
    
    echo "─────────────────────"
    echo "Total users dengan limit: $(echo "$users_data" | jq '[.[] | select(.ip_limit)] | length')"
}

# Remove IP limit for user
remove_ip_limit() {
    echo "🗑️  HAPUS LIMIT IP USER"
    echo "─────────────────────"
    
    read -p "Username: " username
    
    # Hapus rules iptables
    local chain_name="USER_${username}"
    iptables -F $chain_name 2>/dev/null || true
    iptables -X $chain_name 2>/dev/null || true
    
    # Update user data
    init_users_file
    current_data=$(cat $USERS_FILE)
    updated_data=$(echo $current_data | jq --arg user "$username" '
        map(if .username == $user then del(.ip_limit) | del(.allowed_countries) else . end)'
    )
    
    echo $updated_data > $USERS_FILE
    echo "✅ Limit IP untuk $username dihapus!"
    log_action "IP Limit removed: $username"
}

# Monitor active IP connections per user
monitor_user_ips() {
    echo "👁️  MONITOR IP AKTIF PER USER"
    echo "──────────────────────────"
    
    read -p "Username: " username
    
    if [[ -z "$username" ]]; then
        echo "❌ Username harus diisi!"
        return 1
    fi
    
    echo "📊 IP connections untuk $username:"
    
    # Cek SSH connections
    echo "SSH Connections:"
    who | grep "$username" | awk '{print $5}' | sed 's/.*(//' | sed 's/).*//' | sort | uniq -c
    
    # Cek recent connections
    echo "──────────────────────────"
    echo "Recent Connections:"
    netstat -tn | grep ":22" | grep "ESTABLISHED" | awk '{print $5}' | cut -d: -f1 | sort | uniq -c
    
    log_action "IP monitoring: $username"
}

# Auto block IP that exceed limits
auto_block_ips() {
    echo "🚫 AUTO BLOCK EXCESSIVE IP"
    echo "────────────────────────"
    
    init_users_file
    users_data=$(cat $USERS_FILE)
    
    echo "$users_data" | jq -r '.[] | select(.ip_limit) | "\(.username):\(.ip_limit)"' | while read user_limit; do
        username=$(echo $user_limit | cut -d: -f1)
        max_ip=$(echo $user_limit | cut -d: -f2)
        
        # Cek IP yang melebihi limit
        excessive_ips=$(who | grep "$username" | awk '{print $5}' | sed 's/.*(//' | sed 's/).*//' | sort | uniq -c | awk -v limit="$max_ip" '$1 > limit {print $2}')
        
        if [ -n "$excessive_ips" ]; then
            echo "⚠️  User $username melebihi limit:"
            echo "$excessive_ips" | while read ip; do
                echo "🚫 Blocking IP: $ip"
                iptables -A INPUT -s $ip -j DROP
                log_action "Auto blocked IP: $ip for user: $username"
            done
        fi
    done
    
    echo "✅ Auto block completed!"
}