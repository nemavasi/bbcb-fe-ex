/*
 * SPDX-License-Identifier: BSD-3-Clause
 * Copyright (c) 2026 nemavasi
 */

package CP.JEarth;

import java.awt.Graphics2D;
import java.awt.RenderingHints;
import java.awt.image.BufferedImage;
import java.io.File;
import java.lang.reflect.Field;
import java.nio.IntBuffer;

import javax.imageio.ImageIO;

import com.jogamp.opengl.GL;
import com.jogamp.opengl.GL2;
import com.jogamp.opengl.GLAutoDrawable;
import com.jogamp.opengl.GLCapabilities;
import com.jogamp.opengl.GLDrawableFactory;
import com.jogamp.opengl.GLEventListener;
import com.jogamp.opengl.GLOffscreenAutoDrawable;
import com.jogamp.opengl.GLProfile;

import gov.nasa.worldwind.Model;
import gov.nasa.worldwind.View;
import gov.nasa.worldwind.WorldWind;
import gov.nasa.worldwind.WorldWindowGLAutoDrawable;
import gov.nasa.worldwind.WorldWindowImpl;
import gov.nasa.worldwind.avlist.AVKey;
import gov.nasa.worldwind.cache.BasicDataFileStore;
import gov.nasa.worldwind.geom.Position;
import gov.nasa.worldwind.geom.Vec4;
import gov.nasa.worldwind.layers.Layer;
import gov.nasa.worldwind.layers.TiledImageLayer;
import gov.nasa.worldwind.layers.Earth.BMNGOneImage;
import gov.nasa.worldwind.layers.Earth.BMNGWMSLayer;
import gov.nasa.worldwind.layers.Earth.LandsatI3WMSLayer;
import gov.nasa.worldwind.layers.Earth.OSMMapnikLayer;
import gov.nasa.worldwind.view.orbit.OrbitView;

/**
 * Офскрин-окно NASA World Wind для подсистемы {@code JEarth} (ADR-266).
 *
 * <p>WWJ рисует через OpenGL (JOGL), а BBCB — через Swing/AWT. Чтобы не
 * смешивать две оконные системы, кадр рендерится в память:
 * {@link GLOffscreenAutoDrawable} → {@link WorldWindowGLAutoDrawable} →
 * {@code glReadPixels} → {@link BufferedImage}. Вид документа
 * ({@link JEarth_EarthView}) отдаёт этот растр в
 * {@code HostPorts.Rider.DrawImage}.</p>
 *
 * <p>Три места, где WWJ рассчитан только на AWT-канву, обойдены подклассом
 * {@link Offscreen}: {@code redraw()}, {@code redrawNow()} и
 * {@code reshape()} кастуют drawable к {@code AWTGLAutoDrawable}/{@code Component}
 * и на offscreen-FBO падают {@code ClassCastException}. Кадр рисуется по
 * запросу из {@link #render(int, int)}.</p>
 *
 * <p>GPU-кэш WWJ обязан быть инициализирован до {@code initDrawable}
 * ({@code initGpuResourceCache}), иначе рендер падает с
 * «GPU Resource cache is null»; пиксели читает слушатель, добавленный
 * <b>после</b> {@code initDrawable}, иначе читается предыдущий кадр.</p>
 *
 * <p>Кэш тайлов — внутри подсистемы: {@code <startup>/JEarth/Rsrc/Cache}
 * (ADR-265).</p>
 */
final class EarthWindow {

    /** Минимальный размер кадра (WWJ не любит нулевые размеры). */
    private static final int MIN = 16;

    /** Насколько близко/далеко можно улететь, метры. */
    private static final double MIN_ALT = 2.0e3;
    private static final double MAX_ALT = 4.0e7;

    /** Высота камеры по умолчанию (вся Земля). */
    static final double DEFAULT_ALT = 2.2e7;

    private final GLOffscreenAutoDrawable drawable;
    private final Offscreen ww;
    private final Model model;
    /** Наборы слоёв по источникам изображения (BlueMarble/OSM/Landsat). */
    private Layer[][] imagery;
    private Layer[] active;
    /** Точки-маркеры: координаты и фигуры WWJ. */
    private final java.util.List<Marker> markerList = new java.util.ArrayList<>();

