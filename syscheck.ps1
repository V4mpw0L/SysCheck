<#
.SYNOPSIS
    SysCheck - Enterprise System & Hardware Diagnostic Engine (Windows PowerShell Edition)
.DESCRIPTION
    Comprehensive, deep hardware, multi-GPU, thermal, storage, and health audit engine for Windows 10/11 & Windows Server.
    Designed by V4mpw0L / Gennisys Studio.
.EXAMPLE
    .\syscheck.ps1
.EXAMPLE
    .\syscheck.ps1 -Quick -Lang pt
.EXAMPLE
    powershell -ExecutionPolicy Bypass -File .\syscheck.ps1
#>

[CmdletBinding()]
param (
    [switch]$Quick,
    [switch]$NoColor,
    [switch]$NoLog,
    [string]$Output,
    [string]$Lang,
    [switch]$CheckDeps,
    [switch]$InstallDeps,
    [switch]$Yes
)

$VERSION = "4.0.0"
$DateStr = Get-Date -Format "yyyyMMdd_HHmmss"
$LogFile = if ($Output) { $Output } else { "syscheck_$DateStr.log" }

# ------------------------------------------------------------------------------
# PALETA DE CORES & ESTILOS (ANSI 256-color)
# ------------------------------------------------------------------------------
if (-not $NoColor -and ($Host.UI.SupportsVirtualTerminal -or $env:TERM)) {
    $C_RESET   = "`e[0m"
    $C_BOLD    = "`e[1m"
    $C_DIM     = "`e[2m"
    $C_EMERALD = "`e[38;5;48m"
    $C_CYAN    = "`e[38;5;51m"
    $C_BLUE    = "`e[38;5;39m"
    $C_PURPLE  = "`e[38;5;141m"
    $C_GOLD    = "`e[38;5;220m"
    $C_CRIMSON = "`e[38;5;196m"
    $C_WHITE   = "`e[38;5;255m"
    $C_SLATE   = "`e[38;5;245m"
    $C_DARK    = "`e[38;5;238m"
} else {
    $C_RESET = $C_BOLD = $C_DIM = $C_EMERALD = $C_CYAN = $C_BLUE = $C_PURPLE = $C_GOLD = $C_CRIMSON = $C_WHITE = $C_SLATE = $C_DARK = ""
}

# ------------------------------------------------------------------------------
# INTERNACIONALIZAÇÃO (i18n)
# ------------------------------------------------------------------------------
$CurrentLang = "en"
if ($Lang) {
    $CurrentLang = $Lang.ToLower()
} else {
    $Culture = [System.Globalization.CultureInfo]::CurrentUICulture.Name
    if ($Culture -match "^pt") { $CurrentLang = "pt" }
}

