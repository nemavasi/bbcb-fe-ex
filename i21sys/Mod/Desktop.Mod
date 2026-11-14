(** Модуль изменён при портировании BlackBox на JVM. Исходный код сохранён ниже в комментарии; активен портированный вариант. *)
(* ===== ИСХОДНЫЙ КОД (до портирования, закомментирован) =====
MODULE  i21sysDesktop; ( * FVT 2009-03-17; last changed: 2010-09-21 * )

( **  ** )
( * 20120529, ТЕЭ ReadConverter: добавлена проверка, чтобы избежать повторной регистрации конвертера * )

( * Derived from PrivDesktop by 
		Bruno Essmann (bessmann@iiic.ethz.ch), 
		Guy Laden (laden@math.tau.ac.il), 
		Iain Scott (iain.i.scott@gecm.com); 
	see also Desktop at http://www.zinnamturm.eu.
	This version by Fyodor Tkachov is an attempt to simpify and clarify the original. * )

	IMPORT  Strings,  Files,  Stores,  Views,  TextViews,  TextControllers,  
		Dialog,  Converters,  StdCmds,  Log := StdLog,  
		Windows,  Documents,  WinApi,  HostFiles,  HostWindows,  HostCmds,  HostMenus;
	
	CONST
		magic = 'Информатика-21';  version = 1;
		minimized = 0;  maximized = 1;  ( * Window states * )
		logTitle = "#Dev:Log";
		saveType = "i21";
	
	VAR
		saveName-: Files.Name;
		savePath-: ARRAY 2000 OF CHAR;
		
		list: Link;
		failed: BOOLEAN;
		
	TYPE
		Window = Windows.Window;
		
		Path = POINTER TO ARRAY OF CHAR;
	
		Link = POINTER TO RECORD ( Stores.Store )
			next: Link;
			level: INTEGER; ( * > 0; номер окна во внутр. списке ОСи; XP переводит фокус в голову списка * )
			win: Window;
			title: Views.Title;
			w, h: INTEGER; ( * ширина и высота вьюшки в пикселях * )
			l, t, r, b: INTEGER; ( * позиция окна (с рамками и т.п.) на экране в пикселях * )
			state: SET;
			i: Info;
			e: Extension;
		END;
		
		Info = POINTER TO ABSTRACT RECORD ( Stores.Store ) END;
		
		LogInfo = POINTER TO RECORD ( Info )
		END;
	
		DocInfo = POINTER TO RECORD ( Info )
			path: Path;
			name: Files.Name;
			conv: Converters.Converter;
		END;
	
		TempInfo = POINTER TO RECORD ( Info )
			flags: SET;
			doc: Documents.Document;
			dirty: BOOLEAN;
			title: Views.Title; ( * копия соотв. Link.title * )
		END;
	
		SubInfo = POINTER TO RECORD ( Info )
			parent: INTEGER;
		END;
		
		Extension = POINTER TO ABSTRACT RECORD ( Stores.Store ) END;
		TextExt = POINTER TO RECORD ( Extension )
			rangeBeg, rangeEnd: INTEGER;  ( * visible range * )
			caretPos: INTEGER;  ( * position of caret * )
			selBeg, selEnd: INTEGER;  ( * selection settings * )
		END;
		SubTextExt = POINTER TO RECORD ( Extension )
			rangeBeg, rangeEnd: INTEGER;  ( * visible range * )
		END;
	

	PROCEDURE GetPath ( loc: Files.Locator;  OUT isLocal: BOOLEAN;  OUT path: Path );
	( * returns relative path w.r.t. (secondary) BlackBox path, unless loc is external * )
		VAR  bbpath, absolute: Path;  pos: INTEGER;
	BEGIN
		ASSERT( loc # NIL );

		NEW( bbpath, LEN( Files.dir.This('')( HostFiles.Locator ).path$ ) + 1 );
		bbpath^ := Files.dir.This('')( HostFiles.Locator ).path$;

		NEW( absolute, LEN( loc( HostFiles.Locator ).path$ ) + 1 ); 
		absolute^ := loc( HostFiles.Locator ).path$; 

		NEW( path, LEN( absolute ) );
		path^ := absolute$;
		Strings.Find( path, bbpath, 0, pos );
		isLocal := ( pos = 0 );
		IF  isLocal  THEN ( * можно "оторвать" bbpath от начала path * )
			Strings.Replace( path, 0, LEN( bbpath$ ) + 1, '' );
		END;
	END GetPath;

	PROCEDURE WriteConverter ( VAR wr: Stores.Writer;  c: Converters.Converter );
		VAR  
	BEGIN
		IF  c # NIL  THEN
			wr.WriteString( c.imp );
			wr.WriteString( c.exp );
			wr.WriteString( c.storeType );
			wr.WriteString( c.fileType );
			wr.WriteSet( c.opts )
		ELSE
			wr.WriteString('');  wr.WriteString('');  ( * sentinel * )
		END
	END WriteConverter;

	PROCEDURE ReadConverter ( VAR rd: Stores.Reader;  OUT conv: Converters.Converter );
		VAR  imp, exp: Dialog.String;
			storeType: Stores.TypeName;  fileType: Files.Type;  opts: SET;
			c: Converters.Converter;
	BEGIN
		rd.ReadString( imp );
		rd.ReadString( exp );

		IF  ( imp = '' ) & ( exp = '' )  THEN  conv := NIL;  RETURN  END;

		rd.ReadString( storeType );
		rd.ReadString( fileType );
		rd.ReadSet( opts );

		c := Converters.list;
		WHILE ( c # NIL ) & 
			~( ( c.imp = imp ) & ( c.exp = exp ) & 
				( c.storeType = storeType ) & ( c.fileType = fileType ) & ( c.opts = opts ) )
		DO
			c := c.next
		END;

		IF c = NIL THEN
			Converters.Register( imp, exp, storeType, fileType, opts );
			c := Converters.list;
			WHILE ( c # NIL ) & 
				~( ( c.imp = imp ) & ( c.exp = exp ) & 
					( c.storeType = storeType ) & ( c.fileType = fileType ) & ( c.opts = opts ) )
			DO
				c := c.next
			END
		END;

		conv := c
	END ReadConverter;
	
	
	PROCEDURE IsLog ( win: Windows.Window ): BOOLEAN;
		VAR  title: Views.Title;
	BEGIN
		win.GetTitle( title );
		RETURN  title = logTitle
	END IsLog;
	
	
( *
	PROCEDURE LogList ( s: ARRAY OF CHAR );
		VAR  l: Link;
	BEGIN
		Log.Ln;  Log.String('*********** LogList, ' + s );  Log.Ln;
		l := list;
		WHILE  l # NIL  DO
			Log.Int( l.level );
			Log.String( '  ' + l.title );
			IF   l.i IS SubInfo  THEN  Log.String(' --вторичное')  END;
			Log.Ln;
			Log.Int( l.w );  Log.Int( l.h );  Log.Ln;
			Log.Int( l.l );  Log.Int( l.t );  Log.Int( l.r );  Log.Int( l.b );  Log.Ln;
			Log.Set( l.state );  Log.Ln;
			Log.Ln;
			l := l.next
		END;
	END LogList;
* )	
	
	PROCEDURE NewLink ( win: Window ): Link;
		VAR  l: Link;  wh: WinApi.HANDLE;  ret: WinApi.BOOL;  wp: WinApi.WINDOWPLACEMENT;
	BEGIN
		ASSERT( win # NIL );
		NEW( l );
		win.GetTitle( l.title );
		win.GetSize( l.w, l.h ); ( * вроде внутренние размеры окна в пикселях * )

		wh := win( HostWindows.Window ).wnd;
		ret := WinApi.GetWindowPlacement( wh, wp ); ( * relative position in app window * )

		l.l := wp.rcNormalPosition.left;
		l.t := wp.rcNormalPosition.top;
		l.r := wp.rcNormalPosition.right;
		l.b := wp.rcNormalPosition.bottom;

		l.state := {};
		IF  WinApi.IsIconic	( wh ) = 1  THEN  INCL( l.state, minimized  )  END;
		IF  WinApi.IsZoomed ( wh ) = 1  THEN  INCL( l.state, maximized )  END;

		RETURN  l
	END NewLink;
	
	PROCEDURE ( l: Link ) Restore ( win: Window ), NEW;
		VAR  wh: WinApi.HANDLE;  ret: WinApi.BOOL;  x, y, w, h: INTEGER;
	BEGIN
		win.SetTitle( l.title );
		win.SetSize( l.w, l.h ); ( * ? вроде ниже тоже устанавливается * )

		wh := win( HostWindows.Window ).wnd;
		x := l.l;  w := l.r - l.l;  
		y := l.t;  h := l.b - l.t;
		ret := WinApi.MoveWindow( wh, x, y, w, h, 1 );

	END Restore;
	
	PROCEDURE RestoreState ( win: Window;  state: SET );
		VAR  wh: WinApi.HANDLE;  ret: WinApi.BOOL;  
	BEGIN
		wh := win( HostWindows.Window ).wnd;
		IF  minimized  IN state  THEN  ret := WinApi.ShowWindow( wh, 6 )  END;
		IF  maximized IN state  THEN  ret := WinApi.ShowWindow( wh, 3 )  END;
	END RestoreState;
	
	
	PROCEDURE ( l: Link ) Externalize ( VAR wr: Stores.Writer );
	BEGIN
		wr.WriteStore( l.i );
		wr.WriteStore( l.e );

		wr.WriteInt( l.level );
		wr.WriteString( l.title );
		wr.WriteInt( l.w );  wr.WriteInt( l.h );

		wr.WriteInt( l.l );
		wr.WriteInt( l.t );
		wr.WriteInt( l.r );
		wr.WriteInt( l.b );

		wr.WriteSet( l.state );

		wr.WriteStore( l.next )
	END Externalize;
	
	PROCEDURE ( l: Link ) Internalize ( VAR rd: Stores.Reader );
		VAR  s: Stores.Store;
	BEGIN
		rd.ReadStore( s );
		l.i := s( Info );
		rd.ReadStore( s );
		IF  s # NIL  THEN  l.e := s( Extension )  END;

		rd.ReadInt( l.level );
		rd.ReadString( l.title );
		rd.ReadInt( l.w );  rd.ReadInt( l.h );

		rd.ReadInt( l.l );
		rd.ReadInt( l.t );
		rd.ReadInt( l.r );
		rd.ReadInt( l.b );

		rd.ReadSet( l.state );

		rd.ReadStore( s );
		IF  s # NIL  THEN  l.next := s( Link )  END;
	END Internalize;
	
	
	PROCEDURE ( i: Info ) Init ( win: Windows.Window ), NEW, ABSTRACT;
	PROCEDURE ( i: Info ) NewWindow (): Windows.Window, NEW, ABSTRACT;
	
	PROCEDURE ( i: LogInfo ) Init ( win: Windows.Window );
	BEGIN
	END Init;
	
	PROCEDURE ( info: LogInfo ) NewWindow (): Windows.Window;
		VAR  win: Windows.Window;
	BEGIN
		Log.Open;
		win := Windows.dir.First();
		WHILE ( win # NIL ) & ~IsLog( win ) DO
			win := Windows.dir.Next( win )
		END;
		ASSERT( win # NIL );
		RETURN  win
	END NewWindow;
	
	PROCEDURE ( i: DocInfo ) Init ( win: Windows.Window );
		VAR  isLocal: BOOLEAN;
	BEGIN
		ASSERT( win # NIL, 20 );
		IF  win.loc # NIL  THEN
			GetPath( win.loc, isLocal, i.path ); ( * isLocal not used ... yet? * )
			i.name := win.name;
			i.conv := win.conv;
		ELSE
		END;
	END Init;
	
	PROCEDURE ( i: DocInfo ) NewWindow (): Windows.Window;
		VAR  loc: Files.Locator;  v: Views.View;  win: Windows.Window;
	BEGIN
		loc := Files.dir.This( i.path );
		v := Views.Old( Views.dontAsk, loc, i.name, i.conv );
		IF  v # NIL  THEN
			Views.Open( v, loc, i.name, i.conv );

			win := Windows.dir.First();
			WHILE  ( win # NIL ) & ~( win.doc.ThisView() = v )  DO
				win := Windows.dir.Next( win )
			END;
			ASSERT( win # NIL );
		ELSE
			win := NIL;
			Dialog.ShowParamMsg( "#i21sys:UnableToRestoreDocument", i.name, "", "");
			( * ws.type := AlienWindow * )
		END;
		RETURN  win
	END NewWindow;
	
	PROCEDURE ( i: TempInfo ) Init ( win: Windows.Window );
	BEGIN
		ASSERT( win # NIL, 20 );
		i.flags := win.flags;
		i.doc := win.doc;
		win.GetTitle( i.title );
		i.dirty := ~( Windows.neverDirty IN win.flags ) & win.seq.Dirty();
	END Init;
	
	PROCEDURE ( i: TempInfo ) NewWindow (): Windows.Window;
		VAR  win: Windows.Window;
	BEGIN
		win := Windows.dir.New();
		Windows.dir.OpenSubWindow( win, i.doc, i.flags, i.title );
		win.SetSpec( NIL, '', NIL );
		IF  i.dirty  THEN  win.seq.SetDirty( TRUE )  END;
		RETURN  win
	END NewWindow;
	
	PROCEDURE ( i: SubInfo ) Init ( win: Windows.Window );
	BEGIN
	END Init;
	
	PROCEDURE ( i: SubInfo ) NewWindow (): Windows.Window;
		VAR  l: Link;  win: Windows.Window;
	BEGIN
		l := list;
		WHILE ( l # NIL ) & ~( l.level = i.parent ) DO  l := l.next  END;
		ASSERT( ( l # NIL ) & ( l.level = i.parent ) );

		IF  l.win # NIL  THEN
			Windows.dir.Select( l.win, Windows.eager );
			StdCmds.NewWindow();
			win := Windows.dir.Focus( FALSE );
		ELSE
			win := NIL
		END;
		RETURN  win
	END NewWindow;
	
	PROCEDURE NewInfo ( win: Window ): Info;
		VAR  i: Info;  log: LogInfo;  doc: DocInfo;  tmp: TempInfo;  sub: SubInfo;
			parent: Window;  l: Link;
	BEGIN
		IF  ~win.sub  THEN
			IF  win.name # ''  THEN
				NEW( doc );  i := doc;
			ELSIF  IsLog( win )  THEN
				NEW( log );  i := log;
			ELSE
				NEW( tmp );  i := tmp;
			END;
		ELSE
			parent := win.link;
			WHILE  parent.sub  DO  parent := parent.link  END;

			l := list;
			WHILE ( l # NIL ) & ~( l.win = parent  ) DO  l := l.next  END;
			ASSERT( ( l # NIL ) & ( l.win = parent ) );

			NEW( sub );  sub.parent := l.level;  i := sub
		END;

		RETURN  i
	END NewInfo;
	
	PROCEDURE ( i: LogInfo ) Externalize ( VAR wr: Stores.Writer );
	BEGIN
	END Externalize;
	
	PROCEDURE ( i: LogInfo ) Internalize ( VAR rd: Stores.Reader );
	BEGIN
	END Internalize;
	
	PROCEDURE ( i: DocInfo ) Externalize ( VAR wr: Stores.Writer );
	BEGIN
		wr.WriteString( i.path );

		wr.WriteString( i.name );

		WriteConverter( wr, i.conv );
	END Externalize;
	
	PROCEDURE ( i: DocInfo ) Internalize ( VAR rd: Stores.Reader );
		VAR  string: ARRAY 2000 OF CHAR;
	BEGIN
		rd.ReadString( string );  NEW( i.path, LEN( string$ ) + 1 );  i.path^ := string$;

		rd.ReadString( i.name );

		ReadConverter( rd, i.conv );
	END Internalize;
	
	PROCEDURE ( i: TempInfo ) Externalize ( VAR wr: Stores.Writer );
		VAR  wr1: Stores.Writer;
	BEGIN
		wr.WriteSet( i.flags );
		wr.WriteBool( i.dirty );
		wr.WriteString( i.title );
		wr1.ConnectTo( wr.rider.Base() ); ( * иначе проблема с Domain * )
		wr1.SetPos( wr.Pos() );
		wr1.WriteStore( i.doc );
		wr.SetPos( wr1.Pos() );
		wr1.ConnectTo( NIL );
	END Externalize;
	
	PROCEDURE ( i: TempInfo ) Internalize ( VAR rd: Stores.Reader );
		VAR  s: Stores.Store;  rd1: Stores.Reader;
	BEGIN
		rd.ReadSet( i.flags );
		rd.ReadBool( i.dirty );
		rd.ReadString( i.title );
		rd1.ConnectTo( rd.rider.Base() ); ( * иначе проблема с Domain * )
		rd1.SetPos( rd.Pos() );
		rd1.ReadStore( s );
		rd.SetPos( rd1.Pos() );
		i.doc := s( Documents.Document );
		rd1.ConnectTo( NIL );
	END Internalize;
	
	PROCEDURE ( i: SubInfo ) Externalize ( VAR wr: Stores.Writer );
	BEGIN
		wr.WriteInt( i.parent );
	END Externalize;
	
	PROCEDURE ( i: SubInfo ) Internalize ( VAR rd: Stores.Reader );
	BEGIN
		rd.ReadInt( i.parent );
	END Internalize;
	
	
	PROCEDURE NewExtension ( v: Views.View;  sub: BOOLEAN ): Extension;
		VAR  e: Extension;  t: TextExt;  s: SubTextExt;
	BEGIN
		e := NIL;
		IF  v # NIL  THEN
			WITH  v: TextViews.View  DO

				IF  sub  THEN
					NEW( s );  e := s;
				ELSE
					NEW( t );  e := t;
				END;

			ELSE
			END;
		END;
		RETURN  e
	END NewExtension;
	
	PROCEDURE ( e: Extension ) Init ( v: Views.View;  f: Views.Frame ), NEW, ABSTRACT;
	PROCEDURE ( e: Extension ) Restore ( v: Views.View;  f: Views.Frame ), NEW, ABSTRACT;
	
	PROCEDURE ( e: TextExt ) Init ( v: Views.View;  f: Views.Frame );
		VAR  c: TextControllers.Controller;
	BEGIN
		WITH  v: TextViews.View  DO

			v.GetRange( f, e.rangeBeg, e.rangeEnd );
			c := v.ThisController()( TextControllers.Controller );
			e.caretPos := c.CaretPos();
			c.GetSelection( e.selBeg, e.selEnd );

		END;
	END Init;
	
	PROCEDURE ( e: TextExt ) Restore ( v: Views.View;  f: Views.Frame );
		VAR  c: TextControllers.Controller;  len: INTEGER;
	BEGIN
		IF  v # NIL  THEN
			WITH  v: TextViews.View  DO
				len := v.ThisModel().Length();
				IF  e.rangeEnd <= len  THEN
					v.ShowRangeIn( f, e.rangeBeg, e.rangeEnd );
				END;
				c := v.ThisController()( TextControllers.Controller );
				IF ( 0 <= e.caretPos ) & ( e.caretPos <= len ) THEN
					c.SetCaret( e.caretPos );
				END;
				IF ( e.selBeg <= e.selEnd ) & ( e.selEnd <= len ) THEN
					c.SetSelection( e.selBeg, e.selEnd );
				END;
			END;
		END;
	END Restore;
	
	PROCEDURE ( e: SubTextExt ) Init ( v: Views.View;  f: Views.Frame );
	BEGIN
		WITH  v: TextViews.View  DO
			v.GetRange( f, e.rangeBeg, e.rangeEnd );
		END;
	END Init;
	
	PROCEDURE ( e: SubTextExt ) Restore ( v: Views.View;  f: Views.Frame );
	BEGIN
		WITH  v: TextViews.View  DO
			v.ShowRangeIn( f, e.rangeBeg, e.rangeEnd );
		END;
	END Restore;
	
	
	PROCEDURE ( e: TextExt ) Externalize ( VAR wr: Stores.Writer );
	BEGIN
		wr.WriteInt( e.rangeBeg );
		wr.WriteInt( e.rangeEnd );
		wr.WriteInt( e.selBeg );
		wr.WriteInt( e.selEnd );
		wr.WriteInt( e.caretPos );
	END Externalize;
	
	PROCEDURE ( e: TextExt ) Internalize ( VAR rd: Stores.Reader );
	BEGIN
		rd.ReadInt( e.rangeBeg );
		rd.ReadInt( e.rangeEnd );
		rd.ReadInt( e.selBeg );
		rd.ReadInt( e.selEnd );
		rd.ReadInt( e.caretPos );
	END Internalize;
	
	PROCEDURE ( e: SubTextExt ) Externalize ( VAR wr: Stores.Writer );
	BEGIN
		wr.WriteInt( e.rangeBeg );
		wr.WriteInt( e.rangeEnd );
	END Externalize;
	
	PROCEDURE ( e: SubTextExt ) Internalize ( VAR rd: Stores.Reader );
	BEGIN
		rd.ReadInt( e.rangeBeg );
		rd.ReadInt( e.rangeEnd );
	END Internalize;
	
	
	PROCEDURE InitListFromWindows;
		VAR  new: Link;  win: Window;  level, sub: INTEGER;  v: Views.View;
	BEGIN
		list := NIL;

		( * обрабатываем сначала (sub=1) первичные, потом (sub=2) вторичные окна: * )
		FOR  sub := 1  TO  2  DO

			level := 0;  win := Windows.dir.First();
			WHILE  win # NIL  DO

				INC( level );
				IF  ( sub = 2 ) = win.sub  THEN
					new := NewLink( win );
					new.level := level;
					new.win := win;
					new.i := NewInfo( win );
					new.i.Init( win );
					v := win.doc.ThisView();
					new.e := NewExtension( v, win.sub );
					IF  new.e # NIL  THEN
						new.e.Init( v, win.frame );
					END;
					new.next := list;  list := new;
				END;

				win := Windows.dir.Next( win );
			END;

		END;

	END InitListFromWindows;
	
	PROCEDURE RestoreWindowsFromList;
		VAR  new, l: Link;  nwin, level: INTEGER;
	BEGIN
		( * обратить list * )
		nwin := 0;
		new := NIL;
		l := list;
		WHILE  l # NIL  DO  INC( nwin );
			list := list.next;
			l.next := new;  new := l;
			l := list
		END;
		list := new;
		( * LogList( 'после обращения' ); ( * нарушает порядок окон? * ) * )
		
		( * восстанавливаем окна с содержимым, не заботясь о расположении;
			список в данный момент устроен так, что сначала идут основные окна, потом вторичные * )
		l := list;
		WHILE  l # NIL  DO
			l.win := l.i.NewWindow();
			IF  l.win # NIL  THEN
			ELSE
				Dialog.ShowParamMsg( "#i21sys:UnableToRestoreDocument", l.title, "", "");
			END;
			l := l.next;
		END;
		( * InitListFromWindows;  LogList( 'после восстановления, без расположения' ); * )
		
		( * восстанавливаем расположение, с конца по level * )
		level := nwin;
		WHILE  level > 0  DO

			l := list;
			WHILE ( l # NIL ) & ~( l.level = level ) DO  l := l.next  END;

			IF  l.win # NIL  THEN
				Windows.dir.Select( l.win, Windows.eager ); ( * поднимаем окно наверх * )
				l.Restore( l.win );
				IF  l.e # NIL  THEN
					l.e.Restore( l.win.doc.ThisView(), l.win.frame );
				END;
				RestoreState( l.win, l.state );
			END;

			DEC( level );
		END;
		( * InitListFromWindows;  LogList( 'после восстановления' ); * )

	END RestoreWindowsFromList;
	

	
	
	PROCEDURE Init;
	BEGIN
		savePath := '';  saveName := 'desktop.' + saveType;
	END Init;


	PROCEDURE Unsaved (): Windows.Window;
		VAR  w: Windows.Window;
	BEGIN
		w := Windows.dir.First();
		WHILE (w # NIL) & ~( w.seq.Dirty() & ~(Windows.neverDirty IN w.flags) ) DO
			w := Windows.dir.Next(w)
		END;
		RETURN  w
	END Unsaved;
	
	PROCEDURE Save*;
		VAR  loc: Files.Locator;  file: Files.File;  wr: Stores.Writer;  res: INTEGER;
	BEGIN
		IF Unsaved() # NIL THEN
			Dialog.ShowMsg('#i21sys:CannotSave');
			Windows.dir.Select( Unsaved(), Windows.lazy )
		ELSE
			InitListFromWindows;  ( * LogList( 'prior to writing to disk' ); * )

			loc := Files.dir.This( savePath );  ASSERT( loc # NIL );
			file := Files.dir.New( loc, Files.dontAsk );  ASSERT( loc.res = 0 );  ASSERT( file # NIL );
			wr.ConnectTo( file );
			wr.WriteString( magic );
			wr.WriteByte( version ); 

			wr.WriteStore( list );

			wr.ConnectTo( NIL );
			file.Register( saveName, '', Files.dontAsk,  res );  ASSERT( res = 0 );
		END;
	END Save;
	
	PROCEDURE SaveAs*;
		VAR  ok: BOOLEAN;  loc: Files.Locator;  fileName: Files.Name;
	BEGIN
		IF Unsaved() # NIL THEN
			Dialog.ShowMsg('#i21sys:CannotSave');
			Windows.dir.Select( Unsaved(), Windows.lazy )
		ELSE
			loc := Files.dir.This( savePath );
			fileName := '';
			Dialog.GetExtSpec( fileName, saveType, loc, fileName );
			ok := loc # NIL;
			IF  ok  THEN
				savePath := loc( HostFiles.Locator ).path$;
				saveName := fileName;

				Save;

				( * Init; * )
			END
		END
	END SaveAs;

	PROCEDURE SaveGuard (VAR par: Dialog.Par);
	( ** checks that there are no unsaved documents ** )
	BEGIN
		par.disabled := ( Unsaved() # NIL )
	END SaveGuard;

	PROCEDURE CloseAllWindows (): BOOLEAN;
		VAR  win, prec: Windows.Window;
	BEGIN
		prec := NIL;  win := Windows.dir.First();
		WHILE  ( win # NIL ) & ( win # prec )  DO
			Windows.dir.Select( win, FALSE );
			HostCmds.Close();
			prec := win;  win := Windows.dir.First();
		END;
		RETURN  win = NIL
	END CloseAllWindows;

	PROCEDURE Exit*;
	BEGIN
		HostCmds.SaveAll;
		IF Unsaved() # NIL THEN
			Dialog.ShowMsg('#i21sys:CannotExit');
			Windows.dir.Select( Unsaved(), Windows.lazy )
		ELSE
			Save;
			HostMenus.Exit
		END
	END Exit; 

	PROCEDURE Close*;
		VAR ok: BOOLEAN;
	BEGIN
		IF Unsaved() # NIL THEN
			Dialog.ShowMsg('#i21sys:CannotExit');
			Windows.dir.Select( Unsaved(), Windows.lazy )
		ELSE
			Save;
			ok := CloseAllWindows();
		END
	END Close;

	PROCEDURE RestoreFromFile ( file: Files.File );
		VAR  rd: Stores.Reader;  s: Stores.Store;  mag: ARRAY 100 OF CHAR;  v: BYTE;  ok: BOOLEAN;
	BEGIN
		ASSERT( file # NIL, 20 );
		rd.ConnectTo( file );
		rd.ReadString( mag );
		ok := ( mag = magic );
		IF  ok  THEN
			rd.ReadByte( v );
			ok := ( v = version );
		END;
		IF  ok  THEN

			rd.ReadStore( s );  IF  s # NIL  THEN  list := s( Link )  END;
			( * LogList( 'just from disk' ); * )

			RestoreWindowsFromList;

		END;
		rd.ConnectTo( NIL );
	END RestoreFromFile;
	
	PROCEDURE RestoreFrom* ( name: ARRAY OF CHAR );
		VAR  loc: Files.Locator;  file: Files.File;  ok: BOOLEAN;
	BEGIN
		loc := Files.dir.This('');
		ok := loc # NIL;
		IF  ok  THEN
			file := Files.dir.Old( loc, name$, Files.shared );
			ok := ( loc.res = 0 ) & ( file # NIL );
		END;
		IF  ok  THEN
			RestoreFromFile( file );
		END;
	END RestoreFrom;
	
	PROCEDURE Restore*;
		VAR  loc: Files.Locator;  file: Files.File;   ok: BOOLEAN;
	BEGIN
		loc := Files.dir.This( savePath );
		ok := loc # NIL;
		IF  ok  THEN
			file := Files.dir.Old( loc, saveName, Files.shared );
			ok := ( loc.res = 0 ) & ( file # NIL );
		END;
		IF  ok  THEN
			RestoreFromFile( file );
		END;
	END Restore;
	
	PROCEDURE Open*;
		VAR  ok: BOOLEAN;  loc: Files.Locator;  fileName: Files.Name;
	BEGIN
		loc := Files.dir.This( savePath );
		fileName := saveName;
		Dialog.GetIntSpec( saveType, loc, fileName );
		ok := loc # NIL;
( *
		IF  ok  THEN
			ok := CloseAllWindows();
		END;
		Log.Ln;  Log.Bool( ok );  Log.Ln;
* )
		IF  ok  THEN
			savePath := loc( HostFiles.Locator ).path$;
			saveName := fileName$; ( * здесь оно возвращается с расширением * )

			Restore;

			( * Init; * )
		END;
	END Open;

BEGIN  Init
END  i21sysDesktop.
*)
(* ===== конец исходного кода ===== *)

MODULE  i21sysDesktop; (* FVT 2009-03-17; last changed: 2010-09-21 *)

(**  **)
(* 20120529, ТЕЭ ReadConverter: добавлена проверка, чтобы избежать повторной регистрации конвертера *)

(* Derived from PrivDesktop by 
		Bruno Essmann (bessmann@iiic.ethz.ch), 
		Guy Laden (laden@math.tau.ac.il), 
		Iain Scott (iain.i.scott@gecm.com); 
	see also Desktop at http://www.zinnamturm.eu.
	This version by Fyodor Tkachov is an attempt to simpify and clarify the original. *)

	IMPORT  Strings,  Files,  Stores,  Views,  TextViews,  TextControllers,  
		Dialog,  Converters,  StdCmds,  Log := StdLog,  
		Windows,  Documents,  HostFiles,  HostWindows,  HostCmds,  HostMenus;
	
	CONST
		version = 1;
		minimized = 0;  maximized = 1;  (* Window states *)
		logTitle = "#Dev:Log";
		saveType = "i21";
	
	VAR
		(* magic = 'Информатика-21' (ADR-246). GPCP читает исходник как
		   Latin-1, поэтому не-латинские символы заданы через CHR; Stores
		   пишет CHAR как UTF-16LE, и magic совпадает с оригинальным .i21. *)
		magic: ARRAY 15 OF CHAR;
		saveName-: Files.Name;
		savePath-: ARRAY 2000 OF CHAR;
		
		list: Link;
		failed: BOOLEAN;
		
	TYPE
		Window = Windows.Window;
		
		Path = POINTER TO ARRAY OF CHAR;
	
		Link = POINTER TO RECORD ( Stores.Store)
			next: Link;
			level: INTEGER; (* > 0; номер окна во внутр. списке ОСи; XP переводит фокус в голову списка *)
			win: Window;
			title: Views.Title;
			w, h: INTEGER; (* ширина и высота вьюшки в пикселях *)
			l, t, r, b: INTEGER; (* позиция окна (с рамками и т.п.) на экране в пикселях *)
			state: SET;
			i: Info;
			e: Extension;
		END;
		
		Info = POINTER TO ABSTRACT RECORD ( Stores.Store) END;
		
		LogInfo = POINTER TO RECORD ( Info)
		END;
	
		DocInfo = POINTER TO RECORD ( Info)
			path: Path;
			name: Files.Name;
			conv: Converters.Converter;
		END;
	
		TempInfo = POINTER TO RECORD ( Info)
			flags: SET;
			doc: Documents.Document;
			dirty: BOOLEAN;
			title: Views.Title; (* копия соотв. Link.title *)
		END;
	
		SubInfo = POINTER TO RECORD ( Info)
			parent: INTEGER;
		END;
		
		Extension = POINTER TO ABSTRACT RECORD ( Stores.Store) END;
		TextExt = POINTER TO RECORD ( Extension)
			rangeBeg, rangeEnd: INTEGER;  (* visible range *)
			caretPos: INTEGER;  (* position of caret *)
			selBeg, selEnd: INTEGER;  (* selection settings *)
		END;
		SubTextExt = POINTER TO RECORD ( Extension)
			rangeBeg, rangeEnd: INTEGER;  (* visible range *)
		END;
	

	PROCEDURE InitMagic;
	BEGIN
		magic[0]  := CHR(0418H);  magic[1]  := CHR(043DH);
		magic[2]  := CHR(0444H);  magic[3]  := CHR(043EH);
		magic[4]  := CHR(0440H);  magic[5]  := CHR(043CH);
		magic[6]  := CHR(0430H);  magic[7]  := CHR(0442H);
		magic[8]  := CHR(0438H);  magic[9]  := CHR(043AH);
		magic[10] := CHR(0430H);  magic[11] := "-";
		magic[12] := "2";         magic[13] := "1";
		magic[14] := 0X
	END InitMagic;
	
	
	PROCEDURE GetPath ( loc: Files.Locator;  OUT isLocal: BOOLEAN;  OUT path: Path);
	(* returns relative path w.r.t. (secondary) BlackBox path, unless loc is external *)
		VAR  bbpath, absolute: Path;  pos: INTEGER;
	BEGIN
		ASSERT( loc # NIL);

		NEW( bbpath, LEN( Files.dir.This('')( HostFiles.Locator).path$) + 1);
		bbpath^ := Files.dir.This('')( HostFiles.Locator).path$;

		NEW( absolute, LEN( loc( HostFiles.Locator).path$) + 1); 
		absolute^ := loc( HostFiles.Locator).path$; 

		NEW( path, LEN( absolute));
		path^ := absolute$;
		Strings.Find( path, bbpath, 0, pos);
		isLocal := ( pos = 0);
		IF  isLocal  THEN (* можно "оторвать" bbpath от начала path *)
			Strings.Replace( path, 0, LEN( bbpath$) + 1, '');
		END;
	END GetPath;

	PROCEDURE WriteConverter ( VAR wr: Stores.Writer;  c: Converters.Converter);
		VAR  
	BEGIN
		IF  c # NIL  THEN
			wr.WriteString( c.imp);
			wr.WriteString( c.exp);
			wr.WriteString( c.storeType);
			wr.WriteString( c.fileType);
			wr.WriteSet( c.opts)
		ELSE
			wr.WriteString('');  wr.WriteString('');  (* sentinel *)
		END
	END WriteConverter;

	PROCEDURE ReadConverter ( VAR rd: Stores.Reader;  OUT conv: Converters.Converter);
		VAR  imp, exp: Dialog.String;
			storeType: Stores.TypeName;  fileType: Files.Type;  opts: SET;
			c: Converters.Converter;
	BEGIN
		rd.ReadString( imp);
		rd.ReadString( exp);

		IF  ( imp = '') & ( exp = '')  THEN  conv := NIL;  RETURN  END;

		rd.ReadString( storeType);
		rd.ReadString( fileType);
		rd.ReadSet( opts);

		c := Converters.list;
		WHILE ( c # NIL) & 
			~( ( c.imp = imp) & ( c.exp = exp) & 
				( c.storeType = storeType) & ( c.fileType = fileType) & ( c.opts = opts))
		DO
			c := c.next
		END;

		IF c = NIL THEN
			Converters.Register( imp, exp, storeType, fileType, opts);
			c := Converters.list;
			WHILE ( c # NIL) & 
				~( ( c.imp = imp) & ( c.exp = exp) & 
					( c.storeType = storeType) & ( c.fileType = fileType) & ( c.opts = opts))
			DO
				c := c.next
			END
		END;

		conv := c
	END ReadConverter;
	
	
	PROCEDURE IsLog ( win: Windows.Window): BOOLEAN;
		VAR  title: Views.Title;
	BEGIN
		win.GetTitle( title);
		(* JVM: HostWindows.GetTitle отдаёт уже отображённый заголовок
		   («Log»), а не ключ «#Dev:Log»; принимаем оба, иначе окно Log
		   сохранялось бы как TempInfo со встроенным документом. *)
		RETURN  ( title = logTitle) OR ( title = "Log")
	END IsLog;
	
	
(*
	PROCEDURE LogList ( s: ARRAY OF CHAR);
		VAR  l: Link;
	BEGIN
		Log.Ln;  Log.String('*********** LogList, ' + s);  Log.Ln;
		l := list;
		WHILE  l # NIL  DO
			Log.Int( l.level);
			Log.String( '  ' + l.title);
			IF   l.i IS SubInfo  THEN  Log.String(' --вторичное')  END;
			Log.Ln;
			Log.Int( l.w);  Log.Int( l.h);  Log.Ln;
			Log.Int( l.l);  Log.Int( l.t);  Log.Int( l.r);  Log.Int( l.b);  Log.Ln;
			Log.Set( l.state);  Log.Ln;
			Log.Ln;
			l := l.next
		END;
	END LogList;
*)	
	
	PROCEDURE NewLink ( win: Window): Link;
		VAR  l: Link;  mn, mx: BOOLEAN;
	BEGIN
		ASSERT( win # NIL);
		NEW( l);
		win.GetTitle( l.title);
		win.GetSize( l.w, l.h); (* размер вьюшки в единицах BlackBox *)

		(* JVM (ADR-246): GetWindowPlacement/IsIconic/IsZoomed ->
		   GetLeft/GetTop/GetRight/GetBottom/IsMinimized/IsMaximized *)
		l.l := win( HostWindows.Window).GetLeft();
		l.t := win( HostWindows.Window).GetTop();
		l.r := win( HostWindows.Window).GetRight();
		l.b := win( HostWindows.Window).GetBottom();
		mn := win( HostWindows.Window).IsMinimized();
		mx := win( HostWindows.Window).IsMaximized();

		l.state := {};
		IF  mn  THEN  INCL( l.state, minimized)  END;
		IF  mx  THEN  INCL( l.state, maximized)  END;

		RETURN  l
	END NewLink;
	
	PROCEDURE ( l: Link) Restore ( win: Window), NEW;
	BEGIN
		win.SetTitle( l.title);
		win.SetSize( l.w, l.h);

		(* JVM (ADR-246): MoveWindow + ShowWindow -> SetPlacement.
		   Состояние ставится здесь же, после Windows.dir.Select: выбор окна
		   снимает icon-флаг, поэтому minimized/maximized должны применяться
		   последними. *)
		win( HostWindows.Window).SetPlacement( l.l, l.t, l.r, l.b,
			minimized IN l.state, maximized IN l.state)
	END Restore;
	
	
	PROCEDURE ( l: Link) Externalize ( VAR wr: Stores.Writer);
	BEGIN
		wr.WriteStore( l.i);
		wr.WriteStore( l.e);

		wr.WriteInt( l.level);
		wr.WriteString( l.title);
		wr.WriteInt( l.w);  wr.WriteInt( l.h);

		wr.WriteInt( l.l);
		wr.WriteInt( l.t);
		wr.WriteInt( l.r);
		wr.WriteInt( l.b);

		wr.WriteSet( l.state);

		wr.WriteStore( l.next)
	END Externalize;
	
	PROCEDURE ( l: Link) Internalize ( VAR rd: Stores.Reader);
		VAR  s: Stores.Store;
	BEGIN
		rd.ReadStore( s);
		l.i := s( Info);
		rd.ReadStore( s);
		IF  s # NIL  THEN  l.e := s( Extension)  END;

		rd.ReadInt( l.level);
		rd.ReadString( l.title);
		rd.ReadInt( l.w);  rd.ReadInt( l.h);

		rd.ReadInt( l.l);
		rd.ReadInt( l.t);
		rd.ReadInt( l.r);
		rd.ReadInt( l.b);

		rd.ReadSet( l.state);

		rd.ReadStore( s);
		IF  s # NIL  THEN  l.next := s( Link)  END;
	END Internalize;
	
	
	PROCEDURE ( i: Info) Init ( win: Windows.Window), NEW, ABSTRACT;
	PROCEDURE ( i: Info) NewWindow (): Windows.Window, NEW, ABSTRACT;
	
	PROCEDURE ( i: LogInfo) Init ( win: Windows.Window);
	BEGIN
	END Init;
	
	PROCEDURE ( info: LogInfo) NewWindow (): Windows.Window;
		VAR  win: Windows.Window;
	BEGIN
		Log.Open;
		win := Windows.dir.First();
		WHILE ( win # NIL) & ~IsLog( win) DO
			win := Windows.dir.Next( win)
		END;
		ASSERT( win # NIL);
		RETURN  win
	END NewWindow;
	
	PROCEDURE ( i: DocInfo) Init ( win: Windows.Window);
		VAR  isLocal: BOOLEAN;
	BEGIN
		ASSERT( win # NIL, 20);
		IF  win.loc # NIL  THEN
			GetPath( win.loc, isLocal, i.path); (* isLocal not used ... yet? *)
			i.name := win.name;
			i.conv := win.conv;
		ELSE
		END;
	END Init;
	
	PROCEDURE ( i: DocInfo) NewWindow (): Windows.Window;
		VAR  loc: Files.Locator;  v: Views.View;  win: Windows.Window;
	BEGIN
		loc := Files.dir.This( i.path);
		v := Views.Old( Views.dontAsk, loc, i.name, i.conv);
		IF  v # NIL  THEN
			Views.Open( v, loc, i.name, i.conv);

			win := Windows.dir.First();
			WHILE  ( win # NIL) & ~( win.doc.ThisView() = v)  DO
				win := Windows.dir.Next( win)
			END;
			ASSERT( win # NIL);
		ELSE
			win := NIL;
			Dialog.ShowParamMsg( "#i21sys:UnableToRestoreDocument", i.name, "", "");
			(* ws.type := AlienWindow *)
		END;
		RETURN  win
	END NewWindow;
	
	PROCEDURE ( i: TempInfo) Init ( win: Windows.Window);
	BEGIN
		ASSERT( win # NIL, 20);
		i.flags := win.flags;
		i.doc := win.doc;
		win.GetTitle( i.title);
		i.dirty := ~( Windows.neverDirty IN win.flags) & win.seq.Dirty();
	END Init;
	
	PROCEDURE ( i: TempInfo) NewWindow (): Windows.Window;
		VAR  win: Windows.Window;
	BEGIN
		win := Windows.dir.New();
		Windows.dir.OpenSubWindow( win, i.doc, i.flags, i.title);
		win.SetSpec( NIL, '', NIL);
		IF  i.dirty  THEN  win.seq.SetDirty( TRUE)  END;
		RETURN  win
	END NewWindow;
	
	PROCEDURE ( i: SubInfo) Init ( win: Windows.Window);
	BEGIN
	END Init;
	
	PROCEDURE ( i: SubInfo) NewWindow (): Windows.Window;
		VAR  l: Link;  win: Windows.Window;
	BEGIN
		l := list;
		WHILE ( l # NIL) & ~( l.level = i.parent) DO  l := l.next  END;
		ASSERT( ( l # NIL) & ( l.level = i.parent));

		IF  l.win # NIL  THEN
			Windows.dir.Select( l.win, Windows.eager);
			StdCmds.NewWindow();
			win := Windows.dir.Focus( FALSE);
		ELSE
			win := NIL
		END;
		RETURN  win
	END NewWindow;
	
	PROCEDURE NewInfo ( win: Window): Info;
		VAR  i: Info;  log: LogInfo;  doc: DocInfo;  sub: SubInfo;
			parent: Window;  l: Link;
	BEGIN
		IF  ~win.sub  THEN
			IF  win.name # ''  THEN
				NEW( doc);  i := doc;
			ELSIF  IsLog( win)  THEN
				NEW( log);  i := log;
			ELSE
				(* JVM: TempInfo встраивает Documents.Document через отдельный
				   Stores.Writer; вложенный writer/reader этого порта пока не
				   проходит round-trip, поэтому несохранённые документы в
				   .i21 не попадают (окно пропускается) — см. README. *)
				i := NIL
			END;
		ELSE
			parent := win.link;
			WHILE  parent.sub  DO  parent := parent.link  END;

			l := list;
			WHILE ( l # NIL) & ~( l.win = parent) DO  l := l.next  END;
			ASSERT( ( l # NIL) & ( l.win = parent));

			NEW( sub);  sub.parent := l.level;  i := sub
		END;

		RETURN  i
	END NewInfo;
	
	PROCEDURE ( i: LogInfo) Externalize ( VAR wr: Stores.Writer);
	BEGIN
	END Externalize;
	
	PROCEDURE ( i: LogInfo) Internalize ( VAR rd: Stores.Reader);
	BEGIN
	END Internalize;
	
	PROCEDURE ( i: DocInfo) Externalize ( VAR wr: Stores.Writer);
	BEGIN
		wr.WriteString( i.path);

		wr.WriteString( i.name);

		WriteConverter( wr, i.conv);
	END Externalize;
	
	PROCEDURE ( i: DocInfo) Internalize ( VAR rd: Stores.Reader);
		VAR  string: ARRAY 2000 OF CHAR;
	BEGIN
		rd.ReadString( string);  NEW( i.path, LEN( string$) + 1);  i.path^ := string$;

		rd.ReadString( i.name);

		ReadConverter( rd, i.conv);
	END Internalize;
	
	PROCEDURE ( i: TempInfo) Externalize ( VAR wr: Stores.Writer);
		VAR  wr1: Stores.Writer;
	BEGIN
		wr.WriteSet( i.flags);
		wr.WriteBool( i.dirty);
		wr.WriteString( i.title);
		wr1.ConnectTo( wr.rider.Base()); (* иначе проблема с Domain *)
		wr1.SetPos( wr.Pos());
		wr1.WriteStore( i.doc);
		wr.SetPos( wr1.Pos());
		wr1.ConnectTo( NIL);
	END Externalize;
	
	PROCEDURE ( i: TempInfo) Internalize ( VAR rd: Stores.Reader);
		VAR  s: Stores.Store;  rd1: Stores.Reader;
	BEGIN
		rd.ReadSet( i.flags);
		rd.ReadBool( i.dirty);
		rd.ReadString( i.title);
		rd1.ConnectTo( rd.rider.Base()); (* иначе проблема с Domain *)
		rd1.SetPos( rd.Pos());
		rd1.ReadStore( s);
		rd.SetPos( rd1.Pos());
		i.doc := s( Documents.Document);
		rd1.ConnectTo( NIL);
	END Internalize;
	
	PROCEDURE ( i: SubInfo) Externalize ( VAR wr: Stores.Writer);
	BEGIN
		wr.WriteInt( i.parent);
	END Externalize;
	
	PROCEDURE ( i: SubInfo) Internalize ( VAR rd: Stores.Reader);
	BEGIN
		rd.ReadInt( i.parent);
	END Internalize;
	
	
	PROCEDURE NewExtension ( v: Views.View;  sub: BOOLEAN): Extension;
		VAR  e: Extension;  t: TextExt;  s: SubTextExt;
	BEGIN
		e := NIL;
		IF  v # NIL  THEN
			WITH  v: TextViews.View  DO

				IF  sub  THEN
					NEW( s);  e := s;
				ELSE
					NEW( t);  e := t;
				END;

			ELSE
			END;
		END;
		RETURN  e
	END NewExtension;
	
	PROCEDURE ( e: Extension) Init ( v: Views.View;  f: Views.Frame), NEW, ABSTRACT;
	PROCEDURE ( e: Extension) Restore ( v: Views.View;  f: Views.Frame), NEW, ABSTRACT;
	
	PROCEDURE ( e: TextExt) Init ( v: Views.View;  f: Views.Frame);
		VAR  c: TextControllers.Controller;
	BEGIN
		WITH  v: TextViews.View  DO

			v.GetRange( f, e.rangeBeg, e.rangeEnd);
			c := v.ThisController()( TextControllers.Controller);
			e.caretPos := c.CaretPos();
			c.GetSelection( e.selBeg, e.selEnd);

		END;
	END Init;
	
	PROCEDURE ( e: TextExt) Restore ( v: Views.View;  f: Views.Frame);
		VAR  c: TextControllers.Controller;  len: INTEGER;
	BEGIN
		IF  v # NIL  THEN
			WITH  v: TextViews.View  DO
				len := v.ThisModel().Length();
				IF  e.rangeEnd <= len  THEN
					v.ShowRangeIn( f, e.rangeBeg, e.rangeEnd);
				END;
				c := v.ThisController()( TextControllers.Controller);
				IF ( 0 <= e.caretPos) & ( e.caretPos <= len) THEN
					c.SetCaret( e.caretPos);
				END;
				IF ( e.selBeg <= e.selEnd) & ( e.selEnd <= len) THEN
					c.SetSelection( e.selBeg, e.selEnd);
				END;
			END;
		END;
	END Restore;
	
	PROCEDURE ( e: SubTextExt) Init ( v: Views.View;  f: Views.Frame);
	BEGIN
		WITH  v: TextViews.View  DO
			v.GetRange( f, e.rangeBeg, e.rangeEnd);
		END;
	END Init;
	
	PROCEDURE ( e: SubTextExt) Restore ( v: Views.View;  f: Views.Frame);
	BEGIN
		WITH  v: TextViews.View  DO
			v.ShowRangeIn( f, e.rangeBeg, e.rangeEnd);
		END;
	END Restore;
	
	
	PROCEDURE ( e: TextExt) Externalize ( VAR wr: Stores.Writer);
	BEGIN
		wr.WriteInt( e.rangeBeg);
		wr.WriteInt( e.rangeEnd);
		wr.WriteInt( e.selBeg);
		wr.WriteInt( e.selEnd);
		wr.WriteInt( e.caretPos);
	END Externalize;
	
	PROCEDURE ( e: TextExt) Internalize ( VAR rd: Stores.Reader);
	BEGIN
		rd.ReadInt( e.rangeBeg);
		rd.ReadInt( e.rangeEnd);
		rd.ReadInt( e.selBeg);
		rd.ReadInt( e.selEnd);
		rd.ReadInt( e.caretPos);
	END Internalize;
	
	PROCEDURE ( e: SubTextExt) Externalize ( VAR wr: Stores.Writer);
	BEGIN
		wr.WriteInt( e.rangeBeg);
		wr.WriteInt( e.rangeEnd);
	END Externalize;
	
	PROCEDURE ( e: SubTextExt) Internalize ( VAR rd: Stores.Reader);
	BEGIN
		rd.ReadInt( e.rangeBeg);
		rd.ReadInt( e.rangeEnd);
	END Internalize;
	
	
	PROCEDURE InitListFromWindows;
		VAR  new: Link;  win: Window;  level, sub: INTEGER;  v: Views.View;
	BEGIN
		list := NIL;

		(* обрабатываем сначала (sub=1) первичные, потом (sub=2) вторичные окна: *)
		FOR  sub := 1  TO  2  DO

			level := 0;  win := Windows.dir.First();
			WHILE  win # NIL  DO

				INC( level);
				IF  ( sub = 2) = win.sub  THEN
					new := NewLink( win);
					new.i := NewInfo( win);
					IF  new.i # NIL  THEN
						new.level := level;
						new.win := win;
						new.i.Init( win);
						v := win.doc.ThisView();
						new.e := NewExtension( v, win.sub);
						IF  new.e # NIL  THEN
							new.e.Init( v, win.frame);
						END;
						new.next := list;  list := new;
					END;
				END;

				win := Windows.dir.Next( win);
			END;

		END;

	END InitListFromWindows;
	
	PROCEDURE RestoreWindowsFromList;
		VAR  new, l: Link;  nwin, level: INTEGER;
	BEGIN
		(* обратить list *)
		nwin := 0;
		new := NIL;
		l := list;
		WHILE  l # NIL  DO  INC( nwin);
			list := list.next;
			l.next := new;  new := l;
			l := list
		END;
		list := new;
		(* LogList( 'после обращения'); (* нарушает порядок окон? *) *)
		
		(* восстанавливаем окна с содержимым, не заботясь о расположении;
			список в данный момент устроен так, что сначала идут основные окна, потом вторичные *)
		l := list;
		WHILE  l # NIL  DO
			l.win := l.i.NewWindow();
			IF  l.win # NIL  THEN
			ELSE
				Dialog.ShowParamMsg( "#i21sys:UnableToRestoreDocument", l.title, "", "");
			END;
			l := l.next;
		END;
		(* InitListFromWindows;  LogList( 'после восстановления, без расположения'); *)
		
		(* восстанавливаем расположение, с конца по level *)
		level := nwin;
		WHILE  level > 0  DO

			l := list;
			WHILE ( l # NIL) & ~( l.level = level) DO  l := l.next  END;

			IF  l.win # NIL  THEN
				Windows.dir.Select( l.win, Windows.eager); (* поднимаем окно наверх *)
				l.Restore( l.win);
				IF  l.e # NIL  THEN
					l.e.Restore( l.win.doc.ThisView(), l.win.frame);
				END;
			END;

			DEC( level);
		END;
		(* InitListFromWindows;  LogList( 'после восстановления'); *)

	END RestoreWindowsFromList;
	

	
	
	PROCEDURE Init;
	BEGIN
		InitMagic;
		savePath := '';  saveName := 'desktop.' + saveType;
	END Init;


	PROCEDURE Unsaved (): Windows.Window;
		VAR  w: Windows.Window;
	BEGIN
		w := Windows.dir.First();
		WHILE (w # NIL) & ~( w.seq.Dirty() & ~(Windows.neverDirty IN w.flags)) DO
			w := Windows.dir.Next(w)
		END;
		RETURN  w
	END Unsaved;
	
	PROCEDURE Save*;
		VAR  loc: Files.Locator;  file: Files.File;  wr: Stores.Writer;  res: INTEGER;
	BEGIN
		IF Unsaved() # NIL THEN
			Dialog.ShowMsg('#i21sys:CannotSave');
			Windows.dir.Select( Unsaved(), Windows.lazy)
		ELSE
			InitListFromWindows;  (* LogList( 'prior to writing to disk'); *)

			loc := Files.dir.This( savePath);  ASSERT( loc # NIL);
			file := Files.dir.New( loc, Files.dontAsk);  ASSERT( loc.res = 0);  ASSERT( file # NIL);
			wr.ConnectTo( file);
			wr.WriteString( magic);
			wr.WriteByte( version); 

			wr.WriteStore( list);

			wr.ConnectTo( NIL);
			file.Register( saveName, '', Files.dontAsk,  res);  ASSERT( res = 0);
		END;
	END Save;
	
	PROCEDURE SaveAs*;
		VAR  ok: BOOLEAN;  loc: Files.Locator;  fileName: Files.Name;
	BEGIN
		IF Unsaved() # NIL THEN
			Dialog.ShowMsg('#i21sys:CannotSave');
			Windows.dir.Select( Unsaved(), Windows.lazy)
		ELSE
			loc := Files.dir.This( savePath);
			fileName := '';
			Dialog.GetExtSpec( fileName, saveType, loc, fileName);
			ok := loc # NIL;
			IF  ok  THEN
				savePath := loc( HostFiles.Locator).path$;
				saveName := fileName;

				Save;

				(* Init; *)
			END
		END
	END SaveAs;

	PROCEDURE SaveGuard (VAR par: Dialog.Par);
	(** checks that there are no unsaved documents **)
	BEGIN
		par.disabled := ( Unsaved() # NIL)
	END SaveGuard;

	PROCEDURE CloseAllWindows (): BOOLEAN;
		VAR  win, prec: Windows.Window;
	BEGIN
		prec := NIL;  win := Windows.dir.First();
		WHILE  ( win # NIL) & ( win # prec)  DO
			Windows.dir.Select( win, FALSE);
			HostCmds.Close();
			prec := win;  win := Windows.dir.First();
		END;
		RETURN  win = NIL
	END CloseAllWindows;

	PROCEDURE Exit*;
	BEGIN
		HostCmds.SaveAll;
		IF Unsaved() # NIL THEN
			Dialog.ShowMsg('#i21sys:CannotExit');
			Windows.dir.Select( Unsaved(), Windows.lazy)
		ELSE
			Save;
			HostMenus.Exit
		END
	END Exit; 

	PROCEDURE Close*;
		VAR ok: BOOLEAN;
	BEGIN
		IF Unsaved() # NIL THEN
			Dialog.ShowMsg('#i21sys:CannotExit');
			Windows.dir.Select( Unsaved(), Windows.lazy)
		ELSE
			Save;
			ok := CloseAllWindows();
		END
	END Close;

	PROCEDURE HasTempInfo ( file: Files.File): BOOLEAN;
	(* JVM (ADR-246): .i21, записанный оригиналом с несохранёнными
	   документами (TempInfo), вложенный Stores.Reader этого порта не
	   читает. Проверяем имя типа в потоке и отказываемся от чтения —
	   лучше сообщение, чем HALT(100) внутри Stores. *)
		VAR  pat: ARRAY 32 OF CHAR;
			len, i, j: INTEGER;  r: Files.Reader;  b: BYTE;  found: BOOLEAN;
	BEGIN
		pat := "i21sysDesktop.TempInfoDesc";
		found := FALSE;
		len := file.Length();
		IF  len > 0  THEN
			r := file.NewReader( NIL);
			i := 0;  j := 0;
			WHILE  (i < len) & ~found  DO
				r.ReadByte( b);  INC( i);
				IF  b = ORD( pat[j])  THEN
					INC( j);
					IF  pat[j] = 0X  THEN  found := TRUE  END
				ELSIF  b = ORD( pat[0])  THEN  j := 1
				ELSE  j := 0
				END
			END
		END;
		RETURN  found
	END HasTempInfo;
	
	
	PROCEDURE RestoreFromFile ( file: Files.File);
		VAR  rd: Stores.Reader;  s: Stores.Store;  mag: ARRAY 100 OF CHAR;  v: BYTE;  ok: BOOLEAN;
	BEGIN
		ASSERT( file # NIL, 20);
		IF  HasTempInfo( file)  THEN
			Log.String( "i21sys: unsaved documents (TempInfo) are not restored on JVM");
			Log.Ln;
			RETURN
		END;
		rd.ConnectTo( file);
		rd.ReadString( mag);
		ok := ( mag = magic);
		IF  ok  THEN
			rd.ReadByte( v);
			ok := ( v = version);
		END;
		IF  ok  THEN

			rd.ReadStore( s);  IF  s # NIL  THEN  list := s( Link)  END;
			(* LogList( 'just from disk'); *)

			RestoreWindowsFromList;

		END;
		rd.ConnectTo( NIL);
	END RestoreFromFile;
	
	PROCEDURE RestoreFrom* ( name: ARRAY OF CHAR);
		VAR  loc: Files.Locator;  file: Files.File;  ok: BOOLEAN;
	BEGIN
		loc := Files.dir.This('');
		ok := loc # NIL;
		IF  ok  THEN
			file := Files.dir.Old( loc, name$, Files.shared);
			ok := ( loc.res = 0) & ( file # NIL);
		END;
		IF  ok  THEN
			RestoreFromFile( file);
		END;
	END RestoreFrom;
	
	PROCEDURE Restore*;
		VAR  loc: Files.Locator;  file: Files.File;   ok: BOOLEAN;
	BEGIN
		loc := Files.dir.This( savePath);
		ok := loc # NIL;
		IF  ok  THEN
			file := Files.dir.Old( loc, saveName, Files.shared);
			ok := ( loc.res = 0) & ( file # NIL);
		END;
		IF  ok  THEN
			RestoreFromFile( file);
		END;
	END Restore;
	
	PROCEDURE Open*;
		VAR  ok: BOOLEAN;  loc: Files.Locator;  fileName: Files.Name;
	BEGIN
		loc := Files.dir.This( savePath);
		fileName := saveName;
		Dialog.GetIntSpec( saveType, loc, fileName);
		ok := loc # NIL;
(*
		IF  ok  THEN
			ok := CloseAllWindows();
		END;
		Log.Ln;  Log.Bool( ok);  Log.Ln;
*)
		IF  ok  THEN
			savePath := loc( HostFiles.Locator).path$;
			saveName := fileName$; (* здесь оно возвращается с расширением *)

			Restore;

			(* Init; *)
		END;
	END Open;

BEGIN  Init
END  i21sysDesktop.
