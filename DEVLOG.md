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

---

## 2026-07-04 (cont.) — Pared no simétrica + techo flotando

Con los assets reales aparecieron dos problemas que los cubos placeholder no tenían (porque eran simétricos):

1. **Pared con una sola cara "linda"** (vigas de madera de un lado, lisa del otro). Con la lógica vieja (una orientación fija por eje) quedaba bien en 2 de las 4 paredes de una habitación y al revés en las otras 2.
2. **Techo flotando a mitad de pared** y bloqueando el paso: la pared mide 3m y la grilla vertical redondeaba de a 2m, así que nunca había un escalón que coincidiera con la punta de la pared.

**Primer intento (techo: bien / pared: mal):**
- Techo arreglado con altura fija (`wall_height` = 3.0), sin depender de la grilla vertical. Este quedó bien.
- Pared: se agregó un espejado de 180° según de qué lado de la celda estaba el *jugador* al apuntar. La usuaria probó y este arreglo estaba mal pensado: al caminar, la orientación de la pared fantasma cambiaba todo el rato (dependía de la posición del jugador, no de algo estable), y confirmó que 2 de las 4 paredes seguían mal incluso parada quieta.

**Arreglo definitivo de la pared:**
- La orientación ahora se decide con una consulta física a cada celda vecina (`_cell_has_floor`): la cara linda apunta siempre lejos del lado que ya tiene piso construido. Es 100% relativo al mundo ya construido, no al jugador — no debería cambiar más al caminar.
- Se agregó una tecla de emergencia (`F`) para invertir manualmente la pared fantasma si la detección automática se equivoca en algún caso, ya que no hay forma de probar esto visualmente sin que la usuaria lo juegue.
- De paso, se desactivó que el fantasma proyecte sombra (`cast_shadow = OFF`) — no afecta el bug de la pared, pero evita confundir una sombra de una pared ya puesta con el propio fantasma.

**Dónde quedó:** pendiente de una nueva prueba. Esta vez el fix no depende de la posición del jugador, así que caminar no debería romper nada — pero la dirección exacta (afuera vs. adentro) es una suposición sin poder verla en vivo; si queda al revés, es la tecla `F` o pedir un cambio de una línea.

---

## 2026-07-04 (cont.) — El "arreglo por piso" todavía dependía de la posición

La usuaria detectó (antes de probarlo) el problema de fondo antes de que yo lo viera: mi implementación de "orientarse por piso adyacente" comparaba la celda **cerca del jugador** contra la **lejos del jugador** al apuntar — y cuál es cuál depende de desde qué lado te parás a mirar el mismo borde. Verificado a mano: apuntando al mismo borde desde adentro vs. desde afuera de una habitación, dos aproximaciones distintas daban resultados opuestos aunque el piso construido fuera exactamente el mismo.

**Arreglo:** en vez de "cerca/lejos del jugador", ahora se comparan las dos celdas **fijas** a los lados de ese borde en términos absolutos (norte/sur o este/oeste), calculadas a partir de la posición del propio borde — nunca de la posición del jugador. Mismo borde físico → mismas dos celdas a comparar, sin importar desde dónde se apunte.

**Dónde quedó:** este debería ser el arreglo correcto de verdad (ya no hay forma de que dependa de la posición/dirección del jugador, matemáticamente). Falta la prueba en el editor.

---

## 2026-07-04 (cont.) — Este/oeste invertido (bug real, no de posición)

La prueba con dos paredes en escuadra mostró: norte/sur bien, este/oeste al revés. Esta vez lo resolví con la matriz de rotación de Godot (`Ry(θ)`) en vez de a ojo:
- Rama norte/sur (rotación 0°/180°): verificado a mano, consistente. `rot=0` efectivamente apunta la cara decorativa a +Z, `rot=180°` a -Z. Sin cambios.
- Rama este/oeste (rotación ±90°): acá estaba el bug real. Cuando escribí esta rama originalmente, elegí `rot=-90°` para "cara hacia el este" basándome solo en que la pared quedara bien *posicionada* (que abarque el segmento correcto), sin verificar hacia dónde apunta realmente la cara decorativa con esa rotación. Haciendo la cuenta: `rot=-90°` apunta la cara hacia **oeste**, no este — estaba invertido desde el principio. Arreglado invirtiendo qué rotación/esquina corresponde a `face_east=true` vs `false`.

**Dónde quedó:** las dos ramas (norte/sur y este/oeste) ahora están verificadas con la matriz de rotación real, no por prueba y error. Pendiente de confirmación jugando.

---

## 2026-07-04 (cont.) — El bug real: la detección de piso por física no funcionaba

La usuaria probó de nuevo y salió "exactamente al revés". En vez de seguir adivinando, agregué un `print()` en `_place_piece()` para loguear posición y rotación exacta de cada pared colocada, y le pedí los números en vez de fotos.

**Con los datos:** las 4 paredes mostraban un patrón clarísimo — todas las del lado negativo de su eje (oeste; y el equivalente sobre Z) quedaban mal, todas las del lado positivo quedaban bien, **sin importar el lado real de la habitación**. Eso significa que `_cell_has_floor()` (una consulta de física con `SphereShape3D` contra los pisos ya colocados) nunca estaba detectando el piso — siempre caía en el valor por defecto ("mirar hacia el lado positivo"), y por eso el lado positivo de cada eje salía bien "de casualidad" y el negativo siempre mal.

**Arreglo:** se sacó la consulta de física por completo. Ahora `BuildSystem` lleva su propio registro simple (`floor_cells: Dictionary`, celda → true) de dónde hay piso, actualizado directamente cuando se coloca/borra un piso — sin física de por medio, sin capas de colisión, sin radios de esfera que ajustar. Mucho más fácil de verificar leyendo el código.

**Dónde quedó:** pendiente de la prueba. El log de debug (`print` en Output) se deja por ahora como red de seguridad para poder diagnosticar con números si algo más sale mal.

---

## 2026-07-04 (cont.) — Milestone 1 cerrado de verdad

La usuaria armó una esquina con las 4 vigas cruzadas mirando para afuera en las dos caras — el registro de piso propio resolvió el bug de raíz. **Milestone 1 (construcción) completo.**

Se sacó el `print()` de debug de `_place_piece()` ahora que ya cumplió su función. Quedó documentado en [TASKS.md](TASKS.md) una lista corta de mejoras futuras no urgentes (más piezas, más de un piso, deshacer) para no perder la idea sin bloquear el avance a Milestone 2.

**Próximo paso:** Milestone 2 — escritorio de trabajo + mini-juego de "dar clase en vivo".
