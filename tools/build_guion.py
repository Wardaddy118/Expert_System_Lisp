# -*- coding: utf-8 -*-
"""Convierte docs/GUION-PRESENTACION.md a HTML listo para imprimir a PDF.

Una sola fuente de verdad: el guion se escribe y se edita en Markdown, y este
script solo lo presenta. Reutiliza la hoja de estilos del documento de
arquitectura para que los dos entregables se vean como el mismo trabajo.

El conversor cubre el subconjunto de Markdown que usa el guion: titulos,
tablas, listas, bloques de codigo, citas, y enfasis en linea. No pretende ser
un conversor general.
"""
import io, os, re, html

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SRC = os.path.join(ROOT, "docs", "GUION-PRESENTACION.md")
OUT = os.path.join(ROOT, "docs", "GUION-PRESENTACION.html")

CSS = """
@page { size: Letter; margin: 17mm 15mm 16mm 15mm; }
* { box-sizing: border-box; }
body { font-family: "Segoe UI","Helvetica Neue",Arial,sans-serif; color:#1e293b;
       font-size:10.4pt; line-height:1.55; margin:0; }
h1 { font-size:19pt; color:#0f172a; margin:0 0 14px; letter-spacing:-.3px;
     border-bottom:3px solid #6366f1; padding-bottom:7px; page-break-before:always; }
h1:first-of-type { page-break-before:avoid; }
h2 { font-size:13.4pt; color:#0f172a; margin:24px 0 10px; padding-bottom:5px;
     border-bottom:2px solid #cbd5e1; page-break-after:avoid; }
h3 { font-size:11.2pt; color:#4338ca; margin:16px 0 7px; page-break-after:avoid; }
p { margin:0 0 9px; }
ul,ol { margin:0 0 10px; padding-left:22px; }
li { margin-bottom:4px; }
table { width:100%; border-collapse:collapse; margin:10px 0 14px; font-size:9.2pt;
        page-break-inside:avoid; }
th { background:#1e293b; color:#fff; text-align:left; padding:6px 8px; font-weight:600; }
td { padding:5px 8px; border-bottom:1px solid #e2e8f0; vertical-align:top; }
tr:nth-child(even) td { background:#f8fafc; }
code { font-family:"Consolas","Courier New",monospace; background:#f1f5f9; padding:1px 4px;
       border-radius:3px; font-size:9pt; color:#0f172a; }
pre { font-family:"Consolas","Courier New",monospace; font-size:8.4pt; line-height:1.45;
      background:#0f172a; color:#e2e8f0; padding:10px 12px; border-radius:5px;
      white-space:pre-wrap; word-wrap:break-word; page-break-inside:avoid; margin:8px 0 12px; }
pre code { background:none; color:inherit; padding:0; font-size:inherit; }
pre.bash { background:#1e293b; }
pre.bash::before { content:"$ "; color:#6ee7b7; font-weight:700; }
pre.text { background:#f8fafc; color:#0f172a; border:1px solid #cbd5e1; }
blockquote { margin:10px 0; padding:9px 14px; background:#eef2ff; border-left:4px solid #6366f1;
             border-radius:0 4px 4px 0; page-break-inside:avoid; }
blockquote p { margin:0 0 6px; }
blockquote p:last-child { margin-bottom:0; }
blockquote em { font-style:normal; color:#3730a3; font-size:10.6pt; }
hr { border:0; border-top:1px solid #e2e8f0; margin:20px 0; }
.cover { text-align:center; padding:56mm 0 0; page-break-after:always; }
.cover h1 { font-size:26pt; border:0; padding:0; margin-bottom:12px; page-break-before:avoid; }
.cover .sub { font-size:13pt; color:#475569; margin-bottom:30px; }
.cover .line { width:88px; height:3px; background:#6366f1; margin:20px auto 24px; }
.cover .meta { font-size:10.4pt; color:#64748b; line-height:1.9; }
strong { color:#0f172a; }
"""

INLINE = [
    (re.compile(r"`([^`]+)`"), lambda m: "<code>%s</code>" % html.escape(m.group(1))),
    (re.compile(r"\*\*([^*]+)\*\*"), lambda m: "<strong>%s</strong>" % m.group(1)),
    (re.compile(r"(?<!\*)\*([^*]+)\*(?!\*)"), lambda m: "<em>%s</em>" % m.group(1)),
    (re.compile(r"\[([^\]]+)\]\(([^)]+)\)"), lambda m: '<a href="%s">%s</a>' % (m.group(2), m.group(1))),
]

