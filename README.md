# Hello Triangle (OpenGL)

Opens a window and draws a nice little triangle with OpenGL 3.3.

![Screenshot](https://mq32.de/public/fa6ae0d95073caec85c3507c37e690ae0a5a0919.png)

## Building

Checkout all submodules, then use `zig` to build the example.
```sh
git submodule update --init --recursive # fetches ZWL
zig build run                           # builds the example and runs it
```

## Dependencies
This project depends on the awesome [Zig Window Library (ZWL)](https://github.com/Aransentin/ZWL/) by @Aransentin.