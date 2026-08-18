;;;; src/cli/session.lisp
;;;;
;;;; Flujo de la sesion. Hay dos entradas:
;;;;
;;;;   START              perfil fijo desde data/profiles/. Es la que usa
;;;;                      run.lisp para la demostracion reproducible y la
;;;;                      que corre el gate de verificacion.
;;;;   START-INTERACTIVE  captura el perfil preguntando por consola (T012)
;;;;                      y despues corre la misma sesion.
;;;;
;;;; La captura vive en CAPTURE-PROFILE, que recibe los streams
;;;; explicitamente y no toca *STANDARD-INPUT*: asi se puede probar sin
;;;; teclado (ver tests/cli/session-tests.lisp).

(in-package #:expert-system.cli)

(defparameter *default-catalog-path* "data/courses.lisp")
(defparameter *default-profile-path* "data/profiles/sample-profile.lisp")

(defparameter *demo-profiles*
  '(("data/profiles/sample-profile.lisp"  . "Perfil de demostracion (ejercita las 6 razones de descarte)")
    ("data/profiles/first-year.lisp"      . "Primer ingreso, sin cursos aprobados")
    ("data/profiles/advanced.lisp"        . "Estudiante avanzado, quinto cuatrimestre cumplido")
    ("data/profiles/tight-schedule.lisp"  . "Trabaja: solo dos bloques libres por semana")
    ("data/profiles/low-tolerance.lisp"   . "Tolerancia baja a la dificultad"))
  "Perfiles de ejemplo cargables desde la CLI (FR-051, T013).")

(defun start (&key (catalog-path *default-catalog-path*)
                    (profile-path *default-profile-path*)
                    (stream *standard-output*))
  "Corre una sesion completa con un perfil ya escrito en disco: carga
   CATALOG-PATH y PROFILE-PATH, dispara el motor y escribe el informe en
   STREAM. Si los datos son invalidos, lo reporta en STREAM en vez de
   abortar con una traza cruda."
  (handler-case
      (print-report (domain:run-session catalog-path profile-path) stream)
    (domain:data-error (e)
      (format stream "~%No se pudo cargar los datos del sistema:~%  ~a~%" e))))

(defun start-interactive (&key (catalog-path *default-catalog-path*)
                                (input *standard-input*)
                                (output *standard-output*))
  "Sesion completa por consola (T012): pregunta el perfil, corre el motor,
   presenta el informe y despues deja consultar la explicacion de cursos
   puntuales hasta que la persona decida salir."
  (handler-case
      (let* ((wm (domain:load-catalog (engine:make-working-memory) catalog-path))
             (session (obtain-session wm catalog-path input output)))
        (print-report session output)
        (explain-loop session input output))
    (domain:data-error (e)
      (format output "~%No se pudo cargar los datos del sistema:~%  ~a~%" e))))

;;; --- Eleccion del perfil ---------------------------------------------------

