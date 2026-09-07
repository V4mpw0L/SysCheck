#!/usr/bin/env bash
# ==============================================================================
#  ███████╗██╗   ██╗███████╗ ██████╗██╗  ██╗███████╗ ██████╗██╗  ██╗
#  ██╔════╝╚██╗ ██╔╝██╔════╝██╔════╝██║  ██║██╔════╝██╔════╝██║ ██╔╝
#  ███████╗ ╚████╔╝ ███████╗██║     ███████║█████╗  ██║     █████╔╝ 
#  ╚════██║  ╚██╔╝  ╚════██║██║     ██╔══██║██╔══╝  ██║     ██╔═██╗ 
#  ███████║   ██║   ███████║╚██████╗██║  ██║███████╗╚██████╗██║  ██╗
#  ╚══════╝   ╚═╝   ╚══════╝ ╚═════╝╚═╝  ╚═╝╚══════╝ ╚═════╝╚═╝  ╚═╝
# ==============================================================================
#  SysCheck - Enterprise System & Hardware Diagnostic Engine
#  Version  : 4.0.0
#  Author   : V4mpw0L / Gennisys Studio
#  License  : MIT
# ==============================================================================

VERSION="4.0.0"
SCRIPT_NAME="SysCheck"
DATE_STR="$(date +%Y%m%d_%H%M%S)"
DEFAULT_LOG="syscheck_${DATE_STR}.log"
LOG_FILE="$DEFAULT_LOG"
ENABLE_LOG=true
ENABLE_COLOR=true
QUICK_MODE=false
FORCE_LANG=""
CHECK_DEPS_ONLY=false
INSTALL_DEPS_FLAG=false

# ------------------------------------------------------------------------------
# PALETA DE CORES & ESTILOS (Modern High-Contrast Studio Theme)
# ------------------------------------------------------------------------------
setup_colors() {
    if [ "$ENABLE_COLOR" = true ] && [ -t 1 ]; then
        C_RESET="\033[0m"
        C_BOLD="\033[1m"
        C_DIM="\033[2m"
        C_ITALIC="\033[3m"
        
        # Modern 256-color palette
        C_EMERALD="\033[38;5;48m"     # Gennisys Signature Emerald
        C_CYAN="\033[38;5;51m"        # Electric Cyan
        C_BLUE="\033[38;5;39m"        # Sky Blue
        C_PURPLE="\033[38;5;141m"     # Obsidian Violet
        C_GOLD="\033[38;5;220m"       # Amber / Warning Gold
        C_CRIMSON="\033[38;5;196m"    # Critical Crimson Red
        C_WHITE="\033[38;5;255m"      # Crisp Pure White
        C_SLATE="\033[38;5;245m"      # Cool Gray / Labels
        C_DARK="\033[38;5;238m"       # Border Muted Gray
    else
        C_RESET=""
        C_BOLD=""
        C_DIM=""
        C_ITALIC=""
        C_EMERALD=""
        C_CYAN=""
        C_BLUE=""
        C_PURPLE=""
        C_GOLD=""
        C_CRIMSON=""
        C_WHITE=""
        C_SLATE=""
        C_DARK=""
    fi
}

# ------------------------------------------------------------------------------
# PARSING DE ARGUMENTOS CLI
# ------------------------------------------------------------------------------
show_help() {
    cat << 'HLPEND'
SysCheck v4.0.0 - Enterprise System & Hardware Diagnostic Engine
Usage: ./syscheck.sh [OPTIONS]

Options:
  -h, --help           Show this manual and exit
  -v, --version        Display script version
  -q, --quick          Quick diagnosis (skips deep SMART drive logs & dmesg trace)
      --check-deps     Verify required and optional diagnostic dependencies
      --install-deps   Attempt to install missing dependencies via system package manager
      --no-color       Disable ANSI color output
      --no-log         Do not write log file to disk
  -o, --output FILE    Specify custom path for the generated log report
      --lang <code>    Set language explicitly: "en" (English) or "pt" (Português)

Execution Modes:
  Non-Root (User)      Safe, non-destructive audit of CPU, RAM, GPU, Network, OS.
  Root (sudo)          Unlocks deep NVMe/SATA SMART health, dmidecode BIOS/RAM,
                       and kernel dmesg ring buffer logs.

Examples:
  sudo ./syscheck.sh                 # Full deep hardware audit
  ./syscheck.sh --quick              # Quick non-root inspection
  sudo ./syscheck.sh --lang pt       # Force Portuguese interface
  ./syscheck.sh --check-deps         # Audit installed tools
HLPEND
    exit 0
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        -h|--help)
            show_help
            ;;
        -v|--version)
            echo "SysCheck version ${VERSION} (Gennisys Studio)"
            exit 0
            ;;
        -q|--quick)
            QUICK_MODE=true
            shift
            ;;
        --check-deps)
            CHECK_DEPS_ONLY=true
            shift
            ;;
        --install-deps)
            INSTALL_DEPS_FLAG=true
            shift
            ;;
        --no-color)
            ENABLE_COLOR=false
            shift
            ;;
        --no-log)
            ENABLE_LOG=false
            shift
            ;;
        -o|--output)
            LOG_FILE="$2"
            shift 2
            ;;
        --lang)
            FORCE_LANG="$2"
            shift 2
            ;;
        *)
            echo "Unknown option: $1"
            echo "Use '$0 --help' for usage."
            exit 1
            ;;
    esac
done

setup_colors

# ------------------------------------------------------------------------------
# INTERNACIONALIZAÇÃO (i18n)
# ------------------------------------------------------------------------------
CURRENT_LANG="en"
if [[ -n "$FORCE_LANG" ]]; then
    CURRENT_LANG="$FORCE_LANG"
else
    # Auto-detection
    LOCALE_CHECK="${LC_ALL:-${LC_MESSAGES:-${LANG:-}}}"
    if [[ "$LOCALE_CHECK" =~ pt(_(BR|PT))? ]]; then
        CURRENT_LANG="pt"
    fi
fi

declare -A TXT

