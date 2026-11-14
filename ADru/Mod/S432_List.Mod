(*  Общие сведения о примерах: Справка *)
(*  Исправления и подготовка примеров: (С) Ф.В.Ткачев, 2009, info21 AT inr.ac.ru *)

MODULE  ADruS432_List;  (* Простейшая процедура поиска с включением в линейный список (алфавитный частотный словарь), раздел 4.3.2. *)

	IMPORT  Log := StdLog,  In := i21sysIn,  Math,  Texts := ADruS174_Texts;
	
	(* фрагмент из текста, с. 180: **********************)
	TYPE
		Word = POINTER TO RECORD
			key, count: INTEGER;  next: Word  
		END;

	VAR  W: Texts.Writer;  root: Word;
	
	PROCEDURE search ( x: INTEGER;  VAR root: Word );
		VAR  w: Word;
	BEGIN
		w := root;
		WHILE (w # NIL) & (w.key # x) DO  w := w.next  END;
		(* (w = NIL) OR (w.key = x) *)
		IF  w = NIL  THEN  (* новый элемент *)
			w := root;
			NEW( root );  root.key := x;  root.count := 1;  root.next := w
		ELSE
			INC( w.count )
		END
	END search;

	PROCEDURE PrintList ( w: Word );
	BEGIN
		(* используется глобальный объект записи W *)
		(* простой проход по списку: *)
		WHILE  w # NIL  DO
			Texts.WriteInt( W, w.key, 8 );  Texts.WriteInt( W, w.count, 8 ); 
			Texts.WriteLn( W );
			w := w.next
		END
	END PrintList;
	(* конец фрагмента ********************************)
	
	PROCEDURE Do*;
		VAR  n: INTEGER;
	BEGIN
		Texts.OpenWriter( W, Texts.log, Texts.Length( Texts.log ) );
		
		(* читаем и обрабатываем поток чисел: *)
		In.Open; ASSERT( In.done );
		In.Int( n );
		WHILE  In.done  DO
			search( n, root ); 
			In.Int( n )
		END;
		PrintList( root );
	END Do;
	
END  ADruS432_List.

ADruS432_List.Do 4 6 6 9  2 4 1 1 1 0 1 0 1 
