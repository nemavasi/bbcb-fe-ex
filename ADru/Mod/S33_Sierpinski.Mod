(*  Общие сведения о примерах: Справка *)
(*  Исправления и подготовка примеров: (С) Ф.В.Ткачев, 2009, info21 AT inr.ac.ru *)

MODULE  ADruS33_Sierpinski;  (* Рисование кривых Серпиньского, раздел 3.3. *)

	IMPORT  Log := StdLog,  Math,  Draw := ADruS33_Draw;
	
	CONST  east = 0;  north = 2;  west = 4;  south = 6;  (*east = восток и т.д.*)
		northEast = 1;  northWest = 3;  southWest = 5;  southEast = 7;  (*northEast = северо-восток и т.д.*)

	(* фрагмент из книги, с. 141 ************************************)	
	VAR  h: INTEGER;
			(* необходимые упреждающие определения, отсутствующие в книге: *)
			PROCEDURE^ B ( k: INTEGER );
			PROCEDURE^ C ( k: INTEGER );
			PROCEDURE^ D ( k: INTEGER );
	
	PROCEDURE A ( k: INTEGER );
	BEGIN
		IF  k > 0  THEN
			A( k - 1 );  Draw.line( southEast, h );
			B( k - 1 );  Draw.line( east, 2*h );
			D( k - 1 );  Draw.line( northEast, h );
			A( k - 1 )
		END
	END A;
	
	PROCEDURE B ( k: INTEGER );
	BEGIN
		IF  k > 0  THEN
			B( k - 1 );  Draw.line( southWest, h );
			C( k - 1 );  Draw.line( south, 2*h );
			A( k - 1 );  Draw.line( southEast, h );
			B( k - 1 )
		END
	END B;
	
	PROCEDURE C ( k: INTEGER );
	BEGIN
		IF  k > 0  THEN
			C( k - 1 );  Draw.line( northWest, h );
			D( k - 1 );  Draw.line( west, 2*h );
			B( k - 1 );  Draw.line( southWest, h );
			C( k - 1)
		END
	END C;
	
	PROCEDURE D ( k: INTEGER );
	BEGIN
		IF  k > 0  THEN
			D( k - 1 );  Draw.line( northEast, h );
			A( k - 1 );  Draw.line( north, 2*h );
			C( k - 1 );  Draw.line( northWest, h );
			D( k - 1 )
		END
	END D;
	
	PROCEDURE Sn* ( n: INTEGER );
		CONST  SquareSize = 256;
		VAR  i, x0, y0: INTEGER;
	BEGIN
		Draw.Clear;
		h := SquareSize DIV ASH( 2, n );
		x0 := 2 * h DIV 3;  y0 := Draw.width - x0;
		h := h DIV 2;  y0 := y0 + h;  Draw.SetPen( x0, y0 );
		A( n );  Draw.NextThick;  Draw.line( southEast, h );
		B( n );  Draw.NextThick;  Draw.line( southWest, h );
		C( n );  Draw.NextThick;  Draw.line( northWest, h );
		D( n );  Draw.NextThick;  Draw.line( northEast, h );
	END Sn;

	PROCEDURE Sierpinski* ( n: INTEGER );
		CONST  SquareSize = 256;
		VAR  i, x0, y0: INTEGER;
	BEGIN
		Draw.Clear;
		h := SquareSize DIV 2;
		x0 := 2*h;  y0 := Draw.width - h;
		i := 0;
		REPEAT
			INC( i );  x0 := x0 - h;
			h := h DIV 2;  y0 := y0 + h;  Draw.SetPen( x0, y0 );
			A( i );  Draw.line( southEast, h );
			B( i );  Draw.line( southWest, h );
			C( i );  Draw.line( northWest, h );
			D( i );  Draw.line( northEast, h )
		UNTIL  i = n
	END Sierpinski;
	
	(* конец фрагмента *****************************************)

END  ADruS33_Sierpinski.

При клике по одному из нижеприведенных командиров в отдельном окошке рисуется кривая Серпиньского соответствующего порядка.
При повторных кликах рисунок перерисовывается в том же окошке:

Если окошко с рисунком случайно закрылось, прежде чем пытаться нарисовать его снова, кликнуть сюда:
DevDebug.UnloadThis  ADruS33_Hilbert ADruS33_Sierpinski ADruS33_Draw

"ADruS33_Sierpinski.Sierpinski(1)"
"ADruS33_Sierpinski.Sierpinski(2)"
"ADruS33_Sierpinski.Sierpinski(3)"
"ADruS33_Sierpinski.Sierpinski(4)"
"ADruS33_Sierpinski.Sierpinski(5)"
"ADruS33_Sierpinski.Sierpinski(6)"

Отдельные кривые:
"ADruS33_Sierpinski.Sn(1)"
"ADruS33_Sierpinski.Sn(2)"
"ADruS33_Sierpinski.Sn(3)"
"ADruS33_Sierpinski.Sn(4)"
"ADruS33_Sierpinski.Sn(5)"
"ADruS33_Sierpinski.Sn(6)"

Для копирования получившихся картинок в текст (см. такую копию ниже): 
	отрегулировать размер окна, Ctrl+Space, Ctrl+C, 
в тексте, куда надо вставить картинку: 
	Edit, Paste Special..., выбрать Picture (Metafile).




