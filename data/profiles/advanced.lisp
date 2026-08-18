;;;; data/profiles/advanced.lisp
;;;;
;;;; Caso: estudiante AVANZADO, con los primeros cinco cuatrimestres
;;;; practicamente completos.
;;;;
;;;; Que ejercita, ademas del avance alto: las dos reglas de formacion
;;;; general (PRIORITY-GENERAL-EDUCATION y RECOMMENDED-VIA-GENERAL-EDUCATION),
;;;; que nunca disparaban con el perfil de demostracion original.
;;;;
;;;; La causa no eran las reglas sino los datos: los tres cursos de
;;;; formacion general del catalogo (SC-103, AN-100, SC-270) estan
;;;; asignados a bloques NOCTURNOS, y aquel perfil excluia la noche a
;;;; proposito para ejercitar el choque de horario. Este perfil si
;;;; declara disponibilidad nocturna, y con eso las reglas se activan.
;;;; Ver decision D-09 en docs/context/PROJECT_CONTEXT.md.
;;;;
;;;; Todos los campos son PROVISIONALES para la demostracion.

(:approved ("SC-115" "SC-103" "SC-315" "II-115"
            "SC-202" "SC-203" "SC-204" "II-215N"
            "SC-304" "SC-305" "AN-100"
            "SC-402" "SC-403" "SC-404")
 :interests (software-engineering general-education databases)
 :target-area software-engineering
 :available ((monday morning) (monday afternoon) (monday evening)
             (tuesday morning) (tuesday afternoon) (tuesday evening)
             (wednesday morning) (wednesday afternoon) (wednesday evening)
             (thursday morning) (thursday afternoon) (thursday evening)
             (friday morning) (friday afternoon) (friday evening))
 :difficulty-tolerance 5
 :credit-limit 16)
