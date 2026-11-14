(*  Общие сведения о примерах: Справка *)
(*  Исправления и подготовка примеров: (С) Ф.В.Ткачев, 2009, info21 AT inr.ac.ru *)

MODULE  ADruS443_Tree;  (* Поиск и вставка в двоичном дереве, раздел 4.4.3. *)
	IMPORT  Log := StdLog,  In := i21sysIn,  Texts := ADruS174_Texts;
	
	TYPE
		Node = POINTER TO RECORD
			key, count: INTEGER;
			left, right: Node
		END;
	
	VAR  S: Texts.Scanner;  W: Texts.Writer;
		root: Node;  (* дерево, которое строится *)
		sentinel: Node; (* барьер *)
	
	
	(* фрагмент из книги, с. 201: ***********************************)
	PROCEDURE PrintTree ( t: Node;  h: INTEGER);
		VAR  i: INTEGER;
	BEGIN
		(* распечатать дерево t с h отступами *)  
		IF  t # NIL  THEN     
			PrintTree( t.left, h+1 );
			FOR  i := 1  TO  h  DO
				Texts.WriteTab( W )
			END;
			Texts.WriteInt( W, t.key, 6 );  Texts.WriteLn( W );
			PrintTree( t.right, h+1 )
		END
	END PrintTree;

	PROCEDURE search ( x: INTEGER;  VAR p: Node );
	BEGIN      
		IF p = NIL THEN (* x в дереве нет; вставить *) 
			NEW( p );  p.key := x;   p.count := 1;   p.left := NIL;   p.right := NIL      
		ELSIF  x < p.key  THEN  search( x, p.left )
		ELSIF  x > p.key  THEN  search( x, p.right )
		ELSE  INC( p.count )
		END
	END search;
	(* конец фрагмента *******************************************)
	
	PROCEDURE Do*;
	BEGIN
		root := NIL;
		(* будем читать из входного потока после командира 
			(точнее, из потока, определяемого по правилам i21sysIn) *)
		Texts.OpenInput;  Texts.OpenScanner( S, Texts.input, 0 );
		
		(* собственно вычисления: *)
		Texts.Scan( S );
		WHILE  S.class = Texts.Int  DO
			search( S.i, root );
			Texts.Scan( S );
		END;
		
		Texts.OpenWriter( W, Texts.log, Texts.Length( Texts.log ) );
		Texts.WriteTab( W );  Texts.WriteLn( W );
		PrintTree( root, 0 );
	END Do;
	
	(* то же с барьером *)
	
	PROCEDURE PrintTree2 ( t: Node;  h: INTEGER );
		VAR  i: INTEGER;
	BEGIN
		(* распечатать дерево t с h отступами *)  
		IF  t # sentinel  THEN     
			PrintTree2( t.left, h+1 );
			FOR  i := 1  TO  h  DO
				Texts.WriteTab( W )
			END;
			Texts.WriteInt( W, t.key, 6 );  Texts.WriteLn( W );
			PrintTree2( t.right, h+1 )
		END
	END PrintTree2;

	PROCEDURE search2 ( x: INTEGER;  VAR p: Node ); (* то же, но с барьером, с. 202 *)
	BEGIN   
		IF       x < p.key  THEN  search2( x, p.left )
		ELSIF  x > p.key  THEN  search2( x, p.right )
		ELSIF  p # sentinel  THEN  INC( p.count )
		ELSE (* вставить *)
			NEW( p );         
			p.key := x;  p.left := sentinel;  p.right := sentinel;  p.count := 1   
		END
	END search2;

	PROCEDURE Do2*;
	BEGIN
		NEW( sentinel );  root := sentinel;
		(* будем читать из входного потока после командира 
			(точнее, из потока, определяемого по правилам i21sysIn) *)
		Texts.OpenInput;  Texts.OpenScanner( S, Texts.input, 0 );
		
		(* собственно вычисления: *)
		Texts.Scan( S );
		WHILE  S.class = Texts.Int  DO
			sentinel.key := S.i;
			search2( S.i, root );
			Texts.Scan( S );
		END;
		
		Texts.OpenWriter( W, Texts.log, Texts.Length( Texts.log ) );
		Texts.WriteTab( W );  Texts.WriteLn( W );
		PrintTree2( root, 0 );
	END Do2;
	
END  ADruS443_Tree.


ADruS443_Tree.Do	8  9  11  15  19  20  21  7  3  2  1  5  6  4  13  14  10  12  17  16  18~
ADruS443_Tree.Do2	8  9  11  15  19  20  21  7  3  2  1  5  6  4  13  14  10  12  17  16  18~

пролистать Log вниз