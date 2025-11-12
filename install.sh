#!/bin/bash

# SecuryBlack Agent - Script de Instalación
# Inspirado en Tailscale: https://tailscale.com/install
# Uso: curl -fsSL https://raw.githubusercontent.com/SecuryBlack/agent-releases/main/install.sh | sudo bash

set -e

# Manejo de errores
trap 'error_exit "Error en línea $LINENO. Código de salida: $?"' ERR

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
NC='\033[0m' # No Color

# Configuración
AGENT_NAME="securyblack-agent"
INSTALL_DIR="/opt/${AGENT_NAME}"
CONFIG_DIR="/etc/${AGENT_NAME}"
LOG_DIR="/var/log/${AGENT_NAME}"
BIN_PATH="${INSTALL_DIR}/${AGENT_NAME}"
SERVICE_FILE="/etc/systemd/system/${AGENT_NAME}.service"
GITHUB_REPO="SecuryBlack/agent-releases"
GITHUB_API="https://api.github.com/repos/${GITHUB_REPO}/releases/latest"
INSTALL_LOG="/tmp/securyblack-install.log"

# Variables globales
COMPANY_KEY=""
ARCH=""
OS=""
OS_VERSION=""

# Funciones de logging
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1" | tee -a "$INSTALL_LOG"
}

log_success() {
  echo -e "${GREEN}[?]${NC} $1" | tee -a "$INSTALL_LOG"
}

log_warning() {
    echo -e "${YELLOW}[?]${NC} $1" | tee -a "$INSTALL_LOG"
}

log_error() {
    echo -e "${RED}[?]${NC} $1" | tee -a "$INSTALL_LOG"
}

log_step() {
echo -e "${MAGENTA}[STEP]${NC} $1" | tee -a "$INSTALL_LOG"
}

# Manejo de errores
error_exit() {
    log_error "$1"
    log_error "Instalación fallida. Ver log completo en: $INSTALL_LOG"
    log_info "Para reportar el problema, envía el log a support@securyblack.com"
    exit 1
}

# Limpiar archivos temporales al salir
cleanup() {
    if [ -d "/tmp/securyblack" ]; then
        rm -rf /tmp/securyblack
  fi
}
trap cleanup EXIT

# Banner
print_banner() {
    echo "" | tee -a "$INSTALL_LOG"
    echo -e "${BLUE}?????????????????????????????????????????????${NC}" | tee -a "$INSTALL_LOG"
    echo -e "${BLUE}?    SecuryBlack Agent - Instalador        ?${NC}" | tee -a "$INSTALL_LOG"
    echo -e "${BLUE}?    Version 1.0.0        ?${NC}" | tee -a "$INSTALL_LOG"
    echo -e "${BLUE}?????????????????????????????????????????????${NC}" | tee -a "$INSTALL_LOG"
    echo "" | tee -a "$INSTALL_LOG"
    log_info "Iniciando instalación - $(date)"
    log_info "Log guardado en: $INSTALL_LOG"
    echo ""
}

# Verificar que se ejecuta como root
check_root() {
    log_step "Verificando permisos de root..."
    if [ "$EUID" -ne 0 ]; then
        error_exit "Este script debe ejecutarse como root (sudo)"
    fi
    log_success "Ejecutando como root"
}

# Detectar distribución Linux
detect_os() {
    log_step "Detectando sistema operativo..."
    if [ -f /etc/os-release ]; then
    . /etc/os-release
        OS=$ID
        OS_VERSION=$VERSION_ID
        log_info "Distribución detectada: $PRETTY_NAME"
        
        # Verificar si es una distribución soportada
     case $OS in
  ubuntu|debian|centos|rhel|fedora|rocky|almalinux)
           log_success "Distribución soportada: $OS"
       ;;
            *)
 log_warning "Distribución no oficialmente soportada: $OS"
       log_warning "La instalación continuará, pero puede haber problemas"
  ;;
 esac
    else
        error_exit "No se pudo detectar la distribución Linux (/etc/os-release no encontrado)"
    fi
}

# Detectar arquitectura
detect_arch() {
    log_step "Detectando arquitectura del sistema..."
    local MACHINE_ARCH=$(uname -m)
    case $MACHINE_ARCH in
        x86_64)
          ARCH="x64"
            log_success "Arquitectura detectada: x86_64 ($ARCH)"
            ;;
        aarch64|arm64)
     ARCH="arm64"
            log_success "Arquitectura detectada: ARM64 ($ARCH)"
      ;;
