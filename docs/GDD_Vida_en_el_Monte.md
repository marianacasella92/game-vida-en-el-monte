# Documento de Diseño Funcional
## Proyecto: "Vida en el Monte" (título de trabajo)

---

## 1. Concepto

Un simulador de vida rural en primera persona, ambientado en la actualidad. La jugadora vive sola (sin aldeanos ni gestión de pueblo), construye su casa, cultiva su propia comida y arma su sistema de energía autosuficiente — mientras trabaja como **educadora de programación** desde su casa en el campo, dando clases y creando contenido educativo, completamente aparte de su vida rural.

**Pitch en una frase:** Vivir sola y en paz en el monte, cultivando tu comida, armando tu energía, y trabajando desde ahí dando clases de programación.

---

## 2. Pilares de diseño

| Pilar | Descripción |
|---|---|
| **Vida solitaria y personal** | Un solo personaje jugable. Sin aldeanos que reclutar ni gestionar. Todo lo hace la propia jugadora. |
| **Autosuficiencia real** | Cultivás tu propia comida y generás tu propia energía; el juego mide cuán autosuficiente sos. |
| **Progreso tecnológico continuo** | La tecnología avanza más allá de lo rural: eléctrico, mecanizado, renovable/autosuficiente. |
| **Trabajo remoto como educadora de programación** | La jugadora se gana la vida dando clases/cursos de programación online (su profesión real), completamente separado de su vida en el campo. El campo es donde vive, no el tema de su trabajo. |
| **Exploración mínima y opcional** | Los recursos base están cerca del terreno inicial. Explorar es un plus, no un requisito de progresión. |
| **Ritmo tranquilo** | Sin combate, sin trama forzada, sin presión de "sobrevivir minuto a minuto". |

---

## 3. Loop de juego (core loop)

1. Cuidar el terreno: cultivar, cosechar, cocinar con lo propio.
2. Mantener y expandir el sistema de energía (solar/eólico/leña → batería → consumo).
3. Sentarse a trabajar: dar una clase, grabar contenido de programación, o avanzar con su curso/plataforma — como fuente de ingresos, sin relación temática con el campo.
4. Usar ese ingreso + lo cultivado para construir, mejorar la casa, y comprar tecnología nueva.
5. Desbloquear nueva tecnología → nuevas formas de cultivar/generar energía más eficientemente → más tiempo libre para crear contenido o simplemente disfrutar la vida tranquila.

La curva ideal: **la jugadora empieza con tareas 100% manuales y de supervivencia básica, y con el tiempo su granja y su energía funcionan con mantenimiento mínimo — liberando tiempo de juego para su trabajo real (dar clases/crear contenido de programación) y para la decoración/disfrute de su espacio.**

---

## 4. Sistemas centrales (a detallar en documentos separados)

### 4.1 Terreno y construcción
- Colocación modular de paredes, techos, pisos, puertas, ventanas.
- Sistema de snap-to-grid con flexibilidad para diseño libre.
- Decoración interior (mobiliario, terminado).

### 4.2 Economía de recursos
- Recursos base: madera, agua, piedra, comida.
- Recursos intermedios: metal, componentes eléctricos, combustible/biogás.
- Cadenas de producción (ej: madera → leña / madera → tablas → muebles).
- **Doble vía de obtención:** todo recurso/material se puede conseguir recolectando manualmente en el terreno, o comprando en el marketplace (ver sección 4.6) con dinero ganado trabajando. La jugadora elige su propio balance entre recolectar y comprar.

### 4.3 Sistema de energía (pilar diferencial del juego)
- Generación: solar, eólica, leña/biomasa (biodigestor).
- Almacenamiento: baterías.
- Consumo: cada edificio/máquina tiene una demanda energética.
- Factores ambientales: clima y estación afectan generación solar/eólica.

### 4.4 Agua
- Captación (lluvia, pozo).
- Potabilización (filtro básico → sistema UV eléctrico en tiers avanzados).
- Uso: consumo personal, riego, animales.

### 4.5 Cultivo y alimentación
- Huerta propia: plantar, regar, cosechar, con ciclos de crecimiento por estación.
- Cocinar con lo cultivado (autoconsumo real, no solo venta).
- Posibilidad de animales chicos (gallinas, por ejemplo) para huevos/leche, sin que sea obligatorio.