if [[ "$CURRENT_LANG" == "pt" ]]; then
    TXT[TITLE]="MOTOR DE DIAGNÓSTICO DE SISTEMA & HARDWARE"
    TXT[SUBTITLE]="Gennisys Studio  ●  Auditoria de Infraestrutura & Hardware"
    TXT[MODE_ROOT]="MODO PRIVILEGIADO (ROOT) - DIAGNÓSTICO PROFUNDO ATIVO"
    TXT[MODE_USER]="MODO USUÁRIO (NÃO-ROOT) - EXECUTE COM 'sudo' PARA ACESSO SMART/DMI COMPLETO"
    TXT[SECTION_SYS]="01. SISTEMA OPERACIONAL & AMBIENTE"
    TXT[SECTION_CPU]="02. PROCESSADOR (CPU) & EFICIÊNCIA TÉRMICA"
    TXT[SECTION_RAM]="03. MEMÓRIA RAM & GERENCIAMENTO DE SWAP"
    TXT[SECTION_GPU]="04. SUBSISTEMA GRÁFICO & MULTI-GPU"
    TXT[SECTION_STORE]="05. ARMAZENAMENTO, DISCOS & SAÚDE S.M.A.R.T."
    TXT[SECTION_NET]="06. REDE, INTERFACES & CONECTIVIDADE"
    TXT[SECTION_USB]="07. BARRAMENTO USB & PERIFÉRICOS"
    TXT[SECTION_HEALTH]="08. SAÚDE DO SISTEMA, SERVIÇOS & LOGS DE ERRO"
    TXT[SECTION_SUMMARY]="09. PARECER EXECUTIVO & RESUMO DE SAÚDE"
    
    TXT[OS_DISTRO]="Distribuição Linux"
    TXT[KERNEL]="Kernel & Build"
    TXT[HOSTNAME]="Nome da Máquina"
    TXT[UPTIME]="Tempo de Atividade"
    TXT[LOAD_AVG]="Carga Média (1, 5, 15m)"
    TXT[INIT_SYS]="Sistema de Init"
    TXT[DESKTOP_ENV]="Interface / Sessão"
    TXT[MOTHERBOARD]="Placa-Mãe / Chassi"
    TXT[BIOS_INFO]="Firmware BIOS"
    
    TXT[CPU_MODEL]="Modelo do Processador"
    TXT[CPU_ARCH]="Arquitetura / Cores"
    TXT[CPU_FREQ]="Frequência Atual / Máx"
    TXT[CPU_GOVERNOR]="Governor de Energia"
    TXT[CPU_CACHE]="Cache L1 / L2 / L3"
    TXT[CPU_TEMP]="Temperatura da CPU"
    TXT[CPU_FANS]="Ventiladores / Refrigeração"
    TXT[CPU_VULN]="Mitigações de CPU"
    
    TXT[RAM_TOTAL]="Memória Total"
    TXT[RAM_USED]="Memória em Uso"
    TXT[RAM_AVAIL]="Memória Disponível"
    TXT[SWAP_USAGE]="Espaço Swap"
    TXT[RAM_MODULES]="Módulos Físicos DMI"
    
    TXT[GPU_DETECTED]="Placas de Vídeo Detectadas"
    TXT[GPU_ACTIVE_DRV]="Driver de Kernel em Uso"
    TXT[OPENGL_RENDER]="Renderizador OpenGL"
    TXT[VULKAN_DEVS]="Dispositivos Vulkan"
    TXT[NVIDIA_STATUS]="Status Dedicado NVIDIA"
    TXT[NVIDIA_MEM]="VRAM Alocada"
    TXT[NVIDIA_TEMP]="Temperatura / Fans"
    
    TXT[STORAGE_POOLS]="Sistemas de Arquivos Montados"
    TXT[PHYSICAL_DISKS]="Discos Físicos Detectados"
    TXT[SMART_DIAG]="Diagnóstico S.M.A.R.T."
    TXT[SMART_ROOT_REQ]="Requer permissões de root para consultar controladores NVMe/SATA."
    TXT[SMART_STATUS]="Integridade S.M.A.R.T."
    TXT[SMART_WEAR]="Desgaste / Horas Ligado"
    TXT[SMART_TEMP]="Temperatura da Unidade"
    
    TXT[NET_INTERFACES]="Interfaces de Rede Ativas"
    TXT[GATEWAY_DNS]="Gateway Padrão & DNS"
    TXT[INTERNET_TEST]="Latência com a Internet"
    TXT[PING_SUCCESS]="Conectado"
    TXT[PING_FAIL]="Falha ao alcançar servidores de teste"
    
    TXT[USB_COUNT]="Dispositivos USB Conectados"
    TXT[FAILED_UNITS]="Serviços systemd com Falha"
    TXT[KERNEL_ERRS]="Erros Críticos no Kernel (dmesg)"
    TXT[JOURNAL_ERRS]="Erros Recentes no Systemd Journal"
    
    TXT[SCORE_OPTIMAL]="EXCELENTE - Nenhum problema crítico detectado"
    TXT[SCORE_WARN]="ATENÇÃO - Alertas detectados (alta utilização ou erros leves)"
    TXT[SCORE_CRIT]="CRÍTICO - Falhas ativas encontradas no sistema"
    TXT[REPORT_GENERATED]="Relatório detalhado salvo com sucesso em:"
    TXT[HELP_NOTE]="Dica: Para análises de hardware em profundidade, execute: sudo ./syscheck.sh"
