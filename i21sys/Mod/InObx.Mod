MODULE  i21sysInObx;	(** правки  
- 20110330, ТЕЭ, Модуль переименован i21sysInПримеры -> i21sysInObx

Автор: ТФВ
**)
(* info21 2006-03-01; last modification 2010-04-01 *)
	IMPORT  In := i21sysIn,  Log := StdLog;
	
	PROCEDURE Do*;
		VAR  x: REAL;  n: INTEGER;  s: ARRAY 1000 OF CHAR;
	BEGIN
		In.Open; 	ASSERT( In.done );  Log.Ln;
		In.Real( x );	ASSERT( In.done );  Log.Real( x );
		In.Int( n ); 	ASSERT( In.done );  Log.Int( n );
		In.String( s ); 	ASSERT( In.done );  Log.String( s );
		Log.Ln
	END Do;
	
	PROCEDURE Do2* ( m: INTEGER );
		VAR  x: REAL;  n: INTEGER;  s: ARRAY 1000 OF CHAR;
	BEGIN
		Log.Ln;
		Log.Int( m );
		In.Open;	ASSERT( In.done );
		In.Real( x );	ASSERT( In.done );  Log.Real( x );
		In.Int( n );	ASSERT( In.done );  Log.Int( n );
		In.String( s ); 	ASSERT( In.done );  Log.String( s );
		Log.Ln
	END Do2;
	
	PROCEDURE DoRu*;
		VAR  s: ARRAY 1000 OF CHAR;
	BEGIN
		In.Open; 	ASSERT( In.done );  Log.Ln;
		In.String( s );	ASSERT( In.done );  Log.String( s );
		Log.Ln
	END DoRu;
	
	PROCEDURE Copy2; (* копируем два числа из уже открытого потока ввода в Рабочий журнал *)
		VAR  n: INTEGER;
	BEGIN
		ASSERT( In.done );
		In.Int( n );  ASSERT( In.done );  Log.Int( n );
		In.Int( n );  ASSERT( In.done );  Log.Int( n );
		Log.Ln;
	END Copy2;
	
	PROCEDURE TestRestart*;
	BEGIN
		In.Restart;  ASSERT( In.done );
		Copy2;
		In.Restart;  ASSERT( In.done );
		Copy2;
	END TestRestart;

	PROCEDURE TestRestartOpen*;
		VAR  n: INTEGER;
	BEGIN
		In.Restart;  ASSERT( In.done );
		Copy2;
		In.Open;  ASSERT( In.done );
		Copy2;
		In.Restart;  ASSERT( In.done );
		Copy2;
	END TestRestartOpen;

END  i21sysInObx.

Общие замечания см. здесь, а полное описание возможностей модуля i21sysIn — в документации. 

Примеры использования средств модуля i21sysIn

При первых кликах по коммандерам следить, чтобы в тексте не было фрагментов, выделенных мышкой:

простейший пример ввода данных:
i21sysInObx.Do 3.14 137 " цепочка литер"

пример ввода данных с одновременной передачей параметра:
"i21sysInObx.Do2(88)" 3.14 137 " цепочка литер"

два вызова подряд читают один и тот же поток данных:
"i21sysInObx.Do2(99);i21sysInObx.Do2(88)" 3.14 137 " цепочка литер"

Чтобы увидеть, как читать данные, выделенные мышкой, 
выделить мышкой следующие данные и кликнуть по тем же коммандерам:   2.14 2345 " другая цепочка"

Можно поменять данные или значения параметров и снова покликать.

Примеры работы с потоком данных, определяемым отдельно

Выделить мышкой два числа  14 13 (эти числа могут находиться и в другом текстовом окне)
и нажать Shift+F1 (предполагается, что на эту горячую клавишу "посажена" команда i21sysIn.Open).

Затем, убедившись, что в данном окне нет выделенных фрагментов (при необходимости кликнув в любую точку текста), кликнуть по этому коммандеру:
i21sysInObx.TestRestart 5 6
должно напечататься:
 14 13
 14 13
потому что процедура TestRestart использует уже открытый поток данных, где бы они ни находились (т.е. не вызывает i21sysIn.Open, а только i21sysIn.Restart).

Затем кликнуть по 
i21sysInObx.TestRestartOpen 5 6
должно напечататься
14 13
 5 6
 5 6
Это эффект переопределения входного потока из-за вызова Open в процедуре TestRestartOpen.

Снова выделить мышкой два числа  14 13  и нажать Shift+F1.
Затем выделить мышкой  7 8  и кликнуть по 
i21sysInObx.TestRestartOpen 5 6
должно напечататься
 14 13
 7 8
 7 8

В самом деле, так как на момент выполнения Open в переднем окне выделен текст (числа 7 8), то именно этот текст и станет с этого момента новым потоком ввода.