### 4.6 Trabajo como educadora de programación (mecánica económica central)
- La jugadora tiene un "escritorio/oficina" en su casa: ahí se sienta a trabajar, igual que en su vida real.
- El trabajo es dar clases, grabar cursos, o gestionar su plataforma/comunidad de programación — el contenido temático es programación, no la vida rural.
- El campo y el trabajo son dos esferas separadas de la vida de la jugadora, no una sola mecánica combinada.

**Fuentes de ingreso (múltiples, todas ligadas al trabajo, no a recolección):**
- **Crecimiento de comunidad:** una base de alumnos/seguidores que crece con el tiempo y con las acciones de trabajo de la jugadora (dar clases, publicar contenido). A más comunidad, mejores ingresos recurrentes.
- **Comisiones (ingreso pasivo, sin mini-juego):** plata que entra sola, en base a lo que la jugadora ya construyó — ads de YouTube, porcentaje de venta de ebooks/productos, afiliados. No requiere ninguna interacción activa: crece en función del tamaño de la comunidad y de la cantidad de productos publicados en el catálogo (ver "Grabar contenido/curso" más abajo). Es puramente pasivo, como un interés que se acumula solo.
- **Mentoría (acción opcional, simple):** de tanto en tanto aparece la oportunidad de tomar una mentoría puntual — la jugadora **elige si la toma o no** (sin obligación). Si la toma, es una interacción simple y rápida, sin mini-juego de tensión ni mecánica de "acierto/error" — a cambio de un pago mayor a una clase común, ya que es un encargo de mayor valor.
- **Productos vendibles de ingreso fijo:** cursos grabados, plantillas, ebooks — se producen una vez (ver "Grabar contenido/curso" más abajo) y generan ingreso pasivo/recurrente sin necesitar atención constante.

**Uso del dinero — Marketplace tipo "MercadoLibre":**
- Existe una tienda online dentro del juego (estilo marketplace real, con "de todo") donde la jugadora compra materiales, herramientas, semillas, paneles solares, muebles, etc.
- El dinero para comprar ahí sale exclusivamente del trabajo de programación (comunidad + comisiones + productos) — no hay otra fuente de ingreso relevante.
- Esto resuelve el problema central que la jugadora no quiere: no hace falta explorar ni recolectar todo a mano, porque la mayoría de los materiales se pueden comprar directamente con lo ganado trabajando.

**Recolección manual (talar, plantar, juntar piedras, etc.):**
- Existe y es parte de la vida de campo (por ejemplo, cultivar tu propia huerta sigue siendo manual, porque es parte del pilar de autosuficiencia alimentaria).
- Pero es **una opción más, no la única vía** para conseguir materiales de construcción/energía: todo lo que se puede recolectar también se puede comprar en el marketplace.
- Esto le da a la jugadora la libertad de elegir su propio ritmo: si un día no tiene ganas de talar árboles, compra la madera; si quiere ahorrar plata, sale a buscarla ella misma.

**Mini-juegos de trabajo (una acción activa = un mini-juego corto, 30 seg a 2 min):**