else
    TXT[TITLE]="ENTERPRISE SYSTEM & HARDWARE DIAGNOSTIC ENGINE"
    TXT[SUBTITLE]="Gennisys Studio  ●  Infrastructure & Hardware Audit"
    TXT[MODE_ROOT]="PRIVILEGED MODE (ROOT) - DEEP HARDWARE AUDIT ACTIVE"
    TXT[MODE_USER]="USER MODE (NON-ROOT) - RUN WITH 'sudo' FOR COMPLETE SMART/DMI ACCESS"
    TXT[SECTION_SYS]="01. OPERATING SYSTEM & ENVIRONMENT"
    TXT[SECTION_CPU]="02. PROCESSOR (CPU) & THERMAL EFFICIENCY"
    TXT[SECTION_RAM]="03. RAM ALLOCATION & SWAP MANAGEMENT"
    TXT[SECTION_GPU]="04. GRAPHICS SUBSYSTEM & MULTI-GPU PIPELINE"
    TXT[SECTION_STORE]="05. STORAGE, DISKS & S.M.A.R.T. HEALTH"
    TXT[SECTION_NET]="06. NETWORK TOPOLOGY & CONNECTIVITY"
    TXT[SECTION_USB]="07. USB CONTROLLERS & PERIPHERALS"
    TXT[SECTION_HEALTH]="08. SYSTEM HEALTH, FAILED SERVICES & LOGS"
    TXT[SECTION_SUMMARY]="09. EXECUTIVE AUDIT & HEALTH SUMMARY"
    
    TXT[OS_DISTRO]="Linux Distribution"
    TXT[KERNEL]="Kernel & Build"
    TXT[HOSTNAME]="Machine Hostname"
    TXT[UPTIME]="System Uptime"
    TXT[LOAD_AVG]="Load Averages (1, 5, 15m)"
    TXT[INIT_SYS]="Init Subsystem"
    TXT[DESKTOP_ENV]="Desktop / Session"
    TXT[MOTHERBOARD]="Motherboard / Chassis"
    TXT[BIOS_INFO]="Firmware / BIOS"
    
    TXT[CPU_MODEL]="Processor Model"
    TXT[CPU_ARCH]="Architecture / Cores"
    TXT[CPU_FREQ]="Frequency (Current/Max)"
    TXT[CPU_GOVERNOR]="Scaling Governor"
    TXT[CPU_CACHE]="Cache L1 / L2 / L3"
    TXT[CPU_TEMP]="CPU Package Temp"
    TXT[CPU_FANS]="Cooling Fans Telemetry"
    TXT[CPU_VULN]="Mitigation Status"
    
    TXT[RAM_TOTAL]="Total Physical RAM"
    TXT[RAM_USED]="Allocated Memory"
    TXT[RAM_AVAIL]="Available Memory"
    TXT[SWAP_USAGE]="Swap Allocation"
    TXT[RAM_MODULES]="Physical DMI Modules"
    
    TXT[GPU_DETECTED]="Detected Display Adapters"
    TXT[GPU_ACTIVE_DRV]="Active Kernel Driver"
    TXT[OPENGL_RENDER]="OpenGL Renderer"
    TXT[VULKAN_DEVS]="Vulkan Devices"
    TXT[NVIDIA_STATUS]="NVIDIA Dedicated Status"
    TXT[NVIDIA_MEM]="VRAM Allocation"
    TXT[NVIDIA_TEMP]="GPU Temp / Fans"
    
    TXT[STORAGE_POOLS]="Mounted Filesystems"
    TXT[PHYSICAL_DISKS]="Physical Block Devices"
    TXT[SMART_DIAG]="S.M.A.R.T. Health Status"
    TXT[SMART_ROOT_REQ]="Root permissions required to query NVMe/SATA registers."
    TXT[SMART_STATUS]="Overall S.M.A.R.T."
    TXT[SMART_WEAR]="Wear Level / Power Hours"
    TXT[SMART_TEMP]="Drive Temperature"
    
    TXT[NET_INTERFACES]="Active Network Interfaces"
    TXT[GATEWAY_DNS]="Default Gateway & DNS"
    TXT[INTERNET_TEST]="Live Latency Test"
    TXT[PING_SUCCESS]="Online"
    TXT[PING_FAIL]="Unable to reach benchmark targets"
    
    TXT[USB_COUNT]="Connected USB Devices"
    TXT[FAILED_UNITS]="Failed Systemd Units"
    TXT[KERNEL_ERRS]="Critical Kernel Log Events (dmesg)"
    TXT[JOURNAL_ERRS]="Recent Journal Error Events"
    
    TXT[SCORE_OPTIMAL]="OPTIMAL - No critical warnings or failures detected"
    TXT[SCORE_WARN]="WARNING - Elevated resource usage or non-critical issues"
    TXT[SCORE_CRIT]="CRITICAL - Active service or hardware warnings present"
    TXT[REPORT_GENERATED]="Comprehensive report saved to:"
    TXT[HELP_NOTE]="Tip: Run with 'sudo ./syscheck.sh' for full NVMe SMART and DMI access."
fi

# ------------------------------------------------------------------------------
# LOGGING & OUTPUT DISPATCHER
# ------------------------------------------------------------------------------
if [ "$ENABLE_LOG" = true ]; then
    mkdir -p "$(dirname "$LOG_FILE")" 2>/dev/null || true
    : > "$LOG_FILE"
fi

out() {
    local text="$1"
    echo -e "$text"
    if [ "$ENABLE_LOG" = true ]; then
        # Strip ANSI codes for clean file readability
        echo -e "$text" | sed 's/\x1B\[[0-9;]*[mK]//g' >> "$LOG_FILE"
    fi
}

# ------------------------------------------------------------------------------
# COMPONENTES VISUAIS & FORMATADORES
# ------------------------------------------------------------------------------
print_banner() {
    out ""
    out "${C_EMERALD}  ███████╗██╗   ██╗███████╗ ██████╗██╗  ██╗███████╗ ██████╗██╗  ██╗${C_RESET}"
    out "${C_EMERALD}  ██╔════╝╚██╗ ██╔╝██╔════╝██╔════╝██║  ██║██╔════╝██╔════╝██║ ██╔╝${C_RESET}"
    out "${C_EMERALD}  ███████╗ ╚████╔╝ ███████╗██║     ███████║█████╗  ██║     █████╔╝ ${C_RESET}"
    out "${C_CYAN}  ╚════██║  ╚██╔╝  ╚════██║██║     ██╔══██║██╔══╝  ██║     ██╔═██╗ ${C_RESET}"
    out "${C_CYAN}  ███████║   ██║   ███████║╚██████╗██║  ██║███████╗╚██████╗██║  ██╗${C_RESET}"
    out "${C_CYAN}  ╚══════╝   ╚═╝   ╚══════╝ ╚═════╝╚═╝  ╚═╝╚══════╝ ╚═════╝╚═╝  ╚═╝${C_RESET}"
    out ""
    out "  ${C_BOLD}${C_WHITE}${TXT[TITLE]}${C_RESET} ${C_EMERALD}[v${VERSION}]${C_RESET}"
    out "  ${C_SLATE}${TXT[SUBTITLE]}${C_RESET}"
    out "  ${C_DARK}────────────────────────────────────────────────────────────────────────${C_RESET}"
    
    local USER_STR
    if [[ $EUID -eq 0 ]]; then
        USER_STR="${C_EMERALD}⚡ ${TXT[MODE_ROOT]}${C_RESET}"
    else
        USER_STR="${C_GOLD}▲ ${TXT[MODE_USER]}${C_RESET}"
    fi
    out "  ${USER_STR}"
    out "  ${C_SLATE}Date: $(date '+%Y-%m-%d %H:%M:%S %Z')  ●  Host: ${C_WHITE}$(hostname)${C_RESET}"
    out ""
}

print_section() {
    local title="$1"
    out ""
    out "${C_DARK}╭────────────────────────────────────────────────────────────────────────╮${C_RESET}"
    out "${C_DARK}│ ${C_BOLD}${C_EMERALD}❖  ${title}${C_RESET}"
    out "${C_DARK}╰────────────────────────────────────────────────────────────────────────╯${C_RESET}"
}

print_kv() {
    local key="$1"
    local val="$2"
    printf -v line "  ${C_SLATE}●  %-28s${C_RESET} : ${C_WHITE}%b${C_RESET}" "$key" "$val"
    out "$line"
}

print_sub() {
    local subtitle="$1"
    out "  ${C_CYAN}▸ ${subtitle}${C_RESET}"
}

# Gera barra de progresso visual [████████░░░░] 67%
render_bar() {
    local pct="${1:-0}"
    local width="${2:-16}"
    
    pct=${pct%.*}
    [[ ! "$pct" =~ ^[0-9]+$ ]] && pct=0
    (( pct > 100 )) && pct=100
    
    local filled=$(( (pct * width) / 100 ))
    local empty=$(( width - filled ))
    
    local bar_color="$C_EMERALD"
    if (( pct > 85 )); then
        bar_color="$C_CRIMSON"
    elif (( pct > 70 )); then
        bar_color="$C_GOLD"
    fi
    
    local fill_str=""
    local empty_str=""
    for ((i=0; i<filled; i++)); do fill_str+="█"; done
    for ((i=0; i<empty; i++)); do empty_str+="░"; done
    
    echo -e "${bar_color}[${fill_str}${empty_str}] ${pct}%${C_RESET}"
}

