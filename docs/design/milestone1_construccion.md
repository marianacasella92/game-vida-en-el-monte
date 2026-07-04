# Milestone 1 — Construcción: especificación

Diseño cerrado para la primera pieza del vertical slice (ver [GDD](../GDD_Vida_en_el_Monte.md), sección 7.1 y [TASKS.md](../../TASKS.md)).

## Assets
- **Placeholders primero:** cubos/planos grises (un color distinto por tipo de pieza) mientras no bajemos assets reales. La lógica no debería depender de cómo se ven las piezas, así que reemplazarlas después no debería tocar el código de colocación.

## Grid
- Celda de **1m x 1m**. Compatible con la mayoría de los packs low-poly cuando sumemos assets reales.

## Modo de juego
- **No hay "modo construcción" separado.** El jugador siempre puede caminar y construir al mismo tiempo, sin togglear nada.

## Selección de pieza — menú radial
- Se abre **manteniendo apretada la tecla `G`**. Muestra las opciones: Pared, Piso, Techo, Manos vacías.
- Se suelta `G` sobre la opción deseada para equiparla.
- La pieza equipada **queda en mano** hasta que se abra el menú de nuevo y se elija otra (incluida "Manos vacías").
- Mientras el menú está abierto, el mouse controla la selección de la porción de la rueda (no la cámara).

## Preview fantasma
- Con una pieza equipada, aparece una versión semi-transparente en la posición donde se colocaría.
- Posición calculada por raycast desde la cámara, snapeada a la grilla de 1m.
- Color **verde** si la posición es válida, **rojo** si no (colisiona con otra pieza o está fuera de alcance).
- Sin pieza equipada ("Manos vacías"), no se muestra ningún preview.

## Alcance
- Máximo **5 metros** desde el jugador para colocar o borrar piezas (limita el raycast).

## Rotación
- Mientras se mantiene `R` (con una pieza equipada), el movimiento horizontal del mouse rota la pieza fantasma **libremente** sobre el eje Y (sin snap a 90°).
- Al soltar `R`, la rotación queda fija en ese ángulo para la próxima colocación.

## Colocar y borrar
- **Click izquierdo** con pieza equipada y preview en verde → coloca la pieza (queda fija en el mundo, con colisión real).
- **Click derecho** apuntando a una pieza ya colocada (dentro del alcance) → la elimina, sin importar qué esté equipado en ese momento.

## Costo / economía
- **Gratis e ilimitado** en este milestone. No hay descuento de dinero ni de inventario todavía — eso se conecta recién en Milestone 3 (marketplace).

## Zona de construcción
- Se puede construir en **cualquier parte** del terreno de 50x50 actual. Sin parcela delimitada.

---

## Notas técnicas (implementación)

- Piezas placeholder como escenas separadas (`wall.tscn`, `floor.tscn`, `roof.tscn`): `StaticBody3D` + `MeshInstance3D` + `CollisionShape3D`, dimensionadas en múltiplos de 1m.
- Un nodo/script `BuildSystem` (probablemente hijo del `Player`) maneja: raycast, snap a grid, pieza equipada, rotación, instanciar/eliminar piezas.
- El preview fantasma es una instancia de la misma pieza sin colisión (o en una capa de física que no choca con el raycast de colocación), con material semi-transparente cuyo color cambia según validez.
- Menú radial como `Control` con las opciones distribuidas en círculo; se muestra/oculta con `G` y pausa temporalmente el mouse-look de la cámara mientras está abierto.
