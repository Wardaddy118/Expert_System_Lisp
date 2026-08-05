# ADR-005: Motor de inferencia propio con encadenamiento hacia adelante

> **Status:** Accepted
> **Fecha:** 2026-08-05
> **Decisión asociada:** D-01 (`docs/context/PROJECT_CONTEXT.md`)

---

## Contexto

El sistema debe recomendar cursos a partir de un perfil de estudiante. Se
podría resolver sin ningún motor: filtrar el catálogo con `remove-if`, sumar
puntajes con una función y ordenar con `sort`. Eso produciría recomendaciones
correctas y se escribiría en una tarde.

Ese atajo es exactamente lo que hay que evitar. El curso es de sistemas
expertos, y lo que se evalúa es la existencia de:

- una **base de conocimiento** separada del programa,
- un **motor de inferencia** genérico que no sabe nada de cursos,
- **trazabilidad** del razonamiento.

Un `cond` gigante cumple el requisito funcional y falla el objetivo del curso.
Además, sin motor no hay explicación: no queda registro de por qué se llegó a
una conclusión.

Fuerzas adicionales:

- El plazo llega a la semana 15 con un equipo estudiantil.
- El dominio parte de datos conocidos (cursos aprobados, intereses) y deriva
  conclusiones (cursos elegibles, priorizados). Los datos empujan hacia
  las conclusiones, no al revés.
- El volumen es pequeño: decenas de cursos, decenas de reglas.

---

## Decisión

Se implementa un **motor de producción con encadenamiento hacia adelante**
(forward chaining), escrito completo en Common Lisp, sin librerías externas.
El motor no conoce el dominio académico: solo hechos, patrones y reglas.

### Componentes

**1. Memoria de trabajo (working memory)**
Colección de hechos. Cada hecho es una lista con un símbolo de tipo al frente:

```lisp
(approved  "MA-1001")
(interest  algorithms)
(available monday morning)
(eligible  "CI-2400")
```

Cada hecho lleva un identificador de inserción monótono, que sirve para la
resolución de conflictos por recencia y para la traza.

**2. Reglas como datos**
Se declaran con una macro `defrule` que no genera código de decisión, sino una
estructura que el motor interpreta:

```lisp
(defrule eligible-when-prerequisites-met
  :priority 10
  :when ((course ?id)
         (not (approved ?id))
         (prerequisites-satisfied ?id))
  :then ((eligible ?id)))
```

El motor recorre estas estructuras. Agregar una regla **no requiere tocar el
motor** — esa es la prueba de que existe separación real (NFR-004).

**3. Pattern matching con variables**
Unificación de un patrón contra un hecho, con variables prefijadas por `?`.
Una variable se liga la primera vez que aparece y debe coincidir consistente-
mente después. `match` recibe patrón, hecho y bindings, y devuelve bindings
extendidos o un fallo. Es la pieza técnica más delicada y se construye y
prueba **antes** que cualquier regla del dominio.

**4. Agenda y resolución de conflictos**
En cada ciclo, todas las reglas cuyas condiciones se satisfacen forman el
conjunto de conflicto. La selección es determinista, en este orden:

1. Mayor `:priority` de la regla.
2. En empate, la instanciación cuyo hecho más reciente tenga el id de
   inserción más alto (recencia).
3. En empate, orden de declaración de la regla.

El tercer criterio existe para garantizar NFR-005: misma entrada, misma
salida, siempre.

**5. Refracción**
Una regla no vuelve a dispararse con el mismo conjunto de bindings. Sin esto
el motor entra en bucle infinito en cuanto una regla afirma un hecho que
vuelve a satisfacer su propia condición.

**6. Ciclo de inferencia**

```text
    ┌──────────────────────────────────────────┐
    │  MATCH: evaluar condiciones contra la    │
    │  memoria de trabajo → conjunto conflicto │
    └──────────────────┬───────────────────────┘
                       ▼
    ┌──────────────────────────────────────────┐
    │  SELECT: prioridad → recencia → orden    │
    │  descartando instanciaciones ya          │
    │  disparadas (refracción)                 │
    └──────────────────┬───────────────────────┘
                       ▼
    ┌──────────────────────────────────────────┐
    │  ACT: afirmar los hechos del :then con   │
    │  las variables sustituidas; registrar    │
    │  en la traza qué regla y con qué hechos  │
    └──────────────────┬───────────────────────┘
                       │
                       └──► repetir hasta quiescencia
                            (conjunto conflicto vacío)
```

**7. Traza de inferencia**
Cada disparo registra: regla, bindings, hechos que activaron las condiciones y
hechos producidos. La explicación al usuario (FR-030) se construye recorriendo
esta traza hacia atrás desde el hecho `(recommended ?id)`. La traza es un
producto del motor, no un `format` decorativo agregado después.

