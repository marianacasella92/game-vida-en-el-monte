# Tareas — Vida en el Monte

Backlog del proyecto, organizado por milestones del vertical slice (ver [docs/GDD_Vida_en_el_Monte.md](docs/GDD_Vida_en_el_Monte.md), sección 7).
Cada tarea está pensada para entrar en una sesión de 1-3hs. Tildar con `[x]` a medida que se completan.

## Milestone 0 — Setup (listo)
- [x] Proyecto Godot 4 inicializado (renderer Compatibility, GDScript)
- [x] Personaje FPS: movimiento WASD + mouse look, salto, sprint
- [x] Terreno de prueba (plano 50x50)
- [x] Repo git + GitHub conectado

## Milestone 1 — Construcción (casa/terreno) — COMPLETO
Diseño cerrado en [docs/design/milestone1_construccion.md](docs/design/milestone1_construccion.md). Grid de 2m (ajustado al tamaño real de los assets), sin modo de construcción separado, alcance de 10m, auto-encaje de la pared en el borde más cercano, gratis e ilimitado por ahora. Piezas con assets reales de Quaternius (ver [CREDITS.md](CREDITS.md)).

- [x] Crear piezas placeholder: `wall.tscn`, `floor.tscn`, `roof.tscn` (StaticBody3D + colisión, cubos grises)
- [x] Nodo/script `BuildSystem`: raycast desde cámara + snap a grid de 1m
- [x] Preview fantasma: instancia semi-transparente que sigue el raycast, verde/rojo según validez
- [x] Menú de construcción con Pared/Piso/Techo/Manos vacías, se abre/cierra con `G`
- [x] Pieza equipada persiste hasta elegir otra en el menú
- [x] ~~Rotación libre con `R` + mouse~~ → reemplazada por auto-encaje: la pared se orienta sola según el borde de celda más cercano (ver devlog)
- [x] Colocar pieza con click izquierdo (si el preview está en verde)
- [x] Borrar pieza con click derecho apuntando a una ya colocada
- [x] Limitar alcance de colocación/borrado a 5 metros

**Refactor de escalabilidad (hecho):** el sistema separa *categoría* (cómo se posiciona: pared/piso/techo, en `_process`) de *variante* (qué escena se instancia). Agregar una pieza nueva es sumar una entrada al `CATALOG` de `build_system.gd` + su `.tscn` con `metadata/piece_category` y `metadata/piece_id`, sin tocar la lógica de snap.
- Pared: Recta / Puerta / Ventana.
- Techo: Plano / Faldón A / Faldón B / Remate Izq. / Remate Der. / Esquina / Cumbrera (piezas `Roof_Wooden_2x1_*` del pack). Como son piezas direccionales, se agregó una acción nueva `build_rotate` (tecla `R`) que rota 90° sobre Y la pieza de techo equipada — separada de `build_flip` (`F`), que sigue siendo solo el flip binario de la pared.

**Menú: de rueda radial a catálogo (hecho):** el menú radial (`radial_menu.gd`, borrado) no escalaba a categorías con muchas piezas (ej. Escaleras tiene 19 variantes en el pack). Se reemplazó por `catalog_menu.gd`: un panel con lista de categorías a la izquierda y lista de variantes con scroll a la derecha, con el mouse liberado (`Input.mouse_mode`) para clickear. `G` alterna abrir/cerrar (ya no es "mantener apretado"), Escape o click afuera del panel también cierra sin elegir nada.

**Pendiente — mejoras del catálogo de construcción:**
- [ ] Vista previa en el catálogo: hoy `catalog_menu.gd` solo muestra botones de texto, sin thumbnail/render del asset. Habría que generar o precomputar una imagen por variante (ej. `TextureRect` al lado o arriba del nombre en cada botón) para poder identificar la pieza sin tener que equiparla y probarla en el mundo.
- [ ] Catálogo completo del pack: se relevaron ~90 piezas más de la familia Plaster/Madera que todavía no están cargadas (más paredes, pisos y techos de madera, puertas y marcos independientes, ventanas y postigos, escaleras, balcones, aleros, tapas de hueco, esquinas de pared). Se van a ir agregando de a categorías, priorizando primero las que reutilizan snap ya probado (más variantes de pared/piso/techo) antes que las que necesitan lógica de posicionamiento nueva (escaleras, balcones, aleros, puertas/marcos independientes), porque cada categoría nueva requiere entender cómo se ancla a la grilla y eso salió mal a la primera con el techo.

