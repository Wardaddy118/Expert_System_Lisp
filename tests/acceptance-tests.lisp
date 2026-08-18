;;;; tests/acceptance-tests.lisp
;;;;
;;;; Suite de aceptacion del sistema (T014).
;;;;
;;;; Los diez criterios de docs/planning/implementation_plan.md, reunidos en
;;;; un archivo. No reemplazan a las pruebas unitarias: estas responden "el
;;;; sistema cumple lo que prometio el plan", no "esta funcion hace lo suyo".
;;;; Un evaluador que quiera comprobar el proyecto sin leerlo entero empieza
;;;; aqui.

(in-package #:expert-system.tests)
(in-suite all-tests)

;;; Criterio 1 -- Ninguna recomendacion viola un requisito (BR-001)

(test acceptance-1-no-recommendation-violates-a-prerequisite
  (dolist (session (all-demo-sessions))
    (let* ((wm (domain:session-working-memory session))
           (approved (domain:profile-approved wm)))
      (dolist (r (domain:session-recommendations session))
        (dolist (fact (engine:query-facts wm 'domain::prerequisite))
          (when (equal (second fact) (domain:recommendation-course-id r))
            (is (member (third fact) approved :test #'equal)
                "~a se recomendo sin tener aprobado su requisito ~a."
                (second fact) (third fact))))))))

;;; Criterio 2 -- Ninguna recomendacion choca con el horario (BR-003)

(test acceptance-2-no-recommendation-conflicts-with-the-schedule
  (dolist (session (all-demo-sessions))
    (let* ((wm (domain:session-working-memory session))
           (available (domain:profile-available wm)))
      (dolist (r (domain:session-recommendations session))
        (dolist (fact (engine:query-facts wm 'domain::schedule))
          (when (equal (second fact) (domain:recommendation-course-id r))
            (is (member (list (third fact) (fourth fact)) available :test #'equal)
                "~a se recomendo en un bloque no disponible: ~a ~a."
                (second fact) (third fact) (fourth fact))))))))

;;; Criterio 3 -- Toda recomendacion tiene explicacion no vacia (BR-020)

(test acceptance-3-every-recommendation-has-a-non-empty-explanation
  (dolist (session (all-demo-sessions))
    (dolist (r (domain:session-recommendations session))
      (is (plusp (length (domain:recommendation-reasons r)))
          "~a se recomendo sin ninguna razon que lo justifique."
          (domain:recommendation-course-id r)))))

;;; Criterio 4 -- El motor es generico (ADR-005)

(test acceptance-4-the-engine-knows-nothing-about-the-academic-domain
  "El motor tiene que operar sobre hechos inventados, sin un solo simbolo del
   dominio academico. Si esta prueba necesitara cursos para pasar, el motor
   dejo de ser un motor."
  (let ((wm (engine:make-working-memory))
        (engine:*rules* nil))
    (engine:defrule acceptance-generic-rule
      :priority 1
      :when ((color ?x) (not (painted ?x)))
      :then ((painted ?x)))
    (engine:assert-fact (list 'color 'rojo) wm)
    (engine:assert-fact (list 'color 'azul) wm)
    (engine:run wm)
    (is (engine:fact-present-p (list 'painted 'rojo) wm))
    (is (engine:fact-present-p (list 'painted 'azul) wm))))

;;; Criterio 5 -- Se puede agregar una regla sin tocar el motor (NFR-004)

(test acceptance-5-a-new-rule-can-be-added-without-touching-the-engine
  "La prueba que demuestra que las reglas no quedaron cableadas. Si falla, se
   violo ADR-005 y el proyecto perdio su razon de ser."
  (let ((wm (engine:make-working-memory))
        (engine:*rules* nil))
    (engine:assert-fact (list 'animal 'gato) wm)
    (engine:run wm)
    (is (not (engine:fact-present-p (list 'mamifero 'gato) wm))
        "Sin la regla, la conclusion no deberia existir.")
    (engine:defrule acceptance-runtime-rule
      :priority 1
      :when ((animal ?x))
      :then ((mamifero ?x)))
    (let ((wm2 (engine:make-working-memory)))
      (engine:assert-fact (list 'animal 'gato) wm2)
      (engine:run wm2)
      (is (engine:fact-present-p (list 'mamifero 'gato) wm2)
          "Con la regla recien declarada, la conclusion tiene que aparecer."))))

;;; Criterio 6 -- El motor termina siempre (refraccion)

(test acceptance-6-the-engine-always-terminates
  "Una regla cuya conclusion vuelve a satisfacer su propia condicion debe
   alcanzar quiescencia por refraccion, no colgarse ni agotar el limite."
  (let ((wm (engine:make-working-memory))
        (engine:*rules* nil))
    (engine:defrule acceptance-self-reactivating
      :priority 1
      :when ((item ?x))
      :then ((item ?x) (seen ?x)))
    (engine:assert-fact (list 'item 'uno) wm)
    (engine:run wm :max-cycles 50)
    (is (engine:fact-present-p (list 'seen 'uno) wm))
    (is (< (length (engine:trace-entries wm)) 50)
        "Llego al limite de ciclos: la refraccion no esta cortando el bucle.")))

;;; Criterio 7 -- Misma entrada, misma salida (NFR-005)

(test acceptance-7-the-same-input-always-produces-the-same-output
  (let* ((first-run (domain:run-session "data/courses.lisp"
                                         "data/profiles/sample-profile.lisp"))
         (second-run (domain:run-session "data/courses.lisp"
                                          "data/profiles/sample-profile.lisp"))
         (ids-of (lambda (s) (mapcar #'domain:recommendation-course-id
                                     (domain:session-recommendations s))))
         (trace-of (lambda (s) (mapcar #'engine:trace-entry-rule-name
                                       (engine:trace-entries
                                        (domain:session-working-memory s))))))
    (is (equal (funcall ids-of first-run) (funcall ids-of second-run)))
    (is (equal (funcall trace-of first-run) (funcall trace-of second-run))
        "La traza cambio entre dos corridas identicas.")))

;;; Criterio 8 -- Catalogo entre 40 y 60 cursos (decision D-03)

(test acceptance-8-the-catalog-has-between-forty-and-sixty-courses
  (let* ((wm (domain:load-catalog (engine:make-working-memory) "data/courses.lisp"))
         (n (length (domain:catalog-course-ids wm))))
    (is (<= 40 n 60) "El catalogo tiene ~a cursos, fuera del rango 40-60." n)))

;;; Criterio 9 -- Ambas familias de estadisticas presentes (FR-040, FR-041)

(test acceptance-9-both-families-of-statistics-are-present
  (let* ((sessions (all-demo-sessions))
         (student (domain:statistics (first sessions)))
         (catalog (domain:catalog-statistics sessions)))
    (is (integerp (domain:stats-evaluated student)))
    (is (integerp (domain:stats-approved student)))
    (is (integerp (domain:stats-eligible student)))
    (is (numberp (domain:stats-average-difficulty student)))
    (is (plusp (length (domain:catalog-stats-most-recommended catalog))))
    (is (plusp (length (domain:catalog-stats-bottlenecks catalog))))
    (is (plusp (length (domain:catalog-stats-difficulty-by-area catalog))))
    (is (= (domain:catalog-stats-rules-total catalog)
           (domain:catalog-stats-rules-fired catalog)))))

;;; Criterio 10 -- Sesion completa en menos de 2 segundos (NFR-001)

(test acceptance-10-a-full-session-runs-in-under-two-seconds
  "El criterio 10 estaba sin medir: se decia que corre en menos de un segundo
   en desarrollo, sin ninguna prueba detras. Ahora se mide."
  (let* ((start (get-internal-real-time))
         (session (domain:run-session "data/courses.lisp"
                                       "data/profiles/sample-profile.lisp"))
         (elapsed (/ (- (get-internal-real-time) start)
                     internal-time-units-per-second)))
    (is (not (null session)))
    (is (< elapsed 2)
        "La sesion tardo ~,3f s, por encima del limite de 2 s de NFR-001."
        elapsed)))
