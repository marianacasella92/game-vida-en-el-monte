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

## `queue_free()` y consultas de física/grupos en el mismo frame: los "fantasmas" siguen ahí

Otra cara del mismo problema de arriba: un nodo `queue_free()`-ado sigue **vivo, en sus grupos y colisionando** hasta el final del frame. Si en ese mismo frame se recorre un grupo (`get_nodes_in_group`) o se hace una consulta de física (`intersect_shape`/`intersect_ray`), los nodos por borrarse aparecen como si nada — y los recién creados también, así que se ven duplicados.

**Caso real (07/07/2026):** al despertar del desmayo, `load_game()` hace `clear_pieces()` (queue_free de todo lo construido) + `load_pieces()` (recrea lo guardado) — si `_respawn_beside_bed()` corriera en ese mismo frame, vería dos copias de cada pieza: podría elegir una cama por borrarse, o marcar como "ocupados" lugares bloqueados solo por colliders fantasma.

**Regla:** después de un borrado masivo con `queue_free()` + recreación, cualquier lógica que consulte grupos o física espera un frame (`await get_tree().process_frame`) antes de correr. Ver `save_manager.gd::_on_player_died()`.

## Editar `.tscn` a mano: los enums son números — verificarlos, no adivinarlos

Bug real (07/07/2026, reportado como "el círculo quedó enorme atravesando el corazón"): al armar el corazón de dos capas se escribió `stretch_mode = 1` en un `TextureRect` asumiendo que 1 era "escalar" — pero en `TextureRect.StretchMode`, **1 es `STRETCH_TILE`** (repetir la textura a tamaño nativo, 268px dentro de una caja de 98px = se ve un pedazo gigante). El valor correcto para "escalar manteniendo aspecto, centrado" es `5` (`STRETCH_KEEP_ASPECT_CENTERED`), que es el que ya usaban los demás íconos del HUD.

**Regla:** al escribir propiedades enum a mano en un `.tscn`, no adivinar el número — verificar contra la documentación de la clase o contra otro nodo del proyecto que ya use el valor correcto (los íconos existentes del HUD son la referencia rápida para `TextureRect`). Si un ícono/textura se ve gigante o recortado, sospechar primero de `stretch_mode`/`expand_mode` antes que del asset.

## Ícono "medidor" de dos capas (corazón de vida): TextureProgressBar + marco fijo encima

Técnica del corazón que se vacía (PXD sección 2, reusable para cualquier ícono-medidor futuro): el asset se separa en dos PNG **del mismo lienzo** (acá los hizo la usuaria: `icon_health_heart.png` + `icon_health_frame.png`), y en la escena son dos capas dentro de un `Control` — abajo un `TextureProgressBar` con la parte que se vacía (`texture_progress`, `fill_mode = 3` BOTTOM_TO_TOP para que se recorte de arriba hacia abajo, `nine_patch_stretch = true` para que escale al tamaño del HUD), encima un `TextureRect` con la parte fija. Mismo lienzo = las dos capas quedan alineadas con solo anclarlas al mismo rect. Ver `player.tscn` (`Hud/Root/HealthIcon`) y `hud.gd::_update_health()`.

## Ediciones externas a `project.godot` (autoloads, input map): recargar el proyecto

Con el flujo de trabajo de este proyecto (Claude edita archivos mientras el editor de Godot está abierto), cualquier cambio externo a `project.godot` — un autoload nuevo, una acción de input nueva — **no se aplica hasta recargar el proyecto** (Proyecto → Volver a Cargar el Proyecto Actual, o cerrar y reabrir Godot). Síntoma típico (visto 07/07/2026 al agregar `UIState`): lluvia de `Parse Error: Identifier "X" not declared in the current scope` sobre un autoload que sí está registrado en el archivo — el parser del editor todavía trabaja con la lista vieja. Los `.gd`/`.tscn` sueltos sí se recargan solos; `project.godot` no.

`Node3D` en Godot 4 no tiene la propiedad `translation` (quedó de Godot 3) — es `.position`. Si algo tipeado/pegado de un tutorial o código viejo usa `.translation`, va a tirar error de propiedad inválida.