**Mejoras futuras posibles (no urgentes, quedó bastante básico a propósito para cerrar el vertical slice):**
- Las variantes puerta/ventana usan la misma caja de colisión sólida que la pared recta (no se puede caminar por la puerta todavía) — falta ajustar la forma de colisión por variante o agregar un hueco pasable.
- Soporte para más de un piso/planta (hoy `wall_height` asume una sola altura fija).
- Deshacer la última pieza colocada.

**Deuda técnica pendiente:**
- [ ] Desacoplar la lógica de `build_system.gd`: hoy tanto `_unhandled_input` (equipar/rotar/flip/colocar/borrar) como `_process` (snap por categoría) son cadenas de `if/elif equipped_category == "..."` que crecen con cada categoría nueva (pared, techo, escritorio, y lo que se sume del catálogo completo todavía pendiente). Cada pieza nueva sigue sumando otra rama. Conviene extraer cada categoría a su propia estrategia/clase (ej. un recurso o script por categoría con métodos `snap()`, `handle_input()`) en vez de un solo script con ifs encadenados — hoy es manejable para mí, pero se está volviendo difícil de seguir para una persona.

## Milestone 2 — Escritorio de trabajo + mini-juego
Diseño del primer ítem en [docs/design/milestone2_escritorio.md](docs/design/milestone2_escritorio.md).

- [x] Objeto interactuable "escritorio" (detección de proximidad + prompt "Presioná E") — asset real `Desk.glb`, se coloca desde el catálogo de construcción (tecla `G`) como una pieza más, rotable con `R`.
- [x] Estado "trabajando": bloquear movimiento, cambiar cámara/UI — al presionar `E` cerca del escritorio, la jugadora se teletransporta al `SitSpot` de la pieza, se bloquea movimiento/mouse-look/construcción, y aparece un panel placeholder ("Trabajando... (Esc para salir)"). `Esc` restaura todo. Probado y confirmado funcionando en el editor (ver bug de grupos en el doc de diseño). Todavía sin mini-juego real adentro del panel.
- [x] Mini-juego "dar clase en vivo" — "Malabares de atención" (GDD 4.6): 3 alumnos con barra de atención que decae, se sube arrastrando un ícono aleatorio hacia el alumno elegido. Pendiente de probar en el editor.
- [x] Lógica de tiempo límite y puntaje — sesión de 50s, eventos random de "distracción" sobre un alumno al azar, promedio final ≥70% = "buena clase".
- [x] Al terminar: acreditar dinero ganado — autoload mínimo `Economy` (`autoload/economy.gd`), sin UI de marketplace todavía (eso es Milestone 3).
- [x] Volver al modo movimiento normal al salir — reusa `Escape`/`WorkSystem.stop_working()` ya existente, tanto para salir de la clase a mitad de camino (sin cobrar) como para cerrar la pantalla de resultado.

**Deuda técnica pendiente (mini-juego):**
- [ ] Mejorar la UI del mini-juego — hoy es placeholder (emojis y `ProgressBar` simples, sin arte real ni pulido visual).
- [ ] Agregar un mini-tutorial antes de la primera clase, que se pueda omitir y no se vuelva a mostrar (checkbox "No mostrar de nuevo").

## Milestone 3 — Marketplace mínimo
- [x] Sistema de economía global (dinero accesible desde todo el juego) — `autoload/economy.gd`, ahora con `spend_money`/`purchase_item` además de `add_money`
- [x] Celular como punto de acceso al marketplace, según GDD 4.10 — implementado como **tecla siempre disponible** (`open_phone`, tecla `P`) en vez de un objeto físico con proximidad, ya que "lo lleva siempre encima" (`scripts/phone/phone_system.gd`)
- [x] UI de marketplace con 4 ítems (precio + descripción corta) — `scripts/phone/marketplace_ui.gd`; 3 son placeholders genéricos (semillas/herramienta/adorno) y 1 ("Cajón de madera") está conectado a construcción, ver ítem siguiente
- [x] Comprar ítem → resta dinero y lo marca como comprado
- [x] HUD simple: plata actual visible en pantalla — `scripts/ui/hud.gd`
- [x] Conectar ítems comprados con el sistema de construcción (Milestone 1) — comprar "Cajón de madera" en el marketplace desbloquea la variante `decor`/`crate` (`scenes/build/decor_crate.tscn`) en el catálogo de construcción (`CATALOG` de `build_system.gd`, campo `requires_item`); el resto de los ítems placeholder sigue sin conexión
- [x] Sistema de guardado básico: guardado manual (botón "Guardar partida" en el celular) + autoguardado periódico cada 5 minutos reales como placeholder (`autoload/save_manager.gd`), hasta reemplazarlo por el trigger real ("dormir") cuando exista el ciclo día/noche — guarda plata, ítems comprados y piezas construidas