### Lo que el motor NO hace

- No hace encadenamiento hacia atrás. No se necesita: el flujo va de datos a
  conclusiones.
- No implementa RETE. Ver alternativas.
- No conoce cursos, créditos ni horarios. Todo el conocimiento académico vive
  en la base de reglas y en `data/`.

---

## Alternativas consideradas

### Alternativa 1: Usar LISA o CLIPS

Motores de producción ya construidos.

- **Pros:** RETE de verdad, maduros, mucho menos código propio.
- **Contras:** El trabajo se convierte en integración; el núcleo evaluable
  queda fuera del repositorio. CLIPS además requiere FFI.
- **Por qué se rechazó:** Decisión D-01. El motor es el entregable.

### Alternativa 2: Implementar RETE

Red de nodos que cachea resultados parciales del matching.

- **Pros:** Mucho mejor asintóticamente; sería el punto técnico más alto del
  proyecto.
- **Contras:** Es donde los proyectos estudiantiles se quedan atascados. La
  ganancia es nula a esta escala: con 60 cursos y 30 reglas, el matching
  ingenuo corre en milisegundos.
- **Por qué se rechazó:** Riesgo alto de no terminar para la semana 15, a
  cambio de un beneficio de rendimiento que nadie va a poder medir. Se
  documenta como trabajo futuro en el plan.

### Alternativa 3: Encadenamiento hacia atrás (backward chaining)

Partir de la meta "¿es recomendable el curso X?" y probarla.

- **Pros:** Natural para responder preguntas puntuales sobre un curso.
- **Contras:** La tarea real es "dame todos los cursos que me convienen", que
  obligaría a probar la meta una vez por cada curso del catálogo. Además, las
  estadísticas del catálogo (FR-041) necesitan las conclusiones de todos los
  cursos a la vez.
- **Por qué se rechazó:** El problema es de derivación, no de prueba. Forward
  chaining calcula todo en una corrida.

### Alternativa 4: Filtro funcional con puntajes, sin motor

- **Pros:** Se escribe en una tarde y funciona.
- **Contras:** No es un sistema experto. Sin base de conocimiento separada,
  sin trazabilidad, sin extensibilidad.
- **Por qué se rechazó:** Cumple el requisito funcional y falla el objetivo
  del curso. Está registrado aquí porque es la tentación real bajo presión de
  tiempo, y en revisión debe rechazarse explícitamente.

---

## Consecuencias

### Positivas

- La explicación (FR-030) sale gratis de la traza: es un subproducto del
  diseño, no una funcionalidad aparte que haya que inventar.
- Agregar conocimiento es agregar reglas. Las últimas semanas pueden dedicarse
  a enriquecer el comportamiento sin tocar código de motor.
- El motor es genérico y se puede probar con hechos de juguete, aislado del
  dominio académico. Eso hace las pruebas mucho más simples.
- Es exactamente el artefacto que el curso evalúa.

### Negativas

- El matching ingenuo es O(reglas × hechos^condiciones). A esta escala no
  importa, pero el sistema no escalaría a miles de hechos.
- El pattern matching con variables es la parte más difícil del proyecto y
  está al inicio del cronograma. Si se subestima, arrastra todo lo demás. Está
  registrado como el riesgo principal en el PRD.
- Sin refracción bien hecha, el motor cuelga. Necesita prueba específica.

### Neutras

- El motor tendrá más código que la lógica de dominio. Eso es normal y
  esperado en un sistema experto: el motor es infraestructura reutilizable.

---

## Cumplimiento

Se verifica con pruebas automatizadas, no por revisión visual:

1. **Genericidad:** la suite del motor usa hechos inventados (`(color rojo)`),
   sin ningún símbolo del dominio académico. Si el motor necesita saber de
   cursos para pasar sus pruebas, está contaminado.
2. **Extensibilidad (NFR-004):** una prueba agrega una regla nueva en tiempo de
   ejecución y verifica que dispara, sin modificar el motor.
3. **Determinismo (NFR-005):** una prueba corre el mismo escenario varias
   veces y exige traza idéntica.
4. **Terminación:** una prueba con una regla cuya conclusión reactiva su propia
   condición debe alcanzar quiescencia, no colgarse.
5. **Trazabilidad:** ninguna recomendación puede tener explicación vacía.

---

## Referencias

- `docs/adr/ADR-006-representacion-conocimiento.md` — formato de hechos y reglas
- `docs/requirements/PRD-recomendador-academico.md` — FR-010 a FR-014, FR-030
- `.ace/knowledge/business-rules.md` — reglas del dominio que el motor ejecuta
- `.ace/knowledge/glossary.md` — vocabulario del motor
