#!/usr/bin/env bash
set -euo pipefail

# ============================================================
# 04-install-fake-gpu.sh
# Registers nvidia.com/gpu extended resource on training nodes
# via Kubernetes API PATCH (no operator needed in k3d)
# NOTE: Resources reset on node restart — re-run this script
# ============================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"
source "${ROOT_DIR}/.env"

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log()  { echo -e "${GREEN}[✓]${NC} $*"; }
warn() { echo -e "${YELLOW}[!]${NC} $*"; }

CLUSTER_NAME="${K3D_CLUSTER_NAME:-mlops}"
GPU_COUNT=1
TRAINING_NODES=("agent-0" "agent-1")

warn "Starting kubectl proxy..."
kubectl proxy --port=8099 &
PROXY_PID=$!
sleep 2

trap "kill ${PROXY_PID} 2>/dev/null" EXIT

for node in "${TRAINING_NODES[@]}"; do
    NODE_NAME="k3d-${CLUSTER_NAME}-${node}"
    warn "Patching ${NODE_NAME} with ${GPU_COUNT} fake GPU(s)..."

    curl -s --header "Content-Type: application/json-patch+json" \
        --request PATCH \
        --data "[{\"op\": \"add\", \"path\": \"/status/capacity/nvidia.com~1gpu\", \"value\": \"${GPU_COUNT}\"}]" \
        "http://localhost:8099/api/v1/nodes/${NODE_NAME}/status" > /dev/null

    log "${NODE_NAME}: ${GPU_COUNT} GPU(s) registered"
done

echo ""
log "Fake GPU registration complete!"
echo ""
kubectl get nodes -o custom-columns='NAME:.metadata.name,GPU:.status.capacity.nvidia\.com/gpu'
