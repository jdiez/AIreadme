# Sesion 04 — Retroceso en Cuadricula Urbana (Metodo Kocher)

## Informacion General

**Nivel:** Intermedio-Avanzado

**Metodo:** Kevin Kocher (Trailing Positivo)

**Duracion estimada:** 35-45 minutos por binomio

**Objetivo principal:** El perro sigue un rastro con **retroceso** (backtrack) en un barrio con patron de cuadricula. El figurante camina por la Calle Principal, pasa Calle A, continua hacia Calle B, retrocede hasta Calle A (zona de solapamiento entre Calle A y Calle B), gira en Calle A, toma Calle C (que une Calle A y Calle B) y gira de nuevo en Calle B donde se oculta — obligando al perro a resolver la zona de doble olor y tres giros consecutivos.

---

## Habilidades Entrenadas

1. **Discriminacion de direccion en backtrack**: El perro debe determinar en que sentido fue recorrido el rastro cuando las huellas de ida y vuelta se solapan entre Calle A y Calle B
2. **Gestion de zona de solapamiento**: El tramo de Calle Principal entre Calle A y Calle B tiene doble capa de olor — el perro debe resolver la ambiguedad
3. **Toma de decision en cruces multiples**: El perro debe resolver tres giros consecutivos (Calle A, Calle C, Calle B)
4. **Trabajo urbano en cuadricula**: Calles perpendiculares con multiples opciones de direccion
5. **Confianza del guia en el proceso**: El guia vera al perro dudar en la zona de solapamiento — debe esperar sin intervenir

---

## Condiciones Ambientales

| Condicion | Detalle |
|---|---|
| **Terreno** | Barrio residencial con patron de cuadricula — calles perpendiculares |
| **Superficie** | Acera/asfalto |
| **Trafico** | Bajo — zona residencial tranquila |
| **Zona critica** | Tramo de solapamiento en Calle Principal entre Calle A y Calle B (~15m de doble olor) |

```
EFECTO DEL RETROCESO EN EL OLOR:

    IDA SIMPLE:                     ZONA DE SOLAPAMIENTO (backtrack):

    ● ─ ─ ─ ─ ─ ─ ─ ● fin          CALLE B
    Una capa de olor                 │ ═══════════════ │ retorno
    Direccion clara                  │ DOBLE CAPA      │
                                     │ Olor ida + vuelta│
                                     │ 15m entre       │
                                     │ Calle A y       │
                                     │ punto retorno   │
                                     │ El perro debe    │
                                     │ resolver CUAL    │
                                     │ es la mas        │
                                     │ reciente         │
                                     ● CALLE A

    El olor de VUELTA es mas reciente que el de IDA.
    El perro experimentado detecta que el olor
    mas fresco va en la direccion de vuelta.
```

---

## Material Necesario

- **Arnes de trabajo** (diferente al de paseo)
- **Linea larga** de 7-10 metros
- **Articulo de olor** del figurante en bolsa ziplock
- **Recompensa de ALTO VALOR** (la lleva el figurante)
- **Agua** para el perro
- **Cuaderno de registro**
- **Cronometro** (para envejecimiento del rastro)

---

## Localizacion: Barrio Residencial con Cuadricula

### Diagrama General — Vista Completa (Vista Aerea / Cenital)

```
╔══════════════════════════════════════════════════════════════════════════════════╗
║                                                                                  ║
║    CALLE C (vertical)             CALLE PRINCIPAL         CALLE D (vertical)    ║
║              │                              │                        │            ║
║              │                              │                        │            ║
║              │       🏠  🏠  🏠  🏠       │       🏠  🏠  🏠      │            ║
║              │                              │                        │            ║
║    ══════════╬══════════════════════════════╬════════════════════════╬══════════  ║
║    CALLE B   ║                              ║                        ║  CALLE B   ║
║    ══════════╬══════════════════════════════╬════════════════════════╬══════════  ║
║              │                              │                        │            ║
║              │       🏠  🏠  🏠  🏠       │       🏠  🏠  🏠      │            ║
║              │                              │                        │            ║
║              │  Calle C une                 │                        │            ║
║              │  Calle A con Calle B         │                        │            ║
║              │                              │                        │            ║
║              │       🏠  🏠  🏠  🏠       │       🏠  🏠  🏠      │            ║
║              │                              │                        │            ║
║    ══════════╬══════════════════════════════╬════════════════════════╬══════════  ║
║    CALLE A   ║                              ║  CRUCE 1               ║  CALLE A   ║
║    ══════════╬══════════════════════════════╬════════════════════════╬══════════  ║
║              │                              │                        │            ║
║              │       🏠  🏠  🏠  🏠       │       🏠  🏠  🏠      │            ║
║              │                              │                        │            ║
║              │                              │                        │            ║
║              │                              │                        │            ║
║              │                              │                        │            ║
║              │                              │                        │            ║
║              │                              │                        │            ║
║                                           [👃]                                    ║
║                                          INICIO                                  ║
║                                                                                  ║
║                                         [🐕👨]                                   ║
║                                    Binomio espera                                ║
║                                   (detras de coche)                              ║
║                                          [🚗]                                    ║
║                                                                                  ║
╚══════════════════════════════════════════════════════════════════════════════════╝
```

