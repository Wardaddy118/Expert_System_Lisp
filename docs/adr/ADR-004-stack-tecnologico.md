# ADR-004: Stack tecnológico

> **Status:** Accepted
> **Fecha:** 2026-08-05
> **Decisión asociada:** D-02 (`docs/context/PROJECT_CONTEXT.md`)

---

## Contexto

El curso exige que el sistema experto se desarrolle en Lisp. Eso fija el
lenguaje pero deja abierto todo lo demás: qué implementación, cómo se organiza
y carga el sistema, cómo se obtienen dependencias, con qué se prueba y cómo se
presenta al usuario.

Las fuerzas en juego:

- El equipo es estudiantil y el plazo llega hasta la semana 15.
- Debe demostrarse en vivo, en la máquina de alguien del equipo.
- El entorno de desarrollo actual es Windows 11 con la extensión Alive de
  VS Code, y ya hay **SBCL 2.6.7** instalado.
- El repositorio ya contiene `quicklisp.lisp`, el instalador de Quicklisp,
  señal de que se pensaba usar ese gestor.
- El gate de verificación de ACE (`.ace/scripts/verify.sh`) necesita un
  comando de aceptación real que corra sin intervención humana.

---

## Decisión

El sistema se construye sobre:

- **Common Lisp ANSI** como lenguaje, con **SBCL 2.6.7** como implementación
  de referencia. El código específico de SBCL —manejo de argumentos de línea
  de comandos y salida del proceso— se aísla en `src/main.lisp`; el resto del
  sistema es ANSI portable.
- **ASDF** para definir el sistema, sus componentes y el orden de carga, en
  `expert-system.asd`. Se declaran dos sistemas: `expert-system` y
  `expert-system/tests`.
- **Quicklisp** para obtener dependencias. La única dependencia externa es
  la de pruebas.
- **FiveAM** como framework de pruebas, invocado desde
  `asdf:test-system` para que el gate lo pueda correr sin interacción.
- **Interfaz de línea de comandos** interactiva, sin capa web ni gráfica.
- **Datos en S-expressions** bajo `data/`, leídos con `read`, no compilados
  dentro de los fuentes.

Explícitamente **no** se incluye: servidor web, base de datos, FFI, ni
librerías de motores de reglas.

---

## Alternativas consideradas

### Alternativa 1: Clojure o Racket en vez de Common Lisp

Ambos son Lisps y tienen mejor tooling moderno.

- **Pros:** Ecosistema más accesible, mejor documentación para principiantes.
- **Contras:** Clojure arrastra la JVM; Racket se aleja de la tradición de
  sistemas expertos que el curso enseña.
- **Por qué se rechazó:** El curso enseña sistemas expertos en la tradición de
  Common Lisp y CLIPS. Cambiar de dialecto arriesga que el trabajo no cuente
  como cumplido.

### Alternativa 2: CLISP en vez de SBCL

- **Pros:** Instalación más liviana, históricamente popular en cursos.
- **Contras:** Mucho más lento, desarrollo estancado, peores mensajes de error.
- **Por qué se rechazó:** SBCL ya está instalado y funcionando en la máquina
  del equipo, compila a nativo y da diagnósticos de compilación mucho mejores
  —lo que importa cuando el gate compila cada archivo en cada verificación.

### Alternativa 3: Interfaz web con Hunchentoot

- **Pros:** Demostración más vistosa.
- **Contras:** Agrega dependencias, despliegue y trabajo de frontend que
  compite con el motor de inferencia por el mismo tiempo.
- **Por qué se rechazó:** Decisión D-02. El motor es lo que se evalúa; la
  interfaz solo tiene que no estorbar.

### Alternativa 4: Catálogo de cursos en JSON o CSV

- **Pros:** Editable con herramientas externas.
- **Contras:** Requiere un parser y una dependencia; convierte datos que ya
  son código Lisp legítimo en texto que hay que traducir.
- **Por qué se rechazó:** En Lisp los datos son S-expressions. `read` es el
  parser y ya viene incluido. Usar JSON aquí sería trabajo extra para perder
  homoiconicidad.

---

## Consecuencias

### Positivas

- Cero dependencias en tiempo de ejecución: el sistema corre con SBCL y nada
  más. La demostración no puede fallar por una descarga.
- `asdf:test-system` da un comando de aceptación limpio para el gate de ACE.
- Los datos en S-expressions se leen sin parser y se pueden inspeccionar y
  editar en el mismo editor que el código.
- Aislar lo específico de SBCL en un archivo mantiene abierta la puerta a
  probar en otra implementación si el profesor lo pide.

### Negativas

- SBCL en Windows tiene detalles de rutas propios (ver el gate
  `.ace/scripts/verify-lisp.sh`, donde una ruta `/tmp` de Git Bash le llega
  como `C:/tmp` y falla). Hay que cuidar rutas relativas.
- Sin interfaz gráfica, la demostración depende de que la salida de consola
  esté bien formateada. Eso es trabajo real, no gratis.
- Quicklisp introduce una dependencia de red **en tiempo de instalación**
  (para FiveAM). El sistema principal no la necesita, pero correr las pruebas
  en una máquina limpia sí.

### Neutras

- El repositorio conserva `quicklisp.lisp` en la raíz como instalador. No es
  código del proyecto y el gate lo excluye explícitamente del compile-check.

---

## Cumplimiento

- El gate `.ace/scripts/verify.sh` compila todos los fuentes con SBCL en cada
  verificación; un archivo que use algo no disponible falla ahí.
- La portabilidad se verifica por inspección: ningún archivo fuera de
  `src/main.lisp` debe contener el paquete `SB-EXT` ni ningún otro `SB-*`.
- La restricción de dependencias se verifica en `expert-system.asd`: el
  sistema `expert-system` debe declarar `:depends-on ()`. Solo
  `expert-system/tests` puede depender de FiveAM.

---

## Referencias

- `docs/context/PROJECT_CONTEXT.md` — decisiones de la fase DISCUSS
- `docs/adr/ADR-005-motor-inferencia.md` — por qué el motor se escribe desde cero
- `docs/adr/ADR-006-representacion-conocimiento.md` — formato de los datos
- `.ace/standards/lisp.md` — convenciones de código
