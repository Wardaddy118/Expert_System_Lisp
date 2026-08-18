;;;; src/cli/format.lisp
;;;;
;;;; Presentacion en texto del resultado de una sesion. Esta es la unica
;;;; capa con "format t" fuera de aqui (docs/context/system_patterns.md):
;;;; todo lo que imprime, lo imprime este archivo, nunca el dominio.

(in-package #:expert-system.cli)

(defun print-report (session &optional (stream *standard-output*))
  "Imprime el informe completo de SESSION en STREAM: perfil analizado,
   recomendaciones, cursos descartados, estadisticas y traza del motor."
  (format stream "~%SISTEMA DE RECOMENDACIONES ACADEMICAS~%")
  (print-profile (domain:session-working-memory session) stream)
  (print-recommendations (domain:session-recommendations session) stream)
  (print-excluded (domain:session-excluded session) stream)
  (print-statistics (domain:statistics session) stream)
  (print-catalog-statistics (domain:catalog-statistics session) stream)
  (print-trace (domain:session-working-memory session) stream)
  (values))

(defun print-profile (wm stream)
  (format stream "~%PERFIL ANALIZADO~%~%")
  (format stream "- Cursos aprobados: ~a~%" (join-or-none (domain:profile-approved wm)))
  (format stream "- Intereses: ~a~%" (join-or-none (domain:profile-interests wm)))
  (print-wrapped stream "- Horarios disponibles: "
                 (join-or-none (mapcar #'format-schedule-block (domain:profile-available wm))))
  (format stream "- Tolerancia de dificultad: ~a~%" (domain:profile-difficulty-tolerance wm))
  (format stream "- Area profesional objetivo: ~a~%" (stringify (domain:profile-target-area wm))))

(defun print-recommendations (recommendations stream)
  (format stream "~%RECOMENDACIONES~%~%")
  (if (null recommendations)
      (format stream "Ningun curso cumplio los filtros de elegibilidad.~%")
      (loop for r in recommendations
            for i from 1
            do (print-recommendation r i stream))))

(defun print-recommendation (r i stream)
  (format stream "~a. ~a~%" i (domain:recommendation-course-name r))
  (format stream "   Codigo: ~a~%" (domain:recommendation-course-id r))
  (format stream "   Puntuacion: ~a~%" (domain:recommendation-score r))
  (format stream "   Dificultad: ~a~%~%" (domain:recommendation-difficulty r))
  (format stream "   Razones:~%")
  (if (domain:recommendation-reasons r)
      (dolist (reason (domain:recommendation-reasons r))
        (format stream "   - ~a~%" reason))
      (format stream "   - Es elegible segun tus requisitos, horario y dificultad.~%"))
  (when (domain:recommendation-warnings r)
    (format stream "~%   Advertencias:~%")
    (dolist (warning (domain:recommendation-warnings r))
      (format stream "   - ~a~%" warning)))
  (format stream "~%"))

(defun print-excluded (excluded stream)
  (format stream "CURSOS DESCARTADOS~%~%")
  (if (null excluded)
      (format stream "Ningun curso fue descartado.~%")
      (dolist (e excluded)
        (format stream "- ~a~%" (domain:excluded-course-name e))
        (print-wrapped stream "  Motivo: " (describe-reason (domain:excluded-reason e)))))
  (format stream "~%"))

(defun print-statistics (stats stream)
  (format stream "ESTADISTICAS~%~%")
  (format stream "- Cursos evaluados: ~a~%" (domain:stats-evaluated stats))
  (format stream "- Cursos ya aprobados: ~a~%" (domain:stats-approved stats))
  (format stream "- Bloqueados por prerrequisitos: ~a~%" (domain:stats-blocked-by-prerequisites stats))
  (format stream "- Incompatibles con el horario: ~a~%" (domain:stats-schedule-incompatible stats))
  (format stream "- Descartados por dificultad: ~a~%" (domain:stats-too-difficult stats))
  (format stream "- Cursos elegibles: ~a~%" (domain:stats-eligible stats))
  (format stream "- Dificultad promedio: ~,2f~%" (float (domain:stats-average-difficulty stats)))
  (format stream "- Creditos recomendados: ~a~%" (domain:stats-recommended-credits stats)))

(defun print-catalog-statistics (stats stream)
  "Metricas del catalogo y de la base de conocimiento (FR-041), a diferencia
   de PRINT-STATISTICS que describe al estudiante."
  (let ((profiles (domain:catalog-stats-profiles-analyzed stats)))
    (format stream "~%ESTADISTICAS DEL CATALOGO~%~%")
    (format stream "- Perfiles analizados: ~a~%" profiles)
    (when (= profiles 1)
      (print-wrapped stream "  " "Con un solo perfil, 'mas recomendados' aun no compara nada: la metrica cobra sentido con varios perfiles."))

    (format stream "~%  Cursos mas recomendados:~%")
    (print-top-rows (domain:catalog-stats-most-recommended stats) 5 "perfil(es)" stream)

    (format stream "~%  Cursos cuello de botella (cuantos cursos desbloquean):~%")
    (print-top-rows (domain:catalog-stats-bottlenecks stats) 5 "curso(s)" stream)

    (format stream "~%  Dificultad promedio por area:~%")
    (dolist (row (domain:catalog-stats-difficulty-by-area stats))
      (format stream "    ~20a ~,2f  (~a curso(s))~%"
              (string-downcase (symbol-name (first row)))
              (float (second row))
              (third row)))

    (format stream "~%  Cobertura de reglas: ~a de ~a dispararon~%"
            (domain:catalog-stats-rules-fired stats)
            (domain:catalog-stats-rules-total stats))
    (let ((never (domain:catalog-stats-rules-never-fired stats)))
      (if never
          (progn
            (format stream "    Nunca dispararon (conocimiento muerto o datos que no lo ejercitan):~%")
            (dolist (name never)
              (format stream "      - ~a~%" (string-downcase (symbol-name name)))))
          (format stream "    Todas las reglas dispararon al menos una vez.~%")))))

(defun print-top-rows (rows limit unit stream)
  "Imprime las primeras LIMIT filas (id nombre n), o un aviso si no hay."
  (if (null rows)
      (format stream "    (ninguno)~%")
      (dolist (row (subseq rows 0 (min limit (length rows))))
        (format stream "    ~10a ~32a ~a ~a~%"
                (first row) (second row) (third row) unit))))

(defun print-trace (wm stream)
  (format stream "~%TRAZA DEL MOTOR~%~%")
  (dolist (entry (engine:trace-entries wm))
    (format stream "- Regla aplicada: ~a (ciclo ~a)~%"
            (string-downcase (symbol-name (engine:trace-entry-rule-name entry)))
            (engine:trace-entry-cycle entry))
    (dolist (fact (engine:trace-entry-asserted-facts entry))
      (format stream "  Hecho generado: ~a~%" (format-fact fact)))))

;;; --- Utilidades de formato ------------------------------------------------

(defun print-wrapped (stream prefix text &key (width 80))
  "Imprime PREFIX seguido de TEXT cortando en espacios para no pasar WIDTH
   columnas. Las lineas de continuacion se sangran hasta la altura de PREFIX.

   El PRD pide que el informe se lea en una terminal de 80 columnas (FR-050);
   sin esto, una lista larga de horarios o un motivo de descarte extenso se
   desbordan. Hay una prueba que lo verifica sobre el informe completo."
  (let* ((indent (make-string (length prefix) :initial-element #\Space))
         (limit (- width (length prefix)))
         (line "")
         (first-line-p t))
    (flet ((emit ()
             (format stream "~a~a~%" (if first-line-p prefix indent) line)
             (setf first-line-p nil
                   line "")))
      (dolist (word (split-on-spaces text))
        (cond ((string= line "") (setf line word))
              ((<= (+ (length line) 1 (length word)) limit)
               (setf line (concatenate 'string line " " word)))
              (t (emit)
                 (setf line word))))
      (when (or (string/= line "") first-line-p)
        (emit)))))

(defun split-on-spaces (text)
  (loop with start = 0
        for pos = (position #\Space text :start start)
        for word = (subseq text start (or pos (length text)))
        unless (string= word "") collect word
        while pos
        do (setf start (1+ pos))))

(defun join-or-none (items)
  (if items
      (format nil "~{~a~^, ~}" (mapcar #'stringify items))
      "ninguno"))

(defun stringify (x)
  (if (stringp x) x (string-downcase (princ-to-string x))))

(defun format-schedule-block (block)
  (format nil "~a ~a" (string-downcase (princ-to-string (first block)))
          (string-downcase (princ-to-string (second block)))))

(defun format-fact (fact)
  (format nil "(~{~a~^ ~})" (mapcar #'stringify fact)))

(defun describe-reason (reason)
  "Traduce el simbolo de razon (vocabulario cerrado de
   .ace/knowledge/entities.md) a una frase legible. Compara por nombre, no
   por EQ: el simbolo llega interno en expert-system.domain, y esta capa
   no necesita saber ese paquete para explicarlo."
  (let ((name (symbol-name reason)))
    (cond
      ((string= name "ALREADY-APPROVED") "Ya aprobaste este curso.")
      ((string= name "MISSING-PREREQUISITES") "Te faltan requisitos por aprobar.")
      ((string= name "SCHEDULE-CONFLICT") "Su horario no calza con tu disponibilidad declarada.")
      ((string= name "TOO-DIFFICULT") "Supera tu tolerancia a la dificultad.")
      ((string= name "CREDIT-LIMIT-EXCEEDED") "No cabe dentro de tu tope de creditos, dado el orden de prioridad.")
      ((string= name "ELECTIVE-GROUP-LIMIT") "Ya hay otra electiva mejor puntuada de este mismo bloque; solo se puede llevar una.")
      (t (string-downcase name)))))

(defun print-course-explanation (session course-id stream)
  "Explica un curso puntual: si fue recomendado, con que razones y con que
   puntaje; si fue descartado, con cual de las seis razones. Si no aparece
   en ninguna de las dos listas, lo dice en vez de callar."
  (let ((recommendation (find course-id (domain:session-recommendations session)
                              :key #'domain:recommendation-course-id :test #'equal))
        (excluded (find course-id (domain:session-excluded session)
                        :key #'domain:excluded-course-id :test #'equal)))
    (format stream "~%")
    (cond
      (recommendation
       (format stream "~a — RECOMENDADO (puntaje ~a)~%"
               (domain:recommendation-course-name recommendation)
               (domain:recommendation-score recommendation))
       (dolist (reason (domain:recommendation-reasons recommendation))
         (print-wrapped stream "  - " reason))
       (dolist (warning (domain:recommendation-warnings recommendation))
         (print-wrapped stream "  ! " warning)))
      (excluded
       (format stream "~a — DESCARTADO~%" (domain:excluded-course-name excluded))
       (print-wrapped stream "  Motivo: " (describe-reason (domain:excluded-reason excluded))))
      (t
       (print-wrapped stream "  "
                      (format nil "No encontre el curso ~a entre los recomendados ni entre los descartados. Revisa el codigo."
                              course-id))))
    (format stream "~%")))
