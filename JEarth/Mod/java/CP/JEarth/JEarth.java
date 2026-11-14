/*
 * SPDX-License-Identifier: BSD-3-Clause
 * Copyright (c) 2026 nemavasi
 */

package CP.JEarth;

import java.io.File;

import CP.Documents.Documents;
import CP.StdLog.StdLog;
import CP.Views.Views;

/**
 * Java-тело модуля {@code JEarth} — минимальный API карты Земли для
 * Component Pascal (ADR-266).
 *
 * <p>Рендеринг — NASA World Wind Java поверх offscreen OpenGL
 * ({@link EarthWindow}); вид документа — {@link JEarth_EarthView}.
 * Модульные процедуры создают/настраивают вид и открывают его в окне
 * BBCB, поэтому CP-программе не нужны ни Swing, ни classpath:</p>
 *
 * <pre>
 *   v := JEarth.New();
 *   JEarth.SetPosition(v, 45.0, 10.0, 3000000.0);
 *   Views.OpenAux(v, "Земля")
 * </pre>
 *
 * <p>{@code lastError} — текст последней ошибки (пусто, если всё хорошо):
 * так CP-программа узнаёт, что карта недоступна (нет OpenGL/драйвера,
 * не создался кэш), и может показать сообщение вместо карты.</p>
 */
public final class JEarth {

    /** Источники изображения: {@code JEarth.BlueMarble} и т.д. */
    public static final int BLUE_MARBLE = 0;
    public static final int OPEN_STREET_MAP = 1;
    public static final int LANDSAT = 2;

    /** Последняя ошибка (пустая строка — ошибки нет). */
    public static char[] lastError = new char[256];

    private JEarth() {
    }

    // ------------------------------------------------------------- создание

    /** Новый вид карты (без окна). */
    public static JEarth_EarthView New() {
        clearError();
        try {
            JEarth_EarthView v = new JEarth_EarthView();
            // Создаём окно сразу: если GL недоступен, lastError уже заполнен,
            // а вид нарисует заглушку с причиной.
            EarthWindow w = v.window();
            if (!w.ok() && w.error() != null) {
                setError(w.error());
            }
            return v;
        } catch (Throwable t) {
            setError("JEarth.New: " + t);
            return null;
        }
    }

    /** Открыть карту в новом окне документа. */
    public static void Open(char[] title, double lat, double lon, double altitude) {
        JEarth_EarthView v = New();
        if (v == null) {
            return;
        }
        SetPosition(v, lat, lon, altitude);
        try {
            if (title != null && title.length > 0 && str(title).length() > 0) {
                Views.OpenAux(v, title);
            } else {
                Views.OpenView(v);
            }
        } catch (Throwable t) {
            setError("JEarth.Open: " + t);
        }
    }

    // --------------------------------------------------------------- камера

    /** Широта/долгота (градусы) и высота (метры). */
    public static void SetPosition(JEarth_EarthView v, double lat, double lon,
                                   double altitude) {
        try {
            v.window().setPosition(lat, lon, altitude);
        } catch (Throwable t) {
            setError("JEarth.SetPosition: " + t);
        }
    }

    /** Текущая камера: широта, долгота (градусы), высота (метры). */
    public static void GetPosition(JEarth_EarthView v, double[] lat,
                                   double[] lon, double[] altitude) {
        try {
            double[] p = v.window().getPosition();
            if (lat != null && lat.length > 0) {
                lat[0] = p[0];
            }
            if (lon != null && lon.length > 0) {
                lon[0] = p[1];
            }
            if (altitude != null && altitude.length > 0) {
                altitude[0] = p[2];
            }
        } catch (Throwable t) {
            setError("JEarth.GetPosition: " + t);
        }
    }

    /** Зум: {@code factor > 1} — ближе, {@code < 1} — дальше. */
    public static void Zoom(JEarth_EarthView v, double factor) {
        try {
            v.window().zoom(factor);
        } catch (Throwable t) {
            setError("JEarth.Zoom: " + t);
        }
    }

    /** Сдвинуть центр карты на {@code dLat/dLon} градусов. */
    public static void Pan(JEarth_EarthView v, double dLat, double dLon) {
        try {
            v.window().pan(dLat, dLon);
        } catch (Throwable t) {
            setError("JEarth.Pan: " + t);
        }
    }

    /** Источник изображения (BlueMarble/OpenStreetMap/Landsat). */
    public static void SetImagery(JEarth_EarthView v, int source) {
        try {
            v.window().setImagery(source);
        } catch (Throwable t) {
            setError("JEarth.SetImagery: " + t);
        }
    }

    /** Перерисовать вид. */
    public static void Update(JEarth_EarthView v) {
        try {
            // keepFrames: это чистая перерисовка растра. `rebuildFrames`
            // закрывает и создаёт заново кадры документа — вид остался бы с
            // закрытым кадром (`rider = NIL`) и упал бы на `f.Input`/рисовании
            // (TRAP 201 при перетаскивании карты).
            Views.Update(v, false);
        } catch (Throwable t) {
            setError("JEarth.Update: " + t);
        }
    }

    // ------------------------------------------------------------- маркеры

    /**
     * Поставить точку на карте (например, столицу).
     *
     * <p>Точка живёт в отдельном слое поверх изображения и переживает
     * смену источника карты и панорамирование. Цвет — {@code 0xRRGGBB}
     * (см. {@code JEarth.red}); {@code -1} — чёрный.</p>
     */
    public static void AddMarker(JEarth_EarthView v, double lat, double lon,
                                 int color) {
        if (v == null) {
            return;
        }
        try {
            v.addMarker(lat, lon, color);
        } catch (Throwable t) {
            setError("JEarth.AddMarker: " + t);
        }
    }

