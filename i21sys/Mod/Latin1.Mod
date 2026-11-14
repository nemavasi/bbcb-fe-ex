MODULE i21sysLatin1;
(** This module is part of the educational versions of BlackBox 1.5 provided by the project "Informatika-21". 
Its purpose is to provide support for the standard character set in Component Pascal identifiers as specified in the Language Report. See i21sysCharacters and its documentation.
 **)
(**
	project	= "Информатика-21 / Informatika-21"
	contributors	= "F.V.Tkachov"
	changes	= "
	- 20111214, F.V.Tkachov, initial version
	- YYYYMMDD, nn, ...
	"
	issues	= ""

**)
	
	CONST  
		HostFontsCHARSET* = 0;
	
	CONST  uBase = 0;  uRange = 100H;	

	VAR  E, e, U, u: ARRAY 128 OF CHAR;
		charSetName-: ARRAY 64 OF CHAR;
		
	VAR
		ascii: ARRAY 256 OF RECORD
			isCap, isLetter, isFirstIdentChar, isIdentChar: BOOLEAN;
			cap, low, unicode: CHAR;
		END;
		
		unicode: ARRAY uRange OF RECORD
			isCap, isLetter: BOOLEAN;
			cap, low, ascii: CHAR;
		END;
		
	
	PROCEDURE IsCap* (ch: CHAR): BOOLEAN;
		VAR  res: BOOLEAN;  i: INTEGER;
	BEGIN
		IF  ORD(ch) < 256  THEN
			res := ascii[ORD(ch)].isCap
		ELSE
			i := ORD(ch) - uBase;
			res := (0 <= i) & (i < uRange) & unicode[i].isCap;
		END;
		RETURN  res
	END IsCap;

	PROCEDURE IsDigit* (ch: CHAR): BOOLEAN;
	BEGIN
		RETURN ("0" <= ch) & (ch <= "9")
	END IsDigit;

	PROCEDURE IsLetter* (ch: CHAR): BOOLEAN;
		VAR  res: BOOLEAN;  i: INTEGER;
	BEGIN
		IF  ORD(ch) < 256  THEN
			res := ascii[ORD(ch)].isLetter
		ELSE
			i := ORD(ch) - uBase;
			IF  (0 <= i) & (i < uRange) THEN
				res := unicode[i].isLetter
			ELSE
				res := FALSE
			END
		END;
		RETURN  res
	END IsLetter;

	PROCEDURE IsFirstIdentChar* (ch: CHAR): BOOLEAN;
	BEGIN
		RETURN (ORD(ch) < 256) & ascii[ORD(ch)].isFirstIdentChar
	END IsFirstIdentChar;

	PROCEDURE IsIdentChar* (ch: CHAR): BOOLEAN;
	BEGIN
		RETURN (ORD(ch) < 256) & ascii[ORD(ch)].isIdentChar
	END IsIdentChar;

	
	PROCEDURE Cap* (ch: CHAR): CHAR;
		VAR  res: CHAR;  i: INTEGER;
	BEGIN
		IF  ORD(ch) < 256  THEN
			res := ascii[ORD(ch)].cap
		ELSE
			i := ORD(ch) - uBase;
			IF  (0 <= i) & (i < uRange) THEN
				res := unicode[i].cap
			ELSE
				res := ch
			END
		END;
		RETURN  res
	END Cap;
	
	PROCEDURE Upper* (ch: CHAR): CHAR; (* as in Strings *)
	BEGIN  RETURN Cap(ch)
	END Upper;
	
	PROCEDURE Lower* (ch: CHAR): CHAR;  (* is used in Kernel *)
		VAR  res: CHAR;  i: INTEGER;
	BEGIN
		IF  ORD(ch) < 256  THEN
			res := ascii[ORD(ch)].low
		ELSE
			i := ORD(ch) - uBase;
			IF  (0 <= i) & (i < uRange) THEN
				res := unicode[i].low
			ELSE
				res := ch
			END
		END;
		RETURN  res
	END Lower;

	PROCEDURE UnicodeOf* (ch: CHAR): CHAR; (* unicode chars unaffected *)
		VAR  res: CHAR;
	BEGIN
		IF  ORD(ch) < 128  THEN
			res := ch
		ELSIF  ORD(ch) < 256 THEN
			res := ascii[ORD(ch)].unicode
		ELSE
			res := ch
		END;
		RETURN res
	END UnicodeOf;

	PROCEDURE ExtendedAsciiOf* (ch: CHAR): CHAR;
		VAR  res: CHAR;  i: INTEGER;
	BEGIN
		IF ORD(ch) < 256 THEN
			res := ch
		ELSE
			i := ORD(ch) - uBase;
			IF ( 0 <= i ) & ( i < uRange ) THEN
				res := unicode[i].ascii
			ELSE
				res := '?'
			END
		END;
		RETURN res
	END ExtendedAsciiOf;
	
	PROCEDURE ToUpper* (IN in: ARRAY OF CHAR;  OUT out: ARRAY OF CHAR);
		VAR  len, i: INTEGER;
	BEGIN
		len := LEN(in$);  i := 0;
		WHILE  i < len  DO  out[i] := Cap(in[i]);  INC(i)  END;
		out[i] := 0X
	END ToUpper;

