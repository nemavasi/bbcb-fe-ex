MODULE i21sysCharacters;
(** This module is part of the educational versions of BlackBox 1.5 provided by the project "Informatika-21". 
Its purpose is to extend support in the identifiers of Component Pascal of characters from the Extended ASCII range beyond the Latin-1 subset. The Latin-1 limitation is specified in the Language Report.

This module (together with the imported one) replaces the module National formerly used in the Russian versions of BlackBox and adds a functionality similar to that of Strings, that was previously provided by i21sysConv.

The source of the old National is retained for compatibility reasons; it is in the folder System/Mod/
 **)
(**
	project	= "Информатика-21 / Informatika-21"
	contributors	= "I.N.Goryachev, F.V.Tkachov"
	changes	= "
	- 20111214, F.V.Tkachov, redesign, see comments above
	- 20050519, I.N.Goryachev, the initial version under name National
	- YYYYMMDD, nn, ...
	"
	issues	= ""

**)
	IMPORT x := i21sysLatin1;
	(*IMPORT x := i21sysCyrillic;*)
	
	VAR
		HostFontsCHARSET-: INTEGER; (* used in HostFonts *)

		charSetName-: ARRAY 64 OF CHAR;
		
		Cap-:	PROCEDURE (ch: CHAR): CHAR;
		ExtendedAsciiOf-:	PROCEDURE (ch: CHAR): CHAR;
		IsCap-:	PROCEDURE (ch: CHAR): BOOLEAN;
		IsDigit-:	PROCEDURE (ch: CHAR): BOOLEAN;
		IsFirstIdentChar-:	PROCEDURE (ch: CHAR): BOOLEAN;
		IsIdentChar-:	PROCEDURE (ch: CHAR): BOOLEAN;
		IsLetter-:	PROCEDURE (ch: CHAR): BOOLEAN;
		Lower-:	PROCEDURE (ch: CHAR): CHAR;
		ToExtendedAscii-:	PROCEDURE (IN in: ARRAY OF CHAR; OUT out: ARRAY OF CHAR);
		ToUnicode-:	PROCEDURE (IN in: ARRAY OF CHAR; OUT out: ARRAY OF CHAR);
		ToUpper-:	PROCEDURE (IN in: ARRAY OF CHAR; OUT out: ARRAY OF CHAR);
		UnicodeOf-:	PROCEDURE (ch: CHAR): CHAR;
		Upper-:	PROCEDURE (ch: CHAR): CHAR;

	PROCEDURE Init;
	BEGIN
		HostFontsCHARSET	:= x.HostFontsCHARSET;
		charSetName	:= x.charSetName$;

		Cap	:= x.Cap;
		ExtendedAsciiOf	:= x.ExtendedAsciiOf;
		IsCap	:= x.IsCap;
		IsDigit	:= x.IsDigit;
		IsFirstIdentChar	:= x.IsFirstIdentChar;
		IsIdentChar	:= x.IsIdentChar;
		IsLetter	:= x.IsLetter;
		Lower	:= x.Lower;
		ToExtendedAscii	:= x.ToExtendedAscii;
		ToUnicode	:= x.ToUnicode;
		ToUpper	:= x.ToUpper;
		UnicodeOf	:= x.UnicodeOf;
		Upper	:= x.Upper;
	END Init;
	
BEGIN
	Init
END i21sysCharacters.

i21sysCharacters3.Do