    /** Точка на карте: координаты и цвет. */
    private static final class Marker {
        final double lat, lon;
        final int rgb;

        Marker(double lat, double lon, int rgb) {
            this.lat = lat;
            this.lon = lon;
            this.rgb = rgb;
        }
    }

    private BufferedImage frame;
    private int w;
    private int h;
    private boolean dirty = true;
    private String error;

    /** Вызывается, когда WWJ просит перерисовать (пришли тайлы и т.п.). */
    private Runnable repaintHook;

    /**
     * Тайлы приходят порциями, и каждому нужен ещё один кадр, чтобы попасть
     * в текстуру. После сигнала WWJ делаем несколько дорисовок с паузой
     * (`settleFrames`), иначе карта остаётся «звёздным небом» до
     * следующего действия пользователя.
     */
    private int settleFrames;
    private javax.swing.Timer settleTimer;

    /** Идёт рендер: рекурсивные {@code redraw()} игнорируются. */
    private boolean rendering;

    /** Источник изображения по умолчанию. */
    private int source0 = JEarth.BLUE_MARBLE;

    /**
     * Подкласс WWJ-окна, отключающий AWT-операции.
     */
    static final class Offscreen extends WorldWindowGLAutoDrawable {
        private final GLAutoDrawable off;

        Offscreen(GLAutoDrawable d) {
            this.off = d;
        }

        @Override
        public void redraw() {
            // Кадр — по запросу из render(); здесь только сообщаем виду,
            // что пора обновиться (например, догрузились тайлы).
            EarthWindow owner = this.owner;
            if (owner != null) {
                owner.requestRepaint();
            }
        }

        @Override
        public void redrawNow() {
            off.display();
        }

        @Override
        public void reshape(GLAutoDrawable d, int x, int y, int width, int height) {
            // WWJ приводит drawable к Component — на offscreen это падает.
        }

        private EarthWindow owner;
    }

    EarthWindow(int width, int height) {
        this.w = Math.max(MIN, width);
        this.h = Math.max(MIN, height);
        GLOffscreenAutoDrawable d = null;
        Offscreen window = null;
        Model m = null;
        try {
            configureDataStore();
            GLProfile profile = GLProfile.getDefault();
            GLCapabilities caps = new GLCapabilities(profile);
            d = GLDrawableFactory.getFactory(profile)
                    .createOffscreenAutoDrawable(null, caps, null, this.w, this.h);
            d.setAutoSwapBufferMode(false);

            window = new Offscreen(d);
            window.owner = this;
            // 1) GPU-кэш — до initDrawable (иначе WWJ.init падает).
            d.addGLEventListener(new GpuCacheInit(window));
            // 2) сам WWJ.
            window.initDrawable(d);
            // 3) чтение пикселей — после WWJ, иначе кадр «предыдущий».
            d.addGLEventListener(new Grabber());

            m = (Model) WorldWind.createConfigurationComponent(AVKey.MODEL_CLASS_NAME);
            // Умолчательный набор изображений WWJ не используем: источник
            // выбирает CP-программа (SetImagery), и слои не должны
            // накладываться друг на друга.
            for (Layer l : new java.util.ArrayList<>(m.getLayers())) {
                if (l instanceof TiledImageLayer
                        || l instanceof BMNGOneImage
                        || l instanceof LandsatI3WMSLayer) {
                    m.getLayers().remove(l);
                }
            }

            window.setModel(m);
            window.setView((View) WorldWind.createConfigurationComponent(
                    AVKey.VIEW_CLASS_NAME));
            if (!(window.getView() instanceof OrbitView)) {
                throw new IllegalStateException("WWJ: нет OrbitView");
            }
            setPosition(0.0, 0.0, DEFAULT_ALT);
        } catch (Throwable t) {
            error = "JEarth: " + t;
            System.err.println(error);
            window = null;
            m = null;
        }
        this.drawable = d;
        this.ww = window;
        this.model = m;
        if (m == null) {
            this.imagery = null;
        } else {
            this.imagery = new Layer[][]{
                    // BlueMarble: быстрый однослойный снимок + детальный WMS
                    {new BMNGOneImage(), new BMNGWMSLayer()},
                    {new OSMMapnikLayer()},
                    {new LandsatI3WMSLayer()}
            };
            // Слои изображения — в начало списка, чтобы компас/масштаб/
            // карта мира (они в конце) рисовались поверх.
            for (Layer[] group : this.imagery) {
                for (int i = group.length - 1; i >= 0; i--) {
                    Layer l = group[i];
                    l.setEnabled(false);
                    m.getLayers().add(0, l);
                }
            }
            setImagery(source0);
        }
    }