    /** Убрать все маркеры. */
    public static void ClearMarkers(JEarth_EarthView v) {
        if (v == null) {
            return;
        }
        try {
            v.clearMarkers();
        } catch (Throwable t) {
            setError("JEarth.ClearMarkers: " + t);
        }
    }

    /** Сколько маркеров на карте. */
    public static int MarkerCount(JEarth_EarthView v) {
        if (v == null) {
            return 0;
        }
        try {
            return v.markerCount();
        } catch (Throwable t) {
            setError("JEarth.MarkerCount: " + t);
            return 0;
        }
    }

    // -------------------------------------------------------------- снимки

    /** Снимок вида в PNG (текущий кадр в его размере). */
    public static boolean Snapshot(JEarth_EarthView v, char[] path) {
        try {
            if (path == null) {
                setError("JEarth.Snapshot: пустой путь");
                return false;
            }
            EarthWindow w = v.window();
            int[] size = v.viewSize(null);
            // Дать WWJ догрузить тайлы: первый кадр часто ещё фон. Пять
            // дорисовок по 250 мс достаточно для однослойного Blue Marble
            // (демо `CapitalsCheck`), а сеть может и не быть — тогда
            // останется фон, это не ошибка.
            java.awt.image.BufferedImage img = w.render(size[0], size[1]);
            for (int i = 0; i < 5; i++) {
                try {
                    Thread.sleep(250);
                } catch (InterruptedException ignored) {
                    Thread.currentThread().interrupt();
                    break;
                }
                w.markDirty();
                img = w.render(size[0], size[1]);
            }
            // Относительный путь — от каталога поставки (`blackbox.startupDir`),
            // чтобы CP-код не зависел от рабочего каталога процесса.
            File f = new File(str(path));
            if (!f.isAbsolute()) {
                String root = System.getProperty("blackbox.startupDir");
                if (root != null && !root.isEmpty()) {
                    f = new File(root, str(path));
                }
            }
            boolean ok = w.writePng(f);
            if (!ok) {
                setError("JEarth.Snapshot: не записал " + str(path));
            }
            return ok;
        } catch (Throwable t) {
            setError("JEarth.Snapshot: " + t);
            return false;
        }
    }

    /**
     * Рендер в кэш подсистемы ({@code JEarth/Rsrc/Cache/demo.png}).
     * Путь считает Java (она знает `blackbox.startupDir`), поэтому CP-код
     * не зависит от рабочего каталога.
     */
    public static boolean RenderToCache() {
        clearError();
        try {
            File dir = EarthWindow.cacheDir();
            if (dir == null) {
                setError("JEarth: нет каталога подсистемы");
                return false;
            }
            File png = new File(dir, "demo.png");
            return RenderFile(chars(png.getPath()), 320, 200, 45.0, 10.0, 3.0e6);
        } catch (Throwable t) {
            setError("JEarth.RenderToCache: " + t);
            return false;
        }
    }

    /**
     * Headless-проверка рендера без окна и документа (для смоука/экспорта).
     *
     * @return {@code true}, если PNG записан и содержит непустой кадр
     */
    public static boolean RenderFile(char[] path, int width, int height,
                                    double lat, double lon, double altitude) {
        clearError();
        EarthWindow w = null;
        try {
            int ww = width > 0 ? width : 320;
            int hh = height > 0 ? height : 200;
            w = new EarthWindow(ww, hh);
            if (!w.ok()) {
                setError(w.error() == null ? "JEarth: GL недоступен" : w.error());
                return false;
            }
            w.setPosition(lat, lon, altitude);
            // Первые кадры могут быть без тайлов: ждём до ~3 с, пока WWJ
            // догрузит изображение (в офлайне кадр так и останется фоном —
            // это не ошибка, GL-конвейер работает).
            java.awt.image.BufferedImage img = w.render(ww, hh);
            for (int i = 0; i < 10 && EarthWindow.blank(img); i++) {
                Thread.sleep(300);
                w.markDirty();
                img = w.render(ww, hh);
            }
            if (img == null) {
                setError("JEarth: пустой кадр");
                return false;
            }
            boolean ok = w.writePng(new File(str(path)));
            if (!ok) {
                setError("JEarth.RenderFile: не записал " + str(path));
            }
            return ok;
        } catch (Throwable t) {
            setError("JEarth.RenderFile: " + t);
            return false;
        } finally {
            if (w != null) {
                w.dispose();
            }
        }
    }

    /** Текст последней ошибки в окно `Log` (удобно из CP-демо). */
    public static void LogError() {
        String e = cstr(lastError);
        StdLog.String(chars(e.isEmpty() ? "JEarth: ok" : e));
        StdLog.Ln();
    }

    // ------------------------------------------------------------ утилиты

    static void clearError() {
        java.util.Arrays.fill(lastError, (char) 0);
    }

    static void setError(String text) {
        clearError();
        if (text == null) {
            return;
        }
        int n = Math.min(text.length(), lastError.length - 1);
        text.getChars(0, n, lastError, 0);
    }

    /** GPCP-строка ({@code char[]} с завершающим 0) → {@link String}. */
    static String str(char[] s) {
        if (s == null) {
            return "";
        }
        int n = 0;
        while (n < s.length && s[n] != 0) {
            n++;
        }
        return new String(s, 0, n);
    }

    static String cstr(char[] s) {
        return str(s);
    }

    /** {@link String} → GPCP-строка ({@code char[]} с завершающим 0). */
    static char[] chars(String s) {
        char[] r = new char[s.length() + 1];
        s.getChars(0, s.length(), r, 0);
        return r;
    }
}