### Diagrama de Ruta del Figurante — Paso a Paso

```
RUTA DEL FIGURANTE (numerada por segmentos):

    CALLE C               CALLE PRINCIPAL              CALLE D
       │                        │                         │
       │                        │                         │
       │      🏠  🏠  🏠       │                         │
       │                        │                         │
  ═════╬════════════════════════╬═════════════════════════╬═════
  CB   ║  ◄──────────────────  ║                         ║  CB
       ║  7. Gira en Calle B   ║                         ║
       ║     (15m)              ║                         ║
  ═════╬════════════════════════╬═════════════════════════╬═════
       │      ↑                 │                         │
       │      │ 6               │                         │
       │      │ Calle C         │                         │
       │      │ (une A y B)     │                         │
       │      │ (30m)           │                         │
       │      │                 │                         │
       │      🏠  🏠  🏠       │                         │
       │      │                 │                         │
  ═════╬══════●═════════════════╬═════════════════════════╬═════
  CA   ║  5. Gira IZQUIERDA    ║                         ║  CA
       ║     en Calle A         ║                         ║
       ║     (20m)              ║                         ║
       ║  ◄─────────────────── ● CRUCE 1                 ║
  ═════╬════════════════════════╬═════════════════════════╬═════
       │                        │  ↑                      │
       │                        │  │ 4. RETROCESO         │
       │                        │  │ (15m, vuelve         │
       │                        │  │  sobre sus           │
       │                        │  │  pasos a             │
       │                        │  │  Calle A)            │
       │                        │  │                      │
       │                        │  │  ★ ZONA DE           │
       │                        │  │  SOLAPAMIENTO ★      │
       │                        │  │  (entre A y B)       │
       │                        │  │                      │
       │                        │  ↓                      │
       │                        │  ● PUNTO DE RETORNO     │
       │                        │  (15m pasado Calle A,   │
       │                        │   camino a Calle B)     │
       │                        │                         │
       │                        │  ↓  2-3                 │
       │                        │  │ Continua 15m         │
       │                        │  │ mas alla de          │
       │                        │  │ Calle A              │
       │                        │                         │
       │                   1. Camina por                  │
       │                      Calle Principal             │
       │                      (30m, pasa Calle A)         │
       │                        │                         │
       │                        ↑                         │
       │                        │ 30m                     │
       │                        │                         │
       │                      [👃]                        │
       │                     INICIO                       │
```

### Detalle — Zona del Escondite Final

```
DETALLE: ESCONDITE EN CALLE B (lado izquierdo)

    CALLE C                              CALLE PRINCIPAL
    │                                    │
    │       🏠       🏠       🏠        │
    │                                    │
    │    ┌─────┐                         │
    │    │     │                         │
    │    │ 👤  │  ◄── Figurante escondido│
    │    │Fig.A│      en portal/entrada  │
    │    │     │      de edificio        │
    │    │ 🎁  │  ◄── Recompensa        │
    │    └──┬──┘      preparada          │
    │       │                            │
════╬═══════╪════════════════════════════╬════
    ║       │        CALLE B             ║
    ║  ◄────┘  7. Figurante giro        ║
    ║             en Calle B (15m)       ║
    ║             hasta portal           ║
════╬════════════════════════════════════╬════
    │  ↑                                 │
    │  │  6. Viene de Calle C            │
    │  │     (subiendo desde Calle A)    │
    │  │     (30m)                       │
    │                                    │

LEGEND: 👤 = Figurante  🎁 = Recompensa
```

### Diagrama de Distancias

