;;;; tests/engine/matching-tests.lisp
;;;;
;;;; Pruebas del pattern matching: patrones positivos, negacion y pruebas
;;;; estructurales (distinct, precedes, at-most, at-least,
;;;; exceeds-by-one). Todo con hechos inventados.

(in-package #:expert-system.tests)
(in-suite all-tests)

(test rule-fires-when-pattern-matches
  (let ((engine:*rules* nil))
    (engine:defrule warm-if-red
      "Prueba de humo del matching."
      :priority 10
      :when ((color ?x rojo))
      :then ((warm ?x)))
    (let ((wm (engine:make-working-memory)))
      (engine:assert-fact (list 'color "fuego" 'rojo) wm)
      (engine:run wm)
      (is-true (engine:fact-present-p (list 'warm "fuego") wm)))))

(test rule-does-not-fire-when-pattern-does-not-match
  (let ((engine:*rules* nil))
    (engine:defrule warm-if-red
      :priority 10
      :when ((color ?x rojo))
      :then ((warm ?x)))
    (let ((wm (engine:make-working-memory)))
      (engine:assert-fact (list 'color "hielo" 'azul) wm)
      (engine:run wm)
      (is-false (engine:fact-present-p (list 'warm "hielo") wm)))))

(test negation-blocks-firing-when-fact-present
  (let ((engine:*rules* nil))
    (engine:defrule lonely-if-no-friend
      :priority 10
      :when ((person ?x) (not (friend-of ?x)))
      :then ((lonely ?x)))
    (let ((wm (engine:make-working-memory)))
      (engine:assert-fact (list 'person "ana") wm)
      (engine:assert-fact (list 'friend-of "ana") wm)
      (engine:run wm)
      (is-false (engine:fact-present-p (list 'lonely "ana") wm)))))

(test negation-allows-firing-when-fact-absent
  (let ((engine:*rules* nil))
    (engine:defrule lonely-if-no-friend
      :priority 10
      :when ((person ?x) (not (friend-of ?x)))
      :then ((lonely ?x)))
    (let ((wm (engine:make-working-memory)))
      (engine:assert-fact (list 'person "beto") wm)
      (engine:run wm)
      (is-true (engine:fact-present-p (list 'lonely "beto") wm)))))

(test distinct-structural-test
  (let ((engine:*rules* nil))
    (engine:defrule different-pair
      :priority 10
      :when ((item ?a) (item ?b) (engine:distinct ?a ?b))
      :then ((paired ?a ?b)))
    (let ((wm (engine:make-working-memory)))
      (engine:assert-fact '(item x) wm)
      (engine:run wm)
      (is-false (engine:query-facts wm 'paired)))))

(test precedes-structural-test-selects-one-order
  "PRECEDES evita que un trio dispare una vez por cada permutacion."
  (let ((engine:*rules* nil))
    (engine:defrule three-in-order
      :priority 10
      :when ((item ?a) (item ?b) (item ?c)
             (engine:precedes ?a ?b) (engine:precedes ?b ?c))
      :then ((ordered-triple ?a ?b ?c)))
    (let ((wm (engine:make-working-memory)))
      (dolist (x '("a" "b" "c")) (engine:assert-fact (list 'item x) wm))
      (engine:run wm)
      (is (= 1 (length (engine:query-facts wm 'ordered-triple)))))))

(test at-most-structural-test
  (let ((engine:*rules* nil))
    (engine:defrule fits-budget
      :priority 10
      :when ((cost ?c) (budget ?b) (engine:at-most ?c ?b))
      :then ((affordable ?c)))
    (let ((wm (engine:make-working-memory)))
      (engine:assert-fact '(cost 5) wm)
      (engine:assert-fact '(budget 5) wm)
      (engine:run wm)
      (is-true (engine:fact-present-p '(affordable 5) wm)))))

(test exceeds-by-one-structural-test
  (let ((engine:*rules* nil))
    (engine:defrule just-over
      :priority 10
      :when ((value ?v) (limit ?l) (engine:exceeds-by-one ?v ?l))
      :then ((barely-over ?v)))
    (let ((wm (engine:make-working-memory)))
      (engine:assert-fact '(value 4) wm)
      (engine:assert-fact '(limit 3) wm)
      (engine:run wm)
      (is-true (engine:fact-present-p '(barely-over 4) wm)))))
