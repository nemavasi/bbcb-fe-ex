# `JEarth/Lib` — сторонние библиотеки подсистемы

Раскладка по ADR-265: всё, что нужно подсистеме, лежит **в самой подсистеме**.
Эти jar'ы входят в поставку один раз — в составе `JEarth/`, в `_bin/lib/jars`
не копируются. Classpath собирается из `<Подсистема>/Lib/*`.

## Состав

| Файл | Версия | Что | Лицензия |
|---|---|---|---|
| `WorldWindJava.jar` | 2.2.1 | NASA World Wind Java — рендеринг глобуса/карты | Apache-2.0 |
| `jogl-all-2.6.0.jar` | 2.6.0 | JOGL — привязки OpenGL (Java) | BSD-2-Clause (JogAmp) |
| `jogl-all-2.6.0-natives-*.jar` | 2.6.0 | нативные библиотеки JOGL: linux-amd64, windows-amd64, macosx-universal | BSD-2-Clause |
| `gluegen-rt-2.6.0.jar` | 2.6.0 | GlueGen runtime | BSD-2-Clause |
| `gluegen-rt-2.6.0-natives-*.jar` | 2.6.0 | нативные библиотеки GlueGen (те же три платформы) | BSD-2-Clause |

Лицензии — `../LICENSES/` (Apache-2.0 + сторонние уведомления WWJ, BSD JOGL/GlueGen).

## Откуда и как обновлять

* **WWJ** — GitHub release: `https://github.com/NASAWorldWind/WorldWindJava/releases`
  (`worldwind-v2.2.1.zip` → `dist/WorldWindJava.jar`). В Maven Central его нет.
  **Важно:** jar держать **без каталога `lib/` рядом**. В манифесте WWJ прописан
  `Class-Path: lib/jogl-all.jar lib/gluegen-rt.jar`; если положить туда JOGL 2.4 из
  архива WWJ, его классы смешаются с JOGL 2.6 → `UnsatisfiedLinkError:
  GLX.initializeImpl`. Именно поэтому jar лежит один, а JOGL берётся 2.6.0.

* **JOGL / GlueGen** — Maven Central, обновляются Gradle-задачей:

  ```
  ./gradlew syncSubsystemLibs      # раскладывает jar'ы по <Подсистема>/Lib
  ```

  Версии заданы в `build.gradle` (конфигурация `jearthLibs`). После обновления
  сами файлы коммитятся — сборка и релиз не зависят от сети.

## Зачем offscreen

Подсистема не открывает отдельное окно OpenGL: `GLOffscreenAutoDrawable` рисует
кадр в память, оттуда `glReadPixels` → `BufferedImage` → `HostPorts.Rider.DrawImage`
в кадр вида BBCB. Поэтому `WorldWindowGLAutoDrawable` используется через подкласс
(`JEarth/EarthWindow.java`), который отключает `redraw()`/`reshape()`: они
кастуют drawable к AWT-компоненту и на offscreen-FBO падают.
