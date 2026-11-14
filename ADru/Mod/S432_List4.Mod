(*  Общие сведения о примерах: Справка *)
(*  Исправления и подготовка примеров: (С) Ф.В.Ткачев, 2009, info21 AT inr.ac.ru *)

MODULE  ADruS432_List4;  (* Процедура поиска с включением в линейный список с переупорядочением, раздел 4.3.2. *)

	IMPORT  Log := StdLog,  In := i21sysIn,  Math,  Texts := ADruS174_Texts;
	
	TYPE
		Word = POINTER TO RECORD
			key, count: INTEGER;  next: Word  
		END;

	VAR  W: Texts.Writer;  root, sentinel: Word;
	
	(* фрагмент из книги, с. 183: **********************************)	

	PROCEDURE search ( x: INTEGER;  VAR root: Word );
		VAR  w1, w2: Word;
	BEGIN
		w1 := root;  sentinel.key := x;
		IF  w1 = sentinel  THEN  (* первый элемент *)
			NEW( root );  root.key := x;  root.count := 1;  root.next := sentinel
		ELSIF  w1.key = x  THEN
			INC( w1.count )
		ELSE  (* поиск *)
			REPEAT  w2 := w1;  w1 := w2.next
			UNTIL w1.key = x;
			IF w1 = sentinel THEN  (* новый элемент *)
				w2 := root;
				NEW( root );  root.key := x;  root.count := 1;  root.next := w2
			ELSE  (* нашли, переупорядочиваем *)
				INC( w1.count );
				w2.next := w1.next;  w1.next := root;  root := w1
			END
		END
	END search;		(* конец фрагмента *******************************************)

	PROCEDURE PrintList ( w: Word );
	BEGIN
		(* используется глобальный объект записи W *)
		(* простой проход по списку: *)
		WHILE  w # sentinel  DO
			Texts.WriteInt( W, w.key, 8 );  Texts.WriteInt( W, w.count, 8 ); 
			Texts.WriteLn( W );
			w := w.next
		END
	END PrintList;
	
	PROCEDURE Do*;
		VAR  n: INTEGER;
	BEGIN
		NEW( sentinel );  root := sentinel;
		
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
	
END  ADruS432_List4.

ADruS432_List4.Do 4 6 6 9  2 4 1 1 1 0 1 0 1 
