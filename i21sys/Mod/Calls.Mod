(** Модуль изменён при портировании BlackBox на JVM. Исходный код сохранён ниже в комментарии; активен портированный вариант. *)
(* ===== ИСХОДНЫЙ КОД (до портирования, закомментирован) =====
MODULE  i21sysCalls; ( **  правки
- 20101019, ТЕЭ, Конверитровано в юникод. Применены правки
	- 20101006, ТЕЭ, Юникодизация
	- 20100413, ТЕЭ, Особая отработка команды открытия из-под wine (см. http://habrahabr.ru/blogs/development/88907/)
	
 ** )
( * 2008-05-19  Ф.В.Ткачев
-- собрано из примеров в сообщениях рассылки BlackBox-Mailing List
* )
	IMPORT  SYSTEM,  WinApi,  HostDialog,  Services, i21sysInfo;
	
	TYPE
		Action = POINTER TO RECORD ( Services.Action )
			fileName: POINTER TO ARRAY OF ( * SHORT * )CHAR;
		END;
	
		ActionExe = POINTER TO RECORD ( Services.Action )
			fileName: POINTER TO ARRAY OF ( * SHORT * )CHAR;
		END;
	
	PROCEDURE ( a: Action ) Do;
		VAR
			hwnd: WinApi.HWND;
			lpOperation, lpFile, lpParameters, lpDirectory: WinApi.PtrWSTR;
			nShowCmd: INTEGER;
			hinst: WinApi.HINSTANCE;
			win_fileName, win_params, win_workDir: ARRAY [untagged] 5000 OF ( * SHORT * )CHAR;
	BEGIN
		IF i21sysInfo.platform = i21sysInfo.wine THEN
			win_fileName := "winebrowser " + a.fileName$
		ELSE
			win_fileName := a.fileName$;
		END;
		win_params := '';
		win_workDir := '';
		lpOperation := "open";
		lpFile := win_fileName;
		lpParameters := win_params;
		lpDirectory := win_workDir;
		nShowCmd := WinApi.SW_SHOW;
		hinst := WinApi.ShellExecuteW( hwnd, lpOperation, lpFile, lpParameters, lpDirectory, nShowCmd );
		( *
		ErrorOut( hinst );
		Log.Bool( hinst > 32 );  Log.Ln;  ( * RETURN hinst > 32; * )
		* )
	END Do;
	
	PROCEDURE ( a: ActionExe ) Do;
		VAR  
	BEGIN
		HostDialog.Start( a.fileName$ )
	END Do;
	
	PROCEDURE Start* ( exeName: ARRAY OF CHAR ); ( ** запуск произвольной внешней программы (EXE); например, notepad.exe; имя может содержать путь; см. примеры коммандеров после текста модуля ** )
		VAR  a: ActionExe; 
	BEGIN
		NEW( a );
		NEW( a.fileName, LEN( exeName$) + 1 );
		a.fileName^ := ( * SHORT( * ) exeName$ ( * ) * );
		Services.DoLater( a, Services.now ); ( * запуск через Action, т.к. иначе ББ не может выполнять другие команды до завершения запуска EXE. * )
	END Start;
	
	PROCEDURE Open* ( fileName: ARRAY OF CHAR ); ( ** открыть произвольный документ ОС MS Windows в (внешней) программе, связанной в реестре ОС с расширением имени файла; например, документ .WAV будет открыт в WinAmp, если последний связан в реестре с файлами .WAV; имя может содержать путь; см. примеры коммандеров после текста модуля ** )
		VAR  a: Action;
	BEGIN
		NEW( a );
		NEW( a.fileName, LEN( fileName$) + 1 );
		a.fileName^ := ( * SHORT( * ) fileName$ ( * ) * );
		Services.DoLater( a, Services.now ); ( * запуск через Action, т.к. иначе ББ не может выполнять другие команды до завершения запуска EXE. * )
	END Open;
	
END i21sysCalls.
*)
(* ===== конец исходного кода ===== *)

MODULE  i21sysCalls; (**  правки
- 20101019, ТЕЭ, Конверитовано в юникод. Применены правки
	- 20101006, ТЕЭ, Юникодизация
	- 20100413, ТЕЭ, Особая отработка команды открытия из-под wine (см. http://habrahabr.ru/blogs/development/88907/)
	
 **)
(* 2008-05-19  Ф.В.Ткачев
-- собрано из примеров в сообщениях рассылки BlackBox-Mailing List

   JVM-порт (ADR-246): ShellExecuteW заменён на `HostDialog.Open`
   (`java.awt.Desktop`/`xdg-open`/`open`/`cmd /c start`), а `Start` — на
   существующий `HostDialog.Start` (`ProcessBuilder`). Клиентский интерфейс
   (`Start*`, `Open*`) не изменён.
*)

	IMPORT  HostDialog,  Services;

	TYPE
		Action = POINTER TO RECORD ( Services.Action)
			fileName: POINTER TO ARRAY OF CHAR;
		END;

		ActionExe = POINTER TO RECORD ( Services.Action)
			fileName: POINTER TO ARRAY OF CHAR;
		END;

	PROCEDURE ( a: Action) Do;
	BEGIN
		HostDialog.Open( a.fileName$)
	END Do;

	PROCEDURE ( a: ActionExe) Do;
	BEGIN
		HostDialog.Start( a.fileName$)
	END Do;

	PROCEDURE Start* ( exeName: ARRAY OF CHAR); (** запуск произвольной внешней программы (EXE); например, notepad.exe; имя может содержать путь; см. примеры коммандеров после текста модуля **)
		VAR  a: ActionExe;
	BEGIN
		NEW( a);
		NEW( a.fileName, LEN( exeName$) + 1);
		a.fileName^ := exeName$;
		Services.DoLater( a, Services.now); (* запуск через Action, т.к. иначе ББ не может выполнять другие команды до завершения запуска EXE. *)
	END Start;

	PROCEDURE Open* ( fileName: ARRAY OF CHAR); (** открыть произвольный документ в (внешней) программе, связанной в ОС с расширением имени файла; например, документ .WAV будет открыт в проигрывателе; имя может содержать путь; см. примеры коммандеров после текста модуля **)
		VAR  a: Action;
	BEGIN
		NEW( a);
		NEW( a.fileName, LEN( fileName$) + 1);
		a.fileName^ := fileName$;
		Services.DoLater( a, Services.now);
	END Open;

END i21sysCalls.
