MODULE i21sysEdit; (**  **) 
(* 2011-12-19  Ф.В.Ткачев сортировки etc. *)
(* 2010-09-30  Ф.В.Ткачев полная отвязка от национального языка *)
(* 2010-04-11  Ф.В.Ткачев радикальная переделка *)
(* 2008-03-23  Ф.В.Ткачев очищено от дорусификационных артефактов *)
(* 2000-11-20  Ф.В.Ткачев первая версия *)

	IMPORT  Ports, Strings, Fonts, Views, Stores, Models, Files, Converters,
		M := TextModels, TextControllers, TextViews,  TextMappers,  Log := StdLog,
		Ch := i21sysCharacters,  Sc := i21sysScanner,  Vo := i21sysVocabulary;

	TYPE
		String = Sc.String;
		Formatter = TextMappers.Formatter;
	
		What = PROCEDURE (translate: BOOLEAN;  tabs: INTEGER;  VAR fm: Formatter;  OUT pos: INTEGER);
	
	TYPE   Keyword = POINTER TO RECORD (Vo.Entry) END;  (* key = keyword *)
	VAR   keywords: Vo.Vocabulary; (* ключ. слова для угадывания по начальным буквам *)
		
	TYPE   Hint = POINTER TO RECORD (Vo.Entry)
		(* key = short version of keyword *)
		keyword: String; (* full version *)
	END;
	VAR   hints: Vo.Vocabulary;  (* «подсказки» для разрешения двусмысленностей в соответствии с удобством; проверяются до попытки восстановить полное слово по списку words *)
		
	TYPE   Simple = POINTER TO RECORD (Vo.Entry)
		(* key = keyword *)
		expansion0: String; (* исходная цепочка с "|" *)
		expansion: String; (* подставляемая цепочка без "|" *)
		back: INTEGER; (* на сколько позиций назад вернуть курсор после подстановки *)
	END;
	VAR   simples: Vo.Vocabulary; (* простые подстановки *)
		
	TYPE
		Complex = POINTER TO RECORD (Vo.Entry)
			Do: What; (* процедура, создающая конструкцию *)
		END;

	VAR  complexes: Vo.Vocabulary; (* слова, раскрывающиеся в сложные конструкции *)
	
	
	(* keywords *)
	
	PROCEDURE LogKeywords*;
	BEGIN  keywords.Log
	END LogKeywords;
	
	PROCEDURE AddKeyword ( s: String;  replace: BOOLEAN );
		VAR  k: Keyword;
	BEGIN
		NEW( k );
		keywords.Insert( k, s$, replace );
	END AddKeyword;
	
	PROCEDURE AddKeywords* ( lan: ARRAY OF CHAR;  name: ARRAY OF CHAR );
	BEGIN
		Sc.Open( lan, name$ );
		IF  Sc.done  THEN  Sc.Next  END;
		WHILE  Sc.done  DO
			AddKeyword( Sc.string, Vo.dontReplace );
			Sc.Next
		END;
	END AddKeywords;
	
	
	PROCEDURE GuessKeyword (VAR s: String); (* Ищем среди keywords что-нибудь, начинающееся на s$; если находим, то заменяем s на найденное. *)
		VAR  e: Vo.Entry;  j, l: INTEGER;  complete: String;
	BEGIN
		e := keywords.Find(s, FALSE);
		IF e # NIL THEN
			complete := e.key;
			(* является ли s началом complete: *)
			j := 0;  l := LEN(s$);
			WHILE (j < l) & (s[j] = complete[j]) DO  INC(j)  END;
			IF  j = l  THEN
				s := complete
			END
		END;
	END GuessKeyword;
	
	
	(* hints *)
	
	PROCEDURE ( e: Hint ) Log;
	BEGIN  Log.Tab;  Log.String( e.keyword );
	END Log;
	
	PROCEDURE LogHints*;
	BEGIN  hints.Log
	END LogHints;
	
	PROCEDURE AddHints* ( lan: ARRAY OF CHAR;  name: ARRAY OF CHAR );
		VAR  h: Hint;  i: INTEGER;
	BEGIN
		Sc.Open(lan, name$);
		IF Sc.done THEN  Sc.Next  END;
		WHILE  Sc.done  DO
			NEW(h);
			hints.Insert(h, Sc.string, Vo.replace );
			Sc.Next;  ASSERT( Sc.done );
			h.keyword := Sc.string;
			AddKeyword( h.keyword, Vo.dontReplace );
			Sc.Next
		END;
	END AddHints;
	
	PROCEDURE ExpandHint (VAR w: String; OUT done: BOOLEAN);
		VAR  i: Vo.Entry;
	BEGIN
		i := hints.Find( w, TRUE );
		done := ( i # NIL );
		IF done THEN
			w := i( Hint ).keyword;
		END
	END ExpandHint;
	
	
	
	(* simples *)
	
	PROCEDURE ( e: Simple ) Log;
	BEGIN  Log.Tab;  Log.String( e.expansion0 );
	END Log;
	
	PROCEDURE LogSimples*;
	BEGIN  simples.Log
	END LogSimples;
	
	PROCEDURE Extract (from: String;  OUT to: String;  OUT back: INTEGER);
		VAR  i, l: INTEGER;
	BEGIN
		l := LEN(from$);
		i := 0;
		WHILE (i < l) & ~(from[i] = '|') DO  to[i] := from[i];  INC(i)  END;
		IF  i < l  THEN
			back := l - 1 - i;
			WHILE  i < l  DO  to[i] := from[i+1];  INC(i)  END;
			ASSERT( Strings.Valid(to) & (LEN(to$) = l-1) & (back >= 0) );
		ELSE
			back := 0;
			to[l] := 0X;
		END;
	END Extract;
	
	PROCEDURE AddSimples* ( lan: ARRAY OF CHAR;  name: ARRAY OF CHAR );
		VAR  s: Simple;  i: INTEGER;  k: Keyword;
	BEGIN
		Sc.Open(lan, name$);
		IF Sc.done THEN  Sc.Next  END;
		WHILE  Sc.done  DO
			NEW(s);
			simples.Insert( s, Sc.string, Vo.replace );
			Sc.Next;  ASSERT( Sc.done ); (* дочитали пару *)
			s.expansion0 := Sc.string;
			Extract( s.expansion0, s.expansion, s.back );

			AddKeyword( s.key, Vo.dontReplace );
			Sc.Next
		END;
	END AddSimples;
	
	PROCEDURE SimpleExpansion (VAR w: String; OUT done: BOOLEAN; OUT back: INTEGER);
		VAR  i: Vo.Entry;
	BEGIN
		i := simples.Find( w, TRUE );
		done := i # NIL;
		IF done THEN
			w := i( Simple ).expansion;
			back := i( Simple ).back;
		END
	END SimpleExpansion;
	

	(* Сложные расширения, включающие в себя 
		переносы строк ИЛИ изменение атрибутов текста. *)
	
	PROCEDURE  NewLine (tabs: INTEGER;  VAR fm: Formatter);
		VAR  i: INTEGER;
	BEGIN  fm.WriteLn;  i := tabs;  WHILE  i > 0  DO  fm.WriteTab;  DEC(i)  END;
	END NewLine;
	
	PROCEDURE Module (translate: BOOLEAN;  tabs: INTEGER;  VAR fm: Formatter;  OUT pos: INTEGER);
		VAR  m, i, b, e: String;
	BEGIN
		m := 'MODULE';
		i := 'IMPORT';
		b := 'BEGIN';
		e := 'END'; 
		IF translate THEN
			Vo.ToNational(m);
			Vo.ToNational(i);
			Vo.ToNational(b);  
			Vo.ToNational(e)  
		END;
		
		fm.WriteString(m);  fm.WriteString(" ;");  pos := fm.Pos() - 1;
		NewLine(tabs+1, fm);  fm.WriteString(i);
		IF translate & (Vo.language = 'ru') THEN
			fm.WriteString("  Вывод := i21eduВывод,  Ввод := i21eduВвод;");
		ELSE
			fm.WriteString("  Log := StdLog,  In := i21sysIn,  Math;");
		END;	
		NewLine(tabs, fm);  fm.WriteTab;
		(* NewLine(tabs, fm);  fm.WriteString(b); *)
		NewLine(tabs, fm);  fm.WriteString(e);  fm.WriteChar(".");
	END Module;
	
	PROCEDURE Procedure (translate: BOOLEAN;  tabs: INTEGER;  VAR fm: Formatter;  OUT pos: INTEGER);
		VAR  p, v, b, e: String;
	BEGIN
		p := 'PROCEDURE';
		v := 'VAR';
		b := 'BEGIN';  
		e := 'END';
		IF translate THEN  
			Vo.ToNational(p);
			Vo.ToNational(v);  
			Vo.ToNational(b);  
			Vo.ToNational(e);  
		END;
		
		fm.WriteString(p);  fm.WriteString(" ;");  pos := fm.Pos() - 1;
		NewLine(tabs+1, fm);  fm.WriteString(v);  fm.WriteString("  ");  
		NewLine(tabs, fm);  fm.WriteString(b);
		NewLine(tabs, fm);  fm.WriteTab;
		NewLine(tabs, fm);  fm.WriteString(e);  fm.WriteChar(';');
	END Procedure;
	
	PROCEDURE If (translate: BOOLEAN;  tabs: INTEGER;  VAR fm: Formatter;  OUT pos: INTEGER);
		VAR  i, t, else, e: String;
	BEGIN
		i := 'IF';
		t := 'THEN';
		else := 'ELSE';
		e := 'END';
		IF translate THEN  
			Vo.ToNational(i);  
			Vo.ToNational(t);  
			Vo.ToNational(else);  
			Vo.ToNational(e)  
		END;
		
		fm.WriteString(i + ' ');  pos := fm.Pos();
		fm.WriteString(' ' + t);
		NewLine(tabs, fm);  fm.WriteTab;
		NewLine(tabs, fm);  fm.WriteString(else);
		NewLine(tabs, fm);  fm.WriteTab;
		NewLine(tabs, fm);  fm.WriteString(e + ';')
	END If;
	
	PROCEDURE While (translate: BOOLEAN;  tabs: INTEGER;  VAR fm: Formatter;  OUT pos: INTEGER);
		VAR  w, d, e: String;
	BEGIN
		w := 'WHILE';
		d := 'DO';
		e := 'END';
		IF translate THEN
			Vo.ToNational(w);
			Vo.ToNational(d);
			Vo.ToNational(e);
		END;
		
		fm.WriteString(w + ' ');  pos := fm.Pos();
		fm.WriteString(' ' + d);
		NewLine(tabs, fm);  fm.WriteTab;
		NewLine(tabs, fm);  fm.WriteString(e + ';')
	END While;
	
	PROCEDURE For (translate: BOOLEAN;  tabs: INTEGER;  VAR fm: Formatter;  OUT pos: INTEGER);
		VAR  f, t, d, e: String;
	BEGIN
		f := 'F'+'OR';  (*чтобы в этом тексте не заменялось*)
		t := 'TO';
		d := 'DO';
		e := 'END';
		IF translate THEN  
			Vo.ToNational(f);  (*чтобы в этом тексте не заменялось*)
			Vo.ToNational(t);  
			Vo.ToNational(d);  
			Vo.ToNational(e)  
		END;
		
		fm.WriteString(f + ' ');  pos := fm.Pos();
		fm.WriteString(' :=  ' + t + '  ' + d);
		NewLine(tabs, fm);  fm.WriteTab;
		NewLine(tabs, fm);  fm.WriteString(e + ';')
	END For;
	
	PROCEDURE Forbidden (translate: BOOLEAN;  tabs: INTEGER;  VAR fm: Formatter;  OUT pos: INTEGER);
	(* для отучения некоего 8-классника от FOR; подставляется вместо For в нижеследующем списке *)
		VAR  
	BEGIN
		NewLine(tabs, fm);  fm.WriteString('МУЖИК ЧТО БЫК: ВТЕМЯШИТСЯ ');  
		NewLine(tabs, fm);  fm.WriteString('В БАШКУ КАКАЯ БЛАЖЬ —');  
		NewLine(tabs, fm);  fm.WriteString('КОЛОМ ЕЕ ОТТУДОВА');  
		NewLine(tabs, fm);  fm.WriteString('НЕ ВЫБЬЕШЬ.');  
		NewLine(tabs, fm);  fm.WriteString('                             Н.А.Некрасов');  
		pos := fm.Pos();
	END Forbidden;
	
	PROCEDURE Return (translate: BOOLEAN;  tabs: INTEGER;  VAR fm: Formatter;  OUT pos: INTEGER);
		VAR  r: String;  a, bold: M.Attributes;
	BEGIN
		r := 'RETURN';  IF translate THEN  Vo.ToNational(r)  END;
		
		a := fm.rider.attr;
		bold := M.NewWeight(a, Fonts.bold);
		fm.rider.SetAttr(bold);
		fm.WriteString(r);
		fm.rider.SetAttr(a);
		fm.WriteString(' ');  pos := fm.Pos()
	END Return;
	
	PROCEDURE Exit (translate: BOOLEAN;  tabs: INTEGER;  VAR fm: Formatter;  OUT pos: INTEGER);
		VAR  e: String;  a, bold: M.Attributes;
	BEGIN
		e := 'EXIT';  IF translate THEN  Vo.ToNational(e)  END;
		
		a := fm.rider.attr;
		bold := M.NewWeight(a, Fonts.bold);
		fm.rider.SetAttr(bold);
		fm.WriteString(e);
		fm.rider.SetAttr(a);
		fm.WriteString(' ');  pos := fm.Pos()
	END Exit;
	
	PROCEDURE With (translate: BOOLEAN;  tabs: INTEGER;  VAR fm: Formatter;  OUT pos: INTEGER);
		VAR  w, d, e: String;
	BEGIN
		w := 'WITH';
		d := 'DO';
		e := 'END';
		IF translate THEN
			Vo.ToNational(w);  
			Vo.ToNational(d);  
			Vo.ToNational(e);
		END;
		
		fm.WriteString(w + ' ');  pos := fm.Pos();
		fm.WriteString(' ' + d);
		NewLine(tabs, fm);  fm.WriteTab;
		NewLine(tabs, fm);  fm.WriteString(e + ';')
	END With;
	
	PROCEDURE Case (translate: BOOLEAN;  tabs: INTEGER;  VAR fm: Formatter;  OUT pos: INTEGER);
		VAR  c, o, e: String;
	BEGIN
		c := 'CASE';
		o := 'OF';  
		e := 'END';
		IF translate THEN
			Vo.ToNational(c);  
			Vo.ToNational(o);  
			Vo.ToNational(e);
		END;
		
		fm.WriteString(c + ' ');  pos := fm.Pos();
		fm.WriteString(' ' + o);
		NewLine(tabs, fm);  fm.WriteString('|  : ');
		NewLine(tabs, fm);  fm.WriteString(e + ';')
	END Case;
	
	PROCEDURE Record (translate: BOOLEAN;  tabs: INTEGER;  VAR fm: Formatter;  OUT pos: INTEGER);
		VAR  r, e: String;
	BEGIN
		r := 'RECORD';  
		e := 'END';
		IF translate THEN
			Vo.ToNational(r);  
			Vo.ToNational(e);
		END;
		
		fm.WriteString(r);
		NewLine(tabs+1, fm);  pos := fm.Pos();
		NewLine(tabs, fm);  fm.WriteString(e + ';')
	END Record;
	
	PROCEDURE Repeat (translate: BOOLEAN;  tabs: INTEGER;  VAR fm: Formatter;  OUT pos: INTEGER);
		VAR  r, u: String;
	BEGIN
		r := 'REPEAT';  u := 'UNTIL';
		IF translate THEN
			Vo.ToNational(r);  Vo.ToNational(u);
		END;
		
		fm.WriteString(r);
		NewLine(tabs, fm);  fm.WriteTab;
		NewLine(tabs, fm);  fm.WriteString(u + ' ');  pos := fm.Pos();  fm.WriteString(';');
	END Repeat;
	
	PROCEDURE Loop (translate: BOOLEAN;  tabs: INTEGER;  VAR fm: Formatter;  OUT pos: INTEGER);
		VAR  l, e: String;
	BEGIN
		l := 'LOOP';  e := 'END';
		IF translate THEN
			Vo.ToNational(l);  Vo.ToNational(e);
		END;
		
		fm.WriteString(l);
		NewLine(tabs+1, fm);  pos := fm.Pos();
		NewLine(tabs, fm);  fm.WriteString(e + ';');
	END Loop;
	
	PROCEDURE Dijkstra (translate: BOOLEAN;  tabs: INTEGER;  VAR fm: Formatter;  OUT pos: INTEGER);
		VAR  l, e: String;  a, c: M.Attributes;
	BEGIN
		a := fm.rider.attr;
		c := M.NewStyle(a, { Fonts.italic });
		c := M.NewColor(c, Ports.RGBColor(00H, 70H, 60H));
		fm.rider.SetAttr(c);
		fm.WriteString("(" + "* multibranch Dijkstra"+"'"+"s loop: *"+")");
		fm.rider.SetAttr(a);
		
		NewLine(tabs, fm); fm.WriteString('LOOP IF ');  pos := fm.Pos();  fm.WriteString(' THEN');
		NewLine(tabs+1, fm);
		NewLine(tabs, fm);  fm.WriteString('ELSIF  THEN');
		NewLine(tabs+1, fm);
		NewLine(tabs, fm);  fm.WriteString('ELSE EXIT END END;');
	END Dijkstra;
	
	PROCEDURE Comment (translate: BOOLEAN;  tabs: INTEGER;  VAR fm: Formatter;  OUT pos: INTEGER);
		VAR  l, e: String;  a, c: M.Attributes;
	BEGIN
		a := fm.rider.attr;
		c := M.NewStyle(a, { Fonts.italic });
		c := M.NewColor(c, Ports.RGBColor(00H, 70H, 60H));
		fm.rider.SetAttr(c);
		fm.WriteString("(*  *)");
		fm.rider.SetAttr(a);
		pos := fm.Pos() - 3;
	END Comment;
	
	PROCEDURE InitComplexes;
	(* перечисляются все нетрив. синтаксические структуры; 
		для каждой предусмотрена отдельная процедура раскрытия (поле Do) *)
		VAR  c: Complex;

		PROCEDURE Ins( s: ARRAY OF CHAR );
		BEGIN  complexes.Insert(c, s$, Vo.dontReplace);
		END Ins;

	BEGIN
		complexes.Init;
		NEW(c);	c.Do := Case;	Ins( 'CASE' );
		NEW(c);	c.Do := Comment;	Ins( 'COMMENT' );  
		NEW(c);	c.Do := Exit;	Ins( 'EXIT' );  
		NEW(c);	c.Do := If;	Ins( 'IF' );  
		NEW(c);	c.Do := Loop;	Ins( 'LOOP' );  
		NEW(c);	c.Do := Module;	Ins( 'MODULE' );  
		NEW(c);	c.Do := Procedure;	Ins( 'PROCEDURE' );  
		NEW(c);	c.Do := Record;	Ins( 'RECORD' );  
		NEW(c);	c.Do := Repeat;	Ins( 'REPEAT' );  
		NEW(c);	c.Do := Return;	Ins( 'RETURN' );  
		NEW(c);	c.Do := While;	Ins( 'WHILE' );  
		NEW(c);	c.Do := With;	Ins( 'WITH' );  
		NEW(c);	c.Do := Dijkstra;	Ins( 'DIJKSTRA' );  
		NEW(c);	c.Do := For;	Ins( 'F'+'OR' );  
(*		NEW(c);	c.Do := Forbidden;	Ins( 'F'+'OR' );*)
(* для отучения некоторых хвататься за FOR, закомментить синюю строку и раскомментить красную, скомпилировать, перегрузить этот модуль *)
	END InitComplexes;
	
	PROCEDURE Find (IN s: String;  OUT do: What;  OUT translate: BOOLEAN);
		VAR  e: Vo.Entry;  en: String;
	BEGIN
		en := s$;
		Vo.ToEnglish(en);
		e := complexes.Find( en$, TRUE );
		IF e # NIL THEN
			do := e(Complex).Do;
			translate := s # en;
		ELSE
			do := NIL;
			translate := FALSE;
		END;
	END Find;
	
	PROCEDURE Copy (rd: M.Reader;  beg, end: INTEGER;  OUT s: ARRAY OF CHAR);
		VAR  i, length: INTEGER;
	BEGIN
		ASSERT(beg < end, 20);
		length := end - beg;
		rd.SetPos(beg);
		i := 0;  WHILE  i < length  DO  rd.ReadChar(s[i]);  INC(i)  END;
		s[i] := 0X;
	END Copy;
	
	PROCEDURE  BackSelect (rd: M.Reader;  VAR pos: INTEGER);
		VAR  ch: CHAR;
	BEGIN
		(* select the string of (*small*) characters and digits to left of insertion point *)
		(* loop to find beginning *)
		rd.SetPos(pos);  rd.ReadPrevChar(ch);
		WHILE  Ch.IsIdentChar(ch)  OR  Ch.IsLetter(ch) OR  (ch >= "0") & (ch <= "9") DO
			DEC(pos);  ASSERT(pos = rd.Pos(), 100);  rd.ReadPrevChar(ch)
		END;
	END BackSelect;
	
	PROCEDURE Indents (rd: M.Reader): INTEGER;
		VAR  pos, res: INTEGER;  ch: CHAR;
	BEGIN
		pos := rd.Pos();
		(* find start of line *)
		ch := 0X;
		WHILE ~((rd.Pos() = 0) OR (ch = 0DX) OR (ch = 0EX)) DO
			rd.ReadPrevChar(ch)
		END;
		(* (r.Pos() = 0) OR (ch = 0DX) OR (ch = 0EX) *)
		IF (ch = 0DX) OR (ch = 0EX) THEN  rd.SetPos(rd.Pos() + 1)  END;
		
		(* count indents *)
		res := 0;
		REPEAT  INC(res);  rd.ReadChar(ch)  UNTIL  ch # 9X ;
		DEC(res);

		rd.SetPos(pos);
		RETURN  res
	END Indents;
	
	PROCEDURE Capitalize0 (expand: BOOLEAN);
		VAR  c: TextControllers.Controller;
			fm: Formatter;  a: M.Attributes;  
			back, beg, pos, end, tabs: INTEGER;  done, translate: BOOLEAN;
			rd: M.Reader;
			s: String;
			script: Stores.Operation;
			Do: What;
	BEGIN
		c := TextControllers.Focus();  IF c = NIL THEN  RETURN  END;
		IF  c.HasSelection()  THEN
			c.GetSelection(beg, end);  ASSERT(beg < end, 100);
		ELSE
			beg := c.CaretPos();
			end := beg;
		END;
		ASSERT(beg <= end, 101);
		
		rd := c.text.NewReader(rd);  (* new reader at start of text *)
		
		(* if no selection, select to left of insertion point *) 
		IF  beg = end  THEN  BackSelect(rd, beg)  END;
		
		(* it is still possible that there is no selection *) 
		IF  beg < end  THEN
			Copy(rd, beg, end, s);  ASSERT(Strings.Valid(s), 100);
			a := rd.attr; (* attributes from the last character in the segment beg, end *)
			(* we can examine string and modify\expand it accordingly *)
			Models.BeginScript (rd.Base(), "Expand", script); (* все действия до EndScript будут отменяться как целое при нажатии Ctrl+Z *)
			rd.Base().Delete(beg, end);
			fm.ConnectTo(rd.Base());  fm.SetPos(beg);  fm.rider.SetAttr(a);
			Ch.ToUnicode(s, s);
			Ch.ToUpper(s, s);
			IF  ~expand  THEN
				fm.WriteString(s$);  pos := fm.rider.Pos()
			ELSE
				rd.SetPos(beg);
				tabs := Indents(rd);
				ExpandHint(s, done);
				IF ~done THEN  GuessKeyword(s)  END;
				
				SimpleExpansion(s, done, back);
				IF done THEN
					fm.WriteString(s$);  pos := fm.rider.Pos() - back;
				ELSE
					Find(s, Do, translate); (* по s ищем Do, translate; 
						Do # NIL <=> s есть начальное ключ. слово сложной конструкции;
						translate <=> это начальное ключ. слово -- на нац языке *)
					IF Do # NIL THEN
						Do(translate, tabs, fm, pos)
					ELSE
						fm.WriteString(s$);  pos := fm.rider.Pos()
					END
				END
			END;
			fm.ConnectTo(NIL);
			c.SetCaret(pos);
			Models.EndScript (rd.Base(), script);
		END
	END Capitalize0;

	PROCEDURE Capitalize*;
	(** guard: TextCmds.FocusGuard **)
	BEGIN  Capitalize0(FALSE)
	END Capitalize;
	
	PROCEDURE CapitalizeExpand*;
	(** guard: TextCmds.FocusGuard **)
	BEGIN  Capitalize0(TRUE)
	END CapitalizeExpand;
	
	
	PROCEDURE Init;
	BEGIN
		keywords.Init;
		AddKeywords('', 'keywords');

		hints.Init;
		AddHints( '', 'hints' );

		simples.Init;
		AddSimples( '', 'simples' );

		InitComplexes;
	END Init;

	PROCEDURE SetLanguage* ( lan: ARRAY OF CHAR );
	BEGIN
		Init;
		Vo.silent := TRUE;
		Vo.SetLanguage( lan );
		IF  (lan # '') & (lan # 'en')  THEN
			AddKeywords( lan, 'vocab');
			AddHints( lan, 'hints' );
			AddSimples( lan, 'simples' );
		END;
	END SetLanguage;
	
BEGIN Init
END i21sysEdit.

"i21sysEdit.SetLanguage('')"
"i21sysEdit.SetLanguage('ru')"

левые части дополнительных hints/simples автоматически заносятся в список ключевых слов


"i21sysEdit.AddSimples('ua', 'robot')"


"i21sysVocabulary2.SetLanguage('')"   (*никакого (кроме английского)*)
"i21sysEdit.AddHints('ru', 'hints')"	"i21sys/Rsrc/ru/hints"

"i21sysVocabulary.SetLanguage('')"   (*никакого (кроме английского)*)
"i21sysVocabulary.SetLanguage('ru')"    
"i21sysVocabulary.SetLanguage('kabarda')"
"i21sysVocabulary.SetLanguage('ua')"

i21sysVocabulary.Log

"i21sysEdit.AddKeywords('', 'keywords')"	"i21sys/Rsrc/keywords"
"i21sysEdit.AddKeywords('ru', 'keywords')"	"i21sys/Rsrc/ru/keywords"
"i21sysEdit.AddKeywords('ru', 'vocab')"	"i21sys/Rsrc/ru/vocab"
"i21sysEdit.AddKeywords('kabarda', 'vocab')"
"i21sysEdit.AddKeywords('ua', 'vocab')"

"i21sysEdit.AddHints('', 'hints')"
"i21sysEdit.AddHints('ru', 'hints')"	"i21sys/Rsrc/ru/hints"
"i21sysEdit.AddHints('kabarda', 'hints')"
"i21sysEdit.AddHints('ua', 'hints')"

"i21sysEdit.AddSimples('', 'simples')"
"i21sysEdit.AddSimples('ru', 'simples')"
"i21sysEdit.AddSimples('kabarda', 'simples')"
"i21sysEdit.AddSimples('ua', 'simples')"


i21sysEdit.LogKeywords
i21sysEdit.LogHints
i21sysEdit.LogSimples


"i21sysVocabulary.SetLanguage('ru')"
"i21sysVocabulary.SetLanguage('')"