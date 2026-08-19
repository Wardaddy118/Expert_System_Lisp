# -*- coding: utf-8 -*-
"""Genera el documento de diseno y arquitectura en HTML, listo para imprimir a PDF.

Las reglas NO se transcriben a mano: se leen de rules-dump.sexp, que a su vez
sale del sistema en ejecucion. Asi el documento no puede desfasarse del codigo.
"""
import io, re, html, os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from accents import fix_html

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SCRATCH = os.path.join(ROOT, "tools", "samples")

# ---------------------------------------------------------------- reglas

def clean(s):
    s = s.replace("expert-system.domain::", "")
    s = s.replace("expert-system.engine::", "engine:")
    s = s.replace("expert-system.engine:", "engine:")
    s = s.replace("common-lisp::", "")
    return s

def parse_rules(path):
    txt = io.open(path, encoding="utf-8").read()
    txt = clean(txt)
    rules = []
    # cada regla empieza con (:name "..."
    chunks = re.split(r'\n \(:name ', txt)[1:]
    for c in chunks:
        name = re.match(r'"([^"]+)"', c).group(1)
        pri = re.search(r':priority (\d+)', c).group(1)
        doc = re.search(r':doc "((?:[^"\\]|\\.)*)"', c, re.S).group(1)
        doc = doc.replace('\\"', '"')
        doc = re.sub(r'\s+', ' ', doc).strip()
        when = re.search(r':when (.*?)\n  :then', c, re.S).group(1)
        then = re.search(r':then (.*?)\)\s*$', c, re.S).group(1)
        squash = lambda x: re.sub(r'\s+', ' ', x).strip().rstrip(')') + ')' if x.strip() else x
        rules.append(dict(name=name, pri=int(pri), doc=doc,
                          when=re.sub(r'\s+', ' ', when).strip(),
                          then=re.sub(r'\s+', ' ', then).strip()))
    return rules

RULES = parse_rules(os.path.join(ROOT, "rules-dump.sexp"))

# agrupacion tematica por rango de prioridad y nombre
def group_of(r):
    n = r["name"]
    if "prerequisite" in n or "schedule" in n and "unavailable" in n: return "Elegibilidad (BR-001 a BR-003)"
    if n.startswith("eligible") or "schedule-fits" in n: return "Elegibilidad (BR-001 a BR-003)"
    if "bottleneck-with" in n: return "Cuello de botella (BR-006)"
    if "tolerance" in n: return "Tolerancia a la dificultad (BR-005)"
    if n.endswith("-match-rule"): return "Afinidad (soporte de BR-010, BR-011, BR-013)"
    if n.startswith("priority-"): return "Priorizacion (BR-010 a BR-015)"
    if n.startswith("recommended"): return "De elegible a recomendado (BR-007)"
    if n.startswith("excluded"): return "Motivos de descarte (BR-021)"
    return "Otras"

ORDER = ["Elegibilidad (BR-001 a BR-003)", "Cuello de botella (BR-006)",
         "Tolerancia a la dificultad (BR-005)", "Afinidad (soporte de BR-010, BR-011, BR-013)",
         "Priorizacion (BR-010 a BR-015)", "De elegible a recomendado (BR-007)",
         "Motivos de descarte (BR-021)", "Otras"]

def rules_html():
    out = []
    for g in ORDER:
        rs = [r for r in RULES if group_of(r) == g]
        if not rs: continue
        out.append('<h3 class="grp">%s</h3>' % html.escape(g))
        for r in rs:
            out.append("""<div class="rule">
<div class="rule-head"><span class="rname">%s</span><span class="pri">prioridad %d</span></div>
<p class="rdoc">%s</p>
<pre class="code"><span class="kw">:when</span> %s
<span class="kw">:then</span> %s</pre>
</div>""" % (html.escape(r["name"]), r["pri"], html.escape(r["doc"]),
             html.escape(r["when"]), html.escape(r["then"])))
    return "\n".join(out)

def sample(path, start, n):
    txt = io.open(path, encoding="utf-8", errors="replace").read()
    i = txt.find(start)
    if i < 0: return "(no disponible)"
    return "\n".join(txt[i:].splitlines()[:n])

# ---------------------------------------------------------------- SVG

SVG_LAYERS = '''
<svg viewBox="0 0 720 400" class="dia" role="img" aria-label="Arquitectura de tres capas">
  <defs><marker id="a1" markerWidth="9" markerHeight="9" refX="8" refY="4.5" orient="auto">
    <path d="M0,0 L9,4.5 L0,9 z" fill="#64748b"/></marker></defs>

  <rect x="60" y="18" width="600" height="92" rx="8" fill="#eef2ff" stroke="#6366f1" stroke-width="1.6"/>
  <text x="80" y="44" class="lt">CAPA DE PRESENTACION &#8212; src/cli/</text>
  <text x="80" y="66" class="ls">Captura del perfil &#183; flujo de sesion &#183; formato del informe</text>
  <text x="80" y="86" class="ls2">Unica capa con entrada/salida. format.lisp &#183; session.lisp</text>
  <text x="80" y="103" class="ls2">Prohibido: logica de decision. Solo pregunta y presenta.</text>

  <line x1="360" y1="112" x2="360" y2="142" stroke="#64748b" stroke-width="1.6" marker-end="url(#a1)"/>
  <text x="372" y="132" class="ann">depende de</text>

  <rect x="60" y="144" width="600" height="92" rx="8" fill="#ecfdf5" stroke="#10b981" stroke-width="1.6"/>
  <text x="80" y="170" class="lt">CAPA DE DOMINIO &#8212; src/domain/</text>
  <text x="80" y="192" class="ls">25 reglas academicas &#183; carga y validacion &#183; explicaciones &#183; estadisticas</text>
  <text x="80" y="212" class="ls2">loader.lisp &#183; knowledge.lisp &#183; explain.lisp &#183; stats.lisp</text>
  <text x="80" y="229" class="ls2">Conoce cursos y creditos. No conoce la CLI.</text>

  <line x1="360" y1="238" x2="360" y2="268" stroke="#64748b" stroke-width="1.6" marker-end="url(#a1)"/>
  <text x="372" y="258" class="ann">depende de</text>

  <rect x="60" y="270" width="600" height="106" rx="8" fill="#fff7ed" stroke="#f59e0b" stroke-width="1.6"/>
  <text x="80" y="296" class="lt">MOTOR DE INFERENCIA &#8212; src/engine/</text>
  <text x="80" y="318" class="ls">Hechos &#183; matching con variables &#183; reglas como datos &#183; agenda</text>
  <text x="80" y="338" class="ls">Resolucion de conflictos &#183; refraccion &#183; ciclo &#183; traza</text>
  <text x="80" y="357" class="ls2">facts &#183; matching &#183; rules &#183; agenda &#183; inference</text>
  <text x="80" y="372" class="ls2b">GENERICO: no sabe que es un curso. Su suite usa hechos inventados.</text>
</svg>'''

