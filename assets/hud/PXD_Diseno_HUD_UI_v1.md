# Player Experience Design (PXD)
## Anexo — Diseño Funcional de HUD / UI

**Proyecto:** Vida en el Monte
**Versión:** 1.0
**Estado:** En construcción — deriva directamente del Documento Fundacional v0.2

Este documento traduce la "Filosofía de la interfaz" del PXD a especificaciones concretas, listas para implementar en Godot 4.7 (`CanvasLayer` + nodos `Control`).

---

# 1. Principios heredados del PXD (recordatorio)

- El HUD nunca rompe la inmersión.
- Es pequeño, discreto y opcionalmente ocultable.
- Aparece únicamente cuando aporta valor.
- Referencia estética: **Ashen** y **Green Hell**.
- Prohibido: pixel art, cartoon, interfaces infantiles, HUD recargados, colores vívidos en la capa de interfaz.
- Los colores vívidos y realistas quedan reservados exclusivamente al mundo 3D (inmersión), nunca a la capa de UI.

---

# 2. HUD de vitales (siempre visible en el mundo)

## 2.1 Composición

Ubicado en la esquina inferior izquierda de la pantalla, sobre el viewport 3D.

| Elemento | Descripción | Estado |
|---|---|---|
| Círculo grande — **Vida** | Ícono de corazón dentro de marco circular. Standalone, sin barra. | Siempre visible |
| Círculo chico — **Hambre** | Ícono de manzana, con barra horizontal fina a la derecha | Siempre visible |
| Círculo chico — **Energía** | Ícono de rayo, con barra horizontal fina a la derecha | Siempre visible |

## 2.2 Estilo visual

- 100% monocromático: blanco puro (`#FFFFFF`) sobre transparente. Ningún color.
- Línea fina, grosor consistente entre todos los íconos.
- Textura sutil tipo "tiza gastada" (leve, no debe leerse como sucio ni roto).
- Sin gradientes, sin glow, sin sombras duras.
- Inspiración directa: HUD de *Green Hell*.

## 2.3 Assets generados (sprites sheet → recortados)

- `icon_health.png` — corazón grande
- `icon_hunger.png` — manzana grande (referencia de estilo, no usado en el HUD final de vitales)
- `icon_energy.png` — rayo grande (idem)
- `icon_hunger_small.png` + `bar_hunger.png` — par manzana chica + barra
- `icon_energy_small.png` + `bar_energy.png` — par rayo chico + barra
- `icon_compass.png` — brújula (uso futuro, navegación)
- `key_prompt_frame.png` — marco cuadrado vacío para tecla dinámica de interacción

Implementación en Godot: `TextureRect` para íconos, `TextureProgressBar` (fondo + relleno) para las barras. Todos los sprites son blanco puro con alfa real — recolorables vía `modulate` si se necesita un acento sin regenerar el asset.

## 2.4 Comportamiento — energía baja

Cuando la energía cae por debajo de un umbral (a definir en balance de gameplay):

- Efecto de post-procesado: viñeta oscura + leve desenfoque radial en los bordes de pantalla.
- Audio: respiración pesada del personaje.
- **No** es un sprite de HUD — se implementa como shader sobre un `ColorRect` en un `CanvasLayer`, activado por código según el valor de energía. Ver implementación en GDScript (pendiente, próxima sesión).

## 2.5 Prompt de generación (referencia, ya ejecutado)

> "A clean sprite sheet of minimalist survival-game HUD elements, all in pure white line-art, isolated on a solid black background for easy background removal. Include: 1) a heart icon inside a circular frame, for health, 2) an apple icon inside a smaller circular frame, for hunger, 3) a lightning bolt icon inside a smaller circular frame, for energy, 4) two empty horizontal progress bar frames (thin white outline, no fill, no texture) to pair with the hunger and energy icons, 5) a compass icon, 6) a small square key-prompt icon with a thin border and empty space for a letter inside. Every element uses the exact same thin, consistent white line weight, subtle worn or scratched texture but absolutely no color, no gradients, no wood grain, no glow, no pixel art, no cartoon style. Inspired by the minimalist diegetic HUD of the game Green Hell. Realistic, modern, calm aesthetic. Elements evenly spaced in a grid, consistent scale, high resolution."

---

# 3. Prompt de interacción con objetos del mundo

- Aparece únicamente sobre el objeto con el que se puede interactuar, y solo cuando la acción está disponible (ej. al tener una herramienta/objeto equipado que habilita la acción).
- Formato: ícono de tecla arriba (`key_prompt_frame.png` + letra dinámica renderizada como `Label`, ya que la tecla puede cambiar si el jugador remapea controles) + texto de la acción debajo (ej. "Recolectar").
- **No** hay controles de movimiento (correr, agacharse, saltar) fijos en pantalla. Esos se consultan en el menú de Settings → Controles.

---

# 4. Pantalla de Inventario

Referencia estética directa: **inventario de Ashen** (ver imagen de referencia adjunta al proyecto). Se mantiene la composición y tratamiento, con dos cambios de dirección de arte respecto a la referencia:

1. Los **ítems se renderizan en 3D** (render realista con iluminación suave y desaturación), **no** como line-art plano blanco y negro.
2. Se agrega el **contador de dinero**, visible únicamente en esta pantalla (no en el HUD de mundo).

