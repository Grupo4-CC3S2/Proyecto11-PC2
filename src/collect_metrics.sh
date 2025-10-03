#!/usr/bin/env bash
set -euo pipefail

# Verificar que TARGETS esté definido
if [[ -z "${TARGETS:-}" ]]; then
    echo "Error: variable TARGETS no definida" >&2
    exit 5
fi

# Configuración
BUDGET_MS=${BUDGET_MS:-500}  
SAMPLES=${SAMPLES:-10}        

# Crear directorio de salida si no existe
mkdir -p out

TIMESTAMP=$(date +%Y%m%d_%H%M%S)
OUTPUT_FILE="out/metrics-raw-${TIMESTAMP}.csv"

# Header del CSV
echo "endpoint,timestamp,latency_ms,http_code,status,sample_number,budget_exceeded" > "$OUTPUT_FILE"

echo "Recolectando $SAMPLES muestras por endpoint con budget de ${BUDGET_MS}ms"

# Procesar cada endpoint
IFS=',' read -ra ENDPOINTS <<< "$TARGETS"
for endpoint in "${ENDPOINTS[@]}"; do
    # Remover espacios en blanco
    endpoint=$(echo "$endpoint" | xargs)
    
    echo "Procesando endpoint: $endpoint"
    
    # Recolectar n muestras para este endpoint
    for sample in $(seq 1 $SAMPLES); do
        ts=$(date -u +%Y-%m-%dT%H:%M:%SZ)
        
        # Ejecutar curl y capturar métricas
        http_code=0
        time_total=0
        status="FAILED"
        budget_exceeded="false"
        
        if curl_output=$(curl -w "%{http_code}|%{time_total}" -o /dev/null -s --max-time 10 "$endpoint" 2>&1); then
            http_code=$(echo "$curl_output" | cut -d'|' -f1)
            time_total=$(echo "$curl_output" | cut -d'|' -f2)
            
            latency_ms=$(echo "$time_total" | awk '{printf "%.0f", $1 * 1000}')
            
            # Verificar si excede el budget
            if [[ $latency_ms -gt $BUDGET_MS ]]; then
                budget_exceeded="true"
            fi
            
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
            budget_exceeded="false"
        fi
        
        # Escribir línea al CSV
        echo "$endpoint,$ts,$latency_ms,$http_code,$status,$sample,$budget_exceeded" >> "$OUTPUT_FILE"
        
        # Log en consola (cada 5 muestras para no saturar)
        if [[ $((sample % 5)) -eq 0 ]] || [[ $sample -eq 1 ]] || [[ $sample -eq $SAMPLES ]]; then
            budget_status=""
            if [[ "$budget_exceeded" == "true" ]]; then
                budget_status=" [BUDGET EXCEDIDO]"
            fi
            echo "  Muestra $sample/$SAMPLES: $http_code ($latency_ms ms) - $status$budget_status"
        fi
        
        # Pequeña pausa entre muestras para no saturar el servidor
        sleep 0.1
    done
    
    echo " Completadas $SAMPLES muestras para $endpoint"
    echo
done

echo "Métricas guardadas en: $OUTPUT_FILE"
echo "Total de registros: $((${#ENDPOINTS[@]} * SAMPLES))"
exit 0