SVG_FLOW = '''
<svg viewBox="0 0 720 470" class="dia" role="img" aria-label="Flujo de una sesion">
  <defs><marker id="a2" markerWidth="9" markerHeight="9" refX="8" refY="4.5" orient="auto">
    <path d="M0,0 L9,4.5 L0,9 z" fill="#475569"/></marker></defs>

  <rect x="230" y="14" width="260" height="42" rx="21" fill="#e0e7ff" stroke="#6366f1" stroke-width="1.5"/>
  <text x="360" y="40" class="fc" text-anchor="middle">La CLI captura el perfil</text>
  <line x1="360" y1="58" x2="360" y2="82" stroke="#475569" stroke-width="1.5" marker-end="url(#a2)"/>

  <rect x="180" y="84" width="360" height="52" rx="6" fill="#f1f5f9" stroke="#94a3b8" stroke-width="1.4"/>
  <text x="360" y="106" class="fc" text-anchor="middle">El cargador afirma los hechos</text>
  <text x="360" y="124" class="fs" text-anchor="middle">catalogo (47 cursos) + perfil &#8594; memoria de trabajo</text>
  <line x1="360" y1="138" x2="360" y2="162" stroke="#475569" stroke-width="1.5" marker-end="url(#a2)"/>

  <rect x="150" y="164" width="420" height="122" rx="6" fill="#fff7ed" stroke="#f59e0b" stroke-width="1.8"/>
  <text x="360" y="186" class="fc" text-anchor="middle">EL MOTOR CORRE HASTA QUIESCENCIA</text>
  <rect x="172" y="198" width="112" height="34" rx="4" fill="#fff" stroke="#f59e0b"/>
  <text x="228" y="220" class="fs" text-anchor="middle">MATCH</text>
  <rect x="304" y="198" width="112" height="34" rx="4" fill="#fff" stroke="#f59e0b"/>
  <text x="360" y="220" class="fs" text-anchor="middle">SELECT</text>
  <rect x="436" y="198" width="112" height="34" rx="4" fill="#fff" stroke="#f59e0b"/>
  <text x="492" y="220" class="fs" text-anchor="middle">ACT</text>
  <line x1="284" y1="215" x2="300" y2="215" stroke="#f59e0b" stroke-width="1.5" marker-end="url(#a2)"/>
  <line x1="416" y1="215" x2="432" y2="215" stroke="#f59e0b" stroke-width="1.5" marker-end="url(#a2)"/>
  <path d="M492,234 L492,252 L228,252 L228,236" fill="none" stroke="#f59e0b" stroke-width="1.4"
        stroke-dasharray="4 3" marker-end="url(#a2)"/>
  <text x="360" y="268" class="fs" text-anchor="middle">repite mientras haya instanciaciones sin disparar</text>
  <text x="360" y="281" class="fs2" text-anchor="middle">refraccion evita repetir; tope de seguridad 1000 ciclos</text>
  <line x1="360" y1="288" x2="360" y2="312" stroke="#475569" stroke-width="1.5" marker-end="url(#a2)"/>

  <rect x="180" y="314" width="360" height="52" rx="6" fill="#ecfdf5" stroke="#10b981" stroke-width="1.4"/>
  <text x="360" y="336" class="fc" text-anchor="middle">Post-procesamiento del dominio</text>
  <text x="360" y="354" class="fs" text-anchor="middle">BR-008 una electiva por bloque &#8594; BR-004 tope de creditos</text>
  <line x1="360" y1="368" x2="360" y2="392" stroke="#475569" stroke-width="1.5" marker-end="url(#a2)"/>

  <rect x="60" y="394" width="600" height="62" rx="6" fill="#eef2ff" stroke="#6366f1" stroke-width="1.4"/>
  <text x="360" y="416" class="fc" text-anchor="middle">Se presenta el informe</text>
  <text x="360" y="434" class="fs" text-anchor="middle">recomendaciones &#183; descartes con motivo &#183; explicaciones desde la traza</text>
  <text x="360" y="450" class="fs" text-anchor="middle">estadisticas del estudiante &#183; estadisticas del catalogo &#183; traza</text>
</svg>'''

