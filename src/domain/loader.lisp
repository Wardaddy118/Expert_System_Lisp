;;;; src/domain/loader.lisp
;;;;
;;;; Carga y valida data/courses.lisp y los perfiles de data/profiles/,
;;;; y los normaliza a hechos planos en la memoria de trabajo (ADR-006).
;;;; Es la unica parte del dominio que sabe leer archivos: el resto del
;;;; dominio (knowledge.lisp, explain.lisp, stats.lisp) solo ve hechos.

(in-package #:expert-system.domain)

(define-condition data-error (error)
  ((file :initarg :file :initform nil :reader data-error-file)
   (message :initarg :message :reader data-error-message))
  (:report (lambda (c s)
             (format s "Error en datos (~a): ~a" (data-error-file c) (data-error-message c))))
  (:documentation "Error en los archivos de data/. Aborta la carga: datos
   invalidos nunca se cargan a medias (docs/context/system_patterns.md)."))

(define-condition circular-prerequisites (data-error)
  ((cycle :initarg :cycle :reader circular-prerequisites-cycle))
  (:report (lambda (c s)
             (format s "Ciclo de requisitos en ~a: ~{~a~^ -> ~}"
                     (data-error-file c) (circular-prerequisites-cycle c)))))

(defparameter +valid-elective-groups+
  '(sixth-term-elective seventh-term-elective eighth-term-elective)
  "Los tres bloques electivos del plan de Bachillerato en Ingenieria en
   Sistemas de Computacion (Fidelitas): sexto, setimo y octavo
   cuatrimestre. El estudiante elige exactamente una materia por bloque.")

(defparameter +electives-per-group+ 4
  "Cuantas opciones trae cada bloque electivo en el programa suministrado.")

(defun load-catalog (wm path)
  "Lee el catalogo de cursos desde PATH, lo valida (sin duplicados, sin
   requisitos colgantes, sin ciclos, cuatrimestre presente, grupos
   electivos consistentes y completos) y afirma sus hechos en WM. Retorna
   WM. Señala DATA-ERROR o CIRCULAR-PREREQUISITES si los datos son
   invalidos."
  (let ((entries (read-sexp-file path)))
    (validate-no-duplicate-ids entries path)
    (validate-prerequisites-exist entries path)
    (validate-acyclic entries path)
    (validate-all-have-term entries path)
    (validate-elective-consistency entries path)
    (validate-elective-group-sizes entries path)
    (dolist (entry entries wm)
      (assert-course-facts wm entry))))

(defun load-profile (wm path)
  "Lee un perfil de estudiante desde PATH y afirma sus hechos en WM.
   Delega en ASSERT-PROFILE: leer el archivo y afirmar los hechos son dos
   cosas distintas, y la CLI interactiva necesita la segunda sin la
   primera (arma la property list preguntando por consola, sin archivo)."
  (assert-profile wm (read-sexp-file path)))

(defun assert-profile (wm plist)
  "Afirma en WM los hechos de perfil de PLIST, una property list con las
   claves :approved, :interests, :target-area, :available,
   :difficulty-tolerance y :credit-limit. Retorna WM. Un curso aprobado
   que no existe en el catalogo (ya cargado en WM) se advierte y se
   ignora; no aborta la carga (caso borde del PRD)."
  (let* ((known-ids (mapcar #'second (engine:query-facts wm 'course))))
    (dolist (id (getf plist :approved))
      (if (member id known-ids :test #'equal)
          (engine:assert-fact (list 'approved id) wm)
          (warn "El curso aprobado ~a no existe en el catalogo; se ignora." id)))
    (dolist (area (getf plist :interests))
      (engine:assert-fact (list 'interest area) wm))
    (engine:assert-fact (list 'target-area (getf plist :target-area)) wm)
    (dolist (block (getf plist :available))
      (engine:assert-fact (list* 'available block) wm))
    (engine:assert-fact (list 'difficulty-tolerance (getf plist :difficulty-tolerance)) wm)
    (engine:assert-fact (list 'credit-limit (getf plist :credit-limit)) wm)
    wm))

;;; --- Lectura del archivo -----------------------------------------------

(defun read-sexp-file (path)
  "Lee la unica forma S-expression de PATH con READ. Señala DATA-ERROR si
   el archivo no se puede abrir. Los simbolos se internan siempre en el
   paquete expert-system.domain, sin importar cual sea *PACKAGE* en quien
   llama: si no se fijara, un simbolo como ALGORITHMS leido desde main.lisp
   caeria en otro paquete y dejaria de ser EQ al ALGORITHMS que usan las
   reglas de knowledge.lisp, y el matching fallaria en silencio."
  (handler-case
      (let ((*package* (find-package '#:expert-system.domain)))
        (with-open-file (in path :direction :input)
          (read in)))
    (file-error ()
      (error 'data-error :file path
                          :message "No se pudo abrir el archivo."))))

;;; --- Validacion del catalogo --------------------------------------------

(defun validate-no-duplicate-ids (entries path)
  (let ((duplicate (find-duplicate (mapcar #'first entries))))
    (when duplicate
      (error 'data-error :file path
                          :message (format nil "Codigo de curso duplicado: ~a" duplicate)))))

(defun find-duplicate (list)
  "Retorna el primer elemento de LIST que aparece mas de una vez, o NIL."
  (loop for tail on list
        when (member (first tail) (rest tail) :test #'equal)
          return (first tail)))

(defun validate-prerequisites-exist (entries path)
  (let ((known-ids (mapcar #'first entries)))
    (dolist (entry entries)
      (dolist (req (getf (rest entry) :prerequisites))
        (unless (member req known-ids :test #'equal)
          (error 'data-error :file path
                              :message (format nil "El curso ~a tiene un requisito inexistente: ~a"
                                                (first entry) req)))))))

(defun validate-acyclic (entries path)
  "Recorre el grafo de requisitos en profundidad. Si visita un curso que ya
   esta en el camino actual, hay un ciclo."
  (let ((visiting nil)
        (visited nil))
    (labels ((prerequisites-of (id)
               (getf (rest (find id entries :key #'first :test #'equal)) :prerequisites))
             (visit (id path-so-far)
               (cond
                 ((member id visited :test #'equal) nil)
                 ((member id visiting :test #'equal)
                  (error 'circular-prerequisites
                         :file path
                         :message "Ciclo de requisitos detectado."
                         :cycle (reverse (cons id path-so-far))))
                 (t
                  (push id visiting)
                  (dolist (req (prerequisites-of id))
                    (visit req (cons id path-so-far)))
                  (setf visiting (remove id visiting :test #'equal))
                  (push id visited)))))
      (dolist (entry entries)
        (visit (first entry) nil)))))

(defun validate-all-have-term (entries path)
  "Todo curso debe declarar su cuatrimestre (:term); es dato oficial del
   programa, no provisional, y sin el las estadisticas por cuatrimestre
   no tendrian sentido."
  (dolist (entry entries)
    (unless (getf (rest entry) :term)
      (error 'data-error :file path
                          :message (format nil "El curso ~a no tiene cuatrimestre (:term)."
                                            (first entry))))))

(defun validate-elective-consistency (entries path)
  "Un curso electivo debe declarar un grupo valido; un curso que no es
   electivo no debe declarar ninguno. Evita que :elective y
   :elective-group se contradigan entre si."
  (dolist (entry entries)
    (let ((elective-p (getf (rest entry) :elective))
          (group (getf (rest entry) :elective-group)))
      (cond
        ((and elective-p (null group))
         (error 'data-error :file path
                             :message (format nil "~a es electivo pero no declara :elective-group."
                                               (first entry))))
        ((and (not elective-p) group)
         (error 'data-error :file path
                             :message (format nil "~a no es electivo pero declara :elective-group ~a."
                                               (first entry) group)))
        ((and group (not (member group +valid-elective-groups+)))
         (error 'data-error :file path
                             :message (format nil "~a tiene un :elective-group invalido: ~a. Validos: ~a."
                                               (first entry) group +valid-elective-groups+)))))))

(defun validate-elective-group-sizes (entries path)
  "Cada bloque electivo debe traer exactamente +ELECTIVES-PER-GROUP+
   opciones, tal como las trae el programa suministrado (BR de datos, no
   del motor de inferencia)."
  (dolist (group +valid-elective-groups+)
    (let ((count (count-if (lambda (e) (eq (getf (rest e) :elective-group) group)) entries)))
      (unless (= count +electives-per-group+)
        (error 'data-error :file path
                            :message (format nil "El grupo ~a debe tener ~a electivas, tiene ~a."
                                              group +electives-per-group+ count))))))

;;; --- Lectura del perfil para presentacion --------------------------------
;;;
;;; La CLI no debe conocer los nombres de las relaciones (APPROVED,
;;; INTEREST, ...): son simbolos de este paquete y pedirle a otra capa que
;;; los escriba sin prefijo los interna en un paquete distinto, que deja
;;; de ser EQ al que usan las reglas. Estas funciones devuelven listas
;;; simples, seguras de usar desde cualquier paquete.

(defun profile-approved (wm)
  (mapcar #'second (engine:query-facts wm 'approved)))

(defun profile-interests (wm)
  (mapcar #'second (engine:query-facts wm 'interest)))

(defun profile-target-area (wm)
  (second (first (engine:query-facts wm 'target-area))))

(defun profile-available (wm)
  (mapcar #'rest (engine:query-facts wm 'available)))

(defun profile-difficulty-tolerance (wm)
  (second (first (engine:query-facts wm 'difficulty-tolerance))))

(defun profile-credit-limit (wm)
  (second (first (engine:query-facts wm 'credit-limit))))

;;; --- Normalizacion a hechos ----------------------------------------------

(defun assert-course-facts (wm entry)
  "Afirma en WM los hechos de catalogo que describe ENTRY, una property
   list como (\"SC-304\" :name ... :term ... :laboratory ... :collegiate
   ... :elective ... :elective-group ... :credits ... :area ...
   :difficulty ... :prerequisites (...) :schedule (...)).

   TERM, LABORATORY, COLLEGIATE y ELECTIVE-GROUP son datos oficiales del
   programa; CREDITS, AREA, DIFFICULTY, PREREQUISITES y SCHEDULE son
   provisionales para esta demostracion (ver cabecera de data/courses.lisp).

   LABORATORY y COLLEGIATE solo se afirman cuando son verdaderos: no hay
   negacion en los hechos (ADR-006), la ausencia del hecho ES el valor
   falso."
  (let ((id (first entry))
        (props (rest entry)))
    (engine:assert-fact (list 'course id) wm)
    (engine:assert-fact (list 'course-name id (getf props :name)) wm)
    (engine:assert-fact (list 'term id (getf props :term)) wm)
    (when (getf props :laboratory)
      (engine:assert-fact (list 'laboratory id) wm))
    (when (getf props :collegiate)
      (engine:assert-fact (list 'collegiate id) wm))
    (when (getf props :elective-group)
      (engine:assert-fact (list 'elective id (getf props :elective-group)) wm))
    (engine:assert-fact (list 'credits id (getf props :credits)) wm)
    (engine:assert-fact (list 'area id (getf props :area)) wm)
    (engine:assert-fact (list 'difficulty id (getf props :difficulty)) wm)
    (dolist (req (getf props :prerequisites))
      (engine:assert-fact (list 'prerequisite id req) wm))
    (dolist (block (getf props :schedule))
      (engine:assert-fact (list* 'schedule id block) wm))))

;;; --- Consultas de catalogo para la CLI ------------------------------------
;;;
;;; La capa de presentacion necesita saber que es valido antes de preguntar
;;; (que codigos existen, que areas hay, que bloques de horario). Se expone
;;; aqui en vez de dejar que la CLI consulte hechos del dominio con
;;; DOMAIN::, que romperia la separacion de capas.

(defun catalog-course-ids (wm)
  "Codigos de todos los cursos del catalogo, ordenados."
  (sort (mapcar #'second (engine:query-facts wm 'course)) #'string<))

(defun catalog-areas (wm)
  "Areas profesionales presentes en el catalogo, ordenadas alfabeticamente."
  (sort (remove-duplicates (mapcar #'third (engine:query-facts wm 'area)))
        #'string< :key #'symbol-name))

(defun catalog-days (wm)
  "Dias en que hay clases en el catalogo, en orden de la semana."
  (let ((week '(monday tuesday wednesday thursday friday saturday))
        (present (remove-duplicates (mapcar #'third (engine:query-facts wm 'schedule)))))
    (remove-if-not (lambda (day) (member day present)) week)))

(defun catalog-slots (wm)
  "Franjas horarias en uso en el catalogo, en orden natural del dia."
  (let ((order '(morning afternoon evening))
        (present (remove-duplicates (mapcar #'fourth (engine:query-facts wm 'schedule)))))
    (remove-if-not (lambda (slot) (member slot present)) order)))

(defun course-name-for (wm course-id)
  "Nombre legible de COURSE-ID, o el propio codigo si no tiene nombre.

   No delega en COURSE-NAME-OF de stats.lisp a proposito: ese archivo se
   carga despues que este y la referencia adelantada solo serviria para
   ganarse una advertencia de compilacion."
  (or (third (find course-id (engine:query-facts wm 'course-name)
                   :key #'second :test #'equal))
      course-id))
