#!/bin/bash

# ==============================================================================
# Projeto: SysCheck - Script de Diagnóstico do Sistema
# Versão: 3.0.0
# Data: 09 de Setembro de 2025
# Autor: Adaptado por Gemini para o usuário V4mpw0L
# ==============================================================================

# Definições de cores para a saída
VERMELHO='\033[0;31m'
VERDE='\033[0;32m'
AZUL='\033[0;34m'
AMARELO='\033[1;33m'
CIANO='\033[0;36m'
ROXO='\033[0;35m'
BRANCO='\033[1;37m'
NEGRITO='\033[1m'
RESET='\033[0m'

# Variável para o arquivo de log
LOG_FILE="syscheck_$(date +%Y%m%d_%H%M%S).log"

# Variáveis de idioma
LANG_PT="pt"
LANG_EN="en"
CURRENT_LANG=$LANG_EN

# ==============================================================================
# DICIONÁRIOS DE MENSAGENS POR IDIOMA
# ==============================================================================
declare -A MSG
if [[ "$(locale -a | grep -i 'pt_BR.utf8')" ]]; then
    if [[ "$LC_MESSAGES" == *"pt_BR"* ]]; then
        CURRENT_LANG=$LANG_PT
    fi
fi

if [[ "$CURRENT_LANG" == "$LANG_PT" ]]; then
    MSG[INIT_MSG]="Iniciando script de diagnóstico SysCheck..."
    MSG[LOG_CREATED]="Arquivo de log criado:"
    MSG[STARTING_DIAG]="Iniciando diagnóstico em"
    MSG[ROOT_REQUIRED]="Este script deve ser executado com permissões de root. Tente 'sudo ./syscheck.sh'."
    MSG[SECTION_SYSTEM_INFO]="INFORMAÇÕES DO SISTEMA"
    MSG[SYSTEM_DATA]="Dados do Sistema e Kernel:"
    MSG[DISTRO_INFO]="Versão da Distribuição:"
    MSG[CPU_INFO]="Informações da CPU:"
    MSG[MOTHERBOARD_BIOS]="Informações da Placa-Mãe e BIOS:"
    MSG[SECTION_HARDWARE_DRIVERS]="HARDWARE E DRIVERS"
    MSG[PCI_DEVICES]="Dispositivos PCI (Resumo):"
    MSG[GPU_INFO]="Placas de Vídeo (GPU):"
    MSG[NVIDIA_STATUS]="Status do driver NVIDIA:"
    MSG[NVIDIA_NOT_FOUND]="Driver NVIDIA não encontrado ou não está rodando. Isso pode ser normal se estiver usando gráficos integrados."
    MSG[STORAGE_INFO]="ARMAZENAMENTO (SSD)"
    MSG[STORAGE_DEVICES]="Dispositivos de Armazenamento:"
    MSG[SSD_SMART_STATUS]="Status do SSD (verificação SMART):"
    MSG[SMARTCTL_MISSING]="smartctl não encontrado. Por favor, instale 'smartmontools'."
    MSG[SSD_CHECKING]="Verificando SSD:"
    MSG[SSD_ERROR_LOGS]="Erros de SMART para o SSD:"
    MSG[SSD_HEALTH_INFO]="Saúde Geral do SSD:"
    MSG[NO_SSD_DETECTED]="Nenhum SSD detectado para verificação SMART."
    MSG[RAM_INFO]="MEMÓRIA RAM"
    MSG[RAM_MODULES_INFO]="Informações dos Módulos de RAM:"
    MSG[CURRENT_RAM_USAGE]="Uso de Memória Atual:"
    MSG[NETWORK_INFO]="REDE (WI-FI E ETHERNET)"
    MSG[NETWORK_DEVICES]="Dispositivos de Rede:"
    MSG[USB_INFO]="DISPOSITIVOS USB"
    MSG[USB_DEVICES]="Dispositivos USB Conectados:"
    MSG[SECTION_HEALTH_LOGS]="SAÚDE DO SISTEMA, TEMPERATURAS E LOGS"
    MSG[TEMP_INFO]="Temperaturas (CPU e GPU):"
    MSG[SENSORS_MISSING]="'sensors' não encontrado. Por favor, instale o pacote 'lm-sensors'."
    MSG[KERNEL_LOGS]="Últimos 50 erros no dmesg (log do kernel):"
    MSG[SYSTEM_LOGS]="Últimos 50 erros no Journal (log geral do sistema):"
    MSG[FINISHED_DIAG]="Diagnóstico concluído!"
    MSG[REPORT_SAVED]="O relatório detalhado foi salvo em"
    MSG[ANALYSIS_PROMPT]="Por favor, analise o arquivo de log para mais detalhes."
    MSG[DEP_CHECK]="Verificando dependências do sistema..."
    MSG[MISSING_DEPS]="Os seguintes comandos não foram encontrados:"
    MSG[ASK_INSTALL]="Deseja instalá-los agora? (y/n)"
    MSG[INSTALLING_DEPS]="Instalando dependências..."
    MSG[INSTALL_FAILED]="Não foi possível instalar as dependências. Verifique se o gerenciador de pacotes está acessível."
    MSG[PROCEED_WITHOUT]="Continuando sem as dependências. Algumas seções podem falhar."
    MSG[INSTALL_SUCCESS]="Dependências instaladas com sucesso."