```
DISTANCIAS POR SEGMENTO:

    [👃] INICIO
     │
     │  30m ── Segmento 1: Calle Principal (ida)
     │         pasando Cruce 1 (Calle A)
     │
     ● CRUCE 1 (Calle A)
     │
     │  15m ── Segmento 2: Continua 15m hacia Calle B
     │
     ● PUNTO DE RETORNO (entre Calle A y Calle B)
     │
     │  15m ── Segmento 4: RETROCESO (vuelve por el mismo camino)
     │         ★ ZONA DE SOLAPAMIENTO ★
     │         (entre Calle A y Calle B en Calle Principal)
     │
     ● CRUCE 1 (Calle A) — segunda vez
     │
     │  20m ── Segmento 5: Gira izquierda por Calle A
     │
     ● CRUCE con CALLE C
     │
     │  30m ── Segmento 6: Gira derecha por Calle C
     │         (Calle C une Calle A con Calle B)
     │
     ● CRUCE Calle C / Calle B
     │
     │  15m ── Segmento 7: Gira en Calle B
     │
     ● PORTAL / ENTRADA DE EDIFICIO
       [👤] Figurante escondido

    ─────────────────────────────────────
    DISTANCIA TOTAL RECORRIDA:  125m
    DISTANCIA EN LINEA RECTA:   ~40m
    ZONA DE SOLAPAMIENTO:       15m (doble olor, entre A y B)
    GIROS:                      4 (retorno + Calle A + Calle C + Calle B)
```

---

## Diagrama de Comportamiento del Perro

```
SECUENCIA DE COMPORTAMIENTO ESPERADA:

    🐕 INICIO — Presentacion de olor
    │
    ├─ Olfatea articulo (5-15 seg)
    │  Muestra interes
    │
    ├─ Segmento 1: Sigue Calle Principal
    │  │
    │  ├─ Nariz activa, ritmo constante
    │  ├─ Pasa Cruce 1 (Calle A) sin detenerse
    │  │  (el olor sigue recto — no hay giro aqui en la ida)
    │  └─ Continua hacia el punto de retorno (entre A y B)
    │
    ├─ ★ PUNTO DE RETORNO ★ — MOMENTO CRITICO
    │  │  (15m pasado Calle A, camino a Calle B)
    │  │
    │  ├─ El rastro "termina" y "vuelve"
    │  ├─ El perro detecta que el olor cambia de direccion
    │  │
    │  ├─ COMPORTAMIENTOS POSIBLES:
    │  │  ├─ Circulo de busqueda (3-5m radio) ← NORMAL
    │  │  ├─ Olfateo intenso del suelo ← NORMAL
    │  │  ├─ Cabeza arriba buscando en aire ← NORMAL
    │  │  ├─ Breve detencion (10-30 seg) ← NORMAL
    │  │  └─ Retrocede siguiendo el olor mas reciente ← CORRECTO
    │  │
    │  └─ GUIA: No interviene. Linea suelta. Espera.
    │
    ├─ Segmento 4: RETROCESO — Zona de Solapamiento
    │  │  (entre Calle A y Calle B, 15m)
    │  │
    │  ├─ El perro sigue el olor de VUELTA (mas reciente)
    │  ├─ Puede parecer que "vuelve al inicio" — es correcto
    │  ├─ Velocidad puede ser diferente (mas lento, mas inseguro)
    │  └─ GUIA: Confia. No tira de la linea. No corrige.
    │
    ├─ ★ CRUCE 1 / CALLE A (segunda vez) ★ — DECISION CLAVE 1
    │  │
    │  ├─ El perro llega al cruce que ya paso
    │  ├─ Ahora detecta que el figurante giro IZQUIERDA por Calle A
    │  ├─ COMPORTAMIENTOS POSIBLES:
    │  │  ├─ Giro decidido hacia izquierda en Calle A ← IDEAL
    │  │  ├─ Circulo en el cruce, luego gira ← NORMAL
    │  │  ├─ Explora brevemente Calle A derecha ← PERMITIR
    │  │  ├─ Vuelve al cruce y corrige ← EXCELENTE
    │  │  └─ Sigue recto (hacia inicio) ← Esperar, dejara
    │  │                                    de detectar olor
    │  │                                    y retrocedra
    │  │
    │  └─ GUIA: Momento de maxima paciencia. Silencio total.
    │
    ├─ Segmento 5: Calle A hacia Calle C
    │  │
    │  ├─ Olor limpio (solo una direccion, sin solapamiento)
    │  ├─ El perro recupera confianza, ritmo mas constante
    │  └─ Llega al cruce con Calle C
    │
    ├─ ★ CRUCE CALLE A / CALLE C ★ — DECISION CLAVE 2
    │  │
    │  ├─ Detecta que el figurante giro DERECHA en Calle C
    │  ├─ COMPORTAMIENTOS POSIBLES:
    │  │  ├─ Giro decidido a la derecha ← IDEAL
    │  │  ├─ Breve circulo, luego gira ← NORMAL
    │  │  └─ Explora recto por Calle A ← PERMITIR, volvera
    │  │
    │  └─ GUIA: Linea suelta. No indica direccion.
    │
    ├─ Segmento 6: Calle C (une Calle A con Calle B)
    │  │
    │  ├─ Olor limpio, tramo largo (30m, un bloque)
    │  ├─ El perro mantiene ritmo constante
    │  └─ Llega al cruce con Calle B
    │
    ├─ ★ CRUCE CALLE C / CALLE B ★ — DECISION CLAVE 3
    │  │
    │  ├─ Detecta giro del figurante en Calle B
    │  ├─ COMPORTAMIENTOS POSIBLES:
    │  │  ├─ Giro decidido ← IDEAL
    │  │  ├─ Breve circulo, luego gira ← NORMAL
    │  │  └─ Sigue recto por Calle C ← PERMITIR, volvera
    │  │
    │  └─ GUIA: Linea suelta. Confia.
    │
    ├─ Segmento 7: Calle B hacia escondite
    │  │
    │  ├─ Olor limpio, tramo final
    │  ├─ El perro acelera — confianza renovada
    │  └─ Se aproxima al portal
    │
    └─ HALLAZGO
       │
       ├─ Perro detecta figurante en portal
       ├─ Figurante: celebracion EXPLOSIVA
       ├─ Juego + comida (30-60 seg)
       └─ Guia se une a celebracion final
```

