# SecuryBlack Agent - Linux Releases

This repository contains pre-compiled binaries for the SecuryBlack Linux Agent.

## Installation

```bash
curl -fsSL https://raw.githubusercontent.com/SecuryBlack/agent-releases/main/install.sh | sudo bash
```

## Uninstallation

```bash
curl -fsSL https://raw.githubusercontent.com/SecuryBlack/agent-releases/main/uninstall.sh | sudo bash
```

## Releases

All releases with compiled binaries are available in the [Releases](https://github.com/SecuryBlack/agent-releases/releases) page.

### Supported Architectures
- x64 (Intel/AMD 64-bit)
- arm64 (ARM 64-bit)

## Verification

Each release includes SHA256 checksums. Verify the binary integrity:

```bash
sha256sum -c securyblack-agent-linux-x64.sha256
sha256sum -c securyblack-agent-linux-arm64.sha256
```

## Source Code

The source code is available at: https://github.com/SecuryBlack/SecuryBlack

## Documentation

For more information, visit: https://docs.securyblack.com
