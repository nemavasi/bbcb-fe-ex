(*  Общие сведения о примерах: Справка *)
(*  Исправления и подготовка примеров: (С) Ф.В.Ткачев, 2009, info21 AT inr.ac.ru *)

MODULE  ADruS432_List3;  (* Процедура поиска с включением в упорядоченный линейный список, раздел 4.3.2. *)

	IMPORT  Log := StdLog,  In := i21sysIn,  Math,  Texts := ADruS174_Texts;
	
	TYPE
		Word = POINTER TO RECORD
			key, count: INTEGER;  next: Word  
		END;

	VAR  W: Texts.Writer;  root: Word;
	
	(* фрагмент из книги, с. 182: **********************************)
	PROCEDURE search ( x: INTEGER;  VAR root: Word );
		VAR  w1, w2, w3: Word;
	BEGIN
		w2 := root;  w1 := w2.next;
		WHILE (w1 # NIL) & (w1.key < x) DO
			w2 := w1;  w1 := w2.next
		END;
		(* (w1 = NIL) OR (w1.key >= x) *)
		IF  (w1 = NIL) OR (w1.key > x)  THEN  (* новый элемент *)
			NEW( w3 );  w2.next := w3;
			w3.key := x;  w3.count := 1;  w3.next := w1
		ELSE
			INC( w1.count )
		END
	END search;
	(* конец фрагмента ******************************************)

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
	
	PROCEDURE Do*;
		VAR  n: INTEGER;
	BEGIN
		NEW( root );  root.next := NIL;
		
		Texts.OpenWriter( W, Texts.log, Texts.Length( Texts.log ) );
		
		(* читаем и обрабатываем поток чисел: *)
		In.Open; ASSERT( In.done );
		In.Int( n );
		WHILE  In.done  DO
			search( n, root ); 
			In.Int( n )
		END;
		PrintList( root.next );
	END Do;
	
END  ADruS432_List3.

ADruS432_List3.Do 4 6 6 9  2 4 1 1 1 0 1 0 1 
