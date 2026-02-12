#!/usr/bin/env bash
set -euo pipefail

# ============================================================
# 00-setup-all.sh
# Runs all setup scripts in order.
# Usage: bash scripts/00-setup-all.sh
# ============================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "=========================================="
echo " MLOps Training Platform - Full Setup"
echo "=========================================="
echo ""

bash "${SCRIPT_DIR}/01-install-deps.sh"
echo ""
echo "------------------------------------------"
echo ""

bash "${SCRIPT_DIR}/02-create-cluster.sh"
echo ""
echo "------------------------------------------"
echo ""

bash "${SCRIPT_DIR}/03-install-argocd.sh"
echo ""
echo "------------------------------------------"
echo ""

bash "${SCRIPT_DIR}/04-install-fake-gpu.sh"
echo ""
echo "=========================================="
echo " Setup Complete!"
echo "=========================================="
