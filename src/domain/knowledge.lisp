;;;; src/domain/knowledge.lisp
;;;;
;;;; Las defrule del dominio academico (.ace/knowledge/business-rules.md).
;;;; Cada regla cita el BR que implementa. Este archivo es el unico lugar
;;;; del proyecto donde "conocimiento como datos" se vuelve conocimiento
;;;; academico concreto: nada de esto sabe de que otras reglas dependen,
;;;; solo declara condiciones y conclusiones.
;;;;
;;;; Nota sobre prioridades: cuando una regla usa (not X) sobre un hecho X
;;;; que OTRA regla deriva (no un hecho de catalogo o de perfil), hace
;;;; falta que esa otra regla se dispare primero siempre, en todos los
;;;; cursos, antes de que la negacion se evalue -- si no, la negacion
;;;; podria dar un falso positivo en un ciclo temprano. Por eso este
;;;; archivo usa niveles de prioridad separados por franjas de 5 (40, 35,
;;;; 30, 25, 20, 15, 10): la resolucion de conflictos siempre dispara la
;;;; instanciacion de mayor prioridad en TODO el conjunto de conflicto, asi
;;;; que una franja completa se agota antes de que empiece la siguiente.
;;;; Negar un hecho de entrada (approved, que viene del perfil y nunca lo
;;;; afirma una regla) no tiene este problema y puede ir en cualquier
;;;; prioridad.