*)
      error_exit "Arquitectura no soportada: $MACHINE_ARCH (solo x64 y arm64 están soportados)"
      ;;
    esac
}

# Verificar dependencias
check_dependencies() {
    log_step "Verificando dependencias del sistema..."
    
    # Verificar systemd
    if ! command -v systemctl &> /dev/null; then
        error_exit "systemd no está disponible. Este instalador requiere systemd."
    fi
    log_info "? systemd disponible"
    
    # Verificar curl
    if ! command -v curl &> /dev/null; then
        log_warning "curl no está instalado. Intentando instalar..."
      if command -v apt-get &> /dev/null; then
apt-get update -qq && apt-get install -y curl -qq
        elif command -v yum &> /dev/null; then
            yum install -y curl -q
elif command -v dnf &> /dev/null; then
       dnf install -y curl -q
      else
   error_exit "No se pudo instalar curl automáticamente. Instálalo manualmente."
        fi
        log_success "curl instalado exitosamente"
    else
    log_info "? curl disponible"
    fi
    
    # Verificar conectividad a Internet
    if ! curl -s --max-time 5 https://api.github.com > /dev/null; then
    error_exit "No hay conectividad a Internet. Verifica tu conexión."
    fi
    log_info "? Conectividad a Internet OK"
    
    log_success "Todas las dependencias verificadas"
}

# Verificar si ya está instalado
check_existing_installation() {
    log_step "Verificando instalación existente..."
    
    if [ -f "$BIN_PATH" ]; then
      log_warning "SecuryBlack Agent ya está instalado"
        echo ""
        read -p "¿Deseas reinstalar/actualizar? [y/N]: " -n 1 -r
   echo ""
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
 log_info "Instalación cancelada por el usuario"
    exit 0
        fi
     log_info "Procediendo con reinstalación..."
    else
log_info "No se encontró instalación previa"
    fi
}

# Descargar binario desde GitHub Releases
download_agent() {
    log_step "Descargando última versión del agente desde GitHub..."
    
    # Obtener información de la última release
    log_info "Consultando: $GITHUB_API"
    RELEASE_INFO=$(curl -sL "${GITHUB_API}") || error_exit "No se pudo conectar a GitHub API"
    
    if [ -z "$RELEASE_INFO" ]; then
        error_exit "No se pudo obtener información de releases"
    fi
    
    # Buscar el asset correcto para la arquitectura
    ASSET_NAME="securyblack-agent-linux-${ARCH}"
    DOWNLOAD_URL=$(echo "$RELEASE_INFO" | grep -o "\"browser_download_url\": \"[^\"]*${ASSET_NAME}[^\"]*\"" | cut -d'"' -f4 | head -n1)
    
    if [ -z "$DOWNLOAD_URL" ]; then
     log_error "Assets disponibles:"
   echo "$RELEASE_INFO" | grep "browser_download_url" | cut -d'"' -f4
        error_exit "No se encontró el binario para arquitectura: linux-${ARCH}"
    fi
    
    log_info "Descargando desde: $DOWNLOAD_URL"
    
    # Crear directorio temporal
    mkdir -p /tmp/securyblack
 
    # Descargar binario con barra de progreso
    if curl -L --progress-bar -o "/tmp/securyblack/${AGENT_NAME}" "$DOWNLOAD_URL"; then
        log_success "Binario descargado exitosamente"
    else
        error_exit "Error al descargar el binario"
  fi
    
    # Dar permisos de ejecución
    chmod +x "/tmp/securyblack/${AGENT_NAME}"
    
    # Verificar que el binario es válido
    if ! file "/tmp/securyblack/${AGENT_NAME}" | grep -q "executable"; then
      error_exit "El archivo descargado no es un binario válido"
    fi
    
    log_success "Binario verificado correctamente"
}

# Crear directorios necesarios
create_directories() {
    log_step "Creando estructura de directorios..."
    
    mkdir -p "$INSTALL_DIR" || error_exit "No se pudo crear $INSTALL_DIR"
    mkdir -p "$CONFIG_DIR" || error_exit "No se pudo crear $CONFIG_DIR"
    mkdir -p "$LOG_DIR" || error_exit "No se pudo crear $LOG_DIR"
    
    log_success "Directorios creados: $INSTALL_DIR, $CONFIG_DIR, $LOG_DIR"
}

