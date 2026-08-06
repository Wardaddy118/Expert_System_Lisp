;;;; run-tests.lisp
;;;;
;;;; Punto de arranque: sbcl --script run-tests.lisp
;;;;
;;;; Carga Quicklisp (unicamente para obtener FiveAM, la unica
;;;; dependencia externa del proyecto y solo de pruebas, ADR-004),
;;;; registra este directorio ante ASDF a partir de la ruta de este mismo
;;;; archivo y corre la suite completa. Termina con codigo de salida 1 si
;;;; alguna prueba falla, para que sirva como gate de verificacion.

(require :asdf)

(let ((quicklisp-init (merge-pathnames "quicklisp/setup.lisp" (user-homedir-pathname))))
  (if (probe-file quicklisp-init)
      (load quicklisp-init)
      (error "No se encontro Quicklisp en ~a. Se necesita para cargar FiveAM."
             quicklisp-init)))

;; FiveAM es la unica dependencia externa del proyecto y solo de pruebas
;; (ADR-004). Hay que pedirla con QL:QUICKLOAD, no con ASDF:LOAD-SYSTEM:
;; asdf resuelve lo que ya esta instalado pero NO descarga lo que falta, asi
;; que la suite reventaba con "Component #:FIVEAM not found" en cualquier
;; maquina donde nadie la hubiera bajado a mano antes. Este es el paso que
;; hace que un clon limpio pueda correr las pruebas.
(ql:quickload :fiveam :silent t)

(let ((root (make-pathname :directory (pathname-directory *load-truename*))))
  (push root asdf:*central-registry*)
  (asdf:load-system :expert-system/tests))

(if (expert-system.tests:run-project-tests)
    (sb-ext:exit :code 0)
    (sb-ext:exit :code 1))
