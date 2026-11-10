#!/bin/bash
set -e
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"
echo "Start Ollama"
export OLLAMA_DEBUG=1

if command -v systemctl &> /dev/null && systemctl is-active --quiet ollama; then
    echo "Started and serving correctly"
elif command -v ollama &> /dev/null; then
    echo "Ollama installed but needs to be execute it"
    ollama start &> workspace/ollama.logs &
    echo "Sarted"
else
    echo "Unable to start"
    exit 1
fi