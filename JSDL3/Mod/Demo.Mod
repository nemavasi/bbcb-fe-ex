MODULE JSDL3Demo;
(** Пример JSDL3Work (ADR-243, ADR-245): научная поверхность Гаусса в SDL3.

    Переписанный пример `s/sdl2_example.cpp`: вместо SDL2+OpenGL — SDL3
    renderer и Project Panama. Сетка 3D-поверхности проецируется в 2D;
    мышь вращает сцену, закрытие окна завершает пример.

    Нужен SDL3; путь — `-Dblackbox.sdl3.library=...` или автопоиск.
    Соберите `Dev→Compile`, выполните `JSDL3Demo.Run`. *)

  IMPORT JSDL3Work, StdLog, Math;

  CONST
    W = 800; H = 600;
    RANGE = 5.0;
    STEP = 0.5;
    SIGMA = 2.0;
    DEG = 3.14159265358979 / 180.0;

  VAR
    rotationX, rotationY, rotationZ: REAL;
    mouseDown: BOOLEAN;
    lastX, lastY: INTEGER;

  PROCEDURE Z (x, y: REAL): REAL;
  BEGIN
    RETURN Math.Exp(-(x * x + y * y) / (2.0 * SIGMA * SIGMA))
  END Z;

  PROCEDURE Project (x, y, z: REAL; VAR sx, sy: INTEGER);
    VAR sinX, cosX, sinY, cosY, sinZ, cosZ: REAL;
        x1, y1, z1, x2, y2: REAL;
  BEGIN
    Math.SinCos(rotationX * DEG, sinX, cosX);
    Math.SinCos(rotationY * DEG, sinY, cosY);
    Math.SinCos(rotationZ * DEG, sinZ, cosZ);
    x1 := x * cosY + z * sinY;
    z1 := -x * sinY + z * cosY;
    y1 := y * cosX - z1 * sinX;
    z1 := y * sinX + z1 * cosX;
    x2 := x1 * cosZ - y1 * sinZ;
    y2 := x1 * sinZ + y1 * cosZ;
    sx := W DIV 2 + SHORT(ENTIER(x2 * 55.0));
    sy := H DIV 2 - SHORT(ENTIER(y2 * 45.0 + z1 * 80.0))
  END Project;

  PROCEDURE Line (ren: LONGINT; x1, y1, x2, y2, color: INTEGER);
  BEGIN
    IF JSDL3Work.SetRenderDrawColor(ren,
         (color DIV 65536) MOD 256,
         (color DIV 256) MOD 256, color MOD 256, 255) THEN
      IF JSDL3Work.RenderLine(ren, x1, y1, x2, y2) THEN END
    END
  END Line;

  PROCEDURE Run*;
    VAR win, ren: LONGINT; e: JSDL3Work.Event;
        x, y, z, z2, z3: REAL; sx, sy, sx2, sy2, sx3, sy3: INTEGER;
        frames: INTEGER; running: BOOLEAN; r, g, b: INTEGER;
  BEGIN
    rotationX := 45.0; rotationY := 0.0; rotationZ := 45.0;
    mouseDown := FALSE;
    sx := 0; sy := 0; sx2 := 0; sy2 := 0; sx3 := 0; sy3 := 0;
    IF ~JSDL3Work.Init(JSDL3Work.INIT_VIDEO) THEN
      StdLog.String("JSDL3: init failed"); StdLog.Ln; RETURN
    END;
    win := JSDL3Work.CreateWindow("Scientific 3D Surface - SDL3",
                                  W, H, JSDL3Work.WINDOW_RESIZABLE);
    IF win = 0 THEN
      StdLog.String("JSDL3: window failed"); StdLog.Ln;
      JSDL3Work.Quit; RETURN
    END;
    ren := JSDL3Work.CreateRenderer(win);
    IF ren = 0 THEN
      StdLog.String("JSDL3: renderer failed"); StdLog.Ln;
      JSDL3Work.DestroyWindow(win); JSDL3Work.Quit; RETURN
    END;
    running := TRUE; frames := 0;
    WHILE running & (frames < 600) DO
      INC(frames);
      WHILE JSDL3Work.PollEvent(e) DO
        IF e.type = JSDL3Work.EVENT_QUIT THEN
          running := FALSE
        ELSIF e.type = JSDL3Work.EVENT_MOUSE_BUTTON_DOWN THEN
          IF e.button = 1 THEN
            mouseDown := TRUE; lastX := e.x; lastY := e.y
          END
        ELSIF e.type = JSDL3Work.EVENT_MOUSE_BUTTON_UP THEN
          IF e.button = 1 THEN mouseDown := FALSE END
        ELSIF (e.type = JSDL3Work.EVENT_MOUSE_MOTION) & mouseDown THEN
          rotationZ := rotationZ + (e.x - lastX) * 0.5;
          rotationX := rotationX + (e.y - lastY) * 0.5;
          lastX := e.x; lastY := e.y
        END
      END;
      IF JSDL3Work.SetRenderDrawColor(ren, 13, 13, 26, 255) THEN
        IF JSDL3Work.RenderClear(ren) THEN END
      END;
      x := -RANGE;
      WHILE x < RANGE DO
        y := -RANGE;
        WHILE y < RANGE DO
          z := Z(x, y);
          z2 := Z(x + STEP, y);
          z3 := Z(x, y + STEP);
          Project(x, y, z, sx, sy);
          Project(x + STEP, y, z2, sx2, sy2);
          Project(x, y + STEP, z3, sx3, sy3);
          r := SHORT(ENTIER(z * 255.0));
          b := 255 - r; g := 60;
          Line(ren, sx, sy, sx2, sy2, r * 65536 + g * 256 + b);
          Line(ren, sx, sy, sx3, sy3, r * 65536 + g * 256 + b);
          y := y + STEP
        END;
        x := x + STEP
      END;
      (* оси *)
      Project(-RANGE, 0, 0, sx, sy); Project(RANGE, 0, 0, sx2, sy2);
      Line(ren, sx, sy, sx2, sy2, 0FF0000H);
      Project(0, -RANGE, 0, sx, sy); Project(0, RANGE, 0, sx2, sy2);
      Line(ren, sx, sy, sx2, sy2, 000FF00H);
      Project(0, 0, -RANGE, sx, sy); Project(0, 0, RANGE, sx2, sy2);
      Line(ren, sx, sy, sx2, sy2, 00000FFH);
      IF JSDL3Work.RenderPresent(ren) THEN END;
      JSDL3Work.Delay(16)
    END;
    JSDL3Work.DestroyRenderer(ren);
    JSDL3Work.DestroyWindow(win);
    JSDL3Work.Quit
  END Run;

END JSDL3Demo.
