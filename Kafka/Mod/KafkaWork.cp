(** Kafka — платформенный модуль (ADR-200, ADR-234): брокер сообщений.

    В оригинале своего Kafka-модуля не было; это расширение порта, как и
    `Net`/`Sql`. Клиент — **официальная** Java-библиотека
    `org.apache.kafka:kafka-clients` из Gradle-проекта (`build/gradle-libs`),
    поэтому платформенного кода нет.

    Параметры подключения и текст сообщения передаются **через интерфейс** —
    в переменных модуля (как `url/user/password/defQuery` у `SqlPostgres`):

      * `bootstrap` — адрес брокера (`host:port[,host:port]`);
      * `group` — группа потребителя;
      * `topic` — топик по умолчанию;
      * `key` — ключ сообщения по умолчанию;
      * `message` — текст сообщения для `Send`/`Demo`.

    Переменные можно задать из CP-кода, через `KafkaWork.DebugOptions`
    (диалог) или системными свойствами `-Dblackbox.kafka.*` как запасным
    вариантом для смоуков. Значения из диалога сохраняются в реестре.

    `Connect` фиксирует параметры подключения (у Kafka нет постоянного
    соединения — клиенты создаются на каждый `Send`/`Receive`);
    `Disconnect` оставлен для симметрии с `SqlPostgres`.

    Тело — `CP.KafkaWork.KafkaWork`; компиляция `gpcp -special KafkaWork.cp`. *)
SYSTEM MODULE KafkaWork;

  VAR
    (** Адрес брокера: `host:port[,host:port]`. *)
    bootstrap*: ARRAY 256 OF CHAR;

    (** Группа потребителя. *)
    group*: ARRAY 128 OF CHAR;

    (** Топик по умолчанию. *)
    topic*: ARRAY 128 OF CHAR;

    (** Ключ сообщения по умолчанию. *)
    key*: ARRAY 128 OF CHAR;

    (** Текст сообщения для `Send`/`Demo`. *)
    message*: ARRAY 1024 OF CHAR;

  (** Задать параметры подключения (пустые аргументы — не менять). *)
  PROCEDURE Connect* (bootstrap, group: ARRAY OF CHAR): BOOLEAN;

  (** Сбросить состояние (у Kafka нет постоянного соединения). *)
  PROCEDURE Disconnect*;

  (** Отправить сообщение в топик.

      Пустые `topic`/`key`/`value` означают «взять из переменных модуля». *)
  PROCEDURE Send* (topic, key, value: ARRAY OF CHAR): BOOLEAN;

  (** Прочитать первое сообщение из топика (ждать не дольше `timeoutMs`).

      Пустой `topic` означает «взять `topic` из переменных модуля». *)
  PROCEDURE Receive* (topic: ARRAY OF CHAR; timeoutMs: INTEGER;
                      VAR value: ARRAY OF CHAR): BOOLEAN;

  (** Отправить и прочитать сообщение из переменных модуля. *)
  PROCEDURE Demo*;

  (** Диалог параметров подключения и текста сообщения. *)
  PROCEDURE DebugOptions*;

  (** Документация подсистемы. *)
  PROCEDURE Help*;

END KafkaWork.
