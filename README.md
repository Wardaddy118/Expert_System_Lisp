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
| Código de implementación | ✅ Funcional y fusionado en `main` |
| Cola de tareas | **11 de 14 verificadas** (T001–T011); faltan T012, T013 y T014 |
| Catálogo de datos | 47 cursos reales (Bachillerato en Ingeniería en Sistemas de Computación, Fidélitas); créditos, dificultad, horario y prerrequisitos son provisionales y están marcados como tales |
| Suite de pruebas | **235 comprobaciones, 0 fallos** (`sbcl --script run-tests.lisp`) |
| Gate de verificación | 🟢 En verde (`sh .ace/scripts/verify.sh` compila con ASDF y corre la suite) |

### Entregas

| Entrega | Fecha | Estado |
| ------- | ----- | ------ |
| Borrador | jueves 6 de agosto de 2026 (semana 13) | ⏳ En curso |
| Final: sistema 100% funcional | jueves 20 de agosto de 2026 (semana 15) | ⬜ Pendiente |

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
sh .ace/scripts/verify.sh      # debe decir VERIFY_RESULT=pass
sbcl --script run.lisp         # corre la demostracion completa
sbcl --script run-tests.lisp   # corre la suite (235 comprobaciones)
```

Todo está en `main`: no hace falta cambiar de rama.

> **La primera corrida descarga FiveAM** con Quicklisp, así que necesita
> internet una sola vez. Es la única dependencia externa del proyecto y solo
> se usa en pruebas: el sistema principal carga con SBCL y nada más (ADR-004).
>
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
src/
  engine/        Motor genérico: hechos, matching, reglas, agenda, inferencia
  domain/        Dominio académico: carga, 25 reglas, explicaciones, estadísticas
  cli/           Presentación y flujo de sesión
  package.lisp   Los tres paquetes
  main.lisp      Punto de entrada
data/
  courses.lisp   Catálogo de 47 cursos
  profiles/      Perfiles de estudiante
tests/           Espejo de src/, un archivo por archivo
expert-system.asd  Definición ASDF de los dos sistemas
run.lisp           sbcl --script run.lisp → demostración completa
run-tests.lisp     sbcl --script run-tests.lisp → suite de pruebas
quicklisp.lisp     Instalador de Quicklisp. No es código del proyecto.
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

## Qué falta

### Tareas (3 de 14)

| Tarea | Qué falta |
| ----- | --------- |
| **T012** | Captura interactiva del perfil. Hoy la sesión carga un perfil fijo desde `data/profiles/`, no pregunta por consola. |
| **T013** | Perfiles de demostración. Solo existe uno; faltan primer ingreso, estudiante avanzado, horario restringido y tolerancia baja. |
| **T014** | Suite de aceptación en un archivo dedicado. Los 10 criterios ya están cubiertos de forma dispersa por las 235 comprobaciones. |

### Decisiones

Todas cerradas menos una, que es de coordinación:

- [ ] **El informe en formato IEEE.** El profesor lo exige. Se cree que alguien
      del equipo lo está redactando, pero no está confirmado. Si nadie lo
      tiene, el contenido ya existe en `docs/` (PRD, ADR-004 a ADR-006, plan,
      resultados de tareas): es reorganizar, no escribir de cero.

Las de criterio experto —dificultad, pesos de priorización, umbral de cuello de
botella, excepción de tolerancia, reglas sin disparar y qué hacer con los datos
oficiales faltantes— quedaron **ratificadas como D-05 a D-10** en
[PROJECT_CONTEXT.md](docs/context/PROJECT_CONTEXT.md#decisiones-de-criterio-experto-ratificadas-2026-08-05),
cada una con su justificación.

### Datos que faltan (no bloquean)

El programa de la universidad no declara créditos, prerrequisitos ni horarios.
Se entrega con valores provisionales **etiquetados como tales** curso por curso
(decisión D-10). Si aparecen los oficiales, es un cambio en `data/` y **cero
líneas de código**: ADR-006 mantiene los datos fuera del código.

Consecuencia honesta para la defensa: los cuellos de botella que reporta el
sistema son correctos **dado el grafo cargado**, y ese grafo es de ejemplo. El
razonamiento es real; los datos de entrada, parciales.

---

## Alcance

**Sí:** motor de inferencia propio, base de conocimiento auditable,
recomendaciones explicadas, estadísticas del estudiante y del catálogo, CLI
interactiva.

**No:** matrícula real, interfaz web, aprendizaje automático, malla curricular
completa, horarios con hora exacta. Cada exclusión está justificada en su ADR
y documentada como trabajo futuro.
