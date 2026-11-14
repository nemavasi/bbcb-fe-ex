/*
 * SPDX-License-Identifier: BSD-3-Clause
 * Copyright (c) 2026 nemavasi
 */

package CP.JEarth;

import java.awt.Color;
import java.awt.Font;
import java.awt.Graphics2D;
import java.awt.RenderingHints;
import java.awt.image.BufferedImage;

import CP.Controllers.Controllers_PollCursorMsg;
import CP.Controllers.Controllers_TrackMsg;
import CP.Controllers.Controllers_WheelMsg;
import CP.HostPorts.HostPorts;
import CP.HostPorts.HostPorts_Rider;
import CP.HostWindows.HostWindows;
import CP.Models.Models_Model;
import CP.Properties.Properties_SizePref;
import CP.Views.Views;
import CP.Views.Views_Frame;
import CP.Views.Views_PropMessage;
import CP.Views.Views_View;

/**
 * Вид карты Земли в документе BBCB (подсистема {@code JEarth}).
 *
 * <p>Рисование: WWJ рендерит кадр в {@link EarthWindow} (offscreen OpenGL),
 * вид отдаёт готовый растр в {@code HostPorts.Rider.DrawImage} — как
 * {@code HostPictures_StdView}/{@code Media_StdView} (ADR-150). Размер
 * берётся из контекста вида, а не из области перерисовки: иначе при
 * частичном обновлении картинка «сплющивается».</p>
 *
 * <p>Взаимодействие: перетаскивание мышью — прокрутка карты
 * ({@link Controllers_TrackMsg} + модальный цикл {@code f.Input}, как в
 * {@code Ctrls.Track}), колесо — зум ({@link Controllers_WheelMsg}),
 * курсор над картой — «рука» ({@link Controllers_PollCursorMsg}).</p>
 */
public class JEarth_EarthView extends Views_View {

    /** `WinApi.SB_*`-коды из `WheelMsg.op` (см. `HostWindows_Window`). */
    private static final int DEC_LINE = 0;
    private static final int INC_LINE = 1;
    private static final int DEC_PAGE = 2;
    private static final int INC_PAGE = 3;

    /** Один щелчок колеса. */
    private static final double ZOOM_STEP = 1.3;

    /** `Ports.refCursor` — «рука». */
    private static final int CURSOR_HAND = 5;

    /** Размер нового окна карты по умолчанию, в единицах. */
    private static final int DEFAULT_W = 640;
    private static final int DEFAULT_H = 460;

    private transient EarthWindow window;
    private transient String placeholderText;

    /** Окно рендера (создаётся лениво: в документе может быть много видов). */
    EarthWindow window() {
        if (window == null) {
            window = new EarthWindow(DEFAULT_W, DEFAULT_H);
            // WWJ просит перерисовать, когда догрузились тайлы: обновляем вид,
            // иначе карта останется «в клетку» до следующего действия.
            window.setRepaintHook(() -> {
                try {
                    Views.Update(this, false);
                } catch (Throwable ignored) {
                    // вид мог быть уже закрыт
                }
            });
        }
        return window;
    }

    // -------------------------------------------------------------- маркеры

    /** Точка на карте (делегируется окну рендера). */
    void addMarker(double lat, double lon, int rgb) {
        window().addMarker(lat, lon, rgb);
    }

    /** Убрать все точки. */
    void clearMarkers() {
        if (window != null) {
            window.clearMarkers();
        }
    }

    /** Число точек. */
    int markerCount() {
        return window == null ? 0 : window.markerCount();
    }

    // ------------------------------------------------------------- рисование

    @Override
    public void Restore(Views_Frame f, int l, int t, int r, int b) {
        if (!(f.rider instanceof HostPorts_Rider)) {
            return;
        }
        int u = f.unit > 0 ? f.unit : HostWindows.unit;
        int[] size = viewSize(f);
        int x0 = f.gx / u;
        int y0 = f.gy / u;
        int x1 = x0 + size[0];
        int y1 = y0 + size[1];
        BufferedImage img = window().render(x1 - x0, y1 - y0);
        if (img == null) {
            img = placeholder(x1 - x0, y1 - y0);
        }
        ((HostPorts_Rider) f.rider).DrawImage(img, x0, y0, x1, y1);
        HostPorts.touchDrawn();
    }

    /** Размер вида в пикселях: контекст, иначе сохранённый/по умолчанию. */
    int[] viewSize(Views_Frame f) {
        int u = f != null && f.unit > 0 ? f.unit : HostWindows.unit;
        int wpx = 0;
        int hpx = 0;
        try {
            if (context != null && u > 0) {
                int[] hh = {0};
                int wu = context.GetSize(hh);
                if (wu > 0 && hh[0] > 0) {
                    wpx = wu / u;
                    hpx = hh[0] / u;
                }
            }
        } catch (Throwable ignored) {
            // контекста нет — берём размер по умолчанию
        }
        if (wpx <= 0) {
            wpx = DEFAULT_W;
        }
        if (hpx <= 0) {
            hpx = DEFAULT_H;
        }
        return new int[]{Math.max(8, wpx), Math.max(8, hpx)};
    }

