#!/usr/bin/env bash
set -euo pipefail

# Configuración
SLA_FILE=${SLA_FILE:-"docs/sla.csv"}
INPUT_FILE=${1:-$(ls -t out/metrics-raw-*.csv | head -n 1)}

if [[ ! -f "$SLA_FILE" ]]; then
    echo "Error: no se encuentra SLA_FILE ($SLA_FILE)" >&2
    exit 5
fi

if [[ ! -f "$INPUT_FILE" ]]; then
    echo "Error: no se encuentra archivo de métricas ($INPUT_FILE)" >&2
    exit 6
fi

OUTPUT_FILE="${INPUT_FILE}.results"

echo "SLA: $SLA_FILE | métricas: $INPUT_FILE | Generando reporte: $OUTPUT_FILE"

# Encabezado del archivo de salida
echo "endpoint,p50_ms,p95_ms,p99_ms,expected_code,observed_code,estado_final" > "$OUTPUT_FILE"

# Flag global de fallo
fallo_global=0

# Procesar cada endpoint definido en SLA_FILE (saltando header)
while IFS=',' read -r endpoint p50_budget p95_budget p99_budget expected_code required_field; do

    echo "Evaluando $endpoint ..."

    # Verificar contenido requerido en la respuesta
    if ! curl -s "$endpoint" | grep -q "$required_field"; then
        echo "🔴 $endpoint -> no contiene campo requerido '$required_field'"
        echo "$endpoint,0,0,0,$expected_code,INVALID,FALLO" >> "$OUTPUT_FILE"
        fallo_global=1
        continue
    fi

    # Filtrar métricas para este endpoint
    latencias=$(awk -F, -v ep="$endpoint" '$1==ep {print $3}' "$INPUT_FILE" | sort -n)
    codigos=$(awk -F, -v ep="$endpoint" '$1==ep {print $4}' "$INPUT_FILE" | sort -u)

    # Verificar que todos los códigos coincidan con el esperado
    if [[ "$codigos" != "$expected_code" ]]; then
        echo "🔴 $endpoint -> códigos observados distintos al esperado ($expected_code): $codigos"
        echo "$endpoint,0,0,0,$expected_code,$codigos,FALLO" >> "$OUTPUT_FILE"
        fallo_global=1
        continue
    fi

    if [[ -z "$latencias" ]]; then
        echo "🔴 $endpoint -> sin datos"
        echo "$endpoint,0,0,0,$expected_code,NODATA,FALLO" >> "$OUTPUT_FILE"
        fallo_global=1
        continue
    fi

    count=$(echo "$latencias" | wc -l)

    # Calcular percentiles
    p50_index=$(( (count+1)*50/100 ))
    p95_index=$(( (count+1)*95/100 ))
    p99_index=$(( (count+1)*99/100 ))

    p50=$(echo "$latencias" | awk "NR==$p50_index")
    p95=$(echo "$latencias" | awk "NR==$p95_index")
    p99=$(echo "$latencias" | awk "NR==$p99_index")

    # Evaluar SLA → Vista semáforo
    estado="OK"
    emoji="🟢"

    if [[ "$p50" -gt "$p50_budget" ]]; then
        estado="FALLO"
        emoji="🔴"
        fallo_global=1
    elif [[ "$p95" -gt "$p95_budget" ]]; then
        estado="FALLO"
        emoji="🔴"
        fallo_global=1
    elif [[ "$p99" -gt "$p99_budget" ]]; then
        estado="ALERTA"
        emoji="🟠"
    fi

    # Guardar resultado
    echo "$endpoint,$p50,$p95,$p99,$expected_code,$expected_code,$estado" >> "$OUTPUT_FILE"

    # Log en consola
    echo "$emoji $endpoint -> p50=${p50}ms (≤${p50_budget}), p95=${p95}ms (≤${p95_budget}), p99=${p99}ms (≤${p99_budget}), code=$expected_code => $estado"
done < <(tail -n +2 "$SLA_FILE")

echo "Evaluación completada. Resultados en $OUTPUT_FILE"

# Si hubo algún fallo → salir con código ≠ 0
if [[ $fallo_global -ne 0 ]]; then
    echo "Se detectaron incumplimientos de SLA"
    exit 7
fi

exit 0
