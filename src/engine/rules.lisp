;;;; src/engine/rules.lisp
;;;;
;;;; Una regla es una estructura de datos, no codigo (ADR-005). La macro
;;;; DEFRULE solo construye esa estructura y la registra; el motor
;;;; (agenda.lisp, inference.lisp) es quien decide cuando dispararla.

(in-package #:expert-system.engine)

(defstruct rule
  (name nil :type symbol)
  (docstring "" :type string)
  (priority 0 :type integer)
  (declaration-order 0 :type integer)
  (when-conditions nil :type list)
  (then-templates nil :type list))

(defvar *rules* nil
  "Lista de todas las reglas registradas con DEFRULE. Es uno de los dos
   unicos estados globales mutables del motor (junto con la memoria de
   trabajo, que nunca es global: cada sesion crea la suya). Las pruebas
   pueden aislarla con (let ((*rules* nil)) ...).")

(defvar *rule-declaration-counter* 0
  "Contador interno para el criterio de desempate 'orden de declaracion'
   de la resolucion de conflictos (ADR-005).")

(defmacro defrule (name &rest args)
  "Declara una regla llamada NAME. La forma completa es:

     (defrule name \"docstring\" :priority n :when (...) :then (...))

   El DOCSTRING es opcional (las reglas del dominio academico SI deben
   traerlo, citando el BR que implementan -- .ace/standards/lisp.md; las
   pruebas pueden omitirlo). WHEN es una lista de condiciones; THEN es una
   lista de plantillas de hechos a afirmar cuando la regla dispara. Si ya
   existia una regla con el mismo NAME, la reemplaza (recargar un archivo
   no duplica reglas)."
  (let* ((docstring (if (stringp (first args)) (first args) ""))
         (options (if (stringp (first args)) (rest args) args)))
    (destructuring-bind (&key (priority 0) (when nil) (then nil)) options
      `(progn
         (setf *rules* (remove ',name *rules* :key #'rule-name))
         (push (make-rule :name ',name
                           :docstring ,docstring
                           :priority ,priority
                           :declaration-order (incf *rule-declaration-counter*)
                           :when-conditions ',when
                           :then-templates ',then)
               *rules*)
         ',name))))
