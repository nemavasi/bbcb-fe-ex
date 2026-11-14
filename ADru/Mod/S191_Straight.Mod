(*  Общие сведения о примерах: Справка *)
(*  Исправления и подготовка примеров: (С) Ф.В.Ткачев, 2009, info21 AT inr.ac.ru *)

MODULE  ADruS191_Straight; 
(* Поиск в тексте. Простой алгоритм, раздел 1.9.1. *)

	IMPORT  Log := StdLog,  In := i21sysIn;
	
	CONST  Mmax = 1000;
	
	(* для упрощения примеров данные реализованы в глобальных переменных: *)
	
	VAR  p, s: ARRAY Mmax OF CHAR;  M, N: INTEGER;
	
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
	
	(* Ниже в двух процедурах реализованы оба варианта простого поиска из раздела 1.9.1:
		1) простейший -- в виде линейного поиска с использованием предиката R;
		2) через цикл Дейкстры (см. в книге Приложение С). 
	Переменные p, s, M, N определены как глобальные, чтобы предикаты выглядели попроще, как в книге *)
	
	PROCEDURE Simplest* ( OUT r: INTEGER );
	(* Поиск образца p длины M в тексте s длины N; M <= Mmax.
		Если p найден, то r указывает его позицию в s, иначе r = -1.
		Все данные определены как глобальные переменные в начале модуля. *)
		VAR  i: INTEGER;
	BEGIN
		(* фрагмент из книги, с. 56: ***********************************)
		i := 0;
		WHILE (i <= N-M) & ~R(i) DO INC(i) END;
		(* конец фрагмента *****************************************)
		
		IF  i <= N-M  THEN
			r := i
		ELSE
			r := -1
		END;
	END Simplest;
	
	PROCEDURE DejkstraLoop* ( OUT r: INTEGER );
	(* То же, что Простейший, но реализация с помощью цикла Дейкстры;
		см. в книге Приложение С. 
	*)
		VAR  i, j: INTEGER;
	BEGIN
		(* фрагмент из книги, с. 57; в целях иллюстрации красным вставлены проверки инварианта цикла в начале и конце каждой ветви: ***************)
		i := 0;  j := 0;
		ASSERT( P(i,j) );
		LOOP IF (i <= N-M) & (j < M) & (s[i+j] = p[j]) THEN  (* о цикле Дейкстры см. Приложение С *)
			ASSERT( P(i,j) );
			INC( j );
			ASSERT( P(i,j) );
		ELSIF (i <= N-M) & (j < M) THEN
			ASSERT( P(i,j) );
			INC( i );  j := 0;
			ASSERT( P(i,j) );
		ELSE EXIT END END;
		ASSERT( P(i,j) );
		(* конец фрагмента ********************************************)

		(* обработка окончания цикла *)
		IF  i <= N-M  THEN
			r := i
		ELSE
			r := -1
		END;
	END DejkstraLoop;
	
	PROCEDURE Test*;
		VAR  r0, r1: INTEGER;
	BEGIN
		In.Open;	ASSERT( In.done );
		In.String( s );	ASSERT( In.done );
		N := LEN( s$ );
		In.String( p );	ASSERT( In.done );
		M := LEN( p$ );

		Simplest ( r0 );
		DejkstraLoop ( r1 );
		ASSERT( r0 = r1 );

		Log.Int( r0 );  Log.Ln;
	END Test;
	
END  ADruS191_Straight.

ADruS191_Straight.Test "Hoola-Hoola girls like Hooligans." "Hooligan"
	"Hoola-Hoola girls like Hooligans." "Hooligan"

или можно выделить любую строчку и кликнуть по командиру:
	"Hoola-Hoola girls like Hooligans." "H"
	"Hoola-Hoola girls like Hooligans." "o"
	"Hoola-Hoola girls like Hooligans." "gi"
	"Hoola-Hoola girls like Hooligans." "ns."
	"Hoola-Hoola girls like Hooligans." "ooo"
	"baaab" "abab"	
	aahaahaa ahaah
