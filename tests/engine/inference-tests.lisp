;;;; tests/engine/inference-tests.lisp
;;;;
;;;; Pruebas del ciclo de inferencia: quiescencia, refraccion contra
;;;; bucles infinitos y el limite maximo de ciclos.

(in-package #:expert-system.tests)
(in-suite all-tests)

(test run-stops-at-quiescence
  (let ((engine:*rules* nil))
    (engine:defrule once-only :priority 1 :when ((seed)) :then ((sprout)))
    (let ((wm (engine:make-working-memory)))
      (engine:assert-fact '(seed) wm)
      (engine:run wm)
      (is (= 1 (length (engine:trace-entries wm)))))))

(test refraction-prevents-infinite-loop
  "Una regla cuya conclusion reactiva su propia condicion debe alcanzar
   quiescencia por si sola, sin necesitar el limite de ciclos."
  (let ((engine:*rules* nil))
    (engine:defrule self-reactivating
      :priority 5
      :when ((counter ?n) (not (bumped ?n)))
      :then ((bumped ?n) (counter next)))
    (let ((wm (engine:make-working-memory)))
      (engine:assert-fact (list 'counter 1) wm)
      (engine:run wm :max-cycles 20)
      (is (< (length (engine:trace-entries wm)) 20)))))

(test max-cycles-signals-a-warning-when-not-reaching-quiescence
  (let ((engine:*rules* nil))
    (engine:defrule loop-forever
      :priority 1
      :when ((tick ?n) (not (done ?n)))
      :then ((done ?n) (tick next)))
    (let ((wm (engine:make-working-memory)))
      (engine:assert-fact (list 'tick 1) wm)
      (signals engine:max-cycles-exceeded (engine:run wm :max-cycles 1)))))

(test trace-entries-are-in-chronological-order
  (let ((engine:*rules* nil))
    (engine:defrule step-one :priority 10 :when ((start)) :then ((step-one-done)))
    (engine:defrule step-two :priority 5 :when ((step-one-done)) :then ((step-two-done)))
    (let ((wm (engine:make-working-memory)))
      (engine:assert-fact '(start) wm)
      (engine:run wm)
      (is (equal '(step-one step-two)
                  (mapcar #'engine:trace-entry-rule-name (engine:trace-entries wm)))))))
