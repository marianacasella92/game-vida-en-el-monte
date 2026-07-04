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
- **Comisiones:** encargos puntuales de mayor valor (ej: un curso a medida, una mentoría), con mejor pago pero que consumen más tiempo/energía de trabajo.
- **Productos vendibles de ingreso fijo:** cursos grabados, plantillas, ebooks — se producen una vez y generan ingreso pasivo/recurrente sin necesitar atención constante (más previsible que las comisiones).

**Uso del dinero — Marketplace tipo "MercadoLibre":**
- Existe una tienda online dentro del juego (estilo marketplace real, con "de todo") donde la jugadora compra materiales, herramientas, semillas, paneles solares, muebles, etc.
- El dinero para comprar ahí sale exclusivamente del trabajo de programación (comunidad + comisiones + productos) — no hay otra fuente de ingreso relevante.
- Esto resuelve el problema central que la jugadora no quiere: no hace falta explorar ni recolectar todo a mano, porque la mayoría de los materiales se pueden comprar directamente con lo ganado trabajando.

**Recolección manual (talar, plantar, juntar piedras, etc.):**
- Existe y es parte de la vida de campo (por ejemplo, cultivar tu propia huerta sigue siendo manual, porque es parte del pilar de autosuficiencia alimentaria).
- Pero es **una opción más, no la única vía** para conseguir materiales de construcción/energía: todo lo que se puede recolectar también se puede comprar en el marketplace.
- Esto le da a la jugadora la libertad de elegir su propio ritmo: si un día no tiene ganas de talar árboles, compra la madera; si quiere ahorrar plata, sale a buscarla ella misma.

**Mini-juegos de trabajo (una acción activa = un mini-juego corto, 30 seg a 2 min):**
- **Dar una clase en vivo:** mini-juego de ritmo/timing — van apareciendo preguntas de alumnos y hay que responder la opción correcta antes de que se acabe el tiempo.
- **Grabar contenido/curso:** mini-juego de edición — armar el video/clase eligiendo clips, orden, portada, dentro de un tiempo límite.
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

- **Motor:** Godot 4 (renderizador Compatibility, por hardware sin GPU dedicada).
- **Lenguaje:** GDScript.
- **Assets 3D:** packs low-poly prehechos (Kenney, Quaternius, o Synty), estilo cohesivo, sin modelado propio.
- **Estilo visual:** low-poly / estilizado (no fotorrealista) — mejor rendimiento y más rápido de armar.

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
