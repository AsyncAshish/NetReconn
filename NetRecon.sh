#!/bin/bash

# netrecon.sh - this is in online Recon tool which is use to know more about a server 
# i have made this for learning purposes and authorized pentesting only
# only scan systems that you own or have permission for


# colors
RED='\e[0;31m'
GREEN='\e[0;32m'
YELLOW='\e[1;33m'
CYAN='\e[0;36m'
BLUE='\e[0;34m'
BOLD='\e[1m'
RESET='\e[0m'


# checking does install.sh exist
if [ ! -f "./install.sh" ]; then
    echo -e "${RED}[!] Couldn't find install.sh in this directory${RESET}"
    echo -e "${YELLOW}    Make sure you're in the right folder and run:${RESET}"
    echo -e "    ${BOLD}bash install.sh${RESET}"
    echo -e "    That'll set everything up for you before running this"
    exit 1
fi


# ASCII banner
print_banner() {
    echo -e "${CYAN}"
    echo "  _   _      _   ____                      "
    echo " | \ | | ___| |_|  _ \ ___  ___ ___  _ __  "
    echo " |  \| |/ _ \ __| |_) / _ \/ __/ _ \| '_ \ "
    echo " | |\  |  __/ |_|  _ <  __/ (_| (_) | | | |"
    echo " |_| \_|\___|\__|_| \_\___|\___\___/|_| |_|"
    echo ""
    echo -e "       Network Reconnaissance Tool v1.0${RESET}"
    echo -e "       ${YELLOW}For authorized security testing only${RESET}"
    echo ""
}


# Section header
print_section() {
    echo ""
    echo -e "${BLUE}${BOLD}========================================${RESET}"
    echo -e "${BLUE}${BOLD}  $1${RESET}"
    echo -e "${BLUE}${BOLD}========================================${RESET}"
}


# logs things to terminal and saves it to the report file 
log_result() {
    echo -e "$1" | tee -a "$REPORT_FILE"
}


# gets the target from user 
get_target() {
    #checking does target is already specified
    if [ -z "$1" ]; then
        echo -e "${YELLOW}Enter target domain or IP:${RESET}"
        echo -e "${RED}(seriously only scan things you own or have written permission for)${RESET}"
        read -p "> " TARGET
    else
        TARGET="$1"
    fi

    #checking is target empty 
    if [ -z "$TARGET" ]; then
        echo -e "${RED}bro you didn't enter anything, exiting${RESET}"
        exit 1
    fi

    echo -e "\n${GREEN}[✓] Target set: ${BOLD}$TARGET${RESET}"
}


# creates the reports folder and sets up the output file
setup_report() {
    mkdir -p reports

    TIMESTAMP=$(date +"%Y%m%d_%H%M%S")

    # replace dots in traget address with underscores 
    SAFE_TARGET="${TARGET//./_}"
    REPORT_FILE="reports/recon_${SAFE_TARGET}_${TIMESTAMP}.txt"

    # header info for report
    echo "========================================" > "$REPORT_FILE"
    echo "  NetRecon Report" >> "$REPORT_FILE"
    echo "  Target : $TARGET" >> "$REPORT_FILE"
    echo "  Date   : $(date)" >> "$REPORT_FILE"
    echo "  Tool   : github.com/[yourusername]/NetRecon" >> "$REPORT_FILE"
    echo "========================================" >> "$REPORT_FILE"

    echo -e "${GREEN}[✓] Report saving to: ${BOLD}$REPORT_FILE${RESET}"
}


# dns lookup
run_dns_lookup() {
    print_section "DNS Lookup"
    log_result "\n[DNS LOOKUP] - $TARGET"

    # A record ( ipv4 )
    log_result "\n--- A Record (IPv4) ---"
    dig +short A "$TARGET" | while read -r line; do
        log_result "  IPv4: $line"
    done

    # AAAA  ( ipv6 ) 
    log_result "\n--- AAAA Record (IPv6) ---"
    AAAA=$(dig +short AAAA "$TARGET")
    if [ -z "$AAAA" ]; then
        log_result "  No IPv6 found"
    else
        log_result "  IPv6: $AAAA"
    fi

    # MX records ( mail servers )
    log_result "\n--- MX Records (Mail Servers) ---"
    dig +short MX "$TARGET" | while read -r line; do
        log_result "  Mail: $line"
    done

    # TXT records
    log_result "\n--- TXT Records ---"
    dig +short TXT "$TARGET" | while read -r line; do
        log_result "  TXT: $line"
    done

    # NS records ( nameservers )
    log_result "\n--- NS Records (Nameservers) ---"
    dig +short NS "$TARGET" | while read -r line; do
        log_result "  NS: $line"
    done

    echo -e "${GREEN}[✓] DNS lookup done${RESET}"
}