else # Inglês (Padrão)
    MSG[INIT_MSG]="Starting SysCheck diagnostic script..."
    MSG[LOG_CREATED]="Log file created:"
    MSG[STARTING_DIAG]="Starting diagnostic on"
    MSG[ROOT_REQUIRED]="This script must be run with root privileges. Try 'sudo ./syscheck.sh'."
    MSG[SECTION_SYSTEM_INFO]="SYSTEM INFORMATION"
    MSG[SYSTEM_DATA]="System and Kernel Data:"
    MSG[DISTRO_INFO]="Distribution Version:"
    MSG[CPU_INFO]="CPU Information:"
    MSG[MOTHERBOARD_BIOS]="Motherboard and BIOS Information:"
    MSG[SECTION_HARDWARE_DRIVERS]="HARDWARE AND DRIVERS"
    MSG[PCI_DEVICES]="PCI Devices (Summary):"
    MSG[GPU_INFO]="Graphics Cards (GPU):"
    MSG[NVIDIA_STATUS]="NVIDIA driver status:"
    MSG[NVIDIA_NOT_FOUND]="NVIDIA driver not found or not running. This can be normal if using integrated graphics."
    MSG[STORAGE_INFO]="STORAGE (SSD)"
    MSG[STORAGE_DEVICES]="Storage Devices:"
    MSG[SSD_SMART_STATUS]="SSD Status (SMART check):"
    MSG[SMARTCTL_MISSING]="'smartctl' not found. Please install the 'smartmontools' package."
    MSG[SSD_CHECKING]="Checking SSD:"
    MSG[SSD_ERROR_LOGS]="SMART error logs for the SSD:"
    MSG[SSD_HEALTH_INFO]="Overall SSD Health:"
    MSG[NO_SSD_DETECTED]="No NVMe or SATA SSD detected for SMART check."
    MSG[RAM_INFO]="RAM MEMORY"
    MSG[RAM_MODULES_INFO]="RAM Modules Information:"
    MSG[CURRENT_RAM_USAGE]="Current Memory Usage:"
    MSG[NETWORK_INFO]="NETWORK (WI-FI & ETHERNET)"
    MSG[NETWORK_DEVICES]="Network Devices:"
    MSG[USB_INFO]="USB DEVICES"
    MSG[USB_DEVICES]="Connected USB Devices:"
    MSG[SECTION_HEALTH_LOGS]="SYSTEM HEALTH, TEMPERATURES AND LOGS"
    MSG[TEMP_INFO]="Temperatures (CPU and GPU):"
    MSG[SENSORS_MISSING]="'sensors' not found. Please install the 'lm-sensors' package."
    MSG[KERNEL_LOGS]="Last 50 errors from dmesg (kernel log):"
    MSG[SYSTEM_LOGS]="Last 50 errors from Journal (system log):"
    MSG[FINISHED_DIAG]="Diagnosis complete!"
    MSG[REPORT_SAVED]="The detailed report has been saved to"
    MSG[ANALYSIS_PROMPT]="Please analyze the log file for more details."
    MSG[DEP_CHECK]="Checking system dependencies..."
    MSG[MISSING_DEPS]="The following commands were not found:"
    MSG[ASK_INSTALL]="Do you want to install them now? (y/n)"
    MSG[INSTALLING_DEPS]="Installing dependencies..."
    MSG[INSTALL_FAILED]="Could not install dependencies. Check if your package manager is accessible."
    MSG[PROCEED_WITHOUT]="Proceeding without dependencies. Some sections may fail."
    MSG[INSTALL_SUCCESS]="Dependencies installed successfully."