# ------------------------------------------------------------------------------
# TRACKING DE ERROS / HEALTH SCORE GLOBAL
# ------------------------------------------------------------------------------
TOTAL_WARNINGS=0
TOTAL_FAILURES=0

record_warn() { ((TOTAL_WARNINGS++)) || true; }
record_fail() { ((TOTAL_FAILURES++)) || true; }

has_cmd() {
    command -v "$1" &>/dev/null
}

# ------------------------------------------------------------------------------
# AUDITORIA & INSTALAÇÃO DE DEPENDÊNCIAS
# ------------------------------------------------------------------------------
check_or_install_deps() {
    local install_mode="$1"
    out ""
    out "${C_BOLD}${C_CYAN}=== SysCheck Dependency Audit ===${C_RESET}"
    
    # Required and recommended commands
    local -A PKG_FEDORA=(
        ["lscpu"]="util-linux"
        ["lsblk"]="util-linux"
        ["lspci"]="pciutils"
        ["lsusb"]="usbutils"
        ["sensors"]="lm_sensors"
        ["smartctl"]="smartmontools"
        ["glxinfo"]="mesa-demos"
        ["vulkaninfo"]="vulkan-tools"
        ["dmidecode"]="dmidecode"
        ["ip"]="iproute"
        ["ping"]="iputils"
        ["nvidia-smi"]="nvidia-driver"
    )
    
    local -A PKG_DEBIAN=(
        ["lscpu"]="util-linux"
        ["lsblk"]="util-linux"
        ["lspci"]="pciutils"
        ["lsusb"]="usbutils"
        ["sensors"]="lm-sensors"
        ["smartctl"]="smartmontools"
        ["glxinfo"]="mesa-utils"
        ["vulkaninfo"]="vulkan-tools"
        ["dmidecode"]="dmidecode"
        ["ip"]="iproute2"
        ["ping"]="iputils-ping"
        ["nvidia-smi"]="nvidia-utils"
    )

    local -A PKG_ARCH=(
        ["lscpu"]="util-linux"
        ["lsblk"]="util-linux"
        ["lspci"]="pciutils"
        ["lsusb"]="usbutils"
        ["sensors"]="lm_sensors"
        ["smartctl"]="smartmontools"
        ["glxinfo"]="mesa-utils"
        ["vulkaninfo"]="vulkan-tools"
        ["dmidecode"]="dmidecode"
        ["ip"]="iproute2"
        ["ping"]="iputils"
        ["nvidia-smi"]="nvidia-utils"
    )

    # Detect package manager
    local pkg_mgr=""
    if has_cmd dnf; then pkg_mgr="dnf"
    elif has_cmd apt; then pkg_mgr="apt"
    elif has_cmd pacman; then pkg_mgr="pacman"
    elif has_cmd zypper; then pkg_mgr="zypper"
    fi

    local missing=()
    local missing_pkgs=()

    for cmd in "${!PKG_FEDORA[@]}"; do
        if has_cmd "$cmd"; then
            out "  ${C_EMERALD}✔ [FOUND]${C_RESET} ${cmd}"
        else
            out "  ${C_GOLD}▲ [MISSING]${C_RESET} ${cmd}"
            missing+=("$cmd")
            case "$pkg_mgr" in
                "dnf") missing_pkgs+=("${PKG_FEDORA[$cmd]}") ;;
                "apt") missing_pkgs+=("${PKG_DEBIAN[$cmd]}") ;;
                "pacman") missing_pkgs+=("${PKG_ARCH[$cmd]}") ;;
                *) missing_pkgs+=("$cmd") ;;
            esac
        fi
    done

    out ""
    if [[ ${#missing[@]} -eq 0 ]]; then
        out "  ${C_EMERALD}${C_BOLD}All dependencies are installed! SysCheck is ready for full-depth analysis.${C_RESET}"
    else
        out "  ${C_GOLD}Missing commands (${#missing[@]}): ${missing[*]}${C_RESET}"
        if [ -n "$pkg_mgr" ]; then
            out "  Suggested installation command:"
            case "$pkg_mgr" in
                "dnf") out "    ${C_WHITE}sudo dnf install -y ${missing_pkgs[*]}${C_RESET}" ;;
                "apt") out "    ${C_WHITE}sudo apt update && sudo apt install -y ${missing_pkgs[*]}${C_RESET}" ;;
                "pacman") out "    ${C_WHITE}sudo pacman -S --noconfirm ${missing_pkgs[*]}${C_RESET}" ;;
                "zypper") out "    ${C_WHITE}sudo zypper install -y ${missing_pkgs[*]}${C_RESET}" ;;
            esac

            if [ "$install_mode" = true ]; then
                if [[ $EUID -ne 0 ]]; then
                    out "  ${C_CRIMSON}Root privileges required to install packages. Re-run with sudo.${C_RESET}"
                    exit 1
                fi
                out ""
                out "  ${C_CYAN}Installing packages: ${missing_pkgs[*]}...${C_RESET}"
                case "$pkg_mgr" in
                    "dnf") dnf install -y "${missing_pkgs[@]}" ;;
                    "apt") apt update && apt install -y "${missing_pkgs[@]}" ;;
                    "pacman") pacman -S --noconfirm "${missing_pkgs[@]}" ;;
                    "zypper") zypper install -y "${missing_pkgs[@]}" ;;
                esac
            fi
        fi
    fi
    exit 0
}

