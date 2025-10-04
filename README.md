# Proyecto11-PC2: Catálogo de endpoints con presupuesto de latencia y acuerdos de nivel (SLA)

# Integrantes:

- Mora Evangelista Fernando
- Osorio Tello Jesus Diego

Sistema de monitoreo de endpoints HTTP que evalúa cumplimiento de SLAs basándose en percentiles de latencia (p50/p95/p99) y códigos de respuesta.

## Descripción

El sistema:
- Recolecta múltiples muestras de latencia por endpoint
- Calcula percentiles p50/p95/p99
- Compara contra umbrales definidos en archivo SLA
- Genera vista semáforo (OK/ALERTA/FALLO)

## Principios aplicados

- **12-Factor I**: Una única base de código
- **12-Factor III**: Configuración mediante variables de entorno
- **12-Factor V**: Separación compilar/lanzar/ejecutar (build/run)
- **CALMS**: Automatización con Makefile, medición con métricas
- **YBIYRI**: El equipo (Mora y Osorio) que construye opera el sistema

## Requisitos

- bash (con `set -euo pipefail`)
- curl
- awk, sort, grep, sed, cut
- bats (para tests)
- python3 + Flask (servidor de pruebas)
- tar (GNU tar)
- getent, ss

## Variables de entorno

| Variable | Efecto | Valor por defecto | Verificable con |
|----------|--------|-------------------|-----------------|
| `TARGETS` | Lista de URLs separadas por coma a monitorear | Leer de SLA_FILE | `echo $TARGETS` |
| `SAMPLES` | Número de muestras a recolectar por endpoint | 20 | Ver líneas en CSV generado |
| `BUDGET_MS` | Presupuesto de latencia en milisegundos | 500 | Columna `budget_exceeded` en CSV |
| `SLA_FILE` | Ruta al archivo CSV con definición de SLAs | `docs/sla.csv` | `test -f $SLA_FILE` |
| `RELEASE` | Versión del release para empaquetado | v1.0.0 | Nombre de tarball en dist/ |
| `PORT` | Puerto del servidor de pruebas | 8080 | `ss -ltnp \| grep :8080` |
| `DOMAIN` | Dominio local para pruebas | localhost | `getent hosts $DOMAIN` |

## Estructura del proyecto
```
.
├── src/                    # Scripts Bash
│   ├── basic_checks.sh    # Verificaciones DNS/HTTP/sockets
│   ├── collect_metrics.sh # Colector de métricas con curl
│   └── evaluate_metrics.sh # Evaluador SLA con percentiles
├── tests/                  # Suite Bats
│   ├── test_collector.bats
│   └── test_evaluator.bats
├── docs/                   # Documentación
│   ├── sla.csv            # Configuración SLA
│   ├── contrato-salidas.md
│   ├── bitacora-sprint-1.md
│   ├── bitacora-sprint-2.md
│   └── bitacora-sprint-3.md
├── out/                    # Salidas intermedias (generado)
├── dist/                   # Paquetes finales (generado)
├── app.py                  # Servidor Flask para pruebas
├── Makefile               # Automatización
├── README.md
└── requirements.txt        # flask
```

## Uso

### 1. Preparar entorno

```bash
# Instalar dependencias del servidor de pruebas
make prepare

# Configurar hosts 
make hosts-setup

# Verificar herramientas disponibles
make tools
```

### 2. Levantar servidor de pruebas

```bash
# En una terminal
make init-app
# Servidor corre en http://localhost:8080
```

### 3. Ejecutar monitoreo

```bash
# Build (prepara sin ejecutar)
make build

# Ejecutar tests
make test

# Ejecutar flujo completo
make run
```
> Resultados en out/metrics-raw-*.csv y out/metrics-raw-*.csv.results

### 4. Empaquetar release

```bash
make pack
```
> Genera dist/proyecto-sla-v1.0.0.tar.gz

## Lógica del semáforo 

- **(Verde)** OK: p50 ≤ umbral Y p95 ≤ umbral Y p99 ≤ umbral
- **(Ambar)** ALERTA: p99 > umbral (pero p50 y p95 OK)
- **(Rojo)** FALLO: p50 o p95 exceden umbral O código HTTP incorrecto O falta campo requerido

## Targets del Makefile

```bash
make help          # Muestra ayuda
make tools         # Verifica herramientas disponibles
make build         # Prepara artefactos sin ejecutar
make test          # Ejecuta suite Bats
make run           # Flujo completo: checks + collect + evaluate
make pack          # Crea paquete en dist/
make clean         # Limpia out/ y dist/
make init-app      # Inicia servidor Flask de pruebas
make all           # Verifica herramientas, construye, prueba y ejecuta el sistema
make prepare       # Crear entorno virtual e instala dependencias de la app de pruebas
make hosts-setup   # Configura pc2.local en /etc/hosts
```