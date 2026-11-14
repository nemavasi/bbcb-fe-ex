(*  Общие сведения о примерах: Справка *)
(*  Исправления и подготовка примеров: (С) Ф.В.Ткачев, 2009, info21 AT inr.ac.ru *)

MODULE  ADruS24_MergeSorts;  (* Сортировки слияниями, раздел 2.4. *)

	IMPORT  Log := StdLog,  In := i21sysIn,  Dialog,
		Files := ADruS171_Files,  Texts := ADruS174_Texts,  Runs := ADruS242_Runs;
	
	TYPE Proc = PROCEDURE ( src: Files.File ): Files.File; (*для тестов*)
	
	TYPE  element = INTEGER;
	VAR
		N: INTEGER;
		a: POINTER TO ARRAY (* 2*N *) OF element;
	
	PROCEDURE InArray*;
		VAR  i, x: INTEGER;
	BEGIN
		In.Open;  ASSERT( In.done );
		i := 0;
		In.Int( x );
		WHILE  In.done  DO  INC( i );  In.Int( x )  END;
		ASSERT( i > 0 );
		N := i;
		NEW( a, 2*N );
		
		In.Open;  ASSERT( In.done );
		i := 0;
		In.Int( x );
		WHILE  In.done  DO  a[ i ] := x;  INC( i );  In.Int( x )  END;
	END InArray;
	
	PROCEDURE LogArray*;
		VAR  i: INTEGER;
	BEGIN
		Log.Ln;
		FOR  i := 0  TO  N-1  DO
			Log.Int( a[ i ] )
		END;
		Log.Ln;
	END LogArray;
	
	(* простые слияния, с. 101 *************************************)

	PROCEDURE StraightMerge*; 
		VAR  i, j, k, L, t: INTEGER;  (*диапазон индексов массива a is 0 .. 2*n-1 *)
			h, m, p, q, r: INTEGER;  up: BOOLEAN;
	BEGIN
		up := TRUE;  p := 1;
		REPEAT
			h := 1;  m := N;
			IF  up  THEN
				i := 0;  j := N-1;  k := N;  L := 2*N-1
			ELSE
				k := 0;  L := N-1;  i := N;  j := 2*N-1
			END;
			
			REPEAT (*слить по одной подпоследовательности из i- и j-источников в k-приемник *)
				q := MIN( p, m );  (* IF  m >= p  THEN  q := p  ELSE  q := m  END; *)
				m := m - q;
				r := MIN( p, m );   (* IF  m >= p  THEN  r := p  ELSE  r := m  END; *)
				m := m - r;
				WHILE ( q > 0 ) & ( r > 0 ) DO
					IF  a[ i ] < a[ j ]  THEN
						a[ k ] := a[ i ];  k := k+h;  i := i+1;  q := q-1
					ELSE
						a[ k ] := a[ j ];  k := k+h;  j := j-1;  r := r-1
					END
				END;
				WHILE  r > 0  DO
					a[ k ] := a[ j ];  k := k+h;  j := j-1;  r := r-1
				END;
				WHILE  q > 0  DO
					a[ k ] := a[ i ];  k := k+h;  i := i+1;  q := q-1
				END;
				h := -h;  t := k;  k := L;  L := t
			UNTIL  m = 0;
			
			up := ~up;  p := 2*p
		UNTIL  p >= N;
		
		IF  ~up  THEN
			FOR  i := 0  TO  N-1  DO  a[ i ] := a[ i+N ]  END
		END
	END StraightMerge;

	(* конец фрагмента *******************************************)	
	
	PROCEDURE RandomArray* ( n, seed: INTEGER );
		VAR  i: INTEGER;
	BEGIN
		N := n;
		NEW( a, 2*N );
		FOR i := 0 TO N-1 DO
			a[ i ] := seed;
			seed := (31*seed) MOD 997 + 5
		END;
	END RandomArray;
	
	
	(** Естественные слияния, с. 108 ********************************)
	
	PROCEDURE copyrun ( VAR x, y: Runs.Rider );
	BEGIN (*from x to y*)
		REPEAT Runs.copy( x, y ) UNTIL x.eor
	END copyrun;

	PROCEDURE NaturalMerge ( src: Files.File ): Files.File;
		VAR  L: INTEGER;  (*число серий после слияния*)
			f0, f1, f2: Files.File;
			r0, r1, r2: Runs.Rider;
	BEGIN
		Runs.Set( r2, src );
		REPEAT
			f0 := Files.New("test0");  Files.Set(r0, f0, 0);
			f1 := Files.New("test1");  Files.Set (r1, f1, 0);
			
			(*распределить из r2 в r0 и r1*) 
			REPEAT copyrun( r2, r0 );
				IF  ~r2.eof  THEN  copyrun( r2, r1 )  END
			UNTIL r2.eof;
			Runs.Set( r0, f0 );  Runs.Set( r1, f1 );
			f2 := Files.New("");  Files.Set( r2, f2, 0 );  L := 0;
			
			(*слить из r0 и r1 в r2*)
			REPEAT
				REPEAT
					IF  r0.first < r1.first  THEN
						Runs.copy( r0, r2 );
						IF  r0.eor  THEN  copyrun( r1, r2 )  END
					ELSE
						Runs.copy( r1, r2 );
						IF  r1.eor  THEN  copyrun( r0, r2 )  END;
					END
				UNTIL  r0.eor & r1.eor;
				
				INC( L )
			UNTIL  r0.eof OR r1.eof;
			WHILE  ~r0.eof  DO  copyrun( r0, r2 );  INC( L )  END;
			WHILE  ~r1.eof  DO  copyrun( r1, r2 );  INC( L )  END;
			
			Runs.Set( r2, f2 )
		UNTIL  L = 1;
		RETURN  f2
	END NaturalMerge;

	(* конец фрагмента *******************************************)	
	

	(** Сбалансированные слияния, с. 112 ****************************)
	
	PROCEDURE BalancedMerge ( src: Files.File ): Files.File;
		CONST  N = 3;
		VAR  i, j, m, tx: INTEGER;
			L, k1, k2, K1: INTEGER;
			min, x: INTEGER;
			t: ARRAY N OF INTEGER;  (*index map*)
			R: Runs.Rider;  (*source*)
			f, g:  ARRAY N OF Files.File;
			r, w: ARRAY N OF Runs.Rider;
	BEGIN
		Runs.Set( R, src );
		FOR  i := 0  TO  N-1  DO
			g[ i ] := Files.New("");
			Files.Set( w[ i ], g[ i ], 0 )
		END;
		
		(*распределить начальные серии из src по g[0] ... g[N-1]*)
		j := 0;  L := 0; 
		REPEAT
			REPEAT  Runs.copy( R, w[ j ] )  UNTIL  R.eor;
			INC( L ); INC( j );
			IF  j = N  THEN  j := 0  END
		UNTIL  R.eof;
		REPEAT
			IF  L < N  THEN  k1 := L  ELSE  k1 := N  END;
			K1 := k1;  (*число активных w[*]; k1 считает активные r[*]*)
			FOR  i := 0  TO  k1-1  DO  (*установить бегунки-источники*)
				Runs.Set( r[ i ], g[ i ] )
			END;
			FOR  i := 0  TO  k1-1  DO  (*установить бегунки-приемник*)
				g[ i ] := Files.New("");
				Files.Set( w[ i ], g[ i ], 0 )
			END;
			
			(*merge from r[0] ... r[k1-1] to w[0] ... w[K1-1]*)
			FOR  i := 0  TO  k1-1  DO  t[ i ] := i  END;
			L := 0;      (*число серий, созданных слияниями*)
			j := 0;
			REPEAT (*слить по одной серии из источников в w[j]*)
				INC( L );  k2 := k1;
				REPEAT
					(*выбрать наименьший ключ*)
					m := 0;  min := r[ t[ 0 ] ].first;  i := 1;
					WHILE  i < k2  DO
						x := r[ t[ i ] ].first;
						IF  x < min  THEN  min := x;  m := i  END;
						INC( i )
					END;
					
					Runs.copy( r[ t[ m ] ], w[ j ] );
					
					IF  r[ t[ m ] ].eof  THEN (*удалить последовательность*)
						DEC( k1 );  DEC( k2 );  t[ m ] := t[ k2 ];  t[ k2 ] := t[ k1 ]
					ELSIF  r[ t[ m ] ].eor  THEN (*закрыть серию*)
						DEC( k2 );  tx := t[ m ];  t[ m ] := t[ k2 ];  t[ k2 ] := tx
					END
				UNTIL  k2 = 0;
				INC( j );
				IF  j = K1  THEN  j := 0  END;
			UNTIL  k1 = 0
		UNTIL  L = 1;
		RETURN   g[ 0 ]
	END BalancedMerge;

	(* конец фрагмента *****************************************)	
		
	
	(** Многофазная сортировка, с. 121 ****************************)
	
	PROCEDURE Polyphase ( src: Files.File ): Files.File;  (*многофазная сортировка*)
		CONST  N = 6;
		VAR  i, j, mx, tn: INTEGER;
			k, dn, z, level: INTEGER;
			x, min: INTEGER;
			a, d:  ARRAY N OF INTEGER;
			t, ta:  ARRAY N OF INTEGER;  (*отображения индексов*)
			R: Runs.Rider;  (*входные данные*)
			f: ARRAY N OF Files.File;
			r: ARRAY N OF Runs.Rider;
	
		(*использована версия copyrun из NaturalMerge*)
		
		PROCEDURE select;  (*выбор*)
			VAR  i, z: INTEGER;
		BEGIN 
			IF d[ j ] < d[ j+1 ] THEN
				INC( j )
			ELSE
				IF d[ j ] = 0 THEN
					INC( level );  z := a[ 0 ];
					FOR  i := 0  TO  N-2  DO
						d[ i ] := z + a[ i+1 ] - a[ i ];
						a[ i ] := z + a[ i+1 ]
					END
				END;
				j := 0
			END;
			DEC( d[ j ] )
		END select;

	BEGIN
		Runs.Set( R, src );
		FOR i := 0 TO N-2 DO
			a[ i ] := 1;  d[ i ] := 1;
			f[ i ] := Files.New("");  Files.Set( r[ i ], f[ i ], 0 )
		END;
		
		(*распределить начальные серии*)
		level := 1;  j := 0;  a[ N-1 ] := 0;  d[ N-1 ] := 0; 
		REPEAT
			select;
			copyrun( R, r[ j ] )
		UNTIL  R.eof OR ( j = N-2 );
		
		WHILE  ~R.eof  DO
			select;  (* r[ j ].first = последний элемент, записанный в f[ j ] *)
			IF  r[ j ].first <= R.first  THEN
				copyrun( R, r[ j ] );
				IF  R.eof  THEN  INC( d[ j ] )
				               ELSE  copyrun( R, r[ j ] )  END
			ELSE
				copyrun( R, r[ j ] )
			END
		END;

		FOR  i := 0  TO  N-2  DO
			t[ i ] := i;  Runs.Set( r[ i ], f[ i ] )
		END;
		t[ N-1 ] := N-1;
		
		REPEAT (*слить из t[0] ... t[N-2] в t[N-1]*)
			z := a[ N-2 ];  d[ N-1 ] := 0;
			f[ t[ N-1 ] ] := Files.New("");  Files.Set( r[ t[ N-1 ] ], f[ t[ N-1 ] ], 0 );
			REPEAT
				k := 0;  (*создать слиянием одну серию*)
				FOR  i := 0  TO  N-2  DO
					IF  d[i] = 0  THEN
						ta[ k ] := t[ i ];  INC( k )
					ELSE
						DEC( d[ i ] )
					END
				END;
				IF  k = 0  THEN
					INC( d[ N-1 ] )
				ELSE (*создать одну реальную серию слиянием из t[0] ... t[k-1] в t[N-1]*)
					REPEAT  mx := 0;  min := r[ ta[ 0 ] ].first;  i := 1;
						WHILE  i < k  DO
							x := r[ ta[ i ] ].first;
							IF  x < min  THEN  min := x;  mx := i  END;
							INC( i )
						END;
						Runs.copy( r[ ta[ mx ] ], r[ t[ N-1 ] ] );
						IF  r[ ta[ mx ] ].eor  THEN
							ta[ mx ] := ta[ k-1 ];  DEC( k )
						END
					UNTIL  k = 0
				END;
				DEC( z )
			UNTIL  z = 0;
			
			Runs.Set( r[ t[ N-1] ], f[ t[ N-1 ] ] );   (*ротация последовательностей*)
			tn := t[N-1];  dn := d[N-1];  z := a[N-2];
			FOR  i := N-1  TO  1  BY  -1  DO
				t[ i ] := t[ i-1 ];  d[ i ] := d[ i-1 ];  a[ i ] := a[ i-1 ] - z
			END;
			t[ 0 ] := tn;  d[ 0 ] := dn;  a[ 0 ] := z;  DEC( level )
		
		UNTIL  level = 0 ;
		
		RETURN f[ t[ 0 ] ]
	END Polyphase;

	(* конец фрагмента ******************************************)	
	
	
	PROCEDURE Distribute ( src: Files.File ): Files.File;   (* c. 126 ****************)
		CONST  M = 16;  mh = M DIV 2;  (* размер пирамиды *)
		VAR  L, R: INTEGER;
			x: INTEGER;
			dest: Files.File;
			r, w: Files.Rider;
			H: ARRAY M OF INTEGER;  (* пирамида *)
		
		PROCEDURE sift ( L, R: INTEGER );
			VAR  i, j, x: INTEGER;
		BEGIN
			i := L;  j := 2*L+1;  x := H[ i ];
			IF  ( j < R ) & ( H[ j ] > H[ j+1 ] )  THEN  INC( j )  END;
			WHILE  ( j <= R ) & ( x > H[ j ] )  DO
				H[ i ] := H[ j ];  i := j;  j := 2*j+1;
				IF  ( j < R ) & ( H[ j ] > H[ j+1 ] )  THEN  INC( j )  END
			END;
			H[ i ] := x
		END sift;
	
	BEGIN
		Files.Set( r, src, 0 );  dest := Files.New("");  Files.Set( w, dest, 0 );
	(* шаг 1: заполнить верхнюю половину пирамиды *)
		L := M;
		REPEAT  DEC( L );  Files.ReadInt( r, H[ L ] )  UNTIL  L = mh;
	(* шаг 2: заполнить нижнюю половину пирамиды *)
		REPEAT  DEC( L );  Files.ReadInt( r, H[ L ] );  sift( L, M-1 )  UNTIL  L = 0;
		
		IF  r.eof  THEN
			Dialog.ShowMsg( 'слишком короткая последовательность на входе' );  HALT(128)
		END;
	(* шаг 3: пропустить элементы сквозь пирамиду *)
		L := M;  Files.ReadInt( r, x );
		WHILE  ~r.eof  DO
			Files.WriteInt( w, H[0] );
			IF  H[ 0 ] <= x  THEN
				(* x принадлежит той же серии *)  H[ 0 ] := x;  sift( 0, L-1 )
			ELSE
				(* начать новую серию *)
				DEC( L );  H[ 0 ] := H[ L ];  sift( 0, L-1 );  H[ L ] := x;
				IF  L < mh  THEN  sift( L, M-1 )  END;
				IF  L = 0  THEN (* пирамида полна; начать новую серию *)  L := M  END
			END;
			Files.ReadInt( r, x )
		END;
	(* шаг 4: сброс нижней половины пирамиды *)
		R := M;
		REPEAT  DEC( L );  Files.WriteInt( w, H[ 0 ] );
			H[ 0 ] := H[ L ];  sift( 0, L-1 );  DEC( R );  H[ L ] := H[ R ];
			IF  L < mh  THEN  sift( L, R-1 )  END
		UNTIL  L = 0;
	(* шаг 5: сброс верхней половины пирамиды, начать новую серию *)
		WHILE R > 0 DO
			Files.WriteInt(w, H[0]); H[0] := H[R]; DEC(R); sift(0, R)
		END;
		RETURN dest
	END Distribute;

	(* конец фрагмента ******************************************)	
	
	
	(* команды тестирования *)
	
	PROCEDURE TestStraightlMerge*;
		VAR  n, seed: INTEGER;
	BEGIN
		Log.Ln;
		Log.String('Тестируем сортировку простыми слияниями (StraightMerge): ');
		Log.Ln;
		In.Open;     ASSERT( In.done );  
		In.Int( n );  ASSERT( In.done );
		In.Int( seed );  ASSERT( In.done );
		
		RandomArray( n, seed );
		Log.String('исходная последовательность: ');  Log.Ln;
		LogArray;
		StraightMerge;
		Log.Ln;  Log.String('последовательность после сортировки: ');  Log.Ln;
		LogArray;
	END TestStraightlMerge;

	PROCEDURE Do ( p: Proc;  s: ARRAY OF CHAR );
		VAR  n, seed: INTEGER;  old, new: Files.File;  wr: Texts.Writer;
	BEGIN
		Log.Ln;  Log.String(s);  Log.Ln;
		In.Open;	ASSERT( In.done );
		In.Int( n );	ASSERT( In.done );
		In.Int( seed );	ASSERT( In.done );
		old := Files.New('old');
		Runs.OpenRandomSeq( old, n, seed );
		Log.String('исходная последовательность, по сериям: ');  Log.Ln;
		Runs.LogSeq( old );  (* как выглядели серии в исходной последовательности *)
		new := p( old );
		Log.Ln;  Log.String('последовательность после обработки (после знака $ печатается длина последовательности и количество серий минус 1): ');  Log.Ln;
		Runs.LogSeq( new );
	END Do;

	PROCEDURE TestNaturalMerge*;
	BEGIN
		Do( NaturalMerge, 'Тестируем сортировку естественными слияниями (NaturalMerge): ');
	END TestNaturalMerge;
	
	PROCEDURE TestBalancedMerge*;
	BEGIN
		Do( BalancedMerge, 'Тестируем сортировку сбалансированными слияниями (BalancedMerge): ');
	END TestBalancedMerge;
	
	PROCEDURE TestPolyphase*;
	BEGIN
		Do( Polyphase, 'Тестируем многофазную сортировку слияниями (Polyphase): ');
	END TestPolyphase;
	
	PROCEDURE TestDistribute*;
	BEGIN
		Do( Distribute, 'Тестируем процедуру распределения начальных серий посредством фильтрации сквозь пирамиду: ');
	END TestDistribute;
	