# Crear usuario para el agente
create_user() {
    log_step "Configurando usuario del sistema..."
    
    if ! id -u securyblack &> /dev/null; then
        if useradd -r -s /bin/false -d /nonexistent securyblack 2>/dev/null; then
          log_success "Usuario 'securyblack' creado"
        else
          error_exit "No se pudo crear el usuario 'securyblack'"
        fi
    else
        log_info "Usuario 'securyblack' ya existe"
    fi
}

# Instalar binario
install_binary() {
    log_step "Instalando binario..."
    
  # Detener servicio si está corriendo
    if systemctl is-active --quiet "${AGENT_NAME}" 2>/dev/null; then
        log_info "Deteniendo servicio existente..."
        systemctl stop "${AGENT_NAME}"
    fi
    
    # Copiar binario
    if cp "/tmp/securyblack/${AGENT_NAME}" "$BIN_PATH"; then
        chown root:root "$BIN_PATH"
        chmod 755 "$BIN_PATH"
        log_success "Binario instalado en $BIN_PATH"
    else
        error_exit "No se pudo copiar el binario a $BIN_PATH"
    fi
}

# Crear archivo de configuración
create_config() {
    log_step "Creando archivo de configuración..."
    
    # Si ya existe configuración, preguntar si preservar
    if [ -f "${CONFIG_DIR}/appsettings.json" ]; then
        log_warning "Ya existe un archivo de configuración"
        read -p "¿Deseas preservar la configuración existente? [Y/n]: " -n 1 -r
echo ""
        if [[ $REPLY =~ ^[Yy]$ ]] || [[ -z $REPLY ]]; then
            log_info "Preservando configuración existente"
     return 0
        fi
    fi
    
    # Solicitar Company Key
    echo ""
    echo -e "${YELLOW}?????????????????????????????????????????????????????${NC}"
    echo -e "${YELLOW}?  Necesitas tu Company Key para continuar         ?${NC}"
    echo -e "${YELLOW}?  Obtén la desde: dashboard.securyblack.com       ?${NC}"
    echo -e "${YELLOW}?????????????????????????????????????????????????????${NC}"
    echo ""
    read -p "Ingresa tu Company Key (formato: comp_xxxxx): " COMPANY_KEY
    
    if [ -z "$COMPANY_KEY" ]; then
      log_warning "No se proporcionó Company Key"
        log_warning "Deberás configurarla manualmente en ${CONFIG_DIR}/appsettings.json"
        COMPANY_KEY=""
    else
        log_info "Company Key configurada: ${COMPANY_KEY:0:10}..."
    fi
    
    # Crear configuración - JSON corregido
    cat > "${CONFIG_DIR}/appsettings.json" <<'EOF'
{
  "Logging": {
    "LogLevel": {
      "Default": "Information",
      "Microsoft.Hosting.Lifetime": "Information",
      "agent_linux": "Information"
    }
  },
  "Agent": {
    "ApiBaseUrl": "https://api.securyblack.com",
    "CompanyKey": "",
    "Version": "1.0.0",
    "MetricsIntervalSeconds": 60,
    "UpdateCheckIntervalSeconds": 3600,
    "HealthCheckIntervalSeconds": 300,
    "UpdateRepository": "SecuryBlack/agent-releases",
    "ConfigFilePath": "/etc/securyblack-agent/config.json",
    "IsRegistered": false,
    "IsPendingApproval": false
  }
}
EOF

    # Si se proporcionó Company Key, actualizar el archivo
    if [ -n "$COMPANY_KEY" ]; then
        sed -i "s/\"CompanyKey\": \"\"/\"CompanyKey\": \"$COMPANY_KEY\"/" "${CONFIG_DIR}/appsettings.json"
    fi
    
    chown securyblack:securyblack "${CONFIG_DIR}/appsettings.json"
    chmod 600 "${CONFIG_DIR}/appsettings.json"
    
    log_success "Configuración creada en ${CONFIG_DIR}/appsettings.json"
}

