;;;; run.lisp
;;;;
;;;; Punto de arranque: sbcl --script run.lisp
;;;;
;;;; Registra este directorio ante ASDF a partir de la ruta de este mismo
;;;; archivo (nunca una ruta absoluta escrita a mano: *LOAD-TRUENAME* la
;;;; da en tiempo de ejecucion), carga el sistema expert-system -- que no
;;;; depende de nada externo (ADR-004) -- y corre la sesion de
;;;; demostracion.

(require :asdf)

(let ((root (make-pathname :directory (pathname-directory *load-truename*))))
  (push root asdf:*central-registry*)
  (asdf:load-system :expert-system))

(cl-user::main)
