MODULE  i21sysScanner;
(**
	project	= "Информатика-21 / Informatika-21"
	contributors	= "F.V.Tkachov"
	changes	= "
	- 20140323, ТЕЭ, доб. опция TextMappers.maskViews в Open, sc.SetOpts (ЕИЕ: p86831)
	- 20140311, ТЕЭ, Удалена избыточная (завершающая) '/' в константе path0
	- 20121106, F.V.Tkachov, simplified, all conversions to unicode removed
		vocabularies abstracted to here
	- 20100411, F.V.Tkachov, original version
	- YYYYMMDD, nn, ...
	"
	issues	= ""

**)
(** 
Сканер словариков типа используемых в i21sysEdit и при работе с нац. ключевыми словами (например i21sys/Rsrc/ru/vocab.odc и т.п.).
**)
	IMPORT  Log := StdLog,  TextMappers,  Files,  Converters,  Views,  TextViews,  DevCommanders;
	
	TYPE
		String* = ARRAY 256 OF CHAR;

	CONST  path0 = "i21sys/Rsrc";
	
	VAR
		string-: String;
		done-: BOOLEAN;

		path: ARRAY 2000 OF CHAR;
		name: Files.Name;
		sc: TextMappers.Scanner;  ok: BOOLEAN;


	PROCEDURE Open* ( path: ARRAY OF CHAR;  name: Files.Name ); (* path relative to path0 *)
		VAR  loc: Files.Locator;  i: INTEGER;  fullName: Files.Name;
			conv: Converters.Converter;  v: Views.View;
	BEGIN
		string := '';
		done := FALSE;
		loc := Files.dir.This( path0 );  ASSERT( loc.res = 0 );
		loc := loc.This( path$ );
		ok := loc.res = 0;
		IF ~ok THEN  RETURN  END;
		fullName := name + '.odc';
		v := Views.Old( Views.dontAsk, loc, fullName, conv );
		ok := ( v # NIL ) & ( v IS TextViews.View );
		IF ~ok THEN   RETURN  END;
		sc.ConnectTo( v( TextViews.View ).ThisModel() );
		sc.SetOpts( { TextMappers.returnViews, TextMappers.maskViews } ); (* используем вьюшку для отметки конца списка, поэтому хотим, чтобы sc ее не игнорировал, тогда мы тут засечем ее *)
		done := TRUE;
		path := path$;
		name := name$;
	END Open;
	
	PROCEDURE SkipToNextLine; (* стоим после % *)
		CONST
			stop = {TextMappers.eot, TextMappers.view, TextMappers.line, TextMappers.para};
			startOfLine = {TextMappers.line, TextMappers.para};
	BEGIN
		sc.SetOpts( sc.opts + { TextMappers.returnCtrlChars } ); (* сканер видит концы линий etc. *)
		REPEAT  sc.Scan
		UNTIL ( sc.type IN stop );
		done := ( sc.type IN startOfLine );
		sc.SetOpts( sc.opts - { TextMappers.returnCtrlChars } ); (* сканер не видит концы линий etc. *)
	END SkipToNextLine;
	
	PROCEDURE Next*; (* после очередной литерной цепочки *)
	BEGIN
		string := '';
		sc.Scan();
		(* пропускаем комментарии, пока не прочтем очередную цепочку *)
		WHILE ( sc.type # TextMappers.eot ) & ( sc.type # TextMappers.view )
			& ( sc.type = TextMappers.char ) & ( sc.char = '%' ) DO
			IF ( sc.type = TextMappers.char ) & ( sc.char = '%' ) THEN SkipToNextLine END;
			IF done THEN  sc.Scan()  END;
		END;
		IF done & ( sc.type # TextMappers.eot ) & ( sc.type # TextMappers.view ) THEN
			ASSERT( ( sc.type = TextMappers.string ) 
					OR (( sc.type = TextMappers.char ) & ( sc.char # '%' )) );
			string := sc.string$;
		ELSE
			done := FALSE
		END;
	END Next;
	
END  i21sysScanner.



	PROCEDURE Restart*;
	BEGIN
		string := '';
		IF ok THEN
			sc.SetPos( 0 );  done := TRUE
		ELSE
			done := FALSE
		END;
	END Restart;
	
