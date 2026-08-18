;;;; data/profiles/low-tolerance.lisp
;;;;
;;;; Caso: estudiante que declara TOLERANCIA BAJA a la dificultad, pero
;;;; que ya tiene aprobados los requisitos del cuello de botella.
;;;;
;;;; Que ejercita: la excepcion de BR-005, implementada por la regla
;;;; BOTTLENECK-EXCEPTION-TO-TOLERANCE, que nunca disparaba antes.
;;;;
;;;; Como se consigue: SC-304 (Estructura de Datos) tiene dificultad 4 y es
;;;; el cuello de botella del catalogo (es requisito de SC-402, SC-403 y
;;;; SC-404). Con tolerancia 3, su dificultad excede la tolerancia por
;;;; EXACTAMENTE un nivel, que es la condicion de la excepcion. Sus
;;;; requisitos (SC-202 y SC-315) estan aprobados y su bloque
;;;; (miercoles manana) esta disponible, asi que llega a ser elegible.
;;;;
;;;; El resultado esperado es que SC-304 se recomiende IGUAL, marcado con
;;;; advertencia: atrasar un cuello de botella cuesta mas que llevarlo.
;;;; Ver decision D-08 en docs/context/PROJECT_CONTEXT.md.
;;;;
;;;; Todos los campos son PROVISIONALES para la demostracion.

(:approved ("SC-115" "SC-315" "SC-202")
 :interests (mathematics)
 :target-area software-engineering
 :available ((monday morning) (monday afternoon)
             (tuesday morning) (tuesday afternoon)
             (wednesday morning) (wednesday afternoon)
             (thursday morning) (thursday afternoon)
             (friday morning) (friday afternoon))
 :difficulty-tolerance 3
 :credit-limit 12)
