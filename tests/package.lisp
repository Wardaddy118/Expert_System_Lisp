;;;; tests/package.lisp
;;;;
;;;; Paquete de pruebas. A diferencia de src/package.lisp, aqui SI se usa
;;;; :USE de otro paquete ademas de common-lisp (:FIVEAM): es el estilo
;;;; idiomatico de FiveAM y este paquete no es una capa de la arquitectura
;;;; en tres niveles, es el arnes de pruebas.

(defpackage #:expert-system.tests
  (:use #:common-lisp #:fiveam)
  ;; No se llama RUN-ALL-TESTS: FIVEAM ya exporta un simbolo con ese
  ;; nombre (FIVEAM:RUN-ALL-TESTS), y al hacer :USE de FIVEAM esta
  ;; heredado aqui; definir una funcion propia con el mismo nombre
  ;; viola el lock de paquete de FIVEAM.
  (:export #:run-project-tests))

(in-package #:expert-system.tests)

(def-suite all-tests
  :description "Todas las pruebas del sistema experto de recomendaciones academicas.")
