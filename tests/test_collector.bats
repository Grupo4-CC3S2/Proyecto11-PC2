#!/usr/bin/env bats

# se ejecuta antes de cada test
setup() {
    export TEST_DIR="$(pwd)"
    export TARGETS="https://httpbin.org/status/200"
}

# limpieza después de cada test
teardown() {
    rm -f out/metrics-raw-*.csv 2>/dev/null || true
}

@test "colector requiere variable TARGETS definida" {
    unset TARGETS
    run bash src/collect_metrics.sh
    [ "$status" -eq 5 ]
    [[ "$output" =~ "TARGETS no definida" ]]
}

@test "colector genera archivo CSV en out/" {
    export TARGETS="https://httpbin.org/status/200"
    run bash src/collect_metrics.sh
    [ "$status" -eq 0 ]
    
    # Verificar que existe al menos un archivo CSV
    run ls out/metrics-raw-*.csv
    [ "$status" -eq 0 ]
}

@test "CSV contiene header correcto" {
    export TARGETS="https://httpbin.org/status/200"
    bash src/collect_metrics.sh
    
    # Obtener el archivo más reciente
    csv_file=$(ls -t out/metrics-raw-*.csv | head -1)
    
    # Leer primera línea
    header=$(head -1 "$csv_file")
    [ "$header" = "endpoint,timestamp,latency_ms,http_code,status" ]
}

@test "colector procesa endpoint exitoso 200" {
    export TARGETS="https://httpbin.org/status/200"
    bash src/collect_metrics.sh
    
    csv_file=$(ls -t out/metrics-raw-*.csv | head -1)
    
    # Verificar que contiene código 200 y SUCCESS
    run grep "200,SUCCESS" "$csv_file"
    [ "$status" -eq 0 ]
}

@test "colector detecta error 404" {
    export TARGETS="https://httpbin.org/status/404"
    bash src/collect_metrics.sh
    
    csv_file=$(ls -t out/metrics-raw-*.csv | head -1)
    
    # Verificar que contiene código 404 y CLIENT_ERROR
    run grep "404,CLIENT_ERROR" "$csv_file"
    [ "$status" -eq 0 ]
}