(in-package #:expert-system.domain)

;;; --- Pesos de priorizacion configurables (BR-010 a BR-015) -------------
;;;
;;; Un solo lugar para tocar los pesos. Las reglas de abajo los referencian
;;; por nombre en su :then; ENGINE:RUN sustituye el valor actual al
;;; disparar (src/engine/matching.lisp, INSTANTIATE-TEMPLATE), asi que
;;; cambiar un peso aqui cambia el comportamiento sin tocar ninguna regla.

(defparameter +weight-target-area+ 10
  "BR-010: el area del curso es el area profesional objetivo.")
(defparameter +weight-interest+ 5
  "BR-011: el area del curso esta entre los intereses declarados.")
(defparameter +weight-bottleneck+ 8
  "BR-012: el curso es cuello de botella (BR-006).")
(defparameter +weight-unlocks-target-area+ 4
  "BR-013: el curso desbloquea al menos un curso del area objetivo.")
(defparameter +weight-too-easy+ -2
  "BR-014: la dificultad esta 2 o mas niveles por debajo de la tolerancia.")
(defparameter +weight-general-education+ 3
  "BR-015: el curso es de formacion general.")

(defparameter +bottleneck-threshold+ 3
  "BR-006: numero minimo de cursos dependientes para ser cuello de botella.")

;;; --- Elegibilidad (BR-001 a BR-003, duras) ------------------------------

(engine:defrule missing-prerequisite-detected
  "Auxiliar de BR-001: ?id tiene al menos un requisito sin aprobar."
  :priority 40
  :when ((prerequisite ?id ?req) (not (approved ?req)))
  :then ((missing-prerequisite ?id)))

(engine:defrule prerequisites-satisfied-when-none-missing
  "Implementa BR-001: todos los requisitos de ?id estan aprobados."
  :priority 35
  :when ((course ?id) (not (missing-prerequisite ?id)))
  :then ((prerequisites-satisfied ?id)))

(engine:defrule schedule-block-unavailable-detected
  "Auxiliar de BR-003: ?id tiene un bloque de horario fuera de la
   disponibilidad declarada por el estudiante."
  :priority 40
  :when ((schedule ?id ?day ?slot) (not (available ?day ?slot)))
  :then ((schedule-block-unavailable ?id)))

(engine:defrule schedule-fits-when-no-conflict
  "Implementa BR-003: todos los bloques de horario de ?id caen dentro de
   la disponibilidad declarada."
  :priority 35
  :when ((course ?id) (not (schedule-block-unavailable ?id)))
  :then ((schedule-fits ?id)))

(engine:defrule eligible-when-prerequisites-and-schedule-ok
  "Implementa BR-001, BR-002 y BR-003: ?id es elegible si no esta
   aprobado, sus requisitos estan satisfechos y su horario calza."
  :priority 30
  :when ((course ?id) (not (approved ?id))
         (prerequisites-satisfied ?id) (schedule-fits ?id))
  :then ((eligible ?id)))

;;; --- Cuello de botella (BR-006) ------------------------------------------

(engine:defrule bottleneck-with-three-dependents
  "Implementa BR-006: ?id es prerrequisito de 3 o mas cursos distintos. La
   prueba PRECEDES exige un orden estricto entre los tres dependientes
   para que dispare una sola vez por umbral alcanzado, en vez de una vez
   por cada permutacion de los mismos tres cursos."
  :priority 25
  :when ((prerequisite ?c1 ?id) (prerequisite ?c2 ?id) (prerequisite ?c3 ?id)
         (engine:precedes ?c1 ?c2) (engine:precedes ?c2 ?c3))
  :then ((bottleneck ?id +bottleneck-threshold+)))

;;; --- Tolerancia a la dificultad (BR-005) ---------------------------------

(engine:defrule within-tolerance-rule
  "Implementa BR-005: la dificultad de ?id no excede la tolerancia
   declarada por el estudiante."
  :priority 25
  :when ((course ?id) (difficulty ?id ?d) (difficulty-tolerance ?t) (engine:at-most ?d ?t))
  :then ((within-tolerance ?id)))

(engine:defrule bottleneck-exception-to-tolerance
  "Implementa la excepcion de BR-005: un cuello de botella que excede la
   tolerancia por exactamente un nivel se recomienda igual, marcado con
   advertencia."
  :priority 25
  :when ((course ?id) (difficulty ?id ?d) (difficulty-tolerance ?t)
         (bottleneck ?id ?n) (engine:exceeds-by-one ?d ?t))
  :then ((within-tolerance ?id) (tolerance-warning ?id)))

;;; --- Afinidad (soporte de BR-010, BR-011 y BR-013) -----------------------

(engine:defrule area-match-rule
  "?id coincide con el area profesional objetivo del estudiante."
  :priority 25
  :when ((area ?id ?a) (target-area ?a))
  :then ((area-match ?id)))

(engine:defrule interest-match-rule
  "?id coincide con alguno de los intereses declarados por el estudiante."
  :priority 25
  :when ((area ?id ?a) (interest ?a))
  :then ((interest-match ?id)))

;;; --- Priorizacion (BR-010 a BR-015, blandas) -----------------------------

(engine:defrule priority-target-area
  "Implementa BR-010."
  :priority 20
  :when ((eligible ?id) (area-match ?id))
  :then ((priority ?id +weight-target-area+)))

(engine:defrule priority-interest
  "Implementa BR-011."
  :priority 20
  :when ((eligible ?id) (interest-match ?id))
  :then ((priority ?id +weight-interest+)))

(engine:defrule priority-bottleneck
  "Implementa BR-012."
  :priority 20
  :when ((eligible ?id) (bottleneck ?id ?n))
  :then ((priority ?id +weight-bottleneck+)))

(engine:defrule priority-unlocks-target-area
  "Implementa BR-013: ?id es requisito directo de un curso del area
   profesional objetivo."
  :priority 20
  :when ((eligible ?id) (prerequisite ?unlocked ?id)
         (area ?unlocked ?a) (target-area ?a))
  :then ((priority ?id +weight-unlocks-target-area+)))

(engine:defrule priority-too-easy
  "Implementa BR-014: la dificultad esta al menos 2 niveles por debajo de
   la tolerancia declarada."
  :priority 20
  :when ((eligible ?id) (difficulty ?id ?d) (difficulty-tolerance ?t)
         (engine:at-least-below ?t ?d 2))
  :then ((priority ?id +weight-too-easy+)))

(engine:defrule priority-general-education
  "Implementa BR-015. Simplificacion de esta primera version: se premia
   todo curso elegible de formacion general, sin contar cuantos le
   faltan al estudiante -- ese conteo es una agregacion que el matching
   por patrones posicionales no expresa (ver docs/adr/ADR-005 y la nota
   de limitaciones del proyecto)."
  :priority 20
  :when ((eligible ?id) (area ?id general-education))
  :then ((priority ?id +weight-general-education+)))

;;; --- De elegible a recomendado (BR-007) ----------------------------------
;;;
;;; Una regla por cada razon de afinidad positiva, todas concluyendo el
;;; mismo hecho RECOMMENDED. Afirmar el mismo hecho desde varias reglas es
;;; valido (ENGINE:ASSERT-FACT es idempotente) y dispensa con la necesidad
;;; de sumar un numero variable de hechos PRIORITY dentro de una condicion,
;;; que el matching posicional tampoco expresa.

(engine:defrule recommended-via-target-area
  "Implementa BR-007 via BR-010."
  :priority 15
  :when ((eligible ?id) (within-tolerance ?id) (area-match ?id))
  :then ((recommended ?id)))

(engine:defrule recommended-via-interest
  "Implementa BR-007 via BR-011."
  :priority 15
  :when ((eligible ?id) (within-tolerance ?id) (interest-match ?id))
  :then ((recommended ?id)))

(engine:defrule recommended-via-bottleneck
  "Implementa BR-007 via BR-012."
  :priority 15
  :when ((eligible ?id) (within-tolerance ?id) (bottleneck ?id ?n))
  :then ((recommended ?id)))

(engine:defrule recommended-via-unlock
  "Implementa BR-007 via BR-013."
  :priority 15
  :when ((eligible ?id) (within-tolerance ?id) (prerequisite ?unlocked ?id)
         (area ?unlocked ?a) (target-area ?a))
  :then ((recommended ?id)))

(engine:defrule recommended-via-general-education
  "Implementa BR-007 via BR-015."
  :priority 15
  :when ((eligible ?id) (within-tolerance ?id) (area ?id general-education))
  :then ((recommended ?id)))

;;; --- Exclusiones explicadas (BR-021) --------------------------------------

(engine:defrule excluded-already-approved
  "Implementa BR-002 + BR-021: no se recomienda lo ya aprobado."
  :priority 10
  :when ((course ?id) (approved ?id))
  :then ((excluded ?id already-approved)))

(engine:defrule excluded-missing-prerequisites
  "Implementa BR-021 para BR-001."
  :priority 10
  :when ((course ?id) (not (approved ?id)) (missing-prerequisite ?id))
  :then ((excluded ?id missing-prerequisites)))

(engine:defrule excluded-schedule-conflict
  "Implementa BR-021 para BR-003."
  :priority 10
  :when ((course ?id) (not (approved ?id))
         (prerequisites-satisfied ?id) (schedule-block-unavailable ?id))
  :then ((excluded ?id schedule-conflict)))

(engine:defrule excluded-too-difficult
  "Implementa BR-021 para BR-005."
  :priority 10
  :when ((eligible ?id) (not (within-tolerance ?id)))
  :then ((excluded ?id too-difficult)))

;;; --- Post-procesamiento: tope de creditos (BR-004) ------------------------
;;;
;;; BR-004 opera "sobre el conjunto ya priorizado, no sobre cursos
;;; individuales" y "despues de la quiescencia del motor" (asi lo dice la
;;; propia especificacion en business-rules.md). Sumar creditos en orden de
;;; prioridad hasta llenar un cupo es una agregacion sobre una lista de
;;; longitud variable: no se puede expresar con condiciones de aridad fija,
;;; asi que en vez de forzarla dentro de una regla, es la unica logica de
;;; dominio que corre como funcion Lisp normal, despues de RUN. Se
;;; documenta aqui y en el README como una simplificacion deliberada.

