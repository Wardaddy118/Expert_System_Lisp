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
  (facts nil :type list)      ; hechos (struct FACT) que la activaron
  ;; Recencia: el id de insercion mas alto entre FACTS. Se calcula una sola
  ;; vez al construir la instanciacion, no dentro del comparador.
  ;;
  ;; Es un valor derivado de FACTS, que no cambia despues de crearse, asi
  ;; que memoizarlo no altera ninguna decision: solo evita recalcularlo.
  ;; El comparador se invoca O(n log n) veces por ciclo y el ciclo corre
  ;; cientos de veces, de modo que recalcularlo ahi costaba unas 206.000
  ;; llamadas por sesion y dejaba el tiempo total por encima del limite de
  ;; 2 s que fija NFR-001.
  (recency 0 :type integer)
  ;; Clave de refraccion, tambien memoizada. Se consultaba una vez por
  ;; candidato y por ciclo (unas 74.000 veces por sesion) y cada consulta
  ;; recalculaba un COPY-ALIST mas un SORT. Igual que RECENCY, depende solo
  ;; de campos que no cambian tras la construccion.
  (key nil :type list))

(defun build-conflict-set (wm)
  "Retorna la lista de todas las INSTANTIATION posibles en el estado
   actual de WM, recorriendo *RULES*."
  (let ((conflict-set nil))
    (dolist (r *rules* conflict-set)
      (dolist (bs (match-conditions (rule-when-conditions r) wm))
        (let ((facts (binding-set-facts bs)))
          (let ((bindings (binding-set-vars bs)))
            (push (make-instantiation :rule r
                                       :bindings bindings
                                       :facts facts
                                       :recency (max-fact-id facts)
                                       :key (compute-instantiation-key r bindings))
                  conflict-set)))))))

(defun compute-instantiation-key (rule bindings)
  "Identifica una instanciacion por su regla y sus ligaduras, para la
   refraccion: 'una misma instanciacion no dispara dos veces' (ADR-005).
   Las ligaduras se ordenan por nombre de variable para que la misma
   combinacion produzca siempre la misma clave sin importar el orden en
   que se encontraron.

   Se llama una sola vez, al construir la instanciacion; el resultado vive
   en su campo KEY."
  (list (rule-name rule)
        (sort (copy-alist bindings)
              #'string< :key (lambda (pair) (symbol-name (car pair))))))

(defun make-fired-set ()
  "Crea el registro de instanciaciones ya disparadas, usado para la
   refraccion durante una corrida del motor."
  (make-hash-table :test 'equal))

(defun fired-p (fired-set inst)
  (gethash (instantiation-key inst) fired-set))

(defun mark-fired (fired-set inst)
  (setf (gethash (instantiation-key inst) fired-set) t))

(defun preferred-instantiation (candidates)
  "Retorna la instanciacion que gana la resolucion de conflictos entre
   CANDIDATES, con un barrido lineal.

   Antes se ordenaba la lista entera para quedarse con el primer elemento.
   Ordenar es O(n log n) y aqui solo hace falta el maximo, que es O(n); el
   criterio de comparacion es el mismo, asi que la instanciacion elegida no
   cambia."
  (let ((best (first candidates)))
    (dolist (inst (rest candidates) best)
      (when (instantiation-preferred-p inst best)
        (setf best inst)))))

(defun select-instantiation (conflict-set fired-set)
  "Elige, entre las instanciaciones de CONFLICT-SET que no se han disparado
   ya, la que gana la resolucion de conflictos: mayor prioridad de regla;
   en empate, el hecho activador mas reciente; en empate, la regla
   declarada primero. Retorna NIL si no queda ninguna por disparar."
  (let ((candidates (remove-if (lambda (inst) (fired-p fired-set inst)) conflict-set)))
    (when candidates
      (preferred-instantiation candidates))))

(defun instantiation-preferred-p (a b)
  "T si A debe dispararse antes que B segun el orden de resolucion de
   conflictos de ADR-005."
  (let ((priority-a (rule-priority (instantiation-rule a)))
        (priority-b (rule-priority (instantiation-rule b))))
    (cond
      ((/= priority-a priority-b) (> priority-a priority-b))
      (t (let ((recency-a (instantiation-recency a))
               (recency-b (instantiation-recency b)))
           (cond
             ((/= recency-a recency-b) (> recency-a recency-b))
             (t (< (rule-declaration-order (instantiation-rule a))
                   (rule-declaration-order (instantiation-rule b))))))))))
