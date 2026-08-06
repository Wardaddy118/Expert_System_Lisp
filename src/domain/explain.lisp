;;;; src/domain/explain.lisp
;;;;
;;;; Reconstruccion de explicaciones desde la traza del motor (BR-020).
;;;; La traza no se genera para "verse bonita": es el registro real de
;;;; que reglas dispararon y con que hechos (docs/context/system_patterns.md).
;;;; Este archivo solo la traduce a espanol legible; no decide nada.

(in-package #:expert-system.domain)

(defparameter *reason-templates*
  (list (cons 'priority-target-area
              "Coincide con tu area profesional objetivo (+~a puntos).")
        (cons 'priority-interest
              "Coincide con uno de tus intereses declarados (+~a puntos).")
        (cons 'priority-bottleneck
              "Es un curso cuello de botella: atrasarlo bloquea otros cursos (+~a puntos).")
        (cons 'priority-unlocks-target-area
              "Abre camino a un curso de tu area profesional objetivo (+~a puntos).")
        (cons 'priority-too-easy
              "Esta bastante por debajo de tu tolerancia a la dificultad (~a puntos).")
        (cons 'priority-general-education
              "Aporta a tu formacion general (+~a puntos)."))
  "Un texto por cada regla PRIORITY-* de knowledge.lisp, con el hueco para
   el peso configurable que aporto. Cambiar el texto aqui no cambia el
   razonamiento del motor, solo como se explica.")

(defun explanation-reasons (wm course-id)
  "Retorna la lista de razones legibles por las que COURSE-ID acumulo
   puntaje, reconstruidas recorriendo la traza de WM (BR-020): cada
   disparo de una regla PRIORITY-* que afirmo (priority COURSE-ID n) se
   traduce con *REASON-TEMPLATES*."
  (loop for entry in (engine:trace-entries wm)
        for template = (cdr (assoc (engine:trace-entry-rule-name entry) *reason-templates*))
        for amount = (priority-amount-asserted entry course-id)
        when (and template amount)
          collect (format nil template amount)))

(defun priority-amount-asserted (entry course-id)
  "Si la traza ENTRY afirmo (priority COURSE-ID n), retorna N; si no, NIL."
  (let ((fact (find-if (lambda (f) (and (eq (first f) 'priority) (equal (second f) course-id)))
                        (engine:trace-entry-asserted-facts entry))))
    (and fact (third fact))))

(defun explanation-warnings (wm course-id)
  "Advertencias sobre COURSE-ID que no impiden recomendarlo pero el
   estudiante debe conocer: por ahora, la excepcion de BR-005 (cuello de
   botella que excede la tolerancia por un nivel)."
  (when (engine:fact-present-p (list 'tolerance-warning course-id) wm)
    (list "Supera tu tolerancia a la dificultad por un nivel, pero es un curso cuello de botella: atrasarlo cuesta mas que llevarlo ahora.")))
