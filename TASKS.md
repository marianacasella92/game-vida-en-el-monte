# Tareas — Vida en el Monte

Backlog del proyecto, organizado por milestones del vertical slice (ver [docs/GDD_Vida_en_el_Monte.md](docs/GDD_Vida_en_el_Monte.md), sección 7).
Cada tarea está pensada para entrar en una sesión de 1-3hs. Tildar con `[x]` a medida que se completan.

## Milestone 0 — Setup (listo)
- [x] Proyecto Godot 4 inicializado (renderer Compatibility, GDScript)
- [x] Personaje FPS: movimiento WASD + mouse look, salto, sprint
- [x] Terreno de prueba (plano 50x50)
- [x] Repo git + GitHub conectado

## Milestone 1 — Construcción (casa/terreno)
- [ ] Definir tamaño de grid de construcción (ej. 1m x 1m)
- [ ] Modo construcción: entrar/salir con una tecla
- [ ] Preview fantasma de la pieza (raycast desde cámara, snap a grid)
- [ ] Colocar pared (click para confirmar)
- [ ] Colocar piso
- [ ] Colocar techo
- [ ] Colisión real en las piezas colocadas
- [ ] Eliminar/deshacer una pieza colocada (opcional para el vertical slice)

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
- [ ] Elegir pack(s) de assets low-poly (Kenney / Quaternius) y descargar
- [ ] Completar [CREDITS.md](CREDITS.md) con la fuente de cada asset
- [ ] Reemplazar geometría placeholder (cubos/planos) por assets reales

## Fuera de alcance del vertical slice (no tocar todavía)
Cultivo/huerta, energía (solar/batería), agua, hambre/sueño, día-noche/clima, árbol tecnológico completo, más de un mini-juego, novio/perro/familia (Fase 2).