$TXT = @{}
if ($CurrentLang -eq "pt") {
    $TXT.Title          = "MOTOR DE DIAGNÓSTICO DE SISTEMA & HARDWARE [v$VERSION]"
    $TXT.Subtitle       = "Gennisys Studio  ●  Auditoria de Infraestrutura & Hardware"
    $TXT.ModeAdmin      = "MODO PRIVILEGIADO (ADMINISTRADOR) - DIAGNÓSTICO PROFUNDO ATIVO"
    $TXT.ModeUser       = "MODO USUÁRIO (NÃO-ADMIN) - EXECUTE COMO ADMINISTRADOR PARA ACESSO COMPLETO"
    $TXT.SectionSys     = "01. SISTEMA OPERACIONAL & AMBIENTE"
    $TXT.SectionCpu     = "02. PROCESSADOR (CPU) & EFICIÊNCIA TÉRMICA"
    $TXT.SectionRam     = "03. MEMÓRIA RAM & GERENCIAMENTO DE SWAP"
    $TXT.SectionGpu     = "04. SUBSISTEMA GRÁFICO & MULTI-GPU"
    $TXT.SectionStore   = "05. ARMAZENAMENTO, DISCOS & SAÚDE S.M.A.R.T."
    $TXT.SectionNet     = "06. REDE, INTERFACES & CONECTIVIDADE"
    $TXT.SectionUsb     = "07. BARRAMENTO USB & PERIFÉRICOS"
    $TXT.SectionHealth  = "08. SAÚDE DO SISTEMA, SERVIÇOS & LOGS DE ERRO"
    $TXT.SectionSummary = "09. PARECER EXECUTIVO & RESUMO DE SAÚDE"
    $TXT.ScoreOptimal   = "EXCELENTE - Nenhum problema crítico detectado"
    $TXT.ScoreWarn      = "ATENÇÃO - Alertas detectados (alta utilização ou erros leves)"
    $TXT.ScoreCrit      = "CRÍTICO - Falhas ativas encontradas no sistema"
} else {
    $TXT.Title          = "ENTERPRISE SYSTEM & HARDWARE DIAGNOSTIC ENGINE [v$VERSION]"
    $TXT.Subtitle       = "Gennisys Studio  ●  Infrastructure & Hardware Audit"
    $TXT.ModeAdmin      = "PRIVILEGED MODE (ADMINISTRATOR) - DEEP HARDWARE AUDIT ACTIVE"
    $TXT.ModeUser       = "USER MODE (NON-ADMIN) - RUN AS ADMINISTRATOR FOR COMPLETE AUDIT"
    $TXT.SectionSys     = "01. OPERATING SYSTEM & ENVIRONMENT"
    $TXT.SectionCpu     = "02. PROCESSADOR (CPU) & THERMAL EFFICIENCY"
    $TXT.SectionRam     = "03. RAM ALLOCATION & SWAP MANAGEMENT"
    $TXT.SectionGpu     = "04. GRAPHICS SUBSYSTEM & MULTI-GPU PIPELINE"
    $TXT.SectionStore   = "05. STORAGE, DISKS & S.M.A.R.T. HEALTH"
    $TXT.SectionNet     = "06. NETWORK TOPOLOGY & CONNECTIVITY"
    $TXT.SectionUsb     = "07. USB CONTROLLERS & PERIPHERALS"
    $TXT.SectionHealth  = "08. SYSTEM HEALTH, FAILED SERVICES & LOGS"
    $TXT.SectionSummary = "09. EXECUTIVE AUDIT & HEALTH SUMMARY"
    $TXT.ScoreOptimal   = "OPTIMAL - No critical warnings or failures detected"
    $TXT.ScoreWarn      = "WARNING - Elevated resource usage or non-critical issues"
    $TXT.ScoreCrit      = "CRITICAL - Active service or hardware warnings present"
}

# ------------------------------------------------------------------------------
# LOGGING & OUTPUT
# ------------------------------------------------------------------------------
if (-not $NoLog) {
    Set-Content -Path $LogFile -Value "" -Encoding UTF8 -Force
}

function Write-Out {
    param([string]$Text)
    Write-Host $Text
    if (-not $NoLog) {
        $Clean = $Text -replace '\x1B\[[0-9;]*[mK]', ''
        Add-Content -Path $LogFile -Value $Clean -Encoding UTF8
    }
}

function Print-Section {
    param([string]$Title)
    Write-Out ""
    Write-Out "$C_CYAN╭────────────────────────────────────────────────────────────────────────╮$C_RESET"
    Write-Out "$C_CYAN│$C_RESET $C_WHITE$C_BOLD❖  $Title$C_RESET"
    Write-Out "$C_CYAN╰────────────────────────────────────────────────────────────────────────╯$C_RESET"
}

function Print-Kv {
    param([string]$Key, [string]$Val)
    $PadKey = $Key.PadRight(30)
    Write-Out "  $C_CYAN●$C_RESET  $C_SLATE$PadKey$C_RESET : $C_WHITE$Val$C_RESET"
}

function Print-Sub {
    param([string]$Subtitle)
    Write-Out "  $C_PURPLE▸ $C_BOLD$Subtitle$C_RESET"
}

