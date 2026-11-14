(*  Общие сведения о примерах: Справка *)
(*  Исправления и подготовка примеров: (С) Ф.В.Ткачев, 2009, info21 AT inr.ac.ru *)

MODULE  ADruS46_OptTree;  (* Оптимальные деревья, раздел 4.6. *)

	IMPORT  Log := StdLog,  In := i21sysIn,  Texts := ADruS174_Texts;
	
	(* фрагмент из книги, с. 224: ***********************************)
	CONST
		N = 100; (* макс. число ключевых слов *)
		WordLen = 16; (* макс. длина ключа *)
	
	VAR
		key: ARRAY N+1, WordLen OF CHAR;
		a, b: ARRAY N+1 OF INTEGER;
		p, w, r: ARRAY N+1, N+1 OF INTEGER;
	
	VAR  S: Texts.Scanner;  W: Texts.Writer;
	
	PROCEDURE BalTree ( i, j: INTEGER ): INTEGER;
		VAR  k: INTEGER;
	BEGIN
		k := (i+j+1) DIV 2;  r[i, j] := k;
		IF  i >= j  THEN  RETURN 0
		ELSE  RETURN  BalTree( i, k-1 ) + BalTree( k, j ) + w[ i, j ]
		END
	END BalTree;
	
	PROCEDURE ComputeOptTree ( n: INTEGER );
		VAR  x, min, tmp: INTEGER;
			i, j, k, h, m: INTEGER;
	BEGIN
		(*аргумент: w, результаты: p, r*)
		FOR  i := 0  TO  n  DO  p[ i, i ] := 0  END;
		FOR  i := 0  TO  n-1  DO
			j := i+1;  p[ i, j ] := w[ i, j ];  r[ i, j ] := j
		END;
		FOR  h := 2  TO  n  DO
			FOR  i := 0  TO  n-h  DO
				j := i+h;  m := r[ i, j-1 ];  min := p[ i, m-1 ] + p[ m, j ];
				FOR  k := m+1  TO  r[ i+1, j ]  DO
					tmp := p[ i, k-1 ];  x := p[ k, j ] + tmp;
					IF  x < min  THEN  m := k;  min := x  END
				END;
				p[ i, j ] := min + w[ i, j ];  r[ i, j ] := m
			END
		END
	END ComputeOptTree;
	
	PROCEDURE WriteTree ( i, j, level: INTEGER );
		VAR  k: INTEGER;  (* для вывода используется глобальный объект W *)
	BEGIN
		IF  i < j  THEN
			WriteTree( i, r[ i, j ]-1, level+1 );
			FOR  k := 1  TO  level  DO  Texts.WriteTab( W )  END;
			Texts.WriteString( W, key[ r[ i, j ] ] );  Texts.WriteLn( W );
			WriteTree( r[ i, j ], j, level+1 )
		END
	END WriteTree;

	PROCEDURE Find ( VAR S: Texts.Scanner );
		VAR  i, j, n: INTEGER;  (*используется глобальный W*)
	BEGIN
		(* ввод данных *)
		Texts.Scan( S );  b[ 0 ] := SHORT( S.i );
		n := 0;  Texts.Scan( S ); (* ввод: a, ключ, b *)
		WHILE  S.class = Texts.Int  DO
			INC( n );
			a	[ n ] := SHORT( S.i );	Texts.Scan( S );
			key	[ n ] := S.s$;	Texts.Scan( S );  (* COPY( S.s, key[ n ] );*)
			b	[ n ] := SHORT( S.i );	Texts.Scan( S )
		END;
		
		(* вычислить w из a и b *)
		FOR  i := 0  TO  n  DO
			w[ i, i ] := b[ i ];
			FOR  j := i+1  TO  n  DO
				w[ i, j ] := w[ i, j-1 ] + a[ j ] + b[ j ]
			END
		END;
		Texts.WriteString( W, "Полный вес = " );
		Texts.WriteInt( W, w[ 0, n ], 6 );  Texts.WriteLn( W );
		Texts.WriteString( W, "Длина путей сбалансированного дерева = ");
		Texts.WriteInt( W, BalTree( 0, n ), 6 );  Texts.WriteLn( W );
		WriteTree( 0, n, 0 );  Texts.WriteLn( W );
		
		ComputeOptTree( n );
		Texts.WriteString( W, "Длина путей оптимального дерева = " );
		Texts.WriteInt( W, p[ 0, n ], 6 );  Texts.WriteLn( W );
		WriteTree( 0, n, 0 );  Texts.WriteLn( W );
		
		FOR  i := 0  TO  n  DO
			w[ i, i ] := 0;
			FOR  j := i+1  TO  n  DO  w[ i, j ] := w[ i, j-1 ] + a[ j ]  END
		END;
		ComputeOptTree( n );
		Texts.WriteString( W, "оптимальное дерево без учета  b");  Texts.WriteLn( W );
		WriteTree( 0, n, 0 ); Texts.WriteLn( W )
	END Find;
	(* конец фрагмента *****************************************)
	
	PROCEDURE Do*;
	BEGIN
		Texts.OpenInput;  Texts.OpenScanner( S, Texts.input, 0 );
		Texts.OpenWriter( W, Texts.log, Texts.Length( Texts.log ) );
		Find( S )
	END Do;
	
END  ADruS46_OptTree.

ADruS46_OptTree.Do 	20 	1 Albert  10  2 Ernst  1  5 Peter  1  
