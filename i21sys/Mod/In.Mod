MODULE i21sysIn;
(** 
2012-09-21 Ф.В.Ткачев. Практика показала, что нужны альтернативы старой процедуре Open с более простой логикой принятия решения насчёт того, откуда брать поток ввода. Поэтому добавлены: 
— OpenSelection: открывает выделенный фрагмент (именно она теперь стоит в меню для Open Input);
— OpenCommander: открывает текст после коммандера (точнее, после имени команды);
— в самой Open теперь нет попытки открыть весь документ в переднем окне при отсутствии выделенного фрагмента (в программе это не важно, в интерактивной работе это только запутывает, притом что всегда можно предварительно нажать Ctrl+A).
	
2010-09-16 Модификация Real, указанная Е.Э.Темиргалеевым: теперь команда Real корректно вернет значение, если в потоке ввода константа типа LONGINT (например, 1234567890123456).
2010-09-17 Ф.В.Ткачев
— для полноты поддержки парадигмы "текст как интерфейс" добавлены 
		процедура Restart ,
		глобальный scanner для полного доступа к потоку ввода;
— добавлена глобальная done, всегда равная Done. 
Первая версия: август 2002, Ф.Т. *)

	IMPORT  TextControllers, TextMappers, TextModels, DevCommanders;

	VAR
		done-, Done-: BOOLEAN; (* Done оставлен на случай проблем у народа с совместимостью *)
		scanner*: TextMappers.Scanner;

	PROCEDURE OpenText* ( text: TextModels.Model;  beg, end: INTEGER );
		VAR  t: TextModels.Model;
	BEGIN
		ASSERT( text # NIL, 20 );
		ASSERT( (0 <= beg) & (beg <= end) & (end <= text.Length()), 21 );
		t := TextModels.dir.New();
		t.InsertCopy( 0, text, beg, end );
		scanner.ConnectTo( t );  scanner.SetPos( 0 );  scanner.rider.Read;
		done := TRUE;
		Done := done
	END OpenText;

	PROCEDURE OpenFocus*; (** поток ввода — весь передний текст **)
		VAR  c: TextControllers.Controller; 
	BEGIN
		c := TextControllers.Focus();
		IF c # NIL THEN
			OpenText( c.text, 0, c.text.Length() )
		ELSE
			(* в фокусе нет текста *)
			done := FALSE;  Done := done
		END;
		ASSERT( Done = done, 60 )
	END OpenFocus;

	PROCEDURE OpenSelection*;
		VAR  c: TextControllers.Controller;  beg, end: INTEGER;  
	BEGIN
		c := TextControllers.Focus();
		IF ( c # NIL ) & c.HasSelection() THEN
			c.GetSelection( beg, end );
			OpenText( c.text, beg, end )
		ELSE
			(* в фокусе нет текста *)
			done := FALSE;  Done := done
		END;
		ASSERT( Done = done, 60 )
	END OpenSelection;

	PROCEDURE OpenCommander*;
	BEGIN
		IF DevCommanders.par # NIL  THEN (* внутри команды, вызванной из коммандера *)
			OpenText( DevCommanders.par.text, DevCommanders.par.beg, DevCommanders.par.end )
		ELSE
			done := FALSE;  Done := done
		END;
		ASSERT( Done = done, 60 )
	END OpenCommander;

	PROCEDURE Open*;
	BEGIN
		OpenSelection;
		IF ~done THEN
			OpenCommander
		END;
		ASSERT( Done = done, 60 )
	END Open;

	PROCEDURE Restart*; (** возвращаемся в начало потока ввода **)
	BEGIN
		done := ( scanner.rider # NIL ) & ( scanner.rider.Base() # NIL );
		IF  done  THEN
			scanner.SetPos( 0 );  scanner.rider.Read;
		END;
		Done := done
	END Restart;

	PROCEDURE Char* ( OUT ch: CHAR );
	BEGIN
		IF  done  THEN
			IF  scanner.rider.eot  THEN
				done := FALSE;  
			ELSE
				ch := scanner.rider.char;  scanner.rider.Read
			END
		END;
		Done := done
	END Char;

	PROCEDURE Int* ( OUT i: INTEGER );
	BEGIN
		IF  done  THEN
			scanner.Scan;
			IF  scanner.type = TextMappers.int  THEN
				i := scanner.int
			ELSE
				done := FALSE
			END
		END;
		Done := done
	END Int;

	PROCEDURE LongInt* ( OUT l: LONGINT );
	BEGIN
		IF  done  THEN
			scanner.Scan;
			IF ( scanner.type = TextMappers.lint ) OR ( scanner.type = TextMappers.int ) THEN
				l := scanner.lint
			ELSE
				done := FALSE
			END
		END;
		Done := done
	END LongInt;

	PROCEDURE Real* ( OUT x: REAL );
	BEGIN
		IF  done  THEN
			scanner.Scan;
			IF  scanner.type = TextMappers.real  THEN
				x := scanner.real (* в блэкбоксовском In эта инструкция дана подчеркнуто с ошибкой; в менее явном виде эта ошибка есть еще у Вирта-Райзера, откуда в качестве примера был взят модуль In; авторы Блэкбокса оставили ошибку сознательно, т.к. имели целью точно воспроизвести пример Вирта-Райзера; мы здесь не связаны таким условием :-) т.к. пытаемся довести In до ума в качестве удобного инструмента ввода данных *)
			ELSIF  scanner.type IN { TextMappers.int, TextMappers.lint } THEN (* в старом Обероне это было неактуально; исправление указано Е.Э.Темиргалеевым *)
				x := scanner.lint
			ELSE
				done := FALSE
			END
		END;
		Done := done
	END Real;

	PROCEDURE Name* ( OUT name: ARRAY OF CHAR );
	BEGIN
		IF  done  THEN
			scanner.Scan;
			TextMappers.ScanQualIdent( scanner, name, Done )
		END;
		Done := done
	END Name;

	PROCEDURE String* ( OUT str: ARRAY OF CHAR );
	BEGIN
		IF  done  THEN
			scanner.Scan;
			IF  scanner.type = TextMappers.string  THEN
				str := scanner.string$
			ELSE
				done := FALSE
			END
		END;
		Done := done
	END String;

END i21sysIn.
