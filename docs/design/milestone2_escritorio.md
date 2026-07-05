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
- Para distinguir a la jugadora de otras piezas construidas que puedan solaparse con el área (paredes, pisos), el nodo `Player` se sumó al grupo `"player"`, y `desk.gd` sólo reacciona si el body que entra/sale pertenece a ese grupo.
- Se agregó la acción de input `interact` (tecla `E`, físico 69) en `project.godot`, pero **todavía no dispara ninguna lógica** — eso es el próximo ítem de Milestone 2 ("Estado 'trabajando'"), que va a consumir esta misma tecla para efectivamente sentarse a trabajar.

## Fuera de alcance de este ítem (queda para los próximos ítems de Milestone 2)
- Bloquear movimiento / cambiar cámara al interactuar.
- Cualquier mini-juego o lógica de "trabajar".
- Acreditar dinero.
