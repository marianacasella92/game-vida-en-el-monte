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

**Tipografía del HUD/UI (definición global, aplica a toda pantalla — no solo inventario):**
- **Títulos:** Walter Turncoat
- **Texto general** (labels, contadores, texto de acciones, etc.): Syne Mono

- Al abrirse: el mundo 3D permanece visible de fondo, pero con **blur** (desenfoque gaussiano) + oscurecido semitransparente (~40–50% de opacidad negra encima). El juego se pausa o entra en modo "menú" — a definir según diseño de sistemas, pero visualmente nunca corta a negro total: se mantiene la sensación de estar todavía "ahí", parte de la filosofía de inmersión constante del PXD.
- Título **"INVENTARIO"**: esquina superior izquierda. Tipografía **Walter Turncoat** (manuscrita/rústica, no geométrica — corrección respecto a la v1 de este documento), mayúsculas, blanco. Asset: `inv_title_text.png`.
- Línea divisoria fina discontinua (dash), ancho completo del panel, inmediatamente debajo del título. Asset: `inv_divider_top.png`.
- **Contador de dinero** (nuevo, no está en la referencia de Ashen): esquina superior derecha, mismo nivel que el título. Ícono: `icon_money.png` + número en Syne Mono.
- Grilla de ítems: 5 columnas, filas expandibles según cantidad de slots (referencia: 5 filas visibles, scrolleable si hay más).
- Línea divisoria inferior, mismo estilo que la superior, con isotipo del juego centrado (diseñado a pedido, no es un placeholder de la IA). Asset: `inv_divider_bottom.png`.

## 4.2 Slot de ítem

- Marco decorativo tipo "corner-bracket" (no un cuadrado sólido — son trazos discontinuos en las esquinas y bordes, con textura de tiza gastada, igual que el resto del HUD).
- Los 3 estados son **assets separados** (no se usa `modulate` para pasar de uno a otro, porque el trazo del marco varía levemente entre estados en la referencia original — no es solo un cambio de color):
  - **Vacío** → `inv_slot_frame_empty.png` — solo el marco, trazo fino, blanco.
  - **Ocupado** → `inv_slot_frame_occupied.png` — marco de trazo levemente más marcado, sin ningún dibujo adentro. El render 3D del ítem (sección 4.3) se superpone como capa separada encima, centrado, ocupando ~70% del slot.
  - **Seleccionado** → `inv_slot_frame_selected_gold.png` — mismo marco, ya extraído directamente en dorado real (no recoloreado por código):
    - Dorado promedio: `#D3AA27`
    - Dorado brillante (highlight del trazo): `#FFF158`
  - Implementación en Godot: un solo `TextureRect` por slot, cuya `texture` se swap-ea según el estado (vacío / ocupado / seleccionado), más un `TextureRect` adicional encima para el render 3D del ítem cuando corresponde.

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
- `inv_divider_bottom.png` — línea divisoria inferior, con el isotipo del juego centrado
- `inv_slot_frame_empty.png` — marco de slot vacío
- `inv_slot_frame_occupied.png` — marco de slot ocupado (sin el dibujo del ítem adentro; el render 3D va superpuesto como capa separada)
- `inv_slot_frame_selected_gold.png` — marco de slot seleccionado, ya en dorado real (sin el dibujo del ítem adentro)
- `icon_money.png` — ícono de moneda para el contador de dinero

**Pendiente:** renders 3D de los ítems reales del juego (ver prompt 4.5).

---

# 5. Celular diegético

## 5.1 Filosofía (por qué esto NO rompe la estética)

El HUD del juego (vida/hambre/energía, prompts de interacción) es monocromático y minimalista **por diseño propio del juego**. Pero el celular es un objeto del mundo — un dispositivo real que el personaje sostiene — y su pantalla debe verse como la pantalla de un celular real de 2026: con color, con fotos de producto, con una interfaz de app moderna. No es una inconsistencia, es la fantasía del pilar **Modernidad** funcionando correctamente: la tecnología convive con el monte sin filtrar su estética a través del lenguaje visual del HUD del juego.

Regla clara: **el tratamiento monocromático/minimalista aplica al HUD del juego. Las pantallas de dispositivos diegéticos (celular, notebook, sensores) se diseñan con el realismo visual que tendrían en la vida real.**

## 5.2 Apertura y animación

- Tecla de apertura: **`P`** (provisorio — a revisar más adelante con alguien especializado en diseño de controles/keybinding antes de cerrarlo definitivo).
- Al presionar la tecla: se anima la mano del personaje bajando y "agarrando" el celular, que aparece frente a cámara.
- Referencia de framing: **PDA de Subnautica** — el dispositivo ocupa el centro/derecha del encuadre, el guante/mano que lo sostiene aparece parcialmente en el borde inferior-izquierdo de la pantalla, el mundo de fondo queda visible pero fuera de foco (no se oscurece, no se pausa a negro — mismo criterio ya definido en 5.3 de la versión anterior de este documento).
- Al cerrar (misma tecla o `Esc`): animación inversa, la mano baja el celular y la cámara vuelve a la vista normal.

## 5.3 Pantalla de inicio (Home)

Al agarrar el celular, lo primero que se ve es una pantalla de inicio estilo Android/iOS moderno:

- **Hora** — reloj, siempre visible.
- **Batería** — indicador de batería del celular. Para el MVP, se mantiene siempre llena/cargada (no es un sistema que se gestione como recurso de gameplay, al menos no en esta etapa).
- **Notificaciones** — badges/avisos sobre la app de Notificaciones (ver 5.4.4) u otras apps con novedades.
- **Grilla de apps** — íconos de las apps disponibles, layout tipo home screen real (grid de íconos redondeados).

