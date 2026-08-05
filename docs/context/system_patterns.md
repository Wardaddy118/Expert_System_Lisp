# Patrones del Sistema

> Patrones y convenciones estructurales de este proyecto.
> Todo agente y toda persona debe seguirlos.
> Las convenciones de escritura de código Lisp (nombres, sangría, docstrings,
> errores) viven en `.ace/standards/lisp.md` y no se repiten aquí.

**Nota:** el proyecto está en fase de diseño. Este documento describe los
patrones **acordados** que el código debe seguir; se actualizará con los
patrones **observados** conforme se implemente.

---

## Patrón arquitectónico: tres capas con dependencias unidireccionales

```text
┌──────────────────────────────────────────┐
│  CLI            src/cli/                 │
│  Unica capa con E/S de usuario           │
└────────────────────┬─────────────────────┘
                     ▼
┌──────────────────────────────────────────┐
│  DOMINIO        src/domain/              │
│  Conocimiento academico. Sin E/S.        │
└────────────────────┬─────────────────────┘
                     ▼
┌──────────────────────────────────────────┐
│  MOTOR          src/engine/              │
│  Generico. Sin dominio. Sin E/S.         │
└──────────────────────────────────────────┘
```

**Regla:** las dependencias van hacia abajo, nunca hacia arriba ni en ciclo.

**Cómo se verifica:** `src/engine/` no puede contener ningún símbolo del
dominio académico (`course`, `credit`, `prerequisite`, `student`). Su suite de
pruebas usa hechos inventados. Si el motor necesita saber de cursos para pasar
sus pruebas, la capa se rompió.

---

## Patrón: conocimiento como datos, no como código

El corazón del proyecto. Las reglas del dominio se **declaran**, no se
programan:

```lisp
;; Bien: la regla es una estructura inspeccionable
(defrule eligible-when-prerequisites-met
  "Implementa BR-001 y BR-002."
  :priority 10
  :when ((course ?id)
         (not (approved ?id))
         (prerequisites-satisfied ?id))
  :then ((eligible ?id)))

;; Mal: la regla es código y el motor deja de importar
(defun eligible-p (course-id student)
  (and (not (member course-id (student-approved student) :test #'equal))
       (every (lambda (r) (member r (student-approved student) :test #'equal))
              (prerequisites-of course-id))))
```

La segunda forma funciona y es más corta. Está prohibida: destruye la
trazabilidad, la extensibilidad y la razón de ser del proyecto (ADR-005).

**Prueba del patrón:** agregar una regla nueva no debe requerir modificar
ningún archivo de `src/engine/`.

---

## Patrón: hechos planos con símbolo de relación al frente

```lisp
;; Bien
(prerequisite "CI-2400" "CI-1201")
(prerequisite "CI-2400" "MA-1001")

;; Mal: anidamiento, obliga al matcher a manejar listas dentro de patrones
(prerequisite "CI-2400" ("CI-1201" "MA-1001"))

;; Mal: property list, rompe el matching posicional
(:type prerequisite :course "CI-2400" :requires "CI-1201")
```

Aridad fija, sin anidamiento, un hecho por afirmación. El catálogo completo de
relaciones está en `.ace/knowledge/entities.md`; no se inventan relaciones
fuera de ahí.

---

## Patrón: tres capas de hechos distinguidas por relación

No hay marca en el hecho que diga si es dato o conclusión. La distinción está
en **qué relación** se usa y **quién puede afirmarla**:

| Capa | La afirma | Ejemplo |
| ---- | --------- | ------- |
| Catálogo | El cargador de datos | `(credits "CI-2400" 4)` |
| Perfil | La CLI o un archivo de perfil | `(approved "CI-1201")` |
| Derivada | Solo el motor, al disparar reglas | `(eligible "CI-2400")` |

**Anti-patrón:** una regla que afirme un hecho de catálogo o de perfil. Si
hace falta, el modelo está mal y se revisa `entities.md` antes de escribir
código.

---

## Patrón: la explicación es un subproducto de la traza

La traza no se construye para presentar bonito: es el registro que el motor
produce al disparar. La explicación se **reconstruye** recorriéndola.

```text
recommended "CI-2400"
  ← regla priority-target-area  (activada por: area "CI-2400" algorithms,
                                               target-area algorithms)
  ← regla eligible-when-prerequisites-met
      ← regla prerequisites-met  (activada por: approved "CI-1201")
```

**Anti-patrón:** generar el texto de la explicación dentro de la regla que
recomienda. Eso mezcla presentación con inferencia y deja de reflejar el
razonamiento real.

---

## Patrón: errores de datos abortan, errores de usuario advierten

| Situación | Comportamiento |
| --------- | -------------- |
| Ciclo de requisitos en `data/courses.lisp` | Condición `circular-prerequisites`, aborta la carga |
| Requisito que apunta a un curso inexistente | Condición `data-error`, aborta la carga |
| El estudiante declara un curso aprobado que no existe | Advertencia, se ignora, la sesión sigue |
| Ningún curso pasa los filtros | Se reportan los `excluded` con su razón, no lista vacía muda |

El criterio: **datos inválidos nunca se cargan a medias**; la entrada del
usuario nunca tumba la sesión.

---

## Patrón de pruebas: el motor se prueba sin dominio

```lisp
;; Bien: hechos inventados, el motor no sabe de cursos
(test refraction-prevents-infinite-loop
  "Una regla cuya conclusion reactiva su propia condicion alcanza quiescencia."
  (let ((wm (make-working-memory)))
    (assert-fact '(color rojo) wm)
    ...))

;; Mal: la prueba del motor usa el dominio academico
(test engine-recommends-course ...)
```

Cada regla de negocio lleva **dos** pruebas: una que la dispara y una que
verifica que no dispara cuando no corresponde. Una regla probada solo por el
caso positivo no está probada.

---

## Anti-patrones específicos de este proyecto

| Anti-patrón | Por qué es grave | Corrección |
| ----------- | ---------------- | ---------- |
| Filtrar con `remove-if` en vez de reglas | Elimina el sistema experto entero | Expresarlo como `defrule` |
| Lógica de dominio dentro de `engine/` | Rompe la genericidad del motor | Moverla a `domain/` |
| `format t` fuera de `cli/` | La presentación deja de ser una capa | Retornar datos, formatear en `cli/` |
| Regla que llama funciones Lisp arbitrarias en `:when` | La regla deja de ser inspeccionable | Expresar la condición con hechos |
| Estadísticas calculadas aparte del motor | Pueden contradecir lo que el motor concluyó (BR-030) | Derivarlas de la memoria de trabajo |
| Símbolos `SB-*` fuera de `main.lisp` | Rompe la portabilidad (ADR-004) | Aislar en `main.lisp` |
| Agregar conocimiento tocando el motor | Viola ADR-005 | Agregar `defrule` + BR + pruebas |

---

## Referencias a ADR

- [ADR-004: Stack tecnológico](../adr/ADR-004-stack-tecnologico.md)
- [ADR-005: Motor de inferencia](../adr/ADR-005-motor-inferencia.md)
- [ADR-006: Representación del conocimiento](../adr/ADR-006-representacion-conocimiento.md)

---

## Cuando aparezca un patrón nuevo

1. Discutirlo con el equipo.
2. Documentarlo aquí.
3. Abrir un ADR si es arquitectónicamente significativo.
4. Agregarlo a la lista de verificación de revisión.

---

*Última actualización: 2026-08-05*