def inline(text):
    text = html.escape(text)
    # el escape convierte los asteriscos y comillas en entidades? no: solo & < >
    for rx, fn in INLINE:
        text = rx.sub(fn, text)
    return text

def convert(md):
    out, i = [], 0
    lines = md.split("\n")
    while i < len(lines):
        ln = lines[i]

        if ln.startswith("```"):                       # bloque de codigo
            lang = ln[3:].strip() or "text"
            i += 1
            buf = []
            while i < len(lines) and not lines[i].startswith("```"):
                buf.append(lines[i]); i += 1
            i += 1
            cls = "bash" if lang == "bash" else "text"
            body = html.escape("\n".join(buf))
            if cls == "bash":
                body = body.replace("\n", "\n$ ")      # prefijo en cada linea
            out.append('<pre class="%s">%s</pre>' % (cls, body))
            continue

        if ln.startswith("|"):                          # tabla
            rows = []
            while i < len(lines) and lines[i].startswith("|"):
                rows.append(lines[i]); i += 1
            cells = [[c.strip() for c in r.strip().strip("|").split("|")] for r in rows]
            head, body = cells[0], cells[2:] if len(cells) > 2 else []
            t = ["<table><tr>" + "".join("<th>%s</th>" % inline(c) for c in head) + "</tr>"]
            for r in body:
                t.append("<tr>" + "".join("<td>%s</td>" % inline(c) for c in r) + "</tr>")
            out.append("".join(t) + "</table>")
            continue

        if ln.startswith(">"):                          # cita
            buf = []
            while i < len(lines) and lines[i].startswith(">"):
                buf.append(lines[i].lstrip(">").strip()); i += 1
            paras = " ".join(buf).split("  ")
            out.append("<blockquote>%s</blockquote>"
                       % "".join("<p>%s</p>" % inline(p) for p in paras if p.strip()))
            continue

        m = re.match(r"^(#{1,3}) (.+)$", ln)            # titulos
        if m:
            lvl = len(m.group(1))
            out.append("<h%d>%s</h%d>" % (lvl, inline(m.group(2)), lvl))
            i += 1
            continue

        if re.match(r"^[-*] ", ln) or re.match(r"^\d+\. ", ln):
            # Listas. Un item puede ocupar varias lineas: las continuaciones
            # vienen indentadas y pertenecen al item anterior, no son parrafos
            # nuevos. Sin esto, un item envuelto se partia en dos.
            ordered = bool(re.match(r"^\d+\. ", ln))
            start = re.compile(r"^\d+\. ") if ordered else re.compile(r"^[-*] ")
            items = []
            while i < len(lines):
                cur = lines[i]
                if start.match(cur):
                    items.append(start.sub("", cur).strip()); i += 1
                elif items and cur.strip() and cur[:1] in (" ", "	"):
                    items[-1] += " " + cur.strip(); i += 1
                else:
                    break
            tag = "ol" if ordered else "ul"
            out.append("<%s>%s</%s>" % (tag, "".join("<li>%s</li>" % inline(x) for x in items), tag))
            continue

        if ln.strip() == "---":
            out.append("<hr>"); i += 1; continue

        if ln.strip() == "":
            i += 1; continue

        buf = []                                        # parrafo
        while i < len(lines) and lines[i].strip() and not re.match(r"^(#{1,3} |[-*] |\d+\. |\||>|```|---)", lines[i]):
            buf.append(lines[i].strip()); i += 1
        out.append("<p>%s</p>" % inline(" ".join(buf)))

    return "\n".join(out)

md = io.open(SRC, encoding="utf-8").read()
# El titulo del documento pasa a ser portada; el resto se convierte.
md = md.split("\n", 1)[1]

cover = """<div class="cover">
<h1>Guion de presentación</h1>
<div class="line"></div>
<div class="sub">Sistema Experto de Recomendaciones Académicas</div>
<div class="meta">Cuatro bloques de exposición y el paso a paso de la demostración<br>
Alineado con el Documento de Diseño y Arquitectura<br><br>
Duración estimada: 15 minutos, más preguntas<br><br>
Agosto de 2026</div>
</div>"""

doc = ('<!doctype html><html lang="es"><head><meta charset="utf-8">'
       '<title>Guion de presentación</title><style>%s</style></head><body>%s%s</body></html>'
       % (CSS, cover, convert(md)))
io.open(OUT, "w", encoding="utf-8").write(doc)
print("HTML generado -> %s" % OUT)
