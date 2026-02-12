#!/usr/bin/env bash
set -euo pipefail

# ============================================================
# 01-install-deps.sh
# Installs: Docker, k3d, kubectl, helm
# Tested on: Ubuntu 24.04 LTS
# ============================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../.env"

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log()  { echo -e "${GREEN}[✓]${NC} $*"; }
warn() { echo -e "${YELLOW}[!]${NC} $*"; }

# ------ Docker ------
if command -v docker &>/dev/null; then
    log "Docker already installed: $(docker --version)"
else
    warn "Installing Docker..."
    curl -fsSL https://get.docker.com | sh
    systemctl enable --now docker
    log "Docker installed: $(docker --version)"
fi

# Ensure docker runs without issues
docker info &>/dev/null || { echo "ERROR: Docker daemon not running"; exit 1; }

# ------ kubectl ------
if command -v kubectl &>/dev/null; then
    log "kubectl already installed: $(kubectl version --client --short 2>/dev/null || kubectl version --client)"
else
    warn "Installing kubectl..."
    KUBECTL_VERSION=$(curl -sL https://dl.k8s.io/release/stable.txt)
    curl -fsSL "https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/amd64/kubectl" -o /usr/local/bin/kubectl
    chmod +x /usr/local/bin/kubectl
    log "kubectl installed: ${KUBECTL_VERSION}"
fi

# ------ Helm ------
if command -v helm &>/dev/null; then
    log "Helm already installed: $(helm version --short)"
else
    warn "Installing Helm..."
    curl -fsSL https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
    log "Helm installed: $(helm version --short)"
fi

# ------ k3d ------
if command -v k3d &>/dev/null; then
    log "k3d already installed: $(k3d version)"
else
    warn "Installing k3d..."
    curl -fsSL https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | bash
    log "k3d installed: $(k3d version)"
fi

echo ""
log "All dependencies installed successfully!"
echo "  Docker:  $(docker --version)"
echo "  kubectl: $(kubectl version --client 2>&1 | head -1)"
echo "  Helm:    $(helm version --short)"
echo "  k3d:     $(k3d version | head -1)"
