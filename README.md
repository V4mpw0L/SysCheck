# 💻 SysCheck

This repository contains a robust and comprehensive Bash script designed to perform a detailed hardware and software diagnosis on Linux systems, with a focus on troubleshooting specific issues.

The script gathers a wide range of system information, including details about the CPU, GPU, storage, RAM, network devices, and system logs, to help users and technicians identify potential problems.

---

## ✨ Features

* **Comprehensive Diagnostics**: Collects detailed information on critical hardware components (CPU, GPU, RAM, SSD/HDD, etc.).
* **Log Analysis**: Scans system logs (`dmesg` and `journalctl`) for critical errors.
* **Hardware Health Checks**: Runs SMART diagnostics on SSDs to check their health status.
* **Temperature Monitoring**: Reports CPU and GPU temperatures to detect overheating issues.
* **Internationalization (i18n)**: Automatically detects system language and displays messages in either English or Portuguese.
* **Robust and Safe**: The script is read-only and does not make any changes to the system. It includes checks and fallbacks to prevent errors.
* **Detailed Output**: Generates a verbose log file for easy analysis.

---

## 🚀 How to Use

1.  **Clone the Repository**:
    ```bash
    git clone [https://github.com/V4mpw0L/SysCheck.git](https://github.com/V4mpw0L/SysCheck.git)
    cd SysCheck
    ```

2.  **Make the Script Executable**:
    ```bash
    chmod +x syscheck.sh
    ```

3.  **Run the Script with Root Privileges**:
    This is required to access detailed hardware information and system logs.
    ```bash
    sudo ./syscheck.sh
    ```

After execution, the script will generate a detailed log file named `syscheck_YYYYMMDD_HHMMSS.log` in the same directory. You can then open this file to review the full report.

---

## 🤝 Contributing

Contributions are welcome! If you find a bug or have an idea for an improvement, please open an issue or submit a pull request.

**Ideas for Improvement:**
* Add support for more languages.
* Include more specific tests for different hardware manufacturers (e.g., AMD, Dell).
* Implement a function to check for BIOS updates.

---

## 📄 License

This project is licensed under the [MIT License](LICENSE).

---
---

# 💻 SysCheck

Este repositório contém um script Bash robusto e abrangente, projetado para realizar um diagnóstico detalhado de hardware e software em sistemas Linux, com foco na solução de problemas específicos.

O script coleta uma vasta gama de informações do sistema, incluindo detalhes sobre CPU, GPU, armazenamento, RAM, dispositivos de rede e logs do sistema, para ajudar usuários e técnicos a identificar possíveis problemas.

---

## ✨ Funcionalidades

* **Diagnóstico Abrangente**: Coleta informações detalhadas sobre componentes de hardware críticos (CPU, GPU, RAM, SSD/HDD, etc.).
* **Análise de Logs**: Varre os logs do sistema (`dmesg` e `journalctl`) em busca de erros críticos.
* **Verificações de Saúde do Hardware**: Executa diagnósticos SMART em SSDs para verificar a integridade do disco.
* **Monitoramento de Temperatura**: Relata as temperaturas da CPU e GPU para detectar problemas de superaquecimento.
* **Internacionalização (i18n)**: Detecta automaticamente o idioma do sistema e exibe as mensagens em português ou inglês.
* **Robusto e Seguro**: O script é de apenas leitura e não faz nenhuma alteração no sistema. Ele inclui verificações e "fallbacks" para evitar erros.
* **Saída Detalhada**: Gera um arquivo de log completo para facilitar a análise.

---

## 🚀 Como Usar

1.  **Clone o Repositório**:
    ```bash
    git clone [https://github.com/V4mpw0L/SysCheck.git](https://github.com/V4mpw0L/SysCheck.git)
    cd SysCheck
    ```

2.  **Torne o Script Executável**:
    ```bash
    chmod +x syscheck.sh
    ```

3.  **Execute o Script com Permissões de Root**:
    Isso é necessário para acessar informações detalhadas de hardware e logs do sistema.
    ```bash
    sudo ./syscheck.sh
    ```

Após a execução, o script irá gerar um arquivo de log detalhado, com o nome `syscheck_AAAA-MM-DD_HHMMSS.log`, no mesmo diretório. Você pode então abrir este arquivo para revisar o relatório completo.

---

## 🤝 Contribuições

Contribuições são bem-vindas! Se você encontrar um bug ou tiver uma ideia de melhoria, por favor, abra uma "issue" ou envie um "pull request".

**Ideias para Melhoria:**
* Adicionar suporte para mais idiomas.
* Incluir testes mais específicos para diferentes fabricantes de hardware (ex: AMD, Dell).
* Implementar uma função para verificar a existência de atualizações da BIOS.

---

## 📄 Licença

Este projeto está licenciado sob a [Licença MIT](LICENSE).
