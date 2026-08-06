# Sistema Experto de Recomendaciones Académicas

Sistema experto en Common Lisp que recomienda cursos universitarios según los
intereses del estudiante, sus cursos aprobados, su horario disponible, su
tolerancia a la dificultad y su área profesional objetivo — y que **explica**
cada recomendación mostrando las reglas que la produjeron.

El valor del proyecto no está en ordenar una lista de cursos. Está en que un
motor de inferencia propio, con reglas declarativas y trazabilidad, produce y
justifica la recomendación.

---

## Estado actual

| Elemento | Estado |
| -------- | ------ |
| Diseño y documentación | ✅ Completo |
| Código de implementación | ✅ Primera versión funcional, rama `feature/initial-lisp-implementation` |
| Cola de tareas | 10 de 14 verificadas (T001–T010); ver `docs/progress/tasks.json` |
| Catálogo de datos | 47 cursos reales (Bachillerato en Ingeniería en Sistemas de Computación, Fidélitas); créditos, dificultad, horario y prerrequisitos siguen siendo provisionales — ver `docs/context/ACTIVE_CONTEXT.md` |
| Suite de pruebas | 182 comprobaciones, 0 fallos (`sbcl --script run-tests.lisp`) |
| Gate de verificación | 🟢 En verde (`.ace/scripts/verify-lisp.sh` compila todo `src/`) |

Para el estado completo y detallado — qué es oficial, qué es provisional,
qué falta y por dónde seguir — ver
**[docs/context/ACTIVE_CONTEXT.md](docs/context/ACTIVE_CONTEXT.md)**. Este
README describe la arquitectura y cómo arrancar; ACTIVE_CONTEXT.md es la
fuente de verdad sobre el progreso.

---

## Antes de empezar

Necesitás:

