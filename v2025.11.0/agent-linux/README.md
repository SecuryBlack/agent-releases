# SecuryBlack Agent v2025.11.0

Agente de monitorizaci�n para servidores Linux.

## ?? Instalaci�n R�pida

```bash
curl -fsSL https://install.securyblack.com/agent.sh | sudo bash
```

## ?? Archivos en esta Release

| Archivo | Descripci�n | Tama�o |
|---------|-------------|--------|
| `install.sh` | Script de instalaci�n | - |
| `uninstall.sh` | Script de desinstalaci�n | - |
| `securyblack-agent-linux-x64` | Binario para x86_64 | 19.19 MB |
| `securyblack-agent-linux-arm64` | Binario para ARM64 | 18.68 MB |
| `*.sha256` | Checksums para verificaci�n | - |

## ?? Verificar Integridad

```bash
# Descargar checksum
curl -fsSL https://github.com/SecuryBlack/agent-releases/releases/download/v2025.11.0/securyblack-agent-linux-x64.sha256 -o checksum.txt

# Verificar
sha256sum -c checksum.txt
```

## ?? Requisitos del Sistema

- Ubuntu 20.04+ / Debian 10+ / CentOS 8+
- systemd
- 128 MB RAM
- 100 MB disco

## ?? Documentaci�n

- [Gu�a de Instalaci�n](https://docs.securyblack.com/agent/install)
- [Troubleshooting](https://docs.securyblack.com/agent/troubleshooting)
- [API Docs](https://docs.securyblack.com/api)

## ?? Changelog

Ver `RELEASE_NOTES.md` para detalles de esta versi�n.
