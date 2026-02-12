#!/usr/bin/env bash
set -euo pipefail

# ============================================================
# 03-install-argocd.sh
# Installs ArgoCD via Helm on k3d cluster
# Exposes UI on NodePort 31443
# ============================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"
source "${ROOT_DIR}/.env"

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log()  { echo -e "${GREEN}[✓]${NC} $*"; }
warn() { echo -e "${YELLOW}[!]${NC} $*"; }

# Add Argo Helm repo
warn "Adding Argo Helm repository..."
helm repo add argo https://argoproj.github.io/argo-helm 2>/dev/null || true
helm repo update

# Install ArgoCD
warn "Installing ArgoCD..."
helm upgrade --install argocd argo/argo-cd \
    --namespace argocd \
    --create-namespace \
    --set server.service.type=NodePort \
    --set server.service.nodePortHttp=31443 \
    --set server.service.nodePortHttps=31444 \
    --set dex.enabled=false \
    --set notifications.enabled=false \
    --set server.extensions.enabled=true \
    --set configs.params."server\.insecure"=true \
    --wait \
    --timeout 300s

# Wait for ArgoCD server to be ready
warn "Waiting for ArgoCD server..."
kubectl wait --for=condition=Available deployment/argocd-server \
    -n argocd --timeout=180s

# Get initial admin password
ARGOCD_PASSWORD=$(kubectl -n argocd get secret argocd-initial-admin-secret \
    -o jsonpath="{.data.password}" 2>/dev/null | base64 -d || echo "")

if [[ -z "$ARGOCD_PASSWORD" ]]; then
    warn "Initial admin secret not found, ArgoCD may use the password from Helm values"
    ARGOCD_PASSWORD="(check helm values or argocd-initial-admin-secret)"
fi

# Install ArgoCD CLI
if ! command -v argocd &>/dev/null; then
    warn "Installing ArgoCD CLI..."
    curl -sSL -o /usr/local/bin/argocd \
        "https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64"
    chmod +x /usr/local/bin/argocd
    log "ArgoCD CLI installed"
fi

echo ""
log "ArgoCD is ready!"
echo ""
echo "  UI:       http://localhost:31443"
echo "  Username: admin"
echo "  Password: ${ARGOCD_PASSWORD}"
echo ""
echo "  To login via CLI:"
echo "    argocd login localhost:31443 --insecure --username admin --password '${ARGOCD_PASSWORD}'"
echo ""

# Save password to .env if not already there
if ! grep -q "ARGOCD_INITIAL_PASSWORD" "${ROOT_DIR}/.env" 2>/dev/null; then
    echo "" >> "${ROOT_DIR}/.env"
    echo "# ArgoCD (auto-generated)" >> "${ROOT_DIR}/.env"
    echo "ARGOCD_INITIAL_PASSWORD=${ARGOCD_PASSWORD}" >> "${ROOT_DIR}/.env"
    log "Password saved to .env"
fi
