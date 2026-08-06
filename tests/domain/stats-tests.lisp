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