**Diseño pendiente (todavía sin tareas concretas):**
- Personalización del personaje (GDD 4.10) — falta definir profundidad (cambio de rasgos básicos vs. sistema completo) y qué assets/sistema técnico hace falta antes de poder desglosarlo en tareas.

## Assets (transversal, en paralelo a todo lo anterior)
- [x] Elegir pack(s) de assets low-poly (Quaternius) y descargar — `assets/building`, `farm`, `food`, `house_interior`, `nature`, `survival`
- [x] Completar [CREDITS.md](CREDITS.md) con la fuente de cada asset usado
- [x] Reemplazar geometría placeholder de pared/piso/techo por assets reales (Medieval Village MegaKit)
- [ ] Curar/organizar el resto de los packs descargados a medida que se vayan necesitando (huerta, interior, naturaleza, etc. — no urgente todavía, es para milestones futuros)
- [x] Brazos en primera persona: `scenes/player/arms.tscn` (instanciada bajo `Head/Camera3D` en `player.tscn`), con `RealArmsModel` (`assets/character/first_person_hands_rigged.glb`, escala corregida vía import `root_scale = 0.01`) posicionado a mano en `ModelPivot`. Placeholders de cápsulas quedan como fallback si `use_real_model = false`.

**Deuda técnica pendiente (brazos):**
- [ ] El modelo real (`RealArmsModel`) se ve en bind pose fijo (sin animación) — falta posar/animar los dedos y brazos para que sostengan herramientas de forma creíble, y resolver el punto siguiente de anclaje del ítem en la mano.

## Milestone 4 — Huerta básica + necesidades personales
Objetivo del sprint: cerrar el siguiente paso del loop de juego según el GDD, incorporando una huerta simple y una rutina de cuidado básico para que el gameplay se sienta más vivo sin entrar todavía en energía/agua complejas.

### Sprint 4.1 — Base de cultivo
- [x] Definir una grilla simple de slots de cultivo en el terreno (ej. 3x3 o 4x4) y mostrarla visualmente.
- [x] Permitir sembrar una semilla desde una acción simple del jugador (ej. interactuar con un slot vacío).
- [x] Mostrar estados del cultivo: vacío / creciendo / listo para cosechar.
- [x] Guardar el estado de los cultivos en el sistema de guardado actual.

### Sprint 4.2 — Ciclo de cuidado y cosecha
- [x] Implementar un riego manual simple con una herramienta básica (regadera o acción de "regar") — GDD 4.5, nivel 1 (regadera artesanal). Ítem "Regadera" (`watering_can`) gratis en el marketplace; equipada, interactuar con una parcela "creciendo" la riega (`CropManager.water_plot()`). Sin penalización dura: si no se riega, el crecimiento se estanca (label "Necesita agua") pero no retrocede ni muere; regando se reanuda. Niveles 2-3 (manguera, riego automatizado) quedan fuera de alcance, dependen de los sistemas de agua/energía todavía no implementados.
- [x] Agregar crecimiento por tiempo de juego entre estados (sin depender de energía ni agua complejas) — `CropManager` (`autoload/crop_manager.gd`): progreso acumulado (`crop_progress`) que solo avanza mientras la parcela está regada, 5 etapas visuales (montoncito de tierra + `Carrot_1..4` reales de Quaternius) repartidas en `crop_growth_time` (8s de prueba). Ver bugs resueltos en [docs/ESTANDARES_TECNICOS.md](docs/ESTANDARES_TECNICOS.md).
- [x] Permitir cosechar y convertir el cultivo en comida/recursos para consumo — al cosechar (`CropManager.harvest_plot()`, tecla `E`), se agrega "Zanahoria" (`carrot`) al inventario. Plantar/regar ahora es con click izquierdo (`CropManager.use_tool()`) — separado de cosechar a propósito, ver [docs/ESTANDARES_TECNICOS.md](docs/ESTANDARES_TECNICOS.md).
- [x] Añadir una acción simple de consumir comida para recuperar hambre — comer con click izquierdo (mismo input que usar herramienta) teniendo "Zanahoria" equipada; `PlayerNeeds.try_eat()`, tabla `FOOD_ITEMS` (data-driven, igual criterio que `CATALOG`/`ITEMS`).

