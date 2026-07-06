# Estándares técnicos — Vida en el Monte

Convenciones de código y arquitectura acordadas a medida que se van descubriendo (no es un documento de diseño de gameplay, para eso ver el [GDD](GDD_Vida_en_el_Monte.md) y `docs/design/*.md`). Cada regla acá salió de un bug real encontrado jugando, no es teoría — así que si en algún momento deja de ser cierto o aparece un caso que no cubre, se actualiza el documento Y el código, no uno solo.

## Managers con registro dinámico (CropManager, InteractionManager, etc.)

Los autoloads que llevan una lista de objetos vivos (`CropManager.plantables`, `InteractionManager.interactables`) **no se auto-completan solos**. Se llenan de dos formas nada más:
1. Un escaneo único en su propio `_ready()` (`get_tree().get_nodes_in_group(...)`), que solo ve lo que ya existe en el árbol *antes* de que el autoload arranque (los autoloads corren su `_ready()` antes que la escena principal).
2. El camino explícito de restaurar partida guardada (ej. `CropManager.restore_plot()`, llamado desde `world.gd`).

**Regla:** cualquier objeto de ese tipo creado en vivo durante la partida (una parcela nueva colocada con el sistema de construcción, por ejemplo) tiene que registrarse a mano en el momento de crearlo — `CropManager.register_plantable(piece)` en `build_system.gd::_place_piece()`, no alcanza con que el manager lo "encuentre" solo.

**Por qué importa:** un bug real (05/07/2026) hizo que una parcela recién plantada nunca creciera — quedaba con el estado "creciendo" seteado pero el timer nunca la tickeaba, sin ningún error en consola. Al agregar un sistema nuevo con este mismo patrón (un manager + una lista de objetos que trackea), auditar todos los lugares donde ese tipo de objeto se puede crear en runtime y confirmar que llaman al `register_*()` correspondiente.

## Timestamps que se guardan en el save

**Nunca usar `Time.get_ticks_msec()` para algo que se persiste.** Mide milisegundos desde que arrancó el proceso del juego — se reinicia a 0 en cada sesión. Si se guarda un timestamp con eso y se lo compara contra el reloj de una sesión distinta (después de reabrir el juego), da resultados sin sentido (se vio un `-13.7s` de elapsed time en testing).

**Regla:** para cualquier timestamp que vaya a `SaveManager`/al JSON de guardado (timers de crecimiento, cooldowns, "tiempo desde X"), usar `Time.get_unix_time_from_system()` — hora real del sistema, consistente entre reinicios.

`Time.get_ticks_msec()` sigue siendo la opción correcta para cosas que **no** necesitan sobrevivir a un reinicio (animaciones, un cooldown que se resetea si cerrás el juego igual).

## Autoloads no son "Engine singletons"

**Nunca usar `Engine.has_singleton("NombreDelAutoload")` para chequear si un autoload existe.** Esa función es para singletons nativos/de motor (o los registrados a mano con `Engine.register_singleton()`), no para los definidos en `Project Settings > Autoload`. Para un autoload de GDScript, esa condición **siempre da `false`**, así que cualquier `if Engine.has_singleton("CropManager"):` cae siempre al `else` — código muerto que parece funcionar pero nunca corre la rama principal.

**Regla:** si algo está en `[autoload]` en `project.godot`, ya existe garantizado durante toda la partida — usalo directo (`CropManager.algo()`), sin chequeo previo.

## `queue_free()` vs `free()` al reemplazar un hijo con el mismo nombre

Si en la misma función se saca un nodo hijo y se agrega uno nuevo **con el mismo nombre**, usar `queue_free()` en el viejo rompe silenciosamente el reemplazo: `queue_free()` no borra el nodo hasta el final del frame, así que cuando se hace `add_child()` del nuevo con igual `name`, Godot lo renombra solo (`"PlantVisual"` → `"PlantVisual2"`) para no chocar. La próxima vez que se busca por ese nombre (`get_node_or_null("PlantVisual")`), ya no lo encuentra — y el reemplazo deja de funcionar para siempre, acumulando nodos viejos sin borrar.

