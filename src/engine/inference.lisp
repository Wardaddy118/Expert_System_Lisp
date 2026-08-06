;;;; src/engine/inference.lisp
;;;;
;;;; El ciclo de inferencia: match -> select -> act, hasta quiescencia o
;;;; hasta un limite maximo de ciclos (ADR-005). Cada disparo queda
;;;; registrado en la traza de WM, que es el insumo de la explicacion.

(in-package #:expert-system.engine)

(defstruct trace-entry
  (cycle 0 :type integer)
  (rule-name nil :type symbol)
  (bindings nil :type list)
  (matched-facts nil :type list)    ; contenido de los hechos que activaron la regla
  (asserted-facts nil :type list))  ; contenido de los hechos nuevos que produjo

(define-condition max-cycles-exceeded (warning)
  ((cycles :initarg :cycles :reader max-cycles-exceeded-cycles))
  (:report (lambda (c s)
             (format s "El motor alcanzo el limite de ~a ciclos sin llegar a quiescencia."
                     (max-cycles-exceeded-cycles c))))
  (:documentation "Señal de que RUN se detuvo por el limite de ciclos, no
   porque el conjunto de conflicto quedara vacio. Es la red de seguridad
   contra reglas mal escritas que reactivan su propia condicion sin fin."))

(defun run (wm &key (max-cycles 1000))
  "Corre el ciclo match-select-act sobre WM hasta quiescencia (ningun
   instanciacion nueva por disparar) o hasta MAX-CYCLES. Devuelve WM, con
   sus hechos derivados y su traza actualizados. Señala una advertencia
   MAX-CYCLES-EXCEEDED si se alcanza el limite sin llegar a quiescencia."
  (let ((fired-set (make-fired-set))
        (cycle 0))
    (loop
      (when (>= cycle max-cycles)
        (warn 'max-cycles-exceeded :cycles max-cycles)
        (return))
      (let* ((conflict-set (build-conflict-set wm))
             (selected (select-instantiation conflict-set fired-set)))
        (unless selected
          (return))
        (incf cycle)
        (mark-fired fired-set selected)
        (fire-instantiation selected wm cycle)))
    wm))

(defun fire-instantiation (inst wm cycle)
  "Ejecuta las acciones :then de INST: sustituye las ligaduras en cada
   plantilla, afirma los hechos resultantes en WM y registra la traza del
   disparo en el ciclo CYCLE."
  (let* ((rule (instantiation-rule inst))
         (bindings (instantiation-bindings inst))
         (new-facts (loop for template in (rule-then-templates rule)
                           for asserted = (assert-fact
                                           (instantiate-template template bindings) wm)
                           when asserted collect (fact-content asserted))))
    (push (make-trace-entry :cycle cycle
                             :rule-name (rule-name rule)
                             :bindings bindings
                             :matched-facts (mapcar #'fact-content (instantiation-facts inst))
                             :asserted-facts new-facts)
          (working-memory-trace wm))))

(defun trace-entries (wm)
  "Retorna la traza de WM en orden cronologico (el primer disparo primero)."
  (reverse (working-memory-trace wm)))