(*
	PROCEDURE ToLower* (IN in: ARRAY OF CHAR;  OUT out: ARRAY OF CHAR);
		VAR  len, i: INTEGER;
	BEGIN
		len := LEN(in$);  i := 0;
		WHILE  i < len  DO  out[i] := Lower(in[i]);  INC(i)  END;
		out[i] := 0X
	END ToLower;
*)
	PROCEDURE ToUnicode* (IN in: ARRAY OF CHAR;  OUT out: ARRAY OF CHAR); (* used in (Host)Dialog *)
		VAR  len, i: INTEGER;
	BEGIN
		len := LEN(in$);  i := 0;
		WHILE  i < len  DO  out[i] := UnicodeOf(in[i]);  INC(i)  END;
		out[i] := 0X
	END ToUnicode;

	PROCEDURE ToExtendedAscii* (IN in: ARRAY OF CHAR;  OUT out: ARRAY OF CHAR);
		VAR  len, i: INTEGER;
	BEGIN
		len := LEN(in$);  i := 0;
		WHILE  i < len  DO  out[i] := ExtendedAsciiOf(in[i]);  INC(i)  END;
		out[i] := 0X
	END ToExtendedAscii;

	PROCEDURE Set;
		VAR  i, icap, ilow, j: INTEGER; 
	BEGIN
		ASSERT( (LEN(E$)=LEN(e$)) & (LEN(E$)=LEN(U$)) & (LEN(E$)=LEN(u$)), 20 );
		
		FOR i := 0 TO LEN(E$)-1 DO
			ASSERT( (128 <= ORD(E[i])) & (ORD(E[i]) < 256), 21 );  
			ASSERT( (128 <= ORD(e[i])) & (ORD(e[i]) < 256), 22 );  
			ASSERT( ORD(U[i]) >= 128, 23 ); (* not >=256  to allow for U=E, u=e, etc.*)
			ASSERT( ORD(u[i]) >= 128, 24 );
		END;

		ASSERT( uBase >= 0, 25 );

		FOR j := 0 TO 255 DO
			ascii[j].cap := CHR(j); (* self *)
			ascii[j].low := CHR(j);  (* self *) 
			ascii[j].isCap := FALSE;
			ascii[j].isLetter := FALSE;
			ascii[j].isFirstIdentChar := FALSE;
			ascii[j].isIdentChar := FALSE;
		END;

		j := ORD('_');  
			ascii[j].isFirstIdentChar := TRUE;  
			ascii[j].isIdentChar := TRUE;
		
		FOR j := ORD("0") TO ORD("9") DO  
			ascii[j].isIdentChar := TRUE  
		END;
		
		FOR icap := ORD("A") TO ORD("Z") DO  ilow := icap+32;
			ascii[icap].low := CHR(ilow);
			ascii[ilow].cap := CHR(icap);  
			ascii[icap].isCap := TRUE;
			ascii[icap].isLetter := TRUE;
			ascii[ilow].isLetter := TRUE;
			ascii[icap].isFirstIdentChar := TRUE;
			ascii[ilow].isFirstIdentChar := TRUE;
			ascii[icap].isIdentChar := TRUE;
			ascii[ilow].isIdentChar := TRUE;
		END;

		FOR i := 0 TO 255 DO
			ascii[i].unicode := CHR(i) (* self by default *)
		END;
		
		FOR i := 0 TO uRange-1 DO
			unicode[i].ascii := '?';
			unicode[i].cap := CHR(i + uBase); (* self by default *)
			unicode[i].low := CHR(i + uBase); (* self by default *)
			unicode[i].isCap := FALSE;
			unicode[i].isLetter := TRUE;
		END;
		
		FOR i := 0 TO LEN(E$)-1 DO
			ascii[ORD( E [i])].isLetter := TRUE;
			ascii[ORD( e [i])].isLetter := TRUE;
			ascii[ORD( E[i] )].isCap := TRUE;
			ascii[ORD( E[i] )].low := e[i];  
			ascii[ORD( e[i] )].cap := E[i];
			
			ascii[ORD(E [i])].unicode := U[i]; 
			ascii[ORD(e [i])].unicode := u[i]; 

			unicode[ORD(U [i]) - uBase].ascii := E[i];
			unicode[ORD(u [i]) - uBase].ascii := e[i];
			
			unicode[ORD(u [i]) - uBase].cap       := U [i];
			unicode[ORD(U [i]) - uBase].low       := u [i];
			unicode[ORD(U [i]) - uBase].isCap    := TRUE;
			unicode[ORD(U [i]) - uBase].isLetter := TRUE;
			unicode[ORD(u [i]) - uBase].isLetter := TRUE;
		END;
	
		FOR i := 128 TO 255 DO
			ascii[i].isFirstIdentChar := ascii[i].isLetter;
			ascii[i].isIdentChar        := ascii[i].isLetter;
		END; 
	END Set;
	

	PROCEDURE Init;
		VAR  i: INTEGER;
	BEGIN
		E := "ÀÁÂÃÄÅÆÇÈÉÊËÌÍÎÏÐÑÒÓÔÕÖ"+"ØÙÚÛÜÝÞß";
		e := "àáâãäåæçèéêëìíîïðñòóôõö"+"øùúûüýþÿ";
		U := E;
		u := e;
		charSetName := "Latin-1";
		Set;
	END Init;

BEGIN
	Init
END i21sysLatin1.

i21sysUnicodeTools.ExamineIn


