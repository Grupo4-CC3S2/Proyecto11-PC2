#!/usr/bin/env bats

# se ejecuta antes de cada test
setup() {
    export TEST_DIR="$(pwd)"
    export TARGETS="http://localhost:8080/"
    export SAMPLES=3
    export BUDGET_MS=1000

    # Capturar lista de archivos CSV existentes ANTES del test
    if ls out/metrics-raw-*.csv >/dev/null 2>&1; then
        EXISTING_FILES=$(ls out/metrics-raw-*.csv 2>/dev/null)
    else
        EXISTING_FILES=""
    fi
}

# limpieza después de cada test
teardown() {
    if ls out/metrics-raw-*.csv >/dev/null 2>&1; then
        for file in out/metrics-raw-*.csv; do
            if [[ ! " $EXISTING_FILES " =~ " $file " ]]; then
                rm -f "$file"
            fi
        done
    fi
    unset TEST_DIR
    unset TARGETS
    unset SAMPLES
    unset BUDGET_MS
}

@test "colector requiere variable TARGETS definida" {
    unset TARGETS
    run bash src/collect_metrics.sh
    [ "$status" -eq 5 ]
    [[ "$output" =~ "TARGETS no definida" ]]
}

@test "colector genera archivo CSV válido" {
    export TARGETS="http://localhost:8080/"
    run bash src/collect_metrics.sh
    [ "$status" -eq 0 ]
    
    # Verificar archivo existe y tiene header correcto
    csv_file=$(ls -t out/metrics-raw-*.csv | head -1)
    header=$(head -1 "$csv_file")
    [ "$header" = "endpoint,timestamp,latency_ms,http_code,status,sample_number,budget_exceeded" ]
}

@test "colector procesa códigos HTTP correctamente" {
    export TARGETS="http://localhost:8080/,http://localhost:8080/notfound,http://localhost:8080/falla"
    export SAMPLES=1  # Solo 1 muestra para ser eficiente
    bash src/collect_metrics.sh
    
    csv_file=$(ls -t out/metrics-raw-*.csv | head -1)
    
    # Verificar clasificación de códigos HTTP
    grep ",200,SUCCESS," "$csv_file"
    grep ",404,CLIENT_ERROR," "$csv_file" 
    grep ",500,SERVER_ERROR," "$csv_file"
}

@test "colector recolecta múltiples muestras" {
    export TARGETS="http://localhost:8080/salud"
    export SAMPLES=5
    bash src/collect_metrics.sh
    
    csv_file=$(ls -t out/metrics-raw-*.csv | head -1)
    
    # Verificar número correcto de registros (header + 5 muestras)
    total_lines=$(wc -l < "$csv_file")
    [ "$total_lines" -eq 6 ]
}

@test "colector detecta budget excedido" {
    export TARGETS="http://localhost:8080/lento"
    export BUDGET_MS=500
    export SAMPLES=1
    curl -s http://localhost:8080/restart 1>/dev/null 2>&1
    bash src/collect_metrics.sh
    csv_file=$(ls -t out/metrics-raw-*.csv | head -1)
    
    # Verificar que detecta budget excedido
    grep ",true$" "$csv_file"
}