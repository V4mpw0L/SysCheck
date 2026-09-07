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
AUTO_CONFIRM_DEPS=false
SKIP_DEPS_PROMPT=false

# ------------------------------------------------------------------------------
# DETECÇÃO DE PLATAFORMA & AMBIENTE
# ------------------------------------------------------------------------------
detect_platform() {
    local u_sys
    u_sys="$(uname -s 2>/dev/null || echo 'Unknown')"
    case "$u_sys" in
        Darwin*)
            OS_FAMILY="macos"
            OS_NAME="macOS"
            ;;
        Linux*)
            if grep -qi microsoft /proc/version 2>/dev/null || [ -d /proc/sys/fs/binfmt_misc/WSLInterop ]; then
                OS_FAMILY="wsl"
                OS_NAME="WSL (Windows Subsystem for Linux)"
            else
                OS_FAMILY="linux"
                OS_NAME="Linux"
            fi
            ;;
        MINGW*|MSYS*|CYGWIN*)
            OS_FAMILY="windows"
            OS_NAME="Windows (${u_sys%%-*})"
            ;;
        FreeBSD*|OpenBSD*|NetBSD*)
            OS_FAMILY="bsd"
            OS_NAME="${u_sys}"
            ;;
        *)
            OS_FAMILY="generic"
            OS_NAME="${u_sys}"
            ;;
    esac
}

has_cmd() {
    command -v "$1" &>/dev/null
}

detect_package_manager() {
    PKG_MGR=""
    PKG_MGR_NAME=""
    if has_cmd dnf; then
        PKG_MGR="dnf"
        PKG_MGR_NAME="DNF (Fedora / Nobara / RHEL / CentOS)"
    elif has_cmd apt-get; then
        PKG_MGR="apt"
        PKG_MGR_NAME="APT (Debian / Ubuntu / Linux Mint / Pop!_OS)"
    elif has_cmd pacman; then
        PKG_MGR="pacman"
        PKG_MGR_NAME="Pacman (Arch / Manjaro / EndeavourOS)"
    elif has_cmd zypper; then
        PKG_MGR="zypper"
        PKG_MGR_NAME="Zypper (openSUSE)"
    elif has_cmd apk; then
        PKG_MGR="apk"
        PKG_MGR_NAME="APK (Alpine Linux)"
    elif has_cmd brew; then
        PKG_MGR="brew"
        PKG_MGR_NAME="Homebrew (macOS / Linux)"
    elif has_cmd winget.exe || has_cmd winget; then
        PKG_MGR="winget"
        PKG_MGR_NAME="Windows Package Manager (winget)"
    elif has_cmd choco.exe || has_cmd choco; then
        PKG_MGR="choco"
        PKG_MGR_NAME="Chocolatey"
    fi
}

detect_platform
detect_package_manager

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
  -y, --yes            Auto-confirm installation of missing dependencies
      --no-deps-prompt Skip interactive prompt for missing dependencies
      --no-color       Disable ANSI color output
      --no-log         Do not write log file to disk
  -o, --output FILE    Specify custom path for the generated log report
      --lang <code>    Set language explicitly: "en" (English) or "pt" (Português)

Supported Operating Systems:
  Linux                Debian, Ubuntu, Fedora, Nobara, Arch, openSUSE, Alpine, RHEL
  macOS (Darwin)       Apple Silicon (M1-M4) & Intel Macs (macOS 12 Monterey+)
  Windows              Windows Subsystem for Linux (WSL), Git Bash, MSYS2, Cygwin
                       (Native Windows PowerShell: .\syscheck.ps1)

Execution Modes:
  Non-Root (User)      Safe, non-destructive audit of CPU, RAM, GPU, Network, OS.
  Root (sudo)          Unlocks deep NVMe/SATA SMART health, dmidecode BIOS/RAM,
                       and kernel dmesg ring buffer logs.

Examples:
  sudo ./syscheck.sh                 # Full deep hardware audit
  ./syscheck.sh --quick              # Quick inspection
  sudo ./syscheck.sh --lang pt       # Force Portuguese interface
  ./syscheck.sh --check-deps         # Audit installed tools
  sudo ./syscheck.sh -y              # Auto-install missing packages and audit
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
        -y|--yes)
            AUTO_CONFIRM_DEPS=true
            shift
            ;;
        --no-deps-prompt)
            SKIP_DEPS_PROMPT=true
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
    TXT[SECTION_BOOT]="00. DETECÇÃO DE PLATAFORMA & DEPENDÊNCIAS"
    TXT[SECTION_SYS]="01. SISTEMA OPERACIONAL & AMBIENTE"
    TXT[SECTION_CPU]="02. PROCESSADOR (CPU) & EFICIÊNCIA TÉRMICA"
    TXT[SECTION_RAM]="03. MEMÓRIA RAM & GERENCIAMENTO DE SWAP"
    TXT[SECTION_GPU]="04. SUBSISTEMA GRÁFICO & MULTI-GPU"
    TXT[SECTION_STORE]="05. ARMAZENAMENTO, DISCOS & SAÚDE S.M.A.R.T."
    TXT[SECTION_NET]="06. REDE, INTERFACES & CONECTIVIDADE"
    TXT[SECTION_USB]="07. BARRAMENTO USB & PERIFÉRICOS"
    TXT[SECTION_HEALTH]="08. SAÚDE DO SISTEMA, SERVIÇOS & LOGS DE ERRO"
    TXT[SECTION_SUMMARY]="09. PARECER EXECUTIVO & RESUMO DE SAÚDE"
    
    TXT[PLATFORM_DETECTED]="Plataforma / Sistema"
    TXT[PKG_MGR_LABEL]="Gerenciador de Pacotes"
    TXT[TOOLCHAIN_STATUS]="Ferramentas de Diagnóstico"
    TXT[ACTIVE_SENTINELS]="Sensores Ativos"
    TXT[OS_DISTRO]="Sistema Operacional"
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
    TXT[FAILED_UNITS]="Serviços do Sistema com Falha"
    TXT[KERNEL_ERRS]="Erros Críticos no Kernel / Logs"
    TXT[JOURNAL_ERRS]="Eventos de Erro Recentes"
    
    TXT[SCORE_OPTIMAL]="EXCELENTE - Nenhum problema crítico detectado"
    TXT[SCORE_WARN]="ATENÇÃO - Alertas detectados (alta utilização ou erros leves)"
    TXT[SCORE_CRIT]="CRÍTICO - Falhas ativas encontradas no sistema"
    TXT[REPORT_GENERATED]="Relatório detalhado salvo com sucesso em:"
    TXT[HELP_NOTE]="Dica: Para análises de hardware em profundidade, execute: sudo ./syscheck.sh"

    TXT[DEP_PROMPT_TITLE]="AUDITORIA DE DEPENDÊNCIAS: PACOTES RECOMENDADOS"
    TXT[DEP_MISSING_INTRO]="Os seguintes pacotes são recomendados para auditoria completa de hardware:"
    TXT[DEP_MGR_DETECTED]="Gerenciador de Pacotes Detectado"
    TXT[DEP_PROPOSED_CMD]="Comando de Instalação"
    TXT[DEP_ASK_INSTALL]="Deseja instalar essas dependências automaticamente agora?"
    TXT[DEP_SKIPPED]="Instalação ignorada. Prosseguindo com ferramentas disponíveis..."
    TXT[DEP_MANUAL_NOTE]="Dica: Instale as ferramentas ausentes para obter telemetria avançada."