    /** Доступен ли рендер (GL инициализирован). */
    boolean ok() {
        return ww != null && error == null;
    }

    /** Текст последней ошибки (или {@code null}). */
    String error() {
        return error;
    }

    void setRepaintHook(Runnable hook) {
        this.repaintHook = hook;
    }

    private void requestRepaint() {
        if (repaintHook == null) {
            return;
        }
        dirty = true;
        settleFrames = Math.max(settleFrames, 4);
        fireRepaint();
        scheduleSettle();
    }

    /** Разбудить вид: `Restore` перерисует кадр (всегда на EDT). */
    private void fireRepaint() {
        Runnable r = () -> {
            try {
                repaintHook.run();
            } catch (Throwable ignored) {
                // вид уже закрыт
            }
        };
        if (java.awt.EventQueue.isDispatchThread()) {
            r.run();
        } else {
            java.awt.EventQueue.invokeLater(r);
        }
    }

    /** Несколько дорисовок после прихода тайлов (см. {@link #settleFrames}). */
    private void scheduleSettle() {
        if (settleTimer == null) {
            settleTimer = new javax.swing.Timer(250, e -> {
                if (settleFrames <= 0) {
                    ((javax.swing.Timer) e.getSource()).stop();
                    return;
                }
                settleFrames--;
                dirty = true;
                fireRepaint();
            });
            settleTimer.setRepeats(true);
        }
        if (!settleTimer.isRunning()) {
            settleTimer.start();
        }
    }

    /**
     * Кэш тайлов — в подсистеме ({@code JEarth/Rsrc/Cache}, ADR-265).
     * Если каталог недоступен, WWJ использует свой по умолчанию.
     */
    private static void configureDataStore() {
        File dir = cacheDir();
        try {
            if (dir != null && !dir.isDirectory() && !dir.mkdirs()) {
                System.err.println("JEarth: не создать кэш " + dir);
                return;
            }
            BasicDataFileStore store = dir == null
                    ? new BasicDataFileStore() : new BasicDataFileStore(dir);
            // У WWJ нет публичного сеттера: подменяем поле синглтона
            // (приложение работает с classpath, не с module-path).
            Field inst = WorldWind.class.getDeclaredField("instance");
            inst.setAccessible(true);
            Object worldwind = inst.get(null);
            Field fld = WorldWind.class.getDeclaredField("dataFileStore");
            fld.setAccessible(true);
            fld.set(worldwind, store);
        } catch (Throwable t) {
            System.err.println("JEarth: кэш WWJ по умолчанию: " + t);
        }
    }

    /** Диагностика: слои модели (для отладки/тестов). */
    java.util.Iterator<Layer> modelLayers() {
        return model == null ? java.util.Collections.<Layer>emptyList().iterator()
                : model.getLayers().iterator();
    }

    /** Каталог кэша внутри подсистемы. */
    static File cacheDir() {
        String startup = System.getProperty("blackbox.startupDir",
                System.getProperty("user.dir", "."));
        File sub = new File(startup, "JEarth");
        if (!sub.isDirectory()) {
            return null;
        }
        return new File(new File(sub, "Rsrc"), "Cache");
    }

    // ------------------------------------------------------------- рисование

    /**
     * Кадр в пикселях {@code width×height}. Повторный вызов без изменений
     * камеры/размера отдаёт кэш.
     */
    BufferedImage render(int width, int height) {
        if (!ok()) {
            return null;
        }
        if (width < MIN) {
            width = MIN;
        }
        if (height < MIN) {
            height = MIN;
        }
        try {
            if (width != w || height != h) {
                w = width;
                h = height;
                drawable.setSurfaceSize(w, h);
                dirty = true;
            }
            if (frame == null || dirty) {
                rendering = true;
                try {
                    dirty = false;
                    drawable.display();
                } finally {
                    rendering = false;
                }
                // Точки рисуем только на **свежем** кадре: иначе накладка
                // считалась бы по новой камере, а глобус остался бы старым
                // (точки «отрывались» от планеты).
                drawMarkers();
            }
            return frame;
        } catch (Throwable t) {
            error = "JEarth: рендер: " + t;
            System.err.println(error);
            return null;
        }
    }

