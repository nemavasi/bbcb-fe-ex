MODULE KafkaDemo;
(** Пример работы с брокером сообщений через модуль `KafkaWork` (ADR-200).

    Клиент — официальная библиотека `kafka-clients` (входит в поставку).
    Параметры подключения и текст сообщения передаются через интерфейс
    `KafkaWork` (переменные `bootstrap`, `group`, `topic`, `key`, `message`,
    ADR-234); их можно задать здесь или через `KafkaWork.DebugOptions`.

    Соберите модуль (`Dev -> Compile`) и выполните `KafkaDemo.SendReceive`
    (`Dev -> Execute`). Результат — в окне `Log`. *)

  IMPORT KafkaWork, StdLog;

  (** Отправить сообщение и прочитать его из топика. *)
  PROCEDURE SendReceive*;
    VAR value: ARRAY 4096 OF CHAR; ok: BOOLEAN;
  BEGIN
    KafkaWork.topic := "blackbox-demo";
    KafkaWork.key := "demo";
    KafkaWork.message := "hello from BlackBox";
    ok := KafkaWork.Send("", "", "");
    IF ok THEN
      StdLog.String("sent to "); StdLog.String(KafkaWork.topic); StdLog.Ln;
      ok := KafkaWork.Receive("", 15000, value);
      IF ok THEN
        StdLog.String("received: "); StdLog.String(value); StdLog.Ln
      ELSE StdLog.String("KafkaDemo: nothing received in 15 s"); StdLog.Ln
      END
    ELSE StdLog.String("KafkaDemo: send failed (check KafkaWork.bootstrap / KafkaWork.DebugOptions)"); StdLog.Ln
    END
  END SendReceive;

  (** Только отправка — по одному сообщению за вызов. *)
  PROCEDURE SendOne*;
  BEGIN
    KafkaWork.topic := "blackbox-demo";
    KafkaWork.key := "manual";
    KafkaWork.message := "one message";
    IF KafkaWork.Send("", "", "") THEN
      StdLog.String("sent: one message"); StdLog.Ln
    ELSE StdLog.String("KafkaDemo: send failed"); StdLog.Ln
    END
  END SendOne;

  (** Только приём — ждёт до 10 секунд. *)
  PROCEDURE ReceiveOne*;
    VAR value: ARRAY 4096 OF CHAR;
  BEGIN
    KafkaWork.topic := "blackbox-demo";
    IF KafkaWork.Receive("", 10000, value) THEN
      StdLog.String("received: "); StdLog.String(value); StdLog.Ln
    ELSE StdLog.String("KafkaDemo: nothing received"); StdLog.Ln
    END
  END ReceiveOne;

END KafkaDemo.
