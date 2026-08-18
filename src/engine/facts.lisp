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
  (trace nil :type list)
  ;; Indice de hechos por simbolo de relacion. Es una optimizacion pura:
  ;; contiene exactamente los mismos hechos que FACTS y en el mismo orden
  ;; (mas reciente primero), solo que particionados. Sin el, cada
  ;; ASSERT-FACT recorria los ~700 hechos de una sesion con EQUAL y cada
  ;; condicion de cada regla, en cada ciclo, volvia a escanear la lista
  ;; completa: la sesion tardaba mas de 3 s y NFR-001 pide menos de 2 s.
  (index (make-hash-table :test #'eq) :type hash-table))

(defun assert-fact (fact-content wm)
  "Afirma FACT-CONTENT (una lista, p. ej. '(approved \"CI-1201\")) en WM.
   Si el hecho ya existe no hace nada y retorna NIL. Si es nuevo, lo agrega
   con un id de insercion mayor que todos los anteriores y retorna el FACT
   creado."
  (unless (fact-present-p fact-content wm)
    (let ((new-fact (make-fact :id (working-memory-next-id wm)
                                :content fact-content)))
      (push new-fact (working-memory-facts wm))
      (push new-fact (gethash (first fact-content) (working-memory-index wm)))
      (incf (working-memory-next-id wm))
      new-fact)))

(defun fact-present-p (fact-content wm)
  "Retorna T si FACT-CONTENT ya esta afirmado en WM.

   Solo recorre los hechos de la misma relacion, no la memoria entera."
  (some (lambda (f) (equal (fact-content f) fact-content))
        (gethash (first fact-content) (working-memory-index wm))))

(defun facts-for-pattern (pattern wm)
  "Estructuras FACT candidatas a unificar con PATTERN: solo las de su misma
   relacion, tomadas del indice.

   El primer elemento de un patron es siempre un simbolo de relacion
   concreto (.ace/knowledge/entities.md), asi que un hecho de otra relacion
   no puede unificar jamas. Si algun dia un patron llevara variable en esa
   posicion, se recorre la memoria entera y el comportamiento no cambia.

   Sin este filtro, cada condicion probaba unificar contra los ~680 hechos
   de la sesion, cuando los de su relacion son unas decenas."
  (let ((head (first pattern)))
    (if (and head (symbolp head) (char/= #\? (char (symbol-name head) 0)))
        (gethash head (working-memory-index wm))
        (working-memory-facts wm))))

(defun query-facts (wm relation)
  "Retorna el contenido (listas planas, no estructuras FACT) de todos los
   hechos de WM cuya relacion (primer elemento) es RELATION.

   El orden es el mismo que daria recorrer WORKING-MEMORY-FACTS filtrando:
   el mas recientemente afirmado primero. Ese orden importa, porque la
   resolucion de conflictos desempata por recencia (ADR-005)."
  (mapcar #'fact-content (gethash relation (working-memory-index wm))))