END ADruS24_MergeSorts.


Все тесты производятся по одной общей схеме: 
-- генерится последовательность случайных чисел заданной длины (первое число из пары),
-- сгенеренная последовательность печатается в рабочий журнал (Log),
-- к ней применяется соответствующая процедура;
-- получившаяся последовательность распечатывается.

Для прогона теста кликнуть по соответствующему черному командиру :
Простые слияния, раздел 2.4.1:
ADruS24_MergeSorts.TestStraightlMerge  12 1

Естественные слияния, раздел 2.4.2:
ADruS24_MergeSorts.TestNaturalMerge  12 1

Сбалансированные слияния, раздел 2.4.3:
ADruS24_MergeSorts.TestBalancedMerge  12 1

Многофазная сортировка, раздел 2.4.4:
ADruS24_MergeSorts.TestPolyphase  12 1

Распределение начальных серий, раздел 2.4.5; в конце последовательность распечатывается, чтобы показать получившиеся серии:
ADruS24_MergeSorts.TestDistribute  50 1

После команд указана пара чисел. Их можно менять:
Первое число -- определяет длину сортируемой последовательности.
Второе число -- затравка (seed) для генератора случайных чисел (разные затравки дают разные последовательности).
Эту пару чисел можно брать из другого места -- для этого достаточно перед кликом выделить нужную пару, например, вот в этой строчке:
12  314 ~ 91  314 ~ 1112  314 

Еще способ проверки сортировки простыми слияниями.
Сортируемый массив задается непосредственно в потоке ввода, результат печатается в рабочий журнал (Log):
"ADruS24_MergeSorts.InArray;
ADruS24_MergeSorts.StraightMerge;
ADruS24_MergeSorts.LogArray"  44 55 12 42 94 18 06 67 