# ==============================================================================
# SEÇÃO 01: SISTEMA OPERACIONAL & AMBIENTE
# ==============================================================================
audit_system() {
    print_section "${TXT[SECTION_SYS]}"
    
    # Distro
    local distro_name=""
    if [ -f /etc/os-release ]; then
        # shellcheck disable=SC1091
        distro_name=$(source /etc/os-release && echo "${PRETTY_NAME:-$NAME $VERSION}")
    elif has_cmd lsb_release; then
        distro_name=$(lsb_release -d -s)
    else
        distro_name=$(uname -s)
    fi
    print_kv "${TXT[OS_DISTRO]}" "${distro_name}"
    
    # Kernel & Arch
    local kernel_ver
    kernel_ver="$(uname -r) ($(uname -m))"
    print_kv "${TXT[KERNEL]}" "${kernel_ver}"
    
    # Hostname & ID
    local m_id="N/A"
    [ -f /etc/machine-id ] && m_id=$(head -c 8 /etc/machine-id)
    print_kv "${TXT[HOSTNAME]}" "$(hostname) (${m_id}...)"
    
    # Uptime & Load
    local uptime_raw
    uptime_raw="$(uptime -p 2>/dev/null || uptime | sed 's/.*up \([^,]*\), .*/\1/')"
    uptime_raw="${uptime_raw#up }"
    print_kv "${TXT[UPTIME]}" "${uptime_raw}"
    
    local load_avg
    load_avg="$(awk '{print $1", "$2", "$3}' /proc/loadavg 2>/dev/null || uptime | awk -F'load average:' '{print $2}')"
    print_kv "${TXT[LOAD_AVG]}" "${load_avg}"
    
    # Init system & Desktop
    local init_sys="systemd"
    if [ ! -d /run/systemd/system ]; then
        init_sys="SysV/OpenRC/Other"
    fi
    print_kv "${TXT[INIT_SYS]}" "${init_sys}"
    
    local session_env="${XDG_CURRENT_DESKTOP:-Standard} (${XDG_SESSION_TYPE:-TTY})"
    print_kv "${TXT[DESKTOP_ENV]}" "${session_env}"
    
    # Motherboard & BIOS
    local mb_vendor mb_product bios_ven bios_ver bios_date
    mb_vendor="$(cat /sys/class/dmi/id/board_vendor 2>/dev/null || cat /sys/class/dmi/id/sys_vendor 2>/dev/null || echo '')"
    mb_product="$(cat /sys/class/dmi/id/board_name 2>/dev/null || cat /sys/class/dmi/id/product_name 2>/dev/null || echo '')"
    bios_ven="$(cat /sys/class/dmi/id/bios_vendor 2>/dev/null || echo '')"
    bios_ver="$(cat /sys/class/dmi/id/bios_version 2>/dev/null || echo '')"
    bios_date="$(cat /sys/class/dmi/id/bios_date 2>/dev/null || echo '')"
    
    if [[ -z "$mb_product" ]] && has_cmd dmidecode && [[ $EUID -eq 0 ]]; then
        mb_product=$(dmidecode -s baseboard-product-name 2>/dev/null || echo "Unknown")
        mb_vendor=$(dmidecode -s baseboard-manufacturer 2>/dev/null || echo "")
        bios_ver=$(dmidecode -s bios-version 2>/dev/null || echo "")
    fi
    
    local mb_str="${mb_vendor:-Generic} ${mb_product:-System}"
    print_kv "${TXT[MOTHERBOARD]}" "${mb_str}"
    
    local bios_str="${bios_ven:-BIOS} ${bios_ver:-vUnknown} (${bios_date:-N/A})"
    print_kv "${TXT[BIOS_INFO]}" "${bios_str}"
}

