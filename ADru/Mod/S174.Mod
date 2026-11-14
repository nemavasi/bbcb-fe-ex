(*  Общие сведения о примерах: Справка *)
(*  Исправления и подготовка примеров: (С) Ф.В.Ткачев, 2009, info21 AT inr.ac.ru *)

MODULE  ADruS174;  (* Примеры из раздела 1.7.4. *)

	IMPORT  Log := StdLog,  In := i21sysIn,  Texts := ADruS174_Texts;
	
	PROCEDURE Read ( OUT ch: CHAR );
	BEGIN
		In.Char( ch );  ASSERT( In.done );
	END Read;

	PROCEDURE Write ( ch: CHAR );
	BEGIN  Log.Char( ch );
	END Write;


	(* преобразование литер в число из разд. 1.7.4: *)
	
	PROCEDURE StringToInt*; 
		VAR  x: INTEGER;  ch: CHAR;
	BEGIN
		(* приготовление ввода: *)
		In.Open;  ASSERT( In.done );  Read( ch );  ASSERT( In.done );
		
		(* фрагмент из книги, с. 47: ************************************)
		x := 0;  Read( ch );
		WHILE ("0" <= ch) & (ch <= "9") DO
			x := 10*x + (ORD(ch) - ORD("0")); Read(ch)
		END;
		(* конец фрагмента ******************************************)
		
		(* проверяем печатью в рабочий журнал: *)
		Log.Int( x );  Log.Ln;
	END StringToInt; 

	
	(* преобразование числа в литеры из разд. 1.7.4: *)
	
	PROCEDURE IntToString*;
		VAR  x, i: INTEGER;  d: ARRAY 11 OF INTEGER;
	BEGIN
		(* ввод числа: *)
		In.Open;  ASSERT( In.done );  In.Int( x );  ASSERT( In.done & ( x >= 0 ));
		
		(* фрагмент из книги, с. 47: ************************************)
		i := 0;
		REPEAT  d[i] := x MOD 10;  x := x DIV 10;  INC( i )
		UNTIL  x = 0;
		REPEAT  DEC( i );  Write( CHR( d[ i ] + ORD("0") ) )
		UNTIL  i = 0;
		(* конец фрагмента ******************************************)
		
		Log.Ln;
	END IntToString; 
	
END  ADruS174.

ADruS174.StringToInt 12345 
ADruS174.IntToString  2345 

Для изменения входных данных поменять числа после команд (или выделить число мышкой) -- при клике прочтутся новые данные.
Число здесь должно быть целым, без точки.