function Render-Bar {
    param([int]$Pct, [int]$Width = 16)
    if ($Pct -gt 100) { $Pct = 100 }
    if ($Pct -lt 0) { $Pct = 0 }
    $Fill = [math]::Round(($Pct * $Width) / 100)
    $Empty = $Width - $Fill
    $FillStr = [string]::new('█', $Fill)
    $EmptyStr = [string]::new('░', $Empty)
    $Color = $C_EMERALD
    if ($Pct -ge 90) { $Color = "$C_CRIMSON$C_BOLD" }
    elseif ($Pct -ge 75) { $Color = $C_GOLD }
    return "$Color[$FillStr$EmptyStr] $Pct%$C_RESET"
}

$TotalWarnings = 0
$TotalFailures = 0
function Record-Warn { $script:TotalWarnings++ }
function Record-Fail { $script:TotalFailures++ }

$IsAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

# ------------------------------------------------------------------------------
# BANNER
# ------------------------------------------------------------------------------
function Print-Banner {
    Write-Out ""
    Write-Out "  $C_EMERALD$C_BOLD███████╗██╗   ██╗███████╗ ██████╗██╗  ██╗███████╗ ██████╗██╗  ██╗$C_RESET"
    Write-Out "  $C_EMERALD$C_BOLD██╔════╝╚██╗ ██╔╝██╔════╝██╔════╝██║  ██║██╔════╝██╔════╝██║ ██╔╝$C_RESET"
    Write-Out "  $C_CYAN$C_BOLD███████╗ ╚████╔╝ ███████╗██║     ███████║█████╗  ██║     █████╔╝ $C_RESET"
    Write-Out "  $C_CYAN$C_BOLD╚════██║  ╚██╔╝  ╚════██║██║     ██╔══██║██╔══╝  ██║     ██╔═██╗ $C_RESET"
    Write-Out "  $C_BLUE$C_BOLD███████║   ██║   ███████║╚██████╗██║  ██║███████╗╚██████╗██║  ██╗$C_RESET"
    Write-Out "  $C_BLUE$C_BOLD╚══════╝   ╚═╝   ╚══════╝ ╚═════╝╚═╝  ╚═╝╚══════╝ ╚═════╝╚═╝  ╚═╝$C_RESET"
    Write-Out ""
    Write-Out "  $C_WHITE$C_BOLD$($TXT.Title)$C_RESET"
    Write-Out "  $C_SLATE$($TXT.Subtitle)$C_RESET"
    Write-Out "  $C_DARK────────────────────────────────────────────────────────────────────────$C_RESET"
    if ($IsAdmin) {
        Write-Out "  $C_EMERALD$C_BOLD⚡ $($TXT.ModeAdmin)$C_RESET"
    } else {
        Write-Out "  $C_GOLD● $($TXT.ModeUser)$C_RESET"
    }
    Write-Out "  $C_SLATE Date: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')  ●  Platform: Windows  ●  Host: $env:COMPUTERNAME$C_RESET"
    Write-Out ""
}

# ------------------------------------------------------------------------------
# SEÇÃO 01: SISTEMA OPERACIONAL & AMBIENTE
# ------------------------------------------------------------------------------
function Audit-System {
    Print-Section $TXT.SectionSys
    try {
        $OS = Get-CimInstance Win32_OperatingSystem
        $CS = Get-CimInstance Win32_ComputerSystem
        $BIOS = Get-CimInstance Win32_BIOS
        $BB = Get-CimInstance Win32_BaseBoard

        Print-Kv "Operating System" "$($OS.Caption) ($($OS.OSArchitecture))"
        Print-Kv "Build & Version" "$($OS.Version) (Build $($OS.BuildNumber))"
        Print-Kv "Machine Hostname" "$($env:COMPUTERNAME) ($($OS.SerialNumber))"
        
        $Uptime = (Get-Date) - $OS.LastBootUpTime
        $UptimeStr = "$($Uptime.Days) days, $($Uptime.Hours) hours, $($Uptime.Minutes) minutes"
        Print-Kv "System Uptime" $UptimeStr
        
        Print-Kv "Init Subsystem" "Windows Service Control Manager (services.exe)"
        Print-Kv "Desktop / Session" "Windows Desktop (DWM / explorer.exe)"
        Print-Kv "Motherboard / Chassis" "$($BB.Manufacturer) $($BB.Product)"
        Print-Kv "Firmware / BIOS" "$($BIOS.Manufacturer) $($BIOS.SMBIOSBIOSVersion) ($($BIOS.ReleaseDate.ToString('yyyy-MM-dd')))"
    } catch {
        Write-Out "  $C_GOLD▲ Error reading system CIM: $($_.Exception.Message)$C_RESET"
    }
}

