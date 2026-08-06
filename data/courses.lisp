;;;; data/courses.lisp
;;;;
;;;; Catalogo de Bachillerato en Ingenieria en Sistemas de Computacion,
;;;; Universidad Fidelitas. Reemplaza el catalogo de 10 cursos de la
;;;; primera version.
;;;;
;;;; ============================================================
;;;;                  OFICIAL vs. PROVISIONAL
;;;; ============================================================
;;;; El programa academico suministrado por la universidad da, por curso:
;;;; codigo, nombre, cuatrimestre, si es electiva y si algunos cursos
;;;; tienen laboratorio. NO da: creditos, prerrequisitos, correquisitos,
;;;; dificultad, horarios, intereses ni area profesional por curso.
;;;;
;;;; Cada curso de abajo separa sus campos en dos bloques, marcados con un
;;;; comentario:
;;;;
;;;;   ;; -- OFICIAL -- ............ viene del programa de la universidad.
;;;;   ;; -- PROVISIONAL (demo) -- . inventado por el equipo para que el
;;;;                                 motor tenga con que trabajar. NO es
;;;;                                 informacion de la Universidad
;;;;                                 Fidelitas y no debe presentarse como
;;;;                                 tal en ningun informe.
;;;;
;;;; Detalle de los criterios provisionales usados (todos heuristicos, sin
;;;; respaldo oficial, documentados aqui para que sean auditables):
;;;;
;;;; - CREDITOS: valor uniforme de 4 para los 47 cursos. Es la opcion mas
;;;;   honesta cuando no hay dato real: no finge variacion que no existe.
;;;; - DIFICULTAD (1-5): formula por cuatrimestre (1-2 -> 2, 3-5 -> 3,
;;;;   6-8 -> 4) mas 1 si el curso tiene laboratorio (tope 5). Asume que
;;;;   cuatrimestres mas avanzados y los cursos con laboratorio piden mas
;;;;   esfuerzo. Es una aproximacion del equipo, no un dato medido.
;;;; - AREA PROFESIONAL: inferida por el equipo a partir del NOMBRE del
;;;;   curso (ver .ace/knowledge/glossary.md, seccion de areas
;;;;   provisionales). No es una clasificacion de la universidad.
;;;; - PRERREQUISITOS: el programa no declara ninguno. Se agregaron 6
;;;;   enlaces minimos, solo entre SC-115, SC-202, SC-315, SC-304, SC-402,
;;;;   SC-403 y SC-404, unicamente para que el motor tenga una cadena de
;;;;   elegibilidad y un cuello de botella que probar (BR-001, BR-006). No
;;;;   representan el plan real; todos los demas cursos quedan sin
;;;;   prerrequisito declarado.
;;;; - HORARIO: bloque unico por curso, asignado por rotacion
;;;;   (lunes..viernes x manana/tarde/noche) solo para que BR-003 tenga
;;;;   algo que evaluar. No es el horario real de ningun grupo.
;;;;
;;;; Lista de campos pendientes de validacion con la universidad:
;;;;   [ ] Creditos reales por curso
;;;;   [ ] Prerrequisitos y correquisitos oficiales
;;;;   [ ] Horario real por grupo y cuatrimestre
;;;;   [ ] Criterio oficial de dificultad (si existe)
;;;;   [ ] Area profesional oficial por curso (si la universidad la define)
;;;;   [ ] Confirmar el total de cursos: la nota del catalogo suministrado
;;;;       dice "38 regulares + 9 electivas = 47", pero los bloques
;;;;       electivos listados suman 12 opciones (4+4+4), no 9. Este
;;;;       archivo usa el conteo real de items listados: 35 regulares +
;;;;       12 electivas = 47. Hay que confirmar cual de los dos totales
;;;;       parciales es el correcto.
;;;;
;;;; Cuello de botella: con prerrequisitos NO oficiales, BR-006 no debe
;;;; presentarse como un cuello de botella real del plan de estudios.
;;;; SC-304 queda como cuello de botella de EJEMPLO (3 cursos de
;;;; demostracion dependen de el) solo para que la regla se pueda ver
;;;; disparar; no es una conclusion sobre el plan oficial.

