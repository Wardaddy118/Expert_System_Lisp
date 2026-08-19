# -*- coding: utf-8 -*-
"""Restaura tildes y enes del texto visible del documento.

Solo toca prosa: deja intactos los bloques <pre>, los <code>, el <style> y
todo lo que este dentro de una etiqueta HTML (atributos, clases, ids). Los
identificadores del codigo Lisp y los nombres de archivo no llevan tilde y
no deben llevarla.
"""
import re

WORDS = {
    "academicas":"académicas","academico":"académico","academicos":"académicos",
    "aceptacion":"aceptación","acompana":"acompaña","activacion":"activación",
    "ademas":"además","agregacion":"agregación","asi":"así","atras":"atrás",
    "automatico":"automático","catalogo":"catálogo","categoria":"categoría",
    "categorias":"categorías","codigo":"código","codigos":"códigos",
    "computacion":"computación","conclusion":"conclusión","condicion":"condición",
    "conexion":"conexión","creditos":"créditos","credito":"crédito",
    "decision":"decisión","declaracion":"declaración","demostracion":"demostración",
    "descripcion":"descripción","despues":"después","diagnostico":"diagnóstico",
    "direccion":"dirección","diseno":"diseño","distincion":"distinción",
    "distribucion":"distribución","division":"división","ejecucion":"ejecución",
    "especificacion":"especificación","estadisticas":"estadísticas",
    "estan":"están","estandar":"estándar","estaria":"estaría",
    "excepcion":"excepción","exclusion":"exclusión","explicacion":"explicación",
    "fidelitas":"Fidélitas","formacion":"formación","formula":"fórmula",
    "generico":"genérico","grafica":"gráfica","habria":"habría","haria":"haría",
    "indice":"índice","ingenieria":"ingeniería","insercion":"inserción",
    "instanciacion":"instanciación","invalidaria":"invalidaría","jamas":"jamás",
    "librerias":"librerías","limitacion":"limitación","limite":"límite",
    "linea":"línea","lineas":"líneas","logica":"lógica","maquina":"máquina",
    "mas":"más","matricula":"matrícula","monotono":"monótono",
    "narracion":"narración","negacion":"negación","ningun":"ningún",
    "notese":"nótese","numero":"número","obligaria":"obligaría",
    "permutacion":"permutación","podria":"podría","presentacion":"presentación",
    "priorizacion":"priorización","produccion":"producción","proposito":"propósito",
    "recomendacion":"recomendación","refraccion":"refracción","relacion":"relación",
    "resolucion":"resolución","resolveria":"resolvería","rigido":"rígido",
    "rotacion":"rotación","seccion":"sección","senal":"señal","senala":"señala",
    "seria":"sería","sesion":"sesión","simbolo":"símbolo","simbolos":"símbolos",
    "simplificacion":"simplificación","tamano":"tamaño","tambien":"también",
    "terminacion":"terminación","unica":"única","unico":"único",
    "validacion":"validación","vacia":"vacía","verificacion":"verificación",
    "version":"versión","via":"vía","evalua":"evalúa","pequeno":"pequeño",
    "anadir":"añadir","ano":"año","anos":"años",
    "area":"área","areas":"áreas",
}

# Frases donde la tilde depende del sentido y no se puede decidir palabra a palabra.
PHRASES = [
    ("sabe que es un curso", "sabe qué es un curso"),
    ("saber que es un curso", "saber qué es un curso"),
    ("por que lo hace igual", "por qué lo hace igual"),
    ("por que no usamos", "por qué no usamos"),
    ("indica cuales de las", "indica cuáles de las"),
    ("con cuantos desbloquean", "con cuántos desbloquean"),
    ("cuantas de las", "cuántas de las"),
    ("que se pierde con cada atajo", "qué se pierde con cada atajo"),
    ("dice que archivo y que problema", "dice qué archivo y qué problema"),
    # "esta" es demostrativo o verbo segun el caso; solo estos son verbo.
    ("no esta en ordenar", "no está en ordenar"),
    ("Esta en que un motor", "Está en que un motor"),
    ("la distincion esta en que relacion se usa y quien puede afirmarla",
     "la distinción está en qué relación se usa y quién puede afirmarla"),
    ("si no esta aprobado", "si no está aprobado"),
    ("la dificultad esta al menos", "la dificultad está al menos"),
    ("El area esta entre los intereses", "El área está entre los intereses"),
]

def _restore_case(original, replacement):
    if original.isupper():
        return replacement.upper()
    if original[0].isupper():
        return replacement[0].upper() + replacement[1:]
    return replacement

_WORD_RE = re.compile(r"\b(" + "|".join(sorted(WORDS, key=len, reverse=True)) + r")\b",
                      re.IGNORECASE)

def _fix_text(text):
    for a, b in PHRASES:
        text = text.replace(a, b)
        text = text.replace(a.capitalize(), b.capitalize())
    return _WORD_RE.sub(lambda m: _restore_case(m.group(0), WORDS[m.group(0).lower()]), text)

# Regiones que no se tocan: bloques pre/code/style completos, y cualquier etiqueta.
_PROTECTED = re.compile(
    r"(<pre.*?</pre>|<code.*?</code>|<style.*?</style>"
    r"|<text[^>]*class=\"mono[^\"]*\"[^>]*>.*?</text>"   # relaciones en los diagramas
    r"|<[^>]+>)", re.S)

def fix_html(html_text):
    parts = _PROTECTED.split(html_text)
    # split con grupo de captura: los indices impares son las regiones protegidas
    return "".join(p if i % 2 else _fix_text(p) for i, p in enumerate(parts))
