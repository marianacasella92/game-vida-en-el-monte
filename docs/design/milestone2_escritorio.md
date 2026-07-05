# Milestone 2, ítem 1 — Escritorio interactuable: especificación

Diseño cerrado para el primer ítem de Milestone 2 (ver [GDD](../GDD_Vida_en_el_Monte.md), sección 4.6 y 7.2, y [TASKS.md](../../TASKS.md)).

## Asset
- Se usa directo el asset real **`assets/house_interior/Desk.glb`** (Ultimate House Interior Pack, Quaternius, CC0), sin pasar por un placeholder gris previo como en Milestone 1 — a diferencia de pared/piso/techo, el escritorio es una pieza única y estática (sin variantes ni rotación por auto-encaje), así que no había tanto riesgo en ir directo al modelo final.
- Medida real del modelo (relevada a mano en el editor): **2m de largo x 1m de ancho x 1m de alto**. Pivote centrado en el largo (x: -1 a 1) y apoyado en el piso (y: 0 a 1). Se asume también centrado en el ancho (z: -0.5 a 0.5) por ser un modelo simétrico; si al probarlo en el editor queda corrido hacia un costado, se ajusta el offset del nodo `Model` en `desk.tscn`.

## Cómo se coloca en el mundo
- **No se hardcodea una posición fija en `world.tscn`.** Se suma como una pieza más del catálogo de construcción existente (`BuildSystem` / `catalog_menu.gd`, tecla `G`): la jugadora la elige del menú, aparece el fantasma, y la coloca con click donde quiera dentro de la casa que ya construyó.
- **Trade-off asumido a propósito:** mezcla una pieza de mobiliario con las piezas estructurales (pared/piso/techo) en el mismo catálogo. Se eligió así para no duplicar el sistema de colocación/snap ya probado, aunque conceptualmente un escritorio no es "estructura". Si en el futuro se suman muchos más muebles, vale la pena evaluar separarlos en una categoría/menú propio.
- Snap: igual que el piso (`_snap_flat`, centrado en la celda de 2m), no usa el auto-encaje a borde de la pared.

## Rotación
- Rotable con la tecla `R` (`build_rotate`), igual mecanismo que ya usaba el techo (90° sobre Y por paso). Se generalizó la variable `roof_rotation_steps` a `rotation_steps` en `build_system.gd` porque ahora la comparten techo y escritorio.

## Detección de proximidad y prompt
- `desk.tscn` incluye un `Area3D` (`InteractionArea`) con una esfera de radio **2.5m** (creada en código en `desk.gd`, vía `@export var interaction_range`, no hardcodeada en la escena — mismo estilo que `build_range`/`grid_size` en `BuildSystem`).
- Al entrar la jugadora al área, se muestra un `Label3D` con el texto **"Presioná E"** (billboard, siempre mirando a cámara); al salir, se oculta.
- Para distinguir a la jugadora de otras piezas construidas que puedan solaparse con el área (paredes, pisos), el nodo `Player` está en el grupo `"player"` (ver bug de grupos más abajo), y `desk.gd` sólo reacciona si el body que entra/sale pertenece a ese grupo.
- Se agregó la acción de input `interact` (tecla `E`, físico 69) en `project.godot`.

## Ítem 2 — Estado "trabajando"

- **Trigger:** presionar `interact` (`E`) mientras la jugadora está dentro del área de proximidad del escritorio (ver ítem 1).
- **Cámara:** al entrar, el jugador (`CharacterBody3D`) se teletransporta a un nodo `Marker3D` hijo de la pieza (`SitSpot`), y el pitch de la cámara (`Head.rotation.x`) se resetea a 0. Al salir, se restaura la transform y el pitch originales. Se eligió mover al jugador entero (no solo la cámara) para que la física quede consistente con "estar sentada ahí".
  - **Posición de `SitSpot`:** estimada a mano (1.2m en frente del escritorio, sobre el eje -Z local, mirando hacia el escritorio), asumiendo que ese es el lado donde queda el espacio para las piernas/silla del modelo. No se pudo confirmar visualmente. Es un `Marker3D`, así que si al probarlo en el editor la jugadora queda mirando para el lado equivocado (o metida dentro del escritorio), se puede arrastrar/rotar ese nodo directamente en el editor sin tocar código.
