#!/usr/bin/env bash
set -euo pipefail

# ============================================================
# 02-create-cluster.sh
# Creates k3d cluster: 1 server + 3 agents
# Config: infrastructure/k3d-cluster.yaml
# ============================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"
source "${ROOT_DIR}/.env"

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

log()  { echo -e "${GREEN}[✓]${NC} $*"; }
warn() { echo -e "${YELLOW}[!]${NC} $*"; }
err()  { echo -e "${RED}[✗]${NC} $*"; exit 1; }

CLUSTER_NAME="${K3D_CLUSTER_NAME:-mlops}"

# Check if cluster already exists
if k3d cluster list 2>/dev/null | grep -q "${CLUSTER_NAME}"; then
    warn "Cluster '${CLUSTER_NAME}' already exists."
    read -rp "Delete and recreate? [y/N] " answer
    if [[ "$answer" =~ ^[Yy]$ ]]; then
        k3d cluster delete "${CLUSTER_NAME}"
        log "Old cluster deleted"
    else
        echo "Aborted."
        exit 0
    fi
fi

# Create shared volume directories
warn "Creating shared volume directories..."
mkdir -p /tmp/k3d-mlops/{data,models,experiments,cache}

# Create cluster from config
warn "Creating k3d cluster '${CLUSTER_NAME}' (1 server + 3 agents)..."
k3d cluster create --config "${ROOT_DIR}/infrastructure/k3d-cluster.yaml"

# Wait for nodes to be ready
warn "Waiting for all nodes to be Ready..."
kubectl wait --for=condition=Ready nodes --all --timeout=120s

echo ""
log "Cluster '${CLUSTER_NAME}' is ready!"
echo ""
kubectl get nodes -o wide
echo ""

# Show cluster info
echo "--- Cluster Info ---"
echo "  API Server:    https://localhost:6443"
echo "  HTTP Ingress:  http://localhost:8080"
echo "  HTTPS Ingress: https://localhost:8443"
echo "  Registry:      k3d-mlops-registry.localhost:5555"
echo ""
log "kubeconfig is set. 'kubectl' is ready to use."