- **SBCL** ≥ 2.6 — [instalador](https://www.sbcl.org/platform-table.html)
- **Git Bash** (en Windows) o cualquier shell POSIX
- Opcional: extensión **Alive** de VS Code para trabajar Lisp con REPL

```bash
git clone https://github.com/Wardaddy118/Expert_System_Lisp.git
cd Expert_System_Lisp
git checkout feature/initial-lisp-implementation
sh .ace/scripts/verify.sh     # deberia decir VERIFY_RESULT=pass
sbcl --script run.lisp         # corre la demostracion completa
sbcl --script run-tests.lisp   # corre la suite (182 comprobaciones)
```

> **En Mac o Linux:** en `.claude/settings.json` cambiá la ruta a `sh.exe` por
> `sh <script>`. Esa ruta apunta a Git for Windows.

---

## Por dónde empezar a leer

El repo tiene más de 100 archivos. **Estos cinco, en este orden**, son todo lo
que hace falta para entender el proyecto:

| # | Archivo | Qué vas a encontrar |
| - | ------- | ------------------- |
| 1 | [docs/context/ACTIVE_CONTEXT.md](docs/context/ACTIVE_CONTEXT.md) | Dónde estamos parados y qué sigue |
| 2 | [docs/requirements/PRD-recomendador-academico.md](docs/requirements/PRD-recomendador-academico.md) | Qué se va a construir: requisitos, casos borde, riesgos |
| 3 | [docs/adr/ADR-005-motor-inferencia.md](docs/adr/ADR-005-motor-inferencia.md) | El corazón del proyecto, y por qué **no** usamos CLIPS |
| 4 | [.ace/knowledge/business-rules.md](.ace/knowledge/business-rules.md) | Las reglas del conocimiento experto (BR-001 en adelante; 25 `defrule` en `src/domain/knowledge.lisp`) |
| 5 | [docs/planning/implementation_plan.md](docs/planning/implementation_plan.md) | Las 5 fases y las 14 tareas |

---

## Arquitectura

Tres capas con dependencias en una sola dirección:

```text
┌──────────────────────────────────────────────────────────┐
│  CLI          src/cli/                                   │
│  Captura del perfil · sesión · presentación en texto     │
│  Única capa que hace E/S con el usuario                  │
└───────────────────────┬──────────────────────────────────┘
                        ▼
┌──────────────────────────────────────────────────────────┐
│  DOMINIO      src/domain/                                │
│  Carga de datos · reglas académicas (defrule) ·          │
│  explicaciones · estadísticas                            │
│  Conoce cursos y créditos. No conoce la CLI.             │
└───────────────────────┬──────────────────────────────────┘
                        ▼
┌──────────────────────────────────────────────────────────┐
│  MOTOR        src/engine/                                │
│  Hechos · matching con variables · reglas como datos ·   │
│  agenda · resolución de conflictos · refracción ·        │
│  ciclo de inferencia · traza                             │
│  Genérico: no sabe qué es un curso.                      │
└──────────────────────────────────────────────────────────┘

  data/   Catálogo y perfiles en S-expressions (datos, no código)
```

### Cómo funciona una sesión

```text
La CLI captura el perfil
  → el cargador afirma los hechos del catálogo y del perfil
  → el motor corre hasta quiescencia disparando las reglas del dominio
  → se reconstruye el porqué desde la traza de inferencia
  → se calculan las estadísticas sobre la memoria de trabajo final
  → todo se presenta en texto
```

### Motor de inferencia

Motor de producción con **encadenamiento hacia adelante**, escrito desde cero:

- Hechos planos en memoria de trabajo: `(prerequisite "CI-2400" "CI-1201")`
- Reglas declaradas como datos, no como código:

```lisp
(defrule eligible-when-prerequisites-met
  "Implementa BR-001 y BR-002."
  :priority 10
  :when ((course ?id)
         (not (approved ?id))
         (prerequisites-satisfied ?id))
  :then ((eligible ?id)))
```

- Ciclo `match → select → act` hasta quiescencia
- Resolución de conflictos determinista: prioridad → recencia → orden de
  declaración
- Refracción, para que el motor termine siempre
- Traza de cada disparo — de ahí sale la explicación al estudiante

---

## Reglas del proyecto

Tres cosas que **no se negocian**. Cada una está justificada en un ADR:

1. **El motor lo escribimos nosotros.** Nada de LISA, CLIPS, ni resolver con
   `remove-if` y `sort`. [ADR-005](docs/adr/ADR-005-motor-inferencia.md)
   explica qué se pierde con cada atajo.
2. **El conocimiento no se agrega tocando el motor.** Se agrega una regla en
   [business-rules.md](.ace/knowledge/business-rules.md), su `defrule`, y sus
   pruebas de disparo y de no-disparo.
3. **`engine/` no puede saber qué es un curso.** Su suite de pruebas usa
   hechos inventados. Si necesita el dominio académico para pasar, el diseño
   se rompió.

Antes de escribir código, leé [.ace/standards/lisp.md](.ace/standards/lisp.md)
(convenciones) y
[docs/context/system_patterns.md](docs/context/system_patterns.md)
(patrones y anti-patrones).

---

## Estructura del repositorio

```text
docs/
  context/       Estado de la sesión, decisiones estables, patrones
  requirements/  PRD
  adr/           Decisiones de arquitectura (las del proyecto son 004+)
  planning/      Plan de implementación
  progress/      tasks.json — la cola de trabajo
.ace/
  knowledge/     Glosario, entidades y reglas del dominio
  standards/     Convenciones de código
  scripts/       verify.sh — el gate de verificación
src/             (por crear) Código fuente
data/            (por crear) Catálogo de cursos y perfiles
quicklisp.lisp   Instalador de Quicklisp. No es código del proyecto.
```

---

## Flujo de trabajo

El proyecto usa [ACE Framework](https://github.com/jonnabio/ace-framework)
v2.7 con el ciclo BMAD: *Analyze → Discuss → Plan → Execute → Verify*.
En la práctica:

**Consultar qué sigue:**

```bash
npx -y -p create-ace-framework@2.7.0 ace-framework loop --dry-run
```

**Al terminar una tarea**, el gate tiene que pasar antes de darla por cerrada:

```bash
sh .ace/scripts/verify.sh    # debe imprimir VERIFY_RESULT=pass
```

Commits atómicos, uno por tarea, en rama propia. Mensajes en inglés e
imperativo: `add forward-chaining agenda`.

---

## Qué falta decidir

### Ya resueltas

- [x] Carrera y universidad a modelar: Bachillerato en Ingeniería en
      Sistemas de Computación, Universidad Fidélitas. Catálogo real de 47
      cursos cargado en `data/courses.lisp` (T002 verificada).

### Bloquean el arranque

- [ ] Fechas del borrador y de la semana 15
- [ ] Reparto de las 14 tareas entre el equipo
- [ ] Si el profesor exige un formato de informe además del código

### Requieren ratificación del equipo

Hay un valor propuesto en la documentación, pero son juicios de dominio y
alguien tiene que hacerse responsable de ellos:

- [ ] **Con qué criterio se asigna la dificultad 1–5 de cada curso, y quién lo
      hace.** Es el más importante: si al preguntar "¿por qué este curso es
      dificultad 4?" la respuesta es "nos pareció", el sistema experto pierde
      su fundamento.
- [ ] Los pesos de priorización BR-010 a BR-015
- [ ] El umbral de cuello de botella (propuesto: requisito de ≥3 cursos)
- [ ] Si se recomienda un cuello de botella que excede la tolerancia a
      dificultad por un nivel

Detalle completo en el
[PRD §Preguntas abiertas](docs/requirements/PRD-recomendador-academico.md#preguntas-abiertas).

---

## Alcance

**Sí:** motor de inferencia propio, base de conocimiento auditable,
recomendaciones explicadas, estadísticas del estudiante y del catálogo, CLI
interactiva.

**No:** matrícula real, interfaz web, aprendizaje automático, malla curricular
completa, horarios con hora exacta. Cada exclusión está justificada en su ADR
y documentada como trabajo futuro.
