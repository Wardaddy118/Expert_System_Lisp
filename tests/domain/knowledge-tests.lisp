;;;; tests/domain/knowledge-tests.lisp
;;;;
;;;; Pruebas de las reglas academicas reales (.ace/knowledge/business-rules.md),
;;;; contra ENGINE:*RULES* tal como quedo poblado al cargar
;;;; src/domain/knowledge.lisp. Cada BR lleva su prueba de disparo y su
;;;; prueba de no-disparo, con hechos sinteticos minimos (no el catalogo
;;;; completo) para aislar exactamente la condicion bajo prueba.

(in-package #:expert-system.tests)
(in-suite all-tests)

;;; --- BR-001: requisitos aprobados ----------------------------------------

(test prerequisites-satisfied-when-all-approved
  (let ((wm (engine:make-working-memory)))
    (engine:assert-fact '(domain::course "X") wm)
    (engine:assert-fact '(domain::course "Y") wm)
    (engine:assert-fact '(domain::prerequisite "Y" "X") wm)
    (engine:assert-fact '(domain::approved "X") wm)
    (engine:run wm)
    (is-true (engine:fact-present-p '(domain::prerequisites-satisfied "Y") wm))))

(test prerequisites-unmet-blocks-eligibility
  (let ((wm (engine:make-working-memory)))
    (engine:assert-fact '(domain::course "X") wm)
    (engine:assert-fact '(domain::course "Y") wm)
    (engine:assert-fact '(domain::prerequisite "Y" "X") wm)
    (engine:run wm)
    (is-false (engine:fact-present-p '(domain::prerequisites-satisfied "Y") wm))
    (is-false (engine:fact-present-p '(domain::eligible "Y") wm))
    (is-true (engine:fact-present-p '(domain::excluded "Y" domain::missing-prerequisites) wm))))

;;; --- BR-002: curso ya aprobado --------------------------------------------

(test approved-course-is-never-eligible
  (let ((wm (engine:make-working-memory)))
    (engine:assert-fact '(domain::course "X") wm)
    (engine:assert-fact '(domain::approved "X") wm)
    (engine:run wm)
    (is-false (engine:fact-present-p '(domain::eligible "X") wm))
    (is-true (engine:fact-present-p '(domain::excluded "X" domain::already-approved) wm))))

(test unapproved-course-with-no-other-blockers-is-eligible
  (let ((wm (engine:make-working-memory)))
    (engine:assert-fact '(domain::course "X") wm)
    (engine:run wm)
    (is-true (engine:fact-present-p '(domain::eligible "X") wm))))

;;; --- BR-003: horario ------------------------------------------------------

(test schedule-fits-when-all-blocks-available
  (let ((wm (engine:make-working-memory)))
    (engine:assert-fact '(domain::course "X") wm)
    (engine:assert-fact '(domain::schedule "X" domain::monday domain::morning) wm)
    (engine:assert-fact '(domain::available domain::monday domain::morning) wm)
    (engine:run wm)
    (is-true (engine:fact-present-p '(domain::schedule-fits "X") wm))))

(test schedule-conflict-when-a-block-is-unavailable
  (let ((wm (engine:make-working-memory)))
    (engine:assert-fact '(domain::course "X") wm)
    (engine:assert-fact '(domain::schedule "X" domain::monday domain::morning) wm)
    (engine:run wm)
    (is-false (engine:fact-present-p '(domain::schedule-fits "X") wm))
    (is-true (engine:fact-present-p '(domain::excluded "X" domain::schedule-conflict) wm))))

;;; --- BR-005: tolerancia a la dificultad ------------------------------------

(test within-tolerance-when-difficulty-at-or-below
  (let ((wm (engine:make-working-memory)))
    (engine:assert-fact '(domain::course "X") wm)
    (engine:assert-fact '(domain::difficulty "X" 3) wm)
    (engine:assert-fact '(domain::difficulty-tolerance 3) wm)
    (engine:run wm)
    (is-true (engine:fact-present-p '(domain::within-tolerance "X") wm))))

(test excluded-too-difficult-when-far-above-tolerance-and-not-bottleneck
  (let ((wm (engine:make-working-memory)))
    (engine:assert-fact '(domain::course "X") wm)
    (engine:assert-fact '(domain::difficulty "X" 5) wm)
    (engine:assert-fact '(domain::difficulty-tolerance 2) wm)
    (engine:run wm)
    (is-false (engine:fact-present-p '(domain::within-tolerance "X") wm))
    (is-true (engine:fact-present-p '(domain::excluded "X" domain::too-difficult) wm))))

;;; --- BR-006 y excepcion de BR-005: cuello de botella -----------------------

(defun assert-bottleneck-of (wm id dependents)
  (dolist (dep dependents)
    (engine:assert-fact (list 'domain::course dep) wm)
    (engine:assert-fact (list 'domain::prerequisite dep id) wm)))

(test three-dependents-make-a-bottleneck
  (let ((wm (engine:make-working-memory)))
    (engine:assert-fact '(domain::course "X") wm)
    (assert-bottleneck-of wm "X" '("A" "B" "C"))
    (engine:run wm)
    (is-true (engine:fact-present-p '(domain::bottleneck "X" 3) wm))))

(test two-dependents-are-not-a-bottleneck
  (let ((wm (engine:make-working-memory)))
    (engine:assert-fact '(domain::course "X") wm)
    (assert-bottleneck-of wm "X" '("A" "B"))
    (engine:run wm)
    (is-false (engine:query-facts wm 'domain::bottleneck))))

(test bottleneck-exceeding-tolerance-by-one-level-is-recommended-with-warning
  (let ((wm (engine:make-working-memory)))
    (engine:assert-fact '(domain::course "X") wm)
    (engine:assert-fact '(domain::difficulty "X" 4) wm)
    (engine:assert-fact '(domain::difficulty-tolerance 3) wm)
    (assert-bottleneck-of wm "X" '("A" "B" "C"))
    (engine:run wm)
    (is-true (engine:fact-present-p '(domain::within-tolerance "X") wm))
    (is-true (engine:fact-present-p '(domain::tolerance-warning "X") wm))))

(test bottleneck-exceeding-tolerance-by-two-levels-is-excluded-anyway
  (let ((wm (engine:make-working-memory)))
    (engine:assert-fact '(domain::course "X") wm)
    (engine:assert-fact '(domain::difficulty "X" 5) wm)
    (engine:assert-fact '(domain::difficulty-tolerance 3) wm)
    (assert-bottleneck-of wm "X" '("A" "B" "C"))
    (engine:run wm)
    (is-false (engine:fact-present-p '(domain::within-tolerance "X") wm))
    (is-true (engine:fact-present-p '(domain::excluded "X" domain::too-difficult) wm))))

;;; --- BR-010 a BR-013: calculo de puntuacion --------------------------------

(test priority-accumulates-from-independent-rules
  (let ((wm (engine:make-working-memory)))
    (engine:assert-fact '(domain::course "X") wm)
    (engine:assert-fact '(domain::area "X" domain::algorithms) wm)
    (engine:assert-fact '(domain::interest domain::algorithms) wm)
    (engine:assert-fact '(domain::target-area domain::algorithms) wm)
    (engine:run wm)
    (is (= (+ domain::+weight-target-area+ domain::+weight-interest+)
           (domain::course-total-priority wm "X")))))

(test no-affinity-means-zero-priority
  (let ((wm (engine:make-working-memory)))
    (engine:assert-fact '(domain::course "X") wm)
    (engine:assert-fact '(domain::area "X" domain::systems) wm)
    (engine:assert-fact '(domain::target-area domain::security) wm)
    (engine:run wm)
    (is (= 0 (domain::course-total-priority wm "X")))))

;;; --- BR-007 y orden de recomendaciones --------------------------------------

(test recommendations-are-sorted-by-score-descending
  (let ((wm (engine:make-working-memory)))
    (engine:assert-fact '(domain::course "LOW") wm)
    (engine:assert-fact '(domain::area "LOW" domain::algorithms) wm)
    (engine:assert-fact '(domain::interest domain::algorithms) wm)
    (engine:assert-fact '(domain::credits "LOW" 3) wm)
    (engine:assert-fact '(domain::difficulty "LOW" 2) wm)
    (engine:assert-fact '(domain::course "HIGH") wm)
    (engine:assert-fact '(domain::area "HIGH" domain::algorithms) wm)
    (engine:assert-fact '(domain::target-area domain::algorithms) wm)
    (engine:assert-fact '(domain::credits "HIGH" 3) wm)
    (engine:assert-fact '(domain::difficulty "HIGH" 2) wm)
    (engine:assert-fact '(domain::difficulty-tolerance 3) wm)
    (engine:assert-fact '(domain::credit-limit 20) wm)
    (engine:run wm)
    (domain::apply-credit-limit wm)
    (let* ((session (domain::build-session wm))
           (ids (mapcar #'domain:recommendation-course-id (domain:session-recommendations session))))
      (is (equal '("HIGH" "LOW") ids)))))

;;; --- BR-004: tope de creditos, aplicado tras la quiescencia -----------------

(test credit-limit-excludes-lower-priority-course-when-budget-is-tight
  (let ((wm (engine:make-working-memory)))
    (engine:assert-fact '(domain::course "LOW") wm)
    (engine:assert-fact '(domain::area "LOW" domain::algorithms) wm)
    (engine:assert-fact '(domain::interest domain::algorithms) wm)
    (engine:assert-fact '(domain::credits "LOW" 4) wm)
    (engine:assert-fact '(domain::difficulty "LOW" 2) wm)
    (engine:assert-fact '(domain::course "HIGH") wm)
    (engine:assert-fact '(domain::area "HIGH" domain::algorithms) wm)
    (engine:assert-fact '(domain::target-area domain::algorithms) wm)
    (engine:assert-fact '(domain::credits "HIGH" 4) wm)
    (engine:assert-fact '(domain::difficulty "HIGH" 2) wm)
    (engine:assert-fact '(domain::difficulty-tolerance 3) wm)
    (engine:assert-fact '(domain::credit-limit 4) wm)
    (engine:run wm)
    (domain::apply-credit-limit wm)
    (is-true (engine:fact-present-p '(domain::excluded "LOW" domain::credit-limit-exceeded) wm))
    (is-false (engine:fact-present-p '(domain::excluded "HIGH" domain::credit-limit-exceeded) wm))))

;;; --- Un curso por bloque electivo -------------------------------------------

(test elective-group-limit-keeps-only-the-highest-scoring-course
  "El estudiante solo puede llevar una materia por bloque electivo: de
   dos electivas RECOMMENDED del mismo grupo, solo debe sobrevivir la de
   mayor puntaje."
  (let ((wm (engine:make-working-memory)))
    (engine:assert-fact '(domain::course "LOW-ELECTIVE") wm)
    (engine:assert-fact '(domain::area "LOW-ELECTIVE" domain::databases) wm)
    (engine:assert-fact '(domain::interest domain::databases) wm)
    (engine:assert-fact '(domain::credits "LOW-ELECTIVE" 4) wm)
    (engine:assert-fact '(domain::difficulty "LOW-ELECTIVE" 2) wm)
    (engine:assert-fact '(domain::elective "LOW-ELECTIVE" domain::sixth-term-elective) wm)
    (engine:assert-fact '(domain::course "HIGH-ELECTIVE") wm)
    (engine:assert-fact '(domain::area "HIGH-ELECTIVE" domain::databases) wm)
    (engine:assert-fact '(domain::target-area domain::databases) wm)
    (engine:assert-fact '(domain::credits "HIGH-ELECTIVE" 4) wm)
    (engine:assert-fact '(domain::difficulty "HIGH-ELECTIVE" 2) wm)
    (engine:assert-fact '(domain::elective "HIGH-ELECTIVE" domain::sixth-term-elective) wm)
    (engine:assert-fact '(domain::difficulty-tolerance 3) wm)
    (engine:run wm)
    (domain::apply-elective-group-limit wm)
    (is-true (engine:fact-present-p '(domain::excluded "LOW-ELECTIVE" domain::elective-group-limit) wm))
    (is-false (engine:fact-present-p '(domain::excluded "HIGH-ELECTIVE" domain::elective-group-limit) wm))))

(test elective-group-limit-does-not-touch-different-groups
  "Dos electivas RECOMMENDED de bloques distintos no se estorban entre
   si: el limite es por grupo, no global."
  (let ((wm (engine:make-working-memory)))
    (engine:assert-fact '(domain::course "SIXTH") wm)
    (engine:assert-fact '(domain::area "SIXTH" domain::databases) wm)
    (engine:assert-fact '(domain::target-area domain::databases) wm)
    (engine:assert-fact '(domain::credits "SIXTH" 4) wm)
    (engine:assert-fact '(domain::difficulty "SIXTH" 2) wm)
    (engine:assert-fact '(domain::elective "SIXTH" domain::sixth-term-elective) wm)
    (engine:assert-fact '(domain::course "SEVENTH") wm)
    (engine:assert-fact '(domain::area "SEVENTH" domain::databases) wm)
    (engine:assert-fact '(domain::credits "SEVENTH" 4) wm)
    (engine:assert-fact '(domain::difficulty "SEVENTH" 2) wm)
    (engine:assert-fact '(domain::interest domain::databases) wm)
    (engine:assert-fact '(domain::elective "SEVENTH" domain::seventh-term-elective) wm)
    (engine:assert-fact '(domain::difficulty-tolerance 3) wm)
    (engine:run wm)
    (domain::apply-elective-group-limit wm)
    (is-false (engine:fact-present-p '(domain::excluded "SIXTH" domain::elective-group-limit) wm))
    (is-false (engine:fact-present-p '(domain::excluded "SEVENTH" domain::elective-group-limit) wm))))

;;; --- Prevencion de ciclos infinitos con el catalogo real --------------------

(test full-demo-catalog-and-profile-terminate
  "El catalogo y perfil de demostracion completos alcanzan quiescencia muy
   por debajo del limite de seguridad de ciclos."
  (let ((wm (engine:make-working-memory)))
    (domain:load-catalog wm "data/courses.lisp")
    (domain:load-profile wm "data/profiles/sample-profile.lisp")
    (finishes (engine:run wm :max-cycles 500))))
