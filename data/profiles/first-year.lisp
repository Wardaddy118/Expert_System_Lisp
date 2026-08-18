;;;; data/profiles/first-year.lisp
;;;;
;;;; Caso: estudiante de PRIMER INGRESO. No ha aprobado nada.
;;;;
;;;; Que ejercita: el caso borde del PRD "estudiante sin aprobados". Solo
;;;; deberian salir elegibles los cursos sin prerrequisitos; todo lo que
;;;; dependa de algo queda descartado por MISSING-PREREQUISITES.
;;;;
;;;; Todos los campos son PROVISIONALES para la demostracion: la
;;;; universidad no suministra intereses, horario ni tolerancia por
;;;; estudiante.

(:approved ()
 :interests (software-engineering mathematics)
 :target-area software-engineering
 :available ((monday morning) (monday afternoon) (monday evening)
             (tuesday morning) (tuesday afternoon) (tuesday evening)
             (wednesday morning) (wednesday afternoon) (wednesday evening)
             (thursday morning) (thursday afternoon) (thursday evening)
             (friday morning) (friday afternoon) (friday evening))
 :difficulty-tolerance 3
 :credit-limit 12)
