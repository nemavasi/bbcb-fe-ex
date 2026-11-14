(*  Общие сведения о примерах: Справка *)
(*  Исправления и подготовка примеров: (С) Ф.В.Ткачев, 2009, info21 AT inr.ac.ru *)

MODULE  ADruS433_TopSort;  (* Топологическая сортировка, раздел 4.3.3. *)
	IMPORT  Log := StdLog,  In := i21sysIn,  Texts := ADruS174_Texts;

	TYPE  (* определения типов, с. 187 *******************)
		Leader = POINTER TO LeaderDesc;
		Trailer = POINTER TO TrailerDesc;
		LeaderDesc = RECORD
			key, count: INTEGER;
			trail: Trailer;
			next: Leader
		END;
		TrailerDesc = RECORD
			id: Leader;
			next: Trailer
		END;
	
	VAR  W: Texts.Writer;
	
	(* фрагмент из книги, с. 189: **********************************)
	VAR  head, tail: Leader;  n: INTEGER;

	PROCEDURE find ( w: INTEGER ): Leader;
		VAR  h: Leader;
	BEGIN
		h := head;  tail.key := w;  (* барьер *)
		WHILE  h.key # w  DO  h := h.next  END;
		IF  h = tail  THEN
			NEW( tail );  INC( n );
			h.count := 0;  h.trail := NIL;  h.next := tail
		END;
		RETURN  h
	END find;

	PROCEDURE TopSort ( VAR S: Texts.Scanner );
		VAR p, q: Leader;  t: Trailer;  (* используется глобальный объект записи W *)
			x, y: INTEGER;
	BEGIN
		(* инициализировать список ведущих фиктивным элементом-барьером *)
		NEW( head );  tail := head;  n := 0;
		
		(* фаза ввода *)
		Texts.Scan( S );
		WHILE  S.class = Texts.Int  DO
			x := S.i;  Texts.Scan( S );  y := S.i;  p := find( x );  q := find( y );
			NEW(t);  t.id := q;  t.next := p.trail;
			p.trail := t;  INC( q.count );  Texts.Scan( S )
		END;
		
		(* поиск ведущих без предшественников *)
		p := head;  head := NIL;
		WHILE  p # tail  DO
			q := p;  p := q.next;
			IF  q.count = 0  THEN  (* включить q в новую цепочку *)
				q.next := head; head := q
			END
		END;

		(* фаза вывода *) 
		q := head;
		WHILE  q # NIL  DO
			Texts.WriteLn( W );  Texts.WriteInt( W, q.key, 8 );  DEC( n );
			t := q.trail;  q := q.next;
			WHILE  t # NIL  DO
				p := t.id;  DEC( p.count );
				IF  p.count = 0  THEN  (* включить p в список ведущих *)
					p.next := q; q := p
				END;
				t := t.next
			END
		END;
		IF  n # 0  THEN
			Texts.WriteString( W, "Набор не является частично упорядоченным" )
		END;
		Texts.WriteLn( W )
	END TopSort;
	(* конец фрагмента **********************************)
	
	PROCEDURE Do*;
		VAR  S: Texts.Scanner;
	BEGIN
		Texts.OpenInput;
		Texts.OpenWriter( W, Texts.log, Texts.Length( Texts.log ) );
		Texts.WriteString( W, 'TopSort' );  Texts.WriteLn( W );
		Texts.OpenScanner( S, Texts.input, 0 );  (* читается тот же текст, что и при In.Open *)
		
		TopSort( S );
	END Do;

END  ADruS433_TopSort.


ADruS433_TopSort.Do 	1  2	2  4	4  6	2  10	4  8	6  3	1  3  
	3  5	5  8	7  5	7  9	9  4	9  10 
