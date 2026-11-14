(*  Общие сведения о примерах: Справка *)
(*  Исправления и подготовка примеров: (С) Ф.В.Ткачев, 2009, info21 AT inr.ac.ru *)

MODULE  ADruS441_BalancedTree;  (* Построение идеально сбалансированного дерева, раздел 4.4.1. *)

	IMPORT  Log := StdLog,  In := i21sysIn,  Texts := ADruS174_Texts;
	
	(* фрагмент из книги, с. 196: ******************************)
	TYPE
		Node = POINTER TO RECORD
			key: INTEGER;
			left, right: Node          
		END;
	
	VAR  R: Texts.Reader;  W: Texts.Writer;  root: Node;

	PROCEDURE Tree ( n: INTEGER ): Node;
		VAR  new: Node;
			x, nl, nr: INTEGER;
	BEGIN
		(* построить идеально сбалансированное дерево с n узлами *)
		IF  n = 0  THEN
			new := NIL
		ELSE
			nl := n DIV 2;  nr := n-nl-1;
			NEW( new );  Texts.ReadInt( R, x );
			new.key := x;  new.left := Tree( nl );  new.right := Tree( nr )
		END;
		RETURN new 
	END Tree;

	PROCEDURE PrintTree ( t: Node;  h: INTEGER );
		VAR  i: INTEGER;
	BEGIN
		(* распечатать дерево t с h отступами *)
		IF  t # NIL  THEN
			PrintTree( t.left, h+1 );
			FOR  i := 1  TO  h  DO  Texts.WriteTab( W )  END;
			Texts.WriteInt( W, t.key, 3 );  Texts.WriteLn( W );
			PrintTree( t.right, h+1 )
		END
	END PrintTree;
	(* конец фрагмента **************************************)
	
	PROCEDURE Do*;
		VAR  root: Node;
	BEGIN
		(* приготовление ввода-вывода: *)
		Texts.OpenWriter( W, Texts.log, Texts.Length( Texts.log ) );
		(* будем читать из входного потока после командира 
			(точнее, из потока, определяемого по правилам i21sysIn) *)
		Texts.OpenInput;  Texts.OpenReader( R, Texts.input, 0 );
		
		(* собственно вычисления: *)
		root := Tree( 21 );
		PrintTree( root, 0 );
	END Do;
	
END  ADruS441_BalancedTree.

ADruS441_BalancedTree.Do 8  9  11  15  19  20  21  7  3  2  1  5  6  4  13  14  10  12  17  16  18 
