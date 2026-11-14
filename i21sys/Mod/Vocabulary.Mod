MODULE i21sysVocabulary;
(**	project	= "Информатика-21 / Informatika-21"
	contributors	= "F.V.Tkachov"
	changes	= "
	- 20121106, F.V.Tkachov, conversions to unicode minimized based on actual usage
	- 20100411, F.V.Tkachov, original version
	- YYYYMMDD, nn, ...
	"
	issues	= ""
**)
(** 
— Словарик для трансляции (ключевых) слов и средства трансляции для последующей компиляции и возвращением маркеров ошибок в исходный текст до трансляции.
— Модуль выделен из i21sysCompiler, чтобы DevDebug с одной стороны, и i21sysCompiler+DevCompiler с другой, могли перезагружаться независимо; 
DevDebug ссылается сюда.
**)

	IMPORT  Log := StdLog,  Views,
		M := TextModels,  TextViews,  TextControllers,  Dialog,  
		Ch := i21sysCharacters,  Sc := i21sysScanner;
	
	CONST  inc = 100; (* управление размером словариков *)
		replace* = TRUE;  dontReplace* = FALSE;
	
	VAR
		language-: ARRAY 100 OF CHAR;
		module: ARRAY 100 OF CHAR; (* the word MODULE in the chosen language, in Unicode *)
		import: ARRAY 100 OF CHAR; (* the word IMPORT in the chosen language, in Unicode *)
	
	TYPE
		Element = POINTER TO RECORD
			next: Element;
			pos0, pos1: INTEGER;
		END;
	
	VAR  table: Element;  (* NIL = трансляция тождественная *)

	
	TYPE
		String = Sc.String;
		
		Entry* = POINTER TO ABSTRACT RECORD
			key-: String; (* всегда приводится к заглавным в уникоде *)
		END;

		Vocabulary* = RECORD
			len: INTEGER;
			a: POINTER TO ARRAY OF Entry;
		END;
		
		Entry1 = POINTER TO RECORD ( Entry )
			translation: String;
		END;
		
	VAR 
		naen, enna: Vocabulary;  
	
	VAR   silent*: BOOLEAN; (* controls messages about replacement of vocab entries *)
	

	(* Vocabulary *)
	
	PROCEDURE ( v: Entry ) Log*, NEW, EMPTY;

	PROCEDURE ( VAR v: Vocabulary ) Init*, NEW;
	BEGIN  NEW( v.a, inc );  v.len := 0;
	END Init;

	PROCEDURE ( VAR v: Vocabulary ) Log*, NEW;
		VAR  i: INTEGER;
	BEGIN
		FOR i := 0 TO v.len-1 DO
			Log.String( v.a[i].key );
			v.a[i].Log;
			Log.Ln;
		END;
	END Log;

	PROCEDURE AssertIsSorted ( VAR v: Vocabulary );
		VAR  i: INTEGER;
	BEGIN
		i := 1;
		WHILE  i < v.len  DO  ASSERT(v.a[i-1].key < v.a[i].key, 60);  INC(i)  END;
	END AssertIsSorted;

	PROCEDURE ( VAR v: Vocabulary ) FindIndex ( key: String ): INTEGER, NEW;
		VAR  i, L, R: INTEGER;
	BEGIN
		L := 0;  R := v.len;
		WHILE L < R DO
			i := (L+R) DIV 2;
			IF  v.a[i].key < key  THEN
				L := i+1
			ELSE (* key <= a[i].key *)
				R := i
			END;
		END;
		ASSERT(L = R, 100);
		RETURN  L;
	END FindIndex;

	PROCEDURE ( VAR v: Vocabulary ) Find* ( key: String;  exact: BOOLEAN ): Entry, NEW;
		VAR  i: INTEGER;  res: Entry;
	BEGIN
		Ch.ToUnicode( key, key );
		i := v.FindIndex( key );
		IF ( i < v.len ) & (~exact OR (v.a[ i ].key = key)) THEN
			res := v.a[ i ]
		ELSE
			res := NIL
		END;
		RETURN  res
	END Find;

	PROCEDURE EnsureLen ( VAR v: Vocabulary );
		VAR  new: POINTER TO ARRAY OF Entry;  i: INTEGER;
	BEGIN
		(* обеспечить достаточно места для новой вставки: *)
		IF v.len = LEN(v.a) (* забито под завязку *) THEN
			NEW( new, LEN(v.a)+inc ); (* inc — это константа для подобных целей всюду в этом модуле *)
			i := 0;
			WHILE i < LEN(v.a) DO  new[i] := v.a[i];  INC(i)  END;
			v.a := new;  new := NIL;
		END;
		ASSERT(v.len < LEN(v.a), 60);
	END EnsureLen;
	
	PROCEDURE ( VAR v: Vocabulary ) Insert* ( e: Entry;  key: String;  replace: BOOLEAN ), NEW;
		VAR  L, i: INTEGER;  exists: BOOLEAN;
	BEGIN
		exists := FALSE;
		Ch.ToUpper( key, key );
		Ch.ToUnicode( key, key );
		L := v.FindIndex( key );
		IF (L < v.len) & (key # v.a[L].key) THEN
			EnsureLen( v );
			FOR i := v.len TO L+1 BY -1 DO
				v.a[i] := v.a[i-1]
			END;
			e.key := key;
			v.a[L] := e;
			INC(v.len);
		ELSIF L = v.len THEN
			EnsureLen( v );
			e.key := key;
			v.a[L] := e;
			INC(v.len);
		ELSIF replace THEN
			v.a[L] := e;
		ELSIF ~silent THEN
			Log.String('failed attempt to replace entry:' );  Log.Ln;
			e.Log;  Log.Ln;
		END;
	(* AssertIsSorted(v); *)
	END Insert;

	
	PROCEDURE ( v: Entry1 ) Log*;
	BEGIN  Log.Tab;  Log.String( v.translation );
	END Log;

	PROCEDURE Show*;
	BEGIN
		Log.Ln;
		Log.String( language );  Log.Ln;
		Log.String( module );  Log.Ln;
		Log.String( import );  Log.Ln;
		Log.String( 'i21sysVocabulary: active vocabulary' );  Log.Ln;
		naen.Log;
	END Show;
	
	PROCEDURE IsImport* ( s: ARRAY OF CHAR ): BOOLEAN;
		VAR  res: BOOLEAN;
	BEGIN
		res := s = 'IMPORT';
		IF ~res THEN
			Ch.ToUnicode( s, s );
			res := s = import;
		END;
		RETURN res
	END IsImport;
	
	PROCEDURE IsModule* ( s: ARRAY OF CHAR ): BOOLEAN;
		VAR  res: BOOLEAN;
	BEGIN
		res := s = 'MODULE';
		IF ~res THEN
			Ch.ToUnicode( s, s );
			res := s = module;
		END;
		RETURN res
	END IsModule;
	
	PROCEDURE ToNational* ( VAR s: Sc.String ); (* с английского на родной, нужна в сложных подстановках *)
		VAR  e: Entry;
	BEGIN
		e := enna.Find( s, TRUE );
		IF e # NIL THEN
			s := e(Entry1).translation$
		END;
	END ToNational;
	
	PROCEDURE ToEnglish* ( VAR s: Sc.String ); (* с родного/в любой кодировке на английский *)
		VAR  e: Entry;
	BEGIN
		e := naen.Find( s, TRUE );
		IF e # NIL THEN
			s := e(Entry1).translation$
		END;
	END ToEnglish;
	

	PROCEDURE WriteWord (wr: M.Writer;  IN id: Sc.String);
		VAR  i: INTEGER;
	BEGIN
		i := 0;  WHILE  id[i] # 0X  DO  wr.WriteChar(id[i]);  INC(i)  END;
	END WriteWord;
	
	PROCEDURE ConvertText* (t0: M.Model;  OUT t1: M.Model); (* преобразуем текст, одновременно запоминая таблицу соответствия позиций переведенных слов (идентификаторов, в которых разрешены уникодовские буквы наряду с тем, что допускает язык) *)
		VAR
			rd: M.Reader;  wr: M.Writer;  attr: M.Attributes;  ch: CHAR;
			id: Sc.String; (* буфер для очередного слова, найденного в оригинальном тексте *)
			uid, en: Sc.String;
			pos, i: INTEGER;  new, e: Element;
	BEGIN
		(* ASSERT(language # '', 20 ); *)
		
		rd := t0.NewReader(NIL);
		t1 := M.dir.New();  wr := t1.NewWriter(NIL);
		NEW(table);  table.pos0 := -1;  table.pos1 := -1;  table.next := NIL; (* барьер *)
		
(* 
К вопросу об эффективности систематических методов программирования вообще и построения сложных циклов методом Дейкстры в частности. 
Вся группа циклов, играющая центральную роль в этом модуле, во главе со следующим шестиветочным циклом Дейкстры и вместе с соответствующими циклами в модуле i21sysCompiler, была написана за одну рабочую сессию (всего около 10 часов, включая либеральные перерывы на чай, ужин, чтение новостей и отслеживание текущих результатов матчей проходившего тогда теннисного турнира WTA) и сразу корректно заработала, не потребовав традиционной отладки. 
Единственная ошибка (случай, когда документ кончается до точки, закрывающей модуль) была найдена просто на свежую голову (на следующее утро) верификацией программного текста, то есть, опять же, без отладки.
Разумеется, окончательный результат подвергся довольно обширному тестированию, но — это важно подчеркнуть — роль традиционной отладки как способа поиска и устранения ошибок была равна в точности нулю.
—Ф.В.Ткачев (info21)
*)
		(* готовимся войти в цикл: *)
		pos := 0; (* позиция начала id в исходном тексте *)
		i := 0; (* позиция внутри id *)
		rd.Read;  ch := rd.char;
		(* цикл Дейкстры: *)
		LOOP IF ~rd.eot & (attr # rd.attr) THEN 
			(* наткнулись на изменение атрибутов текста — просто копируем *)
			attr := rd.attr;
			wr.SetAttr(attr);
		ELSIF ~rd.eot & (rd.view # NIL) THEN 
			(* наткнулись на вьюшку, делаем дубликат (?) и копируем *)
			wr.WriteView(Views.CopyOf(rd.view, Views.deep), rd.w, rd.h);
			rd.Read;
		ELSIF ~rd.eot & (i = 0) & (Ch.IsFirstIdentChar(rd.char) OR Ch.IsLetter(rd.char)) THEN
			(* увидели начало слова *)
			pos := rd.Pos() - 1; (* запомнили, где оно начинается в оригинале *)
			id[i] := rd.char;  INC(i);  (* записали в буфер его первую литеру *)
			rd.Read;
		ELSIF ~rd.eot & (i > 0) & (Ch.IsIdentChar(rd.char) OR Ch.IsLetter(rd.char)) THEN
			(* слово еще не закончилось *)
			id[i] := rd.char;  INC(i);  (* записали в буфер его очередную литеру *)
			rd.Read;
		ELSIF  i > 0  THEN (* завершили чтение слова *)
			id[i] := 0X; (* оформили завершение соотв. цепочки литер *)
			(* пытаемся заменить id по словарику: *)
			Ch.ToUnicode(id, uid);
			en := uid;
			ToEnglish( en );
			IF  en # uid  THEN
				NEW(new);
				new.pos0 := pos; (* позиция слова в оригинале *)
				new.pos1 := wr.Pos(); (* позиция перевода, здесь начнется переведенное слово *)
				new.next := table;  table := new;
				WriteWord(wr, en);
			ELSE
				WriteWord(wr, id);
			END;
			i := 0;
			wr.WriteChar(rd.char);
			rd.Read;
		ELSIF  ~rd.eot  THEN
			wr.WriteChar(rd.char);
			rd.Read;
		ELSE EXIT END END;

		NEW(new);
			new.pos0 := t0.Length();
			new.pos1 := t1.Length();
		new.next := table;  table := new;
	END ConvertText;
	
	PROCEDURE OriginalPos* (pos: INTEGER): INTEGER;
		VAR  e: Element;  pos0: INTEGER;
	BEGIN
		(* позицию определяем в обратном направлении — т.е. относительно начала *следующего* попавшего в список слова; помним, что список у нас в обратном порядке: *)
		e := table;
		WHILE (e # NIL) & ~((pos <= e.pos1) & (pos > e.next.pos1)) DO
			e := e.next
		END;
		IF  e # NIL  THEN
			pos0 := e.pos0 - (e.pos1 - pos);
		ELSE
			pos0 := pos
		END;
		RETURN  pos0
	END OriginalPos;
	
	PROCEDURE ConvertFocus*;
		VAR  c: TextControllers.Controller;  t: M.Model;  error: BOOLEAN;  v: Views.View;
	BEGIN
		(* взять текст в фокусе *)
		c := TextControllers.Focus();
		IF  c # NIL  THEN
			ASSERT(c.text # NIL); (* c.text = нужный текст *)
			(* преобразовать c.text в t, заменяя ключевые слова, при этом создать таблицу table *)
			ConvertText(c.text, t);
			v := TextViews.dir.New(t);
			Views.OpenView(v);
			Views.SetDirty(v);
		END;
	END ConvertFocus;
	

	PROCEDURE SetLanguage* ( lang: ARRAY OF CHAR );
		VAR  e, f: Entry1;  res: INTEGER;  out: ARRAY 100 OF CHAR;  replaced: BOOLEAN;
	BEGIN
		naen.Init;
		enna.Init;
		language := 'en';  module := 'MODULE';  import := 'IMPORT';
		
		IF ( lang # '' ) & ( lang # 'en') THEN

			(* формат словарика описан в i21sys/Rsrc/ru/vocab.odc *)
			Sc.Open(lang, 'vocab');  (* подсоединились к словарику, можно читать *)
			
			language := lang$;
				(* проходим по парам в словарике, записываем в два словаря: *)
			Sc.Next; (* первый элемент пары *)
			WHILE  Sc.done  DO
				(* ASSERT( IsLatinCaps(i21sysScanner.s0), 30 ); *)
				NEW( e );
				e.translation := Sc.string$;
				Sc.Next;  ASSERT( Sc.done );  (* дочитали пару *)
silent := FALSE;
				naen.Insert( e, Sc.string, dontReplace );
				IF        e.translation = 'MODULE'  THEN  module := e.key$
				ELSIF  e.translation =  'IMPORT'   THEN  import  := e.key$
				END;
				NEW( f );
				f.translation := e.key;
silent := TRUE;
				enna.Insert( f, e.translation, dontReplace );
				
				Sc.Next; (* первый элемент пары *)
			END;
		END;
		Dialog.MapParamString('#i21sys:KeywordsLanguage', language, '', '', out);
		Log.String(out);  Log.Ln;
	END SetLanguage;
	
BEGIN
	silent := TRUE;
	(* не через SetLanguage, чтобы не было лишнего сообщения *)
	naen.Init;
	enna.Init;
	language := 'en';  module := 'MODULE';  import := 'IMPORT';
END i21sysVocabulary.


i21sysVocabulary.Show
"i21sysVocabulary.SetLanguage('ru')"
"i21sysVocabulary.SetLanguage('')"