- **Dar una clase en vivo** — se descartó la idea de quiz de preguntas/respuestas (se sentía más a trivia que a jugar). En su lugar, se definieron **3 modos de juego**, pensados para desarrollarse en este orden:
  1. **Malabares de atención** *(primera versión a implementar)* — varios "alumnos" en pantalla, cada uno con una barra de atención que baja con el tiempo; hay que ir interactuando con cada uno antes de que se vacíe. Mientras más alumnos activos, más difícil el malabareo. Da ritmo y tensión sin depender de contenido de preguntas.

     **Especificación mecánica:**
     - **Interacción:** arrastrar un elemento (recurso/respuesta) hacia el alumno que lo necesita, no un simple clic — le suma una capa extra de habilidad motriz al mini-juego.
     - **Cantidad de alumnos (v1):** 3 alumnos en pantalla, representados como íconos/avatares.
     - **Barra de atención:** cada alumno tiene una barra de 0-100% que decae a un ritmo constante (ej: -2%/seg como punto de partida a ajustar en playtesting).
     - **Al arrastrar el elemento a un alumno:** su barra sube (ej: +30%) y se resetea el decaimiento por un momento.
     - **Duración de la sesión:** 45-60 segundos de juego (representa "una hora de clase" narrativamente).
     - **Eventos de dificultad:** con el correr de la sesión, aparecen eventos que aceleran el decaimiento de un alumno al azar (simula una distracción puntual), sumando variabilidad.
     - **Escalado entre sesiones:** a medida que la comunidad/reputación crece, se suman más alumnos en pantalla (más difícil, pero mejor paga).
     - **Condición de resultado:** si el promedio de atención final supera un umbral (ej: 70%+), la clase es "buena" → mejor pago + más aporte a comunidad. Si un alumno llega a 0%, se "desconecta" y no cuenta para el promedio final — pero no hay game over ni penalización dura, solo un resultado más flojo.
     - **Vínculo económico:** el resultado de la sesión determina el ingreso de esa clase y el aporte a la barra de crecimiento de comunidad (sistema pasivo ya definido en 4.6).
  2. **Ritmo de tipeo** *(se suma en la versión final)* — aparecen fragmentos de código cortos para tipear/tocar en orden al ritmo de una barra que avanza (estilo rhythm game). El puntaje depende del timing, no del contenido.

     **Especificación mecánica:**
     - **Formato:** estilo Guitar Hero con **4 carriles**, cada uno mapeado a una tecla fija (ej: D-F-J-K o flechas).
     - **Notas:** cada nota que cae por un carril representa una **letra** de una palabra clave real de programación (`def`, `return`, `if`, `class`, `for`, etc. — palabras cortas, no líneas completas).
     - **Al acertar las notas en ritmo:** la palabra clave se va completando visualmente en pantalla, letra por letra, dando la sensación de "estar programando" sin ser un tipeo literal.
     - **Progresión dentro de la sesión:** se van encadenando distintas palabras clave, una tras otra, aumentando velocidad/complejidad a medida que avanza la sesión (igual que una canción de rhythm game que se pone más difícil).
     - **Duración de la sesión:** ~45-60 segundos, consistente con "Malabares de atención".
     - **Puntaje:** basado en precisión/combo (acertar notas seguidas suma multiplicador), no en el contenido de las palabras — el jugador no necesita saber programar para jugarlo bien.
     - **Sin penalización dura:** errar una nota baja el combo pero no termina la sesión — mismo tono sin "game over" que el resto del juego.
     - **Vínculo económico:** el puntaje final de precisión determina el ingreso de esa sesión de grabación/clase y su aporte a la barra de crecimiento de comunidad (mismo sistema que "Malabares de atención").
  3. **Termostato de energía de la clase** *(se suma en la versión final)* — hay que mantener un dial/slider en la "zona verde" (ritmo ideal de la clase, ni muy lento ni muy rápido) mientras van apareciendo eventos random que lo empujan fuera de esa zona.

     **Especificación mecánica:**
     - **Representación visual:** una barra horizontal con una zona verde en el centro. El marcador a la izquierda = clase muy lenta (alumnos se aburren); a la derecha = clase muy rápida (alumnos se pierden).
     - **Control:** arrastrar el marcador directamente con el mouse — control táctil e inmediato, sin teclas.
     - **Qué saca al marcador de la zona verde (ambos a la vez):**
       - **Decaimiento pasivo:** el marcador deriva solo hacia un costado con el tiempo (como si la clase tendiera naturalmente a desviarse).
       - **Eventos random:** empujan el marcador de golpe hacia un lado (ej: "un alumno hizo una pregunta difícil" empuja hacia lento; "vas genial" empuja hacia rápido).
     - **Objetivo:** contrarrestar activamente arrastrando el marcador de vuelta al centro durante toda la sesión (~45-60 seg, consistente con los otros dos modos).
     - **Puntaje:** proporcional al tiempo total que el marcador pasó dentro de la zona verde durante la sesión.
     - **Sin penalización dura:** salirse de la zona verde no termina la sesión, solo baja el puntaje final — mismo tono sin "game over" que los otros dos modos.
     - **Vínculo económico:** el puntaje final determina el ingreso de esa sesión y su aporte a la barra de crecimiento de comunidad (mismo sistema que los otros dos mini-juegos).
  - **Plan de desarrollo:** arrancar con "Malabares de atención" como único modo del vertical slice/primeras iteraciones; sumar los otros dos modos más adelante para dar variedad al mini-juego de dar clases.

