;;;; tests/cli/format-tests.lisp
;;;;
;;;; Pruebas de la capa de presentacion.
;;;;
;;;; Por que existe este archivo: la suite llego a estar verde con 225
;;;; comprobaciones mientras `sbcl --script run.lisp` reventaba con un
;;;; FORMAT-ERROR, porque ninguna prueba renderizaba el informe. Un error en
;;;; una directiva de FORMAT solo aparece al ejecutarla. Estas pruebas
;;;; renderizan a un string en memoria, sin E/S real, para que ese fallo no
;;;; pueda volver a pasar inadvertido.

(in-package #:expert-system.tests)
(in-suite all-tests)

(defun render-report ()
  "Renderiza el informe completo del perfil de demostracion a un string."
  (with-output-to-string (out)
    (cli::print-report
     (domain:run-session "data/courses.lisp" "data/profiles/sample-profile.lisp")
     out)))

(test the-full-report-renders-without-error
  "Ejercita todas las directivas de FORMAT del informe."
  (let ((text (render-report)))
    (is (plusp (length text)))))

(test the-report-includes-every-section
  (let ((text (render-report)))
    (dolist (section '("PERFIL ANALIZADO"
                       "RECOMENDACIONES"
                       "ESTADISTICAS"
                       "ESTADISTICAS DEL CATALOGO"
                       "TRAZA DEL MOTOR"))
      (is (search section text)))))

(test the-catalog-section-reports-rule-coverage
  (let ((text (render-report)))
    (is (search "Cobertura de reglas:" text))
    (is (search "Cursos cuello de botella" text))
    (is (search "Dificultad promedio por area" text))))

(test report-lines-fit-in-eighty-columns
  "El PRD pide salida legible en una terminal de 80 columnas. La traza queda
   fuera del limite a proposito: lista contenido de hechos de longitud
   variable y recortarla perderia informacion de la explicacion."
  (let* ((text (render-report))
         (report (subseq text 0 (or (search "TRAZA DEL MOTOR" text) (length text))))
         (too-long (remove-if (lambda (line) (<= (length line) 80))
                              (split-lines report))))
    (is (null too-long)
        "Estas lineas pasan de 80 columnas: ~{~%  ~s~}" too-long)))

(defun split-lines (text)
  (loop with start = 0
        for pos = (position #\Newline text :start start)
        collect (subseq text start (or pos (length text)))
        while pos
        do (setf start (1+ pos))))