**Regla:** cuando se reemplaza un nodo por otro de igual nombre en la misma función, usar `.free()` (inmediato) en vez de `.queue_free()`. Visto en `CropManager._set_plant_stage()` al ir cambiando el mesh de la planta entre etapas de crecimiento.

## Godot 3 → 4: no existe `.translation`

`Node3D` en Godot 4 no tiene la propiedad `translation` (quedó de Godot 3) — es `.position`. Si algo tipeado/pegado de un tutorial o código viejo usa `.translation`, va a tirar error de propiedad inválida.

## Instanciar un modelo externo (.glb/.fbx) y necesitar sus nodos internos

Al instanciar una escena externa como hijo (ej. un rig de manos, un árbol de personaje), Godot **bloquea/colapsa** sus nodos internos por defecto — no se pueden expandir ni seleccionar en el editor.

**Para poder tocarlos** (agregar un `BoneAttachment3D` a un hueso, por ejemplo): clic derecho sobre el nodo instanciado → **"Hijos Editables"**. Recién ahí se puede expandir el árbol interno.

**Para referenciarlos desde código sin rutas gigantes:** en vez de un `$Camino/Larguisimo/Anidado/Hasta/El/Hueso`, marcar el nodo puntual con **"Acceso como Nombre Único"** (clic derecho → esa opción, o en el `.tscn` la propiedad `unique_name_in_owner = true`), y referenciarlo desde el script del nodo raíz de la escena con `%NombreDelNodo`. Funciona incluso dentro del árbol de "Hijos Editables" de una escena instanciada, porque el owner queda seteado a la raíz de la escena contenedora.

## Modelos 3D de terceros con escala rara

Los packs de Quaternius (que ya usa el proyecto) vienen con la escala correcta. Modelos bajados de otros lados (Sketchfab, etc.) a veces no — vienen en centímetros en vez de metros, y aparecen 100x más grandes de lo esperado (al punto de que la cámara termina "adentro" de la geometría y se ve todo negro).

**Cómo diagnosticar:** si algo se ve gigante o no aparece en absoluto, sospechar de la escala antes que de la posición — mover un objeto mal escalado nunca lo arregla, porque escalar y mover son cosas independientes.

**Dónde arreglarlo (dos opciones, se usó la primera por prolija):**
1. En el import del archivo (`.import`, o pestaña "Importar" en el editor): el campo `nodes/root_scale`. Se corrige una sola vez para todo lo que use ese asset.
2. Si hace falta un ajuste puntual nada más para un nodo específico (ej. porque el hueso de un rig no hereda la corrección del import — visto con `BoneAttachment3D`, ver más abajo), un `Scale` chico en el nodo local.

**Caso particular con huesos:** un `BoneAttachment3D` puede quedar con una escala completamente distinta a la del resto del modelo visual, incluso después de corregir el import del modelo entero — el hueso puede seguir viviendo en la escala "original" sin corregir. Si algo colgado de un hueso se ve gigante mientras el modelo alrededor se ve bien, corregir la escala ahí puntualmente (en el hijo del `BoneAttachment3D`, no en el hueso en sí).

## Destruir piezas construidas: herramienta explícita, no un click global

Destruir una pieza construida (`build_system.gd`) es una herramienta más del catálogo de construcción (`G` → "Destruir"), igual que equipar una pared — **no** un botón (como click derecho) que funcione en cualquier momento sin que el jugador lo haya elegido a propósito. Al apuntar con esa herramienta equipada, la pieza se resalta en rojo (reusando el mismo material que ya se usa para mostrar que una pieza no se puede colocar ahí — mismo lenguaje visual, nada nuevo que aprender) y un click la destruye.