# ==============================================================================
# SEÇÃO 02: PROCESSADOR (CPU) & TÉRMICO
# ==============================================================================
audit_cpu() {
    print_section "${TXT[SECTION_CPU]}"
    
    local cpu_model
    cpu_model="$(grep -m1 "model name" /proc/cpuinfo 2>/dev/null | cut -d: -f2 | xargs)"
    if [ -z "$cpu_model" ] && has_cmd lscpu; then
        cpu_model="$(lscpu | grep "Model name:" | cut -d: -f2 | xargs)"
    fi
    print_kv "${TXT[CPU_MODEL]}" "${cpu_model:-Unknown Processor}"
    
    local cores threads
    cores=$(grep -c "^core id" /proc/cpuinfo 2>/dev/null || echo "1")
    threads=$(nproc 2>/dev/null || grep -c "^processor" /proc/cpuinfo || echo "1")
    local arch_str="$(uname -m) ● ${cores} Physical Cores / ${threads} Threads"
    print_kv "${TXT[CPU_ARCH]}" "${arch_str}"
    
    # CPU Frequency
    local cur_freq max_freq
    if [ -f /sys/devices/system/cpu/cpu0/cpufreq/scaling_cur_freq ]; then
        cur_freq=$(( $(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_cur_freq) / 1000 ))
        max_freq=$(( $(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_max_freq) / 1000 ))
        print_kv "${TXT[CPU_FREQ]}" "${cur_freq} MHz / ${max_freq} MHz"
    elif has_cmd lscpu; then
        local freq_str
        freq_str="$(lscpu | grep "CPU MHz:" | awk '{print $3}') MHz"
        print_kv "${TXT[CPU_FREQ]}" "${freq_str}"
    fi
    
    # Governor
    if [ -f /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor ]; then
        local gov
        gov=$(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor)
        print_kv "${TXT[CPU_GOVERNOR]}" "${gov}"
    fi
    
    # Caches
    if has_cmd lscpu; then
        local l1d l2 l3
        l1d=$(lscpu | grep "L1d cache:" | awk -F: '{print $2}' | xargs)
        l2=$(lscpu | grep "L2 cache:" | awk -F: '{print $2}' | xargs)
        l3=$(lscpu | grep "L3 cache:" | awk -F: '{print $2}' | xargs)
        print_kv "${TXT[CPU_CACHE]}" "L1d: ${l1d:-N/A} | L2: ${l2:-N/A} | L3: ${l3:-N/A}"
    fi
    
    # CPU Temperature check
    local cpu_temp=""
    if has_cmd sensors; then
        cpu_temp=$(sensors 2>/dev/null | grep -E "Package id 0|Tdie|Tctl|CPU:" | head -n1 | awk '{print $4}' | tr -d '+')
        if [ -z "$cpu_temp" ]; then
            cpu_temp=$(sensors 2>/dev/null | grep -E "Core 0:" | head -n1 | awk '{print $3}' | tr -d '+')
        fi
    fi
    
    if [ -n "$cpu_temp" ]; then
        local temp_num="${cpu_temp%.*}"
        temp_num="${temp_num%°C}"
        temp_num="${temp_num%C}"
        local temp_disp
        if [[ "$temp_num" =~ ^[0-9]+$ ]]; then
            if (( temp_num >= 85 )); then
                temp_disp="${C_CRIMSON}${C_BOLD}${cpu_temp} [CRITICAL / THROTTLING]${C_RESET}"
                record_fail
            elif (( temp_num >= 70 )); then
                temp_disp="${C_GOLD}${cpu_temp} [HIGH LOAD]${C_RESET}"
                record_warn
            else
                temp_disp="${C_EMERALD}${cpu_temp} [NORMAL]${C_RESET}"
            fi
        else
            temp_disp="${cpu_temp}"
        fi
        print_kv "${TXT[CPU_TEMP]}" "${temp_disp}"
    fi

    # Fans Telemetry
    if has_cmd sensors; then
        local fan_info
        fan_info=$(sensors 2>/dev/null | grep -i "fan" | awk -F: '{gsub(/^[ \t]+|[ \t]+$/, "", $2); print $1": "$2}' | paste -sd " | " -)
        if [ -n "$fan_info" ]; then
            print_kv "${TXT[CPU_FANS]}" "${fan_info}"
        fi
    fi
    
    # Vulnerabilities check
    if [ -d /sys/devices/system/cpu/vulnerabilities ]; then
        local vuln_count vuln_mitigated
        vuln_count=$(find /sys/devices/system/cpu/vulnerabilities -type f | wc -l)
        vuln_mitigated=$(grep -sh "Mitigation" /sys/devices/system/cpu/vulnerabilities/* | wc -l)
        print_kv "${TXT[CPU_VULN]}" "${vuln_mitigated}/${vuln_count} hardware mitigations active"
    fi
}

# ==============================================================================
# SEÇÃO 03: MEMÓRIA RAM & SWAP
# ==============================================================================
audit_ram() {
    print_section "${TXT[SECTION_RAM]}"
    
    if has_cmd free; then
        local total_m used_m free_m avail_m
        read -r _ total_m used_m free_m _ _ avail_m <<< "$(free -m | grep -E '^Mem:' || true)"
        
        if [[ -n "$total_m" && "$total_m" -gt 0 ]]; then
            local pct_used=$(( (used_m * 100) / total_m ))
            local bar
            bar=$(render_bar "$pct_used" 16)
            
            local total_g used_g avail_g
            total_g=$(awk "BEGIN {printf \"%.1f\", $total_m / 1024}")
            used_g=$(awk "BEGIN {printf \"%.1f\", $used_m / 1024}")
            avail_g=$(awk "BEGIN {printf \"%.1f\", $avail_m / 1024}")
            
            print_kv "${TXT[RAM_TOTAL]}" "${total_g} GiB"
            print_kv "${TXT[RAM_USED]}" "${used_g} GiB ${bar}"
            print_kv "${TXT[RAM_AVAIL]}" "${avail_g} GiB"
            
            if (( pct_used > 92 )); then
                record_fail
            elif (( pct_used > 80 )); then
                record_warn
            fi
        fi
        
        # Swap
        local sw_total_m sw_used_m
        read -r _ sw_total_m sw_used_m _ <<< "$(free -m | grep -E '^Swap:' || true)"
        if [[ -n "$sw_total_m" && "$sw_total_m" -gt 0 ]]; then
            local sw_pct=$(( (sw_used_m * 100) / sw_total_m ))
            local sw_bar
            sw_bar=$(render_bar "$sw_pct" 16)
            local sw_tot_g sw_usd_g
            sw_tot_g=$(awk "BEGIN {printf \"%.1f\", $sw_total_m / 1024}")
            sw_usd_g=$(awk "BEGIN {printf \"%.1f\", $sw_used_m / 1024}")
            print_kv "${TXT[SWAP_USAGE]}" "${sw_usd_g} / ${sw_tot_g} GiB ${sw_bar}"
        else
            print_kv "${TXT[SWAP_USAGE]}" "Disabled / None"
        fi
    fi
    
    # DMI Memory Sticks (Root only)
    if [[ $EUID -eq 0 ]] && has_cmd dmidecode; then
        out ""
        print_sub "${TXT[RAM_MODULES]}"
        dmidecode -t memory 2>/dev/null | awk '
            /Memory Device$/ {in_dev=1; size=""; type=""; speed=""; mfr=""}
            in_dev && /Size: [0-9]/ {size=$2" "$3}
            in_dev && /Type: / {type=$2}
            in_dev && /Speed: [0-9]/ {speed=$2" "$3}
            in_dev && /Manufacturer: / {mfr=$2}
            in_dev && size && speed {
                printf "    %s  Slot Module: %s %s @ %s (%s)\n", "\033[38;5;48m✔\033[0m", size, type, speed, mfr
                in_dev=0
            }
        ' | while read -r line; do out "$line"; done
    fi
}

# ==============================================================================
# SEÇÃO 04: SUBSISTEMA GRÁFICO & MULTI-GPU
# ==============================================================================
audit_gpu() {
    print_section "${TXT[SECTION_GPU]}"
    
    if has_cmd lspci; then
        local gpus
        mapfile -t gpus < <(lspci -nn | grep -E "VGA compatible controller|3D controller|Display controller")
        
        if [[ ${#gpus[@]} -gt 0 ]]; then
            out "  ${C_CYAN}▸ ${TXT[GPU_DETECTED]} (${#gpus[@]}):${C_RESET}"
            for gpu_line in "${gpus[@]}"; do
                local pci_id="${gpu_line%% *}"
                local desc="${gpu_line#* controller*: }"
                out "    ${C_EMERALD}⚡${C_RESET} ${C_WHITE}[${pci_id}]${C_RESET} ${desc}"
                
                local kdriver
                kdriver=$(lspci -k -s "$pci_id" 2>/dev/null | grep "Kernel driver in use:" | awk -F: '{print $2}' | xargs)
                if [ -n "$kdriver" ]; then
                    out "       ${C_SLATE}└─ Driver: ${C_CYAN}${kdriver}${C_RESET}"
                fi
            done
        else
            print_kv "${TXT[GPU_DETECTED]}" "None found via PCI bus"
        fi
    fi
    
    # OpenGL Renderer
    if has_cmd glxinfo; then
        local gl_render gl_ver
        gl_render=$(glxinfo -B 2>/dev/null | grep "OpenGL renderer string:" | awk -F: '{print $2}' | xargs)
        gl_ver=$(glxinfo -B 2>/dev/null | grep "OpenGL core profile version string:" | awk -F: '{print $2}' | xargs)
        if [ -n "$gl_render" ]; then
            print_kv "${TXT[OPENGL_RENDER]}" "${gl_render} (${gl_ver:-N/A})"
        fi
    fi
    
    # Vulkan Devices
    if has_cmd vulkaninfo; then
        local vulkan_devs
        mapfile -t vulkan_devs < <(vulkaninfo --summary 2>/dev/null | grep "deviceName" | cut -d= -f2 | xargs -L1 || true)
        if [[ ${#vulkan_devs[@]} -gt 0 ]]; then
            local v_list
            v_list=$(printf "%s, " "${vulkan_devs[@]}")
            v_list="${v_list%, }"
            print_kv "${TXT[VULKAN_DEVS]}" "${v_list}"
        fi
    fi
    
    # NVIDIA Dedicated Subsystem
    if has_cmd nvidia-smi; then
        local nv_raw
        nv_raw=$(nvidia-smi --query-gpu=name,driver_version,temperature.gpu,utilization.gpu,memory.used,memory.total,fan.speed --format=csv,noheader,nounits 2>/dev/null || true)
        if [ -n "$nv_raw" ]; then
            out ""
            print_sub "${TXT[NVIDIA_STATUS]}"
            IFS=',' read -r nv_name nv_drv nv_temp nv_util nv_mem_used nv_mem_tot nv_fan <<< "$nv_raw"
            
            nv_name=$(echo "$nv_name" | xargs)
            nv_drv=$(echo "$nv_drv" | xargs)
            nv_temp=$(echo "$nv_temp" | xargs)
            nv_util=$(echo "$nv_util" | xargs)
            nv_mem_used=$(echo "$nv_mem_used" | xargs)
            nv_mem_tot=$(echo "$nv_mem_tot" | xargs)
            nv_fan=$(echo "$nv_fan" | xargs)
            
            out "    ${C_WHITE}Model${C_RESET}       : ${C_EMERALD}${nv_name}${C_RESET} (Driver: ${nv_drv})"
            
            if [[ -n "$nv_mem_tot" && "$nv_mem_tot" -gt 0 ]]; then
                local nv_pct=$(( (nv_mem_used * 100) / nv_mem_tot ))
                local nv_bar
                nv_bar=$(render_bar "$nv_pct" 16)
                out "    ${C_WHITE}VRAM Usage${C_RESET}  : ${nv_mem_used} / ${nv_mem_tot} MiB ${nv_bar}"
            fi
            
            local fan_disp="${nv_fan:-N/A}%"
            [[ "$nv_fan" =~ \[N/A\] ]] && fan_disp="Dynamic ACPI"
            out "    ${C_WHITE}Core Temp${C_RESET}   : ${C_CYAN}${nv_temp}°C${C_RESET}  ●  Core Load: ${nv_util}%  ●  Fan: ${fan_disp}"
        fi
    fi
}

# ==============================================================================
# SEÇÃO 05: ARMAZENAMENTO & S.M.A.R.T.
# ==============================================================================
audit_storage() {
    print_section "${TXT[SECTION_STORE]}"
    
    print_sub "${TXT[STORAGE_POOLS]}"
    out "    ${C_SLATE}$(printf "%-18s %-7s %-9s %-9s %-9s %s" "MOUNTPOINT" "TYPE" "SIZE" "USED" "AVAIL" "CAPACITY")${C_RESET}"
    
    while read -r fs type size used avail pcent mnt; do
        [[ "$mnt" == "Mounted" || "$fs" == "Filesystem" || -z "$mnt" ]] && continue
        local pct_clean="${pcent%\%}"
        local bar
        bar=$(render_bar "$pct_clean" 10)
        out "    $(printf "%-18s %-7s %-9s %-9s %-9s" "$mnt" "$type" "$size" "$used" "$avail") ${bar}"
        
        if (( pct_clean > 90 )); then
            record_fail
        elif (( pct_clean > 80 )); then
            record_warn
        fi
    done < <(df -hT -x tmpfs -x devtmpfs -x efivarfs -x squashfs 2>/dev/null || true)
    
    out ""
    if has_cmd lsblk; then
        print_sub "${TXT[PHYSICAL_DISKS]}"
        lsblk -d -o NAME,TYPE,SIZE,MODEL,ROTA 2>/dev/null | grep -E "disk|NAME" | while read -r line; do
            out "    ${C_DARK}│${C_RESET} ${line}"
        done
    fi
    
    # S.M.A.R.T. Diagnostics
    out ""
    print_sub "${TXT[SMART_DIAG]}"
    
    if [[ $EUID -ne 0 ]]; then
        out "    ${C_GOLD}▲ ${TXT[SMART_ROOT_REQ]}${C_RESET}"
    elif ! has_cmd smartctl; then
        out "    ${C_SLATE}smartctl not installed (package: smartmontools)${C_RESET}"
    else
        local disk_names
        mapfile -t disk_names < <(lsblk -d -n -o NAME,TYPE | grep "disk" | grep -v "zram" | awk '{print $1}')
        
        if [[ ${#disk_names[@]} -eq 0 ]]; then
            out "    ${C_SLATE}No physical drives found.${C_RESET}"
        else
            for d in "${disk_names[@]}"; do
                local dev_path="/dev/${d}"
                out ""
                out "    ${C_EMERALD}◆ Drive: ${dev_path}${C_RESET}"
                
                local smart_out
                smart_out=$(smartctl -i -H "$dev_path" 2>/dev/null || true)
                
                local model serial fw health
                model=$(echo "$smart_out" | grep -E "Device Model|Model Number" | cut -d: -f2 | xargs)
                serial=$(echo "$smart_out" | grep -E "Serial Number" | cut -d: -f2 | xargs)
                fw=$(echo "$smart_out" | grep -E "Firmware Version" | cut -d: -f2 | xargs)
                health=$(echo "$smart_out" | grep -E "SMART overall-health self-assessment test result|SMART Health Status" | cut -d: -f2 | xargs)
                
                out "      ${C_SLATE}Model / Serial :${C_RESET} ${model:-Generic} (${serial:-N/A}) [FW: ${fw:-N/A}]"
                
                if [[ "$health" =~ (PASSED|OK) ]]; then
                    out "      ${C_SLATE}Health Status  :${C_RESET} ${C_EMERALD}[✔ ${health}]${C_RESET}"
                elif [[ -n "$health" ]]; then
                    out "      ${C_SLATE}Health Status  :${C_RESET} ${C_CRIMSON}[✖ ${health}]${C_RESET}"
                    record_fail
                else
                    out "      ${C_SLATE}Health Status  :${C_RESET} ${C_SLATE}Not Reported${C_RESET}"
                fi
                
                if [[ "$dev_path" =~ nvme ]]; then
                    local wear temp p_hours
                    wear=$(smartctl -A "$dev_path" 2>/dev/null | grep "Percentage Used" | cut -d: -f2 | xargs)
                    temp=$(smartctl -A "$dev_path" 2>/dev/null | grep "Temperature:" | head -n1 | awk '{print $2}')
                    p_hours=$(smartctl -A "$dev_path" 2>/dev/null | grep "Power On Hours" | cut -d: -f2 | xargs)
                    
                    if [ -n "$wear" ]; then
                        out "      ${C_SLATE}SSD Life Used  :${C_RESET} ${wear} worn  ●  Temp: ${temp:-N/A}°C  ●  Power Hours: ${p_hours:-N/A}"
                    fi
                fi
            done
        fi
    fi
}

# ==============================================================================
# SEÇÃO 06: REDE & CONECTIVIDADE
# ==============================================================================
audit_network() {
    print_section "${TXT[SECTION_NET]}"
    
    if has_cmd ip; then
        print_sub "${TXT[NET_INTERFACES]}"
        out "    ${C_SLATE}$(printf "%-16s %-10s %-18s %s" "INTERFACE" "STATUS" "MAC ADDRESS" "IP ADDRESSES")${C_RESET}"
        
        while read -r iface state mac addr; do
            [[ -z "$iface" || "$iface" == "lo" ]] && continue
            local state_padded
            printf -v state_padded "%-10s" "$state"
            if [[ "$state" == "UP" ]]; then
                state_padded="${C_EMERALD}${state_padded}${C_RESET}"
            else
                state_padded="${C_SLATE}${state_padded}${C_RESET}"
            fi
            
            local ip4
            ip4=$(ip -4 -o addr show "$iface" 2>/dev/null | awk '{print $4}' | head -n1)
            out "    $(printf "%-16s" "$iface") ${state_padded} $(printf "%-18s" "${mac:-N/A}") ${ip4:-No IPv4}"
        done < <(ip -br link 2>/dev/null || true)
        
        out ""
        local def_gw
        def_gw=$(ip route 2>/dev/null | grep "^default" | awk '{print $3" via dev "$5}')
        print_kv "Default Gateway" "${def_gw:-None}"
        
        local dns_list=""
        if [ -f /etc/resolv.conf ]; then
            dns_list=$(grep "^nameserver" /etc/resolv.conf | awk '{print $2}' | xargs)
        fi
        print_kv "DNS Resolvers" "${dns_list:-N/A}"
    fi
    
    out ""
    print_sub "${TXT[INTERNET_TEST]}"
    if has_cmd ping; then
        local ping_target="1.1.1.1"
        local ping_res
        ping_res=$(ping -c 2 -W 2 "$ping_target" 2>/dev/null || true)
        if echo "$ping_res" | grep -q "2 received"; then
            local rtt
            rtt=$(echo "$ping_res" | grep "rtt" | awk -F/ '{print $5}')
            out "    ${C_EMERALD}✔ [${TXT[PING_SUCCESS]}]${C_RESET} Cloudflare DNS (${ping_target}) Latency: ${C_WHITE}${rtt:-N/A} ms${C_RESET}"
        else
            out "    ${C_GOLD}▲ [${TXT[PING_FAIL]}]${C_RESET} Destination ${ping_target} unreachable or ICMP blocked."
            record_warn
        fi
    fi
}

# ==============================================================================
# SEÇÃO 07: USB & PERIFÉRICOS
# ==============================================================================
audit_usb() {
    print_section "${TXT[SECTION_USB]}"
    
    if has_cmd lsusb; then
        local usb_lines
        mapfile -t usb_lines < <(lsusb 2>/dev/null || true)
        print_kv "${TXT[USB_COUNT]}" "${#usb_lines[@]} devices present"
        
        out "  ${C_CYAN}▸ Connected Devices List:${C_RESET}"
        for line in "${usb_lines[@]}"; do
            local dev_id="${line#*ID }"
            out "    ${C_DARK}├─${C_RESET} ${C_EMERALD}⚡${C_RESET} ${dev_id}"
        done
    else
        out "    ${C_SLATE}lsusb tool not installed (package: usbutils)${C_RESET}"
    fi
}

# ==============================================================================
# SEÇÃO 08: SAÚDE DO SISTEMA & LOGS
# ==============================================================================
audit_health_logs() {
    print_section "${TXT[SECTION_HEALTH]}"
    
    # Failed systemd services
    if has_cmd systemctl; then
        print_sub "${TXT[FAILED_UNITS]}"
        local failed_units
        mapfile -t failed_units < <(systemctl --failed --no-legend 2>/dev/null || true)
        
        if [[ ${#failed_units[@]} -eq 0 ]]; then
            out "    ${C_EMERALD}✔ [0 FAILED UNITS] All system services running optimally.${C_RESET}"
        else
            for unit in "${failed_units[@]}"; do
                out "    ${C_CRIMSON}✖ ${unit}${C_RESET}"
                record_fail
            done
        fi
    fi
    
    # Kernel Errors (dmesg)
    out ""
    print_sub "${TXT[KERNEL_ERRS]}"
    if [[ $EUID -ne 0 ]]; then
        out "    ${C_SLATE}⊘ Kernel ring buffer requires root privileges (dmesg_restrict).${C_RESET}"
    elif [ "$QUICK_MODE" = true ]; then
        out "    ${C_SLATE}[Quick mode: skipping deep kernel log scan]${C_RESET}"
    elif has_cmd dmesg; then
        local k_errs
        mapfile -t k_errs < <(dmesg -T --level=err,crit,alert,emerg 2>/dev/null | tail -n 10 || true)
        if [[ ${#k_errs[@]} -eq 0 ]]; then
            out "    ${C_EMERALD}✔ No critical kernel errors in recent dmesg buffer.${C_RESET}"
        else
            for k_line in "${k_errs[@]}"; do
                out "    ${C_GOLD}▲ ${k_line}${C_RESET}"
                record_warn
            done
        fi
    fi
    
    # Journal Errors
    out ""
    print_sub "${TXT[JOURNAL_ERRS]}"
    if [ "$QUICK_MODE" = true ]; then
        out "    ${C_SLATE}[Quick mode: skipping journal query]${C_RESET}"
    elif has_cmd journalctl; then
        local j_errs
        mapfile -t j_errs < <(journalctl -p 3 -n 8 --no-pager 2>/dev/null | grep -v "^--" || true)
        if [[ ${#j_errs[@]} -eq 0 ]]; then
            out "    ${C_EMERALD}✔ No priority 3 (err) messages logged recently.${C_RESET}"
        else
            for j_line in "${j_errs[@]}"; do
                out "    ${C_SLATE}│${C_RESET} ${j_line}"
            done
        fi
    fi
}

# ==============================================================================
# SEÇÃO 09: RESUMO & HEALTH SCORE
# ==============================================================================
audit_summary() {
    print_section "${TXT[SECTION_SUMMARY]}"
    
    out ""
    if [[ $TOTAL_FAILURES -eq 0 && $TOTAL_WARNINGS -eq 0 ]]; then
        out "  ${C_EMERALD}${C_BOLD}╔══════════════════════════════════════════════════════════════════════╗${C_RESET}"
        out "  ${C_EMERALD}${C_BOLD}║  STATUS: ${TXT[SCORE_OPTIMAL]}${C_RESET}"
        out "  ${C_EMERALD}${C_BOLD}╚══════════════════════════════════════════════════════════════════════╝${C_RESET}"
    elif [[ $TOTAL_FAILURES -eq 0 ]]; then
        out "  ${C_GOLD}${C_BOLD}╔══════════════════════════════════════════════════════════════════════╗${C_RESET}"
        out "  ${C_GOLD}${C_BOLD}║  STATUS: ${TXT[SCORE_WARN]} (${TOTAL_WARNINGS} warnings)${C_RESET}"
        out "  ${C_GOLD}${C_BOLD}╚══════════════════════════════════════════════════════════════════════╝${C_RESET}"
    else
        out "  ${C_CRIMSON}${C_BOLD}╔══════════════════════════════════════════════════════════════════════╗${C_RESET}"
        out "  ${C_CRIMSON}${C_BOLD}║  STATUS: ${TXT[SCORE_CRIT]} (${TOTAL_FAILURES} errors, ${TOTAL_WARNINGS} warnings)${C_RESET}"
        out "  ${C_CRIMSON}${C_BOLD}╚══════════════════════════════════════════════════════════════════════╝${C_RESET}"
    fi
    out ""
    
    if [ "$ENABLE_LOG" = true ]; then
        out "  ${C_SLATE}${TXT[REPORT_GENERATED]}${C_RESET} ${C_CYAN}${C_BOLD}${LOG_FILE}${C_RESET}"
    fi
    
    if [[ $EUID -ne 0 ]]; then
        out "  ${C_DIM}${TXT[HELP_NOTE]}${C_RESET}"
    fi
    out ""
}

# ==============================================================================
# EXECUÇÃO PRINCIPAL
# ==============================================================================
main() {
    if [ "$CHECK_DEPS_ONLY" = true ] || [ "$INSTALL_DEPS_FLAG" = true ]; then
        check_or_install_deps "$INSTALL_DEPS_FLAG"
        exit 0
    fi

    print_banner
    audit_system
    audit_cpu
    audit_ram
    audit_gpu
    audit_storage
    audit_network
    audit_usb
    audit_health_logs
    audit_summary
}

main "$@"
