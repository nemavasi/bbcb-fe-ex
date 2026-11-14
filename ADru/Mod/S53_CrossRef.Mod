(*  Общие сведения о примерах: Справка *)
(*  Исправления и подготовка примеров: (С) Ф.В.Ткачев, 2009, info21 AT inr.ac.ru *)

MODULE  ADruS53_CrossRef;  (* Хэш-таблицы, раздел 5.3. *)

	IMPORT  Log := StdLog,  In := i21sysIn,  Texts := ADruS174_Texts;
	
	(* фрагмент из книги, с. 259: **********************************)
	CONST
		N = 997;  (* простое, размер таблицы *)
		WordLen = 32;   (* максимальная длина ключей *)
		Noc = 16;   (* макс. число элементов в слове *)
	
	TYPE
		Word = ARRAY WordLen OF CHAR;
		Table = POINTER TO ARRAY N OF
			RECORD
				key: Word;
				n: INTEGER;
				lno: ARRAY Noc OF INTEGER
			END;
	
	VAR  line: INTEGER;  W: Texts.Writer;
	
	PROCEDURE search ( T: Table;  VAR a: Word );
		VAR  i, d: INTEGER;  h: LONGINT;  found: BOOLEAN;
	BEGIN (* вычислить хэш-индекс h для a; 
				используется глобальная переменная line *)
		i := 0;  h := 0;
		WHILE  a[ i ] > 0X  DO
			h := ( 256*h + ORD( a[ i ] ) ) MOD N;
			INC( i )
		END;
		d := 1;  found := FALSE;
		REPEAT
			IF  T[ h ].key = a  THEN (* совпадение *)
				found := TRUE; 
				T[ h ].lno[ T[ h ].n ] := line;
				IF  T[ h ].n < Noc  THEN  INC( T[ h ].n )  END
			ELSIF  T[ h ].key[ 0 ] = " "  THEN (* новый элемент таблицы *)
				found := TRUE;  T[ h ].key := a$;  T[ h ].lno[ 0 ] := line;  T[ h ].n := 1
			ELSE (* коллизия *)  h := h+d;  d := d+2;
				IF  h >= N  THEN  h := h-N  END;
				IF  d = N  THEN
					Texts.WriteString( W, " Переполнение таблицы");
					HALT( 88 )
				END
			END
		UNTIL  found
	END search;
	
	PROCEDURE Tabulate ( T: Table ); (* используется глобальный объект печати W *)
		VAR  i, k: INTEGER;
	BEGIN
		FOR  k := 0  TO  N-1  DO
			IF  T[ k ].key[ 0 ] # " "  THEN
				Texts.WriteString( W, T[ k ].key );  Texts.WriteTab( W );
				FOR  i := 0  TO  T[ k ].n -1  DO
					Texts.WriteInt( W, T[ k ].lno[ i ], 4 )
				END;
				Texts.WriteLn( W )
			END
		END
	END Tabulate;
	
	PROCEDURE CrossRef ( VAR R: Texts.Reader );
		VAR  i: INTEGER;  ch: CHAR;  w: Word;  H: Table;
	BEGIN
		NEW( H );
		FOR  i := 0  TO  N-1  DO  H[ i ].key[ 0 ] := " "  END; (* разместить и очистить хэш-таблицу *)

		line := 0;
		Texts.WriteInt( W, 0, 6 );  Texts.WriteTab( W );
		Texts.Read( R, ch );
		WHILE  ~R.eot  DO
			IF  ch = 0DX  THEN (* конец строки *)
				Texts.WriteLn( W );
				INC( line );  Texts.WriteInt( W, line, 6 );  Texts.WriteTab( W );
				Texts.Read( R, ch )
			ELSIF ("A" <= ch) & (ch <= "Z") OR ("a" <= ch) & (ch <= "z") THEN
				i := 0;
				REPEAT
					IF  i < WordLen-1  THEN  w[ i ] := ch;  INC( i )  END;
					Texts.Write( W, ch );
					Texts.Read( R, ch )
				UNTIL  (i = WordLen-1) OR ~( ("A" <= ch) & (ch <= "Z") ) &
					~(("a" <= ch) & (ch <= "z") ) & ~( ("0" <= ch) & (ch <= "9") );
				w[ i ] := 0X; (* конец цепочки литер *)
				search( H, w )
			ELSE
				Texts.Write( W, ch );
				Texts.Read( R, ch )
			END;
			Texts.WriteLn( W );  Texts.WriteLn( W );
			Tabulate( H )
		END
	END CrossRef;
	(* конец фрагмента ******************************************)
	
	PROCEDURE Do*;
		VAR  r: Texts.Reader;
	BEGIN
		Texts.OpenWriter( W, Texts.log, Texts.Length( Texts.log ) );
		Texts.OpenInput;
		Texts.OpenReader( r, Texts.input, 0 );
		CrossRef( r )
	END Do;
		
END  ADruS53_CrossRef.

Входной поток данных для программы выделен красным цветом.
Программа считает словами последовательности английских букв.

ADruS53_CrossRef.Do 
This is a test of the program CrossRef written by Niklaus Wirth, by Niklaus Wirth. 
