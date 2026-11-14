(*  Общие сведения о примерах: Справка *)
(*  Исправления и подготовка примеров: (С) Ф.В.Ткачев, 2009, info21 AT inr.ac.ru *)

MODULE  ADruS183;
(* К разделу 1.8.3 о поиске в таблице. *)
	IMPORT  Log := StdLog,  In := i21sysIn,  Math;
	
	PROCEDURE Do*;
		CONST  M = 100;  N = 10;
		TYPE  String = ARRAY M OF CHAR;
		VAR
			T: ARRAY N OF String;
			x: String;
		VAR  i, L, R, m: INTEGER;
	BEGIN
		(*ввод аргумента поиска и таблицы: *)
		In.Open;	ASSERT( In.done );
		In.String( x );	ASSERT( In.done );
		FOR  i := 0  TO  N-1  DO  In.String( T[i] ); ASSERT( In.done )  END;
		(* фрагмент из книги, с. 54: ************************************)
		L := 0;  R := N;
		WHILE  L < R  DO
			m := (L+R) DIV 2;
			i := 0;
			WHILE ( x[i] # 0X ) & ( T[m, i] = x[i] ) DO  i := i+1  END;
			IF  T[m, i] < x[i]  THEN  L := m+1  ELSE  R := m  END
		END;
		IF  R < N  THEN
			i := 0;
			WHILE ( x[i] # 0X ) & ( T[R, i] = x[i] ) DO  i := i+1  END
		END;
		(* ( R < N ) & ( T[R,i] = x[i] ) устанавливает совпадение *)
		(* конец фрагмента ******************************************)
		
		Log.Int( R );  Log.Tab;  Log.String( T[R] );  Log.Ln;		
	END Do;
	
END  ADruS183.

можно менять аргумент поиска (искомое значени; это первая вводимая цепочка литер, стоящая в строке командира) и снова кликать:

ADruS183.Do  "Единая"
"Оберон"
"—"
"замечательный язык"
"программирования"
"."
" "
"Единая"
"система"
"вводных"
"курсов"
"информатики"
"на основе"
"Оберонов."
