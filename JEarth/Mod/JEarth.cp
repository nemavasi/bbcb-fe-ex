(** JEarth — платформенный модуль (ADR-010, ADR-265, ADR-266): карта Земли
    на NASA World Wind Java.

    Зачем: BBCB должен уметь показывать карту планеты в окне документа, с
    прокруткой мышью и увеличением/уменьшением — без платформенного кода в
    CP-программе.

    Устройство: интерфейс — этот модуль (`gpcp -special`), тело — Java
    (`CP.JEarth.*`). WWJ рисует кадр в память (offscreen OpenGL через
    JOGL), вид `EarthView` отдаёт готовый растр в кадр BBCB. Поэтому ни
    Swing, ни classpath в CP-коде не нужны:

      VAR v: JEarth.EarthView;
      v := JEarth.New();
      JEarth.SetPosition(v, 45.0, 10.0, 3000000.0);   (* Альпы *)
      Views.OpenAux(v, "Земля")

    Камера задаётся широтой/долготой в градусах и высотой в метрах.
    `SetImagery` переключает слой: NASA Blue Marble (по умолчанию, public
    domain), OpenStreetMap (ODbL, включается явно) или NASA Landsat.

    Если OpenGL на машине недоступен, вид показывает заглушку, а причина
    лежит в `lastError` (карта не «роняет» приложение). `RenderFile` —
    headless-рендер в PNG для тестов и экспорта.

    Зависимости — `JEarth/Lib` (`WorldWindJava.jar`, JOGL/GlueGen и их
    нативные библиотеки внутри jar). Лицензии — `JEarth/LICENSES`. *)
SYSTEM MODULE JEarth;

  IMPORT Views;

  CONST
    (** NASA Blue Marble (WMS, public domain). *)
    BlueMarble* = 0;
    (** OpenStreetMap Mapnik (ODbL: нужна атрибуция). *)
    OpenStreetMap* = 1;
    (** NASA Landsat (WMS, public domain). *)
    Landsat* = 2;

    (** Цвета маркеров: `0xRRGGBB`. *)
    red* = 0FF0000H;
    green* = 0008000H;
    blue* = 00000FFH;
    yellow* = 0FFFF00H;

  TYPE
    (** Вид карты. Полей нет: состояние живёт в Java-теле
        `CP.JEarth.JEarth_EarthView` (как `HostPictures.StdView`). *)
    EarthView* = POINTER TO RECORD (Views.View) END;

  VAR
    (** Текст последней ошибки; пусто — ошибки нет. *)
    lastError*: ARRAY 256 OF CHAR;

  (** Новый вид карты (без окна). *)
  PROCEDURE New* (): EarthView;

  (** Открыть карту в новом окне документа. *)
  PROCEDURE Open* (title: ARRAY OF CHAR; lat, lon, altitude: REAL);

  (** Камера: широта/долгота в градусах, высота в метрах. *)
  PROCEDURE SetPosition* (v: EarthView; lat, lon, altitude: REAL);

  (** Прочитать камеру. *)
  PROCEDURE GetPosition* (v: EarthView; VAR lat, lon, altitude: REAL);

  (** Зум: `factor > 1` — ближе, `< 1` — дальше. *)
  PROCEDURE Zoom* (v: EarthView; factor: REAL);

  (** Сдвиг центра карты на `dLat`/`dLon` градусов. *)
  PROCEDURE Pan* (v: EarthView; dLat, dLon: REAL);

  (** Источник изображения: `BlueMarble` / `OpenStreetMap` / `Landsat`. *)
  PROCEDURE SetImagery* (v: EarthView; source: INTEGER);

  (** Поставить точку на карте: широта/долгота в градусах, цвет
      `0xRRGGBB` (см. `red`, `green`, `blue`). *)
  PROCEDURE AddMarker* (v: EarthView; lat, lon: REAL; color: INTEGER);

  (** Убрать все точки. *)
  PROCEDURE ClearMarkers* (v: EarthView);

  (** Сколько точек на карте. *)
  PROCEDURE MarkerCount* (v: EarthView): INTEGER;

  (** Перерисовать вид. *)
  PROCEDURE Update* (v: EarthView);

  (** Снимок вида в PNG. *)
  PROCEDURE Snapshot* (v: EarthView; IN path: ARRAY OF CHAR): BOOLEAN;

  (** Рендер без окна в `JEarth/Rsrc/Cache/demo.png` (для смоука и меню). *)
  PROCEDURE RenderToCache* (): BOOLEAN;

  (** Headless-рендер в PNG (без окна и документа) — для тестов/экспорта. *)
  PROCEDURE RenderFile* (IN path: ARRAY OF CHAR; w, h: INTEGER;
                         lat, lon, altitude: REAL): BOOLEAN;

  (** Напечатать `lastError` в окно `Log`. *)
  PROCEDURE LogError*;

  (** Рисование вида в кадр (тело — `CP.JEarth.JEarth_EarthView`). *)
  PROCEDURE (v: EarthView) Restore* (f: Views.Frame; l, t, r, b: INTEGER);

END JEarth.
