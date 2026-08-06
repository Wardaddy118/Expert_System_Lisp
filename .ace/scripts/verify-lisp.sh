#!/bin/bash
#
# verify-lisp.sh - Gate de verificacion Common Lisp de este proyecto.
#
# Lo invoca .ace/scripts/verify.sh a traves de verify.test_cmd en .aceconfig.
# Debe salir distinto de cero ante cualquier fallo, y tambien cuando no hay
# nada que verificar: un gate vacio que reporta exito es exactamente el modo
# de fallo que prohibe el estandar de Harness Engineering.
#
# POR QUE ESTE GATE DELEGA EN ASDF
#
# La primera version compilaba cada archivo .lisp por separado, en un proceso
# SBCL nuevo por archivo. Eso solo funciona con archivos que definen su propio
# paquete. En codigo real todo archivo empieza con
# (in-package :expert-system.engine), y ese paquete se define en
# src/package.lisp, que no esta cargado en un proceso nuevo. Resultado: fallaba
# TODO el codigo real, ademas de intentar compilar data/*.lisp (que son datos,
# no codigo) y el propio .asd.
#
# El gate correcto delega en ASDF, que compila en orden de dependencias, y en
# la suite, que ademas verifica comportamiento y no solo compilabilidad.

set -u

LISP="${LISP:-sbcl}"

if ! command -v "$LISP" >/dev/null 2>&1; then
    echo "[!] $LISP no esta en el PATH. Instala SBCL o define LISP=<implementacion>."
    exit 1
fi

if [ ! -f "expert-system.asd" ]; then
    echo "[!] No existe expert-system.asd: no hay sistema que verificar."
    echo "    Este gate falla en vez de aprobar el silencio. Crea el sistema"
    echo "    (tarea T001) o reapunta verify.test_cmd en .aceconfig."
    exit 1
fi

# run-tests.lisp carga :expert-system/tests, que depende de :expert-system.
# Una sola invocacion compila todo src/ en orden de dependencias y despues
# corre la suite completa.
if [ -f "run-tests.lisp" ]; then
    echo "[*] Compilando el sistema y corriendo la suite (ASDF + FiveAM)..."
    if "$LISP" --script run-tests.lisp; then
        echo "[ok] El sistema compila y la suite pasa."
        exit 0
    fi
    echo "[!] Fallo la compilacion del sistema o alguna prueba."
    exit 1
fi

# Sin suite todavia: al menos se comprueba que el sistema cargue completo.
echo "[*] No hay run-tests.lisp. Se verifica solo que el sistema cargue."
if "$LISP" --non-interactive --no-userinit \
     --eval '(require :asdf)' \
     --eval '(push (truename ".") asdf:*central-registry*)' \
     --eval '(asdf:load-system :expert-system)' >/dev/null 2>&1; then
    echo "[ok] El sistema carga y compila."
    echo "[!] Aviso: sin suite de pruebas este gate solo cubre compilacion."
    exit 0
fi

echo "[!] El sistema no carga. Detalle:"
"$LISP" --non-interactive --no-userinit \
     --eval '(require :asdf)' \
     --eval '(push (truename ".") asdf:*central-registry*)' \
     --eval '(asdf:load-system :expert-system)' 2>&1 | tail -20 | sed 's/^/    /'
exit 1