fi


# Função para escrever no log e exibir na tela
log_info() {
    echo -e "${CIANO}[INFO]${RESET} $1" | tee -a "$LOG_FILE"
}

# Função para exibir um cabeçalho de seção
show_section() {
    echo -e "\n${AMARELO}========================================================================================${RESET}" | tee -a "$LOG_FILE"
    echo -e "${AMARELO}>>>>> ${MSG[$1]} <<<<<${RESET}" | tee -a "$LOG_FILE"
    echo -e "${AMARELO}========================================================================================${RESET}" | tee -a "$LOG_FILE"
}

# Função para checar se um comando existe
command_exists() {
    command -v "$1" &> /dev/null
}

# Verifica se o script está rodando como root
if [[ $EUID -ne 0 ]]; then
   echo -e "${VERMELHO}${MSG[ROOT_REQUIRED]}${RESET}"
   exit 1
fi

# ==============================================================================
# FUNÇÃO DE INSTALAÇÃO DE DEPENDÊNCIAS
# ==============================================================================
install_dependencies() {
    log_info "${MSG[DEP_CHECK]}"
    
    # Mapeamento de comandos para nomes de pacotes
    declare -A COMMANDS_TO_PACKAGES=(
        ["lscpu"]="util-linux"
        ["lsb_release"]="lsb-release"
        ["dmidecode"]="dmidecode"
        ["lspci"]="pciutils"
        ["lsblk"]="util-linux"
        ["ip"]="iproute2"
        ["lsusb"]="usbutils"
        ["dmesg"]="util-linux"
        ["journalctl"]="systemd"
        ["smartctl"]="smartmontools"
        ["sensors"]="lm-sensors"
        ["glxinfo"]="mesa-utils"
        ["nvidia-smi"]="nvidia-utils" # Nome comum em algumas distros
    )
    
    MISSING_DEPS=()
    for cmd in "${!COMMANDS_TO_PACKAGES[@]}"; do
        if ! command_exists "$cmd"; then
            MISSING_DEPS+=("$cmd")
        fi
    done

    if [[ ${#MISSING_DEPS[@]} -gt 0 ]]; then
        echo -e "${VERMELHO}${MSG[MISSING_DEPS]}${RESET} ${MISSING_DEPS[*]}"
        read -p "${VERDE}${MSG[ASK_INSTALL]}${RESET} " -n 1 -r REPLY
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            echo -e "${AZUL}${MSG[INSTALLING_DEPS]}${RESET}"
            
            # Detecta o gerenciador de pacotes
            local package_manager=""
            if command_exists apt-get; then
                package_manager="apt-get"
            elif command_exists dnf; then
                package_manager="dnf"
            elif command_exists yum; then
                package_manager="yum"
            elif command_exists pacman; then
                package_manager="pacman"
            fi

            if [[ -n "$package_manager" ]]; then
                PACKAGES_TO_INSTALL=()
                for dep_cmd in "${MISSING_DEPS[@]}"; do
                    # Ajusta os nomes dos pacotes para diferentes gerenciadores
                    case "$package_manager" in
                        apt-get)
                            PACKAGES_TO_INSTALL+=("${COMMANDS_TO_PACKAGES[$dep_cmd]}")
                            ;;
                        dnf|yum)
                            # Fedora/RHEL usa nomes diferentes para alguns pacotes
                            case "$dep_cmd" in
                                "lspci") PACKAGES_TO_INSTALL+=("pciutils");;
                                "dmidecode") PACKAGES_TO_INSTALL+=("dmidecode");;
                                "lsb_release") PACKAGES_TO_INSTALL+=("redhat-lsb");;
                                "smartctl") PACKAGES_TO_INSTALL+=("smartmontools");;
                                "sensors") PACKAGES_TO_INSTALL+=("lm_sensors");;
                                "glxinfo") PACKAGES_TO_INSTALL+=("mesa-demos");;
                                "nvidia-smi") PACKAGES_TO_INSTALL+=("kmod-nvidia-575");; # Exemplo, varia muito
                                *) PACKAGES_TO_INSTALL+=("$dep_cmd");;
                            esac
                            ;;
                        pacman)
                            # Arch Linux
                            case "$dep_cmd" in
                                "lscpu") PACKAGES_TO_INSTALL+=("util-linux");;
                                "lsb_release") PACKAGES_TO_INSTALL+=("lsb-release");;
                                "dmidecode") PACKAGES_TO_INSTALL+=("dmidecode");;
                                "lspci") PACKAGES_TO_INSTALL+=("pciutils");;
                                "lsblk") PACKAGES_TO_INSTALL+=("util-linux");;
                                "ip") PACKAGES_TO_INSTALL+=("iproute2");;
                                "lsusb") PACKAGES_TO_INSTALL+=("usbutils");;
                                "dmesg") PACKAGES_TO_INSTALL+=("util-linux");;
                                "journalctl") PACKAGES_TO_INSTALL+=("systemd");;
                                "smartctl") PACKAGES_TO_INSTALL+=("smartmontools");;
                                "sensors") PACKAGES_TO_INSTALL+=("lm_sensors");;
                                "glxinfo") PACKAGES_TO_INSTALL+=("mesa-utils");;
                                "nvidia-smi") PACKAGES_TO_INSTALL+=("nvidia-utils");;
                                *) PACKAGES_TO_INSTALL+=("$dep_cmd");;
                            esac
                            ;;
                    esac
                done

                # Instala os pacotes
                if [[ ${#PACKAGES_TO_INSTALL[@]} -gt 0 ]]; then
                    sudo $package_manager install -y "${PACKAGES_TO_INSTALL[@]}" &> /dev/null
                    if [[ $? -eq 0 ]]; then
                        log_info "${VERDE}${MSG[INSTALL_SUCCESS]}${RESET}"
                    else
                        log_info "${VERMELHO}${MSG[INSTALL_FAILED]}${RESET}"
                    fi
                fi
            else
                log_info "${VERMELHO}${MSG[INSTALL_FAILED]}${RESET}"
            fi
        else
            log_info "${VERMELHO}${MSG[PROCEED_WITHOUT]}${RESET}"
        fi
    fi
}

# Executa a verificação e instalação
install_dependencies

# Inicialização
echo -e "${VERDE}${MSG[INIT_MSG]}${RESET}"
log_info "${MSG[LOG_CREATED]} $LOG_FILE"
echo -e "${BRANCO}${MSG[STARTING_DIAG]} $(date)...${RESET}" | tee -a "$LOG_FILE"

# ==============================================================================
# SEÇÃO 1: INFORMAÇÕES DO SISTEMA
# ==============================================================================
show_section "SECTION_SYSTEM_INFO"

log_info "${MSG[SYSTEM_DATA]}"
command_exists uname && uname -a | tee -a "$LOG_FILE"
echo | tee -a "$LOG_FILE"

log_info "${MSG[DISTRO_INFO]}"
if command_exists lsb_release; then
    lsb_release -a 2>/dev/null | tee -a "$LOG_FILE"
else
    cat /etc/os-release | tee -a "$LOG_FILE"
fi
echo | tee -a "$LOG_FILE"

log_info "${MSG[CPU_INFO]}"
command_exists lscpu && lscpu | grep -E "Model name|Core|Thread|CPU MHz|L3 cache" | tee -a "$LOG_FILE"
echo | tee -a "$LOG_FILE"

log_info "${MSG[MOTHERBOARD_BIOS]}"
if command_exists dmidecode; then
    dmidecode -t baseboard | grep -E "Manufacturer|Product Name|Version" | tee -a "$LOG_FILE"
    dmidecode -t bios | grep -E "Vendor|Version|Release Date" | tee -a "$LOG_FILE"
else
    log_info "dmidecode não encontrado. Pulando esta verificação."
fi
echo | tee -a "$LOG_FILE"

# ==============================================================================
# SEÇÃO 2: HARDWARE E DRIVERS
# ==============================================================================
show_section "SECTION_HARDWARE_DRIVERS"

log_info "${MSG[PCI_DEVICES]}"
command_exists lspci && lspci -tv | tee -a "$LOG_FILE"
echo | tee -a "$LOG_FILE"

log_info "${MSG[GPU_INFO]}"
if command_exists lspci; then
    lspci -v -s $(lspci | grep -i "vga" | cut -d' ' -f1) | grep -E "VGA|Kernel driver in use|subsystem|firmware" | tee -a "$LOG_FILE"
    if command_exists glxinfo; then
        glxinfo 2>/dev/null | grep "OpenGL renderer string" | tee -a "$LOG_FILE"
    fi
fi
echo | tee -a "$LOG_FILE"

log_info "${MSG[NVIDIA_STATUS]}"
if command_exists nvidia-smi; then
    nvidia-smi 2>/dev/null | tee -a "$LOG_FILE"
    if [[ $? -ne 0 ]]; then
        log_info "${MSG[NVIDIA_NOT_FOUND]}"
    fi
fi
echo | tee -a "$LOG_FILE"

log_info "${MSG[NETWORK_DEVICES]}"
if command_exists lspci; then
    lspci -nn | grep -i "network" | tee -a "$LOG_FILE"
    if command_exists ip; then
        ip addr | grep -E 'state UP|link/ether' | tee -a "$LOG_FILE"
    fi
fi
echo | tee -a "$LOG_FILE"

log_info "${MSG[USB_DEVICES]}"
command_exists lsusb && lsusb -v | grep -E 'Bus|Manufacturer|Product|idVendor|idProduct|iSerial|iManufacturer' | tee -a "$LOG_FILE"
echo | tee -a "$LOG_FILE"

# ==============================================================================
# SEÇÃO 3: ARMAZENAMENTO E MEMÓRIA
# ==============================================================================
show_section "STORAGE_INFO"
log_info "${MSG[STORAGE_DEVICES]}"
command_exists lsblk && lsblk | tee -a "$LOG_FILE"
echo | tee -a "$LOG_FILE"

log_info "${MSG[SSD_SMART_STATUS]}"
if ! command_exists smartctl; then
    log_info "${VERMELHO}${MSG[SMARTCTL_MISSING]}${RESET}"
else
    SSD_DEVICE=$(lsblk -o NAME,TYPE,MODEL | grep "disk" | grep -i "nvme" | head -n 1 | awk '{print "/dev/"$1}')
    if [ -z "$SSD_DEVICE" ]; then
        SSD_DEVICE=$(lsblk -o NAME,TYPE,MODEL | grep "disk" | grep -i "ssd" | head -n 1 | awk '{print "/dev/"$1}')
    fi

    if [ -n "$SSD_DEVICE" ]; then
        log_info "${MSG[SSD_CHECKING]} $SSD_DEVICE"
        smartctl -H "$SSD_DEVICE" | tee -a "$LOG_FILE"
        echo | tee -a "$LOG_FILE"
        
        log_info "${MSG[SSD_ERROR_LOGS]}"
        smartctl -l error "$SSD_DEVICE" | tee -a "$LOG_FILE"
        echo | tee -a "$LOG_FILE"
        
        log_info "${MSG[SSD_HEALTH_INFO]}"
        smartctl -a "$SSD_DEVICE" | grep -i "health" | tee -a "$LOG_FILE"
        echo | tee -a "$LOG_FILE"
    else
        log_info "${MSG[NO_SSD_DETECTED]}"
    fi
fi

show_section "RAM_INFO"
log_info "${MSG[RAM_MODULES_INFO]}"
command_exists dmidecode && dmidecode -t memory | grep -E "Size|Type|Speed|Manufacturer" | tee -a "$LOG_FILE"
log_info "${MSG[CURRENT_RAM_USAGE]}"
command_exists free && free -h | tee -a "$LOG_FILE"
echo | tee -a "$LOG_FILE"

# ==============================================================================
# SEÇÃO 4: SAÚDE DO SISTEMA, TEMPERATURAS E LOGS
# ==============================================================================
show_section "SECTION_HEALTH_LOGS"

log_info "${MSG[TEMP_INFO]}"
if ! command_exists sensors; then
    log_info "${VERMELHO}${MSG[SENSORS_MISSING]}${RESET}"
else
    sensors | tee -a "$LOG_FILE"
fi
echo | tee -a "$LOG_FILE"

log_info "${MSG[KERNEL_LOGS]}"
command_exists dmesg && dmesg -T --level=err | tail -n 50 | tee -a "$LOG_FILE"
echo | tee -a "$LOG_FILE"

log_info "${MSG[SYSTEM_LOGS]}"
command_exists journalctl && journalctl -p 3 -n 50 --no-pager | tee -a "$LOG_FILE"
echo | tee -a "$LOG_FILE"

# ==============================================================================
# FINALIZAÇÃO
# ==============================================================================
echo -e "${VERDE}${MSG[FINISHED_DIAG]}${RESET}" | tee -a "$LOG_FILE"
echo -e "${BRANCO}${MSG[REPORT_SAVED]} ${ROXO}$LOG_FILE${RESET}"
echo -e "${BRANCO}${MSG[ANALYSIS_PROMPT]}${RESET}"