**Por qué:** evita destrucción accidental, y reusa un patrón de interacción que el proyecto ya tiene (equipar herramienta del catálogo → click para actuar) en vez de inventar uno nuevo.

**Reembolso al destruir:** antes de borrar una pieza, `_refund_piece_contents()` le devuelve al inventario lo que tuviera "adentro" (hoy: una semilla si la parcela tenía un cultivo plantado). Si una categoría nueva necesita devolver algo al destruirla, se suma ahí con otro `if`, no hace falta un sistema aparte.

## Interacciones herramienta → objeto: tabla de acciones por estado, no if/elif encadenados

Cuando un sistema tiene "estados de un objeto" x "herramientas que actúan sobre él" (ej. una parcela de huerta: vacía/creciendo/lista, y semilla/regadera/lo que venga), **no** escribir un `if estado == X and tool_id == Y: ... elif ...` que crece sin límite con cada herramienta nueva. Ese patrón mezcla todos los casos en una sola función y cualquier cambio arriesga romper un caso que no tiene nada que ver.

**Patrón usado (`CropManager`, ver `_state_actions`):**
1. Un diccionario `estado -> {tool_id -> Callable}` construido en `_ready()` (no puede ser `const` porque un `Callable` a un método de `self` recién existe con el nodo ya en el árbol).
2. Cada acción (`plant_seed`, `water_plot`, `harvest_plot`) es un método **público y autocontenido**: hace su propia transición de estado, actualiza visuales/label, emite sus señales — nada de lógica de "qué puede hacer qué" queda adentro de la acción misma.
3. `interact()` queda como un dispatcher fino: casos especiales que no dependen de la herramienta (cosechar, acá, no depende de qué tengas equipado) se resuelven aparte, arriba; el resto busca en la tabla y listo.

**Por qué así y no una abstracción más pesada (ej. clases "Tier1Watering"/"Tier2Watering"):** el GDD define niveles de riego (regadera manual, manguera, riego automatizado) que dependen de sistemas que todavía no existen (red de agua, red eléctrica). Diseñar esa jerarquía de clases ahora sería adivinar su forma antes de construir esos sistemas — con la tabla de acciones alcanza: agregar la manguera más adelante es una línea nueva (`"growing": {"watering_can": water_plot, "hose": water_plot}`, o una función `water_plot_from_hose` si el comportamiento difiere), sin tocar `interact()` ni las acciones existentes. Si en el futuro la variedad de "cómo se riega" crece mucho (ej. distintas duraciones, requiere estar conectado a una red), recién ahí vale la pena extraer eso a datos/clases — no antes.

**Regla:** cualquier acción llamable así (`plant_seed(plot, inventory=null)`, etc.) también tiene que poder llamarse **sin pasar por `interact()`** — por eso son públicas y el segundo parámetro tiene default. Un futuro riego automatizado, por ejemplo, va a tickear en su propio `_process()` y llamar `CropManager.water_plot(plot)` directo, sin `tool_id` ni jugador de por medio.

## Herramienta (click) vs. interactuar (E): son inputs distintos, a propósito

Convención de controles: **click izquierdo** es "usar lo que tengo equipado en la mano" (plantar semilla, regar, colocar/destruir una pieza de construcción); **`E`** es "interactuar/agarrar" — cosechar un cultivo listo, sentarse al escritorio, cualquier interactuable genérico. No dependen de la misma herramienta ni se disparan con el mismo evento.

**Por qué:** antes ambas cosas vivían atrás de `E` (plantar, regar y cosechar mezclados en la misma tecla). Separarlas es más intuitivo (un solo botón por concepto: "hago algo con la herramienta" vs. "agarro/interactúo") y evita ambigüedad — cosechar, por ejemplo, no depende de qué tengas equipado, así que tiene sentido que sea un input aparte del que sí depende de la herramienta.

