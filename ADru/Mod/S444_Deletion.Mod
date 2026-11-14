(*  Общие сведения о примерах: Справка *)
(*  Исправления и подготовка примеров: (С) Ф.В.Ткачев, 2009, info21 AT inr.ac.ru *)

MODULE  ADruS444_Deletion;  (* Удаление ключа из дерева, раздел 4.4.4. *)

	IMPORT  Log := StdLog,  In := i21sysIn,  Texts := ADruS174_Texts;
	
	TYPE
		Node = POINTER TO RECORD
			key, count: INTEGER;
			left, right: Node
		END;
	
	VAR  S: Texts.Scanner;  W: Texts.Writer;
		root: Node;  (* дерево, которое строится *)
	
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
	
	(* то, что выше, взято из ADruS443_Tree *)

	(* фрагмент из книги, с. 206: *************************************)
	PROCEDURE delete ( x: INTEGER;  VAR p: Node );
		PROCEDURE del ( VAR r: Node );
		BEGIN
			IF  r.right # NIL  THEN  del( r.right )      
			ELSE
				p.key := r.key;  p.count := r.count;             
				r := r.left 
			END
		END del;
	BEGIN (* удалить *)
		IF  p = NIL  THEN  (* слова в дереве нет, удалять нечего *)
		ELSIF  x < p.key  THEN  delete( x, p.left )
		ELSIF  x > p.key  THEN  delete( x, p.right )
		(* в каждой из трёх веток удалить p^: *)
		ELSIF  p.right = NIL  THEN  p := p.left
		ELSIF  p.left   = NIL  THEN  p := p.right
		ELSE  del( p.left )
		END
	END delete;
	(* конец фрагмента *******************************************)
	
	PROCEDURE Build*; (* Tree443.Do, переназвано *)
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
		PrintTree( root, 0 );
	END Build;
	
	PROCEDURE Delete*;
	BEGIN
		Texts.OpenWriter( W, Texts.log, Texts.Length( Texts.log ) );
		Texts.OpenInput;  Texts.OpenScanner( S, Texts.input, 0 );
		
		Texts.Scan( S );
		WHILE  S.class = Texts.Int  DO
			delete( S.i, root );
			PrintTree( root, 0 );
			Texts.Scan( S );
		END;
	END Delete;
	
END  ADruS444_Deletion.

Данные для воспроизведения картинок на рис. 4.28.
Клик по первому командиру строит дерево из чисел, показанных зеленым.
Клик по второму удаляет числа, показанные красным.

ADruS444_Deletion.Build 10 5 3 8 15 13 18 
ADruS444_Deletion.Delete 13 15 5 10 

Интересный случай:
ADruS444_Deletion.Build   10 5 3 8 7 12  
ADruS444_Deletion.Delete  10 

