;;;; run-interactive.lisp
;;;;
;;;; Punto de arranque de la sesion interactiva: sbcl --script run-interactive.lisp
;;;;
;;;; Se separa de run.lisp a proposito. run.lisp corre la demostracion con
;;;; un perfil fijo y por eso es reproducible: lo usa el gate de
;;;; verificacion y no puede quedarse esperando que alguien teclee. Este
;;;; script es el que pregunta.

(require :asdf)

(let ((root (make-pathname :directory (pathname-directory *load-truename*))))
  (push root asdf:*central-registry*)
  (asdf:load-system :expert-system))

(cl-user::main-interactive)
