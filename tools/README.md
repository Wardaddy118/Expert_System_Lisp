# tools/ — Generador del documento de diseño

Genera `docs/DISENO-Y-ARQUITECTURA.pdf`.

El documento existe para ser leído, pero también para **no mentir**: la
sección de reglas no está transcrita a mano, se vuelca del motor en
ejecución. Si alguien cambia una regla y regenera, el PDF queda al día solo.
Esa promesa solo se sostiene si el generador vive en el repositorio, y por
eso está aquí.

## Cómo regenerar

Desde la raíz del repositorio:

```bash
# 1. Volcar las 25 reglas desde el motor cargado
sbcl --script tools/dump-rules.lisp        # escribe rules-dump.sexp

# 2. Construir el HTML
python tools/build_doc.py                  # escribe docs/DISENO-Y-ARQUITECTURA.html

# 3. Imprimirlo a PDF con Chrome o Edge en modo headless
"C:/Program Files/Google/Chrome/Application/chrome.exe" \
  --headless --disable-gpu --no-pdf-header-footer \
  --print-to-pdf="docs/DISENO-Y-ARQUITECTURA.pdf" \
  "file:///RUTA/ABSOLUTA/docs/DISENO-Y-ARQUITECTURA.html"

rm rules-dump.sexp
```

El HTML intermedio está en `.gitignore`: se regenera, no se versiona. El PDF
sí se versiona, porque es el entregable.

## Archivos

| Archivo | Qué hace |
| ------- | -------- |
| `dump-rules.lisp` | Carga el sistema y vuelca `engine:*rules*` a `rules-dump.sexp` |
| `build_doc.py` | Arma el HTML: diagramas SVG, las reglas volcadas y las salidas de ejemplo |
| `accents.py` | Restaura tildes y eñes del texto visible |
| `samples/` | Salidas reales de cada perfil, citadas literalmente en la sección 8 |

## Sobre `accents.py`

El texto del documento se escribió sin tildes y se restauran al generar. La
restauración **solo toca prosa**: deja intactos los bloques `<pre>`, los
`<code>`, el `<style>` y todo lo que esté dentro de una etiqueta.

Eso importa más de lo que parece. Los identificadores Lisp no llevan tilde y
no deben llevarla: `target-area` y `area-match` tienen que sobrevivir intactos
aunque «área» sí lleve tilde en prosa. Por eso el límite de palabra excluye
guiones, y las listas de relaciones de los diagramas están protegidas.

Las frases donde la tilde depende del sentido —«esta» demostrativo frente a
«está» verbo, «que» frente a «qué»— no se resuelven palabra a palabra: están
listadas una por una en `PHRASES`, o corregidas directamente en el texto
fuente cuando una etiqueta HTML parte la frase en dos.

## Actualizar las salidas de ejemplo

Si cambian las reglas o el catálogo, las salidas citadas en la sección 8 hay
que volver a capturarlas:

```bash
for p in first-year advanced tight-schedule low-tolerance; do
  sbcl --non-interactive \
    --eval '(require :asdf)' \
    --eval '(push (truename ".") asdf:*central-registry*)' \
    --eval '(asdf:load-system :expert-system)' \
    --eval "(cli:start :profile-path \"data/profiles/$p.lisp\")" \
    > "tools/samples/out-$p.txt" 2>/dev/null
done
```
