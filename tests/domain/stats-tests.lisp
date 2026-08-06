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