# ------------------------------------------------------------------------------
# SEÇÃO 02: PROCESSADOR & TÉRMICO
# ------------------------------------------------------------------------------
function Audit-Cpu {
    Print-Section $TXT.SectionCpu
    try {
        $CPU = Get-CimInstance Win32_Processor | Select-Object -First 1
        Print-Kv "Processor Model" $CPU.Name
        Print-Kv "Architecture / Cores" "$env:PROCESSOR_ARCHITECTURE ● $($CPU.NumberOfCores) Physical Cores / $($CPU.NumberOfLogicalProcessors) Threads"
        Print-Kv "Clock Frequency" "$($CPU.CurrentClockSpeed) MHz / $($CPU.MaxClockSpeed) MHz"
        Print-Kv "Cache L2 / L3" "L2: $($CPU.L2CacheSize) KB | L3: $($CPU.L3CacheSize) KB"
        
        # Load
        $Load = $CPU.LoadPercentage
        Print-Kv "Current CPU Load" "$Load%"
        
        # Thermal query (WMI ACPI)
        $Thermal = Get-CimInstance -Namespace "root/wmi" -ClassName "MSAcpi_ThermalZoneTemperature" -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($Thermal -and $Thermal.CurrentTemperature) {
            $TempC = [math]::Round(($Thermal.CurrentTemperature - 2732) / 10, 1)
            Print-Kv "CPU Package Temp" "$TempC°C [NORMAL]"
        }
    } catch {
        Write-Out "  $C_GOLD▲ Error reading CPU CIM: $($_.Exception.Message)$C_RESET"
    }
}

# ------------------------------------------------------------------------------
# SEÇÃO 03: MEMÓRIA RAM & SWAP
# ------------------------------------------------------------------------------
function Audit-Ram {
    Print-Section $TXT.SectionRam
    try {
        $OS = Get-CimInstance Win32_OperatingSystem
        $TotalGB = [math]::Round($OS.TotalVisibleMemorySize / 1MB, 1)
        $FreeGB = [math]::Round($OS.FreePhysicalMemory / 1MB, 1)
        $UsedGB = [math]::Round($TotalGB - $FreeGB, 1)
        $Pct = [math]::Round(($UsedGB / $TotalGB) * 100)
        
        Print-Kv "Total Physical RAM" "$TotalGB GiB"
        Print-Kv "Allocated Memory" "$UsedGB GiB $(Render-Bar $Pct)"
        Print-Kv "Available Memory" "$FreeGB GiB"
        
        # Pagefile
        $Pagefiles = Get-CimInstance Win32_PageFileUsage -ErrorAction SilentlyContinue
        if ($Pagefiles) {
            $PageAlloc = $Pagefiles.AllocatedBaseSize
            $PageCurrent = $Pagefiles.CurrentUsage
            $PagePct = [math]::Round(($PageCurrent / $PageAlloc) * 100)
            Print-Kv "Pagefile Usage" "$PageCurrent / $PageAlloc MB $(Render-Bar $PagePct)"
        }
        
        # Physical sticks
        Write-Out ""
        Print-Sub "Physical Memory Modules:"
        $Sticks = Get-CimInstance Win32_PhysicalMemory -ErrorAction SilentlyContinue
        foreach ($s in $Sticks) {
            $GB = [math]::Round($s.Capacity / 1GB, 1)
            $Mfr = if ($s.Manufacturer) { "($($s.Manufacturer.Trim()))" } else { "" }
            Write-Out "    $C_EMERALD✔$C_RESET  Slot: $GB GB @ $($s.Speed) MT/s $Mfr"
        }
    } catch {
        Write-Out "  $C_GOLD▲ Error reading RAM CIM: $($_.Exception.Message)$C_RESET"
    }
}

