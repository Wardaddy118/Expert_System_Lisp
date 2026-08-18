# Cómo ejecutar el sistema

Guía para correr, probar y demostrar el Sistema Experto de Recomendaciones
Académicas. Pensada para alguien que acaba de clonar el repositorio y nunca lo
ha corrido.

---

## 1. Requisitos previos

| Programa | Versión | Para qué |
| -------- | ------- | -------- |
| **SBCL** | 2.6 o superior | Ejecutar el sistema. [Descarga](https://www.sbcl.org/platform-table.html) |
| **Git Bash** (solo Windows) | cualquiera | Correr el gate de verificación (`.sh`) |
| Conexión a internet | una sola vez | Descargar FiveAM, la única dependencia externa |

**El sistema en sí no tiene dependencias.** Solo la suite de pruebas usa
FiveAM, y se descarga sola la primera vez (ADR-004).

Comprobar que SBCL está instalado:

```bash
sbcl --version
```

Debe responder algo como `SBCL 2.6.7`. Si dice "command not found", SBCL no
está en el PATH.

---

## 2. Clonar

```bash
git clone https://github.com/Wardaddy118/Expert_System_Lisp.git
cd Expert_System_Lisp
```

Todo está en la rama `main`. No hace falta cambiar de rama.

---

## 3. Las tres formas de correrlo

### A. Demostración con perfil fijo

```bash
sbcl --script run.lisp
```

Corre una sesión completa con `data/profiles/sample-profile.lisp` y muestra el
informe entero. **No pregunta nada**, así que es la forma más rápida de ver que
todo funciona y la que conviene para una captura de pantalla.

### B. Sesión interactiva

```bash
sbcl --script run-interactive.lisp
```

Primero pregunta si querés responder las preguntas o cargar uno de los cinco
perfiles de ejemplo. Si elegís responder, hace seis preguntas:

1. Cursos que ya aprobaste (códigos separados por espacios, o ENTER)
2. Áreas que te interesan (números de la lista, varios)
3. Tu área profesional objetivo (un número)
4. Cuándo podés llevar clases (días, luego franjas)
5. Tolerancia a la dificultad (1 a 5)
6. Tope de créditos

**Cualquier pregunta se puede dejar en blanco**: toma el valor por omisión.

Al final podés escribir un código de curso para ver por qué salió recomendado o
por qué se descartó, las veces que quieras. ENTER termina la sesión.

### C. Suite de pruebas

```bash
sbcl --script run-tests.lisp
```

Debe terminar con:

```text
Did 358 checks.
   Pass: 358 (100%)
   Skip: 0 ( 0%)
   Fail: 0 ( 0%)
```

La primera corrida tarda más porque descarga FiveAM y compila todo.

---

## 4. El gate de verificación

Es lo que decide si el proyecto está sano. Compila el sistema con ASDF en orden
de dependencias y corre la suite completa:

```bash
sh .ace/scripts/verify.sh
```

La última línea es el veredicto, pensado para leerse de un vistazo o desde un
script:

```text
VERIFY_RESULT=pass gate=all
```

Si dice `fail`, **algo está roto**: no es un aviso cosmético, y el gate sale con
código distinto de cero.

---

## 5. Para la demostración en vivo

El recorrido que muestra todo lo que el sistema sabe hacer, en orden:

```bash
sh .ace/scripts/verify.sh        # 1. el sistema esta sano
sbcl --script run.lisp           # 2. una sesion completa de punta a punta
sbcl --script run-interactive.lisp   # 3. la sesion que pregunta
```

En el paso 3, los cinco perfiles muestran comportamientos distintos:

| Opción | Perfil | Qué se ve |
| ------ | ------ | --------- |
| 2 | Demostración | Las **seis** razones de descarte en una sola corrida |
| 3 | Primer ingreso | Solo cursos sin requisitos; avance de carrera en 0% |
| 4 | Avanzado | Avance alto y cursos de formación general recomendados |
| 5 | Horario apretado | El horario como filtro dominante |
| 6 | Tolerancia baja | Un cuello de botella recomendado **con advertencia** |

La opción 6 es la más interesante de mostrar: el sistema recomienda un curso
que **excede** la tolerancia declarada, y explica por qué lo hace igual.

### Qué señalar en la salida

- **RECOMENDACIONES** — cada curso con su puntaje y las razones que lo
  produjeron. Esa es la explicación, y sale de la traza del motor, no de un
  texto escrito a mano.
- **CURSOS DESCARTADOS** — cada uno con su motivo. Saber por qué *no* salió un
  curso suele importar más que por qué sí.
- **ESTADISTICAS** — avance de carrera, créditos aprobados y distribución por
  área.
- **ESTADISTICAS DEL CATALOGO** — cuellos de botella y **cobertura de reglas**:
  cuántas de las 25 reglas dispararon.
- **TRAZA DEL MOTOR** — el ciclo de inferencia completo, regla por regla.

---

## 6. Cargar un perfil concreto sin la CLI

Desde un REPL de SBCL, parado en la raíz del repositorio:

```lisp
(require :asdf)
(push (truename ".") asdf:*central-registry*)
(asdf:load-system :expert-system)

;; Informe completo de un perfil cualquiera
(cli:start :profile-path "data/profiles/advanced.lisp")

;; O trabajar con la sesion como dato
(let ((s (domain:run-session "data/courses.lisp" "data/profiles/advanced.lisp")))
  (domain:session-recommendations s))
```

---

## 7. Modificar los datos

Ni el catálogo ni los perfiles son código: se editan y se vuelve a correr, sin
recompilar nada (ADR-006).

| Para... | Editar |
| ------- | ------ |
| Agregar o cambiar un curso | `data/courses.lisp` |
| Crear un perfil nuevo | `data/profiles/` (leer su `README.md` primero) |
| Cambiar el conocimiento experto | `.ace/knowledge/business-rules.md` **y** `src/domain/knowledge.lisp` |

Al agregar una regla hay que agregarla en los dos lugares y con sus dos pruebas
(de disparo y de no-disparo). Es la regla número 2 del proyecto.

El cargador valida los datos al arrancar: códigos duplicados, requisitos que
apuntan a cursos inexistentes y ciclos en el grafo de requisitos abortan la
carga con un mensaje que dice qué archivo y qué problema.

---

## 8. Si algo falla

| Síntoma | Causa probable | Solución |
| ------- | -------------- | -------- |
| `sbcl: command not found` | SBCL no está en el PATH | Reinstalar SBCL marcando "agregar al PATH" |
| `Component #:FIVEAM not found` | Primera corrida sin internet | Conectarse y volver a correr `run-tests.lisp` |
| `sh: command not found` (Windows) | Falta Git Bash | Instalar Git for Windows, o correr `run-tests.lisp` directo |
| `bad interpreter` en los `.sh` | Los scripts se clonaron con CRLF | `git config core.autocrlf input` y volver a clonar |
| `No se pudo cargar los datos` | Ruta mal escrita, o error en `data/` | El mensaje dice el archivo y el problema |
| La sesión interactiva no espera respuestas | La entrada está redirigida | Correrla en una terminal de verdad |

**Importante:** todos los comandos se corren **desde la raíz del repositorio**.
Las rutas a `data/` son relativas.

---

## 9. Estructura, en una pantalla

```text
run.lisp              Demostracion con perfil fijo
run-interactive.lisp  Sesion que pregunta
run-tests.lisp        Suite de pruebas
expert-system.asd     Definicion ASDF

src/engine/    Motor generico: no sabe que es un curso
src/domain/    Conocimiento academico: 25 reglas, explicaciones, estadisticas
src/cli/       Preguntas y presentacion: unica capa con entrada/salida

data/courses.lisp   47 cursos (Bachillerato Ing. Sistemas, Fidelitas)
data/profiles/      Cinco perfiles de demostracion

tests/              Espejo de src/, mas la suite de aceptacion
docs/               PRD, ADR, plan, registro de tareas
.ace/               Framework de trabajo, base de conocimiento, gate
```

---

## 10. Advertencia sobre los datos

El programa que suministró la universidad **solo** trae código, nombre,
cuatrimestre, laboratorio, curso colegiado y bloque electivo.

Los créditos, la dificultad, el área profesional, los horarios y los
prerrequisitos son **provisionales**: los asignó el equipo con criterios
documentados, y están marcados curso por curso en la cabecera de
`data/courses.lisp`.

Consecuencia que conviene decir al presentar: los cuellos de botella que
reporta el sistema son **correctos dado el grafo cargado**, y ese grafo es de
ejemplo. El razonamiento es real; los datos de entrada, parciales.
