;;;; data/profiles/tight-schedule.lisp
;;;;
;;;; Caso: estudiante que TRABAJA y solo tiene dos bloques libres.
;;;;
;;;; Que ejercita: BR-003 a gran escala. Casi todo el catalogo queda
;;;; descartado por SCHEDULE-CONFLICT, lo que pone a prueba que el sistema
;;;; explique cual filtro elimino que (BR-021) en vez de devolver una lista
;;;; corta sin decir por que.
;;;;
;;;; Todos los campos son PROVISIONALES para la demostracion.

(:approved ("SC-115" "SC-103" "SC-315")
 :interests (software-engineering)
 :target-area software-engineering
 ;; Solo dos bloques en toda la semana.
 :available ((tuesday morning) (thursday morning))
 :difficulty-tolerance 4
 :credit-limit 12)
