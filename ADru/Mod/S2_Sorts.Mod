(*  Общие сведения о примерах: Справка *)
(*  Исправления и подготовка примеров: (С) Ф.В.Ткачев, 2009, info21 AT inr.ac.ru *)

MODULE  ADruS2_Sorts;
(* Алгоритмы сортировки массивов, разделы 2.2-2.3. *)

	IMPORT  Log := StdLog,  In := i21sysIn,  Math,  ObxRandom;
	TYPE  Item = INTEGER;

	(* сортируемый массив: *)
	VAR
		n: INTEGER;
		a: POINTER TO ARRAY (* n *) OF Item;
	
	PROCEDURE LogArray*;  (* печать массива в рабочий журнал *)
		VAR  i: INTEGER;
	BEGIN
		Log.String('n =');  Log.Int( n );  Log.Ln;
		FOR  i := 0  TO  n-1  DO  Log.Tab;  Log.Int( a[i] )  END;
		Log.Ln;
	END LogArray;
	
	PROCEDURE Test*;  (* проверка упорядоченности массива *)
		VAR  i: INTEGER;
	BEGIN
		i := 1;
		WHILE ( i < n ) & ( a[i-1] <= a[i] ) DO  INC( i )  END;
		Log.String('n =');  Log.Int( n );  Log.Ln;
		IF  i < n  THEN
			Log.String('массив не упорядочен: ');
			Log.Int( i-1 );  Log.Int( i );  Log.Int( a[i-1] );  Log.Int( a[i] );
			Log.Ln;
			HALT( 128 ); (*останов без трапа*)
		ELSE
			Log.String('массив упорядочен по возрастанию.');  Log.Ln;
		END;
	END Test;
	
	PROCEDURE Std8*;  (* инициализация сортируемого массива стандартной последовательностью, используемой Виртом *)
	BEGIN
		n := 8;  NEW( a, n );
		a[0] := 44;
		a[1] := 55;
		a[2] := 12;
		a[3] := 42;
		a[4] := 94;
		a[5] := 18;
		a[6] := 06;
		a[7] := 67;
		Log.String('Задан стандартный тестовый массив из 8 элементов.');  Log.Ln;
		LogArray
	END Std8;
	
	PROCEDURE Ordered*;
		VAR  i: INTEGER;
	BEGIN
		In.Open;  ASSERT( In.done );
		In.Int( n );  ASSERT( In.done );  ASSERT( n > 0 );
		NEW( a, n );
		FOR  i := 0  TO  n-1  DO  a[i] := i  END;
		Log.String('Задан упорядоченный массив, n =');  Log.Int( n );  Log.Ln;
	END Ordered;

	PROCEDURE Reversed*;
		VAR  i: INTEGER;
	BEGIN
		In.Open;     ASSERT( In.done );
		In.Int( n );  ASSERT( In.done );  ASSERT( n > 0 );
		NEW( a, n );
		FOR  i := 0  TO  n-1  DO  a[i] := n-i  END;
		Log.String('Задан массив, упорядоченный в обратном порядке, n =');  Log.Int( n );  Log.Ln;
	END Reversed;
	
	PROCEDURE Random*;
		VAR  i: INTEGER;
	BEGIN
		In.Open;     ASSERT( In.done );
		In.Int( n );  ASSERT( In.done );  ASSERT( n > 0 );
		NEW( a, n );
		FOR  i := 0  TO  n-1  DO
			a[i] := SHORT( ENTIER( n * ObxRandom.Uniform() ) )
		END;
		Log.String('Задан случайный массив, n =');  Log.Int( n );  Log.Ln;
	END Random;
	
	PROCEDURE InArray*;
		VAR  x, i: INTEGER;
	BEGIN
		In.Open;  ASSERT( In.done );
		In.Int( x );  i := 0;
		WHILE  In.done  DO
			INC( i );  In.Int( x );
		END;
		n := i;  NEW( a, n );
		
		In.Open;  ASSERT( In.done );
		In.Int( x );  i := 0;
		WHILE  In.done  DO
			a[ i ] := x;
			INC( i );  In.Int( x );
		END;
		
		Log.String('Массив введен из потока ввода:');  Log.Ln;
		LogArray
	END InArray;
	
	
	PROCEDURE StraightInsertion*; (* простые вставки, с. 74 **************)
		VAR  i, j: INTEGER;  x: Item;
	BEGIN
		FOR i := 1 TO n-1 DO
			x := a[i];  j := i;
			WHILE (j > 0) & (x < a[j-1]) DO
				a[j] := a[j-1];
				DEC(j)
			END;
			a[j] := x
		END
	END StraightInsertion;
	
	
	PROCEDURE BinaryInsertion*; (* двоичные вставки, с. 74 **************)
		VAR i, j, m, L, R: INTEGER; x: Item;
	BEGIN
		LogArray;
		FOR i := 1 TO n-1 DO
			x := a[i];  L := 0;  R := i;
			WHILE L < R DO
				m := (L+R) DIV 2;
				IF a[m] <= x THEN
					L := m+1
				ELSE
					R := m
				END
			END;
			FOR j := i TO R+1 BY -1 DO a[j] := a[j-1] END;
			a[R] := x;
			LogArray;
		END
	END BinaryInsertion;
	
	
	PROCEDURE StraightSelection*;  (* простой выбор, с. 76 ***************)
		VAR i, j, k: INTEGER;  x: Item;
	BEGIN
		FOR i := 0 TO n-2 DO
			k := i;  x := a[i];
			FOR j := i+1 TO n-1 DO
				IF a[j] < x THEN
					k := j; x := a[k]
				END
			END;
			a[k] := a[i]; a[i] := x
		END
	END StraightSelection;
	
	
	PROCEDURE BubbleSort*;  (* пузырек, с. 78 ************************)
		VAR i, j: INTEGER; x: Item;
	BEGIN
		FOR i := 1 TO n-1 DO
			FOR j := n-1 TO i BY -1 DO
				IF a[j-1] > a[j] THEN
					x := a[j-1];  a[j-1] := a[j];  a[j] := x
				END
			END
		END
	END BubbleSort;
	
	
	PROCEDURE ShakerSort*;  (* шейкер-сортировка, с. 79 ***************)
		VAR  j, k, L, R: INTEGER;  x: Item;
	BEGIN
		L := 1;  R := n-1;  k := R;
		REPEAT
			FOR j := R TO L BY -1 DO
				IF a[j-1] > a[j] THEN
					x := a[j-1];  a[j-1] := a[j];  a[j] := x;
					k := j
				END
			END;
			L := k+1;
			FOR j := L TO R BY +1 DO
				IF a[j-1] > a[j] THEN
					x := a[j-1];  a[j-1] := a[j];  a[j] := x;
					k := j
				END
			END;
			R := k-1
		UNTIL L > R
	END ShakerSort;
	
	
	PROCEDURE ShellSort*;  (* сортировка Шелла, с. 82 *****************)
		CONST  T = 4;
		VAR  i, j, k, m, s: INTEGER;
			x: Item; 
			h: ARRAY T OF INTEGER;
	BEGIN
		(* изменен порядок элементов h, чтоб легче увеличить T *)
		h[0] := 1;  h[1] := 3;  h[2] := 5;  h[3] := 9;
		
		FOR m := T-1 TO 0 BY -1 DO
			k := h[m];
			
			FOR i := k TO n-1 DO
				x := a[i];
				j := i-k;
				WHILE (j >= 0) & (x < a[j]) DO
					a[j+k] := a[j];
					j := j-k
				END;
				a[j+k] := x
			END
			
		END;
	END ShellSort;
	
	
	PROCEDURE sift(L, R: INTEGER);
		VAR i, j: INTEGER;  x: Item;
	BEGIN i := L; j := 2*i+1; x := a[i];
		IF (j < R) & (a[j] < a[j+1]) THEN j := j+1 END;
		WHILE (j <= R) & (x < a[j]) DO
			a[i] := a[j]; i := j; j := 2*j+1;
			IF (j < R) & (a[j] < a[j+1]) THEN j := j+1 END
		END;
		a[i] := x
	END sift;
	
	PROCEDURE HeapSort*;  (* турнирная сортировка, с.87 **************)
		VAR L, R: INTEGER;  x: Item;
	BEGIN L := n DIV 2; R := n-1;
		WHILE L > 0 DO DEC(L); sift(L, R) END;
		WHILE R > 0 DO
			x := a[0]; a[0] := a[R]; a[R] := x;
			DEC(R); sift(L, R)
		END
	END HeapSort;
	
	
	PROCEDURE sort ( L, R: INTEGER );
		VAR  i, j: INTEGER;  w, x: Item;
	BEGIN
		i := L;  j := R;
		x := a[(L+R) DIV 2];
		REPEAT
			WHILE  a[i] < x  DO  i := i+1  END;
			WHILE  x < a[j]  DO  j := j-1  END;
			IF  i <= j  THEN
				w := a[i];  a[i] := a[j];  a[j] := w;
				i := i+1;  j := j-1
			END
		UNTIL  i > j;
		IF  L < j  THEN sort(L, j) END;
		IF  i < R  THEN sort(i, R) END
	END sort;
	
	PROCEDURE QuickSort*;  (* быстрая сортировка, с.90 *******************)
	BEGIN  sort(0, n-1)
	END QuickSort;
	
	PROCEDURE NonRecursiveQuickSort*;  (* нерекурсивный вариант, с.90 ******)
		CONST M = 12;
		VAR  i, j, L, R, s: INTEGER;  x, w: Item;
			low, high: ARRAY M OF INTEGER; (*стек индексов*)
	BEGIN
		s := 0;  low[0] := 0;  high[0] := n-1;
		REPEAT (*взять верхний запрос со стека*)
			L := low[s];  R := high[s];  DEC(s);
			REPEAT (*разделить сегмент a[L] ... a[R]*)
				i := L;  j := R;  x := a[(L+R) DIV 2];
				REPEAT
					WHILE  a[i] < x  DO  INC(i)  END;
					WHILE  x < a[j]  DO  DEC(j)  END;
					IF  i <= j  THEN
						w := a[i];  a[i] := a[j];  a[j] := w;
						i := i+1;  j := j-1
					END
				UNTIL  i > j;
				IF  i < R  THEN (*сохранить в стеке запрос на сортировку правой части*)
					INC(s);  low[s] := i;  high[s] := R
				END;
				R := j  (*теперь L и R ограничивают левую часть*)
				(* часть, показанную синим, можно оптимизировать в соответствии с рассуждениями в тексте книги, см. ниже *)
			UNTIL L >= R
		UNTIL s < 0
	END NonRecursiveQuickSort;

	PROCEDURE NonRecursiveQuickSort2*;
		CONST M = 12;
		VAR  i, j, L, R, s: INTEGER;  x, w: Item;
			low, high: ARRAY M OF INTEGER; (*стек индексов*)
	BEGIN
		s := 0;  low[0] := 0;  high[0] := n-1;
		REPEAT (*взять верхний запрос со стека*)
			L := low[s];  R := high[s];  DEC(s);
			REPEAT (*разделить сегмент a[L] ... a[R]*)
				i := L;  j := R;  x := a[(L+R) DIV 2];
				REPEAT
					WHILE  a[i] < x  DO  INC(i)  END;
					WHILE  x < a[j]  DO  DEC(j)  END;
					IF  i <= j  THEN
						w := a[i];  a[i] := a[j];  a[j] := w;
						i := i+1;  j := j-1
					END
				UNTIL  i > j;

				(* чтобы уменьшить глубину стека, сохраняем туда больший сегмент,
					а сортируем меньший: *)
				IF  j - L < R - i  THEN
					IF  i < R  THEN  (*записать в стек запрос на сортировку правой части*)
						INC(s);  low[s] := i;  high[s] := R
					END;
					R := j  (*продолжать сортировкой левой части*)
				ELSE
					IF  L < j  THEN (*записать в стек запрос на сортировку левой части*)
						INC(s);  low[s] := L;  high[s] := j
					END;
					L := i  (*продолжать сортировкой правой части*)
				END

			UNTIL L >= R
		UNTIL s < 0
	END NonRecursiveQuickSort2;
	
	
	PROCEDURE Find ( k: INTEGER ); (* поиск k-го элемента из раздела 2.3.4, с. 94 *)
		(*переставить a так, чтобы a[k] стал k-м по возрастанию*)
		VAR L, R, i, j: INTEGER; w, x: Item;
	BEGIN
		L := 0; R := n-1;
		WHILE L < R-1 DO
			x := a[k]; i := L; j := R;
			REPEAT
				WHILE a[i] < x DO i := i+1 END;
				WHILE x < a[j] DO j := j-1 END;
				IF i <= j THEN
					w := a[i]; a[i] := a[j]; a[j] := w;
					i := i+1; j := j-1
				END
			UNTIL i > j;
			IF j < k THEN L := i END;
			IF k < i THEN R := j END
		END
	END Find;
	
	PROCEDURE Median*;
		VAR  k: INTEGER;
	BEGIN
		(* предполагаем, что массив a инициализирован *)
		In.Open;  ASSERT( In.done );  
		In.Int( k );  ASSERT( In.done & ( k >= 0 ) );
		Find( k );
		Log.Int( a[k] );  Log.Ln;		
	END Median;
	
