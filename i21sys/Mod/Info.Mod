(** Модуль изменён при портировании BlackBox на JVM. Исходный код сохранён ниже в комментарии; активен портированный вариант. *)
(* ===== ИСХОДНЫЙ КОД (до портирования, закомментирован) =====
MODULE i21sysInfo;	( ** 	правки
- 20101019, ТЕЭ, Оформление для публикации
 ** )
( * 20100413, ТЕЭ, Создан для расширенного определения хост-платформы в i21sysCalls.Open.

Средство выделено в отдельный модуль из соображений, что ещё могут быть тулзы, для работоспособности которых будет важно определить "место" запуска: Windows или wine. * )

	IMPORT Dialog, WinApi, HostDialog;

	CONST	( * из Dialog * )
		windows32s* = 11;
		windows95* = 12;
		windowsNT3* = 13;
		windowsNT4* = 14;
		windows2000* = 15;
		windows98* = 16;
		windowsXP* = 17;
		windowsVista* = 18;
		macOS* = 21;
		macOSX* = 22;
		linux* = 30;
		tru64* = 40;
	
	CONST
		wine* = 17.5;

	VAR
		platform*: REAL;	( * REAL, т.к. для видновсов со свободными значениями для констант Dialog.windows... типа INTEGER напряжёнка * )

	PROCEDURE Init;
		VAR	h: WinApi.HMODULE; adr: WinApi.FARPROC; res: WinApi.BOOL;
	BEGIN
		( * в ББ 1.5-1.6 HostDialog выставляет Dialog.platform; его импорт гарантирует инициализированность * )
		platform := Dialog.platform; ASSERT(platform # 0, 100);
		( * http://habrahabr.ru/blogs/development/76131/ * )
		h := WinApi.LoadLibrary("ntdll.dll");
		IF h # WinApi.NULL THEN
			adr := WinApi.GetProcAddress(h, "wine_get_version");
			IF adr # NIL THEN platform := wine END;
			res := WinApi.FreeLibrary(h)
		END
	END Init;

BEGIN
	Init
END i21sysInfo.
*)
(* ===== конец исходного кода ===== *)

MODULE i21sysInfo;	(** 	правки
- 20101019, ТЕЭ, Оформление для публикации
 **)
(* 20100413, ТЕЭ, Создан для расширенного определения хост-платформы в i21sysCalls.Open.

Средство выделено в отдельный модуль из соображений, что ещё могут быть тулзы, для работоспособности которых будет важно определить "место" запуска: Windows или wine.

   JVM-порт (ADR-246): LoadLibrary/GetProcAddress (ntdll,
   wine_get_version) заменены на `Dialog.platform`, который выставляет
   `HostRegistry.Init` по `os.name`. Wine определяется через
   `Dialog.IsWine` (хук, если его зарегистрировал хост). *)

	IMPORT Dialog;

	CONST	(* из Dialog *)
		windows32s* = 11;
		windows95* = 12;
		windowsNT3* = 13;
		windowsNT4* = 14;
		windows2000* = 15;
		windows98* = 16;
		windowsXP* = 17;
		windowsVista* = 18;
		macOS* = 21;
		macOSX* = 22;
		linux* = 30;
		tru64* = 40;
	
	CONST
		wine* = 17.5;

	VAR
		platform*: REAL;	(* REAL, т.к. для видновсов со свободными значениями для констант Dialog.windows... типа INTEGER напряжёнка *)

	PROCEDURE Init;
	BEGIN
		(* в оригинале Dialog.platform выставлял win32-HostDialog; на JVM —
		   HostRegistry.Init (os.name), см. ADR-246 *)
		platform := Dialog.platform;
		IF platform = 0 THEN platform := linux END;
		IF Dialog.IsWine() THEN platform := wine END
	END Init;

BEGIN
	Init
END i21sysInfo.
