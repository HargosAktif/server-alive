#!/bin/bash
# ╔══════════════════════════════════════════════════════╗
# ║         ServerAlive — by LatenT                     ║
# ║     github.com/HargosAktif | Network Pentest Tool   ║
# ╚══════════════════════════════════════════════════════╝

RED='\033[0;91m'
GREEN='\033[0;92m'
YELLOW='\033[0;93m'
CYAN='\033[0;96m'
PURPLE='\033[0;95m'
GRAY='\033[0;90m'
NC='\033[0m'

BANNER="
${PURPLE}
  ____  _____ ____  ____  _____    ____
 / ___|| ____|  _ \|  _ \| ____|  |  _ \
 \___ \|  _| | |_) | | | |  _|   | |_) |
  ___) | |___|  _ <| |_| | |___  |  _ <
 |____/|_____|_| \_\____/|_____| |_| \_\\
       ServerAlive v1.0 — by LatenT
${NC}"

ALIVE=0
DEAD=0
RESULTS=()

usage() {
    echo -e "${CYAN}Kullanım:${NC}"
    echo -e "  Tek hedef : $0 <ip/domain>"
    echo -e "  Liste     : $0 -f <dosya.txt>"
    echo -e "  Subnet    : $0 -s <192.168.1.0/24>"
    echo ""
    echo -e "  Örnek: $0 192.168.1.1"
    echo -e "  Örnek: $0 -f hedefler.txt"
    exit 1
}

check_deps() {
    for dep in ping curl nmap; do
        if ! command -v "$dep" &>/dev/null; then
            echo -e "${YELLOW}[!] $dep bulunamadı — bazı kontroller atlanacak${NC}"
        fi
    done
}

check_ping() {
    ping -c 1 -W 1 "$1" &>/dev/null
    return $?
}

check_tcp() {
    # 80, 443, 22, 8080 portlarından birine bağlanmayı dene
    for port in 80 443 22 8080 8443; do
        timeout 1 bash -c "echo > /dev/tcp/$1/$port" 2>/dev/null && return 0
    done
    return 1
}

check_http() {
    if command -v curl &>/dev/null; then
        STATUS=$(curl -s -o /dev/null -w "%{http_code}" --connect-timeout 2 "http://$1" 2>/dev/null)
        if [[ "$STATUS" =~ ^[0-9]+$ ]] && [ "$STATUS" -gt 0 ]; then
            echo "$STATUS"
            return 0
        fi
    fi
    return 1
}

scan_target() {
    local target="$1"
    local ping_ok=false
    local tcp_ok=false
    local http_status=""

    printf "${CYAN}[*] Kontrol ediliyor: %-25s${NC}" "$target"

    # ICMP ping
    if check_ping "$target"; then
        ping_ok=true
    fi

    # TCP port knock
    if check_tcp "$target"; then
        tcp_ok=true
    fi

    # HTTP durum kodu
    http_status=$(check_http "$target")

    # Sonuç değerlendirme
    if $ping_ok || $tcp_ok; then
        echo -e "${GREEN}[ALIVE]${NC}"
        $ping_ok && echo -e "         ${GRAY}├── ICMP ping  : ${GREEN}OK${NC}"
        $tcp_ok  && echo -e "         ${GRAY}├── TCP port   : ${GREEN}OPEN${NC}"
        [ -n "$http_status" ] && echo -e "         ${GRAY}└── HTTP kodu  : ${CYAN}$http_status${NC}"
        ALIVE=$((ALIVE + 1))
        RESULTS+=("${GREEN}[+] ALIVE${NC}  $target")
    else
        echo -e "${RED}[DEAD / FILTERED]${NC}"
        DEAD=$((DEAD + 1))
        RESULTS+=("${RED}[-] DEAD  ${NC}  $target")
    fi
}

scan_subnet() {
    local subnet="$1"
    # 192.168.1.0/24 → 192.168.1.1-254
    local base
    base=$(echo "$subnet" | cut -d'/' -f1 | cut -d'.' -f1-3)
    echo -e "${YELLOW}[*] Subnet taranıyor: $subnet${NC}\n"
    for i in $(seq 1 254); do
        scan_target "${base}.${i}"
    done
}

print_summary() {
    echo ""
    echo -e "${PURPLE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${PURPLE}  ÖZET${NC}"
    echo -e "${PURPLE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    for r in "${RESULTS[@]}"; do
        echo -e "  $r"
    done
    echo ""
    echo -e "  ${GREEN}Alive : $ALIVE${NC}"
    echo -e "  ${RED}Dead  : $DEAD${NC}"
    echo -e "  ${CYAN}Toplam: $((ALIVE + DEAD))${NC}"
    echo -e "${GRAY}  github.com/HargosAktif${NC}"
    echo -e "${PURPLE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

# ── MAIN ──────────────────────────────────────
echo -e "$BANNER"
check_deps

if [ $# -eq 0 ]; then
    usage
fi

START=$(date +%s)

case "$1" in
    -f|--file)
        [ -z "$2" ] && usage
        [ ! -f "$2" ] && echo -e "${RED}[!] Dosya bulunamadı: $2${NC}" && exit 1
        echo -e "${YELLOW}[*] Dosyadan okunuyor: $2${NC}\n"
        while IFS= read -r line; do
            [ -z "$line" ] && continue
            [[ "$line" == \#* ]] && continue
            scan_target "$line"
        done < "$2"
        ;;
    -s|--subnet)
        [ -z "$2" ] && usage
        scan_subnet "$2"
        ;;
    -h|--help)
        usage
        ;;
    *)
        scan_target "$1"
        ;;
esac

END=$(date +%s)
ELAPSED=$((END - START))

print_summary
echo -e "  ${GRAY}Süre: ${ELAPSED}s${NC}\n"
