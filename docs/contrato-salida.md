# Contrato de salidas

Este documento describe todos los archivos generados por el sistema, su formato y método de validación.

## Directorio: `out/`

### 1. `dns.txt`
- **Generado por**: `src/basic_checks.sh`
- **Contenido**: Resolución DNS del dominio configurado
- **Ejemplo**: 127.0.0.1

### 2. `port.txt`
- **Generado por**: `src/basic_checks.sh`
- **Contenido**: Procesos escuchando en puerto configurado
- **Ejemplo**: LISTEN 0 128 0.0.0.0:8080 0.0.0.0:* users:(("python3",pid=12732,fd=6),("python3",pid=12732,fd=5),("python3",pid=12731,fd=5))

### 3. `salud.txt`
- **Generado por**: `src/basic_checks.sh`
- **Contenido**: Respuesta completa del endpoint /salud
- **Ejemplo**: HTTP/1.1 200 OK ...

### 4. `metrics-raw-TIMESTAMP.csv`
- **Generado por**: `src/collect_metrics.sh`
- **Contenido**: Métricas crudas de todas las muestras recolectadas

### 5. `metrics-raw-TIMESTAMP.csv.results`

- **Generado por**: `src/evaluate_metrics.sh`
- **Contenido**: Evaluación SLA por endpoint con percentiles calculados

### 6. `proyecto-sla-v1.0.0.tar.gz`
- **Generado por**: `make pack`
- **Contenido**: Código fuente completo (src/, tests/, docs/, Makefile, README.md)
- **Excluye**: out/, dist/, venv/, pycache

## Idempotencia

El sistema es idempotente:

- Ejecutar `make run` múltiples veces genera nuevos archivos con timestamp
- No modifica archivos anteriores
- `make build` con caché no regenera si dependencias no cambiaron