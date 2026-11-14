(*  Общие сведения о примерах: Справка *)
(*  Исправления и подготовка примеров: (С) Ф.В.Ткачев, 2009, info21 AT inr.ac.ru *)

MODULE  ADruS443_CrossRef;  (* Построение указателя перекрестных ссылок, раздел 4.4.3. *)
	IMPORT  Log := StdLog,  In := i21sysIn,  Texts := ADruS174_Texts;
	
	(* фрагмент из книги, с. 204: ************************************)
	CONST  WordLen = 32;
	
	TYPE  Word = ARRAY WordLen OF CHAR;
		Item =	POINTER TO RECORD
				lno: INTEGER;  next: Item
			END;
		Node =	POINTER TO RECORD
				key: Word;
				first, last: Item;  (*список*)
				left, right: Node  (*дерево*)
			END;

	VAR  line: INTEGER;  W: Texts.Writer;

	PROCEDURE search ( VAR w: Node;  VAR a: Word );
		VAR  q: Item;
	BEGIN
		IF  w = NIL  THEN (* слова в дереве нет; вставить новый узел *)
			NEW( w );  NEW( q );  q.lno := line;
			w.key := a$;  w.first := q;  w.last := q;  w.left := NIL;  w.right := NIL
		ELSIF  w.key < a  THEN  search( w.right, a )
		ELSIF  w.key > a  THEN  search( w.left, a )
		ELSE (*слово в дереве*)
			NEW( q );  q.lno := line;  w.last.next := q;  w.last := q
		END
	END search;

	PROCEDURE Tabulate ( w: Node );
		VAR  m: INTEGER;  item: Item;
	BEGIN
		IF  w # NIL  THEN
			Tabulate( w.left );
			Texts.WriteString( W, w.key );  Texts.WriteTab( W );  
			item := w.first;  m := 0;
			REPEAT
				IF  m = 10  THEN
					Texts.WriteLn( W );  Texts.WriteTab( W );  m := 0
				END;
				INC( m );  Texts.WriteInt( W, item.lno, 6 );  item := item.next
			UNTIL  item = NIL;
			Texts.WriteLn( W );
			Tabulate( w.right )
		END
	END Tabulate;

	PROCEDURE CrossRef ( VAR R: Texts.Reader );
		VAR  root: Node;  (* используется глобальный объект печати W *)
			i: INTEGER;  ch: CHAR;  w: Word;
	BEGIN
		Texts.WriteInt( W, 0, 6 );  Texts.WriteTab( W );
		
		root := NIL;  line := 0;
		Texts.Read( R, ch );
		WHILE  ~R.eot  DO
			IF  ch = 0DX  THEN (*конец строки*) Texts.WriteLn( W );
				INC( line );
				Texts.WriteInt( W, line, 6 );  Texts.WriteTab( W );
				Texts.Read( R, ch )
			ELSIF ("A" <= ch) & (ch <= "Z") OR ("a" <= ch) & (ch <= "z") THEN
				i := 0;
				REPEAT
					IF  i < WordLen-1  THEN  w[ i ] := ch;  INC( i )  END;
					Texts.Write( W, ch );
					Texts.Read( R, ch )
				UNTIL (i = WordLen-1) OR ~(("A" <= ch) & (ch <= "Z")) &
					~(("a" <= ch) & (ch <= "z")) & ~(("0" <= ch) & (ch <= "9"));
				
				w[ i ] := 0X; (* конец цепочки литер *)
				search( root, w )
			ELSIF  ch = 09X  THEN
				Texts.WriteTab( W );
				Texts.Read( R, ch )
			ELSE
				Texts.Write( W, ch );
				Texts.Read( R, ch )
			END;
		END;
		Texts.WriteLn( W );  Texts.WriteLn( W );
		Tabulate( root )
	END CrossRef;
	(* конец фрагмента ***************************************)
	
	PROCEDURE Do*;
		VAR  R: Texts.Reader;
	BEGIN
		Texts.OpenInput;
		Texts.OpenReader( R, Texts.input, 0 );
		Texts.OpenWriter( W, Texts.log, Texts.Length( Texts.log ) );
		CrossRef( R )
	END Do;
	
END  ADruS443_CrossRef.


ADruS443_CrossRef.Do 
PROCEDURE search(x: INTEGER; VAR p: Node);     
BEGIN     
	IF x < p.key THEN search(x, p.left)     
	ELSIF x > p^key THEN search(x, p.right)     
	ELSIF p # s THEN INC(p.count)     
	ELSE (*insert*) NEW(p);      
	p.key := x; p.left := s; p.right := s; p.count := 1     
	END     
END 

