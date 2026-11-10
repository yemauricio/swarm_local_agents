#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"
echo "Repo to start is at: "$ROOT" "
# Expose to local network
echo "Local network activate"
systemctl start ssh 2>/dev/null || sudo systemctl start sshd 2>/dev/null
# Python configuration
python3 -m venv .venv
source .venv/bin/activate
python -m pip install uv
uv sync
set -a; source config/agent.env; set +a
echo "Starting Ollama process"
chmod +x deploy/llm_backbone.sh 
deploy/ollama_utils.sh &
exec python -m uvicorn agent.server:app --host 0.0.0.0 --port "$PORT" --reload
