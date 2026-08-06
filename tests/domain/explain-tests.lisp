;;;; tests/domain/explain-tests.lisp
;;;;
;;;; Pruebas de BR-020: toda recomendacion se explica.

(in-package #:expert-system.tests)
(in-suite all-tests)

(test every-recommendation-has-a-nonempty-explanation
  "BR-020: ninguna recomendacion puede tener explicacion vacia -- ni en
   razones ni en advertencias."
  (let ((session (domain:run-session "data/courses.lisp" "data/profiles/sample-profile.lisp")))
    (is-true (domain:session-recommendations session))
    (dolist (r (domain:session-recommendations session))
      (is-true (or (domain:recommendation-reasons r) (domain:recommendation-warnings r))))))

(test explanation-reasons-cite-the-configured-weight
  (let ((wm (engine:make-working-memory)))
    (engine:assert-fact '(domain::course "X") wm)
    (engine:assert-fact '(domain::area "X" domain::algorithms) wm)
    (engine:assert-fact '(domain::target-area domain::algorithms) wm)
    (engine:run wm)
    (let ((reasons (domain::explanation-reasons wm "X")))
      (is-true reasons)
      (is-true (search (format nil "~a" domain::+weight-target-area+) (first reasons))))))

(test tolerance-warning-only-appears-for-the-bottleneck-exception
  (let ((wm (engine:make-working-memory)))
    (engine:assert-fact '(domain::course "X") wm)
    (engine:run wm)
    (is-false (domain::explanation-warnings wm "X"))))
