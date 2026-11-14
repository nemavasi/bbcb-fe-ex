(*  Общие сведения о примерах: Справка *)
(*  Исправления и подготовка примеров: (С) Ф.В.Ткачев, 2009, info21 AT inr.ac.ru *)

MODULE  ADruS48_PrioritySearchTrees;  (* Приоритетные деревья поиска, раздел 4.8. *)

	IMPORT  Log := StdLog,  In := i21sysIn,  Texts := ADruS174_Texts;
	
	CONST  min = 0;  max = 1000;
	
	TYPE  (* определение типа, с. 249 *)
		Node = POINTER TO RECORD
			x, y: INTEGER;
			left, right: Node
		END;
		
	VAR  root: Node;
	
	PROCEDURE report ( x, y: INTEGER );
	BEGIN
		Log.Int( x );  Log.Int( y );  Log.Ln;
	END report;
	
	(* фрагмент из книги, с. 249: ************************************)
	PROCEDURE insert (VAR p: Node;  X, Y, xL, xR: INTEGER );
		VAR  xm, t: INTEGER;
	BEGIN
		IF  p = NIL  THEN (* нет в дереве, вставить *)
			NEW( p );  p.x := X;  p.y := Y;  p.left := NIL;  p.right := NIL
		ELSIF  p.x = X  THEN (* найден; не вставлять *) 
		ELSE
			IF  p.y > Y  THEN
				t := p.x;  p.x := X;  X := t;
				t := p.y;  p.y := Y;  Y := t
			END;
			xm := ( xL + xR ) DIV 2;
			IF  X < xm  THEN  insert ( p.left,   X, Y, xL, xm )
			ELSE                    insert ( p.right, X, Y, xm, xR )
			END
		END
	END insert;
	(* конец фрагмента ****************************************)

	(* фрагмент из книги, с. 250: *********************************)
	PROCEDURE enumerate ( p: Node;  x0, x1, y1, xL, xR: INTEGER );
		VAR  xm: INTEGER;
	BEGIN
		IF  p # NIL  THEN
			IF ( p.y <= y1 ) & ( x0 <= p.x ) & ( p.x < x1 ) THEN
				report( p.x, p.y )
			END;
			xm := ( xL + xR ) DIV 2;
			IF  x0 < xm  THEN  enumerate ( p.left,   x0, x1, y1, xL, xm )  END;
			IF  xm < x1  THEN  enumerate ( p.right, x0, x1, y1, xm, xR )  END
		END
	END enumerate;
	(* конец фрагмента ****************************************)
	
	PROCEDURE Create*;
		VAR  x, y: INTEGER;
	BEGIN
		In.Open;  In.Int( x );
		WHILE  In.done  DO
			In.Int( y );         Log.Tab;  Log.Int( x );  Log.Tab;  Log.Int( y );  Log.Ln;
			insert( root, x, y, min, max );
			In.Int( x );
		END;
		
	END Create;
	
	PROCEDURE List*;
		VAR  x0, x1, y1: INTEGER;
	BEGIN
		In.Open;  In.Int( x0 );  In.Int( x1 );  In.Int( y1 );
		enumerate( root, x0, x1, y1, min, max ) 
	END List;
END  ADruS48_PrioritySearchTrees.


ADruS48_PrioritySearchTrees.Create
	1	100
	10	999
	230	87
	23	876
	999	8754
	888	1
	99	88
	111	111


ADruS48_PrioritySearchTrees.List  10 200 200

