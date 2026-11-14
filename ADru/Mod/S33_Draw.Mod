(*  Общие сведения о примерах: Справка *)
(*  Исправления и подготовка примеров: (С) Ф.В.Ткачев, 2009, info21 AT inr.ac.ru *)

MODULE  ADruS33_Draw;  (* Эмуляция модуля Draw, описанного в разделе 3.3, с. 138 книги Н.Вирта «Алгоритмы и структуры данных. Новая версия для Оберона», 2009. *)

	IMPORT  Views,  Ports,  Properties,  Windows;

	TYPE
		View = POINTER TO RECORD ( Views.View ) END;
		Pos = RECORD
			x, y: INTEGER
		END;
	
		Element = POINTER TO ABSTRACT RECORD
			next: Element
		END;
		
		ElLine = POINTER TO RECORD ( Element )
			start, finish: Pos;
			thick: BOOLEAN;
		END;
		
		UpdateMsg = RECORD ( Views.Message ) END;
		
	CONST  width* = 512;  height* = 512;
	
	VAR  v: View;
		pen: Pos;
		first, last: Element;
		msg: UpdateMsg;
		thick: BOOLEAN;
	
	
	PROCEDURE PixelSize ( f: Ports.Frame ): INTEGER;
		VAR  res: INTEGER;
	BEGIN
		res := MAX( f.unit, 9525 ); (* на экране в пикселях, при печати в неких условных единицах, чтобы не было слишком мелко *)
		RETURN  res
	END PixelSize;
	
	PROCEDURE ( el: Element ) Draw ( f: Ports.Frame ), NEW, ABSTRACT;
	
	PROCEDURE ( el: ElLine ) Draw ( f: Ports.Frame );
		VAR  ps: INTEGER;  s: INTEGER;
	BEGIN
		ps := PixelSize( f );
		IF  el.thick  THEN
			s := 2*ps
		ELSE
			s := 0
		END;
		
		f.DrawLine( 
			ps * el.start.x,  ps * (height - el.start.y), 
			ps * el.finish.x, ps * (height - el.finish.y), 
			s, Ports.black 
		)
	END Draw;
	
	PROCEDURE ( v: View ) Restore ( f: Views.Frame;  l, t, r, b: INTEGER );
		VAR  el: Element;  ps: INTEGER;
	BEGIN
		ps := PixelSize( f );
		el := first;
		WHILE  el # NIL  DO
			el.Draw( f );
			el := el.next
		END
	END Restore;
	
	PROCEDURE ( v: View ) HandlePropMsg- ( VAR p: Properties.Message );
	BEGIN
		WITH  p: Properties.ResizePref  DO
			p.horFitToWin := TRUE;
			p.verFitToWin := TRUE
		ELSE
		END;
	END HandlePropMsg;

	PROCEDURE ( v: View ) HandleViewMsg- ( f: Views.Frame;  VAR p: Views.Message );
	BEGIN
		WITH  p: UpdateMsg  DO
			v.Restore( f, 0, 0, MAX(INTEGER), MAX(INTEGER) )
		ELSE
		END;
	END HandleViewMsg;

	PROCEDURE Include ( el: Element );
	BEGIN
		ASSERT( el.next = NIL, 20 );
		IF  first = NIL  THEN
			first := el
		ELSE
			last.next := el
		END;
		last := el;
		Views.Update( v, Views.keepFrames );
	END Include;
	
	
	PROCEDURE SetPen* ( x, y: INTEGER );
		VAR  
	BEGIN
		ASSERT( x >= 0, 20 );
		ASSERT( y >= 0, 21 );
		pen.x := x;
		pen.y := y;
	END SetPen;
	
	PROCEDURE NextThick*;
		VAR  
	BEGIN
		thick := TRUE
	END NextThick;
	
	PROCEDURE LineTo ( pos: Pos );
		VAR  l: ElLine;
	BEGIN
		NEW( l );
		l.start := pen;
		l.finish := pos;
		l.thick := thick;
		Include( l );
		thick := FALSE;
		SetPen( pos.x, pos.y )
	END LineTo;
	
	PROCEDURE line* ( dir, len: INTEGER );
	(* нарисовать линию длины len в направлении dir*45 градусов; передвинуть перо соответственно *)
		VAR  new: Pos;
	BEGIN
		ASSERT( ( dir >= 0 ) & ( dir < 8 ), 20 );
		new := pen;
		
		IF      ( dir = 0 ) OR ( dir = 1 ) OR ( dir = 7 ) THEN  INC( new.x, len )
		ELSIF ( dir = 3 ) OR ( dir = 4 ) OR ( dir = 5 ) THEN  DEC( new.x, len )
		END;
		
		IF      ( dir = 1 ) OR ( dir = 2 ) OR ( dir = 3 ) THEN  INC( new.y, len )
		ELSIF ( dir = 5 ) OR ( dir = 6 ) OR ( dir = 7 ) THEN  DEC( new.y, len )
		END;
		
		(* draw from pen to new *)
		LineTo( new )
	END line;
	

	PROCEDURE Init;
	BEGIN
		first := NIL;  last := NIL;  thick := FALSE;
	END Init;
	
	PROCEDURE Open;
	BEGIN  Views.OpenView( v );  Views.Update( v, Views.keepFrames )
	END Open;
	
	PROCEDURE Clear*;  (* clear drawing plane *)
	BEGIN  Init;  Views.Omnicast( msg )
	END Clear;
	
	
	PROCEDURE Close;
		VAR  w: Windows.Window;  
	BEGIN
		w := Windows.dir.First();
		WHILE  ( w # NIL ) & ( w.doc.ThisView() # v ) DO
			w := Windows.dir.Next( w )
		END;
		IF  w # NIL  THEN
			Windows.dir.Close( w )
		END;
	END Close;
	
	PROCEDURE Test*;
		VAR  
	BEGIN
		SetPen( 0, 0 );  line( 1, 20 );
		SetPen( 40, 40 );  line( 1, 20 );
		SetPen( 80, 80 );  line( 1, 40 )
	END Test; (* ADruS33_Draw.Test *)
	
BEGIN
	Init;  NEW( v );  Open;
CLOSE
	Close
END  ADruS33_Draw.
