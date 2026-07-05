# Proyecto: Vida en el Monte

Simulador de vida rural en primera persona (Godot). Ver `GDD_Vida_en_el_Monte.md` en la raíz para el diseño completo — no repitas ese contenido en el chat, referenciá el archivo cuando haga falta contexto de diseño.

Para convenciones técnicas y gotchas de Godot ya descubiertos (managers con registro dinámico, timestamps persistidos, escala de modelos importados, etc.), ver [docs/ESTANDARES_TECNICOS.md](docs/ESTANDARES_TECNICOS.md) — actualizarlo cada vez que aparezca un bug/decisión técnica nueva que valga la pena no repetir.

## Stack
- Godot 4.7, renderer **Compatibility** (hardware sin GPU dedicada — Intel Iris Xe integrada).
- Lenguaje: **GDScript únicamente**. No usar C#/.NET.
- Sin plugins/addons externos salvo que se pida explícitamente.

## Estructura de carpetas
```
res://
  ├── scenes/          (archivos .tscn)
  │   ├── player/
  │   ├── construccion/
  │   ├── cultivo/
  │   ├── trabajo/      (mini-juegos de dar clase)
  │   └── ui/
  ├── scripts/          (archivos .gd, mismo árbol que scenes/)
  ├── assets/            (packs de Quaternius, ya importados — no modificar contenido, solo usar)
  │   ├── nature/
  │   ├── food/
  │   ├── house_interior/
  │   ├── furniture/
  │   ├── survival/
  │   └── buildings/
  └── autoload/          (singletons: GameState, EconomyManager, etc.)
```

## Convenciones
- Archivos y carpetas: `snake_case`.
- Nodos en escenas: `PascalCase`.
- Señales para comunicación entre sistemas (construcción, cultivo, energía, agua no deben acoplarse directamente entre sí).
- Cada sistema central (construcción, cultivo, energía, agua, trabajo) vive en su propio autoload/manager singleton cuando corresponda.
- No ejecutar nunca Godot. De eso me encargo yo. Vos solamente programas.

## No tocar / cuidado
- `assets/` — son packs de terceros (Quaternius, CC0), no editar los modelos, solo instanciar/usar.
- No agregar sistemas fuera de scope del vertical slice actual sin confirmarlo primero (ver sección 7 del GDD).

## Tono de desarrollo
- Priorizar código simple y legible por sobre optimización prematura — es un proyecto personal, no un estudio con equipo.
- Sin penalización dura en ninguna mecánica de gameplay (consistente con el diseño): evitar estados de "game over" o fallos duros al programar sistemas.