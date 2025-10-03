# Bitácora Sprint 2

## Objetivo del Sprint
Automatizar la recolección y evaluación de métricas de endpoints HTTP, integrando reglas de SLA y reportes automáticos. Mejorar la trazabilidad y robustez del sistema de pruebas.

---

## Decisiones Técnicas

### 1. Integración de Makefile para flujo completo
- El **Makefile** centraliza la ejecución de herramientas, pruebas, recolección de métricas y evaluación de SLA. Se requiere un archivo `sla.csv` con las reglas de SLA.

### 2. Script `evaluate_metrics.sh`
- Lee el archivo de métricas generado y el archivo de SLA (`sla.csv`).  
- Calcula **percentiles (p50, p95, p99)** de latencia por endpoint.  
- Verifica cumplimiento de códigos HTTP y contenido requerido.  
- Genera reporte de resultados con semáforo (**OK, ALERTA, FALLO**).  
- Salida con código de error si hay incumplimientos de SLA.  

### 3. Pruebas automatizadas con Bats
- Pruebas en `tests` verifican el correcto funcionamiento de los scripts y la recolección de métricas.  
- Validan la generación de archivos, formato de salida y manejo de errores.  

---

## Comandos Ejecutados

- **Flujo completo**: verifica herramientas, ejecuta pruebas, recolecta métricas y evalúa SLA.  
```bash
make all
```
- **Solo métricas + SLA**: recolección de métricas y evaluación de SLA.
```bash
make run
```
- **Pruebas unitarias**: ejecución de tests con Bats.
```bash
make test
```
---

## Observaciones
- El uso de **variables de entorno en el Makefile** permite modificar parámetros sin editar los scripts.  
- El sistema de **logs y reportes** facilita la trazabilidad y el análisis de resultados históricos.  
- La integración de **percentiles y validación de SLA** mejora la calidad de la evaluación.  

---

## Conclusión
Sprint 2 consolida la automatización y evaluación de métricas, permitiendo iteraciones rápidas y confiables sobre los endpoints definidos en el SLA.