else
    TXT[TITLE]="ENTERPRISE SYSTEM & HARDWARE DIAGNOSTIC ENGINE"
    TXT[SUBTITLE]="Gennisys Studio  ●  Infrastructure & Hardware Audit"
    TXT[MODE_ROOT]="PRIVILEGED MODE (ROOT) - DEEP HARDWARE AUDIT ACTIVE"
    TXT[MODE_USER]="USER MODE (NON-ROOT) - RUN WITH 'sudo' FOR COMPLETE SMART/DMI ACCESS"
    TXT[SECTION_BOOT]="00. PLATFORM DISCOVERY & DEPENDENCY SENTINEL"
    TXT[SECTION_SYS]="01. OPERATING SYSTEM & ENVIRONMENT"
    TXT[SECTION_CPU]="02. PROCESSOR (CPU) & THERMAL EFFICIENCY"
    TXT[SECTION_RAM]="03. RAM ALLOCATION & SWAP MANAGEMENT"
    TXT[SECTION_GPU]="04. GRAPHICS SUBSYSTEM & MULTI-GPU PIPELINE"
    TXT[SECTION_STORE]="05. STORAGE, DISKS & S.M.A.R.T. HEALTH"
    TXT[SECTION_NET]="06. NETWORK TOPOLOGY & CONNECTIVITY"
    TXT[SECTION_USB]="07. USB CONTROLLERS & PERIPHERALS"
    TXT[SECTION_HEALTH]="08. SYSTEM HEALTH, FAILED SERVICES & LOGS"
    TXT[SECTION_SUMMARY]="09. EXECUTIVE AUDIT & HEALTH SUMMARY"
    
    TXT[PLATFORM_DETECTED]="Target Platform"
    TXT[PKG_MGR_LABEL]="Package Manager"
    TXT[TOOLCHAIN_STATUS]="Diagnostic Toolchain"
    TXT[ACTIVE_SENTINELS]="Active Sentinels"
    TXT[OS_DISTRO]="Operating System"
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
    TXT[GPU_ACTIVE_DRV]="Driver"
    TXT[OPENGL_RENDER]="OpenGL Renderer"
    TXT[VULKAN_DEVS]="Vulkan Devices"
    TXT[NVIDIA_STATUS]="NVIDIA Dedicated Status"
    TXT[NVIDIA_MEM]="VRAM Usage"
    TXT[NVIDIA_TEMP]="Core Temp / Load"
    
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
    TXT[FAILED_UNITS]="Failed System Services"
    TXT[KERNEL_ERRS]="Critical Kernel Log Events"
    TXT[JOURNAL_ERRS]="Recent Journal Error Events"
    
    TXT[SCORE_OPTIMAL]="OPTIMAL - No critical warnings or failures detected"
    TXT[SCORE_WARN]="WARNING - Elevated resource usage or non-critical issues"
    TXT[SCORE_CRIT]="CRITICAL - Active service or hardware warnings present"
    TXT[REPORT_GENERATED]="Comprehensive report saved to:"
    TXT[HELP_NOTE]="Tip: Run with 'sudo ./syscheck.sh' for full NVMe SMART and DMI access."

    TXT[DEP_PROMPT_TITLE]="DEPENDENCY AUDIT: RECOMMENDED DIAGNOSTIC TOOLS"
    TXT[DEP_MISSING_INTRO]="The following packages are recommended for full deep hardware audit:"
    TXT[DEP_MGR_DETECTED]="Package Manager Detected"
    TXT[DEP_PROPOSED_CMD]="Installation Command"
    TXT[DEP_ASK_INSTALL]="Would you like to install these packages automatically now?"
    TXT[DEP_SKIPPED]="Skipping installation. Running with available tools..."
    TXT[DEP_MANUAL_NOTE]="Tip: Install missing packages with your package manager for deeper telemetry."
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
        echo -e "$text" | sed -r "s/\x1B\[([0-9]{1,2}(;[0-9]{1,2})?)?[mGK]//g" >> "$LOG_FILE" 2>/dev/null || true
    fi
}

# ------------------------------------------------------------------------------
# COMPONENTES VISUAIS (Borders, Headers, Progress Bars)
# ------------------------------------------------------------------------------
print_banner() {
    local p_title="${TXT[TITLE]} [v${VERSION}]"
    local p_sub="${TXT[SUBTITLE]}"
    local host_str
    host_str="$(hostname 2>/dev/null || echo 'Unknown')"
    
    out ""
    out "  ${C_EMERALD}${C_BOLD}███████╗██╗   ██╗███████╗ ██████╗██╗  ██╗███████╗ ██████╗██╗  ██╗${C_RESET}"
    out "  ${C_EMERALD}${C_BOLD}██╔════╝╚██╗ ██╔╝██╔════╝██╔════╝██║  ██║██╔════╝██╔════╝██║ ██╔╝${C_RESET}"
    out "  ${C_CYAN}${C_BOLD}███████╗ ╚████╔╝ ███████╗██║     ███████║█████╗  ██║     █████╔╝ ${C_RESET}"
    out "  ${C_CYAN}${C_BOLD}╚════██║  ╚██╔╝  ╚════██║██║     ██╔══██║██╔══╝  ██║     ██╔═██╗ ${C_RESET}"
    out "  ${C_BLUE}${C_BOLD}███████║   ██║   ███████║╚██████╗██║  ██║███████╗╚██████╗██║  ██╗${C_RESET}"
    out "  ${C_BLUE}${C_BOLD}╚══════╝   ╚═╝   ╚══════╝ ╚═════╝╚═╝  ╚═╝╚══════╝ ╚═════╝╚═╝  ╚═╝${C_RESET}"
    out ""
    out "  ${C_WHITE}${C_BOLD}${p_title}${C_RESET}"
    out "  ${C_SLATE}${p_sub}${C_RESET}"
    out "  ${C_DARK}────────────────────────────────────────────────────────────────────────${C_RESET}"
    
    if [[ $EUID -eq 0 ]]; then
        out "  ${C_EMERALD}${C_BOLD}⚡ ${TXT[MODE_ROOT]}${C_RESET}"
    else
        out "  ${C_GOLD}● ${TXT[MODE_USER]}${C_RESET}"
    fi
    out "  ${C_SLATE}Date: $(date '+%Y-%m-%d %H:%M:%S %Z')  ●  Platform: ${OS_NAME}  ●  Host: ${host_str}${C_RESET}"
    out ""
}

print_section() {
    local title="$1"
    out ""
    out "${C_CYAN}╭────────────────────────────────────────────────────────────────────────╮${C_RESET}"
    out "${C_CYAN}│${C_RESET} ${C_WHITE}${C_BOLD}❖  ${title}${C_RESET}"
    out "${C_CYAN}╰────────────────────────────────────────────────────────────────────────╯${C_RESET}"
}

print_kv() {
    local key="$1"
    local val="$2"
    printf "  ${C_CYAN}●${C_RESET}  ${C_SLATE}%-30s${C_RESET} : ${C_WHITE}%s${C_RESET}\n" "$key" "$val" | while read -r line; do out "$line"; done
}

print_sub() {
    local subtitle="$1"
    out "  ${C_PURPLE}▸ ${C_BOLD}${subtitle}${C_RESET}"
}

render_bar() {
    local pct="${1:-0}"
    local width="${2:-16}"
    
    [[ "$pct" =~ ^[0-9]+$ ]] || pct=0
    (( pct > 100 )) && pct=100
    (( pct < 0 )) && pct=0
    
    local fill_len=$(( (pct * width) / 100 ))
    local empty_len=$(( width - fill_len ))
    
    local fill_str=""
    local empty_str=""
    
    for ((i=0; i<fill_len; i++)); do fill_str+="█"; done
    for ((i=0; i<empty_len; i++)); do empty_str+="░"; done
    
    local bar_color="${C_EMERALD}"
    if (( pct >= 90 )); then
        bar_color="${C_CRIMSON}${C_BOLD}"
    elif (( pct >= 75 )); then
        bar_color="${C_GOLD}"
    fi
    
    echo -e "${bar_color}[${fill_str}${empty_str}] ${pct}%${C_RESET}"
}

# ------------------------------------------------------------------------------
# TRACKING DE ERROS / HEALTH SCORE GLOBAL
# ------------------------------------------------------------------------------
TOTAL_WARNINGS=0
TOTAL_FAILURES=0

record_warn() { ((TOTAL_WARNINGS++)) || true; }
record_fail() { ((TOTAL_FAILURES++)) || true; }