## Godot 3 → 4: no existe `SCREEN_TEXTURE` en shaders — y un shader roto pinta el ColorRect de blanco

Bug real (07/07/2026, reportado como "pantalla blanca" al bajar la vida): en Godot 4 el built-in `SCREEN_TEXTURE` de canvas_item shaders no existe más — hay que declararlo como uniform: `uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_linear;` y muestrear con `texture(screen_texture, SCREEN_UV)`. Con la sintaxis vieja el shader **no compila**, y un `ColorRect` con material roto se dibuja con su color plano — que por default es **blanco opaco**, pantalla entera.

**El mismo bug estuvo oculto desde el principio en `background_blur.gdshader`** (el fondo del inventario): nunca compiló, pero nadie lo notó porque ese ColorRect tenía color negro semitransparente de fallback — se veía "oscurecido sin blur" y pasaba por diseño. Los errores sí aparecían en la consola del editor (`E 16-> sum += textureLod(SCREEN_TEXTURE...`), mezclados con otros logs.

**Reglas:** (1) en todo shader que lea la pantalla, usar la sintaxis de uniform de Godot 4, nunca `SCREEN_TEXTURE`/`textureLod(SCREEN_TEXTURE...)` de tutoriales viejos; (2) todo `ColorRect` con ShaderMaterial lleva `color = Color(0, 0, 0, 0)` como fallback — si el shader falla, no se ve nada en vez de una pantalla blanca; (3) si un efecto de shader "no se nota", revisar la consola antes de ajustar parámetros — puede que directamente no esté compilando.

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

## Checklist: agregar una categoría nueva de pieza colocable (build_system.gd)

Resumen rápido — el detalle y el "por qué" de cada punto está en las secciones de abajo, esto es solo el orden de pasos para no repetir los mismos bugs:

1. **Sumarla al `CATALOG`** (categoría + variante + `.tscn`).
2. **Medir el tamaño real del mesh antes de poner un `BoxShape3D` a ojo.** La caja de colisión tiene que cubrir lo que se ve, ni más ni menos — ver "Cajas de colisión estimadas a mano vs. tamaño real del mesh" más abajo. Una caja subestimada deja que el modelo visual sobresalga de su propia colisión sin que nada lo note.
3. **¿Su módulo real coincide con `grid_size` (2×2)?** Si no (como el techo, modelado en 2×1), necesita su propia función de snap — ver "Techo: el asset está modelado en un módulo de 2×1". No asumir que todo encaja en `grid_size` solo porque pared/piso lo hacen.
4. **¿Necesita auto-encajarse según lo ya construido al lado?** Eso es un caso especial de verdad (hoy solo lo necesita "wall", ver `_snap_wall`) — no entra en el paso 5.
5. **Para todo lo demás:** sumarla a `CATEGORY_BEHAVIOR` (`build_system.gd`, se arma en `_ready()`) con `"rotatable"`/`"furniture"` según corresponda — ver "Categorías por comportamiento: una sola tabla, no dos listas + if/elif" más abajo. Es la única tabla que hace falta tocar.
6. **¿Tiene una abertura para caminar a través (puerta, arco)?** Necesita más de un `CollisionShape3D` (dintel + jambas), nunca una sola caja sólida — ver "Puertas: la colisión necesita un hueco real".

El mismo checklist vive también como comentario en `build_system.gd`, arriba de `CATEGORY_BEHAVIOR`.

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

## Cajas de colisión estimadas a mano vs. tamaño real del mesh — mismo bug de fondo, versión mobiliario

Bug real (07/07/2026): la cama (`bed.tscn`) sobresalía de la casa y atravesaba paredes/muebles vecinos. La caja de colisión (`BoxShape3D`, estimada a mano al crear la pieza — ya había una nota en `TASKS.md` avisando que esto podía pasar) medía `1.1 x 1.0 x 2.1`. El tamaño real del mesh (`Bed Single.glb`) es `~1.98 x 1.35 x 3.94` — casi el doble de largo. **Resuelto:** se corrigió la caja de colisión al tamaño real.

