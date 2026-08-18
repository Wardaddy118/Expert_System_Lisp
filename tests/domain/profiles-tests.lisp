;;;; tests/domain/profiles-tests.lisp
;;;;
;;;; Pruebas de los perfiles de demostracion (T013).
;;;;
;;;; La mas importante de este archivo es la ultima: el criterio de cierre de
;;;; la decision D-09. Con los cinco perfiles, las 25 reglas del dominio
;;;; tienen que disparar al menos una vez. Si alguna no dispara, es
;;;; conocimiento muerto y hay que eliminarla, no dejarla inflando el conteo.

(in-package #:expert-system.tests)
(in-suite all-tests)

(defparameter *demo-profiles*
  '("data/profiles/sample-profile.lisp"
    "data/profiles/first-year.lisp"
    "data/profiles/advanced.lisp"
    "data/profiles/tight-schedule.lisp"
    "data/profiles/low-tolerance.lisp")
  "Los perfiles que la demostracion puede cargar (FR-051).")

(defun session-for (profile-path)
  (domain:run-session "data/courses.lisp" profile-path))

(defun all-demo-sessions ()
  (mapcar #'session-for *demo-profiles*))

(test every-demo-profile-loads-and-produces-a-session
  (dolist (path *demo-profiles*)
    (let ((session (session-for path)))
      (is (not (null (domain:session-working-memory session)))))))

(test the-first-year-profile-has-no-approved-courses
  "Caso borde del PRD: estudiante sin aprobados."
  (let* ((session (session-for "data/profiles/first-year.lisp"))
         (wm (domain:session-working-memory session)))
    (is (null (domain:profile-approved wm)))
    (is (plusp (length (domain:session-recommendations session))))))

(test the-first-year-profile-is-only-offered-courses-without-prerequisites
  "Sin nada aprobado, todo curso recomendado tiene que carecer de requisitos."
  (let* ((session (session-for "data/profiles/first-year.lisp"))
         (wm (domain:session-working-memory session)))
    (dolist (r (domain:session-recommendations session))
      (is (null (remove-if-not
                 (lambda (f) (equal (second f) (domain:recommendation-course-id r)))
                 (engine:query-facts wm 'domain::prerequisite)))))))

(test the-advanced-profile-has-a-high-share-of-approved-courses
  (let* ((session (session-for "data/profiles/advanced.lisp"))
         (wm (domain:session-working-memory session))
         (stats (domain:statistics session)))
    (is (> (length (domain:profile-approved wm)) 10))
    (is (> (domain:stats-approved stats) 10))))

(test the-tight-schedule-profile-discards-mostly-by-schedule
  "Con solo dos bloques libres, el horario tiene que ser el filtro dominante."
  (let* ((session (session-for "data/profiles/tight-schedule.lisp"))
         (stats (domain:statistics session)))
    (is (> (domain:stats-schedule-incompatible stats)
           (domain:stats-blocked-by-prerequisites stats)))))

(test the-low-tolerance-profile-fires-the-bottleneck-exception
  "Decision D-08: un cuello de botella que excede la tolerancia por un solo
   nivel se recomienda igual, con advertencia. SC-304 tiene dificultad 4 y el
   perfil declara tolerancia 3."
  (let* ((session (session-for "data/profiles/low-tolerance.lisp"))
         (sc304 (find "SC-304" (domain:session-recommendations session)
                      :key #'domain:recommendation-course-id :test #'equal)))
    (is (not (null sc304))
        "SC-304 deberia recomendarse pese a exceder la tolerancia.")
    (is (not (null (domain:recommendation-warnings sc304)))
        "La recomendacion tiene que venir marcada con advertencia.")))

(test no-recommendation-in-any-profile-violates-a-prerequisite
  "Invariante duro BR-001, sobre los cinco perfiles a la vez."
  (dolist (session (all-demo-sessions))
    (let* ((wm (domain:session-working-memory session))
           (approved (domain:profile-approved wm)))
      (dolist (r (domain:session-recommendations session))
        (dolist (fact (engine:query-facts wm 'domain::prerequisite))
          (when (equal (second fact) (domain:recommendation-course-id r))
            (is (member (third fact) approved :test #'equal))))))))

(test no-recommendation-in-any-profile-violates-the-schedule
  "Invariante duro BR-003, sobre los cinco perfiles a la vez."
  (dolist (session (all-demo-sessions))
    (let* ((wm (domain:session-working-memory session))
           (available (domain:profile-available wm)))
      (dolist (r (domain:session-recommendations session))
        (dolist (fact (engine:query-facts wm 'domain::schedule))
          (when (equal (second fact) (domain:recommendation-course-id r))
            (is (member (list (third fact) (fourth fact)) available :test #'equal))))))))

(test the-demo-profiles-together-fire-every-rule
  "CRITERIO DE CIERRE DE LA DECISION D-09.

   Si esta prueba falla, la regla que no disparo NO se arregla aflojando la
   prueba: o se le construye un perfil que la ejercite, o se elimina de
   knowledge.lisp y su BR se marca como retirada en business-rules.md."
  (let ((stats (domain:catalog-statistics (all-demo-sessions))))
    (is (null (domain:catalog-stats-rules-never-fired stats))
        "Estas reglas no disparan con ningun perfil: ~{~a~^, ~}"
        (domain:catalog-stats-rules-never-fired stats))
    (is (= (domain:catalog-stats-rules-total stats)
           (domain:catalog-stats-rules-fired stats)))))

(test most-recommended-becomes-meaningful-with-several-profiles
  "Con cinco perfiles, la metrica ya compara: algun curso deberia salir
   recomendado en mas de un perfil."
  (let* ((stats (domain:catalog-statistics (all-demo-sessions)))
         (rows (domain:catalog-stats-most-recommended stats)))
    (is (= 5 (domain:catalog-stats-profiles-analyzed stats)))
    (is (plusp (length rows)))
    (is (some (lambda (row) (> (third row) 1)) rows))))
