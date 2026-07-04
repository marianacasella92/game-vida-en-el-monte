# Milestone 1 — Construcción: especificación

Diseño cerrado para la primera pieza del vertical slice (ver [GDD](../GDD_Vida_en_el_Monte.md), sección 7.1 y [TASKS.md](../../TASKS.md)).

## Assets
- **Placeholders primero** (cubos/planos grises), reemplazados una vez que hubo assets reales bajados, sin tocar el código de colocación — tal como estaba planeado.
- **Assets reales (Milestone 1 cerrado):** pack **Medieval Village MegaKit (Standard)** de Quaternius, CC0. Pared = `Wall_Plaster_Straight`, piso = `Floor_WoodDark`, techo = `Roof_Wooden_2x1`. Ver [CREDITS.md](../../CREDITS.md).

## Grid
- Celda de **2m x 2m** (ajustado desde el 1m original: los módulos del pack de Quaternius miden 2m — pared 2m de ancho x 3m de alto, piso 2m x 2m). El alcance de colocación/borrado subió a **10m** para mantener la misma cantidad de celdas de alcance que antes (5).

## Modo de juego
- **No hay "modo construcción" separado.** El jugador siempre puede caminar y construir al mismo tiempo, sin togglear nada.

## Selección de pieza — menú radial
- Se abre **manteniendo apretada la tecla `G`**. Muestra las opciones: Pared, Piso, Techo, Manos vacías.
- Se suelta `G` sobre la opción deseada para equiparla.
- La pieza equipada **queda en mano** hasta que se abra el menú de nuevo y se elija otra (incluida "Manos vacías").
- Mientras el menú está abierto, el mouse controla la selección de la porción de la rueda (no la cámara).

## Preview fantasma
- Con una pieza equipada, aparece una versión semi-transparente en la posición donde se colocaría.
- Posición calculada por raycast desde la cámara, snapeada a la grilla de 2m.
- Color **verde** si la posición es válida, **rojo** si no (colisiona con otra pieza o está fuera de alcance).
- Sin pieza equipada ("Manos vacías"), no se muestra ningún preview.

## Alcance
- Máximo **10 metros** desde el jugador para colocar o borrar piezas (limita el raycast) — equivalente a 5 celdas de 2m.

## Orientación de la pared (revisado tras la primera prueba)
- La rotación libre con `R` + mouse se probó y se sentía mal: al girar la pared con el pivote en el borde, el otro extremo podía terminar apuntando hacia la cámara y generar artefactos visuales (clipping).
- **Reemplazada por auto-encaje:** la pared no se rota manualmente. Según en qué borde de la celda de 2m esté el puntero (norte/sur/este/oeste), la pared se orienta sola para encajar en ese borde, igual que en Los Sims. Piso y techo no necesitan esto porque son simétricos ante rotación.
- **Revisado de nuevo con assets reales:** la pared de Quaternius no es simétrica (tiene una cara con vigas de madera y otra lisa). Con solo 2 orientaciones posibles (una por eje), la cara linda quedaba mirando para afuera en 2 de las 4 paredes de una habitación y para adentro en las otras 2.
- **Primer intento de arreglo (fallido):** espejar 180° según de qué lado de la celda estaba el *puntero* (posición del jugador al apuntar). Roto: al caminar, el resultado cambiaba todo el tiempo porque dependía de dónde estabas parado, no de algo estable del mundo.
- **Segundo intento (con un bug sutil):** decidir por piso adyacente, pero comparando las celdas "cerca mío" vs "lejos mío" al apuntar. Bug: cuál celda es "cerca" y cuál es "lejos" depende de desde qué lado te parás a apuntar al mismo borde — el mismo borde físico podía dar vuelta la pared distinto según si apuntabas desde adentro o desde afuera de la habitación.
- **Arreglo definitivo:** en vez de "cerca/lejos del jugador", se comparan las dos celdas **fijas** a los lados de ese borde en términos absolutos (norte/sur o este/oeste — no depende de hacia dónde mires ni desde dónde apuntes). La cara linda siempre apunta lejos de la celda que ya tiene piso. Como esas dos celdas son siempre las mismas para un borde dado, el resultado ahora sí es 100% estable sin importar la posición del jugador. Si no hay piso de ningún lado (sin contexto todavía), usa una orientación por defecto.
- **Tecla de emergencia `F`:** invierte manualmente la orientación de la pared fantasma actual, por si la detección automática se equivoca en algún caso (ej. habitaciones muy irregulares). Se resetea cada vez que volvés a elegir "pared" en el menú radial.

## Altura del techo
- El techo **no usa la grilla vertical genérica**: la pared mide 3m de alto, que no es múltiplo de la grilla de 2m, así que redondear la altura a la grilla dejaba el techo flotando a mitad de pared. En cambio, el techo siempre se coloca a una altura fija (`wall_height`, 3m) sin importar hacia dónde esté mirando el jugador verticalmente — asume por ahora que las casas son de una sola planta.

## Colocar y borrar
- **Click izquierdo** con pieza equipada y preview en verde → coloca la pieza (queda fija en el mundo, con colisión real).
- **Click derecho** apuntando a una pieza ya colocada (dentro del alcance) → la elimina, sin importar qué esté equipado en ese momento.

## Costo / economía
- **Gratis e ilimitado** en este milestone. No hay descuento de dinero ni de inventario todavía — eso se conecta recién en Milestone 3 (marketplace).

## Zona de construcción
- Se puede construir en **cualquier parte** del terreno de 50x50 actual. Sin parcela delimitada.

---

## Notas técnicas (implementación)

- Piezas como escenas separadas (`wall.tscn`, `floor.tscn`, `roof.tscn`): `StaticBody3D` raíz (grupo `build_piece`) + el modelo real instanciado como hijo (`Model`, escena `PackedScene` del `.gltf` importado) + `CollisionShape3D` propio con una caja aproximada al bounding box real (no se usa la malla del modelo como colisión, para mantenerlo simple).
- Un nodo/script `BuildSystem` (hijo del `Player`) maneja: raycast, snap a grid, pieza equipada, encaje automático de la pared, instanciar/eliminar piezas.
- El preview fantasma es una instancia de la misma pieza sin colisión. Como el modelo real puede tener varias mallas internas (no una sola como los cubos placeholder), `BuildSystem` busca recursivamente todos los `MeshInstance3D` del fantasma y les aplica el material semi-transparente verde/rojo a todos.
- Menú radial como `Control` con las opciones distribuidas en círculo; se muestra/oculta con `G` y pausa temporalmente el mouse-look de la cámara mientras está abierto.
