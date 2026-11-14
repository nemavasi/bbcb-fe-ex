/*
 * SPDX-License-Identifier: BSD-3-Clause
 * Copyright (c) 2026 nemavasi
 */

package CP.JSDL3Work;

import java.lang.foreign.Arena;
import java.lang.foreign.FunctionDescriptor;
import java.lang.foreign.Linker;
import java.lang.foreign.MemorySegment;
import java.lang.foreign.SymbolLookup;
import java.lang.foreign.ValueLayout;
import java.lang.invoke.MethodHandle;
import java.nio.charset.StandardCharsets;

/**
 * Java-тело {@code JSDL3Work} — официальный SDL3 через Project Panama
 * (ADR-243).
 *
 * <p>Используется {@link java.lang.foreign} из JDK 25: символы SDL3
 * находятся через {@link SymbolLookup}, вызовы — {@link Linker#downcallHandle}.
 * Нативные указатели передаются как {@code long} (CP {@code LONGINT}).</p>
 *
 * <p>Библиотека SDL3 не входит в поставку. Ищется по системному имени
 * ({@code SDL3}); путь можно задать
 * {@code -Dblackbox.sdl3.library=/path/to/libSDL3.so}.</p>
 */
public final class JSDL3Work {

    private static final Linker LINKER = Linker.nativeLinker();
    private static final Arena ARENA = Arena.ofShared();

    /** Поля {@code SDL_Event} (SDL 3.2). */
    private static final long EV_TYPE = 0;
    private static final long EV_SCANCODE = 24;
    private static final long EV_KEY = 28;
    private static final long EV_DOWN = 36;
    private static final long EV_SIZE = 256;

    private static SymbolLookup lookup;
    private static boolean loaded;
    private static String loadError = "";

    private static MethodHandle SDL_Init;
    private static MethodHandle SDL_Quit;
    private static MethodHandle SDL_GetError;
    private static MethodHandle SDL_GetVersion;
    private static MethodHandle SDL_CreateWindow;
    private static MethodHandle SDL_DestroyWindow;
    private static MethodHandle SDL_CreateRenderer;
    private static MethodHandle SDL_DestroyRenderer;
    private static MethodHandle SDL_SetRenderDrawColor;
    private static MethodHandle SDL_RenderClear;
    private static MethodHandle SDL_RenderPresent;
    private static MethodHandle SDL_RenderLine;
    private static MethodHandle SDL_PollEvent;
    private static MethodHandle SDL_Delay;

    static {
        loadLibrary();
    }

    private static void loadLibrary() {
        String path = System.getProperty("blackbox.sdl3.library", "");
        try {
            if (!path.isEmpty()) {
                System.load(path);
            } else if (!loadByName()) {
                // `System.loadLibrary("SDL3")` ищет libSDL3.so в
                // java.library.path, а на Linux runtime-пакет ставит
                // libSDL3.so.0 в /usr/local/lib или
                // /usr/lib/x86_64-linux-gnu (их нет в java.library.path).
                if (!loadFromCandidates()) {
                    loaded = false;
                    loadError = "SDL3 not found (libSDL3.so/ .so.0); "
                            + "задайте -Dblackbox.sdl3.library=/path/libSDL3.so";
                    return;
                }
            }
            lookup = SymbolLookup.loaderLookup();
            if (lookup.find("SDL_Init").isEmpty()) {
                lookup = LINKER.defaultLookup();
            }
            loaded = lookup.find("SDL_Init").isPresent();
            if (!loaded) {
                loadError = "SDL3 loaded, but SDL_Init not found";
                return;
            }
            bind();
        } catch (Throwable e) {
            loaded = false;
            loadError = String.valueOf(e);
        }
    }

    /** Попытка загрузить по системному имени (`libSDL3.so`). */
    private static boolean loadByName() {
        try {
            System.loadLibrary("SDL3");
            return true;
        } catch (Throwable ignored) {
            return false;
        }
    }