**Cómo está armado (`world.gd`):** `_handle_tool_use_click()` (click izquierdo) llama a `CropManager.use_tool(plot, tool_id, inventory)` — solo planta/riega, nunca cosecha, aunque la parcela esté lista. `_handle_interact()` (`E`) llama a `CropManager.harvest_plot()` directo — solo cosecha, nunca planta ni riega. `CropManager.interact()` sigue existiendo como punto de entrada combinado (por si algún interactuable genérico necesita "hacé lo que corresponda" en una sola llamada), pero `world.gd` ya no lo usa para huerta.

**Evitar que el click choque con construcción:** `_handle_tool_use_click()` chequea `build_system.equipped_category != "none"` y no hace nada si es así — mientras estás construyendo/destruyendo con el catálogo, ese click ya es suyo.

**Regla de oro que esto forzó:** cualquier acción pública de un manager (`plant_seed`, `water_plot`, `harvest_plot`) tiene que validar el estado **adentro suyo**, no confiar en que quien la llama ya chequeó — porque ahora hay más de un lugar llamándolas por separado. Se encontró y arregló un bug real por esto: `harvest_plot()` no chequeaba `crop_state == "ready"`, así que llamarla directo desde `E` sobre una parcela vacía la "cosechaba" igual, regalando una Zanahoria gratis.

## JSON y Dictionary con claves numéricas

`JSON.stringify()` convierte **todas** las claves de un `Dictionary` a string, sin excepción. Si algo como `Hotbar.items` (claves `int`: `0, 1, 2...`) se guarda tal cual y se lee de vuelta con `JSON.parse_string()`, las claves vuelven como `"0", "1", "2"` (string) — cualquier `items.has(0)` o `items[slot]` con `slot: int` deja de encontrar nada, porque `0 != "0"` como clave de Dictionary en GDScript.

**Regla:** al restaurar un Dictionary con claves numéricas desde el guardado, reconstruirlo a mano convirtiendo cada clave con `int(key)`. Ver `Hotbar.apply_save_data()`.

## Sistema de guardado — estado actual y deuda conocida

`SaveManager` arma un único diccionario JSON llamando a cada sistema. La mayoría todavía usa nombres de método ad-hoc (`Economy.money` leído directo, `build_system.serialize_pieces()`, `world.serialize_crops()`), pero **`Hotbar` ya adoptó el contrato estándar** (`get_save_data() -> Dictionary` / `apply_save_data(data: Dictionary)`) — es el primero, y el criterio para cualquier sistema nuevo que persista algo (hambre/sueño, día-noche) es usar ese mismo contrato, no inventar otro nombre.

**Por qué importa el cableado manual:** cada sistema nuevo que necesite persistir requiere acordarse de sumarlo a mano en `save_manager.gd`. Dos bugs reales pasaron por esto: la parcela que no crecía al recargar (existían dos copias de la lógica de restaurar, una vieja y muerta en `world.gd`, desincronizada de la real en `CropManager`), y el inventario que **directamente nunca se guardaba** — cada reinicio volvía a la semilla inicial hardcodeada, perdiendo cualquier semilla extra, la regadera comprada, o comida cosechada.

**Mejora pendiente (parcial):** migrar `Economy`/`build_system`/`world` al mismo contrato `get_save_data()`/`apply_save_data()` que ya usa `Hotbar`, y que `SaveManager` mantenga una lista corta de sistemas registrados en vez de llamar a métodos con nombres distintos por sistema. No es urgente romper lo que ya funciona, pero cualquier sistema *nuevo* de acá en adelante debería nacer con el contrato nuevo directamente.

## Colocación en construcción: validar por slot de grilla, no por choque físico de formas

