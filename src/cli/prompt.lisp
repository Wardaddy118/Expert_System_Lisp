;;;; src/cli/prompt.lisp
;;;;
;;;; Primitivas de pregunta y respuesta por consola (T012, FR-050).
;;;;
;;;; Todas reciben los streams de entrada y salida explicitamente, nunca
;;;; *STANDARD-INPUT* por dentro. Esa es la razon de que la captura sea
;;;; probable sin E/S real: una prueba le pasa un WITH-INPUT-FROM-STRING y
;;;; verifica el perfil resultante, sin teclado y sin bloquearse.
;;;;
;;;; Fin de entrada (EOF) nunca es un error: se trata como "el usuario no
;;;; contesto" y se toma el valor por omision. Sin eso, correr la CLI con la
;;;; entrada redirigida colgaria o reventaria con una traza cruda.

(in-package #:expert-system.cli)

(defun ask (input output prompt &key (default nil))
  "Escribe PROMPT en OUTPUT y lee una linea de INPUT. Retorna la respuesta
   sin espacios sobrantes, o DEFAULT si viene vacia o si se acabo la
   entrada."
  (format output "~a" prompt)
  (force-output output)
  (let ((line (read-line input nil nil)))
    (if (null line)
        default
        (let ((trimmed (string-trim '(#\Space #\Tab #\Return) line)))
          (if (string= trimmed "") default trimmed)))))

(defun ask-integer (input output prompt &key (min 1) (max 99) (default nil))
  "Pide un entero entre MIN y MAX. Repregunta mientras la respuesta no sea
   valida; si se acaba la entrada, retorna DEFAULT."
  (loop
    (let ((answer (ask input output prompt :default nil)))
      (when (null answer)
        (return default))
      (let ((n (parse-integer answer :junk-allowed t)))
        (if (and n (<= min n max))
            (return n)
            (format output "  Escribi un numero entre ~a y ~a.~%" min max))))))

(defun ask-choice (input output prompt options &key (multiple nil) (default nil))
  "Muestra OPTIONS numeradas y pide una (o varias, si MULTIPLE) por numero.
   Retorna el elemento elegido, o la lista de elegidos si MULTIPLE."
  (loop for option in options
        for i from 1
        do (format output "    ~a) ~a~%" i (option-label option)))
  (loop
    (let ((answer (ask input output prompt :default nil)))
      (when (null answer)
        (return default))
      (let ((picked (remove nil (mapcar (lambda (token)
                                          (let ((n (parse-integer token :junk-allowed t)))
                                            (when (and n (<= 1 n (length options)))
                                              (nth (1- n) options))))
                                        (split-tokens answer)))))
        (cond ((null picked)
               (format output "  No entendi. Escribi el numero de la opcion.~%"))
              (multiple (return picked))
              (t (return (first picked))))))))

(defun option-label (option)
  "Etiqueta legible de una opcion: los simbolos se muestran en minuscula."
  (if (symbolp option) (string-downcase (symbol-name option)) (princ-to-string option)))

(defun split-tokens (text)
  "Parte TEXT en palabras, aceptando espacios y comas como separadores."
  (let ((tokens '())
        (current (make-string-output-stream)))
    (flet ((flush ()
             (let ((token (get-output-stream-string current)))
               (unless (string= token "") (push token tokens)))))
      (loop for char across text
            do (if (or (char= char #\Space) (char= char #\,) (char= char #\Tab))
                   (flush)
                   (write-char char current)))
      (flush))
    (nreverse tokens)))