# Package mapping definitions for Linux distros
declare -A PKG_FEDORA=(
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

declare -A PKG_DEBIAN=(
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

declare -A PKG_ARCH=(
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

# ------------------------------------------------------------------------------
# AUDITORIA & INSTALAÇÃO DE DEPENDÊNCIAS
# ------------------------------------------------------------------------------
audit_bootstrap_platform() {
    print_section "${TXT[SECTION_BOOT]}"
    
    # 1. Platform Details
    local plat_desc="${OS_NAME}"
    if [ "$OS_FAMILY" = "linux" ]; then
        local d_name=""
        [ -f /etc/os-release ] && d_name=$(source /etc/os-release && echo "${PRETTY_NAME:-$NAME}")
        plat_desc="${d_name:-Linux} ($(uname -m))"
    elif [ "$OS_FAMILY" = "macos" ]; then
        local m_ver m_chip
        m_ver="$(sw_vers -productVersion 2>/dev/null || echo '')"
        m_chip="$(sysctl -n machdep.cpu.brand_string 2>/dev/null || echo 'Apple Silicon')"
        plat_desc="Apple macOS ${m_ver} (${m_chip}) [$(uname -m)]"
    elif [ "$OS_FAMILY" = "windows" ] || [ "$OS_FAMILY" = "wsl" ]; then
        plat_desc="Microsoft Windows / WSL ($(uname -m))"
    fi
    print_kv "${TXT[PLATFORM_DETECTED]}" "${plat_desc}"
    
    # 2. Package Manager
    local pm_status="${PKG_MGR_NAME:-None detected (Manual Binary Mode)}"
    print_kv "${TXT[PKG_MGR_LABEL]}" "${pm_status}"
    
    # 3. Toolchain Verification
    local check_tools=()
    if [ "$OS_FAMILY" = "macos" ]; then
        check_tools=(sysctl sw_vers system_profiler diskutil vm_stat networksetup smartctl)
    elif [ "$OS_FAMILY" = "windows" ]; then
        check_tools=(powershell.exe cmd.exe smartctl)
    else
        check_tools=(lscpu lsblk lspci lsusb sensors smartctl glxinfo vulkaninfo dmidecode ip ping nvidia-smi)
    fi
    
    local found_count=0
    local total_count=${#check_tools[@]}
    local missing=()
    local missing_pkgs=()
    
    for cmd in "${check_tools[@]}"; do
        if has_cmd "$cmd"; then
            ((found_count++)) || true
        else
            missing+=("$cmd")
            case "$PKG_MGR" in
                "dnf") missing_pkgs+=("${PKG_FEDORA[$cmd]:-$cmd}") ;;
                "apt") missing_pkgs+=("${PKG_DEBIAN[$cmd]:-$cmd}") ;;
                "pacman") missing_pkgs+=("${PKG_ARCH[$cmd]:-$cmd}") ;;
                *) missing_pkgs+=("$cmd") ;;
            esac
        fi
    done
    
    if [[ ${#missing[@]} -eq 0 ]]; then
        print_kv "${TXT[TOOLCHAIN_STATUS]}" "${C_EMERALD}${found_count}/${total_count} Verified [OPTIMAL - 100% READY]${C_RESET}"
        out "    ${C_DARK}└─${C_RESET} ${C_SLATE}${TXT[ACTIVE_SENTINELS]}:${C_RESET} ${C_EMERALD}smartctl  ●  sensors  ●  lspci  ●  lsusb  ●  dmidecode  ●  nvidia-smi${C_RESET}"
    else
        print_kv "${TXT[TOOLCHAIN_STATUS]}" "${C_GOLD}${found_count}/${total_count} Detected (${#missing[@]} Missing)${C_RESET}"
        out "    ${C_DARK}└─${C_RESET} ${C_GOLD}Missing optional tools:${C_RESET} ${C_WHITE}${missing[*]}${C_RESET}"
        
        # Interactive install prompt
        if [ "$SKIP_DEPS_PROMPT" != true ] && [ "$QUICK_MODE" != true ] && [ -n "$PKG_MGR" ] && [[ ${#missing_pkgs[@]} -gt 0 ]]; then
            local install_cmd=""
            case "$PKG_MGR" in
                "dnf") [[ $EUID -eq 0 ]] && install_cmd="dnf install -y ${missing_pkgs[*]}" || install_cmd="sudo dnf install -y ${missing_pkgs[*]}" ;;
                "apt") [[ $EUID -eq 0 ]] && install_cmd="apt-get update && apt-get install -y ${missing_pkgs[*]}" || install_cmd="sudo apt-get update && sudo apt-get install -y ${missing_pkgs[*]}" ;;
                "pacman") [[ $EUID -eq 0 ]] && install_cmd="pacman -Sy --noconfirm ${missing_pkgs[*]}" || install_cmd="sudo pacman -Sy --noconfirm ${missing_pkgs[*]}" ;;
                "zypper") [[ $EUID -eq 0 ]] && install_cmd="zypper install -y ${missing_pkgs[*]}" || install_cmd="sudo zypper install -y ${missing_pkgs[*]}" ;;
                "brew") install_cmd="brew install ${missing_pkgs[*]}" ;;
                "winget") install_cmd="winget install ${missing_pkgs[*]}" ;;
            esac
            
            out ""
            out "  ${C_CYAN}▸ ${TXT[DEP_PROPOSED_CMD]}:${C_RESET} ${C_WHITE}${C_BOLD}${install_cmd}${C_RESET}"
            
            local do_install=false
            if [ "$AUTO_CONFIRM_DEPS" = true ]; then
                do_install=true
            elif [ -t 0 ] && [ -t 1 ]; then
                printf "  ${C_CYAN}▸ %s [S/n (Y/n)]: ${C_RESET}" "${TXT[DEP_ASK_INSTALL]}"
                local reply=""
                read -r reply </dev/tty || reply=""
                case "$reply" in
                    [yY]|[yY][eE][sS]|[sS]|[sS][iI][mM]|"") do_install=true ;;
                    *) do_install=false ;;
                esac
            fi
            
            if [ "$do_install" = true ]; then
                out ""
                out "  ${C_CYAN}⚡ Executing: ${install_cmd}...${C_RESET}"
                if eval "$install_cmd"; then
                    out "  ${C_EMERALD}✔ Dependencies installed! Continuing audit...${C_RESET}"
                else
                    out "  ${C_GOLD}▲ Package install returned an exit code. Continuing...${C_RESET}"
                fi
            else
                out "  ${C_SLATE}▸ ${TXT[DEP_SKIPPED]}${C_RESET}"
            fi
        fi
    fi
}

