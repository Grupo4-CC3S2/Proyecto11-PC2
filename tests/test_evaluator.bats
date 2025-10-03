#!/usr/bin/env bats

setup() {
  mkdir -p out
  mkdir -p docs
  export SLA_FILE=docs/sla.test.csv
  # SLA mínimo de prueba
  cat > $SLA_FILE <<EOF
endpoint,p50_budget_ms,p95_budget_ms,p99_budget_ms,expected_code,required_field
http://localhost:8080/salud,200,400,600,200,status
EOF
}


teardown() {
  rm -rf $SLA_FILE
  unset SLA_FILE
}

@test "falla si falta SLA_FILE" {
  rm -f $SLA_FILE
  run ./src/evaluate_metrics.sh out/fake.csv
  [ "$status" -ne 0 ]
  [[ "$output" =~ "Error: no se encuentra" ]]
}

@test "falla si falta archivo de métricas" {
  run ./src/evaluate_metrics.sh out/noexiste.csv
  [ "$status" -ne 0 ]
  [[ "$output" =~ "Error: no se encuentra archivo" ]]
}

@test "genera .results con datos correctos" {
  # archivo de métricas sintético
  cat > out/metrics-raw-123.csv <<EOF
endpoint,timestamp,latency_ms,http_code,status,sample_number,budget_exceeded
http://localhost:8080/salud,2025-09-29T10:00:00Z,100,200,SUCCESS,1,false
http://localhost:8080/salud,2025-09-29T10:00:01Z,120,200,SUCCESS,2,false
http://localhost:8080/salud,2025-09-29T10:00:02Z,150,200,SUCCESS,3,false
EOF

  run ./src/evaluate_metrics.sh out/metrics-raw-123.csv
  [ "$status" -eq 0 ]
  [ -f out/metrics-raw-123.csv.results ]
  grep "http://localhost:8080/salud" out/metrics-raw-123.csv.results
  rm -f out/metrics-raw-123.csv*
}

@test "marca FALLO si http_code no coincide" {
  cat > out/metrics-raw-456.csv <<EOF
endpoint,timestamp,latency_ms,http_code,status,sample_number,budget_exceeded
http://localhost:8080/salud,2025-09-29T10:00:00Z,100,500,SERVER_ERROR,1,false
EOF

  run ./src/evaluate_metrics.sh out/metrics-raw-456.csv
  [ "$status" -ne 0 ]
  grep "FALLO" out/metrics-raw-456.csv.results
  rm -f out/metrics-raw-456.csv*
}

@test "marca FALLO si falta required_field" {
  # Endpoint inexistente para forzar fallo en grep
  sed -i 's/status/fakefield/' $SLA_FILE

  cat > out/metrics-raw-789.csv <<EOF
endpoint,timestamp,latency_ms,http_code,status,sample_number,budget_exceeded
http://localhost:8080/salud,2025-09-29T10:00:00Z,100,200,SUCCESS,1,false
EOF

  run ./src/evaluate_metrics.sh out/metrics-raw-789.csv
  [ "$status" -ne 0 ]
  
  rm -f  out/metrics-raw-789.csv*
}
