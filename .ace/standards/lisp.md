# Estándar de Código Common Lisp

> Convenciones obligatorias para todo el código Lisp del proyecto.
> Complementa `.ace/standards/coding.md` (principios generales); donde este
> documento sea más específico, este manda.
> Cambiar una regla de aquí requiere un ADR.

---

## Estructura de archivos

```text
expert-system.asd          Definición ASDF de los dos sistemas
src/
  package.lisp             Definiciones de paquetes (se carga primero)
  engine/
    facts.lisp             Memoria de trabajo, afirmación de hechos
    matching.lisp          Unificación de patrones con variables
    rules.lisp             Macro defrule y almacenamiento de reglas
    agenda.lisp            Conjunto de conflicto, resolución, refracción
    inference.lisp         Ciclo match-select-act, quiescencia, traza
  domain/
    loader.lisp            Carga y validación de data/
    knowledge.lisp         Las defrule del dominio académico
    explain.lisp           Reconstrucción de explicaciones desde la traza
    stats.lisp             Estadísticas de estudiante y de catálogo
  cli/
    session.lisp           Captura de perfil, flujo de la sesión
    format.lisp            Presentación en texto
  main.lisp                Punto de entrada. Único lugar con código SBCL
tests/
  ...                      Un archivo por archivo de src/
data/
  courses.lisp             Catálogo
  profiles/                Perfiles de ejemplo
```

**Invariante de dependencias:** `engine/` no conoce `domain/`, `domain/` no
conoce `cli/`. Se verifica por inspección: ningún archivo de `engine/` puede
mencionar un símbolo del dominio académico (curso, crédito, requisito).

---

## Paquetes

- Un paquete por capa: `expert-system.engine`, `expert-system.domain`,
  `expert-system.cli`.
- Todos se definen en `src/package.lisp`, nunca dispersos.
- Se exporta lo mínimo. Un símbolo exportado es contrato.
- Prohibido `:use` de paquetes que no sean `:common-lisp`. Las dependencias
  entre capas se escriben con prefijo explícito: `engine:assert-fact`.

```lisp
(defpackage #:expert-system.engine
  (:use #:common-lisp)
  (:nicknames #:engine)
  (:export #:make-working-memory
           #:assert-fact
           #:defrule
           #:run
           #:trace-entries))
```

---

## Nombres

| Elemento | Convención | Ejemplo |
| -------- | ---------- | ------- |
| Funciones y variables | `kebab-case` | `assert-fact`, `conflict-set` |
| Predicados | sufijo `-p` | `fact-matches-p`, `acyclic-p` |
| Funciones destructivas | prefijo `n` o sufijo `!` documentado | `nreverse-agenda` |
| Variables especiales | `*orejas*` | `*working-memory*` |
| Constantes | `+orejas+` | `+max-difficulty+` |
| Estructuras y clases | sustantivo simple | `rule`, `binding`, `trace-entry` |
| Archivos | `kebab-case.lisp` | `matching.lisp` |

- En inglés. El dominio también: `course`, no `curso`. Los comentarios y
  docstrings van en español.
- Nada de abreviaturas salvo las universales (`id`, `wm` documentado una vez).

---

## Estilo

- Sangría estándar de Common Lisp: la que aplica SLIME/Alive por omisión. No
  se pelea con el editor.
- Paréntesis de cierre agrupados al final, nunca en línea propia.
- Máximo 100 columnas.
- Una función hace una cosa. Si pasa de ~40 líneas, se parte.

```lisp
;; Bien
(defun prerequisites-satisfied-p (course-id wm)
  "Retorna T si todos los requisitos de COURSE-ID están aprobados en WM."
  (every (lambda (req) (fact-present-p `(approved ,req) wm))
         (prerequisites-of course-id wm)))