### Sprint 4.3 — Necesidades básicas
- [x] Crear un sistema simple de hambre y sueño con valores y regeneración — `autoload/player_needs.gd`. Hambre decae con el tiempo (100→0 en ~2min de prueba), se recupera comiendo. Sueño decae con el tiempo y más rápido corriendo/trabajando (`_is_exerting()`, GDD 4.8), se recupera durmiendo (restaura todo de una, por ahora).
- [x] Mostrar barras o indicadores visuales en HUD — HUD rediseñado por completo (ver sección "Rediseño de HUD" más abajo): `scenes/player/player.tscn` (`Hud/Root/HealthRow|EnergyRow|HungerRow|MoneyRow`), `scripts/ui/hud.gd`, `scripts/ui/hud_style.gd`.
- [x] Añadir una interacción básica para dormir y recuperar sueño — pieza nueva "Cama simple" (`scenes/build/bed.tscn` + `scripts/build/bed.gd`, mismo patrón de proximidad+prompt que el escritorio), desbloqueada comprándola en el marketplace ($40, como el cajón de madera). **Ojo:** el tamaño de la caja de colisión (`BoxShape3D`) y la posición del área de interacción son estimados a mano, sin confirmar visualmente en el editor — puede necesitar ajuste, igual que pasó con el `SitSpot` del escritorio en su momento.
- [x] Dar feedback claro cuando el personaje está cansado o hambriento — ícono de advertencia por barra (no colores tipo semáforo, ver rediseño de HUD).
- [x] Debuff de movimiento + vida (GDD 4.8) — `autoload/player_needs.gd`: vida baja de a poco cuando hambre o sueño están por debajo del 25% (`is_neglected()`), y la velocidad de movimiento se multiplica por `0.6` en ese estado (`scripts/player.gd`). Regenera sola cuando ninguna de las dos está crítica.
- [x] Muerte → recargar el último guardado (único sistema con penalización dura del juego) — `PlayerNeeds.died` conectado en `autoload/save_manager.gd`; al morir se llama `load_game()` y después `grant_death_grace()` (pone hambre/sueño en un piso del 40% y vida al máximo) para evitar un loop de muerte instantánea si el último guardado también tenía las necesidades bajas.

**Pendiente, no urgente:** dormir sigue restaurando el sueño instantáneo y completo; una transición gradual tiene más sentido una vez que exista el ciclo día/noche de Sprint 4.4.

### Rediseño de HUD (fuera del scope original de Milestone 4, hecho de paso)
Siguiendo `docs/GameDesign/PXD_Documento_Fundacional_v0.2.md` (HUD pequeño/discreto, sin emojis/cartoon, estética minimalista tipo Ashen): HUD reestructurado con íconos reales (`assets/hud/Icon set 1/`, pack CC0 ya descargado) en vez de texto/emoji, barras finas con borde (`scripts/ui/hud_style.gd`, reusable para fases futuras), sin colores saturados — el aviso de "atención acá" es un ícono de exclamación que aparece bajo el 25%, no un cambio de color de la barra entera. Se sacó el texto "Mano: X" (mareaba, según la usuaria) — la fila de plata ahora solo muestra el ícono + número.

**Fases futuras del rediseño (anotadas, no implementadas):**
- Hotbar de 9 slots (abajo-centro, ícono + cantidad + selección resaltada) — faltan íconos por ítem (semilla/regadera/zanahoria), el pack bajado es genérico de UI.
- Notificaciones tipo subtítulo (evento + mensaje, fade in/out) — sistema nuevo desde cero.
- Banner de eventos/hitos (texto centrado + líneas decorativas) — ídem.
- Celular 3D diegético (`assets/tools/smartphone.glb` en la mano, animación de apertura, pantalla renderizada vía `SubViewport`) — reemplazaría el panel 2D fullscreen actual del celular.
- Rediseño del minijuego de la clase (sacar los emojis de `drag_icon.gd`/`student_widget.gd`).

