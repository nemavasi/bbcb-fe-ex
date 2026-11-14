(*  Общие сведения о примерах: Справка *)
(*  Исправления и подготовка примеров: (С) Ф.В.Ткачев, 2009, info21 AT inr.ac.ru *)

MODULE  ADruS45_AVLtrees;  (* Алгоритмы для АВЛ-деревьев, раздел 4.5. *)
(* На основе ADruS444_Deletion. *)

	IMPORT  Log := StdLog,  In := i21sysIn,  Texts := ADruS174_Texts;
	
	TYPE
		Node = POINTER TO RECORD
			key, count, bal: INTEGER;  (* bal = -1, 0, +1 *)
			left, right: Node
		END;
	
	VAR  S: Texts.Scanner;  W: Texts.Writer;
		root: Node;  (* дерево, которое строится *)
	
	PROCEDURE PrintTree ( t: Node;  h: INTEGER);
		VAR  i: INTEGER;
	BEGIN
		(* распечатать дерево t с h отступами *)  
		IF  t # NIL  THEN
			(* left <> right , чтобы легче сравнивать с картинкой *)
			PrintTree( t.right, h+1 );
			FOR  i := 1  TO  h  DO
				Texts.WriteTab( W )
			END;
			Texts.WriteInt( W, t.key, 6 );  Texts.WriteLn( W );
			PrintTree( t.left, h+1 )
		END
	END PrintTree;

	
	(* фрагмент из книги, с. 214: ***********************************)
	PROCEDURE search ( x: INTEGER;  VAR p: Node;  VAR h: BOOLEAN );
		VAR  p1, p2: Node;  (* ~h *)
	BEGIN
		IF  p = NIL  THEN (* вставка *)
			NEW( p );  h := TRUE;
			p.key := x;  p.count := 1;  p.left := NIL;  p.right := NIL;  p.bal := 0  
		ELSIF  p.key > x  THEN
			search( x, p.left, h );    
			IF  h  THEN  (* выросла левая ветвь *)
				IF       p.bal = 1  THEN  p.bal := 0;  h := FALSE      
				ELSIF  p.bal = 0  THEN  p.bal := -1      
				ELSE (* bal = -1, восстановить баланс *)
					p1 := p.left;           
					IF  p1.bal = -1  THEN  (* одинарная LL-ротация *)
						p.left := p1.right;  p1.right := p;             
						p.bal := 0;  p := p1           
					ELSE (* двойная LR-ротация *)
						p2 := p1.right;             
						p1.right := p2.left;    p2.left   := p1;             
						p  .left   := p2.right;  p2.right := p;             
						IF  p2.bal = -1   THEN  p.bal  := 1    ELSE  p.bal   := 0  END;             
						IF  p2.bal = +1  THEN  p1.bal := -1  ELSE  p1.bal := 0  END;             
						p := p2
					END;           
					p.bal := 0; h := FALSE      
				END    
			END  
		ELSIF  p.key < x  THEN
			search( x, p.right, h );
			IF  h  THEN  (* выросла правая ветвь *)
				IF  p.bal = -1  THEN  p.bal := 0;  h := FALSE      
				ELSIF  p.bal = 0  THEN  p.bal := 1
				ELSE (* bal = +1, восстановить баланс *)  p1 := p.right;           
					IF  p1.bal = 1  THEN  (*одинарная RR-ротация*)
						p.right := p1.left;  p1.left := p;
						p.bal := 0;  p := p1           
					ELSE (* двойная RL-ротация *) p2 := p1.left;
						p1.left := p2.right;  p2.right := p1;
						p.right := p2.left;  p2.left := p;             
						IF  p2.bal = +1  THEN  p .bal  := -1 ELSE  p  .bal := 0  END;             
						IF  p2.bal =  -1  THEN  p1.bal :=  1  ELSE  p1.bal := 0  END;             
						p := p2
					END;
					p.bal := 0;  h := FALSE
				END    
			END  
		ELSE
			INC( p.count )
		END
	END search;
	(* конец фрагмента *******************************************)

	PROCEDURE Build*; (* из TreeDeletion444.Do *)
		VAR  h: BOOLEAN;
	BEGIN
		root := NIL;
		Texts.OpenWriter( W, Texts.log, Texts.Length( Texts.log ) );
		Texts.WriteLn( W );  Texts.WriteLn( W );
		
		Texts.OpenInput;  Texts.OpenScanner( S, Texts.input, 0 );
		Texts.Scan( S );
		WHILE  S.class = Texts.Int  DO
			search( S.i, root, h );  PrintTree( root, 0 );  Texts.WriteLn( W );  Texts.WriteLn( W );
			Texts.Scan( S );
		END;
	END Build;
	
	(* фрагмент из книги, с. 217: ************************************)
	PROCEDURE balanceL ( VAR p: Node;  VAR h: BOOLEAN );  
		VAR  p1, p2: Node;
	BEGIN (* h; уменьшилась левая ветвь *)
		IF p.bal = -1 THEN
			p.bal := 0  
		ELSIF p.bal = 0 THEN
			p.bal := 1; h := FALSE
		ELSE (* bal = 1, восстановить баланс *)
			p1 := p.right;
			IF p1.bal >= 0 THEN  (* одинарная RR-ротация *)
				p.right := p1.left; p1.left := p;
				IF p1.bal = 0 THEN p.bal := 1; p1.bal := -1; h := FALSE
				ELSE p.bal := 0; p1.bal := 0
				END;
				p := p1
			ELSE  (* двойная RL-ротация *)
				p2 := p1.left;
				p1.left := p2.right; p2.right := p1;
				p.right := p2.left; p2.left := p;
				IF p2.bal = +1 THEN p.bal := -1 ELSE p.bal := 0 END;
				IF p2.bal = -1 THEN p1.bal := 1 ELSE p1.bal := 0 END;
				p := p2; p2.bal := 0
			END
		END
	END balanceL;

	PROCEDURE balanceR ( VAR p: Node;  VAR h: BOOLEAN );
		VAR  p1, p2: Node;
	BEGIN (* h; уменьшилась правая ветвь *)
		IF p.bal = 1 THEN
			p.bal := 0
		ELSIF p.bal = 0 THEN
			p.bal := -1; h := FALSE
		ELSE (* bal = -1, восстановить баланс *)
			p1 := p.left;   
			IF p1.bal <= 0 THEN  (* одинарная LL-ротация *)         
				p.left := p1.right; p1.right := p;
				IF p1.bal = 0 THEN p.bal := -1; p1.bal := 1; h := FALSE
				ELSE p.bal := 0; p1.bal := 0
				END;
				p := p1
			ELSE  (* двойная LR-ротация *)
				p2 := p1.right;
				p1.right := p2.left; p2.left := p1;
				p.left := p2.right; p2.right := p;
				IF p2.bal = -1 THEN p.bal := 1 ELSE p.bal := 0 END;
				IF p2.bal = +1 THEN p1.bal := -1 ELSE p1.bal := 0 END;
				p := p2; p2.bal := 0
			END  
		END
	END balanceR;
	
	PROCEDURE delete ( x: INTEGER;  VAR p: Node;  VAR h: BOOLEAN );  
		VAR q: Node;

		PROCEDURE del ( VAR r: Node;  VAR h: BOOLEAN );
		BEGIN (* ~h *)
			IF r.right # NIL THEN      
				del( r.right, h );
				IF h THEN balanceR( r, h ) END    
			ELSE
				q.key := r.key; q.count := r.count;      
				q := r; r := r.left; h := TRUE    
			END 
		END del;
	
	BEGIN (* ~h *)
		IF p = NIL THEN (* ключа нет в дереве *)
		ELSIF p.key > x THEN    
			delete( x, p.left, h );    
			IF h THEN balanceL( p, h ) END  
		ELSIF p.key < x THEN
			delete( x, p.right, h );    
			IF h THEN balanceR( p, h ) END  
		ELSE (* удалить p^ *) 
			q := p;
			IF q.right = NIL THEN p := q.left; h := TRUE    
			ELSIF q.left = NIL THEN p := q.right; h := TRUE    
			ELSE
				del( q.left, h );
				IF h THEN balanceL( p, h ) END    
			END
		END
	END delete;
	(* конец фрагмента ******************************************)
	
	PROCEDURE Delete*;
		VAR  h: BOOLEAN;
	BEGIN
		Texts.OpenWriter( W, Texts.log, Texts.Length( Texts.log ) );
		Texts.OpenInput;  Texts.OpenScanner( S, Texts.input, 0 );
		
		Texts.Scan( S );
		WHILE  S.class = Texts.Int  DO
			delete( S.i, root, h );
			PrintTree( root, 0 );  Texts.WriteLn( W );  Texts.WriteLn( W );
			Texts.Scan( S );
		END;
	END Delete;
	
END  ADruS45_AVLtrees.

Пример рис. 4.34
ADruS45_AVLtrees.Build  4 5 7 2 1 3 6 

Еще два примера
ADruS45_AVLtrees.Build 10 5 3 8 15 13 18 
ADruS45_AVLtrees.Build   10 5 3 8 7 12  

Пример с удалением узлов, рис. 4.35.
Первый командир строит дерево, второй удаляет:
ADruS45_AVLtrees.Build 5 3 8 2 4 7 10 1 6 9 11 
ADruS45_AVLtrees.Delete 4 8 6 5 2 1 7 

пролистать вниз Log