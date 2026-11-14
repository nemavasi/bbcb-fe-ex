(*  Общие сведения о примерах: Справка *)
(*  Исправления и подготовка примеров: (С) Ф.В.Ткачев, 2009, info21 AT inr.ac.ru *)

MODULE  ADruS35_Queens;  (* Задача о восьми ферзях, раздел 3.5. *)
	IMPORT  Texts := ADruS174_Texts,  Log := StdLog;
	VAR  x: ARRAY 8 OF INTEGER;
		a: ARRAY 8 OF BOOLEAN;
		b, c: ARRAY 15 OF BOOLEAN;
		m: INTEGER;
	VAR  W: Texts.Writer;
	
	PROCEDURE LogQueens;  (* дополнительная выдача; для выравнивания вставить руками в рабочем журнале линейку с соотв. табуляцией: *)
		VAR  i, j: INTEGER;
	BEGIN
		Log.Ln;
		FOR  j := 0  TO  7  DO (* строки *)
			Log.Int( j );
			FOR  i := 0  TO  7  DO
				Log.Tab;
				IF  x[ i ] = j  THEN  Log.Char('Q')  ELSE  Log.Char('-')  END;
			END;
			Log.Ln
		END;
		FOR  i := 0  TO  7  DO
			Log.Tab;  Log.Char( CHR( i+ORD('0') ) );
		END;
		Log.Ln;  Log.Ln;
		Texts.OpenWriter( W, Texts.log, Texts.Length( Texts.log ) );
	END LogQueens;
	
	PROCEDURE^ CanBeDone ( i, j: INTEGER ): BOOLEAN; 

	(* начало фрагмента из книги, с. 151: *****************************)
	
	PROCEDURE Try ( i: INTEGER; OUT done: BOOLEAN );
		VAR  eos: BOOLEAN;  j: INTEGER;

		PROCEDURE Next;
		BEGIN
			REPEAT
				INC( j );
			UNTIL (j = 8) OR (a[j] & b[i+j] & c[i-j+7]);
			eos := (j = 8)
		END Next;

		PROCEDURE First;
		BEGIN
			eos := FALSE;  j := -1;  Next
		END First;

	BEGIN
		IF i < 8 THEN
			First;
			WHILE ~eos & ~CanBeDone( i, j ) DO
				Next
			END;
			done := ~eos
		ELSE
			done := TRUE
		END
	END Try;
 
	PROCEDURE CanBeDone ( i, j: INTEGER ): BOOLEAN; 
	(*решение можно достроить, поставив i-го ферзя в j-ю строку*)
		VAR done: BOOLEAN;
	BEGIN
		x[i] := j; a[j] := FALSE; b[i+j] := FALSE; c[i-j+7] := FALSE;
		Try( i+1, done );
		IF ~done THEN
			x[i] := -1; a[j] := TRUE; b[i+j] := TRUE; c[i-j+7] := TRUE
		END;
		RETURN  done
	END CanBeDone;

	PROCEDURE Queens*;
		VAR  done: BOOLEAN;  i, j: INTEGER;  (*печать в глобальный W*)
	BEGIN
		FOR i := 0 TO   7 DO  a[ i ] := TRUE;  x[ i ] := -1  END;
		FOR i := 0 TO 14 DO  b[ i ] := TRUE;  c[ i ] := TRUE  END;
		
		Try( 0, done );  ASSERT( done );
		IF  done  THEN
			FOR i := 0 TO 7 DO Texts.WriteInt( W, x[ i ], 4 ) END;
			Texts.WriteLn( W );
			LogQueens;
		END;
	END Queens;
	(* конец фрагмента *****************************************)

	
	(* модификация для нахождения всех решений, с. 153: **************)

	PROCEDURE write;
		VAR  k: INTEGER;
	BEGIN
		FOR  k := 0  TO  7  DO  Texts.WriteInt( W, x[k], 4 )  END;
		Texts.WriteLn( W );
		LogQueens;
	END write;

	PROCEDURE TryAll ( i: INTEGER );
		VAR  j: INTEGER;
	BEGIN
		IF i < 8 THEN
			FOR  j := 0  TO  7  DO
				IF  a[j] & b[i+j] & c[i-j+7]  THEN
					x[i] := j; a[j] := FALSE; b[i+j] := FALSE; c[i-j+7] := FALSE;
					TryAll( i + 1 );
					x[i] := -1; a[j] := TRUE; b[i+j] := TRUE; c[i-j+7] := TRUE
				END
			END
		ELSE
			write;
			m := m+1 (*подсчет решений*)
		END
	END TryAll;
	
	PROCEDURE AllQueens*;
		VAR  i, j: INTEGER;
	BEGIN
		FOR i := 0 TO 7   DO  a[ i ] := TRUE;  x[ i ] := -1  END;
		FOR i := 0 TO 14 DO  b[ i ] := TRUE;  c[ i ] := TRUE  END;
		m := 0;
		TryAll( 0 );
		Log.String('всего решений: ');  Log.Int( m );  Log.Ln
	END AllQueens;

	(* конец фрагмента ******************************************)

BEGIN
	(* пусть W пишет в рабочий журнал, в конец: *)
	Texts.OpenWriter( W, Texts.log, Texts.Length( Texts.log ) )
END ADruS35_Queens.

Кликнуть по соответствующему черному коммандеру для выполнения соответствующей процедуры (вся выдача идет в рабочий журнал -- Log):

ADruS35_Queens.Queens      --поиск одного решения
ADruS35_Queens.AllQueens    --поиск всех решений