;; Mal: cierre en línea propia, sin docstring
(defun prerequisites-satisfied-p (course-id wm)
  (every (lambda (req) (fact-present-p `(approved ,req) wm))
         (prerequisites-of course-id wm)
  )
)
```

---

## Documentación en el código

- **Toda función exportada lleva docstring.** No es opcional: es parte de la
  nota del proyecto.
- El docstring dice qué retorna y qué condiciones señala, no cómo funciona.
- Las `defrule` del dominio citan su regla de negocio:

```lisp
(defrule eligible-when-prerequisites-met
  "Implementa BR-001 y BR-002: un curso es elegible si sus requisitos
   están aprobados y el curso mismo no lo está."
  :priority 10
  :when ((course ?id)
         (not (approved ?id))
         (prerequisites-satisfied ?id))
  :then ((eligible ?id)))
```

- Los comentarios explican **por qué**, no qué. `;;` para comentarios de
  bloque sobre el código siguiente, `;` al final de línea.

---

## Manejo de errores

- Se usan condiciones de Common Lisp, no códigos de retorno ni `nil` como
  señal de error.
- Se define una jerarquía propia en `engine` y `domain`:

```lisp
(define-condition data-error (error)
  ((file :initarg :file :reader data-error-file))
  (:documentation "Error en los archivos de data/."))

(define-condition circular-prerequisites (data-error)
  ((cycle :initarg :cycle :reader circular-prerequisites-cycle))
  (:report (lambda (c s)
             (format s "Ciclo de requisitos: ~{~a~^ → ~}"
                     (circular-prerequisites-cycle c)))))
```

- **Errores de datos abortan la carga** con un mensaje que nombra el archivo y
  el problema. Nunca se cargan datos inválidos "a medias".
- **Errores de entrada del usuario no abortan la sesión**: se advierte y se
  continúa (p. ej. un curso aprobado que no está en el catálogo).
- Prohibido `(ignore-errors ...)` sin comentario que justifique qué error se
  espera y por qué es seguro tragárselo.

---

## Pruebas

- FiveAM. Un `test-suite` por capa, un `test` por comportamiento.
- Nombre del test = qué comportamiento verifica, no qué función llama.

```lisp
(test refraction-prevents-infinite-loop
  "Una regla cuya conclusión reactiva su propia condición debe alcanzar
   quiescencia, no colgarse."
  ...)
```

- Las pruebas del motor usan **hechos inventados** (`(color rojo)`), nunca del
  dominio académico. Si el motor necesita saber de cursos para pasar sus
  pruebas, está contaminado (ADR-005 §Cumplimiento).
- Toda regla de negocio lleva prueba de disparo y prueba de no-disparo.
- Ninguna prueba depende del orden de iteración de una tabla hash.

---

## Prohibiciones

| Prohibido | Razón |
| --------- | ----- |
| `eval` en tiempo de ejecución | Las reglas se interpretan, no se evalúan |
| Símbolos `SB-*` fuera de `src/main.lisp` | Portabilidad (ADR-004) |
| Variables globales mutables fuera de `*working-memory*` y `*rules*` | Determinismo (NFR-005) |
| Lógica de dominio dentro de `engine/` | Genericidad del motor (ADR-005) |
| `defrule` que llame funciones Lisp arbitrarias en `:when` | Las reglas deben ser datos inspeccionables |
| Dependencias externas en el sistema `expert-system` | ADR-004; solo `expert-system/tests` puede depender de FiveAM |
| `format t` fuera de `cli/` | La presentación es una capa |

---

## Antes de dar una tarea por terminada

```markdown
- [ ] `.ace/scripts/verify.sh` pasa (VERIFY_RESULT=pass)
- [ ] Toda función exportada tiene docstring
- [ ] Las defrule nuevas citan su BR
- [ ] Hay pruebas de disparo y de no-disparo
- [ ] Ningún símbolo SB-* fuera de main.lisp
- [ ] engine/ no menciona el dominio académico
- [ ] Se actualizó docs/progress/task_<ID>_result.md
```

---

## Referencias

- `docs/adr/ADR-004-stack-tecnologico.md`
- `docs/adr/ADR-005-motor-inferencia.md`
- `docs/adr/ADR-006-representacion-conocimiento.md`
- `.ace/knowledge/business-rules.md`