    /** Пометить кадр устаревшим (тайлы пришли, камера изменилась). */
    void markDirty() {
        dirty = true;
    }

    /**
     * Пустой ли кадр: почти один цвет. Нужно headless-тесту, чтобы
     * дождаться первых тайлов (или честно сказать «сети нет»).
     */
    static boolean blank(BufferedImage img) {
        if (img == null) {
            return true;
        }
        int w = img.getWidth();
        int h = img.getHeight();
        java.util.HashMap<Integer, Integer> colors = new java.util.HashMap<>();
        int total = 0;
        for (int y = 0; y < h; y += Math.max(1, h / 32)) {
            for (int x = 0; x < w; x += Math.max(1, w / 32)) {
                int rgb = img.getRGB(x, y) & 0x00FFFFFF;
                colors.merge(rgb, 1, Integer::sum);
                total++;
            }
        }
        int max = 0;
        for (int n : colors.values()) {
            max = Math.max(max, n);
        }
        // «Пусто» = один цвет покрывает почти весь кадр (звёздное небо без
        // карты тоже сюда попадает: звёзд единицы).
        return total > 0 && max * 100 / total > 85;
    }

    /** Слушатель, инициализирующий GPU-кэш до {@code initDrawable}. */
    private static final class GpuCacheInit implements GLEventListener {
        private final Offscreen ww;

        GpuCacheInit(Offscreen ww) {
            this.ww = ww;
        }

        @Override
        public void init(GLAutoDrawable d) {
            ww.initGpuResourceCache(WorldWindowImpl.createGpuResourceCache());
        }

        @Override
        public void reshape(GLAutoDrawable d, int x, int y, int w, int h) {
        }

        @Override
        public void dispose(GLAutoDrawable d) {
        }

        @Override
        public void display(GLAutoDrawable d) {
        }
    }

    /** Слушатель, снимающий кадр после отрисовки WWJ. */
    private final class Grabber implements GLEventListener {
        @Override
        public void init(GLAutoDrawable d) {
        }

        @Override
        public void reshape(GLAutoDrawable d, int x, int y, int width, int height) {
            // Размер задаёт render(); WWJ.reshape гасит AWT-каст.
        }

        @Override
        public void dispose(GLAutoDrawable d) {
        }

        @Override
        public void display(GLAutoDrawable d) {
            GL2 gl = d.getGL().getGL2();
            IntBuffer buf = IntBuffer.allocate(w * h);
            gl.glReadPixels(0, 0, w, h, GL.GL_BGRA, GL.GL_UNSIGNED_BYTE, buf);
            BufferedImage img = new BufferedImage(w, h, BufferedImage.TYPE_INT_RGB);
            for (int y = 0; y < h; y++) {
                int row = y * w;
                int dst = h - 1 - y;
                for (int x = 0; x < w; x++) {
                    img.setRGB(x, dst, buf.get(row + x) & 0x00FFFFFF);
                }
            }
            frame = img;
        }
    }

    // --------------------------------------------------------------- камера

    private OrbitView view() {
        return (OrbitView) ww.getView();
    }

    void setPosition(double lat, double lon, double alt) {
        if (!ok()) {
            return;
        }
        double la = clampLat(lat);
        double lo = normLon(lon);
        double al = clampAlt(alt);
        view().setEyePosition(Position.fromDegrees(la, lo, al));
        dirty = true;
    }

    /** Широта, долгота (градусы) и высота (метры) глаза камеры. */
    double[] getPosition() {
        if (!ok()) {
            return new double[]{0, 0, DEFAULT_ALT};
        }
        Position p = view().getEyePosition();
        if (p == null) {
            return new double[]{0, 0, DEFAULT_ALT};
        }
        return new double[]{p.getLatitude().degrees,
                p.getLongitude().degrees, p.getAltitude()};
    }

