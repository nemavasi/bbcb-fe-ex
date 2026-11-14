(*  Общие сведения о примерах: Справка *)
(*  Исправления и подготовка примеров: (С) Ф.В.Ткачев, 2009, info21 AT inr.ac.ru *)

MODULE  ADruS192_KMP;
(* Поиск в тексте. Алгоритм Кнута, Морриса и Пратта, раздел 1.9.2. *)
	IMPORT  Log := StdLog,  In := i21sysIn,  Math;
	
	CONST  Mmax = 10;  Nmax = 1000;
	VAR
		s: ARRAY Nmax OF CHAR;  N: INTEGER;
		p: ARRAY Mmax OF CHAR;  M: INTEGER;
	
	(* реализация предикатов, определенных в тексте: *)
			
	PROCEDURE R ( i: INTEGER ): BOOLEAN;  (*** с. 56 ***)
		VAR  j: INTEGER;
	BEGIN
		(* 0 <= i < N *)
		j := 0;
		WHILE (j < M) & (p[j] = s[i+j]) DO INC(j) END;
		RETURN ~(j < M)
	END R;
	
	PROCEDURE Q ( i: INTEGER ): BOOLEAN;
		VAR  k: INTEGER;
	BEGIN
		k := 0;
		WHILE  ( k < i ) & ~R( k )  DO  INC( k )  END;
		RETURN  ~( k < i )
	END Q;
	
	PROCEDURE P ( i, j: INTEGER ): BOOLEAN;
		VAR  k: INTEGER;
	BEGIN
		k := 0;
		WHILE  ( k < j ) & ( s[ i+k ] = p[ k ] )  DO  INC( k )  END;
		RETURN  ~( k < j )
	END P;
	
	
	PROCEDURE EqHold ( j, D: INTEGER ): BOOLEAN; 
	(* проверка выполнения уравнения сc. 60, 62 *)
		VAR  k: INTEGER;
	BEGIN
		ASSERT( ( j >= 0 ) & ( D >= 0 ), 20 );
		k := 0;
		WHILE  ( k < D ) & ( p[k] = p[j-D+k] )  DO
			INC( k )
		END;
		RETURN  ( D = 0 ) OR ( k = D )
	END EqHold;
	
	PROCEDURE D ( j: INTEGER ): INTEGER;
	(* прямое вычисление величины D, используемой в тексте, 
		-- прямым поиском решения уравнения (см. с. 62) *)
		VAR  d: INTEGER;
	BEGIN
		d := j - 1;
		WHILE  ( d >= 0 ) & ~( EqHold( j, d ) & ( p[d] # p[j] ) )  DO
			DEC( d )
		END;
		RETURN  d
	END D;
	
	(* фрагмент из книги, с.62: *************************************)

	PROCEDURE Search ( IN p, s: ARRAY OF CHAR; M, N: INTEGER; OUT r: INTEGER );
		(* поиск образца p длины M в тексте s длины N; M <= Mmax *)
		(* если p найден, то r указывает его позицию в s, иначе r = -1 *)
		(*  *)
		VAR  i, j, k: INTEGER;
			d: ARRAY Mmax OF INTEGER;
	BEGIN
		(* вычислить d из p *)
		d[0] := -1;  
		IF  p[0] # p[1]  THEN  d[1] := 0  ELSE  d[1] := -1  END;  ASSERT( d[1] = D(1) );
		j := 1;  k := 0;
		LOOP IF (j < M-1) & (k >= 0) & (p[j] # p[k]) THEN
			k := d[k]
		ELSIF j < M-1 THEN (* (k < 0) OR (p[j] = p[k]) *)
			INC( j );  INC( k );
			IF p[j] # p[k] THEN d[j] := k ELSE d[j] := d[k] END;  ASSERT( d[j] = D(j) );
		ELSE EXIT END END;
		(* собственно поиск; проверки инварианта цикла P(i-j,j) показаны красным всюду, где инвариант должен выполняться *)
		i := 0;  j := 0;
		ASSERT( P(i-j, j) );
		LOOP IF  (j < M) & (i < N) & (j >= 0) & (s[i] # p[j])  THEN
			ASSERT( P(i-j, j) );
			j := d[j];
			ASSERT( P(i-j, j) );
		ELSIF  (j < M) & (i < N)  THEN
			ASSERT( P(i-j, j) );
			INC(i);  INC(j);
			ASSERT( P(i-j, j) );
		ELSE  EXIT  END;  END;
		ASSERT( P(i-j, j) );
		
		IF  j = M  THEN
			r := i-M
		ELSE
			r := -1;
		END
	END Search;
	
	(* конец фрагмента ********************************************)
	
	PROCEDURE Test*;
		VAR  r: INTEGER;
	BEGIN
		Log.Ln;
		Log.String('Проверяем Кнута-Морриса-Пратта:');  Log.Ln;

		In.Open;  ASSERT( In.done );
		In.String( s );  ASSERT( In.done );  N := LEN( s$ );
		In.String( p );  ASSERT( In.done );  M := LEN( p$ );
		
		Search( p, s, M, N, r );
		Log.Int( r );  Log.Ln;
	END Test;
	
END  ADruS192_KMP.

ADruS192_KMP.Test 
	"Hoola-Hoola girls like Hooligans." "Hooligan"

или можно выделить любую строчку и кликнуть по командиру:
	"Hoola-Hoola girls like Hooligans." "H"
	"Hoola-Hoola girls like Hooligans." "o"
	"Hoola-Hoola girls like Hooligans." "gi"
	"Hoola-Hoola girls like Hooligans." "ns."
	"Hoola-Hoola girls like Hooligans." "ooo"
	"baaab" "abab"	
	aahaahaa ahaah
