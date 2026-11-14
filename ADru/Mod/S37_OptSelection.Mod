(*  Общие сведения о примерах: Справка *)
(*  Исправления и подготовка примеров: (С) Ф.В.Ткачев, 2009, info21 AT inr.ac.ru *)

MODULE  ADruS37_OptSelection;  (* Задача об оптимальном выборе, раздел 3.7. *)
	IMPORT  Log := StdLog,  In := i21sysIn,  Math;

	CONST n = 10;
	
	(* фрагмент из текста, с. 163: ***********************************)
	TYPE Object = RECORD value, weight: INTEGER END;
	VAR a: ARRAY n OF Object;
		limw, totv, maxv: INTEGER;
		s, opts: SET;
	
	PROCEDURE LogResult; (* процедура добавлена для печати результатов *)
		VAR  i: INTEGER;
	BEGIN
		FOR  i := 0  TO  n - 1  DO
			Log.Tab;
			IF  i IN opts  THEN  Log.Char('*')  END;
		END;
		Log.Tab;  Log.Int( maxv );  Log.Ln
	END LogResult;
	
	PROCEDURE Try ( i, tw, av: INTEGER ); (* более чистая обработка окончания по сравнению с вариантом в книге *)
		VAR  tw1, av1: INTEGER;
	BEGIN
		IF  i = n  THEN
			ASSERT( tw <= limw );
			(* av = ценность s *)
			IF  av > maxv  THEN
				maxv := av;  opts := s
			END
		ELSE
			(*проверка включения*)
			tw1 := tw + a[ i ].weight; 
			IF  tw1 <= limw  THEN
				s := s + { i };
				Try( i+1, tw1, av );
				s := s - { i }
			END;
			(*проверка исключения*)
			av1 := av - a[ i ].value; 
			IF  av1 > maxv  THEN
				Try( i+1, tw, av1 )
			END
		END;
	END Try;
	
	PROCEDURE Selection ( weightInc, weightLimit: INTEGER );
		VAR  i: INTEGER;
	BEGIN
		limw := 0;
		REPEAT
			limw := limw + weightInc;
			s := {};  opts := {};  maxv := 0;
			Try( 0, 0, totv );
			LogResult;
		UNTIL  limw >= weightLimit
	END Selection;
	(* конец фрагмента *******************************************)
	
	PROCEDURE  Do*; (* команда для вызова *)
		VAR  i, x: INTEGER;
	BEGIN
		In.Open;  ASSERT( In.done );
		FOR  i := 0  TO  n - 1  DO
			In.Int( x );  ASSERT( In.done );
			a[ i ].weight := x;
		END;
		totv := 0;
		FOR  i := 0  TO  n - 1  DO
			In.Int( x );  ASSERT( In.done );
			a[ i ].value := x;
			totv := totv + x
		END;
		
		Selection( 10, 120 )
	END Do;

END ADruS37_OptSelection.


Для вызова кликнуть по черному командиру:

ADruS37_OptSelection.Do
10	11	12	13	14	15	16	17	18	19
18	20	17	19	25	21	27	23	25	24


Для форматирования таблички в рабочем журнале перед выдачей вставить линейку (Ctrl+J) и наставить в ней позиций табуляции, кликая мышкой в нужных местах.
Чтобы спрятать/показать линейку (вместе с серыми прямоугольниками -- это символы табуляции), нажимать Ctrl+H.
Стереть/копировать ее можно как букву.

См. модуль TextRulers, «линейки», .
