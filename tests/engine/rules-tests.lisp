;;;; tests/engine/rules-tests.lisp
;;;;
;;;; Pruebas de DEFRULE como estructura de datos: registro y redefinicion.

(in-package #:expert-system.tests)
(in-suite all-tests)

(test defrule-registers-a-rule
  (let ((engine:*rules* nil))
    (engine:defrule ping-pong
      :priority 1 :when ((ping)) :then ((pong)))
    (is (= 1 (length engine:*rules*)))))

(test redefining-a-rule-replaces-it-instead-of-duplicating
  (let ((engine:*rules* nil))
    (engine:defrule dup-name :priority 1 :when ((a)) :then ((old-conclusion)))
    (engine:defrule dup-name :priority 2 :when ((a)) :then ((new-conclusion)))
    (is (= 1 (length engine:*rules*)))
    (let ((wm (engine:make-working-memory)))
      (engine:assert-fact '(a) wm)
      (engine:run wm)
      (is-true (engine:fact-present-p '(new-conclusion) wm))
      (is-false (engine:fact-present-p '(old-conclusion) wm)))))

(test extending-with-a-new-rule-requires-no-engine-changes
  "Prueba de NFR-004: agregar conocimiento es agregar un DEFRULE, no tocar
   ningun archivo de src/engine/."
  (let ((engine:*rules* nil))
    (engine:defrule brand-new-rule
      :priority 1 :when ((ping)) :then ((pong)))
    (let ((wm (engine:make-working-memory)))
      (engine:assert-fact '(ping) wm)
      (engine:run wm)
      (is-true (engine:fact-present-p '(pong) wm)))))