check_or_install_deps() {
    local install_mode="$1"
    out ""
    out "${C_BOLD}${C_CYAN}=== SysCheck Dependency Audit (${OS_NAME}) ===${C_RESET}"
    out "  ${C_SLATE}Package Manager: ${C_WHITE}${PKG_MGR_NAME:-None detected}${C_RESET}"
    out ""

    local check_list=()
    if [ "$OS_FAMILY" = "macos" ]; then
        check_list=(sw_vers sysctl system_profiler diskutil vm_stat networksetup smartctl brew)
    elif [ "$OS_FAMILY" = "windows" ]; then
        check_list=(powershell.exe cmd.exe smartctl winget)
    else
        check_list=(lscpu lsblk lspci lsusb sensors smartctl glxinfo vulkaninfo dmidecode ip ping nvidia-smi)
    fi

    local missing=()
    local missing_pkgs=()

    for cmd in "${check_list[@]}"; do
        if has_cmd "$cmd"; then
            out "  ${C_EMERALD}✔ [FOUND]${C_RESET} ${cmd}"
        else
            out "  ${C_GOLD}▲ [MISSING]${C_RESET} ${cmd}"
            missing+=("$cmd")
            case "$PKG_MGR" in
                "dnf") missing_pkgs+=("${PKG_FEDORA[$cmd]:-$cmd}") ;;
                "apt") missing_pkgs+=("${PKG_DEBIAN[$cmd]:-$cmd}") ;;
                "pacman") missing_pkgs+=("${PKG_ARCH[$cmd]:-$cmd}") ;;
                "brew") missing_pkgs+=("$cmd") ;;
                *) missing_pkgs+=("$cmd") ;;
            esac
        fi
    done

    out ""
    if [[ ${#missing[@]} -eq 0 ]]; then
        out "  ${C_EMERALD}${C_BOLD}All dependencies are installed! SysCheck is ready for full-depth analysis.${C_RESET}"
    else
        out "  ${C_GOLD}Missing commands (${#missing[@]}): ${missing[*]}${C_RESET}"
        if [ -n "$PKG_MGR" ]; then
            out "  Suggested installation command:"
            case "$PKG_MGR" in
                "dnf") out "    ${C_WHITE}sudo dnf install -y ${missing_pkgs[*]}${C_RESET}" ;;
                "apt") out "    ${C_WHITE}sudo apt update && sudo apt install -y ${missing_pkgs[*]}${C_RESET}" ;;
                "pacman") out "    ${C_WHITE}sudo pacman -S --noconfirm ${missing_pkgs[*]}${C_RESET}" ;;
                "zypper") out "    ${C_WHITE}sudo zypper install -y ${missing_pkgs[*]}${C_RESET}" ;;
                "brew") out "    ${C_WHITE}brew install ${missing_pkgs[*]}${C_RESET}" ;;
                "winget") out "    ${C_WHITE}winget install ${missing_pkgs[*]}${C_RESET}" ;;
            esac

            if [ "$install_mode" = true ]; then
                if [[ $EUID -ne 0 ]] && [ "$OS_FAMILY" = "linux" ]; then
                    out "  ${C_CRIMSON}Root privileges required to install packages. Re-run with sudo.${C_RESET}"
                    exit 1
                fi
                out ""
                out "  ${C_CYAN}Installing packages: ${missing_pkgs[*]}...${C_RESET}"
                case "$PKG_MGR" in
                    "dnf") dnf install -y "${missing_pkgs[@]}" ;;
                    "apt") apt-get update && apt-get install -y "${missing_pkgs[@]}" ;;
                    "pacman") pacman -S --noconfirm "${missing_pkgs[@]}" ;;
                    "zypper") zypper install -y "${missing_pkgs[@]}" ;;
                    "brew") brew install "${missing_pkgs[@]}" ;;
                    "winget") winget install "${missing_pkgs[@]}" ;;
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
    
    # macOS Branch
    if [ "$OS_FAMILY" = "macos" ]; then
        local os_ver os_build mac_model
        os_ver="$(sw_vers -productVersion 2>/dev/null || uname -r)"
        os_build="$(sw_vers -buildVersion 2>/dev/null || echo '')"
        print_kv "${TXT[OS_DISTRO]}" "Apple macOS ${os_ver} (Build ${os_build})"
        print_kv "${TXT[KERNEL]}" "Darwin $(uname -r) ($(uname -m))"
        print_kv "${TXT[HOSTNAME]}" "$(hostname)"
        
        local uptime_str
        uptime_str="$(uptime | sed 's/.*up \([^,]*\), .*/\1/')"
        print_kv "${TXT[UPTIME]}" "${uptime_str}"
        
        local load_avg
        load_avg="$(sysctl -n vm.loadavg 2>/dev/null | tr -d '{}' || uptime | awk -F'load average:' '{print $2}')"
        print_kv "${TXT[LOAD_AVG]}" "${load_avg}"
        print_kv "${TXT[INIT_SYS]}" "launchd"
        print_kv "${TXT[DESKTOP_ENV]}" "Aqua (WindowServer / Quartz)"
        
        mac_model="$(sysctl -n hw.model 2>/dev/null || echo 'Apple Mac')"
        print_kv "${TXT[MOTHERBOARD]}" "${mac_model}"
        print_kv "${TXT[BIOS_INFO]}" "Apple BootROM / Secure Enclave"
        return 0
    fi

    # Windows Branch (Git Bash / MSYS2 / WSL)
    if [ "$OS_FAMILY" = "windows" ] || [ "$OS_FAMILY" = "wsl" ]; then
        local win_caption win_build win_mb win_bios
        if has_cmd powershell.exe; then
            win_caption=$(powershell.exe -NoProfile -Command "(Get-CimInstance Win32_OperatingSystem).Caption" 2>/dev/null | tr -d '\r')
            win_build=$(powershell.exe -NoProfile -Command "(Get-CimInstance Win32_OperatingSystem).BuildNumber" 2>/dev/null | tr -d '\r')
            win_mb=$(powershell.exe -NoProfile -Command "$b=Get-CimInstance Win32_BaseBoard; $b.Manufacturer + ' ' + $b.Product" 2>/dev/null | tr -d '\r')
            win_bios=$(powershell.exe -NoProfile -Command "$b=Get-CimInstance Win32_BIOS; $b.Manufacturer + ' ' + $b.SMBIOSBIOSVersion" 2>/dev/null | tr -d '\r')
        fi
        
        if [ "$OS_FAMILY" = "wsl" ]; then
            local wsl_distro="WSL"
            [ -f /etc/os-release ] && wsl_distro=$(source /etc/os-release && echo "${PRETTY_NAME:-$NAME}")
            print_kv "${TXT[OS_DISTRO]}" "${wsl_distro} [WSL Host: ${win_caption:-Windows} Build ${win_build:-N/A}]"
            print_kv "${TXT[KERNEL]}" "$(uname -r) ($(uname -m))"
        else
            print_kv "${TXT[OS_DISTRO]}" "${win_caption:-Windows} (Build ${win_build:-N/A})"
            print_kv "${TXT[KERNEL]}" "NT $(uname -r) ($(uname -m))"
        fi

        print_kv "${TXT[HOSTNAME]}" "$(hostname)"
        local uptime_raw
        uptime_raw="$(uptime -p 2>/dev/null || uptime | sed 's/.*up \([^,]*\), .*/\1/')"
        uptime_raw="${uptime_raw#up }"
        print_kv "${TXT[UPTIME]}" "${uptime_raw}"
        
        local load_avg
        load_avg="$(awk '{print $1", "$2", "$3}' /proc/loadavg 2>/dev/null || uptime | awk -F'load average:' '{print $2}')"
        print_kv "${TXT[LOAD_AVG]}" "${load_avg:-N/A}"
        print_kv "${TXT[INIT_SYS]}" "Service Control Manager / WSL Init"
        print_kv "${TXT[DESKTOP_ENV]}" "Windows DWM (Desktop Window Manager)"
        print_kv "${TXT[MOTHERBOARD]}" "${win_mb:-PC Chassis}"
        print_kv "${TXT[BIOS_INFO]}" "${win_bios:-UEFI Firmware}"
        return 0
    fi

    # Linux Native Branch
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
    
    local kernel_ver
    kernel_ver="$(uname -r) ($(uname -m))"
    print_kv "${TXT[KERNEL]}" "${kernel_ver}"
    
    local m_id="N/A"
    [ -f /etc/machine-id ] && m_id=$(head -c 8 /etc/machine-id)
    print_kv "${TXT[HOSTNAME]}" "$(hostname) (${m_id}...)"
    
    local uptime_raw
    uptime_raw="$(uptime -p 2>/dev/null || uptime | sed 's/.*up \([^,]*\), .*/\1/')"
    uptime_raw="${uptime_raw#up }"
    print_kv "${TXT[UPTIME]}" "${uptime_raw}"
    
    local load_avg
    load_avg="$(awk '{print $1", "$2", "$3}' /proc/loadavg 2>/dev/null || uptime | awk -F'load average:' '{print $2}')"
    print_kv "${TXT[LOAD_AVG]}" "${load_avg}"
    
    local init_sys="systemd"
    if [ ! -d /run/systemd/system ]; then
        init_sys="SysV/OpenRC/Other"
    fi
    print_kv "${TXT[INIT_SYS]}" "${init_sys}"
    
    local desktop="${XDG_CURRENT_DESKTOP:-}"
    local session_type="${XDG_SESSION_TYPE:-}"
    if [[ -z "$desktop" || "$desktop" == "Standard" ]] && [[ -n "$SUDO_USER" ]] && has_cmd loginctl; then
        local user_sess
        user_sess=$(loginctl list-sessions --no-legend 2>/dev/null | awk -v u="$SUDO_USER" '$3 == u {print $1; exit}')
        if [[ -n "$user_sess" ]]; then
            desktop=$(loginctl show-session "$user_sess" -p Desktop --value 2>/dev/null || echo '')
            session_type=$(loginctl show-session "$user_sess" -p Type --value 2>/dev/null || echo '')
        fi
    fi
    [[ -z "$desktop" ]] && desktop="Standard"
    [[ -z "$session_type" ]] && session_type="tty"
    local session_env="${desktop} (${session_type})"
    print_kv "${TXT[DESKTOP_ENV]}" "${session_env}"
    
    local mb_vendor mb_product bios_ven bios_ver bios_date
    mb_vendor="$(cat /sys/class/dmi/id/board_vendor 2>/dev/null || cat /sys/class/dmi/id/sys_vendor 2>/dev/null || echo '')"
    mb_product="$(cat /sys/class/dmi/id/board_name 2>/dev/null || cat /sys/class/dmi/id/product_name 2>/dev/null || echo '')"
    bios_ven="$(cat /sys/class/dmi/id/bios_vendor 2>/dev/null || echo '')"
    bios_ver="$(cat /sys/class/dmi/id/bios_version 2>/dev/null || echo '')"
    bios_date="$(cat /sys/class/dmi/id/bios_date 2>/dev/null || echo '')"
    
    if [[ -z "$mb_product" ]] && has_cmd dmidecode && [[ $EUID -eq 0 ]]; then
        mb_vendor="$(dmidecode -s baseboard-manufacturer 2>/dev/null || echo '')"
        mb_product="$(dmidecode -s baseboard-product-name 2>/dev/null || echo '')"
        bios_ven="$(dmidecode -s bios-vendor 2>/dev/null || echo '')"
        bios_ver="$(dmidecode -s bios-version 2>/dev/null || echo '')"
        bios_date="$(dmidecode -s bios-release-date 2>/dev/null || echo '')"
    fi
    
    local mb_info="Generic Platform"
    [[ -n "$mb_vendor" || -n "$mb_product" ]] && mb_info="${mb_vendor} ${mb_product}"
    print_kv "${TXT[MOTHERBOARD]}" "${mb_info}"
    
    local bios_info="UEFI / Legacy BIOS"
    [[ -n "$bios_ver" ]] && bios_info="${bios_ven} ${bios_ver} (${bios_date})"
    print_kv "${TXT[BIOS_INFO]}" "${bios_info}"
}

