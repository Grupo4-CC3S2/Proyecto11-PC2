#!/usr/bin/env bash
set -euo pipefail

# Variables con valores por defecto
: "${DOMAIN:=${DOMAIN:-localhost}}"
: "${PORT:=${PORT:-8080}}"
: "${SALUD_URL:=${SALUD_URL:-http://${DOMAIN}:${PORT}/salud}}"

OUT_DIR="out"


# Chequeo de DNS
echo "Resolviendo A para ${DOMAIN}..."
if getent hosts "$DOMAIN" | awk '{print $1}' > "${OUT_DIR}/dns.txt"; then
  if [[ -s "${OUT_DIR}/dns.txt" ]]; then
    echo "DNS OK: $(cat "${OUT_DIR}/dns.txt" | head -n1)"
  else
    echo "Error: no se obtuvo respuesta DNS para ${DOMAIN}" >&2
    exit 4
  fi
else
  echo "Error al ejecutar dig" >&2
  exit 4
fi

# Chequeo de puerto
echo "Verificando si hay proceso escuchando en puerto ${PORT}..."
if ss -tlnp | grep -q ":${PORT} "; then
  ss -tlnp | grep ":${PORT} " > "${OUT_DIR}/port.txt"
  echo "Puerto ${PORT} en escucha"
else
  echo "Error: no hay proceso escuchando en puerto ${PORT}" >&2
  exit 3
fi

# Chequeo http de endpoint de salud
echo "Probando endpoint de salud en ${SALUD_URL}..."
if curl -fsSi -m 5 "$SALUD_URL" -o "${OUT_DIR}/salud.txt"; then
  echo "Endpoint /salud respondió correctamente"
else
  echo "Error: endpoint /salud no respondió" >&2
  exit 5
fi

echo "Chequeos completados. Resultados en carpeta '${OUT_DIR}/'."
