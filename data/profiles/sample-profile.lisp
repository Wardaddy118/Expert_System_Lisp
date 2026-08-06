;;;; data/profiles/sample-profile.lisp
;;;;
;;;; Perfil de estudiante de prueba para la demostracion (FR-051), con
;;;; codigos reales del catalogo de Bachillerato en Ingenieria en
;;;; Sistemas de Computacion (Fidelitas, data/courses.lisp). Un
;;;; estudiante que ya curso el primer cuatrimestre completo mas
;;;; Introduccion a la Programacion (SC-202, segundo cuatrimestre), y
;;;; busca orientacion hacia ingenieria de software con interes amplio
;;;; (varias areas), para que la demostracion ejercite las seis razones
;;;; de descarte a la vez -- incluida la nueva ELECTIVE-GROUP-LIMIT, que
;;;; solo se activa cuando dos electivas del mismo bloque compiten.
;;;;
;;;; Todos los campos de este archivo son PROVISIONALES para la
;;;; demostracion (intereses, area objetivo, horario disponible,
;;;; tolerancia y tope de creditos no son datos que la universidad
;;;; suministre por estudiante). Formato: una unica property list, leida
;;;; con READ y normalizada a hechos de perfil por domain/loader.lisp.

(:approved ("II-115" "SC-115" "SC-103" "SC-315" "SC-202")
 :interests (software-engineering databases management infrastructure)
 :target-area software-engineering
 ;; Sin bloques de "evening": deja a los cursos nocturnos como ejemplo de
 ;; choque de horario (BR-003) sobre el horario de demostracion.
 :available ((monday morning) (monday afternoon)
             (tuesday morning) (tuesday afternoon)
             (wednesday morning) (wednesday afternoon)
             (thursday morning) (thursday afternoon)
             (friday morning) (friday afternoon))
 :difficulty-tolerance 4
 :credit-limit 8)