END  ADruS2_Sorts.

Ниже приводятся команды для игр с сортировками массивов из разделов 2.2-2.3.
Обрабатываемый массив сохраняется в модуле, сортировки (и поиск медианы) работают прямо с этим массивом (in situ).
Первая группа команд -- различные способы задания исходного массива.
Вторая группа -- различные команды сортировки.
Третья группа -- вспомогательные команды (печать и проверка упорядоченности).

В командах имя модуля «покрашено» серым цветом (см. меню Атрибуты). Такая раскраска не влияет на работу команд, а только помогает лучше видеть имена вызываемых процедур.
В частности, чтобы посмотреть соотв. процедуры: двойной клик по имени процедуры, F4.)

1. Задание сортируемого массива
Каждый командир задает соответствующий массив.
Заданный массив распечатывается в рабочем журнале (окно Log).
После клика по любому командиру и переходить к командам сортировки.

ADruS2_Sorts.Std8	--стандартный 8-элементный массив из книги (таблица 2.1 и далее).
ADruS2_Sorts.Ordered 256	--упорядоченный массив из 256 элементов. Можно поменять число и снова кликнуть.
ADruS2_Sorts.Reversed 256	--массив из 256 элементов в обратном порядке
ADruS2_Sorts.Random 25	--случайный набор из 25 чисел
ADruS2_Sorts.InArray 13 23 75 234 34 1 22 93 99 2 6 
	--массив составляется из указанных чисел; можно менять числа, удалять, добавлять новые, потом просто кликнуть по круглому командеру.

