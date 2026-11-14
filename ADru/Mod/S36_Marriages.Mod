(*  Общие сведения о примерах: Справка *)
(*  Исправления и подготовка примеров: (С) Ф.В.Ткачев, 2009, info21 AT inr.ac.ru *)

MODULE  ADruS36_Marriages;  (* Задача о стабильных браках, раздел 3.6. *)
	IMPORT  Texts := ADruS174_Texts,  Log := StdLog,  In := i21sysIn;
	TYPE  man = INTEGER;  woman = INTEGER;  rank = INTEGER;
	CONST  n = 8;
	VAR  
		x: ARRAY n OF woman;
		y: ARRAY n OF man;
		single: ARRAY n OF BOOLEAN;
		rmw, rwm: ARRAY n, n OF rank;
		wmr: ARRAY n, n OF woman;
		mwr: ARRAY n, n OF man;
		c: INTEGER;
	
	VAR  W: Texts.Writer;
	
	(* фрагмент из книги, с. 158: ***********************************)
	
	PROCEDURE write;  (* выдача в глобальный объект печати W *)
		VAR  m: man;  rm, rw: INTEGER;
	BEGIN
		Log.String('output:');  Log.Ln;
		Texts.OpenWriter( W, Texts.log, Texts.Length( Texts.log ) ); (*открыть это в MAIN *)
		rm := 0;  rw := 0;
		FOR m := 0 TO n-1 DO
			Texts.WriteInt( W, x[ m ], 4 );
			rm := rmw[ m, x[ m ] ] + rm;
			rw := rwm[ x[ m ], m ] + rw
		END;
		Texts.WriteInt( W, rm, 8 );  Texts.WriteInt( W, rw, 4 );  Texts.WriteInt( W, c, 5 );  Texts.WriteLn( W );
		c := 0;
	END write;

	PROCEDURE stable ( m, w, r: INTEGER ): BOOLEAN;
		VAR  pm, pw, rank, i, lim: INTEGER;  S: BOOLEAN;
	BEGIN
		INC( c );
		
		i := -1;  S := TRUE;
		REPEAT INC(i);
			IF  i < r  THEN
				pw := wmr[m,i];
				IF ~single[pw] THEN S := rwm[pw,m] > rwm[pw, y[pw]] END
			END
		UNTIL (i = r) OR ~S;

		IF  S  THEN
			i := -1;  lim := rwm[w,m];
			REPEAT INC(i);
				IF  i < lim  THEN
					pm := mwr[w,i];
					IF pm < m THEN S := rmw[pm,w] > rmw[pm, x[pm]] END
				END
			UNTIL (i > lim) OR ~S;
		END;
		
		RETURN  S
	END stable;

	PROCEDURE Try ( m: INTEGER );
		VAR  w, r: INTEGER;
	BEGIN
		IF  m < n  THEN
			FOR  r := 0  TO  n-1  DO
				w := wmr[ m, r ];
				IF  single[ w ] & stable( m, w, r )  THEN
					x[ m ] := w;
					y[ w ] := m;
					single[ w ] := FALSE;
					Try( m+1 );
					single[ w ] := TRUE
				END
			END
		ELSE
			write
		END;
	END Try;

	PROCEDURE FindStableMarriages*; 
	(* В тексте книги ввод производится из явно заданного сканера.
		В данном варианте ввод производится из стандартного потока ввода в Блэкбоксе с помощью модуля In. *)
		VAR  m, w, r: INTEGER;  k: INTEGER;
	BEGIN
		In.Open;  ASSERT( In.done ); 
		FOR  m := 0  TO  n-1  DO
			FOR  r := 0  TO  n-1  DO  In.Int( k );  ASSERT( In.done );
				wmr[ m, r ] := k;  rmw[ m, wmr[ m, r ] ] := r 
			END
		END;
		FOR  w := 0  TO  n-1  DO
			single[ w ] := TRUE;
			FOR  r := 0  TO  n-1  DO  In.Int( k );  ASSERT( In.done );
				mwr[ w, r ] := k;  rwm[ w, mwr[ w, r ] ] := r 
			END
		END;
		Log.String('starting...');  Log.Ln;  (* печать в Log для удобства контроля *)
		Try( 0 );
		Log.String('done.');  Log.Ln;  (* печать в Log для удобства контроля *)
	END FindStableMarriages;
	
	(* конец фрагмента ******************************************)

END  ADruS36_Marriages.

Кликнуть по командиру для выполнения:

ADruS36_Marriages.FindStableMarriages
	6	1	5	4	0	2	7	3	
	3	2	1	5	7	0	6	4	
	2	1	3	0	7	4	6	5	
	2	7	3	1	4	5	6	0	
	7	2	3	4	5	0	6	1	
	7	6	4	1	3	2	0	5	
	1	3	5	2	0	6	4	7	
	5	0	3	1	6	4	2	7	

	3	5	1	4	7	0	2	6
	7	4	2	0	5	6	3	1
	5	7	0	1	2	3	6	4
	2	1	3	6	5	7	4	0
	5	2	0	3	4	6	1	7
	1	0	2	7	6	3	5	4
	2	4	6	1	3	0	7	5
	6	1	7	3	4	5	2	0


