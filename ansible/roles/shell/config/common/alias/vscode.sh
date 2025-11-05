#!/bin/bash
alias co="code"
alias co-r="code --reuse-window"
alias co-n="code --new-window"

# Generate .code-workspace file in current dir
# Usage: co-w ../path1 /abs/path2
alias co-w='gen_vscode_workspace.py'
