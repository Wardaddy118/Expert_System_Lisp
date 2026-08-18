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
  approved-credits
  total-credits
  career-progress
  approved-by-area
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
     :approved-credits (approved-credits wm)
     :total-credits (total-credits wm)
     :career-progress (career-progress wm)
     :approved-by-area (approved-by-area wm)
     :blocked-by-prerequisites (count-excluded-by-reason wm 'missing-prerequisites)
     :schedule-incompatible (count-excluded-by-reason wm 'schedule-conflict)
     :too-difficult (count-excluded-by-reason wm 'too-difficult)
     :eligible (length (distinct-second (engine:query-facts wm 'eligible)))
     :average-difficulty (average-difficulty wm courses)
     :recommended-credits (reduce #'+ (mapcar #'recommendation-credits
                                               (session-recommendations session))
                                   :initial-value 0))))

(defun approved-credits (wm)
  "Suma de creditos de los cursos aprobados por el estudiante (FR-040)."
  (reduce #'+ (mapcar (lambda (f) (or (course-credits wm (second f)) 0))
                      (engine:query-facts wm 'approved))
          :initial-value 0))

(defun total-credits (wm)
  "Suma de creditos de todo el catalogo cargado (FR-040)."
  (reduce #'+ (mapcar (lambda (f) (or (course-credits wm (second f)) 0))
                      (engine:query-facts wm 'course))
          :initial-value 0))

(defun career-progress (wm)
  "Implementa BR-031: creditos aprobados sobre creditos totales del catalogo.

   Es avance RELATIVO AL CATALOGO MODELADO, no al plan de estudios real: el
   catalogo es un subconjunto (decision D-03). Quien presente este numero
   tiene que decirlo, y por eso la capa de presentacion lo acompana siempre
   de esa aclaracion. Con catalogo vacio retorna 0 en vez de dividir entre
   cero."
  (let ((total (total-credits wm)))
    (if (zerop total)
        0
        (/ (approved-credits wm) total))))

(defun approved-by-area (wm)
  "Distribucion de los cursos aprobados por area profesional (FR-040):
   lista de (area cantidad creditos), ordenada alfabeticamente por area para
   que no dependa del orden de la tabla hash."
  (let ((by-area (make-hash-table :test #'eq)))
    (dolist (fact (engine:query-facts wm 'approved))
      (let ((area (third (find (second fact) (engine:query-facts wm 'area)
                               :key #'second :test #'equal))))
        (when area
          (push (second fact) (gethash area by-area)))))
    (sort (loop for area being the hash-keys of by-area using (hash-value ids)
                collect (list area
                              (length ids)
                              (reduce #'+ (mapcar (lambda (id) (or (course-credits wm id) 0)) ids)
                                      :initial-value 0)))
          #'string< :key (lambda (row) (symbol-name (first row))))))

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

(defun course-name-of (wm course-id)
  (or (third (find course-id (engine:query-facts wm 'course-name) :key #'second :test #'equal))
      course-id))

;;; --- Estadisticas del catalogo (FR-041, tarea T011) -------------------------
;;;
;;; A diferencia de STATS, que describe la situacion de UN estudiante, estas
;;; metricas describen el catalogo y la base de conocimiento en si. Igual que
;;; las del estudiante, se derivan de la memoria de trabajo de sesiones ya
;;; corridas (BR-030): nunca se consulta data/ por aparte.

(defstruct catalog-stats
  profiles-analyzed
  most-recommended
  bottlenecks
  difficulty-by-area
  rules-total
  rules-fired
  rules-never-fired)

(defun catalog-statistics (sessions)
  "Calcula las metricas agregadas del catalogo a partir de SESSIONS, que es
   una lista de SESSION ya corridas (o una sola SESSION suelta).

   Con un unico perfil, MOST-RECOMMENDED solo dice que curso se recomendo en
   esa corrida; la metrica adquiere sentido comparativo cuando existen varios
   perfiles (tarea T013). El campo PROFILES-ANALYZED se reporta justamente
   para que quien lea la salida sepa sobre cuantos perfiles se calculo."
  (let* ((sessions (if (listp sessions) sessions (list sessions)))
         (wm (session-working-memory (first sessions))))
    (make-catalog-stats
     :profiles-analyzed (length sessions)
     :most-recommended (most-recommended-courses sessions wm)
     :bottlenecks (bottleneck-courses wm)
     :difficulty-by-area (difficulty-by-area wm)
     :rules-total (length engine:*rules*)
     :rules-fired (length (fired-rule-names sessions))
     :rules-never-fired (never-fired-rule-names sessions))))

(defun most-recommended-courses (sessions wm)
  "Lista (id nombre veces) de los cursos recomendados, ordenada por cantidad
   de perfiles que los recibieron (desc) y luego por codigo (asc) para que el
   orden sea determinista (NFR-005)."
  (let ((counts (make-hash-table :test #'equal)))
    (dolist (session sessions)
      (dolist (rec (session-recommendations session))
        (incf (gethash (recommendation-course-id rec) counts 0))))
    (sort-by-count-then-id
     (loop for id being the hash-keys of counts using (hash-value n)
           collect (list id (course-name-of wm id) n)))))

(defun bottleneck-courses (wm)
  "Lista (id nombre n) de cursos que son requisito de N cursos, ordenada por N
   descendente. Implementa la parte de catalogo de BR-006.

   El hecho es (prerequisite <curso-que-requiere> <curso-requerido>), asi que
   el cuello de botella es el TERCER elemento y se cuenta cuantos cursos
   distintos lo requieren."
  (let ((counts (make-hash-table :test #'equal)))
    (dolist (fact (engine:query-facts wm 'prerequisite))
      (pushnew (second fact) (gethash (third fact) counts) :test #'equal))
    (sort-by-count-then-id
     (loop for required being the hash-keys of counts using (hash-value dependents)
           collect (list required (course-name-of wm required) (length dependents))))))

(defun difficulty-by-area (wm)
  "Lista (area promedio cantidad) con la dificultad promedio de cada area
   profesional, ordenada alfabeticamente por area para que sea determinista."
  (let ((by-area (make-hash-table :test #'eq)))
    (dolist (fact (engine:query-facts wm 'area))
      (let ((difficulty (course-difficulty wm (second fact))))
        (when difficulty
          (push difficulty (gethash (third fact) by-area)))))
    (sort (loop for area being the hash-keys of by-area using (hash-value difficulties)
                collect (list area
                              (/ (reduce #'+ difficulties) (length difficulties))
                              (length difficulties)))
          #'string< :key (lambda (row) (symbol-name (first row))))))

(defun fired-rule-names (sessions)
  "Nombres de las reglas que dispararon al menos una vez en alguna de SESSIONS."
  (let ((fired '()))
    (dolist (session sessions fired)
      (dolist (entry (engine:trace-entries (session-working-memory session)))
        (pushnew (engine:trace-entry-rule-name entry) fired)))))

(defun never-fired-rule-names (sessions)
  "Reglas registradas que nunca dispararon. Una regla que nunca dispara es
   conocimiento muerto, o datos que no la ejercitan: en ambos casos es algo
   que hay que mirar, no ruido."
  (let ((fired (fired-rule-names sessions)))
    (sort (remove-if (lambda (name) (member name fired))
                     (mapcar #'engine:rule-name engine:*rules*))
          #'string< :key #'symbol-name)))

(defun sort-by-count-then-id (rows)
  "Ordena filas (id nombre n) por N descendente, desempatando por ID
   ascendente para que el resultado no dependa del orden de la tabla hash."
  (sort rows (lambda (a b)
               (if (= (third a) (third b))
                   (string< (first a) (first b))
                   (> (third a) (third b))))))