SVG_FACTS = '''
<svg viewBox="0 0 720 430" class="dia" role="img" aria-label="Flujo de hechos entre relaciones">
  <defs><marker id="a3" markerWidth="8" markerHeight="8" refX="7" refY="4" orient="auto">
    <path d="M0,0 L8,4 L0,8 z" fill="#94a3b8"/></marker></defs>

  <rect x="30" y="16" width="300" height="104" rx="6" fill="#fff7ed" stroke="#f59e0b" stroke-width="1.4"/>
  <text x="46" y="38" class="lt2">CAPA DE CATALOGO</text>
  <text x="46" y="56" class="mono">course &#183; course-name &#183; term &#183; credits</text>
  <text x="46" y="73" class="mono">area &#183; difficulty &#183; prerequisite</text>
  <text x="46" y="90" class="mono">schedule &#183; laboratory &#183; elective</text>
  <text x="46" y="110" class="ann2">La afirma el cargador de data/courses.lisp</text>

  <rect x="390" y="16" width="300" height="104" rx="6" fill="#eef2ff" stroke="#6366f1" stroke-width="1.4"/>
  <text x="406" y="38" class="lt2">CAPA DE PERFIL</text>
  <text x="406" y="56" class="mono">approved &#183; interest &#183; target-area</text>
  <text x="406" y="73" class="mono">available &#183; difficulty-tolerance</text>
  <text x="406" y="90" class="mono">credit-limit</text>
  <text x="406" y="110" class="ann2">La afirma la CLI o data/profiles/</text>

  <line x1="180" y1="122" x2="300" y2="156" stroke="#94a3b8" stroke-width="1.4" marker-end="url(#a3)"/>
  <line x1="540" y1="122" x2="420" y2="156" stroke="#94a3b8" stroke-width="1.4" marker-end="url(#a3)"/>

  <rect x="150" y="158" width="420" height="252" rx="6" fill="#ecfdf5" stroke="#10b981" stroke-width="1.6"/>
  <text x="360" y="180" class="lt2" text-anchor="middle">CAPA DERIVADA &#8212; solo la produce el motor</text>

  <rect x="172" y="192" width="122" height="30" rx="4" fill="#fff" stroke="#10b981"/>
  <text x="233" y="212" class="mono2" text-anchor="middle">prerequisites-satisfied</text>
  <rect x="300" y="192" width="112" height="30" rx="4" fill="#fff" stroke="#10b981"/>
  <text x="356" y="212" class="mono2" text-anchor="middle">schedule-fits</text>
  <rect x="418" y="192" width="130" height="30" rx="4" fill="#fff" stroke="#10b981"/>
  <text x="483" y="212" class="mono2" text-anchor="middle">within-tolerance</text>

  <line x1="360" y1="224" x2="360" y2="244" stroke="#10b981" stroke-width="1.4" marker-end="url(#a3)"/>
  <rect x="300" y="246" width="120" height="30" rx="4" fill="#d1fae5" stroke="#10b981" stroke-width="1.5"/>
  <text x="360" y="266" class="mono2" text-anchor="middle">eligible</text>

  <line x1="360" y1="278" x2="360" y2="296" stroke="#10b981" stroke-width="1.4" marker-end="url(#a3)"/>
  <rect x="172" y="298" width="108" height="28" rx="4" fill="#fff" stroke="#10b981"/>
  <text x="226" y="317" class="mono2" text-anchor="middle">area-match</text>
  <rect x="288" y="298" width="122" height="28" rx="4" fill="#fff" stroke="#10b981"/>
  <text x="349" y="317" class="mono2" text-anchor="middle">interest-match</text>
  <rect x="418" y="298" width="108" height="28" rx="4" fill="#fff" stroke="#10b981"/>
  <text x="472" y="317" class="mono2" text-anchor="middle">bottleneck</text>

  <line x1="360" y1="328" x2="360" y2="344" stroke="#10b981" stroke-width="1.4" marker-end="url(#a3)"/>
  <rect x="300" y="346" width="120" height="28" rx="4" fill="#fff" stroke="#10b981"/>
  <text x="360" y="365" class="mono2" text-anchor="middle">priority (acumulativo)</text>

  <line x1="360" y1="376" x2="360" y2="390" stroke="#10b981" stroke-width="1.4" marker-end="url(#a3)"/>
  <rect x="238" y="384" width="118" height="26" rx="4" fill="#d1fae5" stroke="#059669" stroke-width="1.5"/>
  <text x="297" y="402" class="mono2" text-anchor="middle">recommended</text>
  <rect x="368" y="384" width="118" height="26" rx="4" fill="#fee2e2" stroke="#dc2626" stroke-width="1.3"/>
  <text x="427" y="402" class="mono2" text-anchor="middle">excluded + motivo</text>
</svg>'''

# ---------------------------------------------------------------- HTML

CSS = """
@page { size: Letter; margin: 17mm 15mm 16mm 15mm; }
* { box-sizing: border-box; }
body { font-family: "Segoe UI", "Helvetica Neue", Arial, sans-serif; color:#1e293b;
       font-size:10.2pt; line-height:1.5; margin:0; }
h1 { font-size:20pt; color:#0f172a; margin:0 0 4px; letter-spacing:-.4px; }
h2 { font-size:14pt; color:#0f172a; margin:26px 0 10px; padding-bottom:5px;
     border-bottom:2px solid #6366f1; page-break-after:avoid; }
h3 { font-size:11.4pt; color:#1e293b; margin:18px 0 7px; page-break-after:avoid; }
h3.grp { color:#4338ca; background:#eef2ff; padding:6px 10px; border-radius:4px;
         border-left:3px solid #6366f1; }
p { margin:0 0 9px; text-align:justify; }
.lead { font-size:10.6pt; color:#334155; }
table { width:100%; border-collapse:collapse; margin:10px 0 14px; font-size:9.1pt;
        page-break-inside:avoid; }
th { background:#1e293b; color:#fff; text-align:left; padding:6px 8px; font-weight:600; }
td { padding:5px 8px; border-bottom:1px solid #e2e8f0; vertical-align:top; }
tr:nth-child(even) td { background:#f8fafc; }
code { font-family:"Consolas","Courier New",monospace; background:#f1f5f9; padding:1px 4px;
       border-radius:3px; font-size:8.9pt; color:#0f172a; }
pre { font-family:"Consolas","Courier New",monospace; font-size:8.2pt; line-height:1.42;
      background:#0f172a; color:#e2e8f0; padding:10px 12px; border-radius:5px;
      overflow:visible; white-space:pre-wrap; word-wrap:break-word;
      page-break-inside:avoid; margin:8px 0 12px; }
pre.code { background:#f8fafc; color:#0f172a; border:1px solid #cbd5e1; }
pre.code .kw { color:#7c3aed; font-weight:700; }
.dia { width:100%; height:auto; margin:12px 0 16px; page-break-inside:avoid; }
.lt  { font:700 12px "Segoe UI",sans-serif; fill:#0f172a; }
.lt2 { font:700 11px "Segoe UI",sans-serif; fill:#0f172a; }
.ls  { font:400 10.5px "Segoe UI",sans-serif; fill:#334155; }
.ls2 { font:400 9.5px "Consolas",monospace; fill:#64748b; }
.ls2b{ font:700 9.5px "Segoe UI",sans-serif; fill:#b45309; }
.ann { font:400 9px "Segoe UI",sans-serif; fill:#64748b; }
.ann2{ font:italic 9px "Segoe UI",sans-serif; fill:#64748b; }
.fc  { font:600 11px "Segoe UI",sans-serif; fill:#0f172a; }
.fs  { font:400 9.3px "Segoe UI",sans-serif; fill:#475569; }
.fs2 { font:italic 8.6px "Segoe UI",sans-serif; fill:#64748b; }
.mono { font:400 9.2px "Consolas",monospace; fill:#334155; }
.mono2{ font:600 8.8px "Consolas",monospace; fill:#0f172a; }
.rule { border:1px solid #e2e8f0; border-radius:5px; padding:9px 11px; margin:9px 0;
        page-break-inside:avoid; background:#fff; }
.rule-head { display:flex; justify-content:space-between; align-items:baseline;
             border-bottom:1px solid #f1f5f9; padding-bottom:4px; margin-bottom:5px; }
.rname { font-family:"Consolas",monospace; font-weight:700; font-size:9.6pt; color:#0f172a; }
.pri { font-size:8.2pt; color:#fff; background:#6366f1; padding:1px 7px; border-radius:9px; }
.rdoc { font-size:9.2pt; color:#475569; margin:0 0 6px; }
.note { background:#fffbeb; border-left:3px solid #f59e0b; padding:9px 12px;
        margin:11px 0; font-size:9.5pt; page-break-inside:avoid; }
.warn { background:#fef2f2; border-left:3px solid #dc2626; padding:9px 12px;
        margin:11px 0; font-size:9.5pt; page-break-inside:avoid; }
.ok   { background:#f0fdf4; border-left:3px solid #16a34a; padding:9px 12px;
        margin:11px 0; font-size:9.5pt; page-break-inside:avoid; }
.cover { text-align:center; padding:52mm 0 0; page-break-after:always; }
.cover h1 { font-size:27pt; line-height:1.18; margin-bottom:14px; }
.cover .sub { font-size:13pt; color:#475569; margin-bottom:34px; }
.cover .meta { font-size:10.4pt; color:#64748b; line-height:1.85; }
.cover .rule-line { width:88px; height:3px; background:#6366f1; margin:22px auto 26px; }
.toc { page-break-after:always; }
.toc ol { font-size:10.4pt; line-height:1.95; padding-left:20px; }
.toc ol ol { font-size:9.6pt; line-height:1.6; color:#475569; }
.pb { page-break-before:always; }
.small { font-size:8.8pt; color:#64748b; }
"""