    /** Поиск versioned-библиотеки в стандартных каталогах Linux/macOS. */
    private static boolean loadFromCandidates() {
        java.util.LinkedHashSet<String> dirs = new java.util.LinkedHashSet<>();
        String extra = System.getProperty("java.library.path", "");
        for (String d : extra.split(java.io.File.pathSeparator)) {
            if (!d.isEmpty()) dirs.add(d);
        }
        String ld = System.getenv("LD_LIBRARY_PATH");
        if (ld == null) ld = System.getenv("DYLD_LIBRARY_PATH");
        if (ld != null) {
            for (String d : ld.split(java.io.File.pathSeparator)) {
                if (!d.isEmpty()) dirs.add(d);
            }
        }
        for (String d : new String[]{
                "/usr/local/lib", "/usr/lib/x86_64-linux-gnu",
                "/usr/lib/aarch64-linux-gnu", "/usr/lib", "/lib/x86_64-linux-gnu",
                "/lib", "/opt/homebrew/lib", "/opt/local/lib"}) {
            dirs.add(d);
        }
        String mapped = System.mapLibraryName("SDL3");        // libSDL3.so / SDL3.dll
        String[] names = {mapped, mapped + ".0", "libSDL3.so.0",
                "libSDL3.dylib", "SDL3.dll"};
        for (String dir : dirs) {
            java.io.File dd = new java.io.File(dir);
            if (!dd.isDirectory()) continue;
            for (String n : names) {
                java.io.File f = new java.io.File(dd, n);
                if (f.isFile() && loadFile(f)) return true;
            }
            // versioned: libSDL3.so.0.5.0 и т.п.
            java.io.File[] fs = dd.listFiles((d, n) -> n.startsWith("libSDL3.so"));
            if (fs != null) {
                java.util.Arrays.sort(fs);
                for (java.io.File f : fs) {
                    if (f.isFile() && loadFile(f)) return true;
                }
            }
        }
        return false;
    }

    private static boolean loadFile(java.io.File f) {
        try {
            System.load(f.getAbsolutePath());
            return true;
        } catch (Throwable ignored) {
            return false;
        }
    }

    private static MethodHandle handle(String name, FunctionDescriptor fd) {
        return lookup.find(name)
                .map(seg -> LINKER.downcallHandle(seg, fd))
                .orElse(null);
    }

    private static void bind() {
        SDL_Init = handle("SDL_Init",
                FunctionDescriptor.of(ValueLayout.JAVA_BOOLEAN, ValueLayout.JAVA_INT));
        SDL_Quit = handle("SDL_Quit", FunctionDescriptor.ofVoid());
        SDL_GetError = handle("SDL_GetError",
                FunctionDescriptor.of(ValueLayout.ADDRESS));
        SDL_GetVersion = handle("SDL_GetVersion",
                FunctionDescriptor.of(ValueLayout.JAVA_INT));
        SDL_CreateWindow = handle("SDL_CreateWindow",
                FunctionDescriptor.of(ValueLayout.ADDRESS,
                        ValueLayout.ADDRESS, ValueLayout.JAVA_INT,
                        ValueLayout.JAVA_INT, ValueLayout.JAVA_LONG));
        SDL_DestroyWindow = handle("SDL_DestroyWindow",
                FunctionDescriptor.ofVoid(ValueLayout.ADDRESS));
        SDL_CreateRenderer = handle("SDL_CreateRenderer",
                FunctionDescriptor.of(ValueLayout.ADDRESS,
                        ValueLayout.ADDRESS, ValueLayout.ADDRESS));
        SDL_DestroyRenderer = handle("SDL_DestroyRenderer",
                FunctionDescriptor.ofVoid(ValueLayout.ADDRESS));
        SDL_SetRenderDrawColor = handle("SDL_SetRenderDrawColor",
                FunctionDescriptor.of(ValueLayout.JAVA_BOOLEAN,
                        ValueLayout.ADDRESS, ValueLayout.JAVA_BYTE,
                        ValueLayout.JAVA_BYTE, ValueLayout.JAVA_BYTE,
                        ValueLayout.JAVA_BYTE));
        SDL_RenderClear = handle("SDL_RenderClear",
                FunctionDescriptor.of(ValueLayout.JAVA_BOOLEAN, ValueLayout.ADDRESS));
        SDL_RenderPresent = handle("SDL_RenderPresent",
                FunctionDescriptor.of(ValueLayout.JAVA_BOOLEAN, ValueLayout.ADDRESS));
        SDL_RenderLine = handle("SDL_RenderLine",
                FunctionDescriptor.of(ValueLayout.JAVA_BOOLEAN,
                        ValueLayout.ADDRESS, ValueLayout.JAVA_FLOAT,
                        ValueLayout.JAVA_FLOAT, ValueLayout.JAVA_FLOAT,
                        ValueLayout.JAVA_FLOAT));
        SDL_PollEvent = handle("SDL_PollEvent",
                FunctionDescriptor.of(ValueLayout.JAVA_BOOLEAN, ValueLayout.ADDRESS));
        SDL_Delay = handle("SDL_Delay",
                FunctionDescriptor.ofVoid(ValueLayout.JAVA_INT));
    }

