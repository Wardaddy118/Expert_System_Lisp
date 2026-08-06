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
  (print-trace (domain:session-working-memory session) stream)
  (values))

(defun print-profile (wm stream)
  (format stream "~%PERFIL ANALIZADO~%~%")
  (format stream "- Cursos aprobados: ~a~%" (join-or-none (domain:profile-approved wm)))
  (format stream "- Intereses: ~a~%" (join-or-none (domain:profile-interests wm)))
  (format stream "- Horarios disponibles: ~a~%"
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
        (format stream "- ~a~%  Motivo: ~a~%"
                (domain:excluded-course-name e) (describe-reason (domain:excluded-reason e)))))
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

(defun print-trace (wm stream)
  (format stream "~%TRAZA DEL MOTOR~%~%")
  (dolist (entry (engine:trace-entries wm))
    (format stream "- Regla aplicada: ~a (ciclo ~a)~%"
            (string-downcase (symbol-name (engine:trace-entry-rule-name entry)))
            (engine:trace-entry-cycle entry))
    (dolist (fact (engine:trace-entry-asserted-facts entry))
      (format stream "  Hecho generado: ~a~%" (format-fact fact)))))

;;; --- Utilidades de formato ------------------------------------------------

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
