# Guion de presentación

Cuatro bloques, alineados con el documento de diseño
([DISENO-Y-ARQUITECTURA.pdf](DISENO-Y-ARQUITECTURA.pdf)). Duración total
estimada: **15 minutos**, más preguntas.

Las frases en cursiva son para decirlas tal cual si sirve. El resto es qué
cubrir, no cómo.

| Bloque | Tema | Minutos | Secciones del PDF |
| ------ | ---- | ------- | ----------------- |
| 1 | Contexto y problema | 3 | 1 y 11 |
| 2 | Decisiones de arquitectura | 4 | 2, 4 y 5 |
| 3 | Requerimientos y reglas | 3 | 6 y 7 |
| 4 | Demostración en vivo | 5 | 3, 8, 9 y 10 |

> **Si son dos personas:** una toma los bloques 1 y 2, la otra el 3 y el 4.
> El corte natural está entre «cómo lo diseñamos» y «qué hace».

---

## Bloque 1 — Contexto y problema (3 min)

**Objetivo:** que quede claro qué problema resuelve y por qué era un sistema
experto y no un programa cualquiera.

### Qué decir

Arrancá con el problema, no con la tecnología.

> *«Cada cuatrimestre el estudiante tiene que cruzar a mano el plan de
> estudios, lo que ya aprobó, los choques de horario y hacia dónde quiere ir
> profesionalmente. Nadie tiene tiempo de hacerlo bien, y las consecuencias
> se ven tarde: semestres sobrecargados, y cursos que resultan ser cuello de
> botella y se descubren cuando ya atrasaron la carrera.»*

Después el planteamiento del proyecto:

> *«Construimos un sistema experto en Common Lisp que recomienda cursos según
> intereses, cursos aprobados, horario disponible, dificultad y área
> profesional, y que además da estadísticas.»*

Y ahora la frase que ordena toda la presentación:

> *«Lo importante no es que ordene una lista de cursos. Eso lo resolvíamos con
> un filtro y un `sort` en una tarde. Lo importante es que hay un motor de
> inferencia propio, con reglas declarativas, que además **explica** por qué
> recomienda cada curso.»*

### Cerrá el bloque con la honestidad de los datos

Esto conviene decirlo temprano y de frente. Si sale después, a pregunta,
parece que lo estaban escondiendo.

> *«Un aviso sobre los datos: el programa que nos dio la universidad trae
> código, nombre, cuatrimestre, laboratorio y bloque electivo. No trae
> créditos, ni prerrequisitos, ni horarios. Todo eso lo asignamos nosotros con
> criterios documentados, y está marcado curso por curso en el archivo de
> datos. Así que el razonamiento del motor es real; los datos de entrada son
> parciales, y lo decimos.»*

---

## Bloque 2 — Decisiones de arquitectura (4 min)

**Objetivo:** mostrar que las decisiones tienen justificación escrita, no que
salieron por casualidad.

### 2.1 Las tres capas

Mostrá el diagrama de la sección 2 del PDF.

> *«El sistema tiene tres capas y las dependencias van en una sola dirección.
> La CLI depende del dominio, el dominio depende del motor, y el motor no
> depende de nada.»*

La regla que sostiene todo:

> *«El motor no puede saber qué es un curso. Ningún archivo de `engine/`
> menciona un curso, un crédito o un requisito, y su suite de pruebas usa
> hechos inventados como `(color rojo)`. Si el motor necesitara conocer el
> dominio para pasar sus pruebas, dejaría de ser un motor y sería un
> recomendador disfrazado.»*

### 2.2 Por qué el motor es propio

La decisión que más van a preguntar. Está en ADR-005.

> *«Evaluamos usar CLIPS o LISA. Los descartamos a propósito: el trabajo se
> habría convertido en integración y el núcleo evaluable habría quedado fuera
> del repositorio.»*

Si preguntan por RETE:

> *«También consideramos implementar una red RETE. La rechazamos por riesgo de
> cronograma: a esta escala, 47 cursos y 25 reglas, el matching directo
> resuelve en menos de un segundo. Está documentado como trabajo futuro.»*

### 2.3 El conocimiento es dato, no código

Mostrá una `defrule` del PDF, sección 6.

