;;;; src/engine/agenda.lisp
;;;;
;;;; El conjunto de conflicto (todas las instanciaciones aplicables en un
;;;; ciclo), su resolucion deterministica y la refraccion (ADR-005).

(in-package #:expert-system.engine)

;;; Una instanciacion es una regla concreta junto con un conjunto de
;;; ligaduras que satisface todas sus condiciones. Es lo que se dispara,
;;; no la regla en abstracto.
(defstruct instantiation
  (rule nil :type (or null rule))
  (bindings nil :type list)   ; alist ?var -> valor
  (facts nil :type list))     ; hechos (struct FACT) que la activaron

(defun build-conflict-set (wm)
  "Retorna la lista de todas las INSTANTIATION posibles en el estado
   actual de WM, recorriendo *RULES*."
  (let ((conflict-set nil))
    (dolist (r *rules* conflict-set)
      (dolist (bs (match-conditions (rule-when-conditions r) wm))
        (push (make-instantiation :rule r
                                   :bindings (binding-set-vars bs)
                                   :facts (binding-set-facts bs))
              conflict-set)))))

(defun instantiation-key (inst)
  "Identifica una instanciacion por su regla y sus ligaduras, para la
   refraccion: 'una misma instanciacion no dispara dos veces' (ADR-005).
   Las ligaduras se ordenan por nombre de variable para que la misma
   combinacion produzca siempre la misma clave sin importar el orden en
   que se encontraron."
  (list (rule-name (instantiation-rule inst))
        (sort (copy-alist (instantiation-bindings inst))
              #'string< :key (lambda (pair) (symbol-name (car pair))))))

(defun make-fired-set ()
  "Crea el registro de instanciaciones ya disparadas, usado para la
   refraccion durante una corrida del motor."
  (make-hash-table :test 'equal))

(defun fired-p (fired-set inst)
  (gethash (instantiation-key inst) fired-set))

(defun mark-fired (fired-set inst)
  (setf (gethash (instantiation-key inst) fired-set) t))

(defun select-instantiation (conflict-set fired-set)
  "Elige, entre las instanciaciones de CONFLICT-SET que no se han disparado
   ya, la que gana la resolucion de conflictos: mayor prioridad de regla;
   en empate, el hecho activador mas reciente; en empate, la regla
   declarada primero. Retorna NIL si no queda ninguna por disparar."
  (let ((candidates (remove-if (lambda (inst) (fired-p fired-set inst)) conflict-set)))
    (when candidates
      (first (sort candidates #'instantiation-preferred-p)))))

(defun instantiation-preferred-p (a b)
  "T si A debe dispararse antes que B segun el orden de resolucion de
   conflictos de ADR-005."
  (let ((priority-a (rule-priority (instantiation-rule a)))
        (priority-b (rule-priority (instantiation-rule b))))
    (cond
      ((/= priority-a priority-b) (> priority-a priority-b))
      (t (let ((recency-a (max-fact-id (instantiation-facts a)))
               (recency-b (max-fact-id (instantiation-facts b))))
           (cond
             ((/= recency-a recency-b) (> recency-a recency-b))
             (t (< (rule-declaration-order (instantiation-rule a))
                   (rule-declaration-order (instantiation-rule b))))))))))
