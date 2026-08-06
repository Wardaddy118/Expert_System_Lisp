;;;; src/domain/stats.lisp
;;;;
;;;; Estadisticas del estudiante y del catalogo (FR-040, FR-041). Implementa
;;;; BR-030: toda estadistica se deriva de la memoria de trabajo final de
;;;; la sesion, nunca con una consulta aparte al catalogo, para que nunca
;;;; pueda contradecir lo que el motor concluyo.

(in-package #:expert-system.domain)

(defstruct stats
  evaluated
  approved
  blocked-by-prerequisites
  schedule-incompatible
  too-difficult
  eligible
  average-difficulty
  recommended-credits)

(defun statistics (session)
  "Calcula las estadisticas de SESSION (un SESSION de knowledge.lisp) leyendo
   unicamente su memoria de trabajo final y su lista de recomendaciones ya
   construida."
  (let* ((wm (session-working-memory session))
         (courses (engine:query-facts wm 'course)))
    (make-stats
     :evaluated (length courses)
     :approved (length (engine:query-facts wm 'approved))
     :blocked-by-prerequisites (count-excluded-by-reason wm 'missing-prerequisites)
     :schedule-incompatible (count-excluded-by-reason wm 'schedule-conflict)
     :too-difficult (count-excluded-by-reason wm 'too-difficult)
     :eligible (length (distinct-second (engine:query-facts wm 'eligible)))
     :average-difficulty (average-difficulty wm courses)
     :recommended-credits (reduce #'+ (mapcar #'recommendation-credits
                                               (session-recommendations session))
                                   :initial-value 0))))

(defun distinct-second (facts)
  (remove-duplicates (mapcar #'second facts) :test #'equal))

(defun count-excluded-by-reason (wm reason)
  (length (distinct-second
           (remove-if-not (lambda (f) (eq (third f) reason)) (engine:query-facts wm 'excluded)))))

(defun average-difficulty (wm courses)
  "Dificultad promedio de todo el catalogo cargado en WM. Si el catalogo
   esta vacio retorna 0 en vez de dividir entre cero."
  (if (null courses)
      0
      (/ (reduce #'+ (mapcar (lambda (c) (course-difficulty wm (second c))) courses))
         (length courses))))

(defun course-difficulty (wm course-id)
  (third (find course-id (engine:query-facts wm 'difficulty) :key #'second :test #'equal)))
