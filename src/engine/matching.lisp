;;;; src/engine/matching.lisp
;;;;
;;;; Unificacion de patrones con variables (ADR-005). Es la pieza mas
;;;; delicada del motor: convierte una condicion de una regla (:when) en
;;;; cero, uno o varios conjuntos de ligaduras (bindings), comparando el
;;;; patron contra los hechos de la memoria de trabajo.
;;;;
;;;; Este archivo no conoce cursos ni estudiantes. Solo listas, simbolos
;;;; que empiezan con ? y numeros.

(in-package #:expert-system.engine)

(defun variable-p (x)
  "Retorna T si X es una variable de patron: un simbolo que empieza con ?."
  (and (symbolp x)
       (> (length (symbol-name x)) 0)
       (char= (char (symbol-name x) 0) #\?)))

;;; --- Unificacion de un patron contra un hecho -----------------------

(defun unify-pattern (pattern content bindings)
  "Compara PATTERN (p. ej. (course ?id)) contra CONTENT (p. ej.
   (course \"CI-2400\")), extendiendo BINDINGS (una alist ?var -> valor).
   Retorna (values bindings-nuevos t) si unifica, o (values nil nil) si
   falla. Una variable se liga la primera vez que aparece y debe coincidir
   con el mismo valor despues."
  (cond
    ;; Aridad distinta: no puede unificar.
    ((/= (length pattern) (length content))
     (values nil nil))
    ;; Ambos vacios: exito, sin cambios en las ligaduras.
    ((null pattern)
     (values bindings t))
    ;; El primer elemento es variable.
    ((variable-p (first pattern))
     (multiple-value-bind (value found-p) (binding-value (first pattern) bindings)
       (if found-p
           ;; Ya ligada antes: debe coincidir con este valor tambien.
           (if (equal value (first content))
               (unify-pattern (rest pattern) (rest content) bindings)
               (values nil nil))
           ;; Primera aparicion: se liga al valor actual.
           (unify-pattern (rest pattern) (rest content)
                          (cons (cons (first pattern) (first content)) bindings)))))
    ;; El primer elemento es literal: debe coincidir exactamente.
    ((equal (first pattern) (first content))
     (unify-pattern (rest pattern) (rest content) bindings))
    (t (values nil nil))))

(defun binding-value (var bindings)
  "Retorna (values valor t) si VAR esta ligada en BINDINGS, o (values nil nil)
   si no lo esta."
  (let ((pair (assoc var bindings)))
    (if pair
        (values (cdr pair) t)
        (values nil nil))))

;;; --- Conjuntos de ligaduras a lo largo de una lista de condiciones ---
;;;
;;; Una regla tiene varias condiciones en :when. Cada una se evalua contra
;;; la memoria de trabajo y contra las ligaduras que dejaron las
;;; condiciones anteriores. El resultado de toda la lista es un conjunto
;;; de "binding-set": una posible combinacion de ligaduras junto con los
;;; hechos que la activaron (para la recencia y la traza).

(defstruct binding-set
  (vars nil :type list)   ; alist ?var -> valor
  (facts nil :type list)) ; hechos (struct FACT) que activaron esta instanciacion

(defun match-conditions (conditions wm)
  "Evalua la lista CONDITIONS (el :when de una regla) contra WM. Retorna la
   lista de BINDING-SET que satisfacen todas las condiciones, en cualquier
   orden. Una lista vacia significa que la regla no tiene instanciaciones
   en este ciclo."
  (let ((binding-sets (list (make-binding-set))))
    (dolist (condition conditions binding-sets)
      (setf binding-sets (match-one-condition condition wm binding-sets)))))

(defun match-one-condition (condition wm binding-sets)
  "Extiende cada BINDING-SET de BINDING-SETS con CONDITION. CONDITION puede
   ser un patron positivo, una negacion (not patron), o una prueba
   estructural (distinct, precedes, at-most, at-least, exceeds-by-one)."
  (cond
    ((eq (first condition) 'not)
     (match-negative-condition (second condition) wm binding-sets))
    ((structural-test-p (first condition))
     (match-structural-test condition binding-sets))
    (t
     (match-positive-condition condition wm binding-sets))))

(defun match-positive-condition (pattern wm binding-sets)
  "Une PATTERN contra cada hecho de WM, para cada binding-set de entrada.
   Cada union exitosa produce un binding-set nuevo con el hecho agregado."
  (let ((result nil))
    (dolist (bs binding-sets result)
      (dolist (f (facts-for-pattern pattern wm))
        (multiple-value-bind (new-vars matched-p)
            (unify-pattern pattern (fact-content f) (binding-set-vars bs))
          (when matched-p
            (push (make-binding-set :vars new-vars
                                     :facts (cons f (binding-set-facts bs)))
                  result)))))))

(defun match-negative-condition (pattern wm binding-sets)
  "Descarta los binding-set para los que existe algun hecho que unifica con
   PATTERN (negacion por fallo: 'no existe un hecho que cumpla esto')."
  (remove-if
   (lambda (bs)
     (some (lambda (f)
             (nth-value 1 (unify-pattern pattern (fact-content f) (binding-set-vars bs))))
           (facts-for-pattern pattern wm)))
   binding-sets))

;;; --- Pruebas estructurales -------------------------------------------
;;;
;;; Un pequeno vocabulario fijo de comparaciones entre variables ya
;;; ligadas. No son "funciones Lisp arbitrarias": son parte del lenguaje
;;; de condiciones del motor, igual que NOT, y son genericas (no saben que
;;; es un curso).

(defparameter *structural-tests*
  (list (cons 'distinct (lambda (a b) (not (equal a b))))
        (cons 'precedes (lambda (a b) (string< a b)))
        (cons 'at-most (lambda (a b) (<= a b)))
        (cons 'at-least (lambda (a b) (>= a b)))
        (cons 'exceeds-by-one (lambda (a b) (= a (1+ b))))
        (cons 'at-least-below (lambda (mayor menor margen) (>= (- mayor menor) margen))))
  "Alista simbolo -> funcion de los argumentos ya resueltos, usada por las
   condiciones estructurales de una regla. No son \"funciones Lisp
   arbitrarias\" en el sentido prohibido por el estandar: son un
   vocabulario cerrado y generico, igual que NOT, que el motor interpreta
   el mismo sin importar el dominio.")

(defun structural-test-p (symbol)
  (and (assoc symbol *structural-tests*) t))

(defun resolve-argument (arg bindings)
  "Si ARG es una variable, retorna su valor en BINDINGS (error si no esta
   ligada). Si no, ARG es un literal (p. ej. un numero) y se retorna tal
   cual."
  (if (variable-p arg)
      (multiple-value-bind (value found-p) (binding-value arg bindings)
        (unless found-p
          (error "La variable ~a debe estar ligada antes de usarse en una prueba." arg))
        value)
      arg))

(defun match-structural-test (condition binding-sets)
  "CONDITION es (nombre-prueba arg1 arg2 ...), donde cada argumento es una
   variable ya ligada o un literal. Conserva los binding-set donde la
   prueba, aplicada a los valores resueltos, es verdadera."
  (let ((test-fn (cdr (assoc (first condition) *structural-tests*)))
        (args (rest condition)))
    (remove-if-not
     (lambda (bs)
       (apply test-fn (mapcar (lambda (a) (resolve-argument a (binding-set-vars bs))) args)))
     binding-sets)))

;;; --- Sustitucion de variables en las plantillas de :then --------------

(defun instantiate-template (template bindings)
  "Sustituye en TEMPLATE (una lista, p. ej. (priority ?id 10)) cada
   variable por su valor en BINDINGS, y cada simbolo que nombre un
   parametro configurable (definido con DEFPARAMETER/DEFCONSTANT) por su
   valor actual. Los demas elementos quedan igual."
  (mapcar (lambda (element)
            (cond
              ((variable-p element)
               (multiple-value-bind (value found-p) (binding-value element bindings)
                 (unless found-p
                   (error "La variable ~a no esta ligada en :then." element))
                 value))
              ((and (symbolp element) (boundp element))
               (symbol-value element))
              (t element)))
          template))

(defun max-fact-id (facts)
  "Retorna el id de insercion mas alto entre FACTS, o -1 si la lista esta
   vacia (una instanciacion sin hechos activadores, poco comun pero valida)."
  (if facts
      (reduce #'max facts :key #'fact-id)
      -1))
