# Mantrailing Training Sessions — Kocher Method (Curso Flash)

## Overview

This directory contains mantrailing training session documents following the **Kevin Kocher Positive Trailing Method**. Each session includes detailed ASCII diagrams, step-by-step procedures, expected behaviors, progressions, and method-specific notes.

All sessions are bilingual: Spanish (primary) + English translation.

---

## Document Creation Rules

### Language & Naming

- **Spanish files**: `sesion_XX_<nombre_descriptivo>.md`
- **English files**: `session_XX_<descriptive_name>_EN.md`
- Always create BOTH versions simultaneously
- Spanish is the primary language; English is a faithful translation (not a rewrite)

### Mandatory Sections (in order)

Every session file MUST include ALL of the following sections:

```
# Sesión XX — [Título descriptivo] (Método Kocher)

## Información General
- Nivel: [Iniciación / Intermedio / Intermedio-Avanzado / Avanzado]
- Método: Kevin Kocher (Trailing Positivo)
- Duración estimada: XX-XX minutos por binomio
- Objetivo principal: [1-2 frases]

## Fundamentos del Ejercicio / Habilidades Entrenadas
- Numbered list of WHY this exercise matters
- Each point is a specific skill being trained

## Condiciones Ambientales (if relevant)
- Wind, rain, terrain type, temperature — if it's a factor, document it
- Include diagram showing how conditions affect scent behavior

## Material Necesario
- Bullet list of required equipment

## Localización: [Descripción del recorrido]

### Diagrama General — Vista Completa
### [Detail diagrams — one per key area]
### Recorrido Completo con Distancias

## Procedimiento
### Fase 0: Preparación
### Fase 1-N: [Step by step with diagrams]

## Tabla de Comportamiento Esperado
- Table: Punto | Comportamiento Esperado | Si No Ocurre

## Progresión
- Table: Sesión | Distancias | Dificultad Añadida

## Notas Método Kocher
- Bullet list of method-specific principles for this exercise
```

### Diagram Style Guide

Diagrams are the MOST IMPORTANT part of each document. Follow these rules exactly:

#### General Diagram Rules

- Use ASCII art with box-drawing characters: `═ ║ ╔ ╗ ╚ ╝ ╠ ╣ ╬ ┌ ┐ └ ┘ ├ ┤ ┬ ┴ ┼ │ ─`
- Use block characters for walls/buildings: `██ ▓▓ ████`
- Use emoji for key elements: `🐕 👨 👤 🚗 👃 🌳 🌿 💨 🚪`
- Every diagram is inside a markdown code block (```)
- Every diagram has a TITLE in CAPS at the top
- Include directional arrows: `← → ↑ ↓ ╱ ╲`
- Trail paths use dashes: `─ ─ ─ ─` or arrows: `→ → → →`
- Mark key decision/action points with: `★ ● ✅ ❌`

#### Required Diagram Types

Each session MUST include:

1. **Vista Completa (Full View)**: Shows the entire scenario from start to finish. Large diagram with all elements. Use `╔══╗` frame.

2. **Detalle por Zona (Zone Details)**: One zoomed-in diagram per distinct area (start point, obstacle, hide location, etc.). Use `┌──┐` frame.

3. **Vista Aérea / Cenital (Aerial/Top-Down View)**: Bird's eye view showing spatial relationships and distances.

4. **Diagrama de Comportamiento (Behavior Diagram)**: Tree-style diagram showing expected dog behavior sequence at key moments. Uses `├─` tree notation.

5. **Diagrama de Distancias (Distance Diagram)**: Linear scale showing route segments and total distances.

6. **Diagrama de Condiciones (Conditions Diagram)**: If environmental factors (wind, terrain) affect the exercise, show HOW they affect scent behavior visually.

#### Diagram Sizing

- Full view diagrams: 60-70 characters wide
- Detail diagrams: 40-60 characters wide
- Behavior trees: indented with `├─` notation, unlimited depth
- Always include distance annotations (meters)
- Always label cardinal directions or relative directions (left/right)

#### Building/Structure Representation

```
Industrial warehouse:     ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
                          ▓▓  ALMACÉN     ▓▓
                          ▓▓  INDUSTRIAL  ▓▓
                          ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓

Walls/fences:             ████████████████████

Corridor:                 ══════╪══════
                          ║ CORREDOR  ║
                          ══════╪══════

Door in fence:            ████[🚪 PUERTA]████

Low brick wall:           █████│████████████
                               │  MURO BAJO
                          █████│████████████
```

#### Scent Representation

```
Scent trail:              ─ ─ ─ ─ rastro ─ ─ ─ ─
Scent article:            [👃] INICIO
Scent cone (clean):       ●──── cono limpio
Scent cone (wind):        ●  ╲╲╲╲ olor arrastrado
Scent loss point:         ★ PUNTO DE SALTO / PÉRDIDA
Overlap zone:             ╱╱╱╱ ZONA SOLAPAMIENTO ╱╱╱╱
```

#### Key Moment Indicators

```
Correct target:           ✅ CORRECTO
Wrong target:             ❌ INCORRECTO
Critical action:          ★ MARCAJE ★
Dog marks here:           ★ PUNTO DE MARCAJE ★
Start point:              (S) ● INICIO
Split/decision point:     ● BIFURCACIÓN
```

### Kocher Method Principles (Always Apply)

These principles MUST be reflected in every session document:

1. **Trailing Positivo**: The dog learns that following a specific scent leads to a reward
2. **Sin correcciones**: The dog is NEVER corrected during work
3. **Éxito garantizado**: Every trail must end in success
4. **Recompensa inmediata**: The figurant is the direct source of reward
5. **Motivación intrínseca**: The dog works by its own will, not obedience
6. **El figurante ES la recompensa**: The figurant is the reward itself, not just the deliverer
7. **El guía sigue al perro**: The handler follows the dog, doesn't direct it
8. **Línea suelta SIEMPRE**: Loose line always, even if the dog seems lost

### Procedure Diagrams

Use tree-notation for all procedure sequences:

```
FIGURANTE A                          GUÍA + PERRO
    │                                     │
    ├─ Action description                ├─ Action description
    │  (detail in parentheses)            │  (detail)
    │                                     │
    ├─ Next action                       ├─ Next action
    │                                     │
    └─ Final action                      └─ Final action
```

### Behavior Tables

Always use this exact format:

```
| Punto | Comportamiento Esperado | Si No Ocurre |
|---|---|---|
| [Location] | [Expected] | [Corrective action with arrow →] |
```

### Progression Tables

Always use this exact format:

```
| Sesión | [Key distance] | [Key variable] | Dificultad Añadida |
|---|---|---|---|
| Primera vez | [easier] | [easier] | Ninguna |
| Repetición 2 | [standard] | [standard] | Estándar (esta sesión) |
| Repetición 3 | [harder] | [harder] | [specific challenge] |
| Repetición 4 | [hardest] | [hardest] | [operational conditions] |
```

---

## Session Numbering

Sessions are numbered sequentially. Current sessions:

| # | Spanish | English | Key Challenge |
|---|---|---|---|
| 01 | Doble figurante bifurcación | Dual figurant split | Scent discrimination at split + wind |
| 02 | Puerta valla figurante oculto | Fence door concealed figurant | Door marking + ground-level camouflaged find |
| 03 | Muro bajo salto pérdida rastro | Low wall jump scent loss | Jump point marking + scent loss communication |

Next session should be numbered `04`.
