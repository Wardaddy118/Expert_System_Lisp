;;;; src/package.lisp
;;;;
;;;; Todos los paquetes del proyecto se definen aqui, nunca dispersos
;;;; (.ace/standards/lisp.md). Cada capa tiene su propio paquete y expone
;;;; solo lo que las capas de arriba necesitan usar.

;;; MOTOR: generico, no sabe que es un curso. Ver docs/adr/ADR-005.
(defpackage #:expert-system.engine
  (:use #:common-lisp)
  (:nicknames #:engine)
  (:export #:make-working-memory
           #:assert-fact
           #:fact-present-p
           #:query-facts
           #:defrule
           #:*rules*
           #:rule-name
           #:run
           #:trace-entries
           #:trace-entry-cycle
           #:trace-entry-rule-name
           #:trace-entry-bindings
           #:trace-entry-matched-facts
           #:trace-entry-asserted-facts
           #:max-cycles-exceeded
           ;; Vocabulario cerrado de pruebas estructurales que una regla
           ;; puede usar en :when, ademas de NOT (que ya viene de
           ;; common-lisp). Un defrule escrito en otro paquete debe
           ;; referirse a ellos con prefijo (engine:at-most ?d ?t): son
           ;; simbolos concretos del paquete engine, no texto magico, y la
           ;; identidad del simbolo importa para que el motor los reconozca.
           #:distinct
           #:precedes
           #:at-most
           #:at-least
           #:exceeds-by-one
           #:at-least-below))

;;; DOMINIO: conocimiento academico. Usa engine: con prefijo explicito.
(defpackage #:expert-system.domain
  (:use #:common-lisp)
  (:nicknames #:domain)
  (:export #:data-error
           #:data-error-file
           #:data-error-message
           #:circular-prerequisites
           #:load-catalog
           #:load-profile
           #:assert-profile
           #:run-session-with-profile
           #:infer-session
           #:catalog-course-ids
           #:catalog-areas
           #:catalog-days
           #:catalog-slots
           #:course-name-for
           #:profile-approved
           #:profile-interests
           #:profile-target-area
           #:profile-available
           #:profile-difficulty-tolerance
           #:profile-credit-limit
           #:run-session
           #:recommendation-course-id
           #:recommendation-course-name
           #:recommendation-credits
           #:recommendation-difficulty
           #:recommendation-score
           #:recommendation-reasons
           #:recommendation-warnings
           #:excluded-course-id
           #:excluded-course-name
           #:excluded-reason
           #:session-recommendations
           #:session-excluded
           #:session-working-memory
           #:statistics
           #:stats-evaluated
           #:stats-approved
           #:stats-blocked-by-prerequisites
           #:stats-schedule-incompatible
           #:stats-too-difficult
           #:stats-eligible
           #:stats-average-difficulty
           #:stats-recommended-credits
           #:catalog-statistics
           #:catalog-stats-profiles-analyzed
           #:catalog-stats-most-recommended
           #:catalog-stats-bottlenecks
           #:catalog-stats-difficulty-by-area
           #:catalog-stats-rules-total
           #:catalog-stats-rules-fired
           #:catalog-stats-rules-never-fired))

;;; CLI: unica capa con E/S de usuario. Usa domain: con prefijo explicito.
(defpackage #:expert-system.cli
  (:use #:common-lisp)
  (:nicknames #:cli)
  (:export #:start
           #:start-interactive))