### Sprint 4.4 — Día/noche mínimo
- [ ] Implementar un ciclo día/noche básico con transición visual simple.
- [ ] Limitar o cambiar el comportamiento del juego según la hora del día (ej. trabajar de día, dormir de noche).
- [ ] Asegurar que el sistema no rompa el loop de construcción/trabajo existente.

### Sprint 4.5 — Pulido y cierre del sprint
- [ ] Revisar balance de tiempos, costos y feedback de interacción.
- [ ] Añadir mensajes/UI de ayuda para sembrar, regar, cosechar y dormir.
- [ ] Probar guardado/carga con cultivos y necesidades activas.
- [ ] Preparar la siguiente iteración con prioridad en agua/energía o en pulido del mini-juego de trabajo.

### Fuera de alcance de este sprint
- Sistema completo de agua y energía.
- Clima, estaciones complejas o riego automatizado.
- Árbol tecnológico completo.
- Más de un mini-juego de trabajo.

## Backlog — Bugs y mejoras varias (sesión 2026-07-06)
Encontrados jugando con el sistema de construcción (Milestone 1, ya cerrado) y el HUD (Sprint 4.3). No están agrupados en un milestone del GDD porque cruzan varios sistemas a la vez (construcción, inventario, input, UI, guardado).

### Bugs
- [ ] La cama (`bed.tscn`) no rota al equiparla en modo construcción — a diferencia de techo/escritorio/decoración, que sí responden a `build_rotate`.
- [ ] El autoguardado pisó una construcción en progreso durante una sesión de juego — piezas recién colocadas se perdieron/revirtieron. Investigar si `save_manager.gd` puede correr su guardado periódico mientras `build_system` todavía tiene una pieza equipada/a mitad de colocar, y si hace falta alguna guarda para no serializar un estado a medio construir.

### Inventario / Marketplace
- [ ] La cama, al comprarse en el marketplace, tiene que aparecer en el inventario — hoy aparece directo desbloqueada en el catálogo de construcción (mismo patrón que el cajón de madera).
- [ ] El escritorio debe comportarse igual que la cama: comprarse en el marketplace (precio $0 por ahora) y aparecer en el inventario, no directo en el catálogo de construcción.
- [ ] Cama y escritorio (y en general cualquier "furniture" colocable en el mundo) tienen que activar el modo construcción al equiparse desde el inventario, para poder posicionarlos en el mundo como cualquier otra pieza del catálogo.
  - **Nota de arquitectura:** este punto está directamente relacionado con la deuda técnica ya anotada en Milestone 1 ("Desacoplar la lógica de `build_system.gd`" — hoy `_unhandled_input`/`_process` son cadenas de `if/elif equipped_category == "..."` que crecen con cada categoría nueva). Antes de conectar más piezas al inventario conviene resolver esa arquitectura (una estrategia/clase por categoría en vez de ifs encadenados), para no seguir sumando ramas a un sistema que ya cuesta seguir. Programar con cuidado y patrones de diseño prolijos, sin romper lo que ya funciona (paredes/techo/piso/puerta/catálogo).

### HUD / UI
- [ ] Prompt de tecla de interacción: reemplazar el rectángulo dibujado a mano por el set de imágenes `assets/hud/keyset` (una imagen por tecla, no un `Label` de texto compuesto a mano). El texto de la acción (ej. "Recolectar") se mantiene como texto, pero con la tipografía de texto general del inventario (Syne Mono — ver `docs/GameDesign/PXD_Diseno_HUD_UI_v1.md` sección 4.1), no la de título (Walter Turncoat). Sin borde negro, todo en blanco.
- [ ] Cambiar la tecla de "cerrar ventana" (celular, catálogo de construcción, etc.) de `Esc` a `Q` — hoy se superpone con el menú de pausa (también en `Esc`), y termina abriendo pausa en vez de cerrar la ventana activa.

## Fuera de alcance del vertical slice (no tocar todavía)
Cultivo/huerta, energía (solar/batería), agua, hambre/sueño, día-noche/clima, árbol tecnológico completo, más de un mini-juego, novio/perro/familia (Fase 2).