# Crear servicio systemd
create_service() {
    log_step "Configurando servicio systemd..."
    
    cat > "$SERVICE_FILE" <<EOF
[Unit]
Description=SecuryBlack Monitoring Agent
Documentation=https://docs.securyblack.com
After=network-online.target
Wants=network-online.target

[Service]
Type=notify
ExecStart=${BIN_PATH}
WorkingDirectory=${INSTALL_DIR}
Environment="DOTNET_ENVIRONMENT=Production"
Environment="ASPNETCORE_URLS="
Restart=always
RestartSec=10
User=securyblack
Group=securyblack

# Logging
StandardOutput=journal
StandardError=journal
SyslogIdentifier=securyblack-agent

# Seguridad
NoNewPrivileges=true
PrivateTmp=true
ProtectSystem=strict
ProtectHome=true
ReadWritePaths=${CONFIG_DIR} ${LOG_DIR}

# Recursos
LimitNOFILE=65535
TasksMax=4096

[Install]
WantedBy=multi-user.target
EOF
    
    # Recargar systemd
    systemctl daemon-reload || error_exit "No se pudo recargar systemd"
    
    log_success "Servicio systemd configurado"
}

# Configurar permisos
set_permissions() {
    log_step "Configurando permisos de archivos..."
    
    chown -R securyblack:securyblack "$CONFIG_DIR"
    chown -R securyblack:securyblack "$LOG_DIR"
    chown root:root "$INSTALL_DIR"
    chown root:root "$BIN_PATH"
  
    log_success "Permisos configurados correctamente"
}

# Iniciar servicio
start_service() {
    log_step "Iniciando servicio SecuryBlack Agent..."
    
    systemctl enable "${AGENT_NAME}" || error_exit "No se pudo habilitar el servicio"
    systemctl start "${AGENT_NAME}" || error_exit "No se pudo iniciar el servicio"
    
    # Esperar y verificar
    sleep 3
    
    if systemctl is-active --quiet "${AGENT_NAME}"; then
     log_success "Servicio iniciado exitosamente"
    else
        log_error "El servicio no está activo"
 log_error "Ver logs con: journalctl -u ${AGENT_NAME} -n 50"
        systemctl status "${AGENT_NAME}" --no-pager || true
        error_exit "El servicio falló al iniciar"
    fi
}

# Mostrar información post-instalación
show_post_install_info() {
    echo "" | tee -a "$INSTALL_LOG"
    echo -e "${GREEN}?????????????????????????????????????????????????????????????${NC}"
    echo -e "${GREEN}?         ? Instalación completada exitosamente!           ?${NC}"
    echo -e "${GREEN}?????????????????????????????????????????????????????????????${NC}"
    echo ""
    echo -e "${BLUE}?? Ubicaciones importantes:${NC}"
    echo "   • Binario:        $BIN_PATH"
    echo "   • Configuración:  ${CONFIG_DIR}/appsettings.json"
    echo "   • Logs:           ${LOG_DIR}/"
    echo "   • Log instalación: $INSTALL_LOG"
    echo ""
    echo -e "${BLUE}?? Comandos útiles:${NC}"
    echo "   • Ver estado:     sudo systemctl status ${AGENT_NAME}"
    echo "   • Ver logs:       sudo journalctl -u ${AGENT_NAME} -f"
    echo "   • Reiniciar:      sudo systemctl restart ${AGENT_NAME}"
    echo "   • Detener:        sudo systemctl stop ${AGENT_NAME}"
    echo "   • Desinstalar:    curl -fsSL https://raw.githubusercontent.com/SecuryBlack/agent-releases/main/uninstall.sh | sudo bash"
    echo ""
    echo -e "${YELLOW}? Próximos pasos:${NC}"
  echo "   1. El agente está esperando aprobación desde el dashboard"
    echo "   2. Inicia sesión en https://dashboard.securyblack.com"
  echo "   3. Ve a 'Servidores' ? 'Pendientes'"
  echo "   4. Aprueba este servidor: $(hostname)"
    echo "   5. El agente comenzará a enviar métricas automáticamente"
    echo ""
  echo -e "${BLUE}?? Tip:${NC} Monitorea los logs mientras esperas aprobación:"
    echo "   sudo journalctl -u ${AGENT_NAME} -f"
    echo ""
}

# Función principal
main() {
    print_banner
    check_root
    detect_os
    detect_arch
    check_dependencies
    check_existing_installation
    download_agent
  create_directories
  create_user
    install_binary
    create_config
    create_service
    set_permissions
    start_service
    show_post_install_info
 
    log_info "Instalación completada - $(date)"
}

# Ejecutar instalación
main "$@"
