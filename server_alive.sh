#!/bin/bash

# Illegal kullanış beni alakadar etmez:D
# github.com/HargosAktif/server_alive

set -euo pipefail

# Colors
RED='\033[0;91m'
GREEN='\033[0;92m'
YELLOW='\033[0;93m'
CYAN='\033[0;96m'
WHITE='\033[1;97m'
NC='\033[0m'

# Config
MAX_JOBS=${MAX_JOBS:-50}
TIMEOUT=1
DEFAULT_PORTS="22 80 443 8080 8443"

BANNER="
${WHITE}    ____  _____ ____  ____  _____    ____
   / ___|| ____|  _ \\|  _ \\| ____|  |  _ \\
  \\___ \\\\  _| | |_) | | | |  _|   | |_) |
   ___) | |___|  _ <| |_| | |___  |  _ <
  |____/|_____|_| \\\\_\____/|_____| |_| \\\\_\\
${CYAN}Network Host Discovery & Latent tarafından globale yapıldı
${NC}"

declare -i ALIVE=0 DEAD=0
declare -a ALIVE_HOSTS=() DEAD_HOSTS=()
declare -i START_TIME=0

usage() {
    cat << EOF
${CYAN}Kullanım:${NC}
  $0 <target>                    # Tek hedef
  $0 -f <file.txt>              # Hedef listesi  
  $0 -s <subnet>                # Subnet (192.168.1.0/24)
  $0 -p <ports> <target>        # Custom portlar
  $0 -j <jobs> <target>         # Parallel jobs

${YELLOW}Örnekler:${NC}
  $0 -f targets.txt -j 100
  $0 -s 10.0.0.0/24 -j 200
  $0 -p "80,443" scanme.nmap.org

${WHITE}Varsayılanlar:${NC} jobs=$MAX_JOBS, ports=$DEFAULT_PORTS, timeout=${TIMEOUT}s
EOF
    exit 1
}

check_dependencies() {
    local missing=()
    for cmd in parallel nc curl; do
        if ! command -v "$cmd" >/dev/null 2>&1; then
            missing+=("$cmd")
        fi
    done
    
    if [ ${#missing[@]} -gt 0 ]; then
        printf "${RED}[!] Gerekli: %s${NC}\n" "$(IFS=', '; echo "${missing[*]}")"
        printf "${YELLOW}   sudo apt install parallel netcat-openbsd curl${NC}\n"
        exit 1
    fi
}

check_icmp() {
    local target="$1"
    timeout $TIMEOUT ping -c 1 -W 1 "$target" >/dev/null 2>&1
}

check_tcp() {
    local target="$1" ports="$2"
    IFS=' ' read -ra PORTS <<< "$ports"
    for port in "${PORTS[@]}"; do
        if timeout $TIMEOUT nc -z -w1 "$target" "$port" >/dev/null 2>&1; then
            return 0
        fi
    done
    return 1
}

check_http() {
    local target="$1"
    local status
    status=$(curl -s -o /dev/null -w "%{http_code}" \
        --connect-timeout $TIMEOUT --max-time $((TIMEOUT+1)) \
        --head "http://$target" 2>/dev/null || echo "0")
    [ "$status" != "0" ] && echo "$status" && return 0
    return 1
}

scan_target() {
    local target="$1" ports="$2"
    local icmp_ok=0 tcp_ok=0 http_status=""
    
    # Parallel checks
    {
        check_icmp "$target" && icmp_ok=1
    } &
    
    {
        check_tcp "$target" "$ports" && tcp_ok=1
    } &
    
    wait
    
    http_status=$(check_http "$target")
    
    if [ $icmp_ok -eq 1 ] || [ $tcp_ok -eq 1 ]; then
        printf "ALIVE;%s;%s;%s\n" "$target" "$icmp_ok" "$tcp_ok" 
        [ -n "$http_status" ] && printf "HTTP:%s;%s\n" "$target" "$http_status"
        echo "$target" >> /tmp/alive_$$.txt
    else
        printf "DEAD;%s\n" "$target"
        echo "$target" >> /tmp/dead_$$.txt  
    fi
}

generate_subnet_targets() {
    local subnet="$1"
    local base
    base=$(echo "$subnet" | sed 's/\.[0-9]\+$//')
    seq 1 254 | sed "s/^/${base}./"
}

process_results() {
    local alive_file="/tmp/alive_$$.txt"
    local dead_file="/tmp/dead_$$.txt"
    
    if [ -f "$alive_file" ]; then
        mapfile -t ALIVE_HOSTS < "$alive_file"
        ALIVE=${#ALIVE_HOSTS[@]}
        rm -f "$alive_file"
    fi
    
    if [ -f "$dead_file" ]; then
        mapfile -t DEAD_HOSTS < "$dead_file"
        DEAD=${#DEAD_HOSTS[@]}
        rm -f "$dead_file"
    fi
}

print_summary() {
    local elapsed="$1"
    cat << EOF

${WHITE}┌─────────────────────────────────────────────┐
│                  SUMMARY                     │
└─────────────────────────────────────────────┘${NC}

${GREEN}ALIVE ($ALIVE):${NC}
$(printf '  ✅ %-25s\n' "${ALIVE_HOSTS[@]:0:10}")
${ALIVE_HOSTS[10]+... +$((ALIVE-10)) more}

${RED}DEAD/FILTERED ($DEAD):${NC} 
$(printf '  ❌ %-25s\n' "${DEAD_HOSTS[@]:0:5}")
${DEAD_HOSTS[5]+... +$((DEAD-5)) more}

${WHITE}TOTAL: $((ALIVE + DEAD)) | TIME: ${elapsed}s | SPEED: $(( (ALIVE + DEAD) * 1000 / elapsed )) hosts/s${NC}

EOF
}

# ═══════════════════════════════════════════════ MAIN ═══════════════════════════════════════════════

echo -e "$BANNER"
check_dependencies

[ $# -eq 0 ] && usage
START_TIME=$(date +%s)

ports="$DEFAULT_PORTS"
jobs="$MAX_JOBS"
targets=()

while [ $# -gt 0 ]; do
    case "$1" in
        -f|--file)
            shift; mapfile -t targets < "$1"; break 2;;
        -s|--subnet)
            shift; mapfile -t targets < <(generate_subnet_targets "$1"); break 2;;
        -p) shift; ports="$2"; shift;;
        -j) shift; jobs="$2"; shift;;
        -h|--help) usage;;
        -*) echo -e "${RED}[!] Unknown option: $1${NC}"; usage;;
        *) targets=("$@"); break 2;;
    esac
done

[ ${#targets[@]} -eq 0 ] && usage

printf "${YELLOW}[*] %d targets, %d jobs, ports: %s${NC}\n" \
    "${#targets[@]}" "$jobs" "$ports"

printf "${CYAN}[*] Scanning...${NC}\n"

# Parallel execution
printf "%s\n" "${targets[@]}" | \
parallel -j "$jobs" --bar scan_target {} "$ports"

process_results
END_TIME=$(date +%s)
ELAPSED=$((END_TIME - START_TIME))

print_summary "$ELAPSED"
