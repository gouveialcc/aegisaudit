#!/bin/bash

# ======================================================================
# FERRAMENTA: AegisAudit
# DESCRIÇÃO: Auditoria de Segurança, Integridade e Postura de Ativos
# ======================================================================

# --- Cores ANSI para exibição no Terminal (Cyber Blue & Steel) ---
NC='\033[0m'               # Sem Cor
CYBER_BLUE='\033[38;5;39m'  # Azul Ciano Vibrante
STEEL_GRAY='\033[38;5;244m' # Cinza Metálico
SUCCESS_GREEN='\033[32m'    # Verde Oliva
ALERT_YELLOW='\033[33m'     # Amarelo Âmbar
CRITICAL_RED='\033[31m'     # Vermelho Carmim

# --- Configurações de Arquivo ---
HOSTNAME=$(hostname)
DATE=$(date +'%Y-%m-%d_%H-%M')
LOG_FILE_RAW="/tmp/aegisaudit_${HOSTNAME}_${DATE}.raw"
LOG_FILE="/tmp/aegisaudit_${HOSTNAME}_${DATE}.log"

# Garante que o script está rodando como Root
if [ "$EUID" -ne 0 ]; then
    echo -e "${CRITICAL_RED}[X] ERRO: O AegisAudit precisa ser executado como ROOT ou via SUDO.${NC}" >&2
    exit 1
fi

echo -e "${CYBER_BLUE}======================================================================${NC}"
echo -e "${CYBER_BLUE}      🛡️  Iniciando AegisAudit - Auditoria de Integridade de Ativos      ${NC}"
echo -e "${CYBER_BLUE}======================================================================${NC}"
echo -e "${STEEL_GRAY}Alvo:${NC} $HOSTNAME | ${STEEL_GRAY}Data:${NC} $(date)"
echo "----------------------------------------------------------------------"