- **UI:** placeholder simple (`WorkSystem/WorkUILayer/Panel` en `player.tscn`) — fondo oscuro + texto "Trabajando... (Esc para salir)". El mini-juego real (ítem siguiente) se va a dibujar dentro de este mismo panel.
- **Bloqueo de movimiento:** `player.gd` corta `_physics_process` y el mouse-look por completo mientras `WorkSystem.is_working` es `true`.
- **Bloqueo cruzado con construcción:** mientras se trabaja, `build_system.gd` no procesa ningún input ni actualiza el fantasma — si no, un click para cerrar el panel de trabajo podía terminar borrando una pieza construida cercana (la cámara sigue apuntando a donde estaba antes de sentarse).
- **Salida:** `Escape` (acción `ui_cancel`). `WorkSystem` la revisa en `_process` (no en `_unhandled_input`) a propósito: `player.gd` ya tiene un manejo genérico de `ui_cancel` que libera el mouse sin condiciones, y como Godot despacha los eventos de input antes de correr `_process` en el mismo frame, esto garantiza que la recaptura del mouse al salir del estado "trabajando" siempre sea la última palabra, sin depender del orden entre `_unhandled_input` de nodos hermanos (que no está garantizado).
- **Grupo `"work_system"`:** se agregó para que `desk.gd` (que vive en el mundo, no es hijo del jugador) pueda encontrarlo con `get_tree().get_first_node_in_group(...)`, igual que ya hacía con el grupo `"player"`.

**Edge case conocido, no resuelto:** si la jugadora abre el catálogo de construcción (`G`) y en ese estado presiona `E` cerca de un escritorio, se podría entrar a "trabajando" con el catálogo todavía abierto de fondo (UIs superpuestas). Es un caso raro y no rompe nada (se sale con Escape), así que se dejó sin guardia explícita por ahora.

## Bugs encontrados al probar en el editor (resueltos)

- **El cartel "Presioná E" nunca aparecía, aunque la detección de físicas funcionaba bien.** Se debuggeó agregando `print()` temporales en `desk.gd` (sacados después): `Area3D.body_entered` sí disparaba y detectaba correctamente al nodo `Player` por nombre, pero `body.is_in_group("player")` daba `false` — el grupo `"player"` simplemente no estaba en la lista de grupos del nodo en tiempo de ejecución, pese a estar declarado como `groups=["player"]` en `player.tscn`.
  - **Causa probable:** `player.tscn` no se usa solo/suelto — está instanciado *dentro de* `world.tscn` (`instance=ExtResource(...)`). Los grupos declarados en el `.tscn` de una escena que vive anidada así, en este proyecto, no se propagaron al nodo real en runtime (no se confirmó el motivo exacto a nivel de Godot, pero el patrón se repitió idéntico para dos nodos distintos, ver abajo).
  - **Arreglo:** en vez de depender de la propiedad `groups=[...]` del `.tscn`, se agregó `add_to_group("player")` directo en el código, en `_ready()` de `player.gd`.
- **El teletransporte al presionar `E` tampoco funcionaba**, incluso después de arreglar el cartel. Mismo patrón exacto: `WorkSystem` (nodo hijo de `Player`, también anidado dentro de la escena instanciada) declaraba `groups=["work_system"]` en `player.tscn`, y `desk.gd` lo busca con `get_tree().get_first_node_in_group("work_system")` — como el grupo tampoco se propagaba, la búsqueda no encontraba nada y `start_working()` nunca se llamaba.
  - **Arreglo:** mismo enfoque, `add_to_group("work_system")` en `_ready()` de `work_system.gd`.
- **Lección general:** para nodos que viven pre-colocados dentro de otra escena (como `Player` y sus hijos dentro de `world.tscn`), declarar grupos por código (`add_to_group()` en `_ready()`) en vez de confiar en la propiedad `groups=[...]` del `.tscn`. Para piezas que se instancian dinámicamente por código en runtime (paredes, techos, el propio escritorio), la declaración en el `.tscn` sí es confiable.

## Fuera de alcance de este ítem (queda para los próximos ítems de Milestone 2)
- Cualquier mini-juego o lógica real de "trabajar" (la UI de este ítem es placeholder).
- Lógica de tiempo límite y puntaje.
- Acreditar dinero.
