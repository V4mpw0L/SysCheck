<div align="center">

# ⚡ SysCheck
### Enterprise System & Hardware Diagnostic Engine

[![Version](https://img.shields.io/badge/version-4.0.0-emerald.svg?style=for-the-badge&color=00e599)](https://github.com/V4mpw0L/SysCheck)
[![Platform](https://img.shields.io/badge/platform-Linux-blue.svg?style=for-the-badge&color=2563eb)](https://www.kernel.org/)
[![Shell](https://img.shields.io/badge/shell-Bash_5.0+-orange.svg?style=for-the-badge&color=f97316)](https://www.gnu.org/software/bash/)
[![License](https://img.shields.io/badge/license-MIT-purple.svg?style=for-the-badge&color=8b5cf6)](LICENSE)
[![Studio](https://img.shields.io/badge/studio-Gennisys-black.svg?style=for-the-badge&color=111827)](https://gennisys.org)

An industrial-grade, non-destructive hardware auditor and system telemetry sentinel designed for Linux workstations, gaming rigs, and enterprise nodes.

[Key Features](#-key-features) • [Installation & Usage](#-installation--usage) • [CLI Manual](#-cli-manual) • [Versão em Português](#-syscheck-português)

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

* 🎮 **Multi-GPU Subsystem Pipeline**: Full enumeration of all onboard and dedicated display controllers (NVIDIA, AMD Radeon, Intel Iris/Xe). Inspects active kernel drivers, OpenGL core renderer versions, Vulkan devices, and dedicated NVIDIA VRAM bars with live clock & thermal telemetry.
* 🛡️ **S.M.A.R.T. Storage Diagnostic**: Deep inspection of NVMe and SATA block drives via `smartctl`. Monitors drive health, percentage used / endurance wear, power-on hours, operational temperatures, and error logs.
* 🌡️ **Thermals & Cooling Telemetry**: Real-time reading of CPU package/core temperatures, GPU thermal status, motherboard sensors, and cooling fans RPM with intelligent throttling detection.
* 📊 **Dynamic Visual Progress Bars**: ASCII capacity and allocation bars for RAM memory, Swap pools, NVIDIA VRAM, and all mounted physical filesystems (`/`, `/home`, `/boot`).
* 🚨 **Systemd & Kernel Error Sentinel**: Automatically audits failed systemd services (`systemctl --failed`), detects hardware MCE events, kernel panics in `dmesg`, and extracts critical systemd journal priority errors.
* 🌐 **Network Topology & Latency Benchmarks**: Audits network interfaces (MAC addresses, IPv4/IPv6, link state), default gateway, configured DNS resolvers, and runs instantaneous ICMP latency tests.
* 🔒 **Dual-Tier Execution**:
  * **User Mode (Non-Root)**: Non-destructive audit that safely runs without superuser privileges, gracefully reporting unprivileged access.
  * **Root Mode (`sudo`)**: Unlocks low-level hardware registers (SMART drive health, DMI BIOS/RAM timings, and kernel ring buffer).
* 🌍 **Native Bilingual Support**: Auto-detects English and Portuguese (`pt_BR`) system locales, with manual override (`--lang pt` / `--lang en`).
* 📝 **Clean Log Exports**: Produces both ANSI-colored terminal dashboards and clean plaintext logs stripped of ANSI codes for archiving.

---

## 🚀 Installation & Usage

### 1. Clone the Repository
```bash
git clone https://github.com/V4mpw0L/SysCheck.git
cd SysCheck
```

### 2. Make the Script Executable
```bash
chmod +x syscheck.sh
```

### 3. Check Dependencies
```bash
./syscheck.sh --check-deps
```
If any tools are missing, install them automatically:
```bash
sudo ./syscheck.sh --install-deps
```

### 4. Run the Audit

* **Full Deep Audit (Recommended)**:
  ```bash
  sudo ./syscheck.sh
  ```

* **Quick User Mode Audit**:
  ```bash
  ./syscheck.sh --quick
  ```

---

## 📖 CLI Manual

```text
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
```

---
---

<div align="center">

# 💻 SysCheck (Português)
### Motor Corporativo de Diagnóstico de Hardware & Sistema

</div>

O **SysCheck** é um motor de auditoria de hardware e diagnóstico de sistema projetado pela **Gennisys Studio** para identificar com rapidez e precisão gargalos, anomalias de temperatura, falhas de serviços e saúde dos componentes em distribuições Linux.

---

## ✨ Recursos Principais

* **Pipeline Gráfico Multi-GPU**: Detecção completa de placas integradas e dedicadas (NVIDIA, AMD, Intel). Exibe driver de kernel em uso, renderizador OpenGL/Mesa, dispositivos Vulkan e métricas detalhadas da GPU NVIDIA (alocação de VRAM, temperatura e ventoinhas).
* **Diagnóstico S.M.A.R.T. de Discos**: Varredura profunda em unidades NVMe e SATA via `smartctl`. Monitora status de saúde, vida útil gasta (desgaste de SSD), horas de funcionamento e temperatura.
* **Telemetria Térmica & Ventiladores**: Monitoramento contínuo da temperatura da CPU (com alertas visuais de estrangulamento térmico), GPU e RPM das ventoinhas de resfriamento.
* **Barra Visual Dinâmica**: Gráficos de barra em ASCII com alertas graduais por cor para RAM, Swap, VRAM e sistemas de arquivos montados.
* **Sentinela de Falhas & Logs**: Identificação imediata de serviços systemd caídos (`systemctl --failed`), erros críticos no kernel (`dmesg`) e falhas prioritárias no journal.
* **Execução em Dois Níveis**:
  * **Modo Usuário (Sem root)**: Inspeção ágil e segura sem permissões administrativas.
  * **Modo Privilegiado (`sudo`)**: Acesso irrestrito aos controladores SMART, BIOS/DMI e buffers restritos do kernel.
* **Internacionalização Automática**: Detecta o idioma do sistema (Português ou Inglês) automaticamente ou permite forçar via `--lang pt`.
* **Exportação Limpa de Relatórios**: Gera relatórios em texto puro sem artefatos de cores ANSI, ideais para análise técnica e arquivamento.

---

## 🚀 Como Executar

```bash
# Diagnóstico completo com privilégios de root (recomendado para SMART e DMI)
sudo ./syscheck.sh

# Diagnóstico rápido em modo usuário
./syscheck.sh --quick

# Forçar exibição em Português
sudo ./syscheck.sh --lang pt

# Verificar ferramentas instaladas
./syscheck.sh --check-deps
```

---

## 📄 Licença

Distribuído sob a licença **MIT**. Consulte o arquivo [LICENSE](LICENSE) para obter mais informações.

<div align="center">
  <sub>Forged with precision by <strong>V4mpw0L</strong> / <strong>Gennisys Studio</strong></sub>
</div>