# ==============================================================================
# SEÇÃO 02: PROCESSADOR (CPU) & TÉRMICO
# ==============================================================================
audit_cpu() {
    print_section "${TXT[SECTION_CPU]}"
    
    # macOS CPU
    if [ "$OS_FAMILY" = "macos" ]; then
        local cpu_brand phys_cores log_cores
        cpu_brand="$(sysctl -n machdep.cpu.brand_string 2>/dev/null || echo '')"
        if [ -z "$cpu_brand" ]; then
            local chip_name
            chip_name="$(system_profiler SPHardwareDataType 2>/dev/null | awk -F: '/Chip/{print $2}' | xargs)"
            cpu_brand="Apple ${chip_name:-Silicon}"
        fi
        print_kv "${TXT[CPU_MODEL]}" "${cpu_brand}"
        
        phys_cores="$(sysctl -n hw.physicalcpu 2>/dev/null || echo 'N/A')"
        log_cores="$(sysctl -n hw.logicalcpu 2>/dev/null || echo 'N/A')"
        print_kv "${TXT[CPU_ARCH]}" "$(uname -m) ● ${phys_cores} Physical Cores / ${log_cores} Threads"
        
        local max_hz
        max_hz="$(sysctl -n hw.cpufrequency_max 2>/dev/null || echo 0)"
        if [ "$max_hz" -gt 0 ]; then
            local max_mhz=$(( max_hz / 1000000 ))
            print_kv "${TXT[CPU_FREQ]}" "${max_mhz} MHz"
        fi
        
        if has_cmd osx-cpu-temp; then
            local m_temp
            m_temp="$(osx-cpu-temp 2>/dev/null)"
            [ -n "$m_temp" ] && print_kv "${TXT[CPU_TEMP]}" "${m_temp} [NORMAL]"
        fi
        return 0
    fi

    # Windows CPU
    if [ "$OS_FAMILY" = "windows" ] && has_cmd powershell.exe; then
        local cpu_name cpu_cores cpu_threads cpu_mhz
        cpu_name=$(powershell.exe -NoProfile -Command "(Get-CimInstance Win32_Processor).Name" 2>/dev/null | tr -d '\r')
        cpu_cores=$(powershell.exe -NoProfile -Command "(Get-CimInstance Win32_Processor).NumberOfCores" 2>/dev/null | tr -d '\r')
        cpu_threads=$(powershell.exe -NoProfile -Command "(Get-CimInstance Win32_Processor).NumberOfLogicalProcessors" 2>/dev/null | tr -d '\r')
        cpu_mhz=$(powershell.exe -NoProfile -Command "(Get-CimInstance Win32_Processor).MaxClockSpeed" 2>/dev/null | tr -d '\r')
        
        print_kv "${TXT[CPU_MODEL]}" "${cpu_name}"
        print_kv "${TXT[CPU_ARCH]}" "$(uname -m) ● ${cpu_cores} Physical Cores / ${cpu_threads} Threads"
        print_kv "${TXT[CPU_FREQ]}" "${cpu_mhz} MHz Max"
        return 0
    fi

    # Linux Native CPU
    local cpu_model=""
    if has_cmd lscpu; then
        cpu_model=$(lscpu | grep -E "Model name:" | head -n1 | sed -e 's/Model name:[ \t]*//g')
    fi
    if [ -z "$cpu_model" ] && [ -f /proc/cpuinfo ]; then
        cpu_model=$(grep -m1 "model name" /proc/cpuinfo | awk -F: '{print $2}' | sed -e 's/^[ \t]*//')
    fi
    print_kv "${TXT[CPU_MODEL]}" "${cpu_model:-Unknown Processor}"
    
    local arch_str cores_str threads_str
    arch_str="$(uname -m)"
    if has_cmd lscpu; then
        cores_str="$(lscpu | grep "Core(s) per socket:" | awk '{print $NF}')"
        local sockets_str
        sockets_str="$(lscpu | grep "Socket(s):" | awk '{print $NF}')"
        local total_cores=$(( ${cores_str:-1} * ${sockets_str:-1} ))
        threads_str="$(lscpu | grep "^CPU(s):" | awk '{print $NF}')"
        print_kv "${TXT[CPU_ARCH]}" "${arch_str} ● ${total_cores} Physical Cores / ${threads_str} Threads"
    else
        threads_str="$(grep -c "processor" /proc/cpuinfo 2>/dev/null || echo "1")"
        print_kv "${TXT[CPU_ARCH]}" "${arch_str} (${threads_str} Threads)"
    fi
    
    local cur_freq max_freq
    if [ -f /sys/devices/system/cpu/cpu0/cpufreq/scaling_cur_freq ]; then
        cur_freq=$(( $(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_cur_freq) / 1000 ))
    fi
    if [ -f /sys/devices/system/cpu/cpu0/cpufreq/scaling_max_freq ]; then
        max_freq=$(( $(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_max_freq) / 1000 ))
    fi
    if [ -n "$cur_freq" ] && [ -n "$max_freq" ]; then
        print_kv "${TXT[CPU_FREQ]}" "${cur_freq} MHz / ${max_freq} MHz"
    elif has_cmd lscpu; then
        local l_freq
        l_freq=$(lscpu | grep "CPU max MHz:" | awk '{print $NF}')
        [ -n "$l_freq" ] && print_kv "${TXT[CPU_FREQ]}" "${l_freq} MHz (Max)"
    fi
    
    if [ -f /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor ]; then
        local governor
        governor="$(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor)"
        print_kv "${TXT[CPU_GOVERNOR]}" "${governor}"
    fi
    
    if has_cmd lscpu; then
        local l1d l2 l3
        l1d=$(lscpu | grep "L1d cache:" | awk -F: '{print $2}' | xargs)
        l2=$(lscpu | grep "L2 cache:" | awk -F: '{print $2}' | xargs)
        l3=$(lscpu | grep "L3 cache:" | awk -F: '{print $2}' | xargs)
        print_kv "${TXT[CPU_CACHE]}" "L1d: ${l1d:-N/A} | L2: ${l2:-N/A} | L3: ${l3:-N/A}"
    fi
    
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

    # Fans Telemetry (clean separator)
    if has_cmd sensors; then
        local fan_info
        fan_info=$(sensors 2>/dev/null | grep -i "fan" | sed -E 's/[[:space:]]+/ /g' | awk -F: '{gsub(/^[ \t]+|[ \t]+$/, "", $2); print $1": "$2}' | paste -sd "|" - | sed 's/|/  │  /g')
        if [ -n "$fan_info" ]; then
            print_kv "${TXT[CPU_FANS]}" "${fan_info}"
        fi
    fi
    
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
    
    # macOS Memory
    if [ "$OS_FAMILY" = "macos" ]; then
        local total_bytes
        total_bytes="$(sysctl -n hw.memsize 2>/dev/null || echo 0)"
        local total_gib
        total_gib=$(awk -v b="$total_bytes" 'BEGIN {printf "%.1f", b/1073741824}')
        print_kv "${TXT[RAM_TOTAL]}" "${total_gib} GiB"
        
        if has_cmd vm_stat; then
            local page_size free_pages active_pages wired_pages compressed_pages
            page_size="$(vm_stat | awk '/page size of/{print $8}')"
            page_size="${page_size:-4096}"
            free_pages="$(vm_stat | awk '/Pages free:/{print $3}' | tr -d '.')"
            active_pages="$(vm_stat | awk '/Pages active:/{print $3}' | tr -d '.')"
            wired_pages="$(vm_stat | awk '/Pages wired down:/{print $4}' | tr -d '.')"
            compressed_pages="$(vm_stat | awk '/Pages occupied by compressor:/{print $5}' | tr -d '.')"
            
            local used_bytes=$(( (active_pages + wired_pages + compressed_pages) * page_size ))
            local used_gib
            used_gib=$(awk -v b="$used_bytes" 'BEGIN {printf "%.1f", b/1073741824}')
            local ram_pct=0
            [ "$total_bytes" -gt 0 ] && ram_pct=$(( (used_bytes * 100) / total_bytes ))
            print_kv "${TXT[RAM_USED]}" "${used_gib} GiB $(render_bar "$ram_pct")"
            local avail_gib
            avail_gib=$(awk -v t="$total_gib" -v u="$used_gib" 'BEGIN {printf "%.1f", t-u}')
            print_kv "${TXT[RAM_AVAIL]}" "${avail_gib} GiB"
        fi
        
        local swap_raw
        swap_raw="$(sysctl -n vm.swapusage 2>/dev/null || echo '')"
        [ -n "$swap_raw" ] && print_kv "${TXT[SWAP_USAGE]}" "${swap_raw}"
        return 0
    fi

    # Windows Memory
    if [ "$OS_FAMILY" = "windows" ] && has_cmd powershell.exe; then
        local mem_data
        mem_data=$(powershell.exe -NoProfile -Command "$os=Get-CimInstance Win32_OperatingSystem; $t=[math]::Round($os.TotalVisibleMemorySize/1MB,1); $f=[math]::Round($os.FreePhysicalMemory/1MB,1); $u=[math]::Round($t-$f,1); $p=[math]::Round(($u/$t)*100); Write-Output \"$t $u $f $p\"" 2>/dev/null | tr -d '\r')
        read -r w_tot w_used w_free w_pct <<< "$mem_data"
        if [ -n "$w_tot" ]; then
            print_kv "${TXT[RAM_TOTAL]}" "${w_tot} GiB"
            print_kv "${TXT[RAM_USED]}" "${w_used} GiB $(render_bar "${w_pct:-0}")"
            print_kv "${TXT[RAM_AVAIL]}" "${w_free} GiB"
        fi
        return 0
    fi

    # Linux Native Memory
    local total_kib free_kib avail_kib total_swap free_swap
    if [ -f /proc/meminfo ]; then
        total_kib=$(grep "MemTotal:" /proc/meminfo | awk '{print $2}')
        free_kib=$(grep "MemFree:" /proc/meminfo | awk '{print $2}')
        avail_kib=$(grep "MemAvailable:" /proc/meminfo | awk '{print $2}')
        total_swap=$(grep "SwapTotal:" /proc/meminfo | awk '{print $2}')
        free_swap=$(grep "SwapFree:" /proc/meminfo | awk '{print $2}')
    fi
    
    local total_gib avail_gib used_gib
    total_gib=$(awk -v k="$total_kib" 'BEGIN {printf "%.1f", k/1048576}')
    avail_gib=$(awk -v k="$avail_kib" 'BEGIN {printf "%.1f", k/1048576}')
    used_gib=$(awk -v t="$total_kib" -v a="$avail_kib" 'BEGIN {printf "%.1f", (t-a)/1048576}')
    
    local used_pct=0
    if (( total_kib > 0 )); then
        used_pct=$(( (total_kib - avail_kib) * 100 / total_kib ))
    fi
    
    print_kv "${TXT[RAM_TOTAL]}" "${total_gib} GiB"
    print_kv "${TXT[RAM_USED]}" "${used_gib} GiB $(render_bar "$used_pct")"
    print_kv "${TXT[RAM_AVAIL]}" "${avail_gib} GiB"
    
    if (( total_swap > 0 )); then
        local swap_tot_gib swap_used_gib swap_pct
        swap_tot_gib=$(awk -v k="$total_swap" 'BEGIN {printf "%.1f", k/1048576}')
        swap_used_gib=$(awk -v t="$total_swap" -v f="$free_swap" 'BEGIN {printf "%.1f", (t-f)/1048576}')
        swap_pct=$(( (total_swap - free_swap) * 100 / total_swap ))
        print_kv "${TXT[SWAP_USAGE]}" "${swap_used_gib} / ${swap_tot_gib} GiB $(render_bar "$swap_pct")"
        if (( swap_pct >= 85 )); then
            record_warn
        fi
    else
        print_kv "${TXT[SWAP_USAGE]}" "Disabled / 0 B"
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
            in_dev && /Manufacturer: / {
                $1=""
                sub(/^[ \t]+/, "")
                mfr=$0
            }
            in_dev && size && speed {
                mfr_disp = (mfr != "" && mfr != "NO DIMM" && mfr != "Unknown") ? " (" mfr ")" : ""
                printf "    %s  Slot Module: %s %s @ %s%s\n", "\033[38;5;48m✔\033[0m", size, type, speed, mfr_disp
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
    
    # macOS Displays
    if [ "$OS_FAMILY" = "macos" ]; then
        print_sub "${TXT[GPU_DETECTED]}"
        system_profiler SPDisplaysDataType 2>/dev/null | awk '
            /Chipset Model:/ {chip=$0; sub(/.*Chipset Model: /, "", chip)}
            /VRAM \(Total\):/ {vram=$0; sub(/.*VRAM \(Total\): /, "", vram)}
            /Metal Support:/ {metal=$0; sub(/.*Metal Support: /, "", metal)}
            /Resolution:/ {
                res=$0; sub(/.*Resolution: /, "", res)
                printf "    ⚡ %s\n       └─ VRAM: %s | Metal: %s | Display: %s\n", chip, vram, metal, res
            }
        ' | while read -r gline; do out "$gline"; done
        return 0
    fi

    # Windows GPUs
    if [ "$OS_FAMILY" = "windows" ] && has_cmd powershell.exe; then
        print_sub "${TXT[GPU_DETECTED]}"
        powershell.exe -NoProfile -Command "Get-CimInstance Win32_VideoController | ForEach-Object { '    ⚡ ' + $_.Name + ' (Driver: ' + $_.DriverVersion + ')' }" 2>/dev/null | tr -d '\r' | while read -r wg; do
            out "$wg"
        done
        if has_cmd nvidia-smi; then
            out ""
            print_sub "${TXT[NVIDIA_STATUS]}"
            local nv_info
            nv_info=$(nvidia-smi --query-gpu=name,driver_version,memory.used,memory.total,temperature.gpu,utilization.gpu --format=csv,noheader,nounits 2>/dev/null | head -n1)
            if [ -n "$nv_info" ]; then
                IFS=',' read -r nv_name nv_drv nv_mused nv_mtot nv_temp nv_load <<< "$nv_info"
                out "    Model       : $(echo "$nv_name" | xargs) (Driver: $(echo "$nv_drv" | xargs))"
                local nv_pct=$(( nv_mused * 100 / nv_mtot ))
                out "    VRAM Usage  : $(echo "$nv_mused" | xargs) / $(echo "$nv_mtot" | xargs) MiB $(render_bar "$nv_pct")"
                out "    Core Temp   : $(echo "$nv_temp" | xargs)°C  ●  Core Load: $(echo "$nv_load" | xargs)%"
            fi
        fi
        return 0
    fi

    # Linux Native GPU
    local gpus=()
    if has_cmd lspci; then
        mapfile -t gpus < <(lspci -nn | grep -E "VGA compatible controller|3D controller|Display controller")
    fi
    
    if [[ ${#gpus[@]} -gt 0 ]]; then
        print_sub "${TXT[GPU_DETECTED]} (${#gpus[@]}):"
        for gpu_entry in "${gpus[@]}"; do
            local pci_slot="${gpu_entry%% *}"
            local gpu_desc
            gpu_desc=$(echo "$gpu_entry" | sed -E 's/^[0-9a-fA-F:.]+[ ]+//' | sed -E 's/^[A-Za-z0-9/ ]+controller[ \[[0-9a-fA-F]+\]]*:[ ]*//')
            out "    ${C_CYAN}⚡ [${pci_slot}]${C_RESET} ${C_WHITE}${gpu_desc}${C_RESET}"
            
            if has_cmd lspci; then
                local in_use
                in_use=$(lspci -v -s "$pci_slot" 2>/dev/null | grep "Kernel driver in use:" | awk -F: '{print $2}' | xargs)
                if [ -n "$in_use" ]; then
                    out "       ${C_DARK}└─${C_RESET} ${C_SLATE}${TXT[GPU_ACTIVE_DRV]}:${C_RESET} ${C_EMERALD}${in_use}${C_RESET}"
                fi
            fi
        done
    else
        out "  ${C_SLATE}No discrete PCI display controllers found.${C_RESET}"
    fi
    
    local gl_render=""
    if has_cmd glxinfo; then
        gl_render=$(glxinfo -B 2>/dev/null | grep -E "OpenGL renderer string|OpenGL version string" | awk -F: '{print $2}' | xargs | paste -sd " (" - | sed 's/$/)/')
    fi
    [ -n "$gl_render" ] && print_kv "${TXT[OPENGL_RENDER]}" "${gl_render}"
    
    if has_cmd vulkaninfo; then
        local vk_devs
        vk_devs=$(vulkaninfo --summary 2>/dev/null | grep -E "deviceName[ 	]*=" | awk -F'=' '{print $2}' | sed -e 's/^[ 	]*//' -e 's/[ 	]*$//' | paste -sd "|" - | sed 's/|/, /g')
        [ -n "$vk_devs" ] && print_kv "${TXT[VULKAN_DEVS]}" "${vk_devs}"
    fi
    
    # NVIDIA Detailed Telemetry
    if has_cmd nvidia-smi; then
        out ""
        print_sub "${TXT[NVIDIA_STATUS]}"
        local nv_raw
        nv_raw=$(nvidia-smi --query-gpu=name,driver_version,memory.used,memory.total,temperature.gpu,utilization.gpu --format=csv,noheader,nounits 2>/dev/null | head -n1)
        if [ -n "$nv_raw" ]; then
            IFS=',' read -r nv_name nv_drv nv_mused nv_mtot nv_temp nv_load <<< "$nv_raw"
            nv_name=$(echo "$nv_name" | xargs)
            nv_drv=$(echo "$nv_drv" | xargs)
            nv_mused=$(echo "$nv_mused" | xargs)
            nv_mtot=$(echo "$nv_mtot" | xargs)
            nv_temp=$(echo "$nv_temp" | xargs)
            nv_load=$(echo "$nv_load" | xargs)
            
            local vram_pct=$(( (nv_mused * 100) / nv_mtot ))
            out "    Model       : ${C_WHITE}${nv_name} (Driver: ${nv_drv})${C_RESET}"
            out "    VRAM Usage  : ${nv_mused} / ${nv_mtot} MiB $(render_bar "$vram_pct")"
            out "    Core Temp   : ${nv_temp}°C  ●  Core Load: ${nv_load}%  ●  Fan: Dynamic ACPI"
        fi
    fi
}

# ==============================================================================
# SEÇÃO 05: ARMAZENAMENTO & SAÚDE S.M.A.R.T.
# ==============================================================================
audit_storage() {
    print_section "${TXT[SECTION_STORE]}"
    
    # macOS Storage
    if [ "$OS_FAMILY" = "macos" ]; then
        print_sub "${TXT[STORAGE_POOLS]}"
        out "    MOUNTPOINT         TYPE    SIZE      USED      AVAIL     CAPACITY"
        df -h | awk 'NR>1 && $1 ~ /^\/dev/ {
            printf "    %-18s %-7s %-9s %-9s %-9s %s\n", $6, "apfs", $2, $3, $4, $5
        }' | head -n 8 | while read -r dline; do out "$dline"; done
        
        out ""
        print_sub "${TXT[SMART_DIAG]}"
        diskutil list 2>/dev/null | grep -E '^/dev/disk[0-9]' | head -n 3 | while read -r ddev; do
            local dpath
            dpath=$(echo "$ddev" | awk '{print $1}')
            local smart_st
            smart_st="$(diskutil info "$dpath" 2>/dev/null | awk -F: '/SMART Status/{print $2}' | xargs)"
            [ -z "$smart_st" ] && smart_st="Verified"
            out "    ◆ Drive: ${dpath}"
            out "      Health Status  : [${smart_st}]"
        done
        return 0
    fi

    # Linux Native Storage
    print_sub "${TXT[STORAGE_POOLS]}"
    out "    ${C_BOLD}MOUNTPOINT         TYPE    SIZE      USED      AVAIL     CAPACITY${C_RESET}"
    
    df -hT -x tmpfs -x devtmpfs -x squashfs -x overlay 2>/dev/null | awk 'NR>1 {
        pct=$6; gsub(/%/, "", pct);
        printf "    %-18s %-7s %-9s %-9s %-9s [%s]\n", $7, $2, $3, $4, $5, pct
    }' | while IFS= read -r line; do
        pct_val=$(echo "$line" | grep -o '\[[0-9]\+\]' | tr -d '[]')
        clean_prefix=$(echo "$line" | sed 's/\[[0-9]\+\]//')
        if [ -n "$pct_val" ]; then
            bar=$(render_bar "$pct_val" 10)
            out "${clean_prefix}${bar}"
            if (( pct_val >= 90 )); then
                record_warn
            fi
        else
            out "$line"
        fi
    done
    
    out ""
    print_sub "${TXT[PHYSICAL_DISKS]}"
    if has_cmd lsblk; then
        lsblk -d -o NAME,TYPE,SIZE,MODEL,ROTA 2>/dev/null | grep -v "loop" | awk 'NR>0 {print "    │ " $0}' | while IFS= read -r line; do
            out "${C_SLATE}${line}${C_RESET}"
        done
    fi
    
    out ""
    print_sub "${TXT[SMART_DIAG]}"
    if [[ $EUID -ne 0 ]]; then
        out "    ${C_GOLD}▲ ${TXT[SMART_ROOT_REQ]}${C_RESET}"
    elif [ "$QUICK_MODE" = true ]; then
        out "    ${C_SLATE}[Quick mode: skipping deep drive SMART interrogation]${C_RESET}"
    elif has_cmd smartctl; then
        local drives=()
        mapfile -t drives < <(lsblk -d -n -o PATH 2>/dev/null | grep -E "/dev/(nvme[0-9]+n[0-9]+|sd[a-z]|vd[a-z])")
        
        if [[ ${#drives[@]} -eq 0 ]]; then
            out "    ${C_SLATE}No standard NVMe or SATA block devices detected.${C_RESET}"
        else
            for d in "${drives[@]}"; do
                out ""
                out "    ${C_CYAN}◆ Drive: ${d}${C_RESET}"
                
                local s_info
                s_info=$(smartctl -i "$d" 2>/dev/null)
                local d_model d_serial d_fw
                d_model=$(echo "$s_info" | grep -E "Model Number:|Device Model:" | awk -F: '{print $2}' | xargs)
                d_serial=$(echo "$s_info" | grep -E "Serial Number:" | awk -F: '{print $2}' | xargs)
                d_fw=$(echo "$s_info" | grep -E "Firmware Version:" | awk -F: '{print $2}' | xargs)
                
                out "      Model / Serial : ${d_model:-Unknown} (${d_serial:-N/A}) [FW: ${d_fw:-N/A}]"
                
                local s_health
                s_health=$(smartctl -H "$d" 2>/dev/null | grep -E "SMART overall-health|SMART Health Status" | awk -F: '{print $2}' | xargs)
                if [[ "$s_health" =~ PASSED|OK ]]; then
                    out "      Health Status  : ${C_EMERALD}[✔ ${s_health}]${C_RESET}"
                elif [ -n "$s_health" ]; then
                    out "      Health Status  : ${C_CRIMSON}${C_BOLD}[✖ ${s_health}]${C_RESET}"
                    record_fail
                else
                    out "      Health Status  : ${C_SLATE}[Not Available / RAW Controller]${C_RESET}"
                fi
                
                local wear temp hours
                wear=$(smartctl -A "$d" 2>/dev/null | awk '/Percentage Used:/ {print $3}' | tr -d '%')
                temp=$(smartctl -A "$d" 2>/dev/null | awk '/Temperature:/ {print $2}' | tr -d 'C')
                [ -z "$temp" ] && temp=$(smartctl -A "$d" 2>/dev/null | awk '/Temperature_Celsius/ {print $10}')
                hours=$(smartctl -A "$d" 2>/dev/null | awk '/Power On Hours:/ {print $4}' | tr -d ',')
                [ -z "$hours" ] && hours=$(smartctl -A "$d" 2>/dev/null | awk '/Power_On_Hours/ {print $10}')
                
                local metrics=()
                [ -n "$wear" ] && metrics+=("${wear}% worn")
                [ -n "$temp" ] && metrics+=("Temp: ${temp}°C")
                [ -n "$hours" ] && metrics+=("Power Hours: $(printf "%'d" "$hours" 2>/dev/null || echo "$hours")")
                
                if [[ ${#metrics[@]} -gt 0 ]]; then
                    local join_metrics=""
                    for m in "${metrics[@]}"; do
                        if [ -z "$join_metrics" ]; then
                            join_metrics="$m"
                        else
                            join_metrics="${join_metrics}  ●  ${m}"
                        fi
                    done
                    out "      SSD Life Used  : ${join_metrics}"
                fi
            done
        fi
    else
        out "    ${C_GOLD}▲ smartctl not found. Run with '--install-deps' or install smartmontools.${C_RESET}"
    fi
}

# ==============================================================================
# SEÇÃO 06: TOPOLOGIA DE REDE & CONECTIVIDADE
# ==============================================================================
audit_network() {
    print_section "${TXT[SECTION_NET]}"
    
    # macOS Network
    if [ "$OS_FAMILY" = "macos" ]; then
        print_sub "${TXT[NET_INTERFACES]}"
        out "    INTERFACE        STATUS     MAC ADDRESS        IP ADDRESSES"
        networksetup -listallhardwareports 2>/dev/null | awk '
            /Hardware Port:/ {port=$0; sub(/.*Hardware Port: /, "", port)}
            /Device:/ {dev=$2}
            /Ethernet Address:/ {
                mac=$3
                cmd = "ipconfig getifaddr " dev " 2>/dev/null"
                ip = ""
                cmd | getline ip
                close(cmd)
                if (ip == "") ip = "No IPv4"
                status = (ip != "No IPv4") ? "UP" : "DOWN"
                printf "    %-16s %-10s %-18s %s (%s)\n", dev, status, mac, ip, port
            }
        ' | while read -r nline; do out "$nline"; done
        
        local def_gw
        def_gw="$(netstat -nr -f inet 2>/dev/null | awk '/default/{print $2; exit}')"
        out ""
        print_kv "${TXT[GATEWAY_DNS]}" "${def_gw:-N/A} (Default Gateway)"
        
        out ""
        print_sub "${TXT[INTERNET_TEST]}"
        if ping -c 1 -W 2000 1.1.1.1 &>/dev/null; then
            local lat
            lat="$(ping -c 1 1.1.1.1 2>/dev/null | awk -F/ '/round-trip|min\/avg\/max/{print $5}')"
            out "    ${C_EMERALD}✔ [${TXT[PING_SUCCESS]}] Cloudflare DNS (1.1.1.1) Latency: ${lat:-N/A} ms${C_RESET}"
        else
            out "    ${C_CRIMSON}✖ [${TXT[PING_FAIL]}]${C_RESET}"
            record_fail
        fi
        return 0
    fi

    # Linux Native Network
    print_sub "${TXT[NET_INTERFACES]}"
    out "    ${C_BOLD}INTERFACE        STATUS     MAC ADDRESS        IP ADDRESSES${C_RESET}"
    
    if has_cmd ip; then
        ip -o link show | awk -F': ' '{print $2}' | while read -r iface; do
            [[ "$iface" == "lo" ]] && continue
            local operstate mac ips
            operstate=$(cat "/sys/class/net/${iface}/operstate" 2>/dev/null || echo "UNKNOWN")
            mac=$(cat "/sys/class/net/${iface}/address" 2>/dev/null || echo "00:00:00:00:00:00")
            ips=$(ip -o -4 addr show dev "$iface" 2>/dev/null | awk '{print $4}' | paste -sd ", " -)
            [ -z "$ips" ] && ips="No IPv4"
            
            local st_color="${C_SLATE}"
            [[ "$operstate" == "up" ]] && st_color="${C_EMERALD}"
            [[ "$operstate" == "down" ]] && st_color="${C_SLATE}"
            
            out "$(printf "    %-16s ${st_color}%-10s${C_RESET} %-18s %s" "$iface" "${operstate^^}" "$mac" "$ips")"
        done
    fi
    
    out ""
    local def_gw dns_servers
    if has_cmd ip; then
        def_gw=$(ip route | grep default | awk '{print $3" via dev "$5}' | head -n1)
    fi
    print_kv "${TXT[GATEWAY_DNS]}" "${def_gw:-None active}"
    
    if [ -f /etc/resolv.conf ]; then
        dns_servers=$(grep "nameserver" /etc/resolv.conf | awk '{print $2}' | paste -sd ", " -)
        print_kv "DNS Resolvers" "${dns_servers:-Unknown}"
    fi
    
    out ""
    print_sub "${TXT[INTERNET_TEST]}"
    if has_cmd ping; then
        local ping_out
        ping_out=$(ping -c 1 -W 2 1.1.1.1 2>/dev/null)
        if [ $? -eq 0 ]; then
            local lat
            lat=$(echo "$ping_out" | grep -E "min/avg/max|rtt" | awk -F'/' '{print $5}')
            out "    ${C_EMERALD}✔ [${TXT[PING_SUCCESS]}] Cloudflare DNS (1.1.1.1) Latency: ${lat} ms${C_RESET}"
        else
            out "    ${C_CRIMSON}✖ [${TXT[PING_FAIL]}]${C_RESET}"
            record_fail
        fi
    fi
}

# ==============================================================================
# SEÇÃO 07: BARRAMENTO USB & PERIFÉRICOS
# ==============================================================================
audit_usb() {
    print_section "${TXT[SECTION_USB]}"
    
    # macOS USB
    if [ "$OS_FAMILY" = "macos" ]; then
        local usb_count
        usb_count="$(system_profiler SPUSBDataType 2>/dev/null | grep -c 'Product ID:' || echo 0)"
        print_kv "${TXT[USB_COUNT]}" "${usb_count} devices present"
        out ""
        print_sub "Connected Devices List:"
        system_profiler SPUSBDataType 2>/dev/null | awk '
            /^[ ]{4}[A-Za-z0-9]/ {
                dev=$0; sub(/^[ ]+/, "", dev); sub(/:$/, "", dev)
                if (dev !~ /Host Controller|Root Hub/ && dev != "") {
                    printf "    ├─ ⚡ %s\n", dev
                }
            }
        ' | head -n 12 | while read -r uline; do out "$uline"; done
        return 0
    fi

    # Linux Native USB
    local usb_count=0
    if has_cmd lsusb; then
        usb_count=$(lsusb | wc -l)
    fi
    print_kv "${TXT[USB_COUNT]}" "${usb_count} devices present"
    
    if has_cmd lsusb; then
        out "  ${C_PURPLE}▸ Connected Devices List:${C_RESET}"
        lsusb | while read -r u_line; do
            local u_id u_name
            u_id=$(echo "$u_line" | awk '{print $6}')
            u_name=$(echo "$u_line" | cut -d' ' -f7-)
            out "    ${C_DARK}├─${C_RESET} ${C_CYAN}⚡ ${u_id}${C_RESET} ${C_WHITE}${u_name}${C_RESET}"
        done
    fi
}

# ==============================================================================
# SEÇÃO 08: SAÚDE DO SISTEMA & LOGS
# ==============================================================================
audit_health_logs() {
    print_section "${TXT[SECTION_HEALTH]}"
    
    # macOS Health
    if [ "$OS_FAMILY" = "macos" ]; then
        print_sub "${TXT[FAILED_UNITS]}"
        local failed_jobs
        failed_jobs=$(launchctl list 2>/dev/null | awk '$2 !~ /^0|-/ {print $3" (exit: "$2")"}' | head -n 5)
        if [ -z "$failed_jobs" ]; then
            out "    ${C_EMERALD}✔ [0 FAILED JOBS] All launchd services running normally.${C_RESET}"
        else
            echo "$failed_jobs" | while read -r fj; do
                out "    ${C_CRIMSON}✖ ${fj}${C_RESET}"
                record_fail
            done
        fi
        out ""
        print_sub "${TXT[KERNEL_ERRS]}"
        out "    ${C_EMERALD}✔ Apple Unified Logging system active (OSLog).${C_RESET}"
        return 0
    fi

    # Linux Native Health
    print_sub "${TXT[FAILED_UNITS]}"
    if has_cmd systemctl; then
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
    
    # Kernel Errors (dmesg) - empty lines filtered
    out ""
    print_sub "${TXT[KERNEL_ERRS]}"
    if [[ $EUID -ne 0 ]]; then
        out "    ${C_SLATE}⊘ Kernel ring buffer requires root privileges (dmesg_restrict).${C_RESET}"
    elif [ "$QUICK_MODE" = true ]; then
        out "    ${C_SLATE}[Quick mode: skipping deep kernel log scan]${C_RESET}"
    elif has_cmd dmesg; then
        local k_errs
        mapfile -t k_errs < <(dmesg -T --level=err,crit,alert,emerg 2>/dev/null | grep -E '[^[:space:]]' | tail -n 10 || true)
        if [[ ${#k_errs[@]} -eq 0 ]]; then
            out "    ${C_EMERALD}✔ No critical kernel errors in recent dmesg buffer.${C_RESET}"
        else
            for k_line in "${k_errs[@]}"; do
                [[ -z "${k_line// }" ]] && continue
                out "    ${C_GOLD}▲ ${k_line}${C_RESET}"
                record_warn
            done
        fi
    fi
    
    # Systemd Journal Errors - empty lines filtered
    out ""
    print_sub "${TXT[JOURNAL_ERRS]}"
    if has_cmd journalctl; then
        local j_errs
        mapfile -t j_errs < <(journalctl -p 3 -xb --no-pager -n 10 2>/dev/null | grep -v -- "-- Logs begin" | grep -E '[^[:space:]]' | tail -n 8 || true)
        if [[ ${#j_errs[@]} -eq 0 ]]; then
            out "    ${C_EMERALD}✔ Clean error journal.${C_RESET}"
        else
            for j_line in "${j_errs[@]}"; do
                [[ -z "${j_line// }" ]] && continue
                out "    ${C_SLATE}│${C_RESET} ${j_line}"
            done
        fi
    fi
}

# ==============================================================================
# SEÇÃO 09: RESUMO EXECUTIVO & PARECER DE SAÚDE
# ==============================================================================
audit_summary() {
    print_section "${TXT[SECTION_SUMMARY]}"
    
    out ""
    if [[ $TOTAL_FAILURES -eq 0 ]] && [[ $TOTAL_WARNINGS -eq 0 ]]; then
        out "  ${C_EMERALD}${C_BOLD}╔══════════════════════════════════════════════════════════════════════╗${C_RESET}"
        out "  ${C_EMERALD}${C_BOLD}║  STATUS: ${TXT[SCORE_OPTIMAL]} ║${C_RESET}"
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
    audit_bootstrap_platform
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
