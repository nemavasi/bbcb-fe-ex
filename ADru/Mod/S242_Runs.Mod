(*  Общие сведения о примерах: Справка *)
(*  Исправления и подготовка примеров: (С) Ф.В.Ткачев, 2009, info21 AT inr.ac.ru *)

MODULE ADruS242_Runs;
(* Реализация вспомогательного модуля Runs из раздела 2.4.2, с. 105. ********
	Средства модуля используются в различных алгоритмах сортировки слияниями. *)
	IMPORT  Files := ADruS171_Files,  Texts := ADruS174_Texts;

	TYPE
		Rider* = RECORD ( Files.Rider )
			first-: INTEGER;
			eor-: BOOLEAN 
		END;
	
	PROCEDURE OpenRandomSeq*( f: Files.File;  length, seed: INTEGER );
		VAR  i: INTEGER;  w: Files.Rider;
	BEGIN
		Files.Set( w, f, 0 );
		FOR i := 0 TO length-1 DO
			Files.WriteInt( w, seed );  seed := (31*seed) MOD 997 + 5
		END;
		Files.Close( f )
	END OpenRandomSeq;
	
	PROCEDURE Set*( VAR r: Rider;  f: Files.File );
	BEGIN
		Files.Set( r, f, 0 );
		Files.ReadInt( r, r.first );
		r.eor := r.eof 
	END Set;
	
	PROCEDURE copy*( VAR src, dest: Rider );
	BEGIN
		dest.first := src.first;
		Files.WriteInt( dest, dest.first );
		Files.ReadInt( src, src.first );
		src.eor := src.eof OR ( src.first < dest.first )
	END copy;
	
	PROCEDURE ListSeq*( VAR W: Texts.Writer;  f: Files.File );
		VAR  x, y, k, n: INTEGER;  r: Files.Rider;
	BEGIN
		k := 0;  n := 0;
(* Версия из книги. Проверка флажка r.eof должна выполняться немедленно за попыткой чтения ReadInt. Ошибка происходит из попытки оптимизации (сэкономить на повторении группы команд). 
Корректная версия приводится ниже.
		Files.Set( r, f, 0 );  Files.ReadInt( r, x ); 
		WHILE ~r.eof DO
			Texts.WriteInt( W, x, 6 );  INC( k );  Files.ReadInt( r, y );
			IF  y < x  THEN (*конец серии*) Texts.Write( W, "|" );  INC( n )  END;
			x := y
		END;
*)
		(* корректная версия *)
		Files.Set( r, f, 0 );  Files.ReadInt( r, x ); 
		IF  ~r.eof  THEN
			Texts.WriteInt( W, x, 6 );  INC( k );  Files.ReadInt( r, y );
			WHILE  ~r.eof  DO
				IF  y < x  THEN (*конец серии*) Texts.Write( W, "|" );  INC( n )  END;
				x := y;
				Texts.WriteInt( W, x, 6 );  INC( k );  Files.ReadInt( r, y );
			END;
		END;
		
		Texts.Write( W, "$" );  Texts.WriteInt( W, k, 5 );  Texts.WriteInt( W, n, 5 );
		Texts.WriteLn( W ) 
	END ListSeq;
	
	
	PROCEDURE LogSeq*( f: Files.File ); (* то же, что ListSeq, но пишет в Log (рабочий журнал), причем всегда в конце *)
		VAR  x, y, k, n: INTEGER;  r: Files.Rider;  log: Texts.Writer; 
	BEGIN
		Texts.OpenWriter( log, Texts.log, Texts.Length( Texts.log ) );
		
		k := 0;  n := 0;  Files.Set( r, f, 0 );

		Files.ReadInt( r, x ); 
		IF  ~r.eof  THEN
			Texts.WriteInt( log, x, 6 );  INC( k );
			Files.ReadInt( r, y );
			WHILE  ~r.eof  DO
				IF  y < x  THEN (*конец серии*)  Texts.WriteLn( log );  Texts.Write( log, "|" );  INC( n )  END;
				Texts.WriteInt( log, y, 6 );  INC( k );
				x := y;
				Files.ReadInt( r, y );
			END;
		ELSE
			
		END;
		
		Texts.Write( log, "$" );  Texts.WriteInt( log, k, 5 );  Texts.WriteInt( log, n, 5 );
		Texts.WriteLn( log );
		Texts.ShowEnd( Texts.log );
		
	END LogSeq;
	
END ADruS242_Runs.
