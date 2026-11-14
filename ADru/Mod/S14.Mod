(*  Общие сведения о примерах: Справка *)
(*  Исправления и подготовка примеров: (С) Ф.В.Ткачев, 2009, info21 AT inr.ac.ru *)

MODULE  ADruS14;  (* Примеры из раздела 1.4. *)

	IMPORT  Log := StdLog,  In := i21sysIn,  Texts := ADruS174_Texts;
	
	PROCEDURE For*;
		CONST  N = 100;
		VAR a: ARRAY N OF INTEGER;
			sum, max, i, k: INTEGER;
	BEGIN
		FOR  i := 0  TO  N - 1  DO
			a[ i ] := 10*i - i*i
		END;
		
		(* фрагмент из книги, с.28: ************************************)
		sum := 0;
		FOR i := 0 TO N-1 DO  sum := a[i] + sum  END;
		k := 0;  max := a[0];
		FOR i := 1 TO N-1 DO
			IF  max < a[i]  THEN  k := i;  max := a[k]  END;
		END;
		(* конец фрагмента ******************************************)
		
		(* вывод в рабочий журнал: *)
		Log.Int( sum );  Log.Ln;
		Log.Int( k );  Log.Int( max );  Log.Ln;
	END For;
(* коммандер для выполнения команды можно вставить прямо в тексте программы, заключив его в комментарий: ADruS14.For *)
	
	
	(* фрагмент из книги, с.29: *************************************)

	PROCEDURE Power ( VAR W: Texts.Writer;  N: INTEGER );
		(* вычислить десятичное представление отрицательных степеней числа 2 *)
		VAR i, k, r: INTEGER;
			d: POINTER TO ARRAY OF INTEGER;
	BEGIN
		NEW( d, N );
		
		FOR k := 0 TO N-1 DO
			Texts.Write(W, "."); r := 0;
			FOR i := 0 TO k-1 DO
				r := 10*r + d[i]; d[i] := r DIV 2; r := r MOD 2;
				Texts.Write(W, CHR(d[i] + ORD("0")))
			END;
			d[k] := 5; Texts.Write(W, "5"); Texts.WriteLn(W)
		END
	END Power;

	(* конец фрагмента *******************************************)
	
	PROCEDURE DoPower*; (* управляющая процедура для Power *)
		VAR  w: Texts.Writer;  N: INTEGER;
	BEGIN
		(* ввод N: *)
		In.Open;  In.Int( N );  ASSERT( In.done & ( N > 0 ) );
		
		(* подготовка w к печати в рабочий журнал (Log): *)
		Texts.OpenWriter( w, Texts.log, Texts.Length( Texts.log ) );
		
		Power( w, N );
		
	END DoPower;

END  ADruS14.

 ADruS14.For 

 ADruS14.DoPower 10