# Bitácora Sprint 1 - Osorio

## Objetivo del Sprint
Establecer base del colector HTTP que capture métricas de latencia y códigos de estado desde endpoints configurables.

## Decisiones Técnicas

### 1. Archivo CSV con timestamp único
Cada ejecución genera archivo `metrics-raw-TIMESTAMP.csv` para mantener un historial de ejecuciones para trazabilidad.  

### 2. Endpoints de prueba: httpbin.org
Usé httpbin.org ya que permite simular diversos escenarios (200, 404, 500, delays -> 1). Esto nos da tests más robustos y realistas.

## Comandos Ejecutados

- Hacemos ejecutable nuestro script `collect_metrics.sh`.

```bash
chmod +x src/collect_metrics.sh
```

- Definimos endpoints de prueba

```bash
export TARGETS="https://httpbin.org/status/200,https://httpbin.org/delay/1,https://httpbin.org/status/404,https://httpbin.org/status/500"

# Ejecutamos
bash src/collect_metrics.sh
```

- Para las pruebas bats, simplemente ejecutamos 
```bash
bats tests/test_collector.bats
```
