;;;; src/cli/session.lisp
;;;;
;;;; Flujo de la sesion: carga el catalogo y un perfil, corre el motor a
;;;; traves del dominio y presenta el informe. Para esta primera version
;;;; el perfil es el de prueba de data/profiles/ (ver README, seccion de
;;;; limitaciones): la captura interactiva por consola queda para una
;;;; siguiente entrega.

(in-package #:expert-system.cli)

(defparameter *default-catalog-path* "data/courses.lisp")
(defparameter *default-profile-path* "data/profiles/sample-profile.lisp")

(defun start (&key (catalog-path *default-catalog-path*)
                    (profile-path *default-profile-path*)
                    (stream *standard-output*))
  "Corre una sesion completa: carga CATALOG-PATH y PROFILE-PATH, dispara
   el motor de inferencia y escribe el informe en STREAM. Si los datos son
   invalidos, lo reporta en STREAM en vez de abortar con una traza cruda."
  (handler-case
      (print-report (domain:run-session catalog-path profile-path) stream)
    (domain:data-error (e)
      (format stream "~%No se pudo cargar los datos del sistema:~%  ~a~%" e))))