> *«Las reglas no son código, son estructuras de datos que el motor
> interpreta. Agregar conocimiento nuevo es agregar una regla; no se toca el
> motor. Y eso no es una promesa: hay una prueba que agrega una regla en
> tiempo de ejecución y verifica que dispara sin modificar nada del motor.»*

### 2.4 El modelo de hechos

Sección 5 del PDF, diagrama de las tres capas de hechos.

> *«Todo lo que el motor conoce es un hecho: una lista plana con la relación
> al frente. Hay tres capas: lo que viene del catálogo, lo que viene del
> perfil del estudiante, y lo que el motor deriva. Ninguna regla puede
> afirmar un hecho de las dos primeras. Esa disciplina es la que hace que la
> traza se pueda leer.»*

---

## Bloque 3 — Requerimientos y reglas (3 min)

**Objetivo:** mostrar que hay conocimiento experto de verdad, especificado
antes de programarlo.

### 3.1 De requisito a regla

> *«Los requisitos están en un PRD, con requisitos funcionales y no
> funcionales. Cada pieza de conocimiento experto se especificó primero en
> lenguaje natural, con un identificador BR, y después se implementó. Cada
> regla del código cita en su docstring el BR que implementa, así que la
> especificación y el código se pueden confrontar en cualquier momento.»*

Mostrá la tabla de la sección 7 del PDF.

### 3.2 Los tres tipos de regla

> *«Hay reglas duras, que son invariantes: nunca se recomienda un curso sin
> sus requisitos, ni uno que choque con el horario. Hay reglas estándar, como
> el cuello de botella. Y hay reglas blandas de priorización, que son los
> pesos: el área objetivo suma 10, un interés suma 5, ser cuello de botella
> suma 8.»*

### 3.3 La regla que muestra conocimiento experto real

Esta es la que vale la pena contar despacio. Prepara la demo del bloque 4.

> *«La más interesante es una excepción. La regla dice que no se recomienda un
> curso que supere la tolerancia a la dificultad que declaró el estudiante.
> Pero si ese curso es cuello de botella y la supera por un solo nivel, sí se
> recomienda, con una advertencia: atrasarlo cuesta más que llevarlo.»*

> *«Eso es conocimiento experto: una excepción con criterio, no un filtro
> rígido. Y lo van a ver funcionando ahora.»*

---

## Bloque 4 — Demostración en vivo (5 min)

**Objetivo:** que vean el sistema corriendo y entiendan lo que aparece en
pantalla.

### Antes de empezar

- Terminal abierta en la raíz del repositorio, fuente grande.
- Correr los comandos **una vez antes** de presentar: la primera corrida
  compila y tarda más.
- Tener el PDF abierto en otra ventana por si preguntan.

### Paso 1 — El sistema está sano (30 s)

```bash
sh .ace/scripts/verify.sh
```

> *«Esto compila el sistema completo y corre las 358 pruebas. La última línea
> es el veredicto.»*

Señalá `VERIFY_RESULT=pass gate=all`.

### Paso 2 — Una sesión completa (1 min)

```bash
sbcl --script run.lisp
```

Dejá que corra y **subí hasta el principio**. Mostrá en este orden:

1. **RECOMENDACIONES** — *«Cada curso con su puntaje y las razones. Esas
   razones no son texto fijo: cada una es una regla que efectivamente
   disparó.»*
2. **CURSOS DESCARTADOS** — *«Cada uno con su motivo. Saber por qué no salió
   un curso suele importar más que por qué sí.»*
3. **ESTADÍSTICAS** — *«Avance de carrera, créditos y distribución por área.»*
4. **ESTADÍSTICAS DEL CATÁLOGO** — *«Cuellos de botella y cobertura de
   reglas: cuántas de las 25 dispararon.»*
5. **TRAZA DEL MOTOR** — *«El ciclo de inferencia completo, disparo por
   disparo. Esta es la evidencia de que hay un motor y no lógica cableada.»*

### Paso 3 — La sesión interactiva y la excepción (2 min)

```bash
sbcl --script run-interactive.lisp
```

Elegí la **opción 6** (*Tolerancia baja a la dificultad*).

Cuando aparezca la primera recomendación, pará y señalá la advertencia:

