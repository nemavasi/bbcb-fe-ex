(*  Общие сведения о примерах: Справка *)
(*  Исправления и подготовка примеров: (С) Ф.В.Ткачев, 2009, info21 AT inr.ac.ru *)

MODULE  ADruS34_KnightsTour;  (* Задача о путешествии коня, раздел 3.4. *)

	IMPORT  Log := StdLog,  In := i21sysIn,  Math;
	
	VAR
		n, nsqr: INTEGER;
	
	(* фрагмент из книги, с. 146: **********************************)
	VAR
		h: POINTER TO ARRAY OF ARRAY (* n, n *) OF INTEGER;
		dx, dy: ARRAY 8 OF INTEGER;
	
	PROCEDURE^ TryNextMove( x, y, i: INTEGER; OUT done: BOOLEAN );
	
	PROCEDURE CanBeDone ( u, v, i: INTEGER ): BOOLEAN;
		VAR  done: BOOLEAN;
	BEGIN
		h[u, v] := i;
		TryNextMove( u, v, i, done );
		IF ~done THEN h[u, v] := 0 END;
		RETURN  done
	END CanBeDone;
	
	PROCEDURE TryNextMove ( x, y, i: INTEGER; OUT done: BOOLEAN );
		VAR  eos: BOOLEAN;  u, v: INTEGER;  k: INTEGER;

		PROCEDURE Next ( OUT eos: BOOLEAN;  OUT u, v: INTEGER );
		BEGIN
			REPEAT
				INC(k);
				IF k < 8 THEN  u := x + dx[k]; v := y + dy[k]  END;
			UNTIL (k = 8) OR ((0 <= u) & (u < n) & (0 <= v) & (v < n) & (h[u, v] = 0));
			eos := (k = 8)
		END Next;

		PROCEDURE First ( OUT eos: BOOLEAN;  OUT u, v: INTEGER );
		BEGIN
			eos := FALSE;  k := -1;  Next( eos, u, v )
		END First;

	BEGIN
		IF i < nsqr THEN
			First( eos, u, v );
			WHILE ~eos & ~CanBeDone( u, v, i+1 ) DO
				Next( eos, u, v )
			END;
			done := ~eos
		ELSE
			done := TRUE
		END;
	END TryNextMove;

	PROCEDURE Clear;
		VAR i, j: INTEGER;
	BEGIN
		FOR i := 0 TO n-1 DO
			FOR j := 0 TO n-1 DO h[i,j] := 0 END
		END
	END Clear;

	PROCEDURE KnightsTour ( x0, y0: INTEGER; OUT done: BOOLEAN ); 
	BEGIN  Clear;  h[x0,y0] := 1;  TryNextMove( x0, y0, 1, done );
	END KnightsTour;

	(* конец фрагмента *******************************************)


	PROCEDURE Do*;  (* тестирующая команда (процедура-драйвер) *)
		VAR  x0, y0: INTEGER;  done: BOOLEAN;  i, j: INTEGER;
	BEGIN
		In.Open;  ASSERT( In.done );
		In.Int( n );  ASSERT( In.done & ( n >= 1 ) );
		nsqr := n*n;
		In.Int( x0 );  ASSERT( In.done & ( 0 <= x0 ) & ( x0 < n ) ); 
		In.Int( y0 );  ASSERT( In.done & ( 0 <= y0 ) & ( y0 < n ) ); 
		
		NEW( h, n, n );
		Clear;
		KnightsTour( x0, y0, done );
		
		Log.Bool( done );  Log.Ln;
		IF  done  THEN
			FOR  i := 0  TO  n-1  DO
				FOR  j := 0  TO  n-1  DO
					Log.Tab;  Log.Int( h[i,j] );
				END;
				Log.Ln;
			END;
		END;
	END Do;
	
BEGIN
	(* dx  :=  (2, 1, -1, -2, -2, -1, 1, 2) *)
	(* dy  :=  (1, 2, 2, 1, -1, -2, -2, -1) *)
	dx[0] := 2;	dx[1] := 1;	dx[2] := -1;	dx[3] := -2;
	dy[0] := 1;	dy[1] := 2;	dy[2] := 2;	dy[3] := 1;
	
	dx[4] := -2;	dx[5] := -1;	dx[6] := 1;	dx[7] := 2;
	dy[4] := -1;	dy[5] := -2;	dy[6] := -2;	dy[7] := -1;

END  ADruS34_KnightsTour.

Выделить мышкой нужную тройку чисел (размер доски, координаты стартовой позиции коня) и кликнуть по черному командиру:

ADruS34_KnightsTour.Do 
5 2 2 ~ 
5 1 3 ~ 
6 0 0 ~

Для форматирования таблички в рабочем журнале перед выдачей вставить линейку (Ctrl+J) и наставить в ней позиций табуляции, кликая мышкой в нужных местах.
Чтобы спрятать/показать линейку (вместе с серыми прямоугольниками -- это символы табуляции), нажимать Ctrl+H.
Стереть/копировать ее можно как букву.

См. модуль TextRulers, «линейки».