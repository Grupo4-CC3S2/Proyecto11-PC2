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

# Bitácora Sprint 1 - Mora

### basic_checks.sh
- Implementación de chequeos básicos:
    - Resolución DNS
    - Puerto escuchando
    - Endpoint `/salud`
    - Manejo de errores y códigos de salida específicos
    - Salida de logs en directorio `out/`

### Makefile
- Definición de reglas:
    - `OUT_DIR` para resultados
    - `run` para ejecutar el flujo p
    - `tools` para verificar dependencias
    - `hosts-setup` para configurar `/etc/hosts` en pruebas
    - `prepare` para inicializar entorno
    - `init-app` para iniciar servidor Flask

- Definición de variables de entorno:
    - `RELEASE`, `PORT`, `MESSAGE`, `VENV_DIR`, `DOMAIN` variables para la app de prueba
    - `SLA_FILE` será evaluado en el siguiente sprint.

### Comandos ejecutados
- Para correr la aplicación de prueba:
```bash
make init-app
```

- Para verificar dependencias:
```bash
make tools
```