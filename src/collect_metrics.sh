#!/usr/bin/env bash
set -euo pipefail

# Verificar que TARGETS esté definido
if [[ -z "${TARGETS:-}" ]]; then
    echo "Error: variable TARGETS no definida" >&2
    exit 5
fi

# Crear directorio de salida si no existe
mkdir -p out

TIMESTAMP=$(date +%Y%m%d_%H%M%S)
OUTPUT_FILE="out/metrics-raw-${TIMESTAMP}.csv"

# Header del CSV
echo "endpoint,timestamp,latency_ms,http_code,status" > "$OUTPUT_FILE"

# Procesar cada endpoint
IFS=',' read -ra ENDPOINTS <<< "$TARGETS"
for endpoint in "${ENDPOINTS[@]}"; do
    # Remover espacios en blanco
    endpoint=$(echo "$endpoint" | xargs)
    
    ts=$(date -u +%Y-%m-%dT%H:%M:%SZ)
    
    # Ejecutar curl y capturar métricas
    http_code=0
    time_total=0
    status="FAILED"
    
    if curl_output=$(curl -w "%{http_code}|%{time_total}" -o /dev/null -s --max-time 10 "$endpoint" 2>&1); then
        http_code=$(echo "$curl_output" | cut -d'|' -f1)
        time_total=$(echo "$curl_output" | cut -d'|' -f2)
        
        latency_ms=$(echo "$time_total" | awk '{printf "%.0f", $1 * 1000}')
        
        # Determinar status según código HTTP
        if [[ "$http_code" -ge 200 && "$http_code" -lt 300 ]]; then
            status="SUCCESS"
        elif [[ "$http_code" -ge 400 && "$http_code" -lt 500 ]]; then
            status="CLIENT_ERROR"
        elif [[ "$http_code" -ge 500 ]]; then
            status="SERVER_ERROR"
        fi
    else
        # Error de red o timeout
        status="NETWORK_ERROR"
        http_code=0
        latency_ms=0
    fi
    
    # Escribir línea al CSV
    echo "$endpoint,$ts,$latency_ms,$http_code,$status" >> "$OUTPUT_FILE"
    
    # Log en consola
    echo "$endpoint -> $http_code ($latency_ms ms) - $status"
done

echo "Métricas guardadas en: $OUTPUT_FILE"
exit 0