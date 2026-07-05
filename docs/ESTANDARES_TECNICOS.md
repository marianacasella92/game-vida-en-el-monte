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

`JSON.stringify()` convierte **todas** las claves de un `Dictionary` a string, sin excepción. Si algo como `Inventory.items` (claves `int`: `0, 1, 2...`) se guarda tal cual y se lee de vuelta con `JSON.parse_string()`, las claves vuelven como `"0", "1", "2"` (string) — cualquier `items.has(0)` o `items[slot]` con `slot: int` deja de encontrar nada, porque `0 != "0"` como clave de Dictionary en GDScript.

**Regla:** al restaurar un Dictionary con claves numéricas desde el guardado, reconstruirlo a mano convirtiendo cada clave con `int(key)`. Ver `Inventory.apply_save_data()`.

## Sistema de guardado — estado actual y deuda conocida

`SaveManager` arma un único diccionario JSON llamando a cada sistema. La mayoría todavía usa nombres de método ad-hoc (`Economy.money` leído directo, `build_system.serialize_pieces()`, `world.serialize_crops()`), pero **`Inventory` ya adoptó el contrato estándar** (`get_save_data() -> Dictionary` / `apply_save_data(data: Dictionary)`) — es el primero, y el criterio para cualquier sistema nuevo que persista algo (hambre/sueño, día-noche) es usar ese mismo contrato, no inventar otro nombre.

**Por qué importa el cableado manual:** cada sistema nuevo que necesite persistir requiere acordarse de sumarlo a mano en `save_manager.gd`. Dos bugs reales pasaron por esto: la parcela que no crecía al recargar (existían dos copias de la lógica de restaurar, una vieja y muerta en `world.gd`, desincronizada de la real en `CropManager`), y el inventario que **directamente nunca se guardaba** — cada reinicio volvía a la semilla inicial hardcodeada, perdiendo cualquier semilla extra, la regadera comprada, o comida cosechada.

**Mejora pendiente (parcial):** migrar `Economy`/`build_system`/`world` al mismo contrato `get_save_data()`/`apply_save_data()` que ya usa `Inventory`, y que `SaveManager` mantenga una lista corta de sistemas registrados en vez de llamar a métodos con nombres distintos por sistema. No es urgente romper lo que ya funciona, pero cualquier sistema *nuevo* de acá en adelante debería nacer con el contrato nuevo directamente.