    /** Заглушка, если GL/WWJ недоступны (headless, нет драйвера). */
    private BufferedImage placeholder(int w, int h) {
        String text = window().error();
        if (text == null) {
            text = "JEarth: карта недоступна";
        }
        if (placeholderText == null || !placeholderText.equals(text)) {
            placeholderText = text;
        }
        BufferedImage img = new BufferedImage(Math.max(8, w), Math.max(8, h),
                BufferedImage.TYPE_INT_RGB);
        Graphics2D g = img.createGraphics();
        try {
            g.setRenderingHint(RenderingHints.KEY_TEXT_ANTIALIASING,
                    RenderingHints.VALUE_TEXT_ANTIALIAS_ON);
            g.setColor(new Color(0xD8, 0xDC, 0xE0));
            g.fillRect(0, 0, w, h);
            g.setColor(new Color(0x80, 0x86, 0x8C));
            g.drawRect(0, 0, w - 1, h - 1);
            g.setFont(new Font(Font.SANS_SERIF, Font.PLAIN, 12));
            g.setColor(new Color(0x40, 0x44, 0x48));
            g.drawString(text, 8, Math.min(h - 8, 20));
            g.setColor(new Color(0x60, 0x64, 0x68));
            g.drawString("(нужен OpenGL: JOGL в JEarth/Lib)", 8,
                    Math.min(h - 8, 38));
        } finally {
            g.dispose();
        }
        return img;
    }

    // --------------------------------------------------------- взаимодействие

    @Override
    public Views_View HandleCtrlMsg(Views_Frame f, CP.Views.Views_CtrlMessage msg,
                                    Views_View focus) {
        if (f != null && msg instanceof Controllers_TrackMsg) {
            // Кнопка нажата: тянем карту, пока её не отпустят.
            if (drag(f)) {
                return this;
            }
        }
        if (msg instanceof Controllers_WheelMsg) {
            wheel((Controllers_WheelMsg) msg);
            return this;
        }
        if (msg instanceof Controllers_PollCursorMsg) {
            ((Controllers_PollCursorMsg) msg).cursor = CURSOR_HAND;
        }
        return super.HandleCtrlMsg(f, msg, focus);
    }

    /**
     * Модальный цикл перетаскивания (как `Ctrls.Track`): каждый шаг —
     * `f.Input`, сдвиг камеры на дельту, немедленная перерисовка вида.
     *
     * <p>Перерисовка — только {@code Views.keepFrames}: {@code rebuildFrames}
     * (см. {@code Views.ValidateRoot}) закрывает дочерние кадры документа и
     * создаёт их заново, а закрытый кадр — это {@code rider = NIL}
     * ({@code Views.Close} → {@code ConnectTo(NIL)}). Следующий
     * {@code f.Input} в цикле трекера падал с TRAP 201
     * («because "f.rider" is null»). Для растра пересборка кадров не нужна
     * никогда — так делают и оригинальные виды ({@code Views.Update(v,
     * Views.keepFrames)}).</p>
     *
     * <p>Второй рубеж: кадр может быть закрыт и по другой причине (окно
     * закрыли во время перетаскивания). Тогда трекер просто завершается, а
     * не трапает.</p>
     *
     * @return {@code true}, если перетаскивание состоялось
     */
    private boolean drag(Views_Frame f) {
        if (f == null || f.rider == null) {
            return false;                       // кадра/порта уже нет
        }
        // `Ports.Frame.Input` отдаёт координаты в единицах кадра
        // (`x * unit - f.gx`), а `EarthWindow.drag` считает метры на
        // *пиксель*. Без пересчёта карта улетала на полюс за пару пикселей.
        int unit = f.unit > 0 ? f.unit : (HostWindows.unit > 0 ? HostWindows.unit : 1);
        int[] y = new int[1];
        int[] mods = new int[1];
        boolean[] down = new boolean[1];
        int px = f.Input(y, mods, down);
        int py = y[0];
        if (!down[0]) {
            return false;                       // это был не драг, а клик
        }
        EarthWindow win = window();
        boolean moved = false;
        int remX = 0;                           // остаток меньше пикселя
        int remY = 0;
        while (down[0]) {
            if (f.rider == null) {
                break;                          // кадр закрыт (окно ушло)
            }
            int nx = f.Input(y, mods, down);
            int ny = y[0];
            remX += nx - px;
            remY += ny - py;
            px = nx;
            py = ny;
            int dx = remX / unit;
            int dy = remY / unit;
            remX -= dx * unit;
            remY -= dy * unit;
            if (dx != 0 || dy != 0) {
                win.drag(dx, dy);
                moved = true;
                Views.Update(this, false);      // keepFrames: кадр не пересобирать
            }
        }
        if (!moved) {
            Views.Update(this, false);
        }
        return true;
    }

    /** Колесо: вверх — ближе, вниз — дальше. */
    private void wheel(Controllers_WheelMsg msg) {
        int n = msg.nofLines > 0 ? msg.nofLines : 3;
        boolean closer = msg.op == DEC_LINE || msg.op == DEC_PAGE;
        double factor = Math.pow(ZOOM_STEP, n);
        window().zoom(closer ? factor : 1.0 / factor);
        msg.done = true;
        Views.Update(this, false);              // keepFrames, см. drag()
    }

    // ------------------------------------------------------------- прочее

    @Override
    public Models_Model ThisModel() {
        return null;
    }

    /** Размер окна по умолчанию — просим 640×460 пикселей. */
    @Override
    public void HandlePropMsg(Views_PropMessage msg) {
        if (msg instanceof Properties_SizePref) {
            Properties_SizePref p = (Properties_SizePref) msg;
            int u = HostWindows.unit > 0 ? HostWindows.unit : 1;
            if (p.w <= 0 || p.h <= 0) {
                p.w = DEFAULT_W * u;
                p.h = DEFAULT_H * u;
            }
        }
        super.HandlePropMsg(msg);
    }

    /** Закрыть GL-ресурсы (вызывается при уничтожении вида). */
    void disposeWindow() {
        if (window != null) {
            window.dispose();
            window = null;
        }
    }
}