# ------------------------------------------------------------------------------
# SEÇÃO 04: SUBSISTEMA GRÁFICO & MULTI-GPU
# ------------------------------------------------------------------------------
function Audit-Gpu {
    Print-Section $TXT.SectionGpu
    try {
        Print-Sub "Detected Display Adapters:"
        $GPUs = Get-CimInstance Win32_VideoController
        foreach ($g in $GPUs) {
            Write-Out "    $C_CYAN⚡$C_RESET $C_WHITE$($g.Name)$C_RESET"
            Write-Out "       $C_DARK└─$C_RESET Driver: $($g.DriverVersion) | Res: $($g.CurrentHorizontalResolution)x$($g.CurrentVerticalResolution)"
        }
        
        # Check nvidia-smi
        $nvSmi = Get-Command nvidia-smi -ErrorAction SilentlyContinue
        if ($nvSmi) {
            Write-Out ""
            Print-Sub "NVIDIA Dedicated Status"
            $nvOut = & nvidia-smi --query-gpu=name,driver_version,memory.used,memory.total,temperature.gpu,utilization.gpu --format=csv,noheader,nounits 2>$null | Select-Object -First 1
            if ($nvOut) {
                $parts = $nvOut -split ','
                $name = $parts[0].Trim()
                $drv = $parts[1].Trim()
                $mUsed = [int]$parts[2].Trim()
                $mTot = [int]$parts[3].Trim()
                $temp = $parts[4].Trim()
                $load = $parts[5].Trim()
                $pct = [math]::Round(($mUsed / $mTot) * 100)
                
                Write-Out "    Model       : $C_WHITE$name (Driver: $drv)$C_RESET"
                Write-Out "    VRAM Usage  : $mUsed / $mTot MiB $(Render-Bar $pct)"
                Write-Out "    Core Temp   : $temp°C  ●  Core Load: $load%  ●  Fan: Dynamic ACPI"
            }
        }
    } catch {
        Write-Out "  $C_GOLD▲ Error reading GPU CIM: $($_.Exception.Message)$C_RESET"
    }
}

# ------------------------------------------------------------------------------
# SEÇÃO 05: ARMAZENAMENTO & DISCOS
# ------------------------------------------------------------------------------
function Audit-Storage {
    Print-Section $TXT.SectionStore
    try {
        Print-Sub "Mounted Drive Volumes:"
        Write-Out "    MOUNTPOINT         TYPE    SIZE      USED      AVAIL     CAPACITY"
        $Vols = Get-CimInstance Win32_LogicalDisk | Where-Object DriveType -eq 3
        foreach ($v in $Vols) {
            $TotGB = [math]::Round($v.Size / 1GB, 1)
            $FreeGB = [math]::Round($v.FreeSpace / 1GB, 1)
            $UsedGB = [math]::Round($TotGB - $FreeGB, 1)
            $Pct = [math]::Round(($UsedGB / $TotGB) * 100)
            $Bar = Render-Bar $Pct 10
            $Id = "$($v.DeviceID)\".PadRight(18)
            $Fs = ($v.FileSystem).PadRight(7)
            $Sz = ("$TotGB" + "G").PadRight(9)
            $Us = ("$UsedGB" + "G").PadRight(9)
            $Av = ("$FreeGB" + "G").PadRight(9)
            Write-Out "    $Id $Fs $Sz $Us $Av $Bar"
        }
        
        Write-Out ""
        Print-Sub "Physical Disks & S.M.A.R.T. Status:"
        $Disks = Get-PhysicalDisk -ErrorAction SilentlyContinue
        if ($Disks) {
            foreach ($d in $Disks) {
                $SzGB = [math]::Round($d.Size / 1GB, 1)
                $HealthColor = if ($d.HealthStatus -eq "Healthy") { "$C_EMERALD[✔ $($d.HealthStatus)]$C_RESET" } else { "$C_CRIMSON[✖ $($d.HealthStatus)]$C_RESET"; Record-Warn }
                Write-Out "    $C_CYAN◆$C_RESET Model: $($d.FriendlyName) ($($d.MediaType) $SzGB GB) ● Health: $HealthColor"
            }
        }
    } catch {
        Write-Out "  $C_GOLD▲ Error reading Storage: $($_.Exception.Message)$C_RESET"
    }
}

