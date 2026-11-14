(*  Общие сведения о примерах: Справка *)
(*  Исправления и подготовка примеров: (С) Ф.В.Ткачев, 2009, info21 AT inr.ac.ru *)

MODULE ADruS171_Files; (* Реализация модуля Files, сс. 39, 40. *)

	(* ORIGINAL: IMPORT  SYSTEM,  Log := StdLog;
	   `SYSTEM` был нужен только для `RECORD [union]` в WriteInt/ReadInt,
	   `Log` не использовался. В JVM-порте (ADR-247) оба импорта не нужны:
	   модуль стал чистым Component Pascal. Старый импорт закомментирован,
	   чтобы сохранить историю изменения. *)

	CONST MaxLength = 4096;

	TYPE
		File* = POINTER TO RECORD
			len: INTEGER;
			a: ARRAY MaxLength OF CHAR
		END;
		
		Rider* = EXTENSIBLE RECORD  (* 0 <= pos <= f.len <= MaxLength *)
			f: File;
			pos: INTEGER;
			eof-: BOOLEAN
		END;
	
	
	PROCEDURE New* ( name: ARRAY OF CHAR ): File;
		VAR  f: File;
	BEGIN  NEW(f);  f.len := 0;  RETURN  f
	END New;

	PROCEDURE Old* ( name: ARRAY OF CHAR ): File;
		VAR  f: File;
	BEGIN  HALT( 126 );  RETURN  f
	END Old;

	PROCEDURE Close* ( VAR f: File );
	BEGIN
	END Close;

	PROCEDURE Set* ( VAR r: Rider;  f: File;  pos: INTEGER );
	BEGIN
		ASSERT( f # NIL );
		r.f := f;  r.eof := FALSE;
		IF  r.pos < 0  THEN
			r.pos := 0
		ELSIF  pos > f.len  THEN
			r.pos := f.len
		ELSE
			r.pos := pos
		END
	END Set;

	PROCEDURE Write* ( VAR r: Rider;  ch: CHAR );
	BEGIN
		ASSERT( r.pos <= r.f.len );
		IF  r.pos < MaxLength  THEN
			r.f.a[ r.pos ] := ch;  INC( r.pos );
			IF  r.pos > r.f.len  THEN  INC( r.f.len )  END
		ELSE
			r.eof := TRUE
		END
	END Write;

	PROCEDURE Read* ( VAR r: Rider;  OUT ch: CHAR );
	BEGIN
		IF  r.pos < r.f.len  THEN  ch := r.f.a[ r.pos ];  INC( r.pos )  ELSE  r.eof := TRUE  END
	END Read;
	
	
	(* следующие две процедуры отсутствуют в английском "исходнике" книги;
		они используются в сортировках слиянием: *)
	
	(* ORIGINAL (BlackBox):
	
		PROCEDURE WriteInt* ( VAR r: Rider;  x: INTEGER );
			VAR  u: RECORD [union]
				x: INTEGER;
				a: ARRAY 2 OF CHAR;
			END;
		BEGIN
			u.x := x;
			Write( r, u.a[ 0 ] );
			Write( r, u.a[ 1 ] );
		END WriteInt;
	
	   `[union]` накладывает x и a на одну память: CHAR 16-битный,
	   INTEGER 32-битный, поэтому a[0]/a[1] — половины числа. В целевом
	   Component Pascal прагмы `[union]` нет; простое удаление дало бы
	   три отдельных поля и сломало ReadInt. Поэтому половины считаются
	   арифметически (старый код выше закомментирован). *)
	PROCEDURE WriteInt* ( VAR r: Rider;  x: INTEGER );
		VAR  lo, hi: INTEGER;
	BEGIN
		lo := x MOD 10000H;
		IF  lo < 0  THEN  lo := lo + 10000H  END;
		hi := (x - lo) DIV 10000H;  (* x - lo кратно 10000H *)
		hi := hi MOD 10000H;
		IF  hi < 0  THEN  hi := hi + 10000H  END;
		Write( r, CHR( lo ) );
		Write( r, CHR( hi ) );
	END WriteInt;
	
	(* ORIGINAL (BlackBox):
	
		PROCEDURE ReadInt* ( VAR r: Rider;  OUT x: INTEGER );
			VAR  u: RECORD [union]
				x: INTEGER;
				a: ARRAY 2 OF CHAR;
			END;
		BEGIN
			Read( r, u.a[ 0 ] );
			Read( r, u.a[ 1 ] );
			x := u.x;
		END ReadInt;
	
	   Обратное к WriteInt: две 16-битные половины; если старшая >= 8000H,
	   число отрицательное — расширяем знак. Старый код закомментирован
	   по той же причине: `[union]` в JVM-порте не поддерживается. *)
	PROCEDURE ReadInt* ( VAR r: Rider;  OUT x: INTEGER );
		VAR  c0, c1: CHAR;  lo, hi: INTEGER;
	BEGIN
		c0 := 0X;  c1 := 0X;
		Read( r, c0 );  Read( r, c1 );
		lo := ORD( c0 );  hi := ORD( c1 );
		IF  hi >= 8000H  THEN  hi := hi - 10000H  END;
		x := lo + hi * 10000H
	END ReadInt;


END ADruS171_Files.

ADruS171_FilesTest.Do