**Mobiliario que no debería superponerse entre sí:** cama/escritorio/decoración ahora comparten un balde de ocupación (`"furniture": true` en `CATEGORY_BEHAVIOR`, `build_system.gd`) en vez de uno por categoría — antes un escritorio y una cama podían coexistir en el mismo punto exacto sin que el sistema lo notara, porque cada categoría tenía su propio diccionario aislado.

**Lo que NO se hizo, a propósito:** con `grid_size = 2.0`, la cama en realidad pisa **3 celdas** (la propia + ~0.95m de cada vecina, al estar centrada en su origen en vez de alineada a un borde como una pared). Se armó y se descartó en la misma sesión un sistema de "huella multi-celda" (`FOOTPRINT_SPECS` + reserva de varias celdas según eje/rotación) para que `occupied_slots` reservara las 3 celdas automáticamente — la usuaria lo frenó por exceso de complejidad de código. **Regla para el futuro:** no reintroducir ese sistema salvo que haga falta para varias piezas a la vez y valga la pena la complejidad.

**El bug real seguía sin resolverse — corregir la caja de colisión no evita chocar contra una pared:** después de arreglar el tamaño, la cama seguía atravesando paredes sin que el fantasma se marcara inválido. La razón: `_slot_taken()` (el sistema de slots de grilla) solo compara "un punto por categoría" — nunca chequeó geometría real contra otras categorías (pared incluida). Un mueble más grande que su celda puede pisar una pared sin que ese sistema se entere. **Regla:** para mobiliario (`"furniture": true`), `_process()` además llama a `_overlaps_wall()` — un `intersect_shape()` real con la colisión ya corregida del fantasma contra las paredes construidas — antes de dar el fantasma por válido. `_slot_taken()` sigue siendo el chequeo liviano para todo lo demás (pared/piso/techo/huerta, y mobiliario-contra-mobiliario); `_overlaps_wall()` es la excepción puntual para cuando la geometría real sí importa.

**Segunda vuelta — ese chequeo era demasiado estricto:** con `_overlaps_wall()` recién agregado, CUALQUIER mueble apoyado contra una pared (no solo la cama) se marcaba inválido con solo tocarla. Causa: `wall.tscn` tiene 0.4m de espesor, centrado en el borde de la celda — la mitad de ese espesor (0.2m) siempre se mete en la celda vecina donde vive el mobiliario, así que un mueble de más de ~1.6m en la dirección que mira a la pared ya la toca aunque esté perfectamente centrado en su celda. Es geometría estructural del kit, no un caso raro. **Regla:** `_wall_check_shape()` recorta `WALL_OVERLAP_MARGIN` (0.4, el espesor de una pared) de cada eje de la caja **solo para este chequeo**, nunca para la colisión real jugable — mismo patrón que ya se usó para tolerar que dos paredes compartan una esquina (ver sección de techo/paredes más arriba). Así "apoyado justo contra la pared" da válido, pero una intrusión de verdad (como la cama metida medio metro adentro) sigue superando el margen y se marca inválida.

## Categorías por comportamiento: una sola tabla, no dos listas + if/elif

**Historia:** primero apareció un bug real (07/07/2026) porque la cama nunca rotaba con `build_rotate` — `"bed"` faltaba de dos chequeos idénticos `equipped_category == "roof" or equipped_category == "desk" or equipped_category == "decor"`, uno en `_unhandled_input` (incrementa `rotation_steps`) y otro en `_process` (aplica `rotation_steps` al ángulo final). Se agregó la categoría a un `or` y se olvidó el otro. El arreglo inmediato fue una constante `ROTATABLE_CATEGORIES` consultada con `in` en los dos lugares. Después se sumó `FURNITURE_CATEGORIES` (mismo patrón, para el balde de ocupación compartido). Con dos listas paralelas más los if/elif de `_process()` decidiendo qué función de snap llamar por categoría, `build_system.gd` volvió a acercarse a la deuda técnica ya anotada desde el Milestone 1 ("Desacoplar la lógica de `build_system.gd`").