(defun obtain-session (wm catalog-path input output)
  "Deja elegir entre responder las preguntas o cargar uno de los perfiles de
   ejemplo, y devuelve la sesion ya corrida. Los perfiles guardados existen
   para poder mostrar en una demostracion casos que tomaria rato teclear:
   primer ingreso, estudiante avanzado, horario imposible, tolerancia baja."
  (format output "~%SISTEMA DE RECOMENDACIONES ACADEMICAS~%")
  (format output "~%Como querés armar el perfil?~%")
  (let* ((options (cons "Respondiendo unas preguntas"
                        (mapcar #'cdr *demo-profiles*)))
         (choice (ask-choice input output "   > " options :default (first options))))
    (if (equal choice (first options))
        (domain:run-session-with-profile
         catalog-path (capture-profile wm input output))
        (let ((path (car (find choice *demo-profiles* :key #'cdr :test #'equal))))
          (format output "~%Cargando ~a~%" path)
          (domain:run-session catalog-path path)))))

;;; --- Captura del perfil ----------------------------------------------------

(defun capture-profile (wm input output)
  "Pregunta por consola los seis campos del perfil y retorna la property
   list que espera DOMAIN:ASSERT-PROFILE. WM es el catalogo ya cargado: de
   ahi salen los codigos, las areas y los horarios validos, para no
   preguntar a ciegas ni aceptar cualquier cosa."
  (format output "~%Voy a hacerte seis preguntas para armar tu perfil.~%")
  (format output "Podes dejar cualquiera en blanco y sigo con el valor por omision.~%")
  (list :approved (ask-approved wm input output)
        :interests (ask-interests wm input output)
        :target-area (ask-target-area wm input output)
        :available (ask-available wm input output)
        :difficulty-tolerance (ask-tolerance input output)
        :credit-limit (ask-credit-limit input output)))

(defun ask-approved (wm input output)
  "Cursos ya aprobados. Vacio es una respuesta legitima: es el estudiante
   de primer ingreso."
  (format output "~%1. Cursos que ya aprobaste~%")
  (format output "   Escribi los codigos separados por espacios (ej: SC-115 SC-202).~%")
  (format output "   ENTER si no aprobaste ninguno todavia.~%")
  (let ((known (domain:catalog-course-ids wm)))
    (loop
      (let ((answer (ask input output "   > " :default nil)))
        (when (null answer)
          (return '()))
        (let* ((tokens (mapcar #'string-upcase (split-tokens answer)))
               (valid (remove-if-not (lambda (id) (member id known :test #'equal)) tokens))
               (unknown (remove-if (lambda (id) (member id known :test #'equal)) tokens)))
          (dolist (id unknown)
            (format output "   Aviso: ~a no esta en el catalogo; lo ignoro.~%" id))
          (return valid))))))

(defun ask-target-area (wm input output)
  "Area profesional objetivo. Exactamente una (entities.md)."
  (let ((areas (domain:catalog-areas wm)))
    (format output "~%3. Tu area profesional objetivo~%")
    (or (ask-choice input output "   Elegi una > " areas :default (first areas))
        (first areas))))

(defun ask-interests (wm input output)
  "Areas que le interesan. Puede declarar varias, o ninguna."
  (let ((areas (domain:catalog-areas wm)))
    (format output "~%2. Areas que te interesan~%")
    (format output "   Podes elegir varias, separadas por espacios.~%")
    (or (ask-choice input output "   > " areas :multiple t :default '()) '())))

(defun ask-available (wm input output)
  "Disponibilidad horaria. Se pregunta por dias y franjas por separado y se
   arma el producto: pedir uno por uno los treinta bloques posibles seria
   insufrible y nadie lo contestaria bien."
  (let ((days (domain:catalog-days wm))
        (slots (domain:catalog-slots wm)))
    (format output "~%4. Cuando podes llevar clases~%")
    (format output "   Primero los dias (varios, separados por espacios; ENTER = todos):~%")
    (let* ((chosen-days (or (ask-choice input output "   > " days :multiple t :default days)
                            days)))
      (format output "   Ahora las franjas (varias; ENTER = todas):~%")
      (let ((chosen-slots (or (ask-choice input output "   > " slots :multiple t :default slots)
                              slots)))
        (loop for day in chosen-days
              nconc (loop for slot in chosen-slots collect (list day slot)))))))

(defun ask-tolerance (input output)
  (format output "~%5. Cuanta dificultad tolerar este cuatrimestre~%")
  (format output "   1 = muy liviano, 5 = muy exigente. Por omision 3.~%")
  (or (ask-integer input output "   > " :min 1 :max 5 :default 3) 3))

(defun ask-credit-limit (input output)
  (format output "~%6. Cuantos creditos como maximo~%")
  (format output "   Cada curso del catalogo vale 4. Por omision 12.~%")
  (or (ask-integer input output "   > " :min 1 :max 60 :default 12) 12))

;;; --- Consulta de explicaciones --------------------------------------------

(defun explain-loop (session input output)
  "Deja pedir la explicacion de un curso por codigo, tantas veces como
   quiera, hasta ENTER o fin de entrada. Responde tanto por los cursos
   recomendados como por los descartados: saber por que NO salio un curso
   suele importar mas que saber por que salio."
  (format output "~%CONSULTAR UN CURSO~%~%")
  (format output "Escribi un codigo para ver por que salio o por que no.~%")
  (loop
    (let ((answer (ask input output "ENTER para terminar > " :default nil)))
      (when (null answer)
        (format output "~%Listo.~%")
        (return))
      (print-course-explanation session (string-upcase answer) output))))
