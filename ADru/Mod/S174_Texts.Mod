(*  Общие сведения о примерах: Справка *)
(*  Исправления и подготовка примеров: (С) Ф.В.Ткачев, 2009, info21 AT inr.ac.ru *)

MODULE  ADruS174_Texts;  (* Эмуляция модуля Texts.
Копия интерфейса, данного в книге, сc. 48-49:

DEFINITION Texts;
	CONST Int = 1; Real = 2; Name = 3; Char = 4;
	TYPE Text, Writer;
		Reader = RECORD eot: BOOLEAN END;
		Scanner = RECORD class: INTEGER;
			i: INTEGER;
			x: REAL;
			s: ARRAY 32 OF CHAR;
			ch: CHAR;
			nextCh: CHAR
		END;
	PROCEDURE OpenReader(VAR r: Reader; t: Text; pos: INTEGER);
	PROCEDURE OpenWriter(VAR w: Writer; t: Text; pos: INTEGER);
	PROCEDURE OpenScanner(VAR s: Scanner; t: Text; pos: INTEGER);
	PROCEDURE Read(VAR r: Reader; VAR ch: CHAR);
	PROCEDURE Scan(VAR s: Scanner);
	PROCEDURE Write(VAR w: Writer; ch: CHAR);
	PROCEDURE WriteLn(VAR w: Writer);    (*завершить строку*)
	PROCEDURE WriteString(VAR w: Writer; s: ARRAY OF CHAR);
	PROCEDURE WriteInt(VAR w: Writer; x, n: INTEGER);
		(*вывести целое x с (по крайней мере) n литерами.
			Если n больше, чем необходимое число цифр, 
			перед числом добавляются пробелы*)
	PROCEDURE WriteReal(VAR w: Writer; x: REAL);
	PROCEDURE Close(VAR w: Writer);
END Texts. 

*)
	
	IMPORT  Log := StdLog,  In := i21sysIn,
		TextModels,  TextViews,  TextMappers,  TextControllers,  C := DevCommanders;
	
	CONST  Int* = 1;  Real* = 2;  Name* = 3;  Char* = 4;  Eot* = 5;
	
	TYPE
		Text* = RECORD
			t: TextModels.Model
		END;
		
		Writer* = RECORD
			fm: TextMappers.Formatter
		END;
		
		Reader* = RECORD
			eot-: BOOLEAN;
			rd: TextModels.Reader;
		END;
		
		Scanner* = RECORD
			class-: INTEGER;
			i-: INTEGER;
			x-: REAL;
			s-: ARRAY 32 OF CHAR;
			ch-: CHAR;
			nextCh-: CHAR;
			sc: TextMappers.Scanner;
		END;
	
	VAR  log*, input*: Text;
	
	
	PROCEDURE OpenText ( VAR text: Text;  t: TextModels.Model ); (* добавлено для удобства *)
	BEGIN
		text.t := t
	END OpenText;
	
	PROCEDURE OpenInput*;  (* POST: input = поток ввода по правилам модуля i21sysIn *)
		VAR  c: TextControllers.Controller;  beg, end: INTEGER;  t: TextModels.Model;
	BEGIN
		t := TextModels.dir.New();
		c := TextControllers.Focus();
		IF  ( c # NIL ) & c.HasSelection()  THEN
			c.GetSelection( beg, end );
			t.InsertCopy( 0, c.text, beg, end )
		ELSIF  C.par # NIL  THEN
			t.InsertCopy( 0, C.par.text, C.par.beg, C.par.end )
		ELSIF  c # NIL  THEN
			t := c.text
		ELSE
			t := NIL
		END;
		ASSERT( t # NIL );
		OpenText( input, t )
	END OpenInput;
	
	PROCEDURE Length* ( t: Text ): INTEGER; (* добавлено для удобства записи в конец Log'а *)
	BEGIN  RETURN  t.t.Length()
	END Length;
	
	PROCEDURE ShowEnd* ( t: Text ); (* добавлено для удобства показа конца текста --info21 *)
	BEGIN
		TextViews.ShowRange( t.t, t.t.Length(), t.t.Length(), TextViews.any );
	END ShowEnd;
	
	
	PROCEDURE OpenReader* ( VAR r: Reader;  t: Text;  pos: INTEGER);
		VAR
	BEGIN
		r.rd := t.t.NewReader( NIL );
		r.rd.SetPos( pos );
		r.eot := r.rd.eot;
	END OpenReader;
	
	PROCEDURE Read* ( VAR r: Reader;  OUT ch: CHAR );
		VAR
	BEGIN
		r.rd.ReadChar( ch );
		r.eot := r.rd.eot;
	END Read;
	
	PROCEDURE OpenScanner* ( VAR s: Scanner;  t: Text;  pos: INTEGER );
		VAR
	BEGIN
		ASSERT( t.t # NIL );
		s.sc.ConnectTo( t.t );
		s.sc.SetPos( pos );
		s.sc.SetOpts( {} );
	END OpenScanner;
	
	PROCEDURE Scan* ( VAR s: Scanner );
		VAR  pos: INTEGER;  c: CHAR;
	BEGIN
		s.sc.Scan;
		IF  s.sc.type = TextMappers.int  THEN
			s.class := Int;
			s.i := s.sc.int;
		ELSIF  s.sc.type = TextMappers.real  THEN
			s.class := Real;
			s.x := s.sc.real;
		ELSIF  s.sc.type = TextMappers.string  THEN
			s.class := Name;
			ASSERT( LEN( s.sc.string$ ) < 32 );
			s.s := s.sc.string$;
		ELSIF  s.sc.type = TextMappers.char  THEN
			s.class := Char;
			s.ch := s.sc.char;
		ELSIF  s.sc.type = TextMappers.eot  THEN
			s.class := Eot;
			s.ch := s.sc.char;
		ELSE
			HALT( 126 );
		END;
		pos := s.sc.rider.Pos();
		s.sc.rider.ReadChar( c );
		s.nextCh := c;
		s.sc.SetPos( pos );
	END Scan;
	
	PROCEDURE ReadInt* ( VAR r: Reader;  OUT n: INTEGER ); (* часто используется *)
		VAR  t: Text;  s: Scanner;
	BEGIN
		OpenText( t, r.rd.Base() );
		OpenScanner( s, t, r.rd.Pos() );
		Scan( s );
		ASSERT( s.class = Int );
		n := s.i;
		r.eot := r.rd.eot;
		r.rd.SetPos( s.sc.rider.Pos() );
	END ReadInt;
	
	
	PROCEDURE OpenWriter* ( VAR w: Writer;  t: Text;  pos: INTEGER );
		VAR
	BEGIN
		w.fm.ConnectTo( t.t );
		w.fm.SetPos( pos );
	END OpenWriter;
	
	PROCEDURE Write* ( VAR w: Writer;  ch: CHAR );
		VAR
	BEGIN
		w.fm.WriteChar( ch );
	END Write;
	
	PROCEDURE WriteLn* ( VAR w: Writer );    (*завершить строку*)
		VAR
	BEGIN
		w.fm.WriteLn;
	END WriteLn;
	
	PROCEDURE WriteTab* ( VAR w: Writer ); 
		VAR
	BEGIN
		w.fm.WriteTab;
	END WriteTab;
	
	PROCEDURE WriteString* ( VAR w: Writer;  s: ARRAY OF CHAR );
		VAR
	BEGIN
		w.fm.WriteString( s );
	END WriteString;
	
	PROCEDURE WriteInt* ( VAR w: Writer;  x, n: INTEGER );
		(*вывести целое x с (по крайней мере) n литерами.
			Если n больше, чем необходимое число цифр, 
			перед числом добавляются пробелы*)
		VAR
	BEGIN
		w.fm.WriteIntForm( x, 10, n, ' ', FALSE );
	END WriteInt;
	
	PROCEDURE WriteReal* ( VAR w: Writer;  x: REAL );
		VAR
	BEGIN
		w.fm.WriteReal( x );
	END WriteReal;
	
	PROCEDURE Close* ( VAR w: Writer );
		VAR
	BEGIN
		w.fm.ConnectTo( NIL );
	END Close;
	
BEGIN
	log.t := Log.text;
END  ADruS174_Texts.

