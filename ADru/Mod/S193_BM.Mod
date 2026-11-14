(*  Общие сведения о примерах: Справка *)
(*  Исправления и подготовка примеров: (С) Ф.В.Ткачев, 2009, info21 AT inr.ac.ru *)

MODULE  ADruS193_BM;
(* Поиск в тексте. Алгоритм Бойера и Мура, раздел 1.9.3. *)
	IMPORT  Log := StdLog,  In := i21sysIn;
	
	CONST  Mmax = 10;  Nmax = 1000;
	VAR
		s: ARRAY Nmax OF CHAR;  N: INTEGER;
		p: ARRAY Mmax OF CHAR;  M: INTEGER;

	(* реализация предикатов, определенных в тексте на с. 63: *)
			
	PROCEDURE P ( i, j: INTEGER ): BOOLEAN;  
		VAR  k: INTEGER;
	BEGIN
		k := j;
		WHILE  ( k < M ) & ( s[ i-M+k ] = p[ k ] )  DO  INC( k )  END;
		RETURN  k = M
	END P;
	
	PROCEDURE R ( i: INTEGER ): BOOLEAN; 
		VAR  j: INTEGER;
	BEGIN
		RETURN  P( i, 0 )
	END R;
	
	PROCEDURE Q ( i: INTEGER ): BOOLEAN;
		VAR  k: INTEGER;
	BEGIN
		k := M;
		WHILE  ( k < i ) & ~R( k )  DO  INC( k )  END;
		RETURN  ~( k < i )
	END Q;
	
	(* фрагмент из книги, с.64: **************************************)
	
	PROCEDURE Search ( IN p, s: ARRAY OF CHAR;  M, N: INTEGER;  OUT r: INTEGER );
		(* поиск образца p длины M в тексте s длины N; M <= Mmax *)
		(* если p найден, то r указывает его позицию в s, иначе r = -1 *)
		VAR  i, j, k: INTEGER;
			d: ARRAY 128 OF INTEGER;
	BEGIN 
		FOR  i := 0  TO  127  DO  d[i] := M  END; 
		FOR  j := 0  TO  M-2  DO  d[ ORD( p[j] ) ] := M-j-1  END;

		(* инвариант цикла Q(i) & P(i-j,j); проверки (показаны красным) вставлены, для ясности с избытком, всюду, где инвариант должен выполняться *)
		i := M; j := M;  k := i;
		ASSERT( Q(i) & P(i, j) & (k = i-M+j) );
		LOOP IF  (j > 0) & (i <= N) & (s[k-1] = p[j-1])  THEN
			ASSERT( Q(i) & P(i, j) & (k = i-M+j) );
			DEC(k); DEC(j);
			ASSERT( Q(i) & P(i, j) & (k = i-M+j) );
		ELSIF  (j > 0) & (i <= N)  THEN
			ASSERT( Q(i) & P(i, j) & (k = i-M+j) );
			i := i + d[ ORD( s[i-1] ) ];  j := M;  k := i;
			ASSERT( Q(i) & P(i, j) & (k = i-M+j) );
		ELSE EXIT END END;
		ASSERT( Q(i) & P(i, j) & (k = i-M+j) );
		
		IF  j = 0  THEN  r := k  ELSE  r := -1  END;
	END Search;

	(* конец фрагмента *******************************************)
	
	PROCEDURE Test*;
		VAR  r: INTEGER;
	BEGIN
		Log.Ln;
		Log.String('Проверяем Бойера-Мура:');  Log.Ln;

		In.Open;  ASSERT( In.done );
		In.String( s );  ASSERT( In.done );  N := LEN( s$ );
		In.String( p );  ASSERT( In.done );  M := LEN( p$ );
		
		Search( p, s, M, N, r );
		
		Log.Int( r );  Log.Ln;
	END Test;
	
END  ADruS193_BM.


ADruS193_BM.Test 
	"Hoola-Hoola girls like Hooligans." "Hooligan"

или можно выделить любую строчку и кликнуть по командиру:
	"Hoola-Hoola girls like Hooligans." "H"
	"Hoola-Hoola girls like Hooligans." "o"
	"Hoola-Hoola girls like Hooligans." "gi"
	"Hoola-Hoola girls like Hooligans." "ns."
	"Hoola-Hoola girls like Hooligans." "gi"
	"Hoola-Hoola girls like Hooligans." "ooo"
	"baaab" "abab"	
	aahaahaa ahaah