**Historia (06/07/2026):** la validez de colocar una pieza (`build_system.gd`) arrancó como un `intersect_shape()` contra la caja de colisión real de cada pieza. Se fue parcheando tres veces seguidas para casos distintos — bloqueaba pared-sobre-piso (categorías distintas que están pensadas para tocarse), después se descubrió que ignoraba el offset del `CollisionShape3D` (pared/techos con offsets grandes probaban colisión en el lugar equivocado del mundo), y después que dos paredes en ángulo recto cerrando una esquina de habitación **siempre** se solapan un poco de verdad (cada una asoma la mitad de su espesor sobre el extremo de la otra). Cada parche arregló su caso pero el enfoque de fondo estaba mal: la geometría real de cada mesh (cajas con formas y offsets distintos por pieza) no tiene por qué reflejar qué combinaciones de piezas son válidas — eso es una decisión de diseño (qué categorías pueden compartir un lugar), no un hecho físico.

**Solución actual:** `occupied_slots` — un diccionario `category (String) -> {Vector3i -> true}`. La posición ya sale snappeada a la grilla (`_snap_flat`/`_snap_wall`, ver `_ray_plane_point` para el techo más abajo), así que "misma categoría + misma posición cuantizada" alcanza para saber si un lugar está ocupado, sin mirar la forma de colisión de nadie. `_slot_taken()`/`_register_slot()`/`_unregister_slot()` son los únicos puntos de contacto — se llaman desde `_process()` (validar el fantasma), `_place_piece()`, `_demolish_hovered()` y `load_pieces()`. Es la misma idea que ya usaba `floor_cells` para pisos, generalizada a todas las categorías.

**Por qué esto no vuelve a romperse con una pieza nueva:** categorías distintas nunca compiten por el mismo slot (conviven en el mismo lugar a propósito — pared sobre piso, techo sobre pared), y dentro de la misma categoría, dos piezas en la posición exacta sí compiten (dos pisos en la misma celda, dos paredes en el mismo borde) — sin depender de cuán rara sea la caja de colisión de esa pieza en particular.

**Regla:** cualquier categoría nueva que registre piezas tiene que pasar por `_register_slot()`/`_unregister_slot()` en los mismos cuatro puntos de arriba. No agregar de nuevo un chequeo de colisión física para decidir si una pieza "entra" — eso fue exactamente lo que se sacó.

## Puertas: la colisión necesita un hueco real, no una caja sólida heredada de la pared

`wall_door.tscn` originalmente copiaba la misma `BoxShape3D` sólida de `wall.tscn` — el modelo 3D tenía el agujero de la puerta, pero la física bloqueaba igual que una pared entera (bug real: jugadora encerrada en su propia casa).

**Regla:** una pieza con una abertura pensada para caminar a través necesita **más de una `CollisionShape3D`** (dintel arriba + jambas a los costados), dejando el hueco de la abertura sin ninguna forma de colisión — nunca una sola caja que cubra todo el rectángulo de la pared. Ver `wall_door.tscn`: dintel (`Vector3(2, 0.8, 0.4)`, cubre de y=2.2 a y=3) + dos jambas (`Vector3(0.5, 3, 0.4)` cada una, a los costados), dejando libre un hueco de 1m de ancho por 2.2m de alto (la cápsula del jugador mide 1.8m, ver `player.tscn`).

**Por qué importa para el fantasma de construcción:** `build_system.gd::_spawn_ghost()` tiene que deshabilitar **todas** las `CollisionShape3D` hijas directas de la pieza (`_find_direct_collision_shapes()`), no solo buscar una por nombre fijo (`get_node("CollisionShape3D")`) — si una pieza nueva tiene varias colisiones (como la puerta), quedarse con una sola dejaría al fantasma bloqueando físicamente al jugador mientras lo tiene equipado, con las demás formas todavía activas.

## Techo: la posición se calcula con un plano, no con un raycast físico

