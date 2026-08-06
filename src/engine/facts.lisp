;;;; src/engine/facts.lisp
;;;;
;;;; Memoria de trabajo: la coleccion de hechos que el motor conoce en un
;;;; momento dado (ADR-006). Este archivo no sabe nada de cursos ni de
;;;; estudiantes: un hecho es simplemente una lista, p. ej. (color rojo).

(in-package #:expert-system.engine)

;;; Un hecho es una lista plana con un simbolo de relacion al frente,
;;; p. ej. (approved "CI-1201"). Aqui lo envolvemos en una estructura para
;;; llevar un identificador de insercion monotono: sirve para la recencia
;;; en la resolucion de conflictos (ADR-005) y para la traza.
(defstruct fact
  (id 0 :type integer)
  (content nil :type list))

;;; La memoria de trabajo guarda los hechos y el contador que asigna el
;;; siguiente identificador. Es el unico lugar donde vive el estado de una
;;; sesion de inferencia: no hay una memoria de trabajo global (ver
;;; docs/context/system_patterns.md), cada sesion o cada prueba crea la
;;; suya con MAKE-WORKING-MEMORY.
(defstruct working-memory
  (facts nil :type list)
  (next-id 0 :type integer)
  (trace nil :type list))

(defun assert-fact (fact-content wm)
  "Afirma FACT-CONTENT (una lista, p. ej. '(approved \"CI-1201\")) en WM.
   Si el hecho ya existe no hace nada y retorna NIL. Si es nuevo, lo agrega
   con un id de insercion mayor que todos los anteriores y retorna el FACT
   creado."
  (unless (fact-present-p fact-content wm)
    (let ((new-fact (make-fact :id (working-memory-next-id wm)
                                :content fact-content)))
      (push new-fact (working-memory-facts wm))
      (incf (working-memory-next-id wm))
      new-fact)))

(defun fact-present-p (fact-content wm)
  "Retorna T si FACT-CONTENT ya esta afirmado en WM."
  (some (lambda (f) (equal (fact-content f) fact-content))
        (working-memory-facts wm)))

(defun query-facts (wm relation)
  "Retorna el contenido (listas planas, no estructuras FACT) de todos los
   hechos de WM cuya relacion (primer elemento) es RELATION."
  (mapcar #'fact-content
          (remove-if-not (lambda (f) (eq (first (fact-content f)) relation))
                          (working-memory-facts wm))))
