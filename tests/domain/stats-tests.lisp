;;;; tests/domain/stats-tests.lisp
;;;;
;;;; Pruebas de BR-030: las estadisticas se derivan de la memoria de
;;;; trabajo final, y son consistentes entre si.

(in-package #:expert-system.tests)
(in-suite all-tests)

(test statistics-evaluated-matches-catalog-size
  (let* ((session (domain:run-session "data/courses.lisp" "data/profiles/sample-profile.lisp"))
         (stats (domain:statistics session)))
    (is (= (length (engine:query-facts (domain:session-working-memory session) 'domain::course))
           (domain:stats-evaluated stats)))))

(test approved-plus-eligible-never-exceeds-evaluated
  (let* ((session (domain:run-session "data/courses.lisp" "data/profiles/sample-profile.lisp"))
         (stats (domain:statistics session)))
    (is (<= (+ (domain:stats-approved stats) (domain:stats-eligible stats))
            (domain:stats-evaluated stats)))))

(test recommended-credits-matches-the-sum-of-recommendations
  (let* ((session (domain:run-session "data/courses.lisp" "data/profiles/sample-profile.lisp"))
         (stats (domain:statistics session)))
    (is (= (reduce #'+ (mapcar #'domain:recommendation-credits (domain:session-recommendations session))
                    :initial-value 0)
           (domain:stats-recommended-credits stats)))))

(test average-difficulty-is-zero-for-an-empty-catalog
  (let ((wm (engine:make-working-memory)))
    (is (= 0 (domain::average-difficulty wm nil)))))

;;; --- Estadisticas del catalogo (T011, FR-041) -------------------------------

(test catalog-statistics-accepts-one-session-or-a-list
  "Una sesion suelta y una lista de una sesion deben dar el mismo resultado."
  (let* ((session (domain:run-session "data/courses.lisp" "data/profiles/sample-profile.lisp"))
         (single (domain:catalog-statistics session))
         (listed (domain:catalog-statistics (list session))))
    (is (= 1 (domain:catalog-stats-profiles-analyzed single)))
    (is (= (domain:catalog-stats-profiles-analyzed single)
           (domain:catalog-stats-profiles-analyzed listed)))
    (is (equal (domain:catalog-stats-bottlenecks single)
               (domain:catalog-stats-bottlenecks listed)))))

(test bottleneck-count-matches-the-prerequisite-facts
  "El n de cada cuello de botella debe ser exactamente la cantidad de cursos
   distintos que lo declaran como requisito."
  (let* ((session (domain:run-session "data/courses.lisp" "data/profiles/sample-profile.lisp"))
         (wm (domain:session-working-memory session))
         (stats (domain:catalog-statistics session)))
    (dolist (row (domain:catalog-stats-bottlenecks stats))
      (destructuring-bind (required name n) row
        (declare (ignore name))
        (is (= n (length (remove-duplicates
                          (mapcar #'second
                                  (remove-if-not (lambda (f) (equal (third f) required))
                                                 (engine:query-facts wm 'domain::prerequisite)))
                          :test #'equal))))))))

(test bottlenecks-are-sorted-descending-and-deterministic
  (let* ((session (domain:run-session "data/courses.lisp" "data/profiles/sample-profile.lisp"))
         (rows (domain:catalog-stats-bottlenecks (domain:catalog-statistics session))))
    (is (equal rows (sort (copy-list rows)
                          (lambda (a b) (if (= (third a) (third b))
                                            (string< (first a) (first b))
                                            (> (third a) (third b)))))))))

(test difficulty-by-area-covers-every-area-in-the-catalog
  (let* ((session (domain:run-session "data/courses.lisp" "data/profiles/sample-profile.lisp"))
         (wm (domain:session-working-memory session))
         (rows (domain:catalog-stats-difficulty-by-area (domain:catalog-statistics session)))
         (areas-in-catalog (remove-duplicates
                            (mapcar #'third (engine:query-facts wm 'domain::area)))))
    (is (= (length areas-in-catalog) (length rows)))
    (dolist (row rows)
      (is (member (first row) areas-in-catalog)))))

(test difficulty-by-area-average-is-within-the-scale
  "Toda dificultad esta en 1-5, asi que ningun promedio puede salirse de ahi."
  (let* ((session (domain:run-session "data/courses.lisp" "data/profiles/sample-profile.lisp"))
         (rows (domain:catalog-stats-difficulty-by-area (domain:catalog-statistics session))))
    (dolist (row rows)
      (is (<= 1 (second row) 5))
      (is (plusp (third row))))))

(test rule-coverage-splits-the-registered-rules-in-two
  "Disparadas + nunca disparadas debe dar exactamente el total registrado:
   ninguna regla puede quedar fuera de la cuenta ni contarse dos veces."
  (let* ((session (domain:run-session "data/courses.lisp" "data/profiles/sample-profile.lisp"))
         (stats (domain:catalog-statistics session)))
    (is (= (domain:catalog-stats-rules-total stats)
           (+ (domain:catalog-stats-rules-fired stats)
              (length (domain:catalog-stats-rules-never-fired stats)))))))

(test rules-reported-as-never-fired-are-absent-from-the-trace
  (let* ((session (domain:run-session "data/courses.lisp" "data/profiles/sample-profile.lisp"))
         (fired (mapcar #'engine:trace-entry-rule-name
                        (engine:trace-entries (domain:session-working-memory session))))
         (never (domain:catalog-stats-rules-never-fired (domain:catalog-statistics session))))
    (dolist (name never)
      (is (not (member name fired))))))

(test most-recommended-counts-one-hit-per-profile
  "Con un solo perfil, ningun curso puede aparecer recomendado dos veces."
  (let* ((session (domain:run-session "data/courses.lisp" "data/profiles/sample-profile.lisp"))
         (rows (domain:catalog-stats-most-recommended (domain:catalog-statistics session))))
    (is (= (length rows) (length (domain:session-recommendations session))))
    (dolist (row rows)
      (is (= 1 (third row))))))

;;; --- Avance de carrera y distribucion por area (FR-040, BR-031) -------------

(test approved-credits-never-exceed-the-catalog-total
  (let* ((session (domain:run-session "data/courses.lisp" "data/profiles/advanced.lisp"))
         (stats (domain:statistics session)))
    (is (<= (domain:stats-approved-credits stats) (domain:stats-total-credits stats)))
    (is (plusp (domain:stats-total-credits stats)))))

(test career-progress-is-approved-credits-over-total-credits
  "BR-031 al pie de la letra."
  (let* ((session (domain:run-session "data/courses.lisp" "data/profiles/advanced.lisp"))
         (stats (domain:statistics session)))
    (is (= (domain:stats-career-progress stats)
           (/ (domain:stats-approved-credits stats)
              (domain:stats-total-credits stats))))))

(test career-progress-stays-between-zero-and-one
  (dolist (path *demo-profiles*)
    (let ((stats (domain:statistics (domain:run-session "data/courses.lisp" path))))
      (is (<= 0 (domain:stats-career-progress stats) 1)))))

(test a-first-year-student-has-zero-career-progress
  (let ((stats (domain:statistics
                (domain:run-session "data/courses.lisp" "data/profiles/first-year.lisp"))))
    (is (zerop (domain:stats-career-progress stats)))
    (is (zerop (domain:stats-approved-credits stats)))
    (is (null (domain:stats-approved-by-area stats)))))

(test an-advanced-student-has-more-progress-than-a-first-year-one
  (let ((advanced (domain:statistics
                   (domain:run-session "data/courses.lisp" "data/profiles/advanced.lisp")))
        (first-year (domain:statistics
                     (domain:run-session "data/courses.lisp" "data/profiles/first-year.lisp"))))
    (is (> (domain:stats-career-progress advanced)
           (domain:stats-career-progress first-year)))))

(test the-area-distribution-accounts-for-every-approved-course-with-an-area
  (let* ((session (domain:run-session "data/courses.lisp" "data/profiles/advanced.lisp"))
         (stats (domain:statistics session))
         (counted (reduce #'+ (mapcar #'second (domain:stats-approved-by-area stats))
                          :initial-value 0)))
    (is (= counted (domain:stats-approved stats)))))

(test career-progress-is-zero-for-an-empty-catalog-instead-of-dividing-by-zero
  (let ((wm (engine:make-working-memory)))
    (is (zerop (domain::career-progress wm)))))