    private static MemorySegment ptr(long address) {
        return address == 0 ? MemorySegment.NULL : MemorySegment.ofAddress(address);
    }

    public static boolean Init(int flags) {
        if (!loaded || SDL_Init == null) {
            log("JSDL3: SDL3 not loaded: " + loadError);
            return false;
        }
        try {
            return (boolean) SDL_Init.invokeExact(flags);
        } catch (Throwable e) {
            log("JSDL3.Init: " + e);
            return false;
        }
    }

    public static void Quit() {
        if (SDL_Quit == null) {
            return;
        }
        try {
            SDL_Quit.invokeExact();
        } catch (Throwable e) {
            log("JSDL3.Quit: " + e);
        }
    }

    public static void GetError(char[] msg) {
        String s = "";
        if (!loaded || SDL_GetError == null) {
            s = "SDL3 not loaded: " + loadError;
        } else {
            try {
                MemorySegment p = (MemorySegment) SDL_GetError.invokeExact();
                if (p.address() != 0) {
                    s = p.reinterpret(4096).getString(0, StandardCharsets.UTF_8);
                }
            } catch (Throwable e) {
                s = String.valueOf(e);
            }
        }
        copy(s, msg);
    }

    public static int Version() {
        if (SDL_GetVersion == null) {
            return 0;
        }
        try {
            return (int) SDL_GetVersion.invokeExact();
        } catch (Throwable e) {
            log("JSDL3.Version: " + e);
            return 0;
        }
    }

    public static long CreateWindow(char[] title, int w, int h, long flags) {
        if (SDL_CreateWindow == null) {
            return 0;
        }
        try {
            MemorySegment t = ARENA.allocateFrom(str(title));
            MemorySegment win = (MemorySegment) SDL_CreateWindow.invokeExact(
                    t, w, h, flags);
            return win.address();
        } catch (Throwable e) {
            log("JSDL3.CreateWindow: " + e);
            return 0;
        }
    }

    public static void DestroyWindow(long window) {
        if (SDL_DestroyWindow == null) {
            return;
        }
        try {
            SDL_DestroyWindow.invokeExact(ptr(window));
        } catch (Throwable e) {
            log("JSDL3.DestroyWindow: " + e);
        }
    }

    public static long CreateRenderer(long window) {
        if (SDL_CreateRenderer == null) {
            return 0;
        }
        try {
            MemorySegment r = (MemorySegment) SDL_CreateRenderer.invokeExact(
                    ptr(window), MemorySegment.NULL);
            return r.address();
        } catch (Throwable e) {
            log("JSDL3.CreateRenderer: " + e);
            return 0;
        }
    }

    public static void DestroyRenderer(long renderer) {
        if (SDL_DestroyRenderer == null) {
            return;
        }
        try {
            SDL_DestroyRenderer.invokeExact(ptr(renderer));
        } catch (Throwable e) {
            log("JSDL3.DestroyRenderer: " + e);
        }
    }

    public static boolean SetRenderDrawColor(long renderer, int r, int g, int b, int a) {
        if (SDL_SetRenderDrawColor == null) {
            return false;
        }
        try {
            return (boolean) SDL_SetRenderDrawColor.invokeExact(
                    ptr(renderer), (byte) r, (byte) g, (byte) b, (byte) a);
        } catch (Throwable e) {
            log("JSDL3.SetRenderDrawColor: " + e);
            return false;
        }
    }

