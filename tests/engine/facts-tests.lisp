;;;; tests/engine/facts-tests.lisp
;;;;
;;;; Pruebas de la memoria de trabajo. Hechos inventados, sin dominio
;;;; academico (.ace/standards/lisp.md).

(in-package #:expert-system.tests)
(in-suite all-tests)

(test assert-fact-adds-a-new-fact
  (let ((wm (engine:make-working-memory)))
    (engine:assert-fact '(color rojo) wm)
    (is-true (engine:fact-present-p '(color rojo) wm))))

(test assert-fact-is-idempotent
  "Afirmar el mismo hecho dos veces no lo duplica."
  (let ((wm (engine:make-working-memory)))
    (engine:assert-fact '(color rojo) wm)
    (engine:assert-fact '(color rojo) wm)
    (is (= 1 (length (engine:query-facts wm 'color))))))

(test query-facts-filters-by-relation
  (let ((wm (engine:make-working-memory)))
    (engine:assert-fact '(color rojo) wm)
    (engine:assert-fact '(shape circle) wm)
    (is (= 1 (length (engine:query-facts wm 'color))))
    (is (= 1 (length (engine:query-facts wm 'shape))))))

(test fact-present-p-is-false-for-unknown-fact
  (let ((wm (engine:make-working-memory)))
    (is-false (engine:fact-present-p '(color rojo) wm))))
