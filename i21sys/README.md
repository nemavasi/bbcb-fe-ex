# i21sys на JVM

`i21sys` — внешняя подсистема «Информатика-21» (Ф. В. Ткачёв): ввод из
текста (`i21sysIn`), запуск внешних программ (`i21sysCalls`), определение
платформы (`i21sysInfo`), сохранение рабочего стола в `.i21`
(`i21sysDesktop`), национальные символы, сканер, словарь и правка
ключевых слов.

Подсистема перенесена на **чистый Component Pascal** (ADR-246): в её
исходниках нет `WinApi`, `SYSTEM`, `[untagged]`, `[code]`. Win32-операции
заменены на методы хост-слоя:

| Было (Win32) | Стало (JVM) |
|---|---|
| `GetWindowPlacement`/`IsIconic`/`IsZoomed` | `HostWindows.Window.GetLeft/GetTop/GetRight/GetBottom/IsMinimized/IsMaximized` |
| `MoveWindow`/`ShowWindow` | `HostWindows.Window.SetPlacement` |
| `ShellExecuteW` | `HostDialog.Open` (`Desktop.open`/`xdg-open`/`open`/`cmd /c start`) |
| `CreateProcess` | `HostDialog.Start` (`ProcessBuilder`) |
| `LoadLibrary("ntdll")`/`wine_get_version` | `Dialog.platform` (выставляет `HostRegistry.Init` по `os.name`) |

Клиентский интерфейс не менялся: имена модулей, экспортируемые процедуры,
типы, переменные и константы — как в оригинале.

## Модули

| Модуль | Назначение |
|---|---|
| `i21sysIn` | поток ввода из текста/выделения/коммандера |
| `i21sysInObx` | пример ввода чисел из текста |
| `i21sysCalls` | `Start(exe)` и `Open(file)` |
| `i21sysInfo` | `platform: REAL` (`linux` = 30, `macOSX` = 22, `windows8` = 10) |
| `i21sysDesktop` | `Save`/`SaveAs`/`Restore`/`RestoreFrom`/`Open`/`Exit`/`Close` |
| `i21sysCharacters` | национальный набор символов |
| `i21sysLatin1` | Latin-1 (основа `Characters`) |
| `i21sysScanner` | сканер ключевых слов |
| `i21sysText` | утилиты текста |
| `i21sysVocabulary` | словарь ключевых слов/подсказок |
| `i21sysEdit` | капитализация и правка ключевых слов |

## `.i21`

Файл рабочего стола — стандартный Stores-поток:

```text
"Информатика-21"   (UTF-16LE, как Stores.WriteString)
version = 1        (байт)
Store(Link)        (окна: LogInfo/DocInfo/SubInfo + TextExt/SubTextExt)
```

`i21sysDesktop` сохраняет заголовки, размеры, позицию, состояние
`minimized/maximized`, прокрутку/каретку/выделение. Документы хранятся
**ссылками** (`path` + `name` + конвертер), поэтому `.i21` открывается и
оригинальной сборкой BlackBox, и портом.

### Ограничение JVM-порта

Несохранённые документы (`TempInfo`) в `.i21` не попадают: оригинал
встраивает `Documents.Document` через отдельный `Stores.Writer`, а
вложенный writer/reader этого порта пока не проходит round-trip. Такие
окна при сохранении пропускаются (без падения); сохранённые документы и
окно `Log` восстанавливаются полностью. Если старый `.i21` всё же
содержит `TempInfo`, порт пишет сообщение в `Log` и не читает файл —
вместо `HALT(100)` внутри `Stores`. Это единственное известное отличие
от оригинала.

## Сборка и проверка

Внутри приложения: открыть `i21sys/Mod/Desktop.Mod` → `Dev→Compile`.

Сквозная проверка (сборка 11 модулей, отсутствие платформенного кода,
`platform`, геометрия окна, `.i21`):

```sh
tools/gpcp/smoke_i21sys.sh
```