**Dirección visual definida:** paleta cálida/tierra (naranjas, duraznos, marrones) — conecta el dispositivo con el mundo natural en vez de sentirse como un gadget frío y genérico. Se usa el dorado ya establecido en el resto del HUD (`#D3AA27` / `#FFF158`) como acento de marca/highlight (ej. badge de notificación, borde de ícono seleccionado), para que el celular no quede visualmente aislado del resto de la identidad del juego.

**Nota de diseño:** con solo 4 apps (Marketplace, Banco, Trabajo, Notificaciones) la grilla del home screen puede sentirse vacía comparada con un celular real. Con el agregado del Calendario (5.4.5) ya son 5, pero conviene sumar igual 1–2 íconos "de relleno" no funcionales por ahora (Cámara, Ajustes) solo para que la pantalla se sienta como un dispositivo real y con densidad — se pueden activar más adelante si se vuelven mecánicas reales.


## 5.4 Apps (MVP)

### 5.4.1 Marketplace

- App de compra/venta, estética de tienda online moderna (referencia: MercadoLibre — ver documento, sección anterior).
- **Mecánica de entrega (decisión de sistemas — ya definida):**
  - Al comprar, se muestra el precio del producto **+ costo de envío por separado** (no es gratis, no es instantáneo).
  - Se muestra **"Llega en X días"** al momento de la compra, para dejar claro que nada es instantáneo.
  - Estado del pedido, visible en la app: un día antes de la entrega dice **"Preparando el paquete"**; el día de la entrega dice **"Tu pedido está en camino"**.
  - El paquete **no llega a la puerta de casa** — aparece como una caja de cartón física en un punto alejado del terreno, que el jugador tiene que ir a buscar y abrir manualmente (refuerza el pilar de Autosuficiencia: nada es cómodo ni automático del todo, incluso la tecnología moderna requiere esfuerzo físico en el monte).
  - Esto resuelve el problema de realismo que preocupaba al inicio: no hace falta mostrar un camión de reparto llegando al medio del monte, el "punto de entrega lejano" lo explica narrativamente (dron/vehículo autónomo deja el paquete en el punto accesible más cercano).

### 5.4.2 App del Banco

- Muestra el dinero actual del jugador.
- A futuro (no MVP): balance mensual de gastos/ingresos.

### 5.4.3 App de Trabajo (Influencer / Educador)

Muestra:
- Cantidad de alumnos.
- Cursos creados.
- Precio de cada curso.
- Agenda de las clases.

### 5.4.4 Notificaciones

- Avisos de clases próximas, eventos aleatorios (ej. propuestas de mentorías), y otras novedades del mundo/sistemas del juego.

### 5.4.5 Calendario (nueva — imprescindible, no opcional)

App de calendario, muestra en una sola vista de días:
- Fecha de llegada del pedido del Marketplace.
- Clases en vivo que el personaje tiene que dar (cruza con la agenda de la app de Trabajo).
- Fecha de cobro/pago (cuándo cobra).
- Otros eventos que se vayan sumando con el tiempo.

Funciona como el "panel de control" que conecta todos los sistemas de fechas del juego en un solo lugar — sin esta app, la información de fechas quedaría dispersa entre Marketplace, Trabajo y Notificaciones sin una vista unificada.

## 5.5 Prompt sugerido para generar el home screen

> "A realistic modern smartphone home screen UI, warm earthy color palette (terracotta, peach, warm brown, soft cream), rounded app icons with subtle depth, status bar showing time and a full battery icon, a small notification badge, app grid including a marketplace icon, a bank/wallet icon, a work/analytics icon, a notifications bell icon, and a calendar icon, plus one or two generic filler icons (camera, settings). One gold accent color used sparingly for the notification badge and a highlighted icon border (hex D3AA27). Clean, modern, 2026 aesthetic, front-facing phone screen mockup, no visible hardware bezel needed — just the screen content."

## 5.6 Pendientes

1. Confirmar tecla de apertura del celular (`P` provisorio) con alguien especializado en input/keybinding.
2. Animación de mano al agarrar el celular (el modelo 3D del celular en sí ya está diseñado y descargado — solo falta la animación).

## 5.7 Referencias visuales recolectadas (moodboard — insumo ya resuelto en 5.3)

Se juntaron varias referencias de interfaces de celular realistas (vía Magnific/stock) con distintas paletas: rosa/turquesa con widgets de reloj y clima, violeta/verde con centro de control, marrón/durazno con librería de apps, y una específica que ya incluye un ícono de "Marketplace" en la grilla. De ahí se tomó el estilo de ícono (redondeado, flat con leve profundidad) y se convergió a la paleta cálida/tierra definida en 5.3.


---

# 6. Reglas de pantallas modales (inventario, celular, minijuego de trabajo, y futuras)

- Al abrir **cualquier** pantalla de este tipo (inventario, celular, minijuego de trabajo, y las que se definan más adelante), el HUD de vitales (vida/hambre/energía) se **oculta por completo**.
- Solo se ve la pantalla abierta — foco total, sin elementos de mundo superpuestos compitiendo visualmente.
- Al cerrar la pantalla, el HUD de vitales vuelve a aparecer.

# 7. Controles y navegación

- **Apertura de inventario:** tecla `I`.
- **Apertura de celular:** tecla `P` (provisoria, ver sección 5.5).
- **Navegación principal:** mouse (por ahora). El juego debe soportar también **gamepad** desde el diseño de estas pantallas — la grilla de slots y cualquier menú deben pensarse con foco navegable por D-pad/stick desde el principio, no como agregado posterior.

# 8. Pendientes / próximas decisiones

Sin pendientes abiertos por ahora — el ícono del contador de dinero ya fue generado y recortado (`icon_money.png`).