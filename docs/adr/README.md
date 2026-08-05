# Registro de Decisiones de Arquitectura (ADR)

## Numeración

Los ADR de este repositorio arrancan en **ADR-004**. Las tres primeras
posiciones vienen del framework ACE y se conservan sin renumerar para no
romper las referencias cruzadas de `.ace/`:

| ADR | Origen | Tema |
| --- | ------ | ---- |
| ADR-001 | ACE Framework | Adopción del framework ACE en el proyecto |
| ADR-002 | ACE Framework | Interfaz de adaptadores del runner del loop |
| ADR-003 | ACE Framework | Política de promoción de reglas destiladas |
| **ADR-004** | **Proyecto** | **Stack tecnológico: SBCL, ASDF, Quicklisp, FiveAM** |
| **ADR-005** | **Proyecto** | **Motor de inferencia propio con encadenamiento hacia adelante** |
| **ADR-006** | **Proyecto** | **Representación del conocimiento: hechos, reglas y catálogo** |

Al evaluar el proyecto, los ADR relevantes al sistema experto son del **004 en
adelante**. Los tres primeros documentan el andamiaje de trabajo, no el
producto.

## Cómo agregar uno

1. Copiar `ADR-000-template.md` al siguiente número libre.
2. Nombrar el archivo `ADR-NNN-tema-en-kebab-case.md`.
3. Registrarlo en la tabla de arriba.
4. Enlazarlo desde `docs/context/PROJECT_CONTEXT.md` si cambia una decisión de
   la fase DISCUSS.

Un ADR se escribe cuando la decisión es difícil de revertir, afecta a varios
módulos, o alguien razonablemente preguntaría después "¿por qué lo hicieron
así?".