# ------------------------------------------------------------------------------
# SEÇÃO 06: TOPOLOGIA DE REDE
# ------------------------------------------------------------------------------
function Audit-Network {
    Print-Section $TXT.SectionNet
    try {
        Print-Sub "Active Network Interfaces:"
        Write-Out "    INTERFACE        STATUS     MAC ADDRESS        IP ADDRESSES"
        $Adapters = Get-NetAdapter -ErrorAction SilentlyContinue | Where-Object Status -eq "Up"
        foreach ($a in $Adapters) {
            $IPs = (Get-NetIPAddress -InterfaceIndex $a.InterfaceIndex -AddressFamily IPv4 -ErrorAction SilentlyContinue).IPAddress -join ", "
            $IfName = ($a.Name).PadRight(16)
            $Status = "$C_EMERALD" + ($a.Status.ToUpper()).PadRight(10) + "$C_RESET"
            $Mac = ($a.MacAddress).PadRight(18)
            Write-Out "    $IfName $Status $Mac $IPs"
        }
        
        $Route = Get-NetRoute -DestinationPrefix "0.0.0.0/0" -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($Route) {
            Write-Out ""
            Print-Kv "Default Gateway" $Route.NextHop
        }
        
        # Ping Test
        Write-Out ""
        Print-Sub "Live Latency Test:"
        $Ping = Test-Connection -ComputerName 1.1.1.1 -Count 1 -ErrorAction SilentlyContinue
        if ($Ping) {
            $Lat = $Ping.ResponseTime
            Write-Out "    $C_EMERALD✔ [Online] Cloudflare DNS (1.1.1.1) Latency: $Lat ms$C_RESET"
        } else {
            Write-Out "    $C_CRIMSON✖ [Offline] Target unreachable$C_RESET"
            Record-Fail
        }
    } catch {
        Write-Out "  $C_GOLD▲ Error reading Network: $($_.Exception.Message)$C_RESET"
    }
}

# ------------------------------------------------------------------------------
# SEÇÃO 07: BARRAMENTO USB & PERIFÉRICOS
# ------------------------------------------------------------------------------
function Audit-Usb {
    Print-Section $TXT.SectionUsb
    try {
        $UsbDevs = Get-PnpDevice -Class USB -Status OK -ErrorAction SilentlyContinue | Where-Object { $_.FriendlyName -notmatch "Root Hub|Host Controller" } | Select-Object -First 14
        Print-Kv "Connected USB Devices" "$($UsbDevs.Count) devices present"
        Write-Out ""
        Print-Sub "Connected Devices List:"
        foreach ($dev in $UsbDevs) {
            Write-Out "    $C_DARK├─$C_RESET $C_CYAN⚡$C_RESET $($dev.FriendlyName)"
        }
    } catch {
        Write-Out "  $C_GOLD▲ Error reading USB devices: $($_.Exception.Message)$C_RESET"
    }
}

