(*  Общие сведения о примерах: Справка *)
(*  Исправления и подготовка примеров: (С) Ф.В.Ткачев, 2009, info21 AT inr.ac.ru *)

MODULE  ADruS471_Btrees;  (* Сильно ветвящиеся Б-деревья, раздел 4.7.1. *)

	IMPORT  Log := StdLog,  In := i21sysIn,  Texts := ADruS174_Texts;
	
	CONST  N = 2;
	
	(* фрагмент из книги, с. 235: ***********************************)
	TYPE
		Page = POINTER TO PageRec;
		
		Entry = RECORD
			key: INTEGER;  p: Page
		END;
		
		PageRec = RECORD
			m: INTEGER;  (* число элементов на странице *)
			p0: Page;
			e: ARRAY 2*N OF Entry
		END;
		
		VAR  root: Page;  W: Texts.Writer;
	
	PROCEDURE search ( x: INTEGER;  VAR p: Page;  VAR k: INTEGER );
		VAR  i, L, R: INTEGER;  found: BOOLEAN;  a: Page;
	BEGIN
		a := root;  found := FALSE;
		WHILE  (a # NIL) & ~found  DO
			L := 0;  R := a.m;  (* поиск делением пополам *)
			WHILE  L < R  DO
				i := (L+R) DIV 2;
				IF  x <= a.e[i].key  THEN  R := i  ELSE  L := i+1  END
			END;
			IF  (R < a.m) & (a.e[R].key = x)  THEN  found := TRUE; (* a := a; *)
			ELSIF  R = 0  THEN  a := a.p0
			ELSE  a := a.e[R-1].p
			END
		END;
		p := a;  k := R
	END search;
	
	PROCEDURE insert ( x: INTEGER;  a: Page;  VAR h: BOOLEAN;  VAR v: Entry );
	(* a # NIL. Искать ключ x в Б-дереве с корнем a; вставить новый элемент с ключем x.
		Если наверх нужно передать элемент, присвоить его v. 
		h := "высота дерева увеличилась" 
	*)
		VAR  i, L, R: INTEGER;  b: Page;  u: Entry;
	BEGIN
		(* ~h *)
		IF  a = NIL  THEN
			v.key := x;  v.p := NIL;
			h := TRUE
		ELSE
			L := 0;  R := a.m;  (* поиск делением пополам *)
			WHILE  L < R  DO
				i := (L+R) DIV 2;
				IF  x <= a.e[ i ].key  THEN  R := i  ELSE  L := i+1  END
			END;
			IF (R < a.m) & (a.e[R].key = x) THEN (* нашли, делать нечего *)
			ELSE
				(* на этой странице нет *)
				IF  R = 0  THEN  b := a.p0  ELSE  b := a.e[R-1].p  END;
				insert( x, b, h, u );
				IF  h  THEN  (* вставить u слева от a.e[R] *)
					IF  a.m < 2*N  THEN
						h := FALSE;
						FOR  i := a.m  TO  R+1  BY  -1  DO  a.e[ i ] := a.e[ i-1 ]  END;
						a.e[ R ] := u;  INC( a.m )
					ELSE
						NEW( b ); 
						(* переполнение; разбить a на a, b и присвоить средний элемент v *)
						IF  R < N  THEN  (* вставить в левую страницу a *)
							v := a.e[ N-1 ];
							FOR  i := N-1  TO  R+1  BY  -1  DO  a.e[ i ] := a.e[ i-1 ]  END;
							a.e[ R ] := u;
							FOR  i := 0  TO  N-1  DO  b.e[ i ] := a.e[ i+N ]  END
						ELSE (* вставить в правую страницу b *)
							DEC( R, N );
							IF  R = 0  THEN  v := u
							ELSE  v := a.e[ N ];
								FOR  i := 0  TO  R-2  DO  b.e[ i ] := a.e[ i+N+1 ]  END;
								b.e[ R-1 ] := u
							END;
							FOR  i := R  TO  N-1  DO  b.e[ i ] := a.e[ i+N ]  END
						END;
						a.m := N;  b.m := N;  b.p0 := v.p;  v.p := b
					END
				END
			END
		END
	END insert;

	PROCEDURE underflow ( c, a: Page;  s: INTEGER;  VAR h: BOOLEAN );
		(* a = страница, где слишком мало элементов (underflow), 
		    c = страница-предок,
			s = индекс стертого значения в c
		*)
		VAR  b: Page;  i, k: INTEGER;
	BEGIN
		(* h & (a.m = N-1) & (c.e[s-1].p = a) *)
		IF  s < c.m  THEN  (* b := страница справа от a *)
			b := c.e[ s ].p;
			k := (b.m-N+1) DIV 2; (* k = число свободных элементов на странице b *)
			a.e[ N-1 ] := c.e[ s ];  a.e[ N-1 ].p := b.p0;
			IF  k > 0  THEN  (* сбалансировать перемещением k-1 элементов с b на a *)
				FOR  i := 0  TO  k-2  DO  a.e[ i+N ] := b.e[ i ]  END;
				c.e[ s ] := b.e[ k-1 ];  b.p0 := c.e[ s ].p;
				c.e[ s ].p := b;  DEC( b.m, k );
				FOR  i := 0  TO  b.m-1  DO  b.e[ i ] := b.e[ i+k ]  END;
				a.m := N-1+k;
				h := FALSE
			ELSE (* слить страницы a и b, b больше не нужна *)
				FOR  i := 0  TO  N-1  DO  a.e[ i+N ] := b.e[ i ]  END;
				DEC( c.m );
				FOR  i := s  TO  c.m-1  DO  c.e[ i ] := c.e[ i+1 ]  END;
				a.m := 2*N;
				h := c.m < N
			END
		ELSE (* b := страница слева от a *)
			DEC( s );
			IF  s = 0  THEN  b := c.p0  ELSE  b := c.e[ s-1 ].p  END;
			k := (b.m-N+1) DIV 2; (* k = число свободных элементов на странице b *)
			IF  k > 0  THEN
				FOR  i := N-2  TO  0  BY  -1  DO  a.e[ i+k ] := a.e[ i ]  END;
				a.e[ k-1 ] := c.e[ s ];  a.e[ k-1 ].p := a.p0;
				(* переместить k-1 элементов с b на a, один на c *)
				DEC( b.m, k );
				FOR  i := k-2  TO  0  BY  -1  DO  a.e[ i ] := b.e[ i+b.m+1 ]  END;
				c.e[ s ] := b.e[ b.m ];  a.p0 := c.e[s].p;
				c.e[ s ].p := a;  a.m := N-1+k;
				h := FALSE
			ELSE (* слить страницы a и b, a больше не нужна *)
				c.e[ s ].p := a.p0;  b.e[ N ] := c.e[ s ];
				FOR  i := 0  TO  N-2  DO  b.e[ i+N+1 ] := a.e[ i ]  END;
				b.m := 2*N;  DEC( c.m );
				h := c.m < N
			END
		END
	END underflow;

	PROCEDURE delete ( x: INTEGER;  a: Page;  VAR h: BOOLEAN );
		(* найти и удалить ключ x в Б-дереве a; 
		    если на странице стало слишком мало элементов, 
			сбалансировать с соседней страницей или слить; 
			h := "на странице слишком мало элементов"
		*)
		VAR  i, L, R: INTEGER;  q: Page;
		
		PROCEDURE del ( p: Page;  VAR h: BOOLEAN );
			VAR  k: INTEGER;  q: Page;  (* глобальные a, R *)
		BEGIN
			k := p.m-1;  q := p.e[ k ].p;
			IF  q # NIL  THEN
				del( q, h );
				IF  h  THEN  underflow( p, q, p.m, h )  END
			ELSE
				p.e[ k ].p := a.e[ R ].p;  a.e[ R ] := p.e[ k ];
				DEC( p.m );
				h := p.m < N
			END
		END del;
	
	BEGIN
		IF  a # NIL  THEN
			L := 0;  R := a.m;  (* поиск делением пополам *)
			WHILE  L < R  DO
				i := (L+R) DIV 2;
				IF  x <= a.e[ i ].key  THEN  R := i  ELSE  L := i+1  END
			END;
			IF  R = 0  THEN  q := a.p0  ELSE  q := a.e[ R-1 ].p  END;
			IF  (R < a.m) & (a.e[ R ].key = x)  THEN (* нашли *)
				IF  q = NIL  THEN (* a -- концевая страница *)
					DEC( a.m );  h := a.m < N;
					FOR  i := R  TO  a.m-1  DO  a.e[ i ] := a.e[ i+1 ]  END
				ELSE
					del( q, h );
					IF  h  THEN  underflow( a, q, R, h )  END
				END
			ELSE
				delete( x, q, h );
				IF  h  THEN  underflow( a, q, R, h )  END
			END
		END
	END delete;
	
	PROCEDURE ShowTree ( VAR W: Texts.Writer;  p: Page;  level: INTEGER );
		VAR  i: INTEGER;
	BEGIN
		IF  p # NIL  THEN
			FOR  i := 1  TO  level  DO  Texts.WriteTab( W )  END;
			FOR  i := 0  TO  p.m-1  DO  Texts.WriteInt( W, p.e[ i ].key, 4 )  END;
			Texts.WriteLn( W );
			IF  p.m > 0  THEN  ShowTree( W, p.p0, level+1 )  END;
			FOR  i := 0  TO  p.m-1  DO  ShowTree( W, p.e[ i ].p,  level+1 )  END
		END
	END ShowTree;
	(* конец фрагмента ******************************************)
	
	
	PROCEDURE Create*;
		VAR  S: Texts.Scanner;  h: BOOLEAN;  u: Entry;  q: Page;
	BEGIN
		root := NIL;
		
		Texts.OpenWriter( W, Texts.log, Texts.Length( Texts.log ) );
		Texts.WriteString( W, "создание Б-дерева **********" ); 
		Texts.WriteLn( W );  Texts.WriteLn( W );  
		
		Texts.OpenInput;  Texts.OpenScanner( S, Texts.input, 0 );
		Texts.Scan( S );
		WHILE  S.class = Texts.Int  DO
			Texts.WriteString( W, "*** " );  Texts.WriteInt( W, S.i, 4 );  Texts.WriteLn( W );  
			IF  S.i >= 0  THEN
				insert( S.i, root, h, u );
				IF  h  THEN  (* нужна новая корневая страница *)
					q := root;
					NEW( root );  root.m := 1;  root.p0 := q;  root.e[ 0 ] := u;
				END;
			ELSE
				ShowTree( W, root, 0 );  Texts.WriteLn( W );
			END;
			Texts.Scan( S );
		END;
	END Create;
	
	PROCEDURE Delete*;
		VAR  S: Texts.Scanner;  h: BOOLEAN;  u: Entry;
	BEGIN
		Texts.OpenWriter( W, Texts.log, Texts.Length( Texts.log ) );
		Texts.WriteString( W, "удаление элементов из Б-дерева **********" );
		Texts.WriteLn( W );  Texts.WriteLn( W );  
		
		Texts.OpenInput;  Texts.OpenScanner( S, Texts.input, 0 );
		Texts.Scan( S );
		WHILE  S.class = Texts.Int  DO
			Texts.WriteString( W, "*** " );  Texts.WriteInt( W, S.i, 4 );  Texts.WriteLn( W );  
			IF  S.i >= 0  THEN
				delete( S.i, root, h );
				IF  h  THEN  (*размер корневой страницы уменьшился *)
					IF  root.m = 0  THEN
						root := root.p0
					END;
				END;
			ELSE
				ShowTree( W, root, 0 );  Texts.WriteLn( W );
			END;
			Texts.Scan( S );
		END;
	END Delete;
	
END  ADruS471_Btrees.

Приводимые ниже команды воспроизводят рост и уменьшение Б-дерева на рисунках 4.45 и 4.46 соответственно.
Используются последовательности ключей, приводимые в тексте, но вместо символа «;» используется значение -1 для отметки точек, где делаются «снимки» текущего состояния дерева.

Создание Б-дерева, рис. 4.45:
ADruS471_Btrees.Create 20 -1  40  10  30  15 -1  35  7  26  18  22 -1  5 -1 42  13  46  27  8  32 -1  38  24  45  25 -1

Удаление элементов из того же Б-дерева, рис. 4.46:
ADruS471_Btrees.Delete  25  45  24 -1  38  32 -1  8  27  46  13  42 -1  5  22  18  26 -1  7  35  15 -1