- **Grabar contenido/curso (producto de ingreso pasivo):** a diferencia de los 3 modos de "dar clase en vivo" (que son mini-juegos de tensión que se juegan cada vez), esto funciona distinto — es **una sola acción que se hace una vez y después genera ingreso solo**, similar a escribir un libro en Los Sims: el personaje "escribe" una vez y el juego después vende el libro solo en segundo plano.

  **Especificación:**
  - **Una sola interacción** (sin presión de tiempo, sin mini-juego de tensión) representa todo el proceso real (grabar → editar → subir) simplificado en un solo paso — no hace falta separarlo en 3 dinámicas distintas.
  - Al completar esa acción, se genera un **producto** (curso grabado, plantilla, ebook) que se suma al catálogo/vidriera de la jugadora.
  - **Cada producto del catálogo genera ingreso pasivo recurrente** de ahí en adelante, sin que la jugadora tenga que volver a interactuar con él — funciona como una fuente de ingreso "de fondo" que sigue sumando mientras la jugadora hace otras cosas (cultivar, construir, etc.).
  - Esto conecta directo con lo ya definido en 4.6 como **"productos vendibles de ingreso fijo"** — este mini-juego/acción es la forma concreta de generarlos.
  - A definir más adelante: ¿el ingreso pasivo de cada producto decae con el tiempo (se "desactualiza" el curso) o es constante mientras no se reemplace? ¿Hay un límite de productos en el catálogo o se pueden acumular indefinidamente?
- Otras acciones de trabajo (corregir código, responder consultas, etc.) a definir con la misma lógica: cada una con su propio mini-juego cortito y distinto.

**Crecimiento de comunidad — NO es un mini-juego:**
- La comunidad/base de alumnos crece de forma pasiva, como consecuencia de las acciones de trabajo (dar clases, grabar contenido) — no es algo que la jugadora "juegue" directamente.
- Funciona más como una estadística/barra que sube sola con el tiempo y con la cantidad/calidad de trabajo realizado, similar a como el sistema de energía se acumula en una batería.

- A definir en detalle más adelante: ¿cómo se representa visualmente "trabajar" en cada mini-juego? ¿Cuánto tiempo del día ocupa trabajar vs. las tareas del campo?

### 4.7 Árbol tecnológico / progresión de era
- **Tier 1 — Rural básico:** herramientas manuales, leña, pozo de agua, huerta simple.
- **Tier 2 — Mecanizado:** herramientas con motor simple, biodigestor, primeras bombas de agua.
- **Tier 3 — Eléctrico:** paneles solares chicos, batería básica, iluminación eléctrica, riego con temporizador.
- **Tier 4 — Renovable avanzado:** eólica, batería de gran capacidad, riego automatizado, invernadero climatizado.
- **Tier 5 — Autosuficiencia total:** red energética propia estable, huerta y energía funcionando con mantenimiento mínimo, foco total en el trabajo de programación y disfrute del espacio.

### 4.8 Necesidades personales de la jugadora
- **Hambre:** baja con el tiempo, se recupera comiendo (idealmente con lo cultivado/cocinado — refuerza el pilar de autosuficiencia).
- **Sueño/energía:** baja con las horas despierta y con el esfuerzo de las tareas (trabajar, cultivar, construir); se recupera durmiendo.
- **Sin mecánicas de estrés o salud complejas por ahora** — mantenerlo simple: dos barras (hambre y energía/sueño) alcanzan para dar sensación de "vida real" sin volverse un simulador médico.
- A definir: ¿qué pasa si se descuidan (débuff temporal, no "muerte" ni penalización dura, dado el tono tranquilo del juego)?

### 4.9 Ciclo temporal y clima
- **Día/noche:** con horarios que afectan qué se puede hacer (dormir de noche, trabajar/cultivar de día), y afecta la generación solar de energía.
- **Estaciones:** afectan qué se puede cultivar, el clima general, y la demanda de energía (ej: más calefacción en invierno).
- **Clima (lluvia, sol, viento):** efecto directo en el gameplay, no solo estético — la lluvia riega la huerta sola y llena los tanques de captación de agua; el viento genera energía si hay eólica instalada; los días nublados bajan la generación solar.
- Este sistema conecta directamente con energía, agua y cultivo — es transversal a todo el core loop.

---

## 5. Fuera de alcance (por ahora)

- Combate.
- Historia/narrativa forzada.
- Aldeanos, NPCs contratables, o gestión de un pueblo.
- Exploración de biomas múltiples como requisito de progresión.
- Multijugador (evaluar en una fase posterior).