(("II-115" :name "Introduccion al Calculo o Matematica Basica"
           ;; -- OFICIAL --
           :term 1 :laboratory nil :collegiate t :elective nil :elective-group nil
           ;; -- PROVISIONAL (demo) --
           :credits 4 :area mathematics :difficulty 2
           :prerequisites () :schedule ((monday morning)))

 ("SC-115" :name "Programacion Basica"
           ;; -- OFICIAL -- (nombre alternativo del programa: "Introduccion a la Programacion")
           :term 1 :laboratory nil :collegiate nil :elective nil :elective-group nil
           ;; -- PROVISIONAL (demo) --
           :credits 4 :area software-engineering :difficulty 2
           :prerequisites () :schedule ((tuesday afternoon)))

 ("SC-103" :name "Introduccion a la Informatica"
           ;; -- OFICIAL --
           :term 1 :laboratory nil :collegiate nil :elective nil :elective-group nil
           ;; -- PROVISIONAL (demo) --
           :credits 4 :area general-education :difficulty 2
           :prerequisites () :schedule ((wednesday evening)))

 ("SC-315" :name "Matematicas Discretas"
           ;; -- OFICIAL --
           :term 1 :laboratory nil :collegiate t :elective nil :elective-group nil
           ;; -- PROVISIONAL (demo) --
           :credits 4 :area mathematics :difficulty 2
           :prerequisites () :schedule ((thursday morning)))

 ("II-215N" :name "Calculo Diferencial e Integral I"
            ;; -- OFICIAL --
            :term 2 :laboratory nil :collegiate t :elective nil :elective-group nil
            ;; -- PROVISIONAL (demo) --
            :credits 4 :area mathematics :difficulty 2
            :prerequisites () :schedule ((friday afternoon)))

 ("SC-202" :name "Introduccion a la Programacion"
           ;; -- OFICIAL --
           :term 2 :laboratory t :collegiate nil :elective nil :elective-group nil
           ;; -- PROVISIONAL (demo) --
           :credits 4 :area software-engineering :difficulty 3
           :prerequisites ("SC-115") :schedule ((monday evening)))

 ("SC-203" :name "Fundamentos de Sistemas Operativos"
           ;; -- OFICIAL --
           :term 2 :laboratory t :collegiate nil :elective nil :elective-group nil
           ;; -- PROVISIONAL (demo) --
           :credits 4 :area infrastructure :difficulty 3
           :prerequisites () :schedule ((tuesday morning)))

 ("SC-204" :name "Principios de Redes y Comunicaciones"
           ;; -- OFICIAL --
           :term 2 :laboratory t :collegiate nil :elective nil :elective-group nil
           ;; -- PROVISIONAL (demo) --
           :credits 4 :area networks :difficulty 3
           :prerequisites () :schedule ((wednesday afternoon)))

 ("SC-205" :name "Electronica Digital y Microprocesadores"
           ;; -- OFICIAL --
           :term 2 :laboratory nil :collegiate nil :elective nil :elective-group nil
           ;; -- PROVISIONAL (demo) --
           :credits 4 :area infrastructure :difficulty 2
           :prerequisites () :schedule ((thursday evening)))

 ("EM-220" :name "Algebra Lineal"
           ;; -- OFICIAL --
           :term 3 :laboratory nil :collegiate t :elective nil :elective-group nil
           ;; -- PROVISIONAL (demo) --
           :credits 4 :area mathematics :difficulty 3
           :prerequisites () :schedule ((friday morning)))

 ("SC-302" :name "Documentacion del Software"
           ;; -- OFICIAL --
           :term 3 :laboratory nil :collegiate nil :elective nil :elective-group nil
           ;; -- PROVISIONAL (demo) --
           :credits 4 :area software-engineering :difficulty 3
           :prerequisites () :schedule ((monday afternoon)))

 ("SC-303" :name "Programacion Cliente/Servidor Concurrente"
           ;; -- OFICIAL --
           :term 3 :laboratory t :collegiate nil :elective nil :elective-group nil
           ;; -- PROVISIONAL (demo) --
           :credits 4 :area software-engineering :difficulty 4
           :prerequisites () :schedule ((tuesday evening)))

 ("SC-304" :name "Estructura de Datos"
           ;; -- OFICIAL --
           :term 3 :laboratory t :collegiate nil :elective nil :elective-group nil
           ;; -- PROVISIONAL (demo) -- cuello de botella de EJEMPLO, ver nota arriba
           :credits 4 :area software-engineering :difficulty 4
           :prerequisites ("SC-202" "SC-315") :schedule ((wednesday morning)))

 ("SC-305" :name "Diseno de Interfaz Grafica de Usuario"
           ;; -- OFICIAL --
           :term 3 :laboratory t :collegiate nil :elective nil :elective-group nil
           ;; -- PROVISIONAL (demo) --
           :credits 4 :area software-engineering :difficulty 4
           :prerequisites () :schedule ((thursday afternoon)))

 ("AN-100" :name "Metodologia de la Investigacion y Comunicacion"
           ;; -- OFICIAL --
           :term 4 :laboratory nil :collegiate nil :elective nil :elective-group nil
           ;; -- PROVISIONAL (demo) --
           :credits 4 :area general-education :difficulty 3
           :prerequisites () :schedule ((friday evening)))

 ("SC-402" :name "Fundamentos de Enrutamiento y Conmutacion"
           ;; -- OFICIAL --
           :term 4 :laboratory t :collegiate nil :elective nil :elective-group nil
           ;; -- PROVISIONAL (demo) -- depende de SC-304, ver nota de cuello de botella
           :credits 4 :area networks :difficulty 4
           :prerequisites ("SC-304") :schedule ((monday morning)))

 ("SC-403" :name "Desarrollo de Aplicaciones Web y Patrones"
           ;; -- OFICIAL --
           :term 4 :laboratory t :collegiate nil :elective nil :elective-group nil
           ;; -- PROVISIONAL (demo) -- depende de SC-304, ver nota de cuello de botella
           :credits 4 :area software-engineering :difficulty 4
           :prerequisites ("SC-304") :schedule ((tuesday afternoon)))

 ("SC-404" :name "Fundamentos de Diseno de Base de Datos Relacionales"
           ;; -- OFICIAL --
           :term 4 :laboratory t :collegiate nil :elective nil :elective-group nil
           ;; -- PROVISIONAL (demo) -- depende de SC-304, ver nota de cuello de botella
           :credits 4 :area databases :difficulty 4
           :prerequisites ("SC-304") :schedule ((wednesday evening)))

 ("SC-405" :name "Calidad del Software"
           ;; -- OFICIAL --
           :term 4 :laboratory nil :collegiate nil :elective nil :elective-group nil
           ;; -- PROVISIONAL (demo) --
           :credits 4 :area software-engineering :difficulty 3
           :prerequisites () :schedule ((thursday morning)))

 ("I-240" :name "Probabilidad y Estadistica Descriptiva"
          ;; -- OFICIAL --
          :term 5 :laboratory nil :collegiate nil :elective nil :elective-group nil
          ;; -- PROVISIONAL (demo) --
          :credits 4 :area mathematics :difficulty 3
          :prerequisites () :schedule ((friday afternoon)))

 ("SC-502" :name "Ambiente Web Cliente/Servidor"
           ;; -- OFICIAL --
           :term 5 :laboratory t :collegiate nil :elective nil :elective-group nil
           ;; -- PROVISIONAL (demo) --
           :credits 4 :area software-engineering :difficulty 4
           :prerequisites () :schedule ((monday evening)))

 ("SC-503" :name "Administracion de Base de Datos"
           ;; -- OFICIAL --
           :term 5 :laboratory t :collegiate nil :elective nil :elective-group nil
           ;; -- PROVISIONAL (demo) --
           :credits 4 :area databases :difficulty 4
           :prerequisites () :schedule ((tuesday morning)))

 ("SC-504" :name "Lenguajes de Base de Datos"
           ;; -- OFICIAL --
           :term 5 :laboratory t :collegiate nil :elective nil :elective-group nil
           ;; -- PROVISIONAL (demo) --
           :credits 4 :area databases :difficulty 4
           :prerequisites () :schedule ((wednesday afternoon)))

 ("SC-505" :name "Administracion de Proyecto"
           ;; -- OFICIAL --
           :term 5 :laboratory nil :collegiate nil :elective nil :elective-group nil
           ;; -- PROVISIONAL (demo) --
           :credits 4 :area management :difficulty 3
           :prerequisites () :schedule ((thursday evening)))

 ("SC-601" :name "Programacion Avanzada"
           ;; -- OFICIAL --
           :term 6 :laboratory t :collegiate nil :elective nil :elective-group nil
           ;; -- PROVISIONAL (demo) --
           :credits 4 :area software-engineering :difficulty 5
           :prerequisites () :schedule ((friday morning)))

 ("SC-602" :name "Data Warehouse y Base de Datos Multidimensionales"
           ;; -- OFICIAL --
           :term 6 :laboratory t :collegiate nil :elective nil :elective-group nil
           ;; -- PROVISIONAL (demo) --
           :credits 4 :area data :difficulty 5
           :prerequisites () :schedule ((monday afternoon)))

 ("SC-603" :name "Analisis y Modelado de Requerimientos"
           ;; -- OFICIAL --
           :term 6 :laboratory nil :collegiate nil :elective nil :elective-group nil
           ;; -- PROVISIONAL (demo) --
           :credits 4 :area software-engineering :difficulty 4
           :prerequisites () :schedule ((tuesday evening)))

 ("SC-604" :name "Gobernanza y Gestion de Tecnologias de Informacion y Comunicaciones"
           ;; -- OFICIAL --
           :term 6 :laboratory nil :collegiate nil :elective nil :elective-group nil
           ;; -- PROVISIONAL (demo) --
           :credits 4 :area management :difficulty 4
           :prerequisites () :schedule ((wednesday morning)))

 ("AN-125" :name "Contabilidad Basica"
           ;; -- OFICIAL -- electiva de sexto cuatrimestre
           :term 6 :laboratory nil :collegiate nil :elective t :elective-group sixth-term-elective
           ;; -- PROVISIONAL (demo) --
           :credits 4 :area management :difficulty 4
           :prerequisites () :schedule ((thursday afternoon)))

 ("SC-607" :name "Sistemas Operativos Avanzados"
           ;; -- OFICIAL -- electiva de sexto cuatrimestre
           :term 6 :laboratory nil :collegiate nil :elective t :elective-group sixth-term-elective
           ;; -- PROVISIONAL (demo) --
           :credits 4 :area infrastructure :difficulty 4
           :prerequisites () :schedule ((friday evening)))

 ("SC-620" :name "Estructura y Arquitectura de Videojuegos"
           ;; -- OFICIAL -- electiva de sexto cuatrimestre
           :term 6 :laboratory t :collegiate nil :elective t :elective-group sixth-term-elective
           ;; -- PROVISIONAL (demo) --
           :credits 4 :area software-engineering :difficulty 5
           :prerequisites () :schedule ((monday morning)))

 ("SC-609" :name "Base de Datos NoSQL"
           ;; -- OFICIAL -- electiva de sexto cuatrimestre
           :term 6 :laboratory t :collegiate nil :elective t :elective-group sixth-term-elective
           ;; -- PROVISIONAL (demo) --
           :credits 4 :area databases :difficulty 5
           :prerequisites () :schedule ((tuesday afternoon)))

 ("SC-701" :name "Programacion Avanzada en Web"
           ;; -- OFICIAL --
           :term 7 :laboratory t :collegiate nil :elective nil :elective-group nil
           ;; -- PROVISIONAL (demo) --
           :credits 4 :area software-engineering :difficulty 5
           :prerequisites () :schedule ((wednesday evening)))

 ("SC-702" :name "Diseno y Desarrollo de Sistemas"
           ;; -- OFICIAL --
           :term 7 :laboratory nil :collegiate nil :elective nil :elective-group nil
           ;; -- PROVISIONAL (demo) --
           :credits 4 :area software-engineering :difficulty 4
           :prerequisites () :schedule ((thursday morning)))

 ("SC-703" :name "Programacion para Dispositivos Moviles"
           ;; -- OFICIAL --
           :term 7 :laboratory t :collegiate nil :elective nil :elective-group nil
           ;; -- PROVISIONAL (demo) --
           :credits 4 :area software-engineering :difficulty 5
           :prerequisites () :schedule ((friday afternoon)))

 ("SC-704" :name "Auditoria de Sistemas"
           ;; -- OFICIAL --
           :term 7 :laboratory nil :collegiate nil :elective nil :elective-group nil
           ;; -- PROVISIONAL (demo) --
           :credits 4 :area cybersecurity :difficulty 4
           :prerequisites () :schedule ((monday evening)))

 ("AN-110" :name "Administracion General"
           ;; -- OFICIAL -- electiva de setimo cuatrimestre
           :term 7 :laboratory nil :collegiate nil :elective t :elective-group seventh-term-elective
           ;; -- PROVISIONAL (demo) --
           :credits 4 :area management :difficulty 4
           :prerequisites () :schedule ((tuesday morning)))

 ("SC-706" :name "Diseno de Videojuegos"
           ;; -- OFICIAL -- electiva de setimo cuatrimestre
           :term 7 :laboratory t :collegiate nil :elective t :elective-group seventh-term-elective
           ;; -- PROVISIONAL (demo) --
           :credits 4 :area software-engineering :difficulty 5
           :prerequisites () :schedule ((wednesday afternoon)))

 ("SC-707" :name "Big Data"
           ;; -- OFICIAL -- electiva de setimo cuatrimestre
           :term 7 :laboratory t :collegiate nil :elective t :elective-group seventh-term-elective
           ;; -- PROVISIONAL (demo) --
           :credits 4 :area data :difficulty 5
           :prerequisites () :schedule ((thursday evening)))

 ("SC-708" :name "Administracion de Servidores"
           ;; -- OFICIAL -- electiva de setimo cuatrimestre
           :term 7 :laboratory t :collegiate nil :elective t :elective-group seventh-term-elective
           ;; -- PROVISIONAL (demo) --
           :credits 4 :area infrastructure :difficulty 5
           :prerequisites () :schedule ((friday morning)))

 ("SC-250" :name "Paradigmas de Programacion"
           ;; -- OFICIAL --
           :term 8 :laboratory nil :collegiate nil :elective nil :elective-group nil
           ;; -- PROVISIONAL (demo) --
           :credits 4 :area software-engineering :difficulty 4
           :prerequisites () :schedule ((monday afternoon)))

 ("SC-270" :name "Computacion y Sociedad"
           ;; -- OFICIAL --
           :term 8 :laboratory nil :collegiate nil :elective nil :elective-group nil
           ;; -- PROVISIONAL (demo) --
           :credits 4 :area general-education :difficulty 4
           :prerequisites () :schedule ((tuesday evening)))

 ("SC-803" :name "Implantacion de Sistemas"
           ;; -- OFICIAL --
           :term 8 :laboratory nil :collegiate nil :elective nil :elective-group nil
           ;; -- PROVISIONAL (demo) --
           :credits 4 :area software-engineering :difficulty 4
           :prerequisites () :schedule ((wednesday morning)))

 ("AN-775" :name "Desarrollo de Emprendedores y Liderazgo Empresarial"
           ;; -- OFICIAL -- electiva de octavo cuatrimestre
           :term 8 :laboratory nil :collegiate nil :elective t :elective-group eighth-term-elective
           ;; -- PROVISIONAL (demo) --
           :credits 4 :area management :difficulty 4
           :prerequisites () :schedule ((thursday afternoon)))

 ("SC-805" :name "Inteligencia de Negocios"
           ;; -- OFICIAL -- electiva de octavo cuatrimestre
           :term 8 :laboratory t :collegiate nil :elective t :elective-group eighth-term-elective
           ;; -- PROVISIONAL (demo) --
           :credits 4 :area data :difficulty 5
           :prerequisites () :schedule ((friday evening)))

 ("SC-806" :name "Servidores de Colaboracion"
           ;; -- OFICIAL -- electiva de octavo cuatrimestre
           :term 8 :laboratory nil :collegiate nil :elective t :elective-group eighth-term-elective
           ;; -- PROVISIONAL (demo) --
           :credits 4 :area infrastructure :difficulty 4
           :prerequisites () :schedule ((monday morning)))

 ("SC-807" :name "Seguridad Informatica"
           ;; -- OFICIAL -- electiva de octavo cuatrimestre
           :term 8 :laboratory nil :collegiate nil :elective t :elective-group eighth-term-elective
           ;; -- PROVISIONAL (demo) --
           :credits 4 :area cybersecurity :difficulty 4
           :prerequisites () :schedule ((tuesday afternoon))))
