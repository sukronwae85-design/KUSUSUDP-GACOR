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
        echo "7. 🔐 LIMIT IP MANAGEMENT"
        echo "8. ↩️  Kembali"
        echo
        
        read -p "Pilih menu [1-8]: " choice
        
        case $choice in
            1) create_ssh_user ;;
            2) delete_ssh_user ;;
            3) list_all_users ;;
            4) view_active_users ;;
            5) limit_multi_login ;;
            6) kick_user ;;
            7) ip_limit_menu ;;
            8) break ;;
            *) echo -e "${RED}Pilihan tidak valid!${NC}" ;;
        esac
        
        echo
        read -p "Tekan Enter untuk melanjutkan..."
    done
}

# Menu Limit IP baru
ip_limit_menu() {
    while true; do
        show_header
        echo -e "${RED}🛡️  LIMIT IP MANAGEMENT${NC}"
        echo "────────────────────"
        echo "1. 🔒 Limit IP per User"
        echo "2. 🌍 Limit by Country"
        echo "3. 📋 View IP Limits"
        echo "4. 🗑️  Remove IP Limit"
        echo "5. 👁️  Monitor User IPs"
        echo "6. 🚫 Auto Block Excessive IP"
        echo "7. ↩️  Kembali"
        echo
        
        read -p "Pilih menu [1-7]: " choice
        
        case $choice in
            1) limit_user_ip ;;
            2) limit_by_country ;;
            3) view_ip_limits ;;
            4) remove_ip_limit ;;
            5) monitor_user_ips ;;
            6) auto_block_ips ;;
            7) break ;;
            *) echo -e "${RED}Pilihan tidak valid!${NC}" ;;
        esac
        
        echo
        read -p "Tekan Enter untuk melanjutkan..."
    done
}