#!/bin/bash
set -e

echo "=== Garabu - Vercel Build Script ==="

# Clone Flutter SDK if not present
if [ ! -d "$HOME/flutter" ] && [ ! -d "_flutter" ]; then
  echo "=== Clonando Flutter SDK (stable) ==="
  git clone https://github.com/flutter/flutter.git --depth 1 -b stable _flutter
  export PATH="$PATH:$(pwd)/_flutter/bin"
elif [ -d "_flutter" ]; then
  echo "=== Flutter SDK encontrado localmente en _flutter ==="
  export PATH="$PATH:$(pwd)/_flutter/bin"
elif [ -d "$HOME/flutter" ]; then
  echo "=== Flutter SDK encontrado en HOME ==="
  export PATH="$PATH:$HOME/flutter/bin"
fi

echo "=== Configurando Flutter SDK ==="
flutter config --no-analytics
flutter --version

echo "=== Obteniendo dependencias de Garabu ==="
flutter pub get

echo "=== Compilando Garabu para Web (Release) ==="
flutter build web --release

echo "=== Compilación exitosa en build/web ==="
