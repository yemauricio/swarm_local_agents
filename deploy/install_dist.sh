#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

ROLE="${1:-auto}"
RAM_GB="$(awk '/MemTotal/ {printf "%.0f", $2/1024/1024}' /proc/meminfo)"
CPU_CORES="$(nproc)"
GPU="none"
VRAM_GB="0"
# Assign ollama
echo "Using default Ollama backbone"
LLM_BACKBONE="ollama" 

echo "Role definition"
if command -v nvidia-smi >/dev/null 2>&1; then
  GPU="$(nvidia-smi --query-gpu=name --format=csv,noheader | head -n1 || true)"
  # Fetch raw MiB integer directly
  VRAM_MIB="$(nvidia-smi --query-gpu=memory.total --format=csv,noheader,nounits | head -n1 | tr -d ' ' || echo 0)"
  VRAM_GB=$((VRAM_MIB / 1024))
fi

# Auto-assign role
if [[ "$ROLE" == auto ]]; then
  if [[ "$VRAM_GB" -ge 8 ]]; then 
    ROLE=coordinator
  else 
    ROLE=worker
  fi
fi

case "$ROLE" in
  coordinator) 
    MODEL_FILE="${MODEL_FILE:-qwen2.5-7b-instruct-q4_k_m}"
    CONTEXT="${CONTEXT:-32000}"
    ;;
  worker) 
    if [ "$RAM_GB" -ge 6 ]; then 
      MODEL_FILE="${MODEL_FILE:-qwen2.5-3b-instruct-q4_k_m}"
      CONTEXT="${CONTEXT:-32000}"
    else 
      MODEL_FILE="${MODEL_FILE:-qwen2.5-1.5b-instruct-q4_k_m}"
      CONTEXT="${CONTEXT:-32000}"
    fi
    PORT="${PORT:-8001}"
    GPU_LAYERS="${GPU_LAYERS:-0}"
    ;;
  *) 
    echo "Usage: $0 [auto|coordinator|worker]"
    exit 
    ;;
esac

echo "Configuration ..."
NETPUB="$(ip route get 1.2.3.4 | awk -F"src " '{print $2}' | cut -d' ' -f1)"
mkdir -p runtime models agent config skills tools workspace
touch agent/__init__.py
for i in runtime models config skills tools workspace; do cp  agent/__init__.py $i; done 
# Write run config environment file
cat <<EOF > config/agent.env
ROLE=$ROLE
MODEL_FILE=$MODEL_FILE
MODEL_PATH=$ROOT/models/$MODEL_FILE
PORT=$PORT
CONTEXT=$CONTEXT
GPU_LAYERS=$GPU_LAYERS
THREADS=$CPU_CORES
LLAMA_HOST=127.0.0.1
LLAMA_PORT=11434
AGENT_NAME=$(hostname)
IP_LOCAL=$NETPUB
WORKSPACE=$ROOT/workspace
EOF

echo "Start agentic distribution"
chmod +x deploy/start_dist.sh 
echo "Installed role=$ROLE model=$MODEL_FILE port=$PORT"
bash "$ROOT/deploy/start_dist.sh" 