`_process()` decidía dónde ubicar el fantasma tirando un raycast físico y snappeando lo que golpeara (`_cast_build_ray()`), igual para las cuatro categorías. Funciona para pared/piso/escritorio porque siempre apuntás a algo sólido (el piso, una pared existente), pero se rompe para el techo: la celda del medio de una cumbrera sin terminar tiene **cielo abierto arriba y nada sólido dentro de `build_range`** — sin nada contra qué chocar, `in_range` daba `false` sin importar el ángulo (bug real 06/07/2026: "ninguna orientación encaja" al cerrar la fila del medio de un techo a dos aguas). Mirando desde otro ángulo, el rayo a veces pegaba primero contra el Faldón vecino (que abomba un poco hacia el medio) y snappeaba a esa celda ya ocupada, en vez de a la vacía.

**Regla:** el techo se coloca en un plano horizontal fijo (`wall_height`), así que su posición se calcula con `_ray_plane_point()` — intersección matemática del rayo de la cámara con ese plano — en vez de depender de que el rayo choque contra algo. Cualquier categoría futura que viva en un plano fijo en vez de "sobre lo último que tocaste" (ej. un segundo piso a una altura fija) debería usar el mismo patrón, no `_cast_build_ray()`.

## Techo: el asset está modelado en un módulo de 2×1, no 2×2 — necesita su propia grilla

Bug real (06/07/2026, reportado como "los assets del techo no cubren el slot"): cada pieza de techo del pack "Medieval Village MegaKit" es literalmente un `Roof_Wooden_2x1*.gltf` — el nombre del archivo lo dice: están modeladas en un módulo de 2×1, mientras que pared/piso/escritorio/decoración usan un módulo de 2×2 (`grid_size`). Colocar techo con la misma grilla de 2×2 que todo lo demás dejaba cada pieza cubriendo solo la mitad de su celda — el hueco no era un bug de colocación, era un desfase real entre el tamaño del módulo del asset y el tamaño de celda que usa el resto del kit.

**Regla:** `_snap_roof()` (no confundir con `_snap_flat()`, que usan pared/piso/escritorio) snappea con `grid_size` en el eje largo del mesh (el "2", a lo largo de la cumbrera) y con `grid_size / 2.0` en el eje corto (el "1", a lo largo de la pendiente) — así una celda de piso de 2×2 necesita **dos** piezas de techo, una al lado de la otra en el eje corto, para quedar cubierta entera. Qué eje del mundo es cuál depende de `rotation_steps` (par = eje largo en X, impar = eje largo en Z) — mismo criterio que la dimensión larga de `wall.tscn`, que también corre en su X local.

**Si se agrega un asset nuevo con un módulo que no sea 2×2:** revisar el nombre del archivo/las dimensiones reales del modelo antes de asumir que encaja en `grid_size` — este bug pasó desapercibido varias sesiones porque nadie miró el nombre del `.gltf` hasta que el hueco se hizo evidente jugando.

## Visuales de debug: pasan por `DevMode`, nunca hardcodeados a siempre-visible

Cualquier visual que exista solo para verificar que la lógica funciona durante el desarrollo (ej. el `Label3D` "StateLabel" de `CropManager` mostrando el estado interno de una parcela) **no puede quedar visible incondicionalmente** — rompe la regla de inmersión/realismo del PXD (`docs/GameDesign/PXD_Diseno_HUD_UI_v1.md`, sección 1.1): en el juego final solo debe verse el prompt de interacción, nunca texto de debug flotando sobre objetos del mundo.

**Regla:** ese tipo de visual se crea/actualiza igual que siempre, pero su `visible` se controla con el autoload `DevMode` (`DevMode.enabled`, default `false`, toggle con `F1` vía la acción `toggle_dev_mode`) — no con un `@export` propio del nodo ni un flag nuevo por sistema. Al agregar un visual de debug nuevo: suscribirse a `DevMode.toggled` (o consultar `DevMode.enabled` al crearlo) para que se oculte/muestre junto con todo lo demás, un solo interruptor para todo el proyecto.