{
    echo "======================================================================"
    echo "AEGISAUDIT - RELATÓRIO DE AUDITORIA E SEGURANÇA - $HOSTNAME"
    echo "DATA DA EXTRAÇÃO: $(date)"
    echo "======================================================================"

    echo -e "\n[🛡️ 1] IDENTIFICAÇÃO DO ATIVO E SISTEMA OPERACIONAL"
    echo "----------------------------------------------------------------------"
    [ -f /etc/os-release ] && grep -E "^PRETTY_NAME|^ID=|^VERSION=" /etc/os-release | sed 's/"//g'
    uname -a
    echo "Tempo de atividade (Uptime): $(uptime -p)"
    command -v timedatectl &> /dev/null && timedatectl | grep -E "Time zone|System clock synchronized" || echo "timedatectl não disponível."

    echo -e "\n[⚙️ 2] CAPACIDADE E PERFORMANCE (DISCO, CPU, RAM)"
    echo "----------------------------------------------------------------------"
    echo "--- CPU ---"
    if command -v lscpu &> /dev/null; then
        lscpu | grep -E "Model name|Socket\(s\)|Core\(s\) per socket|Thread\(s\) per core"
    else
        grep "model name" /proc/cpuinfo | head -n 1
    fi
    echo -e "\n--- Memória RAM ---"
    free -h
    echo -e "\n--- Espaço em Disco ---"
    df -hT -x tmpfs -x devtmpfs 2>/dev/null | column -t || df -h
    echo -e "\n--- Processos Críticos (Top 10 CPU) ---"
    ps -eo pcpu,pid,user,args --sort=-pcpu | head -n 11

    echo -e "\n[🛡️ 3] SEGURANÇA DE ENDPOINT E MALWARE (CLAMAV)"
    echo "----------------------------------------------------------------------"
    if command -v clamscan &> /dev/null; then
        clamscan --version
        echo "Status das definições de vírus:"
        ls -lh /var/lib/clamav/*.cvd /var/lib/clamav/*.cld 2>/dev/null | awk '{print $9, "Modificado em:", $6, $7}' || echo "Base de dados não encontrada."
    else
        echo "ALERTA: Antivírus ClamAV não instalado."
    fi

    echo -e "\n[🔍 4] GESTÃO DE VULNERABILIDADES E ATUALIZAÇÕES"
    echo "----------------------------------------------------------------------"
    echo "--- Última Instalação de Segurança Realizada ---"
    if [ -f /etc/fedora-release ] || [ -f /etc/redhat-release ]; then
        dnf history list security 2>/dev/null | head -n 5 || echo "Sem histórico de segurança dnf disponível."
        echo -e "\n--- Atualizações Pendentes ---"
        dnf updateinfo summary 2>/dev/null || echo "Não foi possível coletar sumário do dnf."
    elif [ -f /etc/debian_version ] || [ -f /etc/lsb-release ]; then
        grep "Packages that will be upgraded" /var/log/unattended-upgrades/unattended-upgrades.log 2>/dev/null | tail -n 1 || echo "Sem logs recentes de unattended-upgrades."
        echo -e "\n--- Atualizações Pendentes ---"
        if [ -f /usr/lib/update-notifier/apt-check ]; then
            /usr/lib/update-notifier/apt-check --human-readable 2>/dev/null
        else
            apt-get -s upgrade | grep -E "^[0-9]+ upgraded" || echo "Não foi possível verificar via APT."
        fi
    fi

    echo -e "\n[🔑 5] CONTROLE DE ACESSO E LOGINS (ÚLTIMOS 10 DIAS)"
    echo "----------------------------------------------------------------------"
    echo "--- Usuários com Privilégio Root (UID 0) ---"
    grep -E '^[^:]+:[^:]+:0:' /etc/passwd | cut -d: -f1
    echo -e "\n--- Logins com Sucesso ---"
    last --since "-10 days" 2>/dev/null | grep -v "wtmp begins" | head -n 20
    echo -e "\n--- Tentativas de Login com FALHA ---"
    lastb --since "-10 days" 2>/dev/null | grep -v "btmp begins" | head -n 20 || echo "Sem registros de falhas ou btmp inacessível."

    echo -e "\n[🌐 6] INTEGRIDADE DO SISTEMA E REDE"
    echo "----------------------------------------------------------------------"
    echo "--- Portas em Escuta e Conexões Ativas ---"
    ss -tunap 2>/dev/null | grep -E 'LISTEN|ESTAB' | column -t || ss -tuna
    echo -e "\n--- Alterações em Configurações (/etc nos últimos 10 dias) ---"
    find /etc -type f -mtime -10 -printf "%TY-%Tm-%Td %TH:%TM | %p\n" 2>/dev/null | sort -r | head -n 20
    echo -e "\n--- Arquivos com Permissão de Escrita Mundial em /tmp e /var/tmp ---"
    find /tmp /var/tmp -type f -perm -0002 -ls 2>/dev/null

    echo -e "\n[📋 7] LOGS DE EVENTOS E ERROS CRÍTICOS (10 DIAS)"
    echo "----------------------------------------------------------------------"
    echo "--- Erros do Kernel/Sistema ---"
    if command -v journalctl &> /dev/null; then
        journalctl -p 3 --since "-10 days" --reverse --no-pager --output=short-iso 2>/dev/null | head -n 20
    else
        tail -n 50 /var/log/syslog /var/log/messages 2>/dev/null | grep -E "error|fail|critical" | head -n 20
    fi
    
    if command -v docker &> /dev/null && command -v journalctl &> /dev/null; then
        echo -e "\n--- Eventos de Ciclo de Vida Docker ---"
        journalctl -u docker --since "-10 days" --reverse --no-pager --output=short-iso 2>/dev/null | \
        grep -E "start|stop|restart|destroy|die|create" | head -n 20
    fi

} > "$LOG_FILE_RAW"

# --- Interface em tempo de execução (Console do Administrador) ---
echo -e "Extaindo [1/7] - Identificação do Ativo...       ${SUCCESS_GREEN}[OK]${NC}"
sleep 0.2
echo -e "Coletando [2/7] - Capacidade e Performance...     ${SUCCESS_GREEN}[OK]${NC}"
sleep 0.2
echo -e "Analisando [3/7] - Endpoint e Antivírus...        ${SUCCESS_GREEN}[OK]${NC}"
sleep 0.2
echo -e "Verificando [4/7] - Vulnerabilidades/Pacotes...   ${SUCCESS_GREEN}[OK]${NC}"
sleep 0.2
echo -e "Avaliando [5/7] - Controle de Acessos...         ${SUCCESS_GREEN}[OK]${NC}"
sleep 0.2
echo -e "Escaneando [6/7] - Integridade e Portas...        ${SUCCESS_GREEN}[OK]${NC}"
sleep 0.2
echo -e "Processando [7/7] - Eventos Críticos do Kernel... ${SUCCESS_GREEN}[OK]${NC}"
sleep 0.2

# Limpa caracteres ANSI do log final para garantir leitura limpa em editores de texto (.log)
sed -r "s/\x1B\[([0-9]{1,3}(;[0-9]{1,2})?)?[mGK]//g" "$LOG_FILE_RAW" > "$LOG_FILE"
rm -f "$LOG_FILE_RAW"

echo "----------------------------------------------------------------------"
echo -e "${SUCCESS_GREEN}✓ AegisAudit executado com sucesso!${NC}"
echo -e "${STEEL_GRAY}Relatório gerado em:${NC} ${CYBER_BLUE}$LOG_FILE${NC}"
echo "----------------------------------------------------------------------"
