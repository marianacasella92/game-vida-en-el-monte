# Devlog — Vida en el Monte

Registro corto de cada sesión de trabajo. Formato: fecha, qué se hizo, dónde quedó, próximo paso.
Pensado para retomar rápido después de una semana sin tocar el proyecto.

---

## 2026-07-04

**Qué se hizo:**
- Proyecto Godot 4 creado (renderer Compatibility, GDScript, sin .NET).
- Personaje en primera persona: movimiento WASD, cámara con mouse, salto, sprint.
- Terreno de prueba (plano simple) para probar el movimiento.
- GDD escrito y versionado en `docs/`.
- Repo git inicializado y conectado a GitHub.
- Backlog armado en `TASKS.md`, organizado en 3 milestones del vertical slice.

**Dónde quedó:**
Personaje moviéndose correctamente sobre el terreno. Nada de construcción, trabajo ni marketplace todavía.

**Próximo paso:**
Arrancar Milestone 1 (construcción): definir el grid y el modo de colocación de piezas.

---

## 2026-07-04 (cont.) — Milestone 1 completo

**Qué se hizo:**
- Diseño de construcción cerrado y documentado en [docs/design/milestone1_construccion.md](docs/design/milestone1_construccion.md).
- Piezas placeholder `wall.tscn`, `floor.tscn`, `roof.tscn` (cubos grises con colisión, origen en la base, grupo `build_piece`).
- `BuildSystem` (`scripts/build/build_system.gd`): raycast desde cámara, snap a grid de 1m, preview fantasma verde/rojo según validez y alcance (5m).
- Menú radial (`scripts/build/radial_menu.gd`) para elegir pared/piso/techo/manos vacías, se abre manteniendo `G`.
- Rotación libre de la pieza fantasma manteniendo `R` + mouse (rotación global, no se ve afectada por hacia dónde mira la cámara).
- Colocar con click izquierdo (solo si el preview está válido) y borrar con click derecho, ambos limitados al mismo alcance de 5m.

**Dónde quedó:**
Milestone 1 (construcción) completo según el diseño. Todavía no probado en el editor — pendiente de que la usuaria lo juegue y valide que se sienta bien.

**Próximo paso:**
Probar todo el flujo de construcción en el editor. Si algo no se siente bien (sensibilidad de rotación, tamaño de la rueda, etc.), ajustar antes de pasar a Milestone 2 (escritorio de trabajo + mini-juego).

---

## 2026-07-04 (cont.) — Bugfixes tras la primera prueba

Primera prueba jugada por la usuaria. Feedback: "el resto está impecable". 3 bugs encontrados y corregidos:

1. **Pared centrada en el punto de grilla en vez de apoyada en el borde**, y giraba sobre su propio centro. Fix: origen de `wall.tscn` movido a uno de sus extremos (antes en `x=0`, ahora en `x=0.5` relativo a su mesh/colisión), así queda anclada al punto de grilla como un poste y rota alrededor de ese punto.
2. **Menú radial cortado en la esquina superior izquierda.** Fix: anclas de pantalla completa puestas directamente en `player.tscn` (`anchor_right`/`anchor_bottom` = 1.0) en vez de calculadas por script en `_ready()`.
3. **El juego arrancaba con el modo construcción ya con la pared equipada.** Fix: `equipped_piece` ahora arranca en `"none"`, sin fantasma visible hasta abrir el menú con `G`.

**Próximo paso:** la usuaria vuelve a probar. Si queda bien, Milestone 1 se da por cerrado y se pasa a Milestone 2.

---

## 2026-07-04 (cont.) — Rediseño de la orientación de la pared

Segunda prueba: la pared, al rotar libremente con `R`, generaba un artefacto visual (un cono/cuña verde gigante) cuando el extremo libre apuntaba cerca de la cámara — clipping contra el plano cercano de la cámara. La usuaria propuso sacar la rotación manual directamente: la pared debe encajar sola en el lugar correcto, no rotarse a mano.

**Qué se hizo:**
- Sacada toda la lógica de rotación manual (`R` + mouse, `piece_rotation`, `rotating`, input `build_rotate`).
- Nueva función `_snap_wall()` en `build_system.gd`: según en qué mitad de la celda de 1m cae el punto apuntado (comparando la distancia al borde en X vs. en Z), la pared se posiciona y orienta sola sobre ese borde — sin intervención manual.
- Piso y techo siguen usando el snap centrado de siempre (`_snap_flat()`), sin cambios, porque son simétricos y no necesitan orientarse.
- Documentación actualizada en `docs/design/milestone1_construccion.md`.

**Dónde quedó:**
Milestone 1 debería estar más sólido ahora. Pendiente de una tercera prueba centrada en: colocar varias paredes formando las 4 paredes de una habitación y confirmar que encajan prolijas entre sí y con el piso.

**Próximo paso:** esperar el resultado de la prueba. Si cierra bien, pasar a Milestone 2 (escritorio + mini-juego).

---

## 2026-07-04 (cont.) — Milestone 1 confirmado + primeros assets reales

Tercera prueba: la usuaria armó una casa completa con las 4 paredes y quedó feliz — **Milestone 1 dado por cerrado**.

De paso, encontramos que había un merge sin resolver en git (la usuaria viene commiteando en paralelo, probablemente con GitHub Desktop, mientras yo trabajaba en el mismo working directory). Resuelto quedándonos con la versión local, que ya tenía todos los fixes; nada se perdió. Todavía sin pushear a GitHub.

**Qué se hizo (assets):**
- La usuaria bajó varios packs de Quaternius (`assets/building`, `farm`, `food`, `house_interior`, `nature`, `survival`), la mayoría en glTF, algunos solo en FBX.
- Reemplazados los cubos placeholder de `wall.tscn`, `floor.tscn` y `roof.tscn` por modelos reales del pack **Medieval Village MegaKit (Standard)** de Quaternius (CC0): `Wall_Plaster_Straight`, `Floor_WoodDark`, `Roof_Wooden_2x1`.
- Los módulos de este pack miden **2m** (no 1m) → se subió `grid_size` a 2.0 y `build_range` a 10.0 en `build_system.gd` para mantener el mismo alcance de 5 celdas.
- `BuildSystem` ahora busca recursivamente todos los `MeshInstance3D` dentro del fantasma (los modelos reales tienen varias mallas, a diferencia de los cubos placeholder) para pintarlos de verde/rojo.
- `CREDITS.md` actualizado con la fuente y licencia del pack.

**Dónde quedó:**
Milestone 1 completo y con arte real (aunque estilo "medieval", no necesariamente el look final del juego — es lo que había disponible y funciona bien para probar el sistema). El resto de los packs descargados (farm, food, house_interior, nature, survival) están en el proyecto pero todavía sin usar en ninguna escena.

**Próximo paso:** decidir si seguimos afinando el look de la construcción (ej. probar otras variantes de pared/piso dentro del mismo pack) o pasamos directamente a Milestone 2 (escritorio + mini-juego).
