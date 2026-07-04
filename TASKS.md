# Tareas — Vida en el Monte

Backlog del proyecto, organizado por milestones del vertical slice (ver [docs/GDD_Vida_en_el_Monte.md](docs/GDD_Vida_en_el_Monte.md), sección 7).
Cada tarea está pensada para entrar en una sesión de 1-3hs. Tildar con `[x]` a medida que se completan.

## Milestone 0 — Setup (listo)
- [x] Proyecto Godot 4 inicializado (renderer Compatibility, GDScript)
- [x] Personaje FPS: movimiento WASD + mouse look, salto, sprint
- [x] Terreno de prueba (plano 50x50)
- [x] Repo git + GitHub conectado

## Milestone 1 — Construcción (casa/terreno) — COMPLETO
Diseño cerrado en [docs/design/milestone1_construccion.md](docs/design/milestone1_construccion.md). Grid de 2m (ajustado al tamaño real de los assets), sin modo de construcción separado, menú radial con `G`, alcance de 10m, auto-encaje de la pared en el borde más cercano, gratis e ilimitado por ahora. Piezas con assets reales de Quaternius (ver [CREDITS.md](CREDITS.md)).

- [x] Crear piezas placeholder: `wall.tscn`, `floor.tscn`, `roof.tscn` (StaticBody3D + colisión, cubos grises)
- [x] Nodo/script `BuildSystem`: raycast desde cámara + snap a grid de 1m
- [x] Preview fantasma: instancia semi-transparente que sigue el raycast, verde/rojo según validez
- [x] Menú radial (`Control`) con Pared/Piso/Techo/Manos vacías, se abre manteniendo `G`
- [x] Pieza equipada persiste hasta elegir otra en el menú
- [x] ~~Rotación libre con `R` + mouse~~ → reemplazada por auto-encaje: la pared se orienta sola según el borde de celda más cercano (ver devlog)
- [x] Colocar pieza con click izquierdo (si el preview está en verde)
- [x] Borrar pieza con click derecho apuntando a una ya colocada
- [x] Limitar alcance de colocación/borrado a 5 metros

## Milestone 2 — Escritorio de trabajo + mini-juego
- [ ] Objeto interactuable "escritorio" (detección de proximidad + prompt "Presioná E")
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
