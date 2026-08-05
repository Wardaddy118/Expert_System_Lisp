# Active Context: Fase de diseño completada

## Session Metadata

- **Última actualización:** 2026-08-05
- **Rol activo:** Architect
- **Mode:** PLANNING
- **Próxima transición:** PLANNING → EXECUTION (requiere aprobación del equipo)

## Objetivo actual

Diseñar la arquitectura y producir la documentación del Sistema Experto de
Recomendaciones Académicas antes de escribir código de implementación.

## Estado actual

### Terminado

- Fase DISCUSS cerrada: cuatro decisiones capturadas en
  `docs/context/PROJECT_CONTEXT.md` (D-01 a D-04).
- PRD con FR/NFR, casos borde, riesgos y métricas de éxito.
- ADR-004 (stack), ADR-005 (motor de inferencia), ADR-006 (representación del
  conocimiento), con alternativas rechazadas y criterios de cumplimiento.
- Base de conocimiento: glosario con vocabulario cerrado, catálogo de
  relaciones (`entities.md`) y 20 reglas de dominio especificadas
  (`business-rules.md`).
- Estándar de código Lisp (`.ace/standards/lisp.md`), registrado en
  `.aceconfig`.
- Patrones del sistema reescritos para Lisp (el scaffold traía TypeScript).
- Plan de implementación con cinco fases y diez criterios de aceptación.
- Cola de tareas T001–T014 en `docs/progress/tasks.json`, validada contra el
  schema y los invariantes del loop.

### En progreso

- Nada. La fase de diseño está cerrada y espera aprobación.

### Bloqueado

- **Fechas del calendario académico.** El cronograma tiene las semanas pero no
  las fechas; hay que completarlas antes de arrancar la Fase 2.
- **Carrera y universidad a modelar.** T002 no puede empezar sin esto.
- **Reparto de tareas.** `tasks.json` no asigna personas.

## Próximos pasos

1. [ ] El equipo revisa y aprueba `docs/planning/implementation_plan.md`.
2. [ ] Confirmar carrera, universidad y fechas; completar el cronograma.
3. [ ] Reapuntar `verify.test_cmd` en `.aceconfig` a `asdf:test-system`
       cuando T001 cierre (hoy el gate solo compila).
4. [ ] Transición a EXECUTION: **iniciar una sesión nueva de LLM**
       (context flush) cargando únicamente T001 y el plan de implementación.

## Restricciones activas

- `.ace/standards/lisp.md` — convenciones de código
- `.ace/standards/coding.md` — principios generales
- `.ace/standards/security.md`
- `docs/context/PROJECT_CONTEXT.md` — D-01 a D-04 son restricciones duras
- `docs/context/system_patterns.md` — patrones y anti-patrones
- `.ace/knowledge/business-rules.md` — especificación del conocimiento experto

## Notas de sesión

- El motor de inferencia se escribe desde cero (D-01). Cualquier propuesta de
  usar LISA/CLIPS o de resolver con filtros funcionales contradice ADR-005 y
  debe rechazarse en revisión.
- El riesgo principal del cronograma es T004 (pattern matching con variables).
  No arrancar T005 hasta que su suite esté verde.
- El gate `verify.sh` está en rojo mientras no exista código Lisp: es
  intencional, no un defecto.
- Los ADR del proyecto empiezan en el 004; los tres primeros son del framework
  ACE (ver `docs/adr/README.md`).
