;;;; Vuelca las reglas del sistema en ejecucion, para generar documentacion
;;;; a partir del codigo real y no de una transcripcion a mano.

(require :asdf)

(let ((root (make-pathname :directory (pathname-directory *load-truename*))))
  (declare (ignore root))
  (push (truename ".") asdf:*central-registry*)
  (asdf:load-system :expert-system))

(with-open-file (out "rules-dump.sexp" :direction :output :if-exists :supersede)
  (let ((*print-case* :downcase)
        (*print-right-margin* 70))
    (format out "(~%")
    (dolist (r (sort (copy-list engine:*rules*) #'<
                     :key (lambda (x) (funcall (intern "RULE-DECLARATION-ORDER" :expert-system.engine) x))))
      (format out " (:name ~s~%  :priority ~a~%  :doc ~s~%  :when ~s~%  :then ~s)~%"
              (string-downcase (symbol-name (engine:rule-name r)))
              (funcall (intern "RULE-PRIORITY" :expert-system.engine) r)
              (substitute #\Space #\Newline
                          (funcall (intern "RULE-DOCSTRING" :expert-system.engine) r))
              (funcall (intern "RULE-WHEN-CONDITIONS" :expert-system.engine) r)
              (funcall (intern "RULE-THEN-TEMPLATES" :expert-system.engine) r)))
    (format out ")~%")))

(format t "~&Reglas volcadas: ~a~%" (length engine:*rules*))