# whois registration info for the domain
run_whois() {
    print_section "WHOIS Lookup"
    log_result "\n[WHOIS] - $TARGET"

    WHOIS_OUTPUT=$(whois "$TARGET" 2>/dev/null)

    FIELDS=("Registrar:" "Creation Date:" "Updated Date:" "Expiry Date:"
            "Registry Expiry" "Name Server:" "DNSSEC:" "Registrant"
            "Organization:" "Country:")

    for field in "${FIELDS[@]}"; do
        RESULT=$(echo "$WHOIS_OUTPUT" | grep -i "$field" | head -3)
        if [ -n "$RESULT" ]; then
            log_result "  $RESULT"
        fi
    done

    echo -e "${GREEN}[✓] WHOIS done${RESET}"
}


# port scaning
run_port_scan() {
    print_section "Port Scan (nmap)"
    log_result "\n[PORT SCAN] - $TARGET"

    echo -e "${YELLOW}Pick your scan:${RESET}"
    echo "  1) Quick   - top 100 ports, done in like 30 sec"
    echo "  2) Standard - top 1000 ports + version detection, ~2 min"
    echo "  3) Full     - all 65535 ports, grab a snack this takes a while"
    read -p "Choice [1/2/3]: " SCAN_CHOICE

    case "$SCAN_CHOICE" in
        1)
            log_result "\n--- Quick Scan (Top 100 ports) ---"
            nmap --top-ports 100 -T4 --open "$TARGET" 2>/dev/null | tee -a "$REPORT_FILE"
            ;;
        2)
            log_result "\n--- Standard Scan (Top 1000 + version detection) ---"
            # -sV detects software versions, -sC runs basic safe scripts
            nmap -sV -sC -T4 --open "$TARGET" 2>/dev/null | tee -a "$REPORT_FILE"
            ;;
        3)
            log_result "\n--- Full Scan (All 65535 ports) ---"
            echo -e "${YELLOW}this will take a while, go grab chai or something${RESET}"
            # -p- = all ports, -O tries to detect the OS too
            nmap -sV -sC -O -T4 -p- --open "$TARGET" 2>/dev/null | tee -a "$REPORT_FILE"
            ;;
        *)
            echo -e "${YELLOW}invalid choice, just running standard scan${RESET}"
            nmap -sV -sC -T4 --open "$TARGET" 2>/dev/null | tee -a "$REPORT_FILE"
            ;;
    esac

    echo -e "${GREEN}[✓] Port scan done${RESET}"
}


# check http headers for security misconfigs
run_http_headers() {
    print_section "HTTP Header Analysis"
    log_result "\n[HTTP HEADERS] - $TARGET"

    # try https first, fall back to http if that fails
    for PROTOCOL in "https" "http"; do
        URL="${PROTOCOL}://${TARGET}"
        log_result "\n--- Checking: $URL ---"

       
        HEADERS=$(curl -I -L -s --max-time 10 "$URL" 2>/dev/null)

        if [ -z "$HEADERS" ]; then
            log_result "  [!] couldn't connect to $URL"
            continue
        fi

        log_result "$HEADERS"

        log_result "\n--- Security Header Check ---"

        declare -A SECURITY_HEADERS=(
            ["Strict-Transport-Security"]="HSTS - stops HTTP downgrade attacks"
            ["Content-Security-Policy"]="CSP - helps prevent XSS"
            ["X-Frame-Options"]="stops clickjacking"
            ["X-Content-Type-Options"]="prevents MIME sniffing"
            ["Referrer-Policy"]="controls what referrer info gets shared"
            ["Permissions-Policy"]="controls browser features like camera/mic"
        )

        for header in "${!SECURITY_HEADERS[@]}"; do
            if echo "$HEADERS" | grep -qi "$header"; then
                log_result "  ${GREEN}[✓ PRESENT]${RESET}  $header"
                log_result "             ↳ ${SECURITY_HEADERS[$header]}"
            else
                log_result "  ${RED}[✗ MISSING]${RESET}  $header"
                log_result "             ↳ ${SECURITY_HEADERS[$header]}"
                log_result "             ↳ ${YELLOW}FINDING: should add this header${RESET}"
            fi
        done


        SERVER=$(echo "$HEADERS" | grep -i "^Server:" | head -1)
        if [ -n "$SERVER" ]; then
            log_result "\n  ${YELLOW}[!] server info exposed: $SERVER${RESET}"
            log_result "      FINDING: hide the server version in prod"
        fi

        if [ "$PROTOCOL" = "https" ] && [ -n "$HEADERS" ]; then
            break
        fi
    done

    echo -e "${GREEN}[✓] Header analysis done${RESET}"
}


