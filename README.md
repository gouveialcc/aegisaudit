# 🛡️ AegisAudit

O **AegisAudit** é uma ferramenta leve e automatizada em Shell Script voltada para a auditoria de segurança, integridade e postura de ativos em sistemas Linux. Projetada para administradores de sistemas e equipes de SecOps, ela consolida diagnósticos essenciais de endpoint, acessos, redes e vulnerabilidades em um relatório consolidado e limpo.

O script foi desenvolvido com a paleta **Cyber Blue & Steel**, oferecendo um feedback visual dinâmico no terminal durante a execução, enquanto exporta um relatório final livre de códigos ANSI (perfeito para ingestão em ferramentas de logs ou leitura em qualquer editor de texto).

---

## ✨ Principais Recursos

A ferramenta executa uma varredura abrangente dividida em 7 blocos estruturados:

1. **🛡️ Identificação do Ativo e OS:** Coleta informações detalhadas de distribuição (via `os-release`), versão do Kernel, Uptime e sincronização de relógio (`timedatectl`).
2. **⚙️ Capacidade e Performance:** Visão rápida de hardware (CPU, RAM, Espaço em Disco) e lista dos 10 processos que mais consomem recursos.
3. **🛡️ Segurança de Endpoint:** Validação do status de instalação e data de atualização das definições de vírus do **ClamAV**.
4. **🔍 Gestão de Vulnerabilidades:** Histórico de patches de segurança e inventário de atualizações pendentes (compatível com sistemas baseados em **Debian/Ubuntu** e **Fedora/RHEL**).
5. **🔑 Controle de Acesso:** Auditoria de usuários com privilégios de `root` (UID 0), histórico de logins bem-sucedidos e tentativas de login com falha (`lastb`) nos últimos 10 dias.
6. **🌐 Integridade de Rede e Sistema:** Mapeamento de portas em escuta (`ss`), modificações recentes de arquivos de configuração em `/etc` e busca por arquivos com permissão de escrita mundial em diretórios temporários.
7. **📋 Eventos e Erros Críticos:** Filtragem de erros de nível crítico do Kernel (`journalctl -p 3`) e rastreamento do ciclo de vida de containers **Docker** nos últimos 10 dias.

---

## 🚀 Como Executar

### Pré-requisitos
Por acessar arquivos restritos do sistema (como logs de falhas de login e portas de rede associadas a processos), o script **exige privilégios de superusuário (root)**.

### Instalação Rápida
1. Clone o repositório ou baixe o script diretamente:
   git clone [https://github.com/gouveialcc/aegisaudit.git)
   cd AegisAudit

Dê permissão de execução ao script:
chmod +x aegisaudit.sh

Execute a ferramenta utilizando sudo:
sudo ./aegisaudit.sh

📊 Output da Ferramenta
Visualização no Terminal (Interface Executiva)
Durante a execução, o painel exibe o progresso estilizado em tempo real:

Plaintext
======================================================================
      🛡️  Iniciando AegisAudit - Auditoria de Integridade de Ativos      
======================================================================
Alvo: server-prod-01 | Data: Sex Jul  3 09:12:00 -03 2026
----------------------------------------------------------------------
Extraindo [1/7] - Identificação do Ativo...       [OK]
Coletando [2/7] - Capacidade e Performance...     [OK]
Analisando [3/7] - Endpoint e Antivírus...        [OK]
Verificando [4/7] - Vulnerabilidades/Pacotes...   [OK]
Avaliando [5/7] - Controle de Acessos...         [OK]
Escaneando [6/7] - Integridade e Portas...        [OK]
Processando [7/7] - Eventos Críticos do Kernel... [OK]
----------------------------------------------------------------------
✓ AegisAudit executado com sucesso!
Relatório gerado em: /tmp/aegisaudit_server-prod-01_2026-07-03_09-12.log
----------------------------------------------------------------------
Arquivo de Log Gerado
O relatório final é salvo em /tmp/ com a convenção de nomenclatura aegisaudit_[HOSTNAME]_[DATA].log. Ele é estruturado em blocos textuais limpos com divisórias, facilitando buscas rápidas (grep) por anomalias.

⚙️ Customização
O script é altamente portável e auto-contido. Se você precisar alterar o diretório de saída do relatório, basta modificar a variável inicial no código:
LOG_FILE="/var/log/aegisaudit_${HOSTNAME}_${DATE}.log"

💙 Apoie este Projeto Open Source
Se este software te ajudou, considere fazer uma contribuição para ajudar a manter o desenvolvimento ativo e as atualizações de segurança:

⚡ Pix (Brasil)
Use a chave aleatória abaixo no aplicativo do seu banco: a850f586-0189-4867-bae3-93830e58dcff

₿ Bitcoin
Envie qualquer valor para o endereço oficial do projeto: bc1qr5ka6pjhtkh4rk7k4tgppy3k7svksa2nllr560wrvsjgskz3lm5qxy7f6p

Toda contribuição é opcional, direcionada integralmente à sustentabilidade técnica da ferramenta e altamente apreciada!
