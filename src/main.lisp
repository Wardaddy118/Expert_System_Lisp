;;;; src/main.lisp
;;;;
;;;; Punto de entrada del sistema (ADR-004). Es el unico archivo del
;;;; proyecto donde se permitiria codigo especifico de SBCL -- hoy no lo
;;;; necesita, pero aqui es donde iria si se agrega manejo de argumentos
;;;; de linea de comandos con SB-EXT:*POSIX-ARGV*, por ejemplo.

(in-package #:common-lisp-user)

(defun main ()
  "Corre la sesion de demostracion sobre el catalogo y el perfil de
   prueba (data/), e imprime el informe en la salida estandar. Es lo que
   invoca run.lisp con sbcl --script."
  (expert-system.cli:start))
