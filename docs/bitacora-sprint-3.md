# Bitácora Sprint 3

## Caché incremental en Makefile
Implementamos timestamp `.build_stamp` en `out/` que se regenera solo si cambian:
- Scripts en `src/`
- Archivo SLA configurado
- Primera ejecución

Evidenciable con:
```bash
time make build  # Primera vez: ~200ms
time make build  # Segunda vez: instantáneo o "Nothing to be done"
touch src/collect_metrics.sh # modificamos algo
time make build  # Regenera por cambio de dependencia
```

## Empaquetado reproducible
Target `pack` genera tarball con nomenclatura fija `proyecto-sla-${RELEASE}.tar.gz`:

- Excluye directorios generados (out/, dist/, venv/)
- Incluye solo código fuente y documentación
- Usa `--transform` para crear estructura consistente

## Separación build/run 
- `build`: Valida configuración, prepara permisos, no ejecuta
- `run`: Ejecuta flujo asumiendo que build ya corrió
- Separación clara de compilar/lanzar/ejecutar

## Comandos ejecutados: end-to-end
```bash
# Limpiar estado previo
make clean

# Verificar herramientas disponibles
make tools

# Valida configuración, prepara permisos, no ejecuta
make build

make init-app # ejecutar en otra terminal

# Ejecuta flujo 
make run

# Ejecuta pruebas bats
make test

# O ejcutar make all
make all # -> Verifica herramientas, construye, prueba y ejecuta el sistema

# Generar paquete
make pack
```