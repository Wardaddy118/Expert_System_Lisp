;;;; tests/cli/session-tests.lisp
;;;;
;;;; Pruebas de la captura interactiva (T012).
;;;;
;;;; El objetivo de T012 pedia que "la logica de sesion sea probable sin E/S
;;;; real". Se cumple porque CAPTURE-PROFILE recibe los streams como
;;;; argumentos: aqui se le pasa un WITH-INPUT-FROM-STRING con las respuestas
;;;; que teclearia una persona y se verifica el perfil que sale, sin teclado,
;;;; sin bloquearse y sin ensuciar la salida estandar.

(in-package #:expert-system.tests)
(in-suite all-tests)

(defun catalog-wm ()
  (domain:load-catalog (engine:make-working-memory) "data/courses.lisp"))

(defun capture-with (answers)
  "Corre CAPTURE-PROFILE alimentandolo con ANSWERS (una linea por pregunta)
   y descartando lo que imprime. Retorna la property list capturada."
  (let ((wm (catalog-wm)))
    (with-input-from-string (in (format nil "~{~a~%~}" answers))
      (with-output-to-string (out)
        (return-from capture-with (cli::capture-profile wm in out))))))

(test capture-builds-a-profile-usable-by-the-domain
  "El perfil capturado tiene que servirle tal cual a DOMAIN:ASSERT-PROFILE."
  (let* ((profile (capture-with '("SC-115 SC-202" "1" "1" "1 2" "1 2" "3" "8")))
         (session (domain:run-session-with-profile "data/courses.lisp" profile)))
    (is (equal '("SC-115" "SC-202") (getf profile :approved)))
    (is (= 3 (getf profile :difficulty-tolerance)))
    (is (= 8 (getf profile :credit-limit)))
    (is (not (null (domain:session-working-memory session))))))

(test capture-accepts-an-empty-answer-for-approved-courses
  "El estudiante de primer ingreso no ha aprobado nada: vacio es valido, no
   un error."
  (let ((profile (capture-with '("" "1" "1" "" "" "3" "12"))))
    (is (null (getf profile :approved)))))

(test capture-ignores-course-codes-that-are-not-in-the-catalog
  "Caso borde del PRD: se avisa y se ignora, no se aborta la sesion."
  (let ((profile (capture-with '("SC-115 NO-EXISTE-999" "1" "1" "" "" "3" "12"))))
    (is (equal '("SC-115") (getf profile :approved)))))

(test capture-normalizes-lowercase-course-codes
  (let ((profile (capture-with '("sc-115" "1" "1" "" "" "3" "12"))))
    (is (equal '("SC-115") (getf profile :approved)))))

(test capture-falls-back-to-defaults-when-the-input-ends
  "Si se acaba la entrada, cada pregunta toma su valor por omision en vez de
   colgarse o reventar. Es lo que pasa al redirigir la entrada."
  (let ((profile (capture-with '())))
    (is (= 3 (getf profile :difficulty-tolerance)))
    (is (= 12 (getf profile :credit-limit)))
    (is (not (null (getf profile :target-area))))))

(test capture-rejects-an-out-of-range-tolerance-and-asks-again
  "La tolerancia va de 1 a 5; un 9 se rechaza y se repregunta."
  (let ((profile (capture-with '("" "1" "1" "" "" "9" "4" "12"))))
    (is (= 4 (getf profile :difficulty-tolerance)))))

(test capture-crosses-days-with-slots
  "Se preguntan dias y franjas por separado; la disponibilidad es el
   producto de ambos, no una lista que la persona tenga que enumerar."
  (let* ((profile (capture-with '("" "1" "1" "1 2" "1" "3" "12")))
         (available (getf profile :available)))
    (is (= 2 (length available)))
    (dolist (block available)
      (is (= 2 (length block))))))

(test capture-allows-several-interests
  (let ((profile (capture-with '("" "1 2 3" "1" "" "" "3" "12"))))
    (is (= 3 (length (getf profile :interests))))))

(test the-target-area-is-always-a-single-symbol
  "entities.md exige exactamente un TARGET-AREA por perfil."
  (let ((profile (capture-with '("" "1 2" "2" "" "" "3" "12"))))
    (is (symbolp (getf profile :target-area)))))

;;; --- Explicacion de un curso puntual ---------------------------------------

(defun explanation-of (course-id)
  (let ((session (domain:run-session "data/courses.lisp"
                                      "data/profiles/sample-profile.lisp")))
    (with-output-to-string (out)
      (cli::print-course-explanation session course-id out))))

(test explaining-a-recommended-course-shows-its-reasons
  (let* ((session (domain:run-session "data/courses.lisp"
                                       "data/profiles/sample-profile.lisp"))
         (first-id (domain:recommendation-course-id
                    (first (domain:session-recommendations session))))
         (text (explanation-of first-id)))
    (is (search "RECOMENDADO" text))))

(test explaining-a-discarded-course-shows-why-it-was-discarded
  (let* ((session (domain:run-session "data/courses.lisp"
                                       "data/profiles/sample-profile.lisp"))
         (first-id (domain:excluded-course-id
                    (first (domain:session-excluded session))))
         (text (explanation-of first-id)))
    (is (search "DESCARTADO" text))
    (is (search "Motivo:" text))))

(test explaining-an-unknown-course-says-so-instead-of-staying-silent
  (let ((text (explanation-of "NO-EXISTE-999")))
    (is (search "No encontre el curso" text))))
