;;;; expert-system.asd
;;;;
;;;; Definicion ASDF del Sistema Experto de Recomendaciones Academicas.
;;;; Declara dos sistemas (ADR-004):
;;;;
;;;;   expert-system        El motor y el dominio. Sin dependencias externas.
;;;;   expert-system/tests  Las pruebas. Unico componente que depende de FiveAM.
;;;;
;;;; El orden de :components es el orden de carga: primero los paquetes,
;;;; luego el motor generico (engine/), luego el dominio academico que usa
;;;; el motor (domain/), y por ultimo la CLI que usa el dominio (cli/).

(asdf:defsystem #:expert-system
  :description "Sistema experto de recomendaciones academicas en Common Lisp"
  :author "Proyecto CheckPoint"
  :license "MIT"
  :depends-on ()
  :pathname "src/"
  :serial t
  :components ((:file "package")
                (:module "engine"
                 :serial t
                 :components ((:file "facts")
                              (:file "matching")
                              (:file "rules")
                              (:file "agenda")
                              (:file "inference")))
                (:module "domain"
                 :serial t
                 :components ((:file "loader")
                              (:file "knowledge")
                              (:file "explain")
                              (:file "stats")))
                (:module "cli"
                 :serial t
                 :components ((:file "format")
                              (:file "session")))
                (:file "main")))

(asdf:defsystem #:expert-system/tests
  :description "Suite de pruebas del sistema experto"
  :depends-on (#:expert-system #:fiveam)
  :pathname "tests/"
  :serial t
  :components ((:file "package")
                (:module "engine"
                 :serial t
                 :components ((:file "facts-tests")
                              (:file "matching-tests")
                              (:file "rules-tests")
                              (:file "agenda-tests")
                              (:file "inference-tests")))
                (:module "domain"
                 :serial t
                 :components ((:file "loader-tests")
                              (:file "knowledge-tests")
                              (:file "explain-tests")
                              (:file "stats-tests")))
                (:file "test-runner"))
  :perform (asdf:test-op (op system)
             (uiop:symbol-call :expert-system.tests :run-project-tests)))