```text
1. Estructura de Datos
   Puntuacion: 22
   Dificultad: 4
   Razones:
   - Es un curso cuello de botella: atrasarlo bloquea otros cursos (+8 puntos).
   - Coincide con tu area profesional objetivo (+10 puntos).
   - Abre camino a un curso de tu area profesional objetivo (+4 puntos).
   Advertencias:
   - Supera tu tolerancia a la dificultad por un nivel, pero es un curso
     cuello de botella: atrasarlo cuesta mas que llevarlo ahora.
```

> *«Este estudiante declaró tolerancia baja, y el sistema le está recomendando
> un curso más difícil de lo que pidió. No es un error: es la excepción que
> les conté, y el sistema explica por qué la aplicó. El puntaje 22 son 8 por
> cuello de botella, 10 por el área objetivo y 4 por desbloquear otro curso.
> Cada sumando se puede rastrear a la regla que lo produjo.»*

### Paso 4 — Cierre (30 s)

Volvé a la cobertura de reglas de la salida.

> *«Esta métrica nos dice cuántas reglas dispararon. Si una regla nunca
> dispara, o sobra o los datos no la ejercitan; en ambos casos es algo que hay
> que mirar. Nos sirvió durante el desarrollo para encontrar conocimiento
> muerto.»*

Cerrá con el estado:

> *«El sistema corre una sesión completa en menos de un segundo, tiene 358
> pruebas verdes, 25 reglas y 47 cursos reales de la carrera. Todo está en el
> repositorio, con el documento de diseño y una guía de ejecución.»*

---

## Preguntas que van a hacer

| Pregunta | Respuesta corta |
| -------- | --------------- |
| **¿Esto es un sistema experto o un filtro con nombre bonito?** | Las pruebas de aceptación 4 y 5. El motor corre con `(color rojo)` sin un solo símbolo académico, y una regla declarada en tiempo de ejecución dispara sin tocar el motor. |
| **¿Por qué no usaron CLIPS?** | ADR-005. Habría convertido el trabajo en integración y sacado el núcleo evaluable del repositorio. |
| **¿De dónde sacaron que este curso es dificultad 4?** | Fórmula documentada: cuatrimestre más uno si tiene laboratorio, tope 5. Se deriva de dos datos que la universidad sí da, así que es reproducible. Es heurística del equipo, no clasificación de la universidad. |
| **¿Estos prerrequisitos son reales?** | No. El programa no declara ninguno; pusimos seis de demostración. Los cuellos de botella son correctos **dado el grafo cargado**, y ese grafo es de ejemplo. Está documentado campo por campo. |
| **¿Y si consiguen los datos oficiales?** | Es un cambio en `data/` y cero líneas de código: la arquitectura mantiene los datos fuera del programa (ADR-006). |
| **¿Cómo garantizan que no recomienda algo imposible?** | Es un invariante probado sobre todos los perfiles: ninguna recomendación viola un requisito ni choca con el horario. |
| **¿El motor puede quedarse en un bucle?** | No. Refracción: una misma instanciación no dispara dos veces. Hay una prueba con una regla que se reactiva a sí misma y verifica que llega a quiescencia. |
| **¿Por qué el tope de créditos no es una regla?** | Compara entre sí un conjunto de tamaño variable, y el matching por patrones tiene aridad fija. Corre como post-procesamiento después de la quiescencia, y está documentado como limitación del modelo de matching. |

---

## Errores a evitar

- **No arranques por el código.** El problema primero, la solución después.
- **No leas el PDF en voz alta.** El PDF es el respaldo; ustedes cuentan la
  historia.
- **No escondas lo provisional.** Decilo en el bloque 1, con naturalidad. Si
  sale a pregunta, se ve peor.
- **No prometas lo que no está.** No hay interfaz web, no hay matrícula real,
  no hay aprendizaje automático — y cada exclusión tiene su justificación.
- **No corras la demo por primera vez en vivo.** Probala antes; la primera
  corrida compila y tarda.

---

## Comandos, para tener a mano

```bash
sh .ace/scripts/verify.sh            # el gate: VERIFY_RESULT=pass
sbcl --script run.lisp               # sesión completa con perfil fijo
sbcl --script run-interactive.lisp   # sesión que pregunta (opción 6 para la demo)
sbcl --script run-tests.lisp         # 358 pruebas
```
