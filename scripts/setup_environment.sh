#!/bin/bash

# Environment setup script for Gestao de Estoque PRO
# - Checks required tools
# - Installs backend dependencies
# - Prepares environment variables
# - Installs Flutter dependencies and runs diagnostics

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"
BACKEND_DIR="$ROOT_DIR/backend"
FRONTEND_DIR="$ROOT_DIR/frontend"

# Tool checks
for tool in node npm flutter; do
    if ! command -v "$tool" > /dev/null 2>&1; then
        echo "❌ $tool não encontrado. Instale $tool antes de continuar." >&2
        exit 1
    fi
done

echo "📦 Instalando dependências do backend..."
cd "$BACKEND_DIR"
npm install

if [ ! -f .env ] && [ -f .env.example ]; then
    echo "🔧 Criando arquivo .env a partir do exemplo..."
    cp .env.example .env
fi

cd "$FRONTEND_DIR"
echo "📦 Baixando dependências do Flutter..."
flutter pub get

echo "🩺 Verificando ambiente Flutter..."
flutter doctor -v

echo "✅ Configuração concluída."