**Solución actual:** `CATEGORY_BEHAVIOR` — un diccionario `category -> {"targeting": "ray"|"plane", "snap": Callable, "rotatable": bool, "furniture": bool}`, armado en `_ready()` (no puede ser `const`: un `Callable(self, ...)` recién existe con el nodo ya en el árbol, mismo motivo que `_state_actions` en `CropManager`). Reemplaza `ROTATABLE_CATEGORIES` + `FURNITURE_CATEGORIES` + los if/elif de `_process()` que decidían la función de snap por categoría. `"wall"` queda deliberadamente afuera de esta tabla: es la única categoría con auto-encaje según lo ya construido al lado (`_snap_wall`), un comportamiento realmente distinto al resto — forzarla a la misma forma hubiera sido peor que dejarla como caso especial explícito.

**Por qué esto no vuelve a crecer sin control:** agregar una categoría nueva que se posiciona plana (con o sin rotación, con o sin compartir balde de mobiliario) es sumar **una entrada** a `CATEGORY_BEHAVIOR` — ni `_unhandled_input()` ni `_process()` necesitan una rama nueva, leen la tabla con `.get(category, {}).get(campo, default)`. Una categoría no listada usa el comportamiento por defecto (no rota, no es mobiliario, apunta con raycast, snappea con `_snap_flat`) — el mismo que ya tenían piso/huerta antes del refactor.

**Regla:** cualquier comportamiento transversal por categoría (rota, comparte balde, targeting especial, etc.) vive en esta tabla, nunca como una lista nueva consultada con `in` en dos lugares por separado — eso es exactamente el patrón que se acaba de sacar.

## Piezas que se equipan desde el inventario (no desde el catálogo de `G`)

Cama, escritorio y cajón de madera pasaron de "desbloqueo permanente" (`Economy.purchased_items`, visibles siempre en el catálogo de `G` una vez comprados) a **ítems físicos de inventario**: se compran cuantas veces se quiera (`grants_item` en `marketplace_ui.gd`, igual que semillas/regadera), se suman a `Backpack`/`Hotbar`, y quedan **ocultas del catálogo de `G`** (no tiene sentido elegirlas ahí si no las tenés en la mochila).

**Cómo se conecta con `build_system.gd`:**
- `CATALOG` marca la variante con `"inventory_item": "<item_id>"` (el id que usa `Backpack.add_item`) y `"hidden_from_catalog": true`. Ver el comentario completo sobre estos dos campos arriba de `CATALOG`.
- `_inventory_item_to_piece` (`item_id -> {category, variant}`) se arma en `_ready()` recorriendo `CATALOG` — **nunca a mano aparte**, mismo criterio que `CATEGORY_BEHAVIOR`: una tabla derivada de una sola fuente, no dos listas para desincronizar.
- `_on_hotbar_changed()`, conectado a `Hotbar.inventory_changed`, mira qué ítem quedó seleccionado en el hotbar: si mapea a una pieza, la equipa (`_equip()`) como si se hubiera elegido en el catálogo; si el jugador cambia a otra cosa (u otro slot vacío) mientras había una pieza equipada así, la suelta (`_exit_build_mode()`). `_equipped_via_inventory` distingue esto de una pieza equipada por catálogo, para no interferir con pared/piso/techo/puerta (que no cambiaron).
- `_place_piece()` gasta 1 del stack del hotbar al colocar con éxito (`Hotbar.remove_item()`) — si era el último, ese mismo `remove_item()` dispara `inventory_changed` de nuevo y `_on_hotbar_changed()` suelta la pieza sola, sin lógica extra.

**Por qué no se tocó nada de pared/piso/techo/garden:** siguen exactamente con el flujo de catálogo de siempre (`_on_piece_chosen()`, llamado solo desde `catalog_menu.gd`). El nuevo camino (`_on_hotbar_changed()`) es aditivo, no reemplaza el existente — dos puertas de entrada al mismo `_equip()`, cada una para su tipo de pieza.

**Bug real (07/07/2026): comprar entraba en modo construcción sola.** `Backpack.add_item()` (el punto de entrada normal para "darle un ítem a la jugadora") intenta meter todo ítem nuevo en el **hotbar** primero, para acceso rápido — no tiene forma de saber que una pieza de construcción no debería auto-equiparse. Si la compra caía justo en el slot del hotbar que ya estaba seleccionado, `_on_hotbar_changed()` no podía distinguir eso de "la jugadora lo eligió a propósito" (ambos casos se ven igual desde `Hotbar`: el slot seleccionado ahora tiene ese ítem) — y entraba en modo construcción sin que nadie lo pidiera.