    /** Сдвиг центра карты на {@code dLat/dLon} градусов. */
    void pan(double dLat, double dLon) {
        if (!ok()) {
            return;
        }
        Position c = view().getCenterPosition();
        if (c == null) {
            c = view().getEyePosition();
        }
        if (c == null) {
            return;
        }
        double lat = clampLat(c.getLatitude().degrees + dLat);
        double lon = normLon(c.getLongitude().degrees + dLon);
        view().setCenterPosition(Position.fromDegrees(lat, lon, 0));
        dirty = true;
    }

    /**
     * Сдвиг от перетаскивания мышью на {@code dx,dy} пикселей.
     *
     * <p>Масштаб считается по высоте камеры и размеру кадра (поле зрения
     * WWJ ≈ 45°): при перетаскивании карта «липнет» к курсору с точностью,
     * достаточной для просмотра.</p>
     */
    void drag(double dx, double dy) {
        if (!ok()) {
            return;
        }
        double alt = Math.max(MIN_ALT, view().getEyePosition().getAltitude());
        double metersPerPixel = alt * 2.0 * Math.tan(Math.toRadians(22.5)) / Math.max(1, h);
        double degPerPixel = metersPerPixel / 111320.0;
        Position c = view().getCenterPosition();
        double lat = c == null ? 0 : c.getLatitude().degrees;
        double lon = c == null ? 0 : c.getLongitude().degrees;
        double cos = Math.max(0.15, Math.cos(Math.toRadians(lat)));
        pan(dy * degPerPixel, -dx * degPerPixel / cos);
    }

    /** Зум: {@code factor > 1} — ближе, {@code < 1} — дальше. */
    void zoom(double factor) {
        if (!ok() || factor <= 0) {
            return;
        }
        double[] p = getPosition();
        setPosition(p[0], p[1], p[2] / factor);
    }

    /** Слой изображения: {@code JEarth.BlueMarble/OpenStreetMap/Landsat}. */
    void setImagery(int source) {
        if (!ok() || imagery == null) {
            return;
        }
        int idx = source >= 0 && source < imagery.length ? source : 0;
        if (active != null) {
            for (Layer l : active) {
                l.setEnabled(false);
            }
        }
        active = imagery[idx];
        for (Layer l : active) {
            l.setEnabled(true);
        }
        dirty = true;
    }

    // ------------------------------------------------------------- маркеры

    /**
     * Поставить точку на карте.
     *
     * <p>Точка — {@link PointPlacemark} со «встроенной» точкой WWJ
     * ({@code setUsePointAsDefaultImage}), поэтому картинка-иконка не нужна:
     * рисуется кружок заданного цвета. Слой маркеров лежит поверх
     * изображения, поэтому точки видны и на спутниковом снимке, и на OSM.</p>
     *
     * @param lat широта, градусы
     * @param lon долгота, градусы
     * @param rgb цвет {@code 0xRRGGBB}
     */
    void addMarker(double lat, double lon, int rgb) {
        markerList.add(new Marker(lat, lon, rgb));
        markDirty();
    }

    /** Убрать все маркеры. */
    void clearMarkers() {
        markerList.clear();
        markDirty();
    }

    /** Сколько маркеров на карте. */
    int markerCount() {
        return markerList.size();
    }

