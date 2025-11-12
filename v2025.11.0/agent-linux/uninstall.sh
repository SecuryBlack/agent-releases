#!/bin/bash

# SecuryBlack Agent - Script de Desinstalación
# Uso: curl -fsSL https://install.securyblack.com/uninstall.sh | sudo bash

set -e

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuración
AGENT_NAME="securyblack-agent"
INSTALL_DIR="/opt/${AGENT_NAME}"
CONFIG_DIR="/etc/${AGENT_NAME}"
LOG_DIR="/var/log/${AGENT_NAME}"
SERVICE_FILE="/etc/systemd/system/${AGENT_NAME}.service"

# Funciones de logging
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[OK]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Banner
print_banner() {
    echo ""
    echo -e "${RED}?????????????????????????????????????????????${NC}"
    echo -e "${RED}?  SecuryBlack Agent - Desinstalador       ?${NC}"
    echo -e "${RED}?????????????????????????????????????????????${NC}"
    echo ""
}

# Verificar que se ejecuta como root
check_root() {
    if [ "$EUID" -ne 0 ]; then
        log_error "Este script debe ejecutarse como root (sudo)"
        exit 1
    fi
    log_success "Ejecutando como root"
}

# Confirmar desinstalación
confirm_uninstall() {
    echo ""
    read -p "$(echo -e ${YELLOW}¿Estás seguro de que deseas desinstalar SecuryBlack Agent? [y/N]:${NC} )" -n 1 -r
  echo ""
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log_info "Desinstalación cancelada"
        exit 0
    fi
}

# Detener servicio
stop_service() {
    log_info "Deteniendo servicio..."
    
    if systemctl is-active --quiet "${AGENT_NAME}"; then
        systemctl stop "${AGENT_NAME}"
        log_success "Servicio detenido"
    else
        log_info "El servicio no estaba en ejecución"
    fi
}

# Deshabilitar servicio
disable_service() {
    log_info "Deshabilitando servicio..."
    
    if systemctl is-enabled --quiet "${AGENT_NAME}"; then
systemctl disable "${AGENT_NAME}"
        log_success "Servicio deshabilitado"
    else
        log_info "El servicio no estaba habilitado"
 fi
}

# Eliminar servicio systemd
remove_service() {
    log_info "Eliminando servicio systemd..."
    
    if [ -f "$SERVICE_FILE" ]; then
        rm -f "$SERVICE_FILE"
    systemctl daemon-reload
        log_success "Servicio systemd eliminado"
    else
        log_info "Archivo de servicio no encontrado"
    fi
}

# Eliminar binario y directorios
remove_files() {
    log_info "Eliminando archivos..."
    
    # Preguntar si desea conservar los logs
    echo ""
    read -p "$(echo -e ${YELLOW}¿Deseas conservar los logs? [y/N]:${NC} )" -n 1 -r
    echo ""
    KEEP_LOGS=$REPLY
    
    # Eliminar directorio de instalación
    if [ -d "$INSTALL_DIR" ]; then
        rm -rf "$INSTALL_DIR"
        log_success "Directorio de instalación eliminado"
  fi
 
    # Eliminar directorio de configuración
    if [ -d "$CONFIG_DIR" ]; then
        rm -rf "$CONFIG_DIR"
      log_success "Directorio de configuración eliminado"
    fi
    
    # Eliminar logs si se solicitó
    if [[ ! $KEEP_LOGS =~ ^[Yy]$ ]] && [ -d "$LOG_DIR" ]; then
     rm -rf "$LOG_DIR"
        log_success "Directorio de logs eliminado"
else
        log_info "Logs conservados en: $LOG_DIR"
    fi
}

# Eliminar usuario
remove_user() {
    log_info "Eliminando usuario del sistema..."
  
    if id -u securyblack &> /dev/null; then
        userdel securyblack
        log_success "Usuario 'securyblack' eliminado"
    else
        log_info "Usuario 'securyblack' no existe"
    fi
}

# Mostrar información post-desinstalación
show_post_uninstall_info() {
    echo ""
    echo -e "${GREEN}?????????????????????????????????????????????????????????????${NC}"
    echo -e "${GREEN}?        Desinstalación completada exitosamente!     ?${NC}"
    echo -e "${GREEN}?????????????????????????????????????????????????????????????${NC}"
    echo ""
    echo -e "${BLUE}? El agente SecuryBlack ha sido completamente eliminado${NC}"
    echo ""
    echo -e "${YELLOW}Nota:${NC} El servidor todavía aparecerá en tu dashboard."
    echo "   Puedes eliminarlo manualmente desde la interfaz web."
    echo ""
    echo -e "${BLUE}Para reinstalar:${NC}"
    echo "   curl -fsSL https://install.securyblack.com/agent.sh | sudo bash"
    echo ""
}

# Función principal
main() {
    print_banner
    check_root
    confirm_uninstall
    stop_service
    disable_service
  remove_service
    remove_files
    remove_user
    show_post_uninstall_info
}

# Ejecutar desinstalación
main