run_geolocation() {
    print_section "IP Geolocation"
    log_result "\n[GEOLOCATION] - $TARGET"

    #getting ip if the target is provided as domain
    IP=$(dig +short A "$TARGET" | head -1)

    if [ -z "$IP" ]; then
        # if dig returned nothing, maybe TARGET is already an ip
        IP="$TARGET"
    fi

    log_result "  Resolved IP: $IP"

    # get geolaction of target through ip-api.com
    GEO_DATA=$(curl -s --max-time 10 "http://ip-api.com/json/$IP" 2>/dev/null)

    if [ -z "$GEO_DATA" ]; then
        log_result "  [!] couldn't get geo data, maybe no internet?"
        return
    fi

    parse_json_field() {
        echo "$1" | grep -o "\"$2\":\"[^\"]*\"" | cut -d'"' -f4
    }

    parse_json_number() {
        echo "$1" | grep -o "\"$2\":[0-9.-]*" | cut -d':' -f2
    }

    COUNTRY=$(parse_json_field "$GEO_DATA" "country")
    CITY=$(parse_json_field "$GEO_DATA" "city")
    REGION=$(parse_json_field "$GEO_DATA" "regionName")
    ISP=$(parse_json_field "$GEO_DATA" "isp")
    ORG=$(parse_json_field "$GEO_DATA" "org")
    LAT=$(parse_json_number "$GEO_DATA" "lat")
    LON=$(parse_json_number "$GEO_DATA" "lon")
    TIMEZONE=$(parse_json_field "$GEO_DATA" "timezone")

    log_result "  Country  : $COUNTRY"
    log_result "  Region   : $REGION"
    log_result "  City     : $CITY"
    log_result "  ISP      : $ISP"
    log_result "  Org      : $ORG"
    log_result "  Lat/Lon  : $LAT, $LON"
    log_result "  Timezone : $TIMEZONE"

    echo -e "${GREEN}[✓] Geolocation done${RESET}"
}


#find subdomains
run_subdomain_discovery() {
    print_section "Subdomain Discovery (crt.sh)"
    log_result "\n[SUBDOMAINS] - $TARGET"

    log_result "  Source: crt.sh (Certificate Transparency Logs)"
    log_result "  passive recon only, we never talk to the target server"
    log_result ""

    # crt.sh keeps records of all ssl certs ever issued
    # so if they got a cert for sub.example.com, we can find it
    CRT_DATA=$(curl -s --max-time 15 \
        "https://crt.sh/?q=%25.$TARGET&output=json" 2>/dev/null)

    if [ -z "$CRT_DATA" ]; then
        log_result "  [!] crt.sh didn't respond, try again later"
        return
    fi

    # parse out all the domain names
    SUBDOMAINS=$(echo "$CRT_DATA" | \
        grep -oP '"name_value":"[^"]*"' | \
        cut -d'"' -f4 | \
        tr ',' '\n' | \
        sed 's/^\*\.//' | \
        sort -u)

    if [ -z "$SUBDOMAINS" ]; then
        log_result "  nothing found in the cert logs"
        return
    fi

    COUNT=$(echo "$SUBDOMAINS" | wc -l)
    log_result "  found $COUNT subdomains:\n"

    echo "$SUBDOMAINS" | while read -r subdomain; do
        log_result "    $subdomain"
    done

    echo -e "${GREEN}[✓] Subdomain scan done${RESET}"
}


# final summary after everything runs
print_summary() {
    print_section "All Done!"
    echo ""
    echo -e "  ${BOLD}Target  :${RESET} $TARGET"
    echo -e "  ${BOLD}Report  :${RESET} $REPORT_FILE"
    echo -e "  ${BOLD}Time    :${RESET} $(date)"
    echo ""
    echo -e "  ${YELLOW}reminder: only use this on stuff you have permission to test"
    echo -e "  don't be that guy${RESET}"
    echo ""
    log_result "\n\n[END OF REPORT] - $(date)"
}


# main - ties everything together
main() {
    clear

    print_banner
    get_target "$@"
    setup_report

    # confirmation before starting scaning
    echo ""
    echo -e "${RED}${BOLD}hey confirm you actually have permission to scan $TARGET${RESET}"
    echo -e "type 'yes' to continue or anything else to quit:"
    read -p "> " CONFIRM

    if [ "$CONFIRM" != "yes" ]; then
        echo -e "${RED}scan cancelled, always get permission first fr${RESET}"
        exit 0
    fi

    # run all the modules
    run_dns_lookup
    run_whois
    run_http_headers
    run_geolocation
    run_subdomain_discovery

    # port scan ( because it takes time ) 
    run_port_scan

    print_summary
}

main "$@"
