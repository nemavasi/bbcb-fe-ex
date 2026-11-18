/*
 * SPDX-License-Identifier: BSD-3-Clause
 * Copyright (c) 2026 nemavasi
 */

import javax.swing.SwingUtilities;

/**
 * Пример: Java вызывает подсистему {@code JEarth} (карта Земли).
 *
 * <p>Подсистема — обычный платформенный модуль: интерфейс
 * {@code JEarth/Mod/JEarth.cp}, тело — классы
 * {@code CP.JEarth.*}. Поэтому из Java доступно то же, что из CP:
 * {@code New}, {@code SetPosition}, {@code SetImagery}, {@code Zoom},
 * {@code Snapshot} и т.д.</p>
 *
 * <p>Порядок запуска (как у остальных примеров Interop):</p>
 * <pre>
 *   javac -cp build/native:build/gpcp-work:build/gradle-libs/* \
 *         -d /tmp/out EarthFromJava.java
 *   java  -Dblackbox.startupDir=&lt;каталог BBCB&gt; \
 *         -cp /tmp/out:build/native:build/gpcp-work:compiler/jars/cprts.jar:build/gradle-libs/* \
 *         EarthFromJava
 * </pre>
 *
 * <p>UI-вызовы (`Views.OpenAux`, `Views.Update`) — только в потоке Swing
 * (EDT): модели и виды BlackBox не потокобезопасны.</p>
 */
public final class EarthFromJava {

    private EarthFromJava() {
    }

    public static void main(String[] args) throws Exception {
        final boolean openWindow = args.length > 0 && "-open".equals(args[0]);

        // 1. Вид карты и камера (Альпы, 3000 км).
        final CP.JEarth.JEarth_EarthView v = CP.JEarth.JEarth.New();
        if (v == null) {
            System.out.println("earth=none err=" + str(CP.JEarth.JEarth.lastError));
            System.exit(1);
        }
        CP.JEarth.JEarth.SetPosition(v, 45.0, 10.0, 3.0e6);
        CP.JEarth.JEarth.SetImagery(v, CP.JEarth.JEarth.BLUE_MARBLE);

        // 2. Прочитать камеру: CP REAL = Java double, VAR-параметр = double[].
        double[] lat = new double[1];
        double[] lon = new double[1];
        double[] alt = new double[1];
        CP.JEarth.JEarth.GetPosition(v, lat, lon, alt);
        System.out.println("camera=" + lat[0] + "," + lon[0] + "," + alt[0]);

        // 3. Зум в 2 раза и проверка, что высота уменьшилась.
        CP.JEarth.JEarth.Zoom(v, 2.0);
        CP.JEarth.JEarth.GetPosition(v, lat, lon, alt);
        System.out.println("zoomed-alt=" + alt[0]);

        // 4. Снимок в PNG (headless): путь — во временный каталог.
        String png = System.getProperty("java.io.tmpdir") + "/earth-from-java.png";
        boolean ok = CP.JEarth.JEarth.Snapshot(v, cp(png));
        System.out.println("snapshot=" + ok + " path=" + png);

        // 5. Окно документа — только в EDT и только если он есть (GUI).
        if (openWindow) {
            SwingUtilities.invokeAndWait(() ->
                    CP.Views.Views.OpenAux(v, cp("Земля (из Java)")));
            System.out.println("window=opened");
        }
        System.out.println(ok ? "earth-from-java=ok" : "earth-from-java=fail");
        System.exit(ok ? 0 : 1);
    }

    /** Java-строка → CP-строка (char[] с завершающим NUL). */
    private static char[] cp(String s) {
        char[] c = new char[s.length() + 1];
        s.getChars(0, s.length(), c, 0);
        return c;
    }

    private static String str(char[] s) {
        int n = 0;
        while (n < s.length && s[n] != 0) {
            n++;
        }
        return new String(s, 0, n);
    }
}