    public static boolean RenderClear(long renderer) {
        if (SDL_RenderClear == null) {
            return false;
        }
        try {
            return (boolean) SDL_RenderClear.invokeExact(ptr(renderer));
        } catch (Throwable e) {
            log("JSDL3.RenderClear: " + e);
            return false;
        }
    }

    public static boolean RenderPresent(long renderer) {
        if (SDL_RenderPresent == null) {
            return false;
        }
        try {
            return (boolean) SDL_RenderPresent.invokeExact(ptr(renderer));
        } catch (Throwable e) {
            log("JSDL3.RenderPresent: " + e);
            return false;
        }
    }

    public static boolean RenderLine(long renderer, int x1, int y1, int x2, int y2) {
        if (SDL_RenderLine == null) {
            return false;
        }
        try {
            return (boolean) SDL_RenderLine.invokeExact(ptr(renderer),
                    (float) x1, (float) y1, (float) x2, (float) y2);
        } catch (Throwable e) {
            log("JSDL3.RenderLine: " + e);
            return false;
        }
    }

    public static boolean PollEvent(JSDL3Work_Event event) {
        if (SDL_PollEvent == null || event == null) {
            return false;
        }
        try {
            MemorySegment ev = ARENA.allocate(EV_SIZE);
            boolean ok = (boolean) SDL_PollEvent.invokeExact(ev);
            if (!ok) {
                return false;
            }
            int type = ev.get(ValueLayout.JAVA_INT, EV_TYPE);
            event.type = type;
            event.scancode = 0;
            event.key = 0;
            event.down = false;
            event.x = 0;
            event.y = 0;
            event.button = 0;
            if (type == 0x400) {                 // SDL_EVENT_MOUSE_MOTION
                event.x = (int) ev.get(ValueLayout.JAVA_FLOAT, 28);
                event.y = (int) ev.get(ValueLayout.JAVA_FLOAT, 32);
            } else if (type == 0x401 || type == 0x402) { // ...BUTTON_DOWN/UP
                event.button = ev.get(ValueLayout.JAVA_BYTE, 24) & 0xFF;
                event.down = ev.get(ValueLayout.JAVA_BOOLEAN, 25);
                event.x = (int) ev.get(ValueLayout.JAVA_FLOAT, 28);
                event.y = (int) ev.get(ValueLayout.JAVA_FLOAT, 32);
            } else {                             // keyboard / quit
                event.scancode = ev.get(ValueLayout.JAVA_INT, EV_SCANCODE);
                event.key = ev.get(ValueLayout.JAVA_INT, EV_KEY);
                event.down = ev.get(ValueLayout.JAVA_BOOLEAN, EV_DOWN);
            }
            return true;
        } catch (Throwable e) {
            log("JSDL3.PollEvent: " + e);
            return false;
        }
    }

    public static void Delay(int ms) {
        if (SDL_Delay == null) {
            return;
        }
        try {
            SDL_Delay.invokeExact(ms);
        } catch (Throwable e) {
            log("JSDL3.Delay: " + e);
        }
    }

    private static void log(String s) {
        try {
            CP.StdLog.StdLog.String(z(s));
            CP.StdLog.StdLog.Ln();
        } catch (Throwable ignored) {
            System.err.println(s);
        }
    }

    private static String str(char[] c) {
        if (c == null) {
            return "";
        }
        int n = 0;
        while (n < c.length && c[n] != 0) {
            n++;
        }
        return new String(c, 0, n);
    }

    private static void copy(String s, char[] out) {
        if (out == null) {
            return;
        }
        if (s == null) {
            s = "";
        }
        int n = Math.min(s.length(), out.length - 1);
        s.getChars(0, n, out, 0);
        out[n] = 0;
    }

    private static char[] z(String s) {
        char[] c = new char[s.length() + 1];
        s.getChars(0, s.length(), c, 0);
        return c;
    }

    private JSDL3Work() {
    }
}
