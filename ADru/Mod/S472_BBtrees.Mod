(*  Общие сведения о примерах: Справка *)
(*  Исправления и подготовка примеров: (С) Ф.В.Ткачев, 2009, info21 AT inr.ac.ru *)

MODULE  ADruS472_BBtrees;  (* Симметричные двоичные Б-деревья (СДБ-деревья), раздел 4.7.2. *)

	IMPORT  Log := StdLog,  In := i21sysIn,  Texts := ADruS174_Texts;
	
	TYPE
		Node = POINTER TO NodeDesc;
		NodeDesc = RECORD
			key, count: INTEGER;
			L, R: Node; 
			lh, rh: BOOLEAN
		END;
	
	VAR  root: Node;  W: Texts.Writer;
	
	(* фрагмент из книги, с. 245: ***********************************)
	PROCEDURE search ( VAR p: Node;  x: INTEGER;  VAR h: INTEGER );
		VAR q, r: Node;
	BEGIN (* h=0 *)
		IF  p = NIL  THEN (* вставить новый узел *)
			NEW( p );  p.key := x;
			p.L := NIL;   p.lh := FALSE;
			p.R := NIL;  p.rh := FALSE;  
			h := 2;
		ELSIF  x < p.key  THEN
			search( p.L, x, h );
			IF  h > 0  THEN  (* левая ветвь выросла или получила «брата» *)
				q := p.L;
				IF  p.lh  THEN
					h := 2;  p.lh := FALSE;
					IF  q.lh  THEN (* LL *)
						p.L := q.R;  q.lh := FALSE;  q.R := p;  p := q
					ELSE (* q.rh, LR *)
						r := q.R;  q.R := r.L;  q.rh := FALSE;  r.L := p.L;  p.L := r.R;  r.R := p;  p := r
					END
				ELSE
					DEC( h );
					IF  h = 1  THEN  p.lh := TRUE  END
				END
			END
		ELSIF  x > p.key  THEN
			search( p.R, x, h );
			IF  h > 0  THEN  (* левая ветвь выросла или получила «брата» *)
				q := p.R;
				IF  p.rh  THEN
					h := 2;  p.rh := FALSE;
					IF  q.rh  THEN (* RR *)
						p.R := q.L;  q.rh := FALSE;  q.L := p;  p := q
					ELSE (* q.lh, RL *)
						r := q.L;  q.L := r.R;  q.lh := FALSE;  r.R := p.R;  p.R := r.L;  r.L := p;  p := r
					END
				ELSE
					DEC( h );
					IF  h = 1  THEN  p.rh := TRUE  END
				END
			END
		END
	END search;
	
	PROCEDURE ShowTree ( VAR W: Texts.Writer;  n: Node;  level: INTEGER );
		VAR  i: INTEGER;
	BEGIN
		IF  n # NIL  THEN
			IF  n.R # NIL  THEN
				IF  n.rh  THEN
					ShowTree( W, n.R, level )
				ELSE
					ShowTree( W, n.R, level+1 )
				END
			END;
			FOR  i := 1  TO  level  DO  Texts.WriteTab( W )  END;
			Texts.WriteInt( W, n.key, 4 );  Texts.WriteLn( W );
			IF  n.L # NIL  THEN
				IF  n.lh  THEN
					ShowTree( W, n.L, level )
				ELSE
					ShowTree( W, n.L, level+1 )
				END
			END
		END
	END ShowTree;
	(* конец фрагмента *******************************************)
	
	PROCEDURE Create*;
		VAR  S: Texts.Scanner;  h: INTEGER;  q: Node;
	BEGIN
		root := NIL;
		
		Texts.OpenWriter( W, Texts.log, Texts.Length( Texts.log ) );
		Texts.WriteString( W, "создание Б-дерева **********" ); 
		Texts.WriteLn( W );  Texts.WriteLn( W );  
		
		Texts.OpenInput;  Texts.OpenScanner( S, Texts.input, 0 );
		Texts.Scan( S );
		WHILE  S.class = Texts.Int  DO
			Texts.WriteString( W, "*** " );  Texts.WriteInt( W, S.i, 4 );  Texts.WriteLn( W );  
			IF  S.i >= 0  THEN
				search( root, S.i, h );
			ELSE
				ShowTree( W, root, 0 );  Texts.WriteLn( W );
			END;
			Texts.Scan( S );
		END;
	END Create;
	
END  ADruS472_BBtrees.

Последовательности вставок на рис. 4.50:

(1) ADruS472_BBtrees.Create	1	2	-1	3	-1	4	5	6	-1	7	-1

(2) ADruS472_BBtrees.Create	5	4	-1	3	-1	1	2	7	6	-1

(3) ADruS472_BBtrees.Create	6	2	-1	4	-1	1	7	3	5	-1

(4) ADruS472_BBtrees.Create	4	2	6	-1	1	7	-1	3	5	-1