def build():
    r_html = rules_html()
    out_low = SCRATCH + "/out-low-tolerance.txt"
    out_adv = SCRATCH + "/out-advanced.txt"

    doc = []
    doc.append('<div class="cover">')
    doc.append('<h1>Sistema Experto de<br>Recomendaciones Academicas</h1>')
    doc.append('<div class="rule-line"></div>')
    doc.append('<div class="sub">Documento de Diseno y Arquitectura</div>')
    doc.append('<div class="meta">Implementado en Common Lisp (SBCL)<br>'
               'Bachillerato en Ingenieria en Sistemas de Computacion<br>'
               'Universidad Fidelitas<br><br>'
               'Motor de inferencia propio &#183; 25 reglas declarativas<br>'
               '47 cursos &#183; 358 pruebas automatizadas<br><br>'
               'Agosto de 2026</div>')
    doc.append('</div>')

    doc.append('''<div class="toc"><h2>Contenido</h2><ol>
<li>Proposito y alcance del sistema</li>
<li>Arquitectura general
  <ol><li>Division en capas</li><li>Invariante de dependencias</li><li>Estructura de archivos</li></ol></li>
<li>Flujo de una sesion completa</li>
<li>El motor de inferencia
  <ol><li>Ciclo match &#8594; select &#8594; act</li><li>Resolucion de conflictos</li>
      <li>Refraccion y terminacion</li><li>La traza</li></ol></li>
<li>Modelo de conocimiento
  <ol><li>Las tres capas de hechos</li><li>Catalogo de relaciones</li>
      <li>Reglas de modelado</li></ol></li>
<li>Reglas implementadas (25)</li>
<li>Reglas de negocio y su trazabilidad</li>
<li>Ejemplos implementados
  <ol><li>Los cinco perfiles</li><li>Salida real del sistema</li>
      <li>Explicacion reconstruida</li><li>Traza del motor</li></ol></li>
<li>Estadisticas producidas</li>
<li>Verificacion y criterios de aceptacion</li>
<li>Limitaciones y procedencia de los datos</li>
</ol></div>''')

    # 1
    doc.append('<h2>1. Proposito y alcance del sistema</h2>')
    doc.append('<p class="lead">El sistema recomienda cursos universitarios a un estudiante '
      'a partir de sus intereses, sus cursos aprobados, su horario disponible, su tolerancia '
      'a la dificultad y su area profesional objetivo, y <strong>explica</strong> cada '
      'recomendacion enumerando las reglas que la produjeron. Ademas entrega estadisticas '
      'del estudiante y del catalogo.</p>')
    doc.append('<p>El valor del proyecto no esta en ordenar una lista de cursos: eso se resolveria '
      'con un filtro y un ordenamiento en unas pocas lineas. Está en que un <strong>motor de '
      'inferencia propio</strong>, con reglas declarativas y trazabilidad completa, produce y '
      'justifica la recomendacion. Esa distincion gobierna todas las decisiones de diseno que '
      'siguen.</p>')
    doc.append('<div class="note"><strong>Criterio de diseno dominante.</strong> El conocimiento '
      'academico vive fuera del programa: son datos que el motor interpreta. Agregar conocimiento '
      'nuevo significa agregar una regla, nunca modificar el motor. Una prueba automatizada '
      'verifica exactamente eso.</div>')

    doc.append('<h3>Alcance</h3>')
    doc.append('<table><tr><th style="width:50%">Incluido</th><th>Excluido deliberadamente</th></tr>'
      '<tr><td>Motor de encadenamiento hacia adelante escrito desde cero</td>'
      '<td>Librerias de reglas (LISA, CLIPS)</td></tr>'
      '<tr><td>Base de conocimiento auditable en texto</td><td>Aprendizaje automatico</td></tr>'
      '<tr><td>Recomendaciones con explicacion trazable</td><td>Interfaz web o grafica</td></tr>'
      '<tr><td>Estadisticas de estudiante y de catalogo</td><td>Matricula real o conexion a la universidad</td></tr>'
      '<tr><td>Interfaz de linea de comandos interactiva</td><td>Horarios con hora exacta y traslapes parciales</td></tr>'
      '</table>')

    # 2
    doc.append('<h2 class="pb">2. Arquitectura general</h2>')
    doc.append('<h3>2.1 Division en capas</h3>')
    doc.append('<p>El sistema se divide en tres capas con dependencias en una sola direccion. '
      'Cada una tiene una responsabilidad que las otras no pueden asumir.</p>')
    doc.append(SVG_LAYERS)

    doc.append('<h3>2.2 Invariante de dependencias</h3>')
    doc.append('<p>Las flechas apuntan siempre hacia abajo. La regla que sostiene todo el diseno '
      'es la del motor:</p>')
    doc.append('<div class="ok"><strong>El motor no puede saber que es un curso.</strong> '
      'Ningun archivo de <code>src/engine/</code> menciona un simbolo del dominio academico. '
      'Su suite de pruebas opera exclusivamente con hechos inventados como '
      '<code>(color rojo)</code>. Si el motor necesitara conocer el dominio para pasar sus '
      'pruebas, dejaria de ser un motor y seria un programa de recomendacion disfrazado.</div>')
    doc.append('<table><tr><th>Capa</th><th>Puede usar</th><th>Tiene prohibido</th></tr>'
      '<tr><td><code>cli/</code></td><td>El dominio</td><td>Decidir nada; solo pregunta y presenta</td></tr>'
      '<tr><td><code>domain/</code></td><td>El motor</td><td>Entrada/salida; <code>format t</code> fuera de la CLI</td></tr>'
      '<tr><td><code>engine/</code></td><td>Solo Common Lisp</td><td>Cualquier simbolo del dominio academico</td></tr>'
      '</table>')

    doc.append('<h3>2.3 Estructura de archivos</h3>')
    doc.append('''<pre>src/
  package.lisp          Los tres paquetes y sus exportaciones
  engine/               MOTOR GENERICO
    facts.lisp          Memoria de trabajo, hechos con id monotono
    matching.lisp       Unificacion de patrones con variables
    rules.lisp          Macro DEFRULE y registro de reglas
    agenda.lisp         Conjunto de conflicto, resolucion, refraccion
    inference.lisp      Ciclo match-select-act, quiescencia, traza
  domain/               CONOCIMIENTO ACADEMICO
    loader.lisp         Carga y validacion de data/
    knowledge.lisp      Las 25 reglas + post-procesamiento
    explain.lisp        Explicaciones reconstruidas desde la traza
    stats.lisp          Estadisticas de estudiante y de catalogo
  cli/                  PRESENTACION
    format.lisp         Todo el texto que ve el usuario
    session.lisp        Captura interactiva y flujo de sesion
  main.lisp             Punto de entrada

data/
  courses.lisp          Catalogo de 47 cursos (datos, no codigo)
  profiles/             Cinco perfiles de demostracion

tests/                  Espejo de src/ + suite de aceptacion</pre>''')

    # 3
    doc.append('<h2 class="pb">3. Flujo de una sesion completa</h2>')
    doc.append('<p>Desde que el estudiante responde la primera pregunta hasta que ve el informe, '
      'el recorrido es el siguiente. Notese que el motor corre una sola vez, hasta agotar todo '
      'lo que puede concluir.</p>')
    doc.append(SVG_FLOW)
    doc.append('<div class="note"><strong>Por que hay post-procesamiento despues del motor.</strong> '
      'Dos reglas &#8212; el tope de creditos (BR-004) y el limite de una electiva por bloque '
      '(BR-008) &#8212; comparan entre si un conjunto de tamano variable. El matching por patrones '
      'posicionales tiene aridad fija y no expresa esa clase de agregacion, asi que se implementan '
      'como funciones de dominio que corren tras la quiescencia. Es una limitacion conocida del '
      'modelo de matching, documentada, no un atajo.</div>')

    # 4
    doc.append('<h2 class="pb">4. El motor de inferencia</h2>')
    doc.append('<p>Es un motor de produccion con <strong>encadenamiento hacia adelante</strong>: '
      'parte de los datos y deriva conclusiones, en vez de partir de una meta e intentar probarla. '
      'Se eligio asi porque la tarea real es "dame todos los cursos que me convienen", que en '
      'encadenamiento hacia atras obligaria a probar la meta una vez por cada curso del catalogo.</p>')

    doc.append('<h3>4.1 Ciclo match &#8594; select &#8594; act</h3>')
    doc.append('<table><tr><th style="width:16%">Fase</th><th>Que hace</th></tr>'
      '<tr><td><strong>MATCH</strong></td><td>Evalua las condiciones de todas las reglas contra la '
      'memoria de trabajo y construye el conjunto de conflicto: todas las instanciaciones aplicables.</td></tr>'
      '<tr><td><strong>SELECT</strong></td><td>Ordena el conjunto de conflicto y elige una sola '
      'instanciacion, descartando las ya disparadas.</td></tr>'
      '<tr><td><strong>ACT</strong></td><td>Afirma los hechos de la parte <code>:then</code> con las '
      'variables sustituidas, y registra el disparo en la traza.</td></tr></table>')

    doc.append('<h3>4.2 Resolucion de conflictos</h3>')
    doc.append('<p>Cuando varias reglas pueden dispararse, el motor elige de forma '
      '<strong>determinista</strong>, en este orden:</p>')
    doc.append('<table><tr><th style="width:8%">#</th><th style="width:28%">Criterio</th><th>Justificacion</th></tr>'
      '<tr><td>1</td><td>Mayor prioridad de la regla</td><td>Permite ordenar por franjas: una franja '
      'completa se agota antes de que empiece la siguiente</td></tr>'
      '<tr><td>2</td><td>Hecho mas reciente</td><td>Medido por el id de insercion monotono de la memoria de trabajo</td></tr>'
      '<tr><td>3</td><td>Orden de declaracion</td><td>Desempate final: garantiza que la misma entrada '
      'produzca siempre la misma traza</td></tr></table>')
    doc.append('<div class="note"><strong>Por que las prioridades van de 5 en 5.</strong> Cuando una regla '
      'niega un hecho que <em>otra regla</em> deriva, esa otra debe haber disparado ya en todos los cursos, '
      'o la negacion daria un falso positivo en un ciclo temprano. Las franjas 40, 35, 30, 25, 20, 15 y 10 '
      'garantizan ese agotamiento por niveles.</div>')

    doc.append('<h3>4.3 Refraccion y terminacion</h3>')
    doc.append('<p>Una misma instanciacion &#8212; la misma regla con las mismas ligaduras &#8212; no vuelve '
      'a dispararse. Sin refraccion, una regla que afirma un hecho que vuelve a satisfacer su propia '
      'condicion haria que el motor no terminara nunca. Existe ademas un tope de seguridad de 1000 ciclos '
      'que senala una advertencia si se alcanza; la demostracion completa usa alrededor de 295.</p>')

    doc.append('<h3>4.4 La traza</h3>')
    doc.append('<p>Cada disparo registra la regla, las ligaduras, los hechos que la activaron y los hechos '
      'que produjo. <strong>La explicacion al estudiante no se escribe a mano: se reconstruye recorriendo '
      'esta traza</strong> hacia atras desde el hecho <code>(recommended ?id)</code>. Por eso la explicacion '
      'refleja el razonamiento real y no una narracion paralela que podria desincronizarse.</p>')

    # 5
    doc.append('<h2 class="pb">5. Modelo de conocimiento</h2>')
    doc.append('<h3>5.1 Las tres capas de hechos</h3>')
    doc.append('<p>Todo lo que el motor conoce es un hecho: una lista plana cuyo primer elemento nombra '
      'la relacion. No hay marca que diga si un hecho es dato de entrada o conclusion; la distinción está '
      'en <em>qué relación se usa</em> y <em>quién puede afirmarla</em>. Esa disciplina es lo que hace '
      'legible la traza.</p>')
    doc.append(SVG_FACTS)
    doc.append('<div class="warn"><strong>Invariante.</strong> Ninguna regla puede afirmar una relacion de '
      'la capa de catalogo o de la capa de perfil. Si una regla lo necesitara, el modelo de datos estaria '
      'mal planteado y habria que revisarlo antes de escribir codigo.</div>')

    doc.append('<h3>5.2 Catalogo de relaciones</h3>')
    doc.append('<table><tr><th style="width:34%">Relacion</th><th style="width:14%">Capa</th><th>Significado</th></tr>'
      '<tr><td><code>(course id)</code></td><td>Catalogo</td><td>Existencia de un curso</td></tr>'
      '<tr><td><code>(course-name id nombre)</code></td><td>Catalogo</td><td>Nombre legible; ninguna regla condiciona sobre el</td></tr>'
      '<tr><td><code>(term id n)</code></td><td>Catalogo</td><td>Cuatrimestre del plan (1&#8211;8)</td></tr>'
      '<tr><td><code>(credits id n)</code></td><td>Catalogo</td><td>Creditos del curso</td></tr>'
      '<tr><td><code>(area id area)</code></td><td>Catalogo</td><td>Area profesional</td></tr>'
      '<tr><td><code>(difficulty id n)</code></td><td>Catalogo</td><td>Dificultad en escala 1&#8211;5</td></tr>'
      '<tr><td><code>(prerequisite id req)</code></td><td>Catalogo</td><td>Un hecho por requisito; nunca listas anidadas</td></tr>'
      '<tr><td><code>(schedule id dia franja)</code></td><td>Catalogo</td><td>Un hecho por bloque de horario</td></tr>'
      '<tr><td><code>(elective id grupo)</code></td><td>Catalogo</td><td>Bloque electivo al que pertenece</td></tr>'
      '<tr><td><code>(approved id)</code></td><td>Perfil</td><td>Curso ya ganado por el estudiante</td></tr>'
      '<tr><td><code>(interest area)</code></td><td>Perfil</td><td>Area que le atrae; puede haber varias</td></tr>'
      '<tr><td><code>(target-area area)</code></td><td>Perfil</td><td>Area profesional objetivo; exactamente una</td></tr>'
      '<tr><td><code>(available dia franja)</code></td><td>Perfil</td><td>Bloque en que puede llevar clases</td></tr>'
      '<tr><td><code>(difficulty-tolerance n)</code></td><td>Perfil</td><td>Umbral de dificultad declarado</td></tr>'
      '<tr><td><code>(credit-limit n)</code></td><td>Perfil</td><td>Tope de creditos del semestre</td></tr>'
      '<tr><td><code>(eligible id)</code></td><td>Derivada</td><td>Puede llevarlo: requisitos, horario y no aprobado</td></tr>'
      '<tr><td><code>(bottleneck id n)</code></td><td>Derivada</td><td>Es requisito de n cursos</td></tr>'
      '<tr><td><code>(priority id n)</code></td><td>Derivada</td><td>Puntaje acumulativo: varias reglas suman</td></tr>'
      '<tr><td><code>(recommended id)</code></td><td>Derivada</td><td>Se le presenta al estudiante</td></tr>'
      '<tr><td><code>(excluded id razon)</code></td><td>Derivada</td><td>Descartado, con el motivo explicito</td></tr>'
      '</table>')

    doc.append('<h3>5.3 Reglas de modelado</h3>')
    doc.append('<table><tr><th style="width:6%">#</th><th style="width:28%">Regla</th><th>Por que</th></tr>'
      '<tr><td>1</td><td>Aridad fija</td><td>Una relacion tiene siempre el mismo numero de argumentos</td></tr>'
      '<tr><td>2</td><td>Sin anidamiento</td><td>Ningun argumento es una lista; se repite el hecho. Mantiene el matcher simple</td></tr>'
      '<tr><td>3</td><td>Identificadores string, categorias simbolo</td><td>Los codigos se comparan con <code>equal</code>; las categorias con <code>eq</code></td></tr>'
      '<tr><td>4</td><td>Sin negacion en los hechos</td><td>No existe <code>(not-approved id)</code>; la ausencia se expresa en las condiciones</td></tr>'
      '<tr><td>5</td><td>Una relacion, un significado</td><td>Un matiz nuevo es una relacion nueva, no un argumento extra</td></tr>'
      '</table>')

    # 6
    doc.append('<h2 class="pb">6. Reglas implementadas</h2>')
    doc.append('<p>Las <strong>%d reglas</strong> que siguen se extrajeron del sistema en ejecucion, no se '
      'transcribieron a mano: el documento se genera leyendo las estructuras que el motor tiene cargadas, '
      'de modo que no puede desfasarse del codigo. Cada una se declara con la macro <code>defrule</code> y '
      'es una estructura de datos inspeccionable, no codigo ejecutable.</p>' % len(RULES))
    doc.append('<pre class="code">(engine:defrule <span class="kw">nombre-de-la-regla</span>\n'
      '  "Docstring que cita el BR que implementa."\n'
      '  <span class="kw">:priority</span> 30\n'
      '  <span class="kw">:when</span> ((course ?id) (not (approved ?id)))\n'
      '  <span class="kw">:then</span> ((eligible ?id)))</pre>')
    doc.append(r_html)

    # 7
    doc.append('<h2 class="pb">7. Reglas de negocio y su trazabilidad</h2>')
    doc.append('<p>El conocimiento experto se especifica primero en lenguaje natural, con un identificador '
      'BR, y despues se implementa. Cada <code>defrule</code> cita en su docstring el BR que implementa, de '
      'modo que la especificacion y el codigo se pueden confrontar en cualquier momento.</p>')
    doc.append('<table><tr><th style="width:10%">BR</th><th style="width:13%">Categoria</th><th>Descripcion</th></tr>'
      '<tr><td>BR-001</td><td>Dura</td><td>Un curso es elegible solo si <em>todos</em> sus requisitos estan aprobados</td></tr>'
      '<tr><td>BR-002</td><td>Dura</td><td>Nunca se recomienda un curso ya aprobado</td></tr>'
      '<tr><td>BR-003</td><td>Dura</td><td>Todos los bloques de horario del curso deben caber en la disponibilidad declarada</td></tr>'
      '<tr><td>BR-004</td><td>Dura</td><td>La suma de creditos recomendados no excede el tope del estudiante</td></tr>'
      '<tr><td>BR-005</td><td>Estandar</td><td>No se recomienda un curso que excede la tolerancia a la dificultad</td></tr>'
      '<tr><td>BR-006</td><td>Estandar</td><td>Un curso es cuello de botella si es requisito de 3 o mas cursos</td></tr>'
      '<tr><td>BR-007</td><td>Estandar</td><td>De elegible a recomendado hace falta prioridad acumulada positiva</td></tr>'
      '<tr><td>BR-008</td><td>Dura</td><td>De un mismo bloque electivo se conserva solo el de mayor prioridad</td></tr>'
      '<tr><td>BR-010</td><td>Blanda</td><td>El area del curso es el area objetivo: <strong>+10</strong></td></tr>'
      '<tr><td>BR-011</td><td>Blanda</td><td>El area esta entre los intereses declarados: <strong>+5</strong></td></tr>'
      '<tr><td>BR-012</td><td>Blanda</td><td>El curso es cuello de botella: <strong>+8</strong></td></tr>'
      '<tr><td>BR-013</td><td>Blanda</td><td>Desbloquea un curso del area objetivo: <strong>+4</strong></td></tr>'
      '<tr><td>BR-014</td><td>Blanda</td><td>Muy por debajo de la tolerancia: <strong>&#8722;2</strong></td></tr>'
      '<tr><td>BR-015</td><td>Blanda</td><td>Curso de formacion general: <strong>+3</strong></td></tr>'
      '<tr><td>BR-020</td><td>Dura</td><td>Toda recomendacion debe tener explicacion no vacia</td></tr>'
      '<tr><td>BR-021</td><td>Estandar</td><td>Toda exclusion se acompana de su motivo</td></tr>'
      '<tr><td>BR-030</td><td>Dura</td><td>Las estadisticas se derivan de la memoria de trabajo, nunca de una consulta aparte</td></tr>'
      '<tr><td>BR-031</td><td>Estandar</td><td>Avance de carrera: creditos aprobados sobre creditos totales del catalogo</td></tr>'
      '</table>')
    doc.append('<div class="note"><strong>La excepcion de BR-005.</strong> Un curso cuello de botella que '
      'excede la tolerancia <em>por un solo nivel</em> se recomienda igual, marcado con advertencia: '
      'atrasarlo cuesta mas que llevarlo. Es el caso mas interesante del sistema porque muestra '
      'conocimiento experto real &#8212; una excepcion con criterio, no un filtro rigido.</div>')

    # 8
    doc.append('<h2 class="pb">8. Ejemplos implementados</h2>')
    doc.append('<h3>8.1 Los cinco perfiles</h3>')
    doc.append('<p>Cada perfil de <code>data/profiles/</code> existe para ejercitar un comportamiento '
      'distinto del sistema, no para llenar. En conjunto activan las seis razones de descarte y las '
      'reglas de excepcion.</p>')
    doc.append('<table><tr><th style="width:22%">Perfil</th><th style="width:30%">Que representa</th><th>Que demuestra</th></tr>'
      '<tr><td><code>sample-profile</code></td><td>Estudiante de segundo cuatrimestre</td>'
      '<td>Las <strong>seis</strong> razones de descarte en una sola corrida</td></tr>'
      '<tr><td><code>first-year</code></td><td>Primer ingreso, sin cursos aprobados</td>'
      '<td>Solo recomienda cursos sin requisitos; avance de carrera en 0&#160;%</td></tr>'
      '<tr><td><code>advanced</code></td><td>Estudiante avanzado</td>'
      '<td>Avance alto y activacion de las reglas de formacion general</td></tr>'
      '<tr><td><code>tight-schedule</code></td><td>Disponibilidad muy restringida</td>'
      '<td>El horario como filtro dominante (BR-003)</td></tr>'
      '<tr><td><code>low-tolerance</code></td><td>Tolerancia a la dificultad baja</td>'
      '<td>La <strong>excepcion de BR-005</strong>: cuello de botella recomendado con advertencia</td></tr>'
      '</table>')

    doc.append('<h3>8.2 Salida real del sistema</h3>')
    doc.append('<p>Lo que sigue es salida literal de <code>data/profiles/low-tolerance.lisp</code>, sin editar. '
      'Es el caso mas ilustrativo: el sistema recomienda un curso que <em>excede</em> la tolerancia declarada '
      'y explica por que lo hace igual.</p>')
    doc.append('<pre>%s</pre>' % html.escape(sample(out_low, "RECOMENDACIONES", 16)))

    doc.append('<h3>8.3 Explicacion reconstruida</h3>')
    doc.append('<p>Las lineas de "Razones" y "Advertencias" no son texto fijo: cada una corresponde a una '
      'regla que efectivamente disparo sobre ese curso, recuperada de la traza. El puntaje 22 es la suma '
      'de los aportes de BR-012 (+8), BR-010 (+10) y BR-013 (+4), y cada sumando se puede rastrear hasta '
      'la regla que lo produjo.</p>')
    doc.append('<p>Los descartes tambien se explican, con su motivo del vocabulario cerrado:</p>')
    doc.append('<pre>%s</pre>' % html.escape(sample(out_low, "CURSOS DESCARTADOS", 9)))

    doc.append('<h3>8.4 Traza del motor</h3>')
    doc.append('<p>El sistema puede mostrar el ciclo de inferencia completo, disparo por disparo. Esta es '
      'la evidencia de que existe un motor real y no logica cableada:</p>')
    doc.append('<pre>%s</pre>' % html.escape(sample(out_low, "TRAZA DEL MOTOR", 12)))

    # 9
    doc.append('<h2 class="pb">9. Estadisticas producidas</h2>')
    doc.append('<p>Se calculan dos familias, ambas <strong>derivadas de la memoria de trabajo final</strong> '
      '(BR-030). No se consulta el catalogo por aparte, de modo que las cifras nunca pueden contradecir lo '
      'que el motor concluyo.</p>')
    doc.append('<table><tr><th style="width:33%">Del estudiante</th><th>Del catalogo y la base de conocimiento</th></tr>'
      '<tr><td>Avance de carrera (BR-031)</td><td>Cursos mas recomendados entre perfiles</td></tr>'
      '<tr><td>Creditos aprobados frente al total</td><td>Cursos cuello de botella, con cuantos desbloquean</td></tr>'
      '<tr><td>Distribucion de aprobados por area</td><td>Dificultad promedio por area</td></tr>'
      '<tr><td>Cursos evaluados, elegibles y descartados por motivo</td><td>Cobertura de reglas</td></tr>'
      '<tr><td>Carga estimada del semestre propuesto</td><td>&#160;</td></tr></table>')
    doc.append('<div class="ok"><strong>La cobertura de reglas es una herramienta de diagnostico, no un adorno.</strong> '
      'Indica cuales de las 25 reglas nunca dispararon en una corrida. Una regla que jamas se activa es, o bien '
      'conocimiento muerto que sobra, o bien senal de que los datos no la ejercitan. En ambos casos es algo que '
      'hay que mirar.</div>')
    doc.append('<pre>%s</pre>' % html.escape(sample(out_adv, "  Cobertura de reglas", 7)))

    # 10
    doc.append('<h2 class="pb">10. Verificacion y criterios de aceptacion</h2>')
    doc.append('<p>El sistema se verifica con <strong>358 comprobaciones automatizadas</strong>. El gate de '
      'verificacion compila el sistema completo con ASDF en orden de dependencias y corre la suite; termina '
      'imprimiendo un veredicto legible por maquina.</p>')
    doc.append('<pre>$ sh .ace/scripts/verify.sh\n[ok] Gate \'test\' passed.\nAll configured gates passed.\n'
      'VERIFY_RESULT=pass gate=all\n\n$ sbcl --script run-tests.lisp\nDid 358 checks.\n'
      '   Pass: 358 (100%)\n   Skip: 0 ( 0%)\n   Fail: 0 ( 0%)</pre>')
    doc.append('<p>Los diez criterios de aceptacion del sistema se verifican en una suite dedicada:</p>')
    doc.append('<table><tr><th style="width:6%">#</th><th>Criterio</th></tr>'
      '<tr><td>1</td><td>Ninguna recomendacion viola un requisito, en ningun perfil</td></tr>'
      '<tr><td>2</td><td>Ninguna recomendacion choca con el horario declarado</td></tr>'
      '<tr><td>3</td><td>Toda recomendacion tiene explicacion no vacia (BR-020)</td></tr>'
      '<tr><td>4</td><td>El motor es generico: su suite no usa ningun simbolo del dominio</td></tr>'
      '<tr><td>5</td><td>Se puede agregar una regla en tiempo de ejecucion sin tocar el motor</td></tr>'
      '<tr><td>6</td><td>El motor siempre termina, incluso con una regla que se reactiva a si misma</td></tr>'
      '<tr><td>7</td><td>Misma entrada, misma salida: traza identica en corridas repetidas</td></tr>'
      '<tr><td>8</td><td>El catalogo tiene entre 40 y 60 cursos</td></tr>'
      '<tr><td>9</td><td>Ambas familias de estadisticas estan presentes</td></tr>'
      '<tr><td>10</td><td>Una sesion completa corre en menos de dos segundos (medido: 0,3 s)</td></tr>'
      '</table>')
    doc.append('<div class="note"><strong>Los criterios 4 y 5 son los que sostienen la tesis del proyecto.</strong> '
      'El 4 demuestra que el motor es independiente del dominio; el 5, que el conocimiento se agrega como datos. '
      'Si alguno fallara, el sistema habria dejado de ser un sistema experto aunque siguiera dando buenas '
      'recomendaciones.</div>')

    # 11
    doc.append('<h2 class="pb">11. Limitaciones y procedencia de los datos</h2>')
    doc.append('<p>Esta seccion existe porque presentar datos provisionales como si fueran oficiales '
      'invalidaria el trabajo. El programa academico suministrado por la universidad aporta solo una parte '
      'de lo que el motor necesita para razonar.</p>')
    doc.append('<table><tr><th style="width:30%">Campo</th><th style="width:16%">Origen</th><th>Detalle</th></tr>'
      '<tr><td>Codigo, nombre, cuatrimestre</td><td><strong>Oficial</strong></td><td>Tal como lo entrego la universidad</td></tr>'
      '<tr><td>Laboratorio, curso colegiado</td><td><strong>Oficial</strong></td><td>Indicadores del programa</td></tr>'
      '<tr><td>Bloque electivo</td><td><strong>Oficial</strong></td><td>El programa organiza las electivas en tres bloques</td></tr>'
      '<tr><td>Creditos</td><td>Provisional</td><td>Valor uniforme de 4; el programa no los declara</td></tr>'
      '<tr><td>Dificultad</td><td>Provisional</td><td>Formula: cuatrimestre, mas 1 si tiene laboratorio, tope 5</td></tr>'
      '<tr><td>Area profesional</td><td>Provisional</td><td>Inferida por el equipo del nombre del curso</td></tr>'
      '<tr><td>Horario</td><td>Provisional</td><td>Un bloque por curso, asignado por rotacion</td></tr>'
      '<tr><td>Prerrequisitos</td><td>Provisional</td><td>Seis enlaces de demostracion; el programa no declara ninguno</td></tr>'
      '</table>')
    doc.append('<div class="warn"><strong>Consecuencia que debe declararse al presentar el sistema.</strong> '
      'Los cuellos de botella que el sistema reporta son <em>correctos dado el grafo de requisitos cargado</em>, '
      'y ese grafo es de ejemplo. El razonamiento del motor es real y verificable; los datos de entrada son '
      'parciales. Si aparecieran los prerrequisitos oficiales, incorporarlos es un cambio en '
      '<code>data/</code> y <strong>cero lineas de codigo</strong>: la arquitectura mantiene los datos fuera '
      'del programa precisamente para eso.</div>')
    doc.append('<h3>Otras limitaciones conocidas</h3>')
    doc.append('<table><tr><th style="width:34%">Limitacion</th><th>Alcance</th></tr>'
      '<tr><td>Matching sin red RETE</td><td>El conjunto de conflicto se reconstruye entero en cada ciclo. Mitigado con un indice de hechos por relacion: sin el, cada condicion intentaba unificar contra los ~680 hechos de la sesion en vez de las decenas de su relacion, y una sesion pasaba de 0,3 s a mas de 3 s</td></tr>'
      '<tr><td>Horarios por bloques discretos</td><td>No modela traslapes parciales ni horas exactas</td></tr>'
      '<tr><td>Solo Bachillerato</td><td>El catalogo no cubre las licenciaturas</td></tr>'
      '<tr><td>Agregaciones fuera del motor</td><td>BR-004 y BR-008 corren como post-procesamiento</td></tr>'
      '<tr><td>Traza extensa</td><td>Cerca de 295 lineas en una corrida completa; no hay vista resumida</td></tr>'
      '</table>')

    doc.append('<p class="small" style="margin-top:26px;border-top:1px solid #e2e8f0;padding-top:9px">'
      'Documento generado a partir del codigo fuente del sistema. Las %d reglas de la seccion 6 se '
      'extrajeron del motor en ejecucion; las salidas de la seccion 8 son literales, sin editar. '
      'Repositorio: github.com/Wardaddy118/Expert_System_Lisp</p>' % len(RULES))

    return ('<!doctype html><html lang="es"><head><meta charset="utf-8">'
            '<title>Diseno y Arquitectura</title><style>%s</style></head><body>%s</body></html>'
            % (CSS, "\n".join(doc)))

path = os.path.join(ROOT, "docs", "DISENO-Y-ARQUITECTURA.html")
io.open(path, "w", encoding="utf-8").write(fix_html(build()))
print("HTML generado con %d reglas -> %s" % (len(RULES), path))