---

## 6. Stack técnico

- **Motor:** Godot 4.7 (renderizador Compatibility, por hardware sin GPU dedicada).
- **Lenguaje:** GDScript.
- **Assets 3D:** línea "Ultimate Stylized" de **Quaternius** (CC0, gratis) — elegido por su estética orgánica/pintada a mano, más cálida que otras opciones low-poly más geométricas. Packs a usar:
  - Ultimate Stylized Nature Pack (terreno, árboles, rocas, flores)
  - Ultimate Food Pack (comida/cultivos)
  - Ultimate House Interior Pack (decoración interior)
  - Furniture Pack (muebles)
  - Survival Pack (herramientas rurales, a revisar qué aplica)
  - LowPoly Farm Buildings (punto de partida para la casa, a modificar con el sistema modular propio)
  - Pendiente: paneles solares / tecnología moderna no tienen pack específico gratuito — a resolver modelando en Blender o con formas primitivas de Godot como placeholder.
- **Estilo visual:** low-poly estilizado, consistente al usar una sola línea/autor (Quaternius) en vez de mezclar fuentes distintas.

---

## 7. Alcance del primer prototipo (vertical slice)

**Dedicación estimada:** 1-3 hs/semana (ratos sueltos) → el alcance se mantiene deliberadamente chico para poder completarlo sin frustración, incluso a este ritmo.

**Orden de desarrollo:**
1. **Construcción (casa/terreno)** — sistema base: moverse en primera persona por un terreno simple, colocar paredes/piso/techo básicos con snap-to-grid. Esta es la fundación sobre la que se apoya todo lo demás.
2. **Escritorio de trabajo + un solo mini-juego** — se incluye desde el principio (no se pospone), pero acotado a **un único mini-juego** (por ejemplo, "dar clase en vivo") para probar el concepto completo: sentarse, jugar el mini-juego, ganar dinero.
3. **Marketplace mínimo** — una interfaz simple para gastar ese dinero en 2-3 materiales/objetos de construcción, cerrando el loop económico básico (trabajar → ganar → comprar → construir).

**Explícitamente fuera del vertical slice** (se suman en iteraciones posteriores):
- Cultivo/huerta.
- Sistema de energía (solar/batería).
- Agua.
- Necesidades personales (hambre, sueño).
- Ciclo día/noche y clima.
- Árbol tecnológico completo (tiers).
- Más de un mini-juego de trabajo.
- Todo lo de Fase 2 (novio, perro, familia).

**Meta del vertical slice:** demostrar el loop más chico posible que ya se siente como "el juego" — moverte, trabajar (mini-juego), ganar plata, comprar, construir. Si este loop funciona y se siente bien, se expande sumando cultivo y energía en la siguiente iteración.

---

## 8. Roadmap futuro — Fase 2 (post-1.0)

Sistemas a sumar una vez que el core del juego (cultivo, energía, casa, trabajo de contenido) esté funcionando sólido. Enfoque: simple y simbólico, sin rasgos de personalidad ni simulación granular tipo Sims.

### 8.1 Novio / pareja (inspirado en la vida real de la jugadora)
- Vive en la casa, con una rutina simple (duerme, come, eventualmente ayuda con alguna tarea puntual).
- Sistema de vínculo simbólico: una barra o estado de "conexión" que sube con actividades compartidas (cocinar juntos, cenar, pasear). Nada granular, sin árbol de personalidad.

### 8.2 Perro (inspirado en Tubis)
- Necesidades básicas simples: comida, agua, paseo.
- Da compañía / un beneficio de ánimo al estar cerca. Sistema liviano, sin complejidad extra.

### 8.3 Embarazo y familia
- Resuelto de forma simbólica, no biológica-realista: un evento narrativo ("deciden tener un bebé") → etapa de embarazo con cambios visuales/de energía → nacimiento.
- El hijo/a crece en etapas simples (bebé → niño/a → adolescente), con necesidades básicas únicamente.
- Sin sistema de rasgos de personalidad ni genética — foco en la progresión de etapas de vida familiar, no en simulación profunda.

**Nota:** esta fase se diseña para sumarse sin romper el core loop ya construido (cultivo + energía + casa + contenido). Se retoma en detalle una vez cerrado el vertical slice inicial.

---

*Documento vivo — se actualiza a medida que definimos cada sistema en profundidad.*