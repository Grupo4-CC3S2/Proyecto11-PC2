# Bitácora Sprint 1 - Osorio

## Objetivo del Sprint
Establecer base del colector HTTP que capture métricas de latencia y códigos de estado desde endpoints configurables.

## Decisiones Técnicas

### 1. Archivo CSV con timestamp único
Cada ejecución genera archivo `metrics-raw-TIMESTAMP.csv` para mantener un historial de ejecuciones para trazabilidad.  

### 2. Endpoints de prueba: servidor local app.py

Implementamos un servidor Flask en puerto 8080 con endpoints:
- `/` - 200 OK
- `/salud` - 200 OK con metadata
- `/lento` - 200 con delay 1-2s
- `/notfound` - 404
- `/falla` - 500

### 3. Variables de entorno
- `TARGETS`: Lista de endpoints separados por comas
- `SAMPLES`: Número de muestras por endpoint (default: 10)
- `BUDGET_MS`: Presupuesto de latencia en ms (default: 500)

## Comandos Ejecutados

- Hacemos ejecutable nuestro script `collect_metrics.sh`.

```bash
chmod +x src/collect_metrics.sh
```

- Definimos endpoints de prueba

```bash
export TARGETS="http://localhost:8080/,http://localhost:8080/salud,http://localhost:8080/config,http://localhost:8080/lento,http://localhost:8080/notfound,http://localhost:8080/falla"

# Ejecutamos
bash src/collect_metrics.sh
```

- Para las pruebas bats, simplemente ejecutamos 
```bash
bats tests/test_collector.bats
```
