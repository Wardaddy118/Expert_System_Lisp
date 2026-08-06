;;;; tests/engine/agenda-tests.lisp
;;;;
;;;; Pruebas de la resolucion de conflictos: prioridad, recencia y orden
;;;; de declaracion (ADR-005).

(in-package #:expert-system.tests)
(in-suite all-tests)

(test higher-priority-rule-fires-first
  (let ((engine:*rules* nil))
    (engine:defrule low-priority :priority 1 :when ((trigger)) :then ((low-fired)))
    (engine:defrule high-priority :priority 10 :when ((trigger)) :then ((high-fired)))
    (let ((wm (engine:make-working-memory)))
      (engine:assert-fact '(trigger) wm)
      (engine:run wm)
      (is (eq 'high-priority (engine:trace-entry-rule-name (first (engine:trace-entries wm))))))))

(test more-recent-fact-wins-at-equal-priority
  (let ((engine:*rules* nil))
    (engine:defrule react-to-signal
      :priority 1 :when ((signal ?x)) :then ((reacted ?x)))
    (let ((wm (engine:make-working-memory)))
      (engine:assert-fact '(signal old) wm)
      (engine:assert-fact '(signal new) wm)
      (engine:run wm)
      (let ((first-binding (engine:trace-entry-bindings (first (engine:trace-entries wm)))))
        (is (eq 'new (cdr (assoc '?x first-binding))))))))

(test same-input-produces-the-same-trace
  "Prueba de NFR-005: determinismo de la resolucion de conflictos."
  (flet ((run-once ()
           (let ((engine:*rules* nil))
             (engine:defrule warm-if-red
               :priority 10 :when ((color ?x rojo)) :then ((warm ?x)))
             (let ((wm (engine:make-working-memory)))
               (engine:assert-fact (list 'color "a" 'rojo) wm)
               (engine:assert-fact (list 'color "b" 'rojo) wm)
               (engine:run wm)
               (mapcar #'engine:trace-entry-rule-name (engine:trace-entries wm))))))
    (is (equal (run-once) (run-once)))))