**Regla:** cualquier ítem que dispare un efecto con solo estar en el hotbar seleccionado (como activar modo construcción) tiene que **entrar siempre por la mochila**, nunca directo al hotbar — usar `Backpack.add_item_no_hotbar()` en vez de `Backpack.add_item()`. `marketplace_ui.gd` lo marca con `"skip_hotbar": true` en la entrada de `ITEMS` correspondiente. La jugadora arrastra el ítem al hotbar ella misma cuando quiere equiparlo — recién ahí es una acción explícita, no un efecto colateral de comprar.

## Muerte por descuido (GDD 4.8) recarga el guardado en silencio — necesita aviso

Bug real (07/07/2026), reportado como "el autoguardado me pisó la construcción": `save_game()` (`save_manager.gd`) solo escribe a disco, nunca toca el mundo — no podía ser el culpable. El mecanismo real: `PlayerNeeds._process_health()` baja la vida de a poco si hambre o sueño quedan descuidados (`is_neglected()`) y, al llegar a 0, emite `died`; `SaveManager._on_player_died()` escucha esa señal y llama `load_game()`, que sí revierte piezas construidas/inventario/plata al último guardado — **sin ningún feedback visual**. Absorta construyendo (sin comer/dormir), la jugadora no se enteraba de que había "muerto" hasta ver su casa a medio construir desaparecer.

**Regla:** cualquier mecánica que revierta/descarte estado del jugador (esta es la única del juego, a propósito según el GDD) tiene que dar aviso explícito en el momento en que pasa — nunca una recarga silenciosa. Ver `hud.gd::_on_player_died()`, conectado a `PlayerNeeds.died`, que muestra un mensaje en pantalla por unos segundos. Si se agrega alguna otra mecánica futura que dispare `load_game()` fuera del arranque normal de la escena, necesita el mismo tipo de aviso.

## UIState: las pantallas modales se registran, nadie pregunta sistema por sistema

**Refactor de arquitectura (07/07/2026), pedido explícito de la usuaria ("las bases importan por todo lo que viene después"):** antes había ~10 lugares con la misma cadena `work_system.is_working or phone_system.is_open or inventory_system.is_open or pause_system.is_open` — cada pantalla nueva obligaba a tocar todos, y olvidarse de uno ya había causado bugs reales. Ahora existe el autoload `UIState`: cada pantalla modal se registra al abrir/cerrar (`UIState.open(&"phone")` / `UIState.close(&"phone")`, idempotentes) y todo el mundo consulta `UIState.is_any_modal_open()` (o `is_any_modal_open_except(id)` para el toggle de una pantalla desde su propia tecla).

**Ids registrados hoy:** `&"phone"`, `&"inventory"`, `&"pause"`, `&"work"`, `&"build_catalog"`.

**Reglas:**
- Toda pantalla modal nueva declara su `MODAL_ID`, llama `UIState.open/close` en su abrir/cerrar (¡en TODOS los caminos de cierre! — `build_system._exit_build_mode()` cierra el catálogo sin pasar por `_close_catalog()`, y también registra el cierre), y usa `close_window` (Q) para cerrarse.
- **Estados de gameplay NO van en UIState:** "pieza de construcción equipada" (`build_system.equipped_category`) bloquea cosas pero no es una pantalla — se consulta directo donde hace falta (pausa, prompt de huerta). `work_system.is_working` está en los dos mundos a propósito: registra `&"work"` como modal Y mantiene su flag propio porque `PlayerNeeds` lo usa para el desgaste por esfuerzo (gameplay).
- Cambio de comportamiento consciente al unificar: con el catálogo de construcción abierto ahora tampoco se puede caminar (antes sí — era una inconsistencia de guardas escritas a mano, no una decisión).

## Guardado versionado + contrato único (formato v2)

**El archivo de guardado lleva `"version"`.** Formato v2 (07/07/2026): un diccionario por sistema (`economy`, `inventory`, `backpack`, `player_needs`, `build`), cada uno producido/consumido por el contrato estándar `get_save_data()`/`apply_save_data()` que ahora implementan **todos** los sistemas persistibles. `SaveManager` solo mantiene el registro `_save_systems()` — agregar un sistema persistible nuevo (día/noche, clima) es implementarle el contrato y sumarlo ahí, nada más.

