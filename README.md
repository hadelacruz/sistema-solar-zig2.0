# Sistema Solar (versión simple)

Render por software en Zig. Raylib solo abre la ventana, lee el teclado y el mouse, decodifica
los PNG y muestra la imagen final: cada píxel lo calcula el programa.

**Video:** _(link)_

## Correr

```sh
zig build run
```

Requiere Zig 0.17.1.

## Controles

| Tecla | Acción |
|---|---|
| Mouse | Mirar |
| W A S D | Moverse |
| Espacio / Ctrl | Subir / bajar |
| Shift | Más rápido |
| 1 … 5 | Viaje rápido: Sol, Ignis, Terra, Zephyr, Glacia |
| B | Activar/desactivar back-face culling |

## Archivos

| Archivo | Qué hace |
|---|---|
| `main.zig` | Ventana, entrada y ciclo principal |
| `framebuffer.zig` | Arreglo de píxeles y z-buffer |
| `camera.zig` | Cámara y proyección |
| `sphere.zig` | Genera la esfera UV |
| `render.zig` | Vertex shader, back-face culling y rasterización |
| `shaders.zig` | Color de cada píxel según el cuerpo |
| `planets.zig` | Órbitas y colisiones |
| `skybox.zig` | Estrellas (y su efecto al viajar) |
| `travel.zig` | Viaje rápido |

## Shaders

- **Sol:** emisivo, dos capas de textura que se mueven y un pulso de brillo.
- **Ignis:** la lava brilla sola y pulsa.
- **Terra:** nubes transparentes que se mueven.
- **Zephyr:** cada banda de gas se mueve a su propia velocidad.
- **Glacia:** borde brillante (fresnel) que late.

## Puntos de la rúbrica

| Punto | Pts | Cómo se cumple |
|---|---|---|
| Planetas/lunas con textura propia (10 c/u) | 40 | Ignis, Terra, Zephyr y Glacia, cada uno con su textura |
| Shader único por planeta/luna (+5 c/u) | 20 | Lava animada, nubes transparentes, bandas animadas, fresnel que late |
| La estrella ilumina a los planetas | 10 | El Sol es una luz puntual (Lambert) en `shaders.zig` |
| Back-face culling | 10 | `render.zig`; con la tecla B se ve el contador en el título |
| Corre bien la mayoría del tiempo | 10 | 60 FPS |
| No se atasca cerca de los objetos | 10 | Peor caso medido: ~3 ms por cuadro, cerca del Sol |
| Viaje rápido | 10 | Teclas 1–5, `travel.zig` |
| Efecto animado al viajar | 10 | Estrellas estiradas en líneas y FOV que se abre |
| Skybox con estrellas | 10 | `skybox.zig` |
| La cámara no atraviesa los cuerpos | 10 | `pushOut` en `planets.zig` |
| Movimiento 3D de la cámara | 10 | WASD en la dirección en que miras + Espacio/Ctrl |
| **Total** | **150** | |

No implementados: LOD (10) y la nave que sigue a la cámara (30 + 10 + 20).

## Referencias

### Zig
- Referencia del lenguaje: https://ziglang.org/documentation/master/
- Librería estándar (`std.math`, `std.ArrayList`, `std.Random`, etc.): https://ziglang.org/documentation/master/std/
- Sistema de compilación (`build.zig`, `build.zig.zon`): https://ziglang.org/learn/build-system/

### Raylib
- Raylib: https://github.com/raysan5/raylib
- Bindings de raylib para Zig: https://github.com/raylib-zig/raylib-zig

Funciones de raylib usadas: `initWindow`, `windowShouldClose`, `setTargetFPS`, `getFrameTime`,
`isKeyDown`, `isKeyPressed`, `getMouseDelta`, `disableCursor`, `loadImageFromMemory`,
`loadImageColors`, `genImageColor`, `loadTextureFromImage`, `updateTexture` y una sola llamada
a `drawTextureEx` por cuadro para mostrar la imagen ya terminada.


## Uso de LLM

Durante el desarrollo del proyecto utilicé Claude como herramienta de apoyo para realizar una auditoría del código, identificar posibles errores y encontrar oportunidades de optimización. Principalmente, me ayudó a revisar y mejorar el rendimiento del renderizador para que el sistema solar funcionara de manera más fluida (render.zig), así como a optimizar algunos aspectos visuales, entre ellos el skybox y los efectos de las estrellas (skybox.zig). Su uso estuvo enfocado en mejorar funciones existentes y revisar la eficiencia del programa, incluyendo sugerencias y modificaciones de código en estas áreas.