## 4.1 Estructura general

- Al abrirse: el mundo 3D permanece visible de fondo, pero con **blur** (desenfoque gaussiano) + oscurecido semitransparente (~40–50% de opacidad negra encima). El juego se pausa o entra en modo "menú" — a definir según diseño de sistemas, pero visualmente nunca corta a negro total: se mantiene la sensación de estar todavía "ahí", parte de la filosofía de inmersión constante del PXD.
- Título **"INVENTARIO"**: esquina superior izquierda. Tipografía sans-serif geométrica de trazo fino, mayúsculas, tracking amplio (letras separadas), blanco. Asset: `inv_title_text.png`.
- Línea divisoria fina discontinua (dash), ancho completo del panel, inmediatamente debajo del título. Asset: `inv_divider_top.png`.
- **Contador de dinero** (nuevo, no está en la referencia de Ashen): esquina superior derecha, mismo nivel que el título. Ícono simple de moneda (monocromático, mismo lenguaje visual que el resto del HUD) + número en la misma tipografía del título pero más chica. Pendiente de generación de asset — ver prompt sugerido en 4.5.
- Grilla de ítems: 5 columnas, filas expandibles según cantidad de slots (referencia: 5 filas visibles, scrolleable si hay más).
- Línea divisoria inferior, mismo estilo que la superior, con marca/logo centrada (en la referencia hay un placeholder — reemplazar por el isotipo definitivo del juego cuando esté listo). Asset: `inv_divider_bottom.png`.

## 4.2 Slot de ítem

- Marco decorativo tipo "corner-bracket" (no un cuadrado sólido — son trazos discontinuos en las esquinas y bordes, con textura de tiza gastada, igual que el resto del HUD). Asset base: `inv_slot_frame_empty.png`.
- **Estado vacío:** solo el marco, blanco, ~70% de opacidad.
- **Estado con ítem:** marco + render 3D del ítem centrado, ocupando ~70% del slot.
- **Estado seleccionado:** mismo marco, pero recoloreado a dorado — no se genera un asset nuevo, se aplica `modulate` con el color exacto extraído de la referencia:
  - Dorado promedio: `#D3AA27`
  - Dorado brillante (highlight/glow del borde): `#FFF158`
  - Sugerencia de implementación: `modulate` en `#D3AA27` para el marco base, y un segundo nodo con blend "Add" en `#FFF158` a baja opacidad para el brillo del contorno, si se quiere replicar el glow de la referencia.

## 4.3 Renderizado de los ítems (cambio de dirección respecto a la referencia)

- **No** line-art plano.
- Render 3D con iluminación suave tipo estudio (soft studio lighting), ángulo 3/4, fondo transparente u oscuro sólido para extracción.
- Paleta desaturada / muted — no colores vívidos, para no romper la calma visual del resto del HUD, pero con volumen y sombra reales (a diferencia de los íconos de vitales, que son 100% flat).
- Consistencia entre todos los ítems: mismo ángulo de cámara, misma iluminación, mismo tratamiento de color en toda la generación.

## 4.4 Navegación

- Selección con teclado/mouse/gamepad (a definir el método principal).
- Al seleccionar un ítem, aparece el prompt de tecla dinámica (mismo lenguaje visual que el HUD de mundo, sección 3) indicando la acción disponible, ej. `[E] Usar`.
- Cierre de la pantalla con tecla dedicada (a definir, ej. Tab / I / Esc).

## 4.5 Prompt sugerido para generar los renders 3D de ítems (a ejecutar por ítem o en lote pequeño, no en una sola imagen con todos los ítems del juego para mantener consistencia)

> "A single 3D-rendered game inventory icon of [OBJETO], isolated on a solid dark background for easy extraction. Soft studio lighting, 3/4 camera angle, realistic materials but desaturated and muted color grading — no vivid colors. Subtle soft shadow beneath the object. Clean and consistent style suitable for a calm, modern, realistic life-simulation game (not fantasy, not medieval). High resolution, centered composition, generous empty margin around the object."

Reemplazar `[OBJETO]` por cada ítem del juego (herramientas, semillas, componentes de panel solar, celular, conservas, etc.), manteniendo el mismo prompt base para consistencia visual entre todos.

## 4.6 Assets generados en esta sesión

- `inv_title_text.png` — texto "INVENTARIO" recortado de la referencia
- `inv_divider_top.png` — línea divisoria superior
- `inv_divider_bottom.png` — línea divisoria inferior (incluye marca placeholder, a reemplazar)
- `inv_slot_frame_empty.png` — marco de slot vacío, base para todos los estados (normal y seleccionado vía `modulate`)

**Pendiente:** renders 3D de los ítems reales del juego (ver prompt 4.5) y el ícono + número del contador de dinero.

---

# 5. Pendientes / próximas decisiones

1. ¿Los íconos de vida/hambre/energía se ocultan mientras el inventario está abierto, o permanecen visibles de fondo? (sugerido: ocultar, para foco total en el inventario — a confirmar).
2. Tecla de apertura/cierre del inventario.
3. Método principal de navegación en la grilla (teclado / mouse / gamepad).
4. Ícono y tipografía exacta del contador de dinero.
5. Isotipo final para el centro de la línea divisoria inferior.