# ------------------------------------------------------------------------------
# SEÇÃO 08: SAÚDE DO SISTEMA & LOGS DE ERRO
# ------------------------------------------------------------------------------
function Audit-Health {
    Print-Section $TXT.SectionHealth
    try {
        Print-Sub "Failed Automatic Services:"
        $FailedSvc = Get-Service -ErrorAction SilentlyContinue | Where-Object { $_.StartType -eq "Automatic" -and $_.Status -ne "Running" }
        if ($FailedSvc.Count -eq 0) {
            Write-Out "    $C_EMERALD✔ [0 FAILED SERVICES] All automatic services running optimally.$C_RESET"
        } else {
            foreach ($s in $FailedSvc) {
                Write-Out "    $C_CRIMSON✖ $($s.DisplayName) (State: $($s.Status))$C_RESET"
                Record-Fail
            }
        }
        
        Write-Out ""
        Print-Sub "Critical & Error Event Log Entries (Last 2 Hours):"
        $Events = Get-WinEvent -FilterHashtable @{LogName='System'; Level=1,2; StartTime=(Get-Date).AddHours(-2)} -MaxEvents 6 -ErrorAction SilentlyContinue
        if (-not $Events -or $Events.Count -eq 0) {
            Write-Out "    $C_EMERALD✔ No critical system error events logged recently.$C_RESET"
        } else {
            foreach ($ev in $Events) {
                $Msg = ($ev.Message -split "`r`n")[0]
                if ($Msg.Length -gt 85) { $Msg = $Msg.Substring(0, 82) + "..." }
                Write-Out "    $C_GOLD▲ [$($ev.TimeCreated.ToString('HH:mm:ss'))] $($ev.ProviderName): $Msg$C_RESET"
                Record-Warn
            }
        }
    } catch {
        Write-Out "  $C_GOLD▲ Notice reading Event Log: $($_.Exception.Message)$C_RESET"
    }
}

# ------------------------------------------------------------------------------
# SEÇÃO 09: PARECER EXECUTIVO & RESUMO DE SAÚDE
# ------------------------------------------------------------------------------
function Audit-Summary {
    Print-Section $TXT.SectionSummary
    Write-Out ""
    if ($TotalFailures -eq 0 -and $TotalWarnings -eq 0) {
        Write-Out "  $C_EMERALD$C_BOLD╔══════════════════════════════════════════════════════════════════════╗$C_RESET"
        Write-Out "  $C_EMERALD$C_BOLD║  STATUS: $($TXT.ScoreOptimal)  ║$C_RESET"
        Write-Out "  $C_EMERALD$C_BOLD╚══════════════════════════════════════════════════════════════════════╝$C_RESET"
    } elseif ($TotalFailures -eq 0) {
        Write-Out "  $C_GOLD$C_BOLD╔══════════════════════════════════════════════════════════════════════╗$C_RESET"
        Write-Out "  $C_GOLD$C_BOLD║  STATUS: $($TXT.ScoreWarn) ($TotalWarnings warnings)$C_RESET"
        Write-Out "  $C_GOLD$C_BOLD╚══════════════════════════════════════════════════════════════════════╝$C_RESET"
    } else {
        Write-Out "  $C_CRIMSON$C_BOLD╔══════════════════════════════════════════════════════════════════════╗$C_RESET"
        Write-Out "  $C_CRIMSON$C_BOLD║  STATUS: $($TXT.ScoreCrit) ($TotalFailures errors, $TotalWarnings warnings)$C_RESET"
        Write-Out "  $C_CRIMSON$C_BOLD╚══════════════════════════════════════════════════════════════════════╝$C_RESET"
    }
    Write-Out ""
    if (-not $NoLog) {
        Write-Out "  $C_SLATE Comprehensive report saved to:$C_RESET $C_CYAN$C_BOLD$LogFile$C_RESET"
    }
    if (-not $IsAdmin) {
        Write-Out "  $C_DIM Tip: Run as Administrator for full physical disk and event log telemetry.$C_RESET"
    }
    Write-Out ""
}

# ------------------------------------------------------------------------------
# EXECUÇÃO PRINCIPAL
# ------------------------------------------------------------------------------
Print-Banner
Audit-System
Audit-Cpu
Audit-Ram
Audit-Gpu
Audit-Storage
Audit-Network
Audit-Usb
Audit-Health
Audit-Summary
