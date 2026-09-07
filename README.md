<div align="center">

# ⚡ SysCheck
### Universal Enterprise System & Hardware Diagnostic Engine

[![Version](https://img.shields.io/badge/version-4.0.0-emerald.svg?style=for-the-badge&color=00e599)](https://github.com/V4mpw0L/SysCheck)
[![Platforms](https://img.shields.io/badge/platform-Linux%20%7C%20macOS%20%7C%20Windows-blue.svg?style=for-the-badge&color=2563eb)](https://github.com/V4mpw0L/SysCheck)
[![Shell](https://img.shields.io/badge/shell-Bash%20%7C%20PowerShell-orange.svg?style=for-the-badge&color=f97316)](https://github.com/V4mpw0L/SysCheck)
[![License](https://img.shields.io/badge/license-MIT-purple.svg?style=for-the-badge&color=8b5cf6)](LICENSE)
[![Studio](https://img.shields.io/badge/studio-Gennisys-black.svg?style=for-the-badge&color=111827)](https://gennisys.org)

An industrial-grade, 100% cross-platform hardware auditor and system telemetry sentinel designed for Linux workstations, macOS devices, Windows gaming rigs, and enterprise servers.

[Key Features](#-key-features) • [Platform Support](#-platform-support) • [Installation & Usage](#-installation--usage) • [CLI Manual](#-cli-manual) • [Versão em Português](#-syscheck-português)

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

* 🌐 **100% Universal Cross-Platform**: Run natively on **Linux**, **macOS (Apple Silicon & Intel)**, and **Windows (WSL, Git Bash, or native PowerShell `syscheck.ps1`)**.
* 📦 **Smart Dependency Engine & Auto-Installer**: Detects your system's package manager (`dnf`, `apt`, `pacman`, `zypper`, `apk`, `brew`, `winget`, `choco`), identifies missing diagnostic tools, and interactively prompts to install them automatically (or via `-y / --yes`).
* 🎮 **Multi-GPU Subsystem Pipeline**: Full enumeration of all onboard and dedicated display controllers (NVIDIA, AMD Radeon, Intel Iris/Xe, Apple Metal). Inspects active drivers, OpenGL core renderer, Vulkan devices, and dedicated NVIDIA VRAM bars with live clock & thermal telemetry.
* 🛡️ **S.M.A.R.T. Storage Diagnostic**: Deep inspection of NVMe, SATA, and APFS block drives via `smartctl` and native disk utilities. Monitors health, wear level percentage, operational temperatures, and power-on hours.
* 🌡️ **Thermals & Cooling Telemetry**: Real-time reading of CPU package/core temperatures, GPU thermal status, motherboard sensors, and cooling fans RPM with intelligent throttling detection.
* 📊 **Dynamic Visual Progress Bars**: ASCII capacity and allocation bars for RAM memory, Swap pools, NVIDIA VRAM, and all mounted physical filesystems (`/`, `/home`, `/boot`, drive letters).
* 🚨 **System Health & Error Sentinel**: Automatically audits failed systemd services (`systemctl --failed`), Windows services, launchd jobs, dmesg hardware events, and journal / event log errors.
* 🔒 **Dual-Tier Execution**:
  * **User Mode (Non-Root / Non-Admin)**: Non-destructive audit that safely runs without superuser privileges, gracefully falling back to user-level metrics.
  * **Privileged Mode (`sudo` / Administrator)**: Unlocks low-level hardware registers (SMART drive health, DMI BIOS/RAM timings, and kernel ring buffer).
* 🌍 **Native Bilingual Support**: Auto-detects English and Portuguese (`pt_BR`) system locales, with manual override (`--lang pt` / `--lang en`).
* 📝 **Clean Log Exports**: Produces both ANSI-colored terminal dashboards and clean plaintext logs stripped of ANSI codes for archiving.

---

## 💻 Platform Support

| Operating System | Engine Script | Recommended Command | Hardware Telemetry |
| :--- | :--- | :--- | :--- |
| **Fedora / Nobara / RHEL** | `syscheck.sh` | `sudo ./syscheck.sh` | Full DMI, SMART, Multi-GPU, Sensors, Systemd |
| **Ubuntu / Debian / Mint** | `syscheck.sh` | `sudo ./syscheck.sh` | Full DMI, SMART, Multi-GPU, Sensors, Systemd |
| **Arch / Manjaro / EndeavourOS** | `syscheck.sh` | `sudo ./syscheck.sh` | Full DMI, SMART, Multi-GPU, Sensors, Systemd |
| **macOS (Apple Silicon M1-M4)** | `syscheck.sh` | `sudo ./syscheck.sh` | Apple Silicon Chip, Metal, APFS, RAM pressure, Displays |
| **macOS (Intel Macs)** | `syscheck.sh` | `sudo ./syscheck.sh` | Machdep CPU, Displays, APFS, Network, USB |
| **Windows 10 / 11 / Server** | `syscheck.ps1` | `.\syscheck.ps1` | CIM Processor, VideoController, PhysicalMemory, EventLog |
| **Windows WSL / Git Bash** | `syscheck.sh` | `./syscheck.sh` | Cross-bridged Windows + Linux kernel telemetry |

---

## 🚀 Installation & Usage

### Linux & macOS

```bash
# 1. Clone repository
git clone https://github.com/V4mpw0L/SysCheck.git
cd SysCheck

# 2. Make executable
chmod +x syscheck.sh

# 3. Run full deep hardware audit (Root / sudo)
sudo ./syscheck.sh

# Or run non-root quick inspection:
./syscheck.sh --quick
```

### Windows (Native PowerShell)

Open PowerShell as Administrator:
```powershell
# 1. Clone or navigate to repository
cd SysCheck

# 2. Run SysCheck PowerShell engine
powershell -ExecutionPolicy Bypass -File .\syscheck.ps1

# Or with parameters:
.\syscheck.ps1 -Quick -Lang pt
```

---

## ⚙️ CLI Manual & Options

### `syscheck.sh` (Linux / macOS / WSL / Git Bash)

```text
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
```

### `syscheck.ps1` (Windows PowerShell)

```powershell
.\syscheck.ps1 [-Quick] [-NoColor] [-NoLog] [-Output <file>] [-Lang <pt|en>] [-CheckDeps] [-InstallDeps] [-Yes]
```

---

## 🇧🇷 SysCheck (Português)

O **SysCheck** é um motor industrial de diagnóstico e auditoria de hardware para servidores, estações de trabalho e computadores gamers. Desenvolvido para entregar a telemetria mais completa e refinada do ecossistema, compatível nativamente com **Linux**, **macOS** e **Windows**.

### Funcionalidades Principais:
1. **Detecção Multiplataforma Inteligente**: Identifica a distribuição Linux, versão do macOS (Apple Silicon M1-M4 ou Intel) ou compilação do Windows.
2. **Gerenciamento Automático de Dependências**: Detecta seu gerenciador de pacotes (`dnf`, `apt`, `pacman`, `zypper`, `apk`, `brew`, `winget`) e pergunta interativamente se deseja instalar ferramentas ausentes (`smartctl`, `sensors`, `lspci`, etc.).
3. **Multi-GPU Avançado**: Reconhece GPUs integradas e dedicadas simultaneamente, exibindo renderizadores OpenGL, dispositivos Vulkan, drivers de kernel e métricas de VRAM/temperatura NVIDIA.
4. **Saúde de Armazenamento S.M.A.R.T.**: Monitora unidades NVMe e SATA, porcentagem de desgaste do SSD, horas de uso e temperatura operacional.
5. **Telemetria de Refrigeração**: Medição precisa de RPM de fans da CPU e GPU, evitando superaquecimento e thermal throttling.
6. **Auditoria de Falhas no Sistema**: Varredura de serviços com falha no systemd / Windows, logs críticos do kernel (`dmesg`) e journal de eventos.

### Como Executar:

**No Linux e macOS:**
```bash
sudo ./syscheck.sh
```

**No Windows (PowerShell):**
```powershell
powershell -ExecutionPolicy Bypass -File .\syscheck.ps1
```

---

## 📜 License

Distributed under the **MIT License**. Engineered with precision by **V4mpw0L / Gennisys Studio**.