**Reglas:**
- Cualquier cambio de formato del save **sube `SAVE_VERSION` y agrega una función de migración** (ver `_migrate_v1()`) — nunca se rompe el guardado existente de la jugadora por un cambio de código. Los saves v1 (sin campo version, con `money`/`pieces` como claves sueltas) se migran solos al cargar; los `crops` legacy de v1 se descartan a propósito (eran de la grilla vieja pre-CropManager, borrada).
- `_save_systems()` se resuelve en cada llamada (no se cachea en `_ready()`): `build_system` vive en la escena, no es autoload, y puede no existir al arrancar.

## Valores de balance/tuning: archivo de config editable, no constantes en código

El GDD (4.9) pide que la duración del día sea editable sin tocar código, para buscar el balance con playtesting. El patrón quedó armado con el ciclo día/noche: `config/day_night.cfg` (formato INI, se edita con cualquier editor de texto) leído con `ConfigFile` en el `_ready()` del sistema (`TimeManager._load_config()`), con defaults en el código si falta el archivo o una clave — nunca crashea por config incompleta.

**Regla:** cualquier valor de balance futuro que se vaya a ajustar jugando (tiempos de cultivo, decaimiento de hambre/sueño, precios) debería migrar a este patrón — un `.cfg` por sistema en `config/`, no constantes que obligan a tocar código y recargar el editor por cada prueba. Los `@export` en escenas son la alternativa para valores que se ajustan desde el Inspector; el `.cfg` gana cuando se quiere iterar con el juego corriendo o sin abrir Godot.

## Simulación vs. presentación: la UI no contiene lógica de juego

**Regla general (patrón de estudio):** las pantallas (`Control`) solo pintan estado y llaman servicios; la lógica vive en autoloads. Caso concreto: `marketplace_ui.gd` cobraba la plata y entregaba los ítems ella misma — ahora el catálogo (`Economy.SHOP_CATALOG`) y la compra (`Economy.buy(item_id)`) viven en `Economy`, y la UI solo lee/llama/refresca. Cuando el celular diegético (PXD sección 5) rehaga esta pantalla, reusa el servicio sin duplicar una línea de lógica. Al crear una pantalla nueva, preguntarse: "si mañana esta UI se rehace desde cero, ¿qué lógica se perdería?" — esa lógica va en un servicio, no en la pantalla.

## Cerrar ventanas (`Q`) vs. menú de pausa (`Esc`): acciones separadas a propósito

Bug real (07/07/2026): "cerrar una pantalla siempre terminaba abriendo el menú de pausa". Todos los sistemas modales (celular, inventario, catálogo de construcción, sesión de trabajo) reaccionaban al mismo `ui_cancel` (Escape) que `pause_system.gd` usa para abrir/cerrar pausa. Varios de esos chequeos viven en `_process` (no en `_unhandled_input`, ver comentarios de cada script) — como `pause_system.gd` también revisa `ui_cancel` en su propio `_process`, el orden en que Godot procesa los `_process` de nodos hermanos en el mismo frame decidía si el modal ya se había cerrado (`is_open = false`) *antes* de que `pause_system` chequeara ese mismo `is_open` para decidir si abrir pausa — condición de carrera entre nodos hermanos, no un bug de lógica.

**Regla:** `close_window` (tecla `Q`) es la acción dedicada para cerrar/salir de cualquier pantalla modal (`build_system.gd`, `catalog_menu.gd`, `phone_system.gd`, `inventory_system.gd`, `work_system.gd`). `ui_cancel` (Esc) quedó exclusivo de `pause_system.gd`. Ninguna categoría nueva de pantalla modal debería volver a engancharse a `ui_cancel` — si necesita cerrarse con una tecla, es `close_window`.

## Visuales de debug: pasan por `DevMode`, nunca hardcodeados a siempre-visible