2. Сортировки
Длинные вычисления можно останавливать нажатием Ctrl+Break. Если при этом Рабочий журнал (Log) станет серым, то его можно закрыть и снова открыть -- Info, Open Log,
Клик по каждому командеру вызывает сортировку соответствующим методом:
ADruS2_Sorts.StraightInsertion	--простые вставки, раздел 2.2.1.
ADruS2_Sorts.BinaryInsertion	--двоичные вставки, там же.
ADruS2_Sorts.StraightSelection	--простой выбор, раздел 2.2.2.
ADruS2_Sorts.BubbleSort	--пузырьковая, раздел 2.2.3.
ADruS2_Sorts.ShakerSort	--шейкер-сортировка, раздел 2.2.3.
ADruS2_Sorts.ShellSort	--сортировка Шелла, раздел 2.3.1.
ADruS2_Sorts.HeapSort	--турнирная сортировка, раздел 2.3.2.
ADruS2_Sorts.QuickSort	--быстрая сортировка Хоора, раздел 2.3.3.
ADruS2_Sorts.NonRecursiveQuickSort	--нерекурсивный вариант быстрой сортировки.
ADruS2_Sorts.NonRecursiveQuickSort2	--вариант с оптимизацией глубины стека.
ADruS2_Sorts.Median 4	--поиск k-го элемента по возрастанию, раздел 2.3.4; после вызова удобно отсортировать массив любым способом (кликнуть по любой сортировке) и распечатать командой ниже.

3. Проверки результата
Эти команды можно вызывать до и после сортировок, они не меняют массива:
ADruS2_Sorts.Test	--проверка, что получился упорядоченный массив.
ADruS2_Sorts.LogArray	--печать получившегося массива в рабочий журнал (Log).

Вызов нескольких команд одним кликом:
Последовательность команд оформляется как показано в примере.
Команды пишутся подряд через ; в порядке выполнения.
Все вместе заключаются в двойные кавычки.
Поток ввода -- всё, что стоит после закрывающей двойной кавычки до значка 
"ADruS2_Sorts.Random;
ADruS2_Sorts.QuickSort;
ADruS2_Sorts.Test;ADruS2_Sorts.LogArray"   55 