    /**
     * Нарисовать маркеры поверх готового кадра.
     *
     * <p>Точки проецируются **сами**, по текущей камере
     * ({@code getEyePoint}/{@code getForwardVector}/{@code getUpVector} и
     * полю зрения), а не через {@code View.project}. Причина — рассинхрон:
     * {@code View.project} берёт матрицы последнего {@code apply()}, и при
     * перетаскивании/повороте карты точки отставали на кадр и «отрывались»
     * от глобуса. Векторы камеры обновляются сразу в
     * {@code setPosition}/{@code pan}, поэтому накладка совпадает с
     * картой.</p>
     *
     * <p>Точки на обратной стороне Земли отбрасываются: нормаль в точке
     * против направления на глаз.</p>
     */
    private void drawMarkers() {
        if (frame == null || markerList.isEmpty() || ww == null || model == null) {
            return;
        }
        gov.nasa.worldwind.View view;
        gov.nasa.worldwind.globes.Globe globe;
        Vec4 eye, fwd, up;
        double fov;
        try {
            view = ww.getView();
            globe = model.getGlobe();
            eye = view.getEyePoint();
            fwd = view.getForwardVector();
            up = view.getUpVector();
            fov = view.getFieldOfView() == null ? 45.0
                    : view.getFieldOfView().degrees;
        } catch (Throwable t) {
            return;
        }
        if (view == null || globe == null || eye == null || fwd == null || up == null) {
            return;
        }
        Vec4 right = fwd.cross3(up).normalize3();
        // ВАЖНО: `View.getFieldOfView()` в WWJ — **горизонтальный** угол
        // (`Matrix.fromPerspective` строит m00 = 1/tan(fov/2),
        // m11 = m00 * width / height). Поэтому фокусное расстояние считается
        // по ширине кадра. Раньше здесь стояла высота: при соотношении
        // сторон 661:501 точки проецировались к центру примерно на 24 %
        // ближе, чем поверхность глобуса, — столицы «уезжали» под землю или
        // над ней при панорамировании и зуме.
        int vw = w;
        int vh = h;
        int vx = 0;
        int vy = 0;
        try {
            java.awt.Rectangle vp = view.getViewport();
            if (vp != null && vp.width > 0 && vp.height > 0) {
                vx = vp.x;
                vy = vp.y;
                vw = vp.width;
                vh = vp.height;
            }
        } catch (Throwable ignored) {
            // остаётся размер кадра
        }
        double focal = (vw / 2.0) / Math.tan(Math.toRadians(fov) / 2.0);
        Graphics2D g = frame.createGraphics();
        try {
            g.setRenderingHint(RenderingHints.KEY_ANTIALIASING,
                    RenderingHints.VALUE_ANTIALIAS_ON);
            for (Marker m : markerList) {
                Vec4 p;
                try {
                    p = globe.computePointFromPosition(Position.fromDegrees(m.lat, m.lon, 0));
                } catch (Throwable t) {
                    continue;
                }
                if (p.dot3(eye.subtract3(p)) <= 0) {
                    continue;                     // обратная сторона Земли
                }
                Vec4 d = p.subtract3(eye);
                double z = d.dot3(fwd);
                if (z <= 0) {
                    continue;
                }
                double x = d.dot3(right);
                double y = d.dot3(up);
                int sx = (int) Math.round(vx + vw / 2.0 + focal * x / z);
                int sy = (int) Math.round(vy + vh / 2.0 - focal * y / z);
                if (sx < -4 || sy < -4 || sx > w + 4 || sy > h + 4) {
                    continue;
                }
                g.setColor(new java.awt.Color(m.rgb & 0xFFFFFF));
                g.fillOval(sx - 2, sy - 2, 5, 5);
            }
        } finally {
            g.dispose();
        }
    }

    // -------------------------------------------------------------- запись

    /** Записать текущий кадр в PNG. */
    boolean writePng(File file) {
        BufferedImage img = frame != null ? frame : render(w, h);
        if (img == null) {
            return false;
        }
        try {
            File parent = file.getParentFile();
            if (parent != null && !parent.isDirectory()) {
                parent.mkdirs();
            }
            return ImageIO.write(img, "png", file);
        } catch (Throwable t) {
            error = "JEarth: запись PNG: " + t;
            System.err.println(error);
            return false;
        }
    }

    void dispose() {
        try {
            if (settleTimer != null) {
                settleTimer.stop();
                settleTimer = null;
            }
        } catch (Throwable ignored) {
            // таймер уже не нужен
        }
        try {
            if (ww != null) {
                ww.shutdown();
            }
        } catch (Throwable ignored) {
            // shutdown WWJ не критичен для жизни приложения
        }
        try {
            if (drawable != null) {
                drawable.destroy();
            }
        } catch (Throwable ignored) {
            // destroy GL-контекста
        }
        frame = null;
    }

    // ------------------------------------------------------------ утилиты

    private static double clampLat(double lat) {
        return Math.max(-89.9, Math.min(89.9, lat));
    }

    private static double normLon(double lon) {
        double l = lon % 360.0;
        if (l > 180.0) {
            l -= 360.0;
        }
        if (l < -180.0) {
            l += 360.0;
        }
        return l;
    }

    private static double clampAlt(double alt) {
        return Math.max(MIN_ALT, Math.min(MAX_ALT, alt));
    }
}