---

## Procedimiento Completo

### Fase 0: Preparacion (5 minutos)

```
FIGURANTE A                                GUIA + PERRO
    │                                           │
    ├─ Frota articulo de olor                  ├─ Esperan LEJOS
    │  (30 seg, cuello/axilas)                  │  (fuera de vista,
    │                                           │   detras de coche)
    ├─ Sella articulo en bolsa ziplock          │
    │                                           │
    ├─ Camina por Calle Principal              │
    │  (30m, pasa Cruce 1 / Calle A)           │
    │                                           │
    ├─ Continua 15m mas alla de Calle A        │
    │  (hacia Calle B)                          │
    │                                           │
    ├─ SE DETIENE                              │
    │                                           │
    ├─ RETROCEDE 15m por mismo camino          │
    │  (vuelve a Calle A)                       │
    │                                           │
    ├─ Gira IZQUIERDA en Calle A              │
    │  (camina 20m hacia la izquierda)          │
    │                                           │
    ├─ Llega al cruce con Calle C             │
    │                                           │
    ├─ Gira DERECHA en Calle C                │
    │  (camina 30m hacia Calle B)               │
    │                                           │
    ├─ Llega al cruce con Calle B             │
    │                                           │
    ├─ Gira en Calle B                        │
    │  (camina 15m)                             │
    │                                           │
    ├─ Entra en PORTAL de edificio             │
    │  (entrada en Calle B)                     │
    │                                           │
    ├─ Se oculta dentro del portal             │
    │                                           │
    └─ Prepara recompensa                      ├─ Instructor da
                                                │  senal "listo"
                                                │
                                                └─ Acerca al punto
                                                   de inicio
```

### Fase 1: Segmentos 1-2 — Calle Principal (3-5 minutos)

- Presentar articulo de olor (5-15 segundos)
- Senal verbal: "Busca" (una sola vez)
- El perro sigue el rastro por la Calle Principal
- Pasa el Cruce 1 (Calle A) sin detenerse (el olor va recto)
- Continua 15m hasta el punto de retorno (entre Calle A y Calle B)

### Fase 2: Punto de Retorno — Momento Critico (2-5 minutos)

- El perro detecta que el rastro "termina" y vuelve
- Puede hacer circulos, olfatear intensamente, detenerse
- **GUIA: No interviene. Linea suelta. Silencio.**
- El perro resuelve y retrocede siguiendo el olor de vuelta

### Fase 3: Cruce 1 / Calle A — Decision 1 (2-5 minutos)

- El perro llega al cruce por segunda vez
- Detecta que el figurante giro izquierda por Calle A
- Puede explorar brevemente antes de decidir
- Gira izquierda y sigue por Calle A
- **GUIA: Maxima paciencia. No indicar direccion.**

### Fase 4: Calle C — Decision 2 (1-3 minutos)

