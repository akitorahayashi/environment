# CodeRabbit Role

The `coderabbit` role installs the CodeRabbit CLI so you can request AI reviews from the terminal.

## Tag
- `coderabbit`

Execute with `just coderabbit`. Included in `just common`.

## Tasks
- Ensure `~/.ansible/tmp` exists.
- Download `https://cli.coderabbit.ai/install.sh` with a pinned SHA-256 checksum to prevent tampering.
- Run the installer via `/bin/bash`, which places the binary in `~/.local/bin/coderabbit`.
- Remove the temporary installer script after installation.

Re-run the role whenever CodeRabbit releases a new installer or the checksum changes.
