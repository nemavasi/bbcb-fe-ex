(** JSDL3Work — платформенный модуль (ADR-243): официальный SDL3 через
    Project Panama (`java.lang.foreign`, JDK 25).

    Модуль — тонкая оболочка над C API SDL3. Нативные указатели
    (`SDL_Window*`, `SDL_Renderer*`) передаются как `LONGINT` (адрес);
    события — записью `Event`.

    Библиотека не входит в поставку: нужен установленный SDL3
    (`libSDL3.so.0`/`SDL3.dll`/`libSDL3.dylib`); путь можно задать
    `-Dblackbox.sdl3.library=/path/to/libSDL3.so`.

    Пример: `JSDL3Demo` (`JSDL3/Mod/Demo.Mod`) — окно и цветные кадры.
    *)
SYSTEM MODULE JSDL3Work;

  CONST
    (** Флаги `SDL_Init`. *)
    INIT_AUDIO*   = 00000010H;
    INIT_VIDEO*   = 00000020H;
    INIT_JOYSTICK* = 00000200H;
    INIT_EVENTS*  = 00004000H;
    INIT_SENSOR*  = 00008000H;
    INIT_CAMERA*  = 00010000H;

    (** Типы событий SDL3. *)
    EVENT_QUIT*     = 00100H;
    EVENT_KEY_DOWN* = 00300H;
    EVENT_KEY_UP*   = 00301H;
    EVENT_MOUSE_MOTION*      = 00400H;
    EVENT_MOUSE_BUTTON_DOWN* = 00401H;
    EVENT_MOUSE_BUTTON_UP*   = 00402H;

    (** Флаги окна. *)
    WINDOW_FULLSCREEN* = 0000001H;
    WINDOW_HIDDEN*     = 0000008H;
    WINDOW_BORDERLESS* = 0000010H;
    WINDOW_RESIZABLE*  = 0000020H;

  TYPE
    (** Событие SDL3 (подмножество для клавиатуры/выхода). *)
    Event* = RECORD
      type*:     INTEGER;  (** EVENT_… *)
      key*:      INTEGER;  (** SDL_Keycode *)
      scancode*: INTEGER;  (** SDL_Scancode *)
      down*:     BOOLEAN;  (** TRUE для нажатия *)
      x*, y*:    INTEGER;  (** координаты мыши *)
      button*:   INTEGER;  (** кнопка мыши *)
    END;

  (** Инициализировать подсистемы SDL3. *)
  PROCEDURE Init* (flags: INTEGER): BOOLEAN;

  (** Завершить SDL3. *)
  PROCEDURE Quit*;

  (** Последняя ошибка SDL3 (UTF-8). *)
  PROCEDURE GetError* (VAR msg: ARRAY OF CHAR);

  (** Числовая версия SDL3 (`SDL_VERSIONNUM`). *)
  PROCEDURE Version* (): INTEGER;

  (** Создать окно; возвращает адрес `SDL_Window*` или 0. *)
  PROCEDURE CreateWindow* (title: ARRAY OF CHAR; w, h: INTEGER;
                           flags: LONGINT): LONGINT;

  (** Уничтожить окно. *)
  PROCEDURE DestroyWindow* (window: LONGINT);

  (** Создать renderer для окна; возвращает адрес `SDL_Renderer*` или 0. *)
  PROCEDURE CreateRenderer* (window: LONGINT): LONGINT;

  (** Уничтожить renderer. *)
  PROCEDURE DestroyRenderer* (renderer: LONGINT);

  (** Установить цвет очистки (0..255). *)
  PROCEDURE SetRenderDrawColor* (renderer: LONGINT;
                                 red, green, blue, alpha: INTEGER): BOOLEAN;

  (** Очистить кадр. *)
  PROCEDURE RenderClear* (renderer: LONGINT): BOOLEAN;

  (** Показать кадр. *)
  PROCEDURE RenderPresent* (renderer: LONGINT): BOOLEAN;

  (** Нарисовать линию (координаты в пикселях). *)
  PROCEDURE RenderLine* (renderer: LONGINT;
                         x1, y1, x2, y2: INTEGER): BOOLEAN;

  (** Забрать одно событие из очереди (не блокирует). *)
  PROCEDURE PollEvent* (VAR event: Event): BOOLEAN;

  (** Задержка, мс. *)
  PROCEDURE Delay* (milliseconds: INTEGER);

END JSDL3Work.