- Olor limpio en Calle A, el perro recupera ritmo
- Llega al cruce con Calle C
- Detecta giro a la derecha
- Gira derecha por Calle C (une Calle A con Calle B, 30m)
- **GUIA: Linea suelta. Confia en el perro.**

### Fase 5: Calle B — Decision 3 (1-3 minutos)

- El perro recorre Calle C hasta llegar a Calle B
- Detecta giro del figurante en Calle B
- Gira y sigue por Calle B
- **GUIA: Linea suelta.**

### Fase 6: Calle B y Hallazgo (2-3 minutos)

- Tramo final, olor limpio — el perro acelera
- Localiza al figurante en el portal
- **Celebracion EXPLOSIVA** del figurante
- Juego + comida (30-60 segundos)
- Guia se une a la celebracion final

---

## Tabla de Comportamiento Esperado

| Punto | Comportamiento Esperado | Si No Ocurre |
|---|---|---|
| Calle Principal (ida) | Sigue rastro con ritmo constante, pasa Calle A sin parar | Si se detiene en cruce → olor insuficiente; reducir distancia del cruce al inicio |
| Punto de retorno (entre A y B) | Circulos, olfateo intenso, pausa; luego retrocede | No retrocede en 60 seg → instructor evalua; puede acortar distancia de retroceso |
| Zona solapamiento (A-B) | Sigue en direccion correcta (vuelta), puede ir mas lento | Sigue en direccion incorrecta (ida) → se dara cuenta, dejara de oler y corregira; esperar |
| Cruce 1 — Calle A (segunda vez) | Detecta giro izquierda, puede hacer circulo; gira correctamente | Sigue recto → esperar, perdera olor y volvera; si >90 seg → simplificar ejercicio |
| Cruce Calle A / Calle C | Detecta giro derecha, gira con decision | Sigue recto por Calle A → esperar, perdera olor y volvera al cruce |
| Cruce Calle C / Calle B | Detecta giro, gira con decision | Sigue recto por Calle C → esperar, perdera olor y volvera |
| Calle B | Olor limpio, acelera, busqueda decidida | Pierde interes → figurante emite sonido minimo desde portal |
| Portal | Localiza figurante, celebracion | No entra en portal → figurante asoma brevemente para crear referencia visual |

---

## Progresion

| Sesion | Distancia retroceso | Distancia total | Dificultad Anadida |
|---|---|---|---|
| Primera vez | 10m (retroceso corto) | 100m | Ninguna — figurante semi-visible en portal |
| Repeticion 2 | 15m (esta sesion) | 125m | Estandar — portal completamente oculto |
| Repeticion 3 | 20m | 145m | Envejecimiento 10 min + 1 transeуnte cruzando |
| Repeticion 4 | 25m + doble retroceso | 170m | Envejecimiento 15 min + contaminacion en cruces |

---

## Notas Metodo Kocher

- **El retroceso es el desafio central**: La zona de solapamiento entre Calle A y Calle B tiene dos capas de olor del mismo figurante. El perro debe discriminar por FRESCURA del olor (el de vuelta es mas reciente). Esto es una habilidad olfativa avanzada.
- **No intervenir en la zona de solapamiento**: El perro NECESITA tiempo para procesar la doble capa. Los circulos, el olfateo intenso y las pausas son senal de que esta trabajando, no de que esta perdido.
- **Tres giros tras el retroceso**: Despues de resolver el solapamiento, el perro debe resolver tres giros consecutivos (Calle A, Calle C, Calle B). Cada giro es una prueba independiente de toma de decisiones.
- **Calle C como conector**: Calle C une Calle A con Calle B (un bloque, ~30m). Este tramo largo sin giros permite al perro recuperar confianza entre decisiones.
- **El cruce es la segunda prueba**: Cuando el perro vuelve al cruce que ya paso, tiene nueva informacion. Debe elegir correctamente. Si elige mal, se dara cuenta por perdida de olor — la autocorreccion es parte del aprendizaje.
- **Linea suelta es CRITICA aqui**: El guia vera al perro "ir hacia atras" y sentira el impulso de corregir. NO hacerlo. El perro esta siguiendo el rastro correctamente.
- **Exito garantizado**: Si el perro no resuelve el retroceso en intentos razonables, el instructor puede pedir al figurante que se acerque al cruce para acortar el ejercicio. Siempre terminar en positivo.
- **Celebracion proporcional**: Este ejercicio tiene multiples dificultades (retroceso + solapamiento + tres giros en cuadricula). La recompensa debe ser excepcional.
