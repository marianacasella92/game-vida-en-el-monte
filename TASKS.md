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

- [x] Objeto interactuable "escritorio" (detección de proximidad + prompt "Presioná E") — asset real `Desk.glb`, se coloca desde el catálogo de construcción (tecla `G`) como una pieza más, rotable con `R`. La tecla `interact` (`E`) ya está mapeada pero todavía no dispara nada.
- [ ] Estado "trabajando": bloquear movimiento, cambiar cámara/UI
- [ ] Mini-juego "dar clase en vivo": preguntas + opciones de respuesta
- [ ] Lógica de tiempo límite y puntaje
- [ ] Al terminar: acreditar dinero ganado
- [ ] Volver al modo movimiento normal al salir

## Milestone 3 — Marketplace mínimo
- [ ] Sistema de economía global (dinero accesible desde todo el juego)
- [ ] UI de marketplace con 2-3 ítems (precio + descripción corta)
- [ ] Comprar ítem → resta dinero, lo deja disponible para construir
- [ ] HUD simple: plata actual visible en pantalla
- [ ] Conectar ítems comprados con el sistema de construcción (Milestone 1)

## Assets (transversal, en paralelo a todo lo anterior)
- [x] Elegir pack(s) de assets low-poly (Quaternius) y descargar — `assets/building`, `farm`, `food`, `house_interior`, `nature`, `survival`
- [x] Completar [CREDITS.md](CREDITS.md) con la fuente de cada asset usado
- [x] Reemplazar geometría placeholder de pared/piso/techo por assets reales (Medieval Village MegaKit)
- [ ] Curar/organizar el resto de los packs descargados a medida que se vayan necesitando (huerta, interior, naturaleza, etc. — no urgente todavía, es para milestones futuros)

## Fuera de alcance del vertical slice (no tocar todavía)
Cultivo/huerta, energía (solar/batería), agua, hambre/sueño, día-noche/clima, árbol tecnológico completo, más de un mini-juego, novio/perro/familia (Fase 2).
