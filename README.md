<div align="center">

# ⚡ SysCheck
### Universal Enterprise System & Hardware Diagnostic Engine

[![Version](https://img.shields.io/badge/version-4.0.0-00e599.svg?style=for-the-badge)](https://github.com/V4mpw0L/SysCheck)
[![Platforms](https://img.shields.io/badge/platform-Linux%20%7C%20macOS%20%7C%20Windows-2563eb.svg?style=for-the-badge)](https://github.com/V4mpw0L/SysCheck)
[![Shell](https://img.shields.io/badge/shell-Bash%20%7C%20PowerShell-f97316.svg?style=for-the-badge)](https://github.com/V4mpw0L/SysCheck)
[![License](https://img.shields.io/badge/license-MIT-8b5cf6.svg?style=for-the-badge)](LICENSE)
[![Studio](https://img.shields.io/badge/studio-Gennisys-111827.svg?style=for-the-badge)](https://gennisys.org)

An industrial-grade, 100% cross-platform hardware auditor and system telemetry sentinel designed for Linux workstations, macOS devices, Windows gaming rigs, and enterprise servers.

[Key Features](#-key-features) • [Diagnostic Pipeline](#-diagnostic-pipeline) • [Platform Support](#-platform-support) • [Installation & Usage](#-installation--usage) • [CLI Manual](#-cli-manual) • [Dependencies](#-dependency-matrix) • [Versão em Português](#-syscheck-português)

</div>

---

```
  ███████╗██╗   ██╗███████╗ ██████╗██╗  ██╗███████╗ ██████╗██╗  ██╗
  ██╔════╝╚██╗ ██╔╝██╔════╝██╔════╝██║  ██║██╔════╝██╔════╝██║ ██╔╝
  ███████╗ ╚████╔╝ ███████╗██║     ███████║█████╗  ██║     █████╔╝ 
  ╚════██║  ╚██╔╝  ╚════██║██║     ██╔══██║██╔══╝  ██║     ██╔═██╗ 
  ███████║   ██║   ███████║╚██████╗██║  ██║███████╗╚██████╗██║  ██╗
  ╚══════╝   ╚═╝   ╚══════╝ ╚═════╝╚═╝  ╚═╝╚══════╝ ╚═════╝╚═╝  ╚═╝

  ENTERPRISE SYSTEM & HARDWARE DIAGNOSTIC ENGINE [v4.0.0]
  Gennisys Studio  ●  Infrastructure & Hardware Audit
```

---

## ⚡ Key Features

* 🌐 **100% Universal Cross-Platform**: Run natively on **Linux**, **macOS (Apple Silicon M1-M4 & Intel)**, and **Windows (Native PowerShell `syscheck.ps1`, WSL, or Git Bash)**.
* 📦 **Smart Dependency Engine & Auto-Installer**: Automatically detects package managers (`dnf`, `apt`, `pacman`, `zypper`, `apk`, `brew`, `winget`, `choco`), audits missing diagnostic tools, and interactively offers to install them (or via `-y / --yes`).
* 🎮 **Multi-GPU Subsystem Pipeline**: Enumerate all onboard and dedicated display controllers (NVIDIA, AMD Radeon, Intel Iris/Xe, Apple Metal). Inspects active kernel drivers, OpenGL core renderer, Vulkan devices, and dedicated NVIDIA VRAM bars with live clock & thermal telemetry.
* 🛡️ **S.M.A.R.T. Storage Diagnostic**: Deep inspection of NVMe, SATA, and APFS block drives via `smartctl` and native disk utilities. Monitors health status, wear level percentage, operational temperatures, and power-on hours.
* 🌡️ **Thermals & Cooling Telemetry**: Real-time reading of CPU package/core temperatures, GPU thermal status, motherboard sensors, and cooling fans RPM with intelligent throttling detection.
* 📊 **Dynamic Visual Progress Bars**: ASCII capacity and allocation bars for RAM memory, Swap pools, NVIDIA VRAM, and all mounted physical filesystems (`/`, `/home`, `/boot`, drive letters).
* 🚨 **System Health & Error Sentinel**: Automatically audits failed systemd services (`systemctl --failed`), Windows services, launchd jobs, dmesg hardware events, and journal / event log errors.
* 🔒 **Dual-Tier Execution**:
  * **User Mode (Non-Root / Non-Admin)**: Non-destructive audit that safely runs without superuser privileges, gracefully falling back to user-level metrics.
  * **Privileged Mode (`sudo` / Administrator)**: Unlocks low-level hardware registers (SMART drive health, DMI BIOS/RAM timings, and kernel ring buffer).
* 🌍 **Native Bilingual Support**: Auto-detects English and Portuguese (`pt_BR`) system locales, with manual override (`--lang pt` / `--lang en`).
* 📝 **Clean Log Exports**: Produces both ANSI-colored terminal dashboards and clean plaintext logs stripped of ANSI codes for archiving.

---

## 🔬 Diagnostic Pipeline

SysCheck executes a structured 10-stage diagnostic sequence:

| Stage | Section | Description |
| :--- | :--- | :--- |
| **00** | **Platform Discovery & Toolchain Sentinel** | Identifies OS architecture, kernel, package manager, and probes diagnostic binary availability (`smartctl`, `sensors`, `lspci`, `lscpu`, etc.). |
| **01** | **System & Firmware Information** | Hostname, uptime, motherboard model, BIOS/UEFI version, chassis type, desktop environment, and display server (Wayland / X11). |
| **02** | **Processor & Performance** | Model, microarchitecture, topology (sockets, cores, threads), scaling governor, frequency limits, cache hierarchy (L1/L2/L3), CPU package temperatures, and fan RPM. |
| **03** | **Physical & Virtual Memory** | Total, used, free, cache/buffers with visual progress bar; Swap pool utilization; DMI hardware DIMM slots (locator, type, speed, manufacturer, part number). |
| **04** | **Graphics Subsystem Pipeline** | Enumeration of all PCI display controllers, active kernel drivers, OpenGL renderer & version, Vulkan physical devices, and NVIDIA GPU telemetry (VRAM bar, temperature, fan %, power, clocks). |
| **05** | **Block Storage & S.M.A.R.T. Health** | Physical drive list (model, size, transport); deep SMART health assessment, wear level / endurance, power-on hours, operational temperatures; mounted filesystem partition bars. |
| **06** | **Network Interfaces & Routing** | Physical and virtual adapters (IPv4, IPv6, MAC, state UP/DOWN, speed, duplex); default gateway routing and active DNS nameservers. |
| **07** | **USB Bus & Peripherals** | Hierarchical or enumerated USB bus topology, vendor IDs, device IDs, and peripheral descriptions. |
| **08** | **System Health & Event Logs** | Scans for failed systemd services, hardware errors in kernel ring buffer (`dmesg`), critical journal logs, thermal throttle events, and OOM issues. |
| **09** | **Executive Health Summary** | Aggregated count of warnings and critical failures, overall system health verdict (`PASSED`, `ATTENTION`, or `CRITICAL`), and path to saved log report. |

---

## 💻 Platform Support

| Operating System | Engine Script | Recommended Command | Telemetry Features |
| :--- | :--- | :--- | :--- |
| **Fedora / Nobara / RHEL** | `syscheck.sh` | `sudo ./syscheck.sh` | Full DMI, SMART NVMe/SATA, Multi-GPU, Sensors, Systemd, Fans |
| **Ubuntu / Debian / Mint** | `syscheck.sh` | `sudo ./syscheck.sh` | Full DMI, SMART NVMe/SATA, Multi-GPU, Sensors, Systemd, Fans |
| **Arch / Manjaro / EndeavourOS** | `syscheck.sh` | `sudo ./syscheck.sh` | Full DMI, SMART NVMe/SATA, Multi-GPU, Sensors, Systemd, Fans |
| **openSUSE / Alpine / Other Linux** | `syscheck.sh` | `sudo ./syscheck.sh` | Modular fallback, zypper/apk package management |
| **macOS (Apple Silicon M1-M4)** | `syscheck.sh` | `sudo ./syscheck.sh` | Apple Silicon Chip, Metal GPU, APFS, RAM pressure, Displays |
| **macOS (Intel Macs)** | `syscheck.sh` | `sudo ./syscheck.sh` | Machdep CPU, Displays, APFS, Network, USB |
| **Windows 10 / 11 / Server** | `syscheck.ps1` | `.\syscheck.ps1` | Native PowerShell CIM/WMI, PhysicalMemory, VideoController, EventLog |
| **Windows WSL / Git Bash** | `syscheck.sh` | `./syscheck.sh` | Cross-bridged Windows + Linux kernel telemetry |

---

## 🚀 Installation & Usage

### Linux & macOS

```bash
# 1. Clone repository
git clone https://github.com/V4mpw0L/SysCheck.git
cd SysCheck

# 2. Make script executable
chmod +x syscheck.sh

# 3. Run full privileged audit (Recommended)
sudo ./syscheck.sh

# Or run non-root quick diagnosis:
./syscheck.sh --quick
```

### Windows (Native PowerShell)

Open PowerShell as Administrator:
```powershell
# 1. Clone or navigate to directory
cd SysCheck

# 2. Run SysCheck native PowerShell engine
powershell -ExecutionPolicy Bypass -File .\syscheck.ps1

# Or with specific parameters:
.\syscheck.ps1 -Quick -Lang pt
```

---

## ⚙️ CLI Manual & Options

### `syscheck.sh` (Linux / macOS / WSL / Git Bash)

```text
Usage: ./syscheck.sh [OPTIONS]

Options:
  -h, --help             Show this manual and exit
  -v, --version          Display script version
  -q, --quick            Quick diagnosis (skips deep SMART drive logs & dmesg trace)
      --check-deps       Verify required and optional diagnostic dependencies
      --install-deps     Attempt to install missing dependencies via system package manager
  -y, --yes              Auto-confirm installation of missing dependencies
      --no-deps-prompt   Skip interactive prompt for missing dependencies
      --no-color         Disable ANSI color output
      --no-log           Do not write log file to disk
  -o, --output FILE      Specify custom path for the generated log report
      --lang <code>      Set language explicitly: "en" (English) or "pt" (Português)
```

### `syscheck.ps1` (Windows PowerShell)

```powershell
.\syscheck.ps1 [-Quick] [-NoColor] [-NoLog] [-Output <file>] [-Lang <pt|en>] [-CheckDeps] [-InstallDeps] [-Yes]
```

---

## 📦 Dependency Matrix

SysCheck operates standalone with core POSIX utilities, but unlocks deeper hardware registers when auxiliary tools are present:

| Diagnostic Feature | Required Tool | Fedora / RHEL | Ubuntu / Debian | Arch Linux | macOS (Homebrew) |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **S.M.A.R.T. Drives** | `smartctl` | `smartmontools` | `smartmontools` | `smartmontools` | `smartmontools` |
| **CPU / Fan Sensors** | `sensors` | `lm_sensors` | `lm-sensors` | `lm_sensors` | *Native sysctl* |
| **PCI / GPU Detection**| `lspci` | `pciutils` | `pciutils` | `pciutils` | *Native system_profiler* |
| **USB Bus Topology** | `lsusb` | `usbutils` | `usbutils` | `usbutils` | *Native system_profiler* |
| **DMI BIOS / RAM Slots**| `dmidecode` | `dmidecode` | `dmidecode` | `dmidecode` | *Native system_profiler* |
| **OpenGL Graphics** | `glxinfo` | `mesa-demos` | `mesa-utils` | `mesa-utils` | *Native system_profiler* |
| **Vulkan Subsystem** | `vulkaninfo` | `vulkan-tools` | `vulkan-tools` | `vulkan-tools` | *Native MoltenVK* |

> [!TIP]
> SysCheck's built-in **Toolchain Sentinel** can automatically detect your package manager and install any missing packages using `--install-deps` or interactively at launch.

---

## 🇧🇷 SysCheck (Português)

O **SysCheck** é um motor industrial de auditoria e telemetria de hardware para servidores, estações de trabalho e computadores de alta performance. Desenvolvido para entregar o diagnóstico mais detalhado, estético e confiável, compatível nativamente com **Linux**, **macOS** e **Windows**.

### Funcionalidades Principais:
1. **Detecção Multiplataforma Inteligente**: Identifica a distribuição Linux, versão do macOS (Apple Silicon M1-M4 ou Intel) ou compilação do Windows.
2. **Gerenciamento Automático de Dependências**: Detecta seu gerenciador de pacotes (`dnf`, `apt`, `pacman`, `zypper`, `apk`, `brew`, `winget`) e pergunta interativamente se deseja instalar ferramentas ausentes (`smartctl`, `sensors`, `lspci`, etc.).
3. **Multi-GPU Subsystem**: Reconhece GPUs integradas e dedicadas simultaneamente, exibindo renderizadores OpenGL, dispositivos Vulkan, drivers de kernel e métricas de VRAM/temperatura/fans NVIDIA.
4. **Saúde de Armazenamento S.M.A.R.T.**: Monitora unidades NVMe e SATA, porcentagem de desgaste do SSD, horas de uso e temperatura operacional.
5. **Telemetria de Refrigeração**: Medição de RPM de fans da CPU e GPU, identificando riscos de superaquecimento e thermal throttling.
6. **Auditoria de Falhas no Sistema**: Varredura de serviços com falha no systemd / Windows, logs críticos do kernel (`dmesg`) e journal de eventos.
7. **Relatórios Limpos**: Gera arquivos `.log` com texto limpo (sem códigos de escape ANSI) prontos para arquivamento e suporte técnico.

### Como Executar:

**No Linux e macOS:**
```bash
sudo ./syscheck.sh
```

**No Windows (PowerShell Administrador):**
```powershell
powershell -ExecutionPolicy Bypass -File .\syscheck.ps1
```

---

## 📜 License

Distributed under the **MIT License**. Engineered with precision by **V4mpw0L / Gennisys Studio**.
