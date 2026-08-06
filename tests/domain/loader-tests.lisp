;;;; tests/domain/loader-tests.lisp
;;;;
;;;; Pruebas de carga y validacion del catalogo y del perfil.

(in-package #:expert-system.tests)
(in-suite all-tests)

(test duplicate-course-id-signals-data-error
  (signals domain:data-error
    (domain::validate-no-duplicate-ids '(("A" :name "x") ("A" :name "y")) "test")))

(test unique-ids-pass-validation
  (finishes (domain::validate-no-duplicate-ids '(("A") ("B")) "test")))

(test dangling-prerequisite-signals-data-error
  (signals domain:data-error
    (domain::validate-prerequisites-exist '(("A" :prerequisites ("B"))) "test")))

(test existing-prerequisite-passes-validation
  (finishes (domain::validate-prerequisites-exist
             '(("A" :prerequisites ("B")) ("B" :prerequisites ())) "test")))

(test circular-prerequisites-signals-condition
  (signals domain:circular-prerequisites
    (domain::validate-acyclic '(("A" :prerequisites ("B")) ("B" :prerequisites ("A"))) "test")))

(test acyclic-catalog-passes-validation
  (finishes (domain::validate-acyclic '(("A" :prerequisites ()) ("B" :prerequisites ("A"))) "test")))

(test load-catalog-loads-the-official-catalog
  "El catalogo de Bachillerato en Ingenieria en Sistemas de Computacion
   (Fidelitas) trae exactamente 47 cursos."
  (let ((wm (engine:make-working-memory)))
    (domain:load-catalog wm "data/courses.lisp")
    (is (= 47 (length (engine:query-facts wm 'domain::course))))))

(test load-profile-asserts-all-profile-relations
  (let ((wm (engine:make-working-memory)))
    (domain:load-catalog wm "data/courses.lisp")
    (domain:load-profile wm "data/profiles/sample-profile.lisp")
    (is-true (domain:profile-approved wm))
    (is-true (domain:profile-interests wm))
    (is-true (domain:profile-target-area wm))
    (is-true (domain:profile-available wm))
    (is-true (domain:profile-difficulty-tolerance wm))
    (is-true (domain:profile-credit-limit wm))))

;;; --- Cuatrimestre y bloques electivos (catalogo real de 47 cursos) -------

(test every-official-course-has-a-term
  (let ((wm (engine:make-working-memory)))
    (domain:load-catalog wm "data/courses.lisp")
    (dolist (course (engine:query-facts wm 'domain::course))
      (is-true (engine:query-facts wm 'domain::term)
               "El catalogo debe tener hechos TERM")
      (is-true (find (second course) (engine:query-facts wm 'domain::term)
                      :key #'second :test #'equal)))))

(test course-count-splits-into-regular-and-elective
  "35 cursos regulares + 12 opciones electivas (4 por bloque x 3 bloques)
   = 47. Ver la nota de conteo en la cabecera de data/courses.lisp: el
   total resumido del programa (38 + 9) no cuadra con los items
   realmente listados (35 + 12); este catalogo usa el conteo real."
  (let ((wm (engine:make-working-memory)))
    (domain:load-catalog wm "data/courses.lisp")
    (let* ((all-ids (mapcar #'second (engine:query-facts wm 'domain::course)))
            (elective-ids (remove-duplicates
                            (mapcar #'second (engine:query-facts wm 'domain::elective))
                            :test #'equal)))
      (is (= 12 (length elective-ids)))
      (is (= 35 (- (length all-ids) (length elective-ids)))))))

(test each-elective-group-has-four-options
  (let ((wm (engine:make-working-memory)))
    (domain:load-catalog wm "data/courses.lisp")
    (dolist (group domain::+valid-elective-groups+)
      (is (= 4 (count-if (lambda (f) (eq (third f) group))
                          (engine:query-facts wm 'domain::elective)))))))

(test elective-without-group-signals-data-error
  (signals domain:data-error
    (domain::validate-elective-consistency '(("A" :elective t)) "test")))

(test non-elective-with-group-signals-data-error
  (signals domain:data-error
    (domain::validate-elective-consistency
     '(("A" :elective nil :elective-group sixth-term-elective)) "test")))

(test elective-with-invalid-group-signals-data-error
  (signals domain:data-error
    (domain::validate-elective-consistency
     '(("A" :elective t :elective-group not-a-real-group)) "test")))

(test consistent-electives-pass-validation
  (finishes (domain::validate-elective-consistency
             `(("A" :elective t :elective-group ,(first domain::+valid-elective-groups+))
               ("B" :elective nil :elective-group nil))
             "test")))

(test elective-group-with-wrong-size-signals-data-error
  (signals domain:data-error
    (domain::validate-elective-group-sizes
     `(("A" :elective-group ,(first domain::+valid-elective-groups+))
       ("B" :elective-group ,(first domain::+valid-elective-groups+)))
     "test")))

(test course-without-term-signals-data-error
  (signals domain:data-error
    (domain::validate-all-have-term '(("A" :name "sin cuatrimestre")) "test")))
