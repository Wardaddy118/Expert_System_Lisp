;;;; tests/test-runner.lisp
;;;;
;;;; Corre la suite completa y expone un resultado booleano, para que
;;;; run-tests.lisp pueda traducirlo a un codigo de salida de proceso.

(in-package #:expert-system.tests)

(defun run-project-tests ()
  "Corre ALL-TESTS, imprime un resumen legible y retorna T si todas las
   pruebas pasaron, NIL si alguna fallo."
  (let ((result (run 'all-tests)))
    (explain! result)
    (results-status result)))