Cualquier visual que exista solo para verificar que la lógica funciona durante el desarrollo (ej. el `Label3D` "StateLabel" de `CropManager` mostrando el estado interno de una parcela) **no puede quedar visible incondicionalmente** — rompe la regla de inmersión/realismo del PXD (`docs/GameDesign/PXD_Diseno_HUD_UI_v1.md`, sección 1.1): en el juego final solo debe verse el prompt de interacción, nunca texto de debug flotando sobre objetos del mundo.

**Regla:** ese tipo de visual se crea/actualiza igual que siempre, pero su `visible` se controla con el autoload `DevMode` (`DevMode.enabled`, default `false`, toggle con `F1` vía la acción `toggle_dev_mode`) — no con un `@export` propio del nodo ni un flag nuevo por sistema. Al agregar un visual de debug nuevo: suscribirse a `DevMode.toggled` (o consultar `DevMode.enabled` al crearlo) para que se oculte/muestre junto con todo lo demás, un solo interruptor para todo el proyecto.

## Prompt de tecla: imagen real del keyset, no texto compuesto a mano

`interaction_prompt_3d.gd` mostraba la tecla como un `Label3D` con texto ("E") superpuesto a un marco dibujado a mano (`key_prompt_frame.png`) — no calzaba con el resto del HUD (sin bordes negros, sin texto renderizado por Godot para algo que debería ser un ícono real). Se reemplazó por un `Sprite3D` (`KeySprite`) que carga la imagen real de `assets/hud/keyset/White/` según la tecla configurada en `InputMap`.

**Cómo mapear la tecla a un archivo:** `OS.get_keycode_string(physical_keycode)` devuelve el nombre de Godot para la tecla ("E", "1", "F5", pero también "Escape", "Space"). Letras, números y F1-F12 coinciden directo con el nombre de archivo del keyset (`"E" -> "E.png"`) — no necesitan mapeo. Las teclas con nombre especial sí lo necesitan (`"Escape" -> "esc.png"`, `"Space" -> "space_bar.png"`, etc.) — ver `SPECIAL_KEY_ICONS` en `interaction_prompt_3d.gd`. Al usar este mismo patrón para un prompt de una tecla nueva que no sea letra/número/F-key, revisar si ya está en ese diccionario antes de asumir que el nombre de archivo va a coincidir solo.

## Encapsular antes de aplicar dos veces — la huerta se quedó sin el prompt de tecla nuevo

Bug real (07/07/2026): se arregló el prompt de tecla (imagen del keyset en vez de texto+marco) editando `interaction_prompt_3d.gd`/`.tscn`, y quedó perfecto para cama y escritorio — pero la huerta directamente no mostraba ningún prompt, ni el viejo. Causa de fondo: `bed.gd`/`desk.gd` tenían el mismo bloque de código copiado y pegado (Area3D de proximidad + `InteractPrompt` + guardas de pantallas modales), y la huerta usa un mecanismo completamente distinto (raycast por frame en `world.gd`, ver `_cast_crop_ray()`) al que nadie le había conectado nunca ningún prompt. Arreglar el componente compartido (`interaction_prompt_3d.tscn`) no alcanza si cada sistema que lo usa (o que *debería* usarlo) llegó ahí por su cuenta, copiando código en vez de compartirlo.

**Regla:** cuando un patrón de UI/interacción se repite (proximidad + prompt, en este caso), extraerlo a una base reusable apenas aparece la segunda copia — no esperar a la tercera. Ver `scripts/build/proximity_interactable.gd`: `bed.gd`/`desk.gd` heredan de ahí (`extends "res://scripts/build/proximity_interactable.gd"`) y solo implementan `_on_interact()`; `action_text`/`interaction_range` se configuran como propiedades exportadas en la escena, no repitiendo el script. Para interacciones que **no** son de proximidad (como la huerta, que es apuntar con la cámara, no acercarse) — no fuerces el mismo componente: comparten la **pieza visual** (`interaction_prompt_3d.tscn`, con su `show_prompt()`/`hide_prompt()`), pero cada sistema decide cuándo mostrarla según su propia lógica (ver `world.gd::_update_crop_prompt()`, un prompt compartido tipo "roaming" que sigue la parcela apuntada, mismo criterio que ya usa `build_system.gd` para el fantasma/resaltado de demolición en vez de un nodo por pieza).