(defun course-total-priority (wm course-id)
  "Suma los hechos (priority COURSE-ID n) de WM para COURSE-ID. Es el
   'puntaje final' de entities.md: varias reglas aportan, y el total se
   ve sumando sus aportes por separado."
  (reduce #'+
          (mapcar #'third
                  (remove-if-not (lambda (f) (equal (second f) course-id))
                                  (engine:query-facts wm 'priority)))
          :initial-value 0))

(defun course-credits (wm course-id)
  (third (find course-id (engine:query-facts wm 'credits) :key #'second :test #'equal)))

(defun course-name (wm course-id)
  (third (find course-id (engine:query-facts wm 'course-name) :key #'second :test #'equal)))

(defun recommended-course-ids (wm)
  "Cursos que el motor marco RECOMMENDED y que ningun post-procesamiento
   anterior ya haya excluido. Usada por APPLY-ELECTIVE-GROUP-LIMIT y
   APPLY-CREDIT-LIMIT para que sus recortes se compongan en cualquier
   orden sin pisarse ni gastar presupuesto en un curso que de todas
   formas no se va a mostrar."
  (let ((excluded-ids (remove-duplicates (mapcar #'second (engine:query-facts wm 'excluded))
                                          :test #'equal)))
    (set-difference
     (remove-duplicates (mapcar #'second (engine:query-facts wm 'recommended)) :test #'equal)
     excluded-ids :test #'equal)))

(defun apply-credit-limit (wm)
  "Aplica BR-004 sobre los cursos aun RECOMMENDED (no excluidos por otro
   post-procesamiento previo): toma los de mayor puntaje mientras quepan
   en el CREDIT-LIMIT del perfil; los que no caben se afirman como
   (excluded id credit-limit-exceeded). Retorna WM."
  (let* ((recommended-ids (recommended-course-ids wm))
         (limit (second (first (engine:query-facts wm 'credit-limit))))
         (sorted (sort (copy-list recommended-ids) #'>
                        :key (lambda (id) (course-total-priority wm id))))
         (budget limit))
    (dolist (id sorted wm)
      (let ((credits (course-credits wm id)))
        (if (<= credits budget)
            (decf budget credits)
            (engine:assert-fact (list 'excluded id 'credit-limit-exceeded) wm))))))

;;; --- Post-procesamiento: un curso por bloque electivo ----------------------
;;;
;;; El programa exige elegir UNA materia por bloque electivo (sexto,
;;; setimo y octavo cuatrimestre). Igual que BR-004, decidir "cual de las
;;; recomendadas de este grupo se queda" es comparar entre un numero
;;; variable de cursos del mismo grupo -- otra agregacion que el matching
;;; de patrones de aridad fija no expresa -- asi que corre como funcion de
;;; dominio normal despues de la quiescencia, no como defrule.

(defun course-elective-group (wm course-id)
  (third (find course-id (engine:query-facts wm 'elective) :key #'second :test #'equal)))

(defun apply-elective-group-limit (wm)
  "Implementa BR-008. De los cursos RECOMMENDED que comparten un mismo
   :elective-group, deja solo el de mayor puntaje y afirma
   (excluded id elective-group-limit) para el resto. Se corre antes que
   APPLY-CREDIT-LIMIT para no gastar presupuesto de creditos en una electiva
   que de todas formas se descartaria por venir del mismo bloque que otra
   mejor puntuada.

   Es post-procesamiento y no una DEFRULE por la misma razon que BR-004:
   comparar entre si un conjunto de tamano variable no se expresa con
   condiciones de aridad fija."
  (let* ((recommended-ids (recommended-course-ids wm))
         (groups (remove-duplicates
                  (remove nil (mapcar (lambda (id) (course-elective-group wm id)) recommended-ids)))))
    (dolist (group groups wm)
      (let* ((in-group (remove-if-not (lambda (id) (eq (course-elective-group wm id) group))
                                       recommended-ids))
             (sorted (sort (copy-list in-group) #'>
                            :key (lambda (id) (course-total-priority wm id)))))
        (dolist (id (rest sorted))
          (engine:assert-fact (list 'excluded id 'elective-group-limit) wm))))))

;;; --- Orquestacion de una sesion --------------------------------------------

(defstruct recommendation
  course-id course-name credits difficulty score reasons warnings)

(defstruct excluded
  course-id course-name reason)

(defstruct session
  working-memory recommendations excluded)

(defun run-session (catalog-path profile-path)
  "Carga el catalogo y el perfil, corre el motor hasta quiescencia, aplica
   el limite de una materia por bloque electivo, aplica BR-004 y
   construye el resultado de la sesion: recomendaciones ordenadas por
   puntaje y cursos descartados con su razon. Implementa la excepcion de
   BR-007: si ningun curso llego a RECOMMENDED, se ofrecen los elegibles
   de mayor puntaje con una advertencia explicita."
  (let ((wm (engine:make-working-memory)))
    (load-catalog wm catalog-path)
    (load-profile wm profile-path)
    (infer-session wm)))

(defun run-session-with-profile (catalog-path profile-plist)
  "Como RUN-SESSION, pero el perfil llega como property list en memoria en
   vez de leerse de un archivo. Es la via que usa la captura interactiva de
   la CLI, que arma el perfil preguntando por consola."
  (let ((wm (engine:make-working-memory)))
    (load-catalog wm catalog-path)
    (assert-profile wm profile-plist)
    (infer-session wm)))

(defun infer-session (wm)
  "Corre el motor sobre WM y construye el resultado de la sesion. Asume que
   el catalogo y el perfil ya estan afirmados.

   El orden importa: BR-008 (una electiva por bloque) va antes que BR-004
   (tope de creditos), para no gastar presupuesto de creditos en una
   electiva que igual se descartaria por su bloque."
  (engine:run wm)
  (apply-elective-group-limit wm)
  (apply-credit-limit wm)
  (build-session wm))

(defun build-session (wm)
  (let* ((excluded-ids (remove-duplicates (mapcar #'second (engine:query-facts wm 'excluded))
                                           :test #'equal))
         (recommended-ids (recommended-course-ids wm))
         (fallback-p (null recommended-ids))
         (final-ids (if fallback-p
                        (set-difference
                         (remove-duplicates (mapcar #'second (engine:query-facts wm 'eligible))
                                             :test #'equal)
                         excluded-ids :test #'equal)
                        recommended-ids)))
    (make-session
     :working-memory wm
     :recommendations (sort (mapcar (lambda (id) (build-recommendation wm id fallback-p)) final-ids)
                             #'> :key #'recommendation-score)
     :excluded (mapcar (lambda (id) (build-excluded wm id)) excluded-ids))))

(defun build-recommendation (wm id fallback-p)
  (make-recommendation
   :course-id id
   :course-name (course-name wm id)
   :credits (course-credits wm id)
   :difficulty (third (find id (engine:query-facts wm 'difficulty) :key #'second :test #'equal))
   :score (course-total-priority wm id)
   :reasons (explanation-reasons wm id)
   :warnings (append (explanation-warnings wm id)
                      (when fallback-p
                        (list "Ningun curso alcanzo afinidad positiva; se ofrece por elegibilidad, no por interes.")))))

(defun build-excluded (wm id)
  "Si un curso quedo excluido por mas de una razon, se muestra la primera
   que se encuentre; con una razon basta para el caso borde de BR-021."
  (make-excluded :course-id id
                  :course-name (course-name wm id)
                  :reason (third (find id (engine:query-facts wm 'excluded)
                                       :key #'second :test #'equal))))
