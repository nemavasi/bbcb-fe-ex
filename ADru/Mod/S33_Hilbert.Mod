(*  Общие сведения о примерах: Справка *)
(*  Исправления и подготовка примеров: (С) Ф.В.Ткачев, 2009, info21 AT inr.ac.ru *)

MODULE  ADruS33_Hilbert;
(* Рисование гильбертовых кривых из раздела 3.3. *)
	IMPORT  Draw := ADruS33_Draw;
	CONST  right = 0;  up = 2;  left = 4;  down = 6;
	
	(* фрагмент из книги, с. 138 *************************************)
	VAR  u: INTEGER;
			(* необходимые упреждающие определения, отсутствующие в книге: *)
			PROCEDURE^ B ( i: INTEGER ); 
			PROCEDURE^ C ( i: INTEGER );
			PROCEDURE^ D ( i: INTEGER );
	
	PROCEDURE A ( i: INTEGER );
	BEGIN
		IF  i > 0  THEN
			D( i - 1 );  Draw.line( left, u );
			A( i - 1 );  Draw.line( down, u );
			A( i - 1 );  Draw.line( right, u );
			B( i - 1 )
		END
	END A;
	
	PROCEDURE B ( i: INTEGER );
	BEGIN
		IF  i > 0  THEN
			C( i - 1 );  Draw.line( up, u );
			B( i - 1 );  Draw.line( right, u );
			B( i - 1 );  Draw.line( down, u );
			A( i - 1 )
		END
	END B;
	
	PROCEDURE C ( i: INTEGER );
	BEGIN
		IF  i > 0  THEN
			B( i - 1 );  Draw.line( right, u );
			C( i - 1 );  Draw.line( up, u );
			C( i - 1 );  Draw.line( left, u );
			D( i - 1 )
		END 
	END C;
	
	PROCEDURE D ( i: INTEGER );
	BEGIN
		IF  i > 0  THEN
			A( i - 1 );  Draw.line( down, u );
			D( i - 1 );  Draw.line( left, u );
			D( i - 1 );  Draw.line( up, u );
			C( i - 1 )
		END
	END D;
	
	PROCEDURE Hilbert* ( n: INTEGER );
		CONST  SquareSize = 512;
		VAR  i, x0, y0: INTEGER;
	BEGIN
		Draw.Clear;
		x0 := Draw.width DIV 2;  y0 := Draw.height DIV 2;
		u := SquareSize;
		i := 0;
		REPEAT
			INC( i );
			u := u DIV 2;
			x0 := x0 + (u DIV 2);  y0 := y0 + (u DIV 2);  Draw.SetPen( x0, y0 );
			A( i )
		UNTIL  i = n
	END Hilbert;
	
	(* конец фрагмента *******************************************)
	
END  ADruS33_Hilbert. 

При клике по одному из нижеприведенных командиров в отдельном окошке рисуется гильбетрова кривая соответствующего порядка.
При повторных кликах рисунок перерисовывается в том же окошке:

"ADruS33_Hilbert.Hilbert(1)"
"ADruS33_Hilbert.Hilbert(2)"
"ADruS33_Hilbert.Hilbert(3)"
"ADruS33_Hilbert.Hilbert(4)"
"ADruS33_Hilbert.Hilbert(5)"
"ADruS33_Hilbert.Hilbert(6)"
"ADruS33_Hilbert.Hilbert(7)"

Если окошко с рисунком случайно закрылось, кликнуть сюда:

DevDebug.UnloadThis  ADruS33_Hilbert ADruS33_Sierpinski ADruS33_Draw

Для копирования получившихся картинок в текст (см. такую копию ниже): 
	отрегулировать размер окна, Ctrl+Space, Ctrl+C, 
в тексте, куда надо вставить картинку: 
	Edit, Paste Special..., выбрать Picture (Metafile).



