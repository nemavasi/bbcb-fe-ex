/*
 * SPDX-License-Identifier: BSD-3-Clause
 * Copyright (c) 2026 nemavasi
 */

package CP.KafkaWork;

import java.time.Duration;
import java.util.Collections;
import java.util.Properties;
import java.util.UUID;

import org.apache.kafka.clients.consumer.ConsumerConfig;
import org.apache.kafka.clients.consumer.ConsumerRecord;
import org.apache.kafka.clients.consumer.ConsumerRecords;
import org.apache.kafka.clients.consumer.KafkaConsumer;
import org.apache.kafka.clients.producer.KafkaProducer;
import org.apache.kafka.clients.producer.ProducerConfig;
import org.apache.kafka.clients.producer.ProducerRecord;
import org.apache.kafka.common.serialization.StringDeserializer;
import org.apache.kafka.common.serialization.StringSerializer;

/**
 * Java-тело {@code KafkaWork} — официальный клиент Apache Kafka (ADR-200,
 * ADR-234).
 *
 * <p>Параметры подключения и текст сообщения — переменные модуля (ADR-234),
 * как {@code url/user/password/defQuery} у {@code SqlPostgres}. Они читаются
 * из {@code HostRegistry} при загрузке класса, задаются диалогом
 * {@link #DebugOptions()} и используются процедурами {@link #Send}/
 * {@link #Receive}/{@link #Demo}. Системные свойства
 * {@code -Dblackbox.kafka.*} остаются запасным вариантом для смоуков/CI.</p>
 */
public final class KafkaWork {

    // ---- переменные модуля (объявлены в KafkaWork.cp, ADR-234) ------------

    /** {@code bootstrap}: адрес брокера. */
    public static char[] bootstrap = new char[256];

    /** {@code group}: группа потребителя. */
    public static char[] group = new char[128];

    /** {@code topic}: топик по умолчанию. */
    public static char[] topic = new char[128];

    /** {@code key}: ключ сообщения по умолчанию. */
    public static char[] key = new char[128];

    /** {@code message}: текст сообщения для {@code Send}/{@code Demo}. */
    public static char[] message = new char[1024];

    static {
        loadSettings();
    }

    /** Прочитать параметры из реестра ({@code HostRegistry}). */
    static void loadSettings() {
        try {
            char[] buf = new char[256];
            if (CP.HostRegistry.HostRegistry.ReadString(z("kafka.bootstrap"), buf, 0) == 0) {
                copyInto(buf, bootstrap);
            }
            buf = new char[128];
            if (CP.HostRegistry.HostRegistry.ReadString(z("kafka.group"), buf, 0) == 0) {
                copyInto(buf, group);
            }
            buf = new char[128];
            if (CP.HostRegistry.HostRegistry.ReadString(z("kafka.topic"), buf, 0) == 0) {
                copyInto(buf, topic);
            }
            buf = new char[128];
            if (CP.HostRegistry.HostRegistry.ReadString(z("kafka.key"), buf, 0) == 0) {
                copyInto(buf, key);
            }
            buf = new char[1024];
            if (CP.HostRegistry.HostRegistry.ReadString(z("kafka.message"), buf, 0) == 0) {
                copyInto(buf, message);
            }
        } catch (Throwable t) {
            // реестр ещё не поднят — переменные пусты, сработают свойства
        }
    }

    /** Сохранить параметры в реестр. */
    static void saveSettings() {
        try {
            CP.HostRegistry.HostRegistry.WriteString(z("kafka.bootstrap"), bootstrap);
            CP.HostRegistry.HostRegistry.WriteString(z("kafka.group"), group);
            CP.HostRegistry.HostRegistry.WriteString(z("kafka.topic"), topic);
            CP.HostRegistry.HostRegistry.WriteString(z("kafka.key"), key);
            CP.HostRegistry.HostRegistry.WriteString(z("kafka.message"), message);
        } catch (Throwable t) {
            log("Kafka: cannot save settings: " + t);
        }
    }

    /** Параметр: переменная модуля, иначе системное свойство, иначе `def`. */
    static String param(char[] var, String prop, String def) {
        String v = str(var);
        if (!v.isEmpty()) {
            return v;
        }
        String p = System.getProperty(prop, "");
        return p.isEmpty() ? def : p;
    }

    static String bootstrapValue() {
        return param(bootstrap, "blackbox.kafka.bootstrap", "localhost:9092");
    }

    static String groupValue() {
        return param(group, "blackbox.kafka.group", "blackbox");
    }

    static String topicValue() {
        return param(topic, "blackbox.kafka.topic", "blackbox-demo");
    }

    static String keyValue() {
        return param(key, "blackbox.kafka.key", "");
    }

    static String messageValue() {
        String v = str(message);
        if (!v.isEmpty()) {
            return v;
        }
        String p = System.getProperty("blackbox.kafka.message", "");
        if (p.isEmpty()) {
            p = System.getProperty("blackbox.kafka.demo.text", "");
        }
        return p.isEmpty() ? "hello from BlackBox JVM" : p;
    }

    private static Properties producerProps() {
        Properties p = new Properties();
        p.put(ProducerConfig.BOOTSTRAP_SERVERS_CONFIG, bootstrapValue());
        p.put(ProducerConfig.KEY_SERIALIZER_CLASS_CONFIG, StringSerializer.class.getName());
        p.put(ProducerConfig.VALUE_SERIALIZER_CLASS_CONFIG, StringSerializer.class.getName());
        p.put(ProducerConfig.ACKS_CONFIG, "all");
        p.put(ProducerConfig.DELIVERY_TIMEOUT_MS_CONFIG, "15000");
        p.put(ProducerConfig.REQUEST_TIMEOUT_MS_CONFIG, "10000");
        p.put(ProducerConfig.MAX_BLOCK_MS_CONFIG, "15000");
        return p;
    }

    private static Properties consumerProps() {
        Properties p = new Properties();
        p.put(ConsumerConfig.BOOTSTRAP_SERVERS_CONFIG, bootstrapValue());
        p.put(ConsumerConfig.GROUP_ID_CONFIG, groupValue());
        p.put(ConsumerConfig.KEY_DESERIALIZER_CLASS_CONFIG, StringDeserializer.class.getName());
        p.put(ConsumerConfig.VALUE_DESERIALIZER_CLASS_CONFIG, StringDeserializer.class.getName());
        p.put(ConsumerConfig.AUTO_OFFSET_RESET_CONFIG, "earliest");
        p.put(ConsumerConfig.ENABLE_AUTO_COMMIT_CONFIG, "true");
        p.put(ConsumerConfig.CLIENT_ID_CONFIG, "blackbox-" + UUID.randomUUID());
        return p;
    }

    // -------------------------------------------------------------- команды

    /**
     * {@code Connect}: зафиксировать параметры подключения.
     *
     * <p>У Kafka нет постоянного соединения: {@code KafkaProducer}/
     * {@code KafkaConsumer} создаются на каждый вызов. Поэтому {@code Connect}
     * запоминает адрес/группу в переменных модуля и сохраняет их в реестре;
     * пустые аргументы оставляют текущие значения.</p>
     */
    public static boolean Connect(char[] bootstrapArg, char[] groupArg) {
        if (bootstrapArg != null && !str(bootstrapArg).isEmpty()) {
            copyInto(bootstrapArg, bootstrap);
        }
        if (groupArg != null && !str(groupArg).isEmpty()) {
            copyInto(groupArg, group);
        }
        saveSettings();
        String b = bootstrapValue();
        if (b.isEmpty()) {
            log("Kafka: пустой bootstrap — задайте его в KafkaWork.DebugOptions");
            return false;
        }
        log("Kafka: configured bootstrap=" + b + " group=" + groupValue());
        return true;
    }

    /** {@code Disconnect}: у Kafka нет постоянного соединения. */
    public static void Disconnect() {
        log("Kafka: disconnected");
    }

    /** {@code Send}: записать сообщение в топик. */
    public static boolean Send(char[] topicArg, char[] keyArg, char[] valueArg) {
        String t = str(topicArg);
        if (t.isEmpty()) {
            t = topicValue();
        }
        String k = str(keyArg);
        if (k.isEmpty()) {
            k = keyValue();
        }
        String v = str(valueArg);
        if (v.isEmpty()) {
            v = messageValue();
        }
        try (KafkaProducer<String, String> p = new KafkaProducer<>(producerProps())) {
            p.send(new ProducerRecord<>(t, k.isEmpty() ? null : k, v)).get();
            log("Kafka: sent to " + t + " (" + v.length() + " char(s))");
            return true;
        } catch (Throwable e) {
            log("Kafka: send failed: " + e.getMessage());
            return false;
        }
    }

    /** {@code Receive}: прочитать первое сообщение (не дольше `timeoutMs`). */
    public static boolean Receive(char[] topicArg, int timeoutMs, char[] value) {
        String t = str(topicArg);
        if (t.isEmpty()) {
            t = topicValue();
        }
        int ms = timeoutMs <= 0 ? 10000 : timeoutMs;
        try (KafkaConsumer<String, String> c = new KafkaConsumer<>(consumerProps())) {
            c.subscribe(Collections.singletonList(t));
            long deadline = System.currentTimeMillis() + ms;
            while (System.currentTimeMillis() < deadline) {
                ConsumerRecords<String, String> recs = c.poll(Duration.ofMillis(500));
                for (ConsumerRecord<String, String> r : recs) {
                    copy(r.value(), value);
                    log("Kafka: received from " + t + ": "
                            + (r.value() == null ? "" : r.value()));
                    return true;
                }
            }
            copy("", value);
            log("Kafka: no message in " + t + " within " + ms + " ms");
            return false;
        } catch (Throwable e) {
            log("Kafka: receive failed: " + e.getMessage());
            copy("", value);
            return false;
        }
    }

    /** {@code Demo}: отправить и прочитать сообщение из переменных модуля. */
    public static void Demo() {
        String t = topicValue();
        String k = keyValue();
        String text = messageValue();
        boolean sent = Send(z(""), z(""), z(""));
        char[] got = new char[8192];
        boolean received = sent && Receive(z(""), 15000, got);
        String value = str(got);
        log("Kafka.Demo: sent=" + sent + " received=" + received);
        show("Kafka: demo",
                "bootstrap = " + bootstrapValue() + "\r"
                        + "group = " + groupValue() + "\r"
                        + "topic = " + t + "\r"
                        + "key = " + (k.isEmpty() ? "(none)" : k) + "\r\r"
                        + "sent = " + sent + "\r"
                        + "sent text = " + text + "\r\r"
                        + "received = " + received + "\r"
                        + "received text = " + value);
    }

    /**
     * {@code DebugOptions}: диалог параметров подключения и текста сообщения.
     *
     * <p>По OK значения пишутся в переменные модуля и в реестр
     * ({@code kafka.bootstrap/group/topic/key/message}), поэтому действуют
     * после перезапуска.</p>
     */
    public static void DebugOptions() {
        if (java.awt.GraphicsEnvironment.isHeadless()) {
            log("Kafka.DebugOptions: нет дисплея; параметры — переменные модуля");
            return;
        }
        final String[] result = new String[5];
        Runnable show = () -> {
            javax.swing.JTextField fBootstrap = new javax.swing.JTextField(str(bootstrap), 40);
            javax.swing.JTextField fGroup = new javax.swing.JTextField(str(group), 24);
            javax.swing.JTextField fTopic = new javax.swing.JTextField(str(topic), 30);
            javax.swing.JTextField fKey = new javax.swing.JTextField(str(key), 24);
            javax.swing.JTextField fMessage = new javax.swing.JTextField(str(message), 40);
            javax.swing.JPanel p = new javax.swing.JPanel(new java.awt.GridBagLayout());
            java.awt.GridBagConstraints c = new java.awt.GridBagConstraints();
            c.insets = new java.awt.Insets(3, 6, 3, 6);
            c.anchor = java.awt.GridBagConstraints.WEST;
            javax.swing.JComponent[] fields = {fBootstrap, fGroup, fTopic, fKey, fMessage};
            String[] labels = {"Брокер (host:port):", "Группа потребителя:", "Топик:",
                    "Ключ:", "Текст сообщения:"};
            for (int i = 0; i < labels.length; i++) {
                c.gridx = 0;
                c.gridy = i;
                c.weightx = 0;
                c.fill = java.awt.GridBagConstraints.NONE;
                p.add(new javax.swing.JLabel(labels[i]), c);
                c.gridx = 1;
                c.weightx = 1;
                c.fill = java.awt.GridBagConstraints.HORIZONTAL;
                p.add(fields[i], c);
            }
            c.gridx = 0;
            c.gridy = labels.length;
            c.gridwidth = 2;
            c.fill = java.awt.GridBagConstraints.HORIZONTAL;
            p.add(new javax.swing.JLabel("Пример: 127.0.0.1:9092"), c);
            Object[] opts = {"OK", "Отмена"};
            int r = javax.swing.JOptionPane.showOptionDialog(null, p,
                    "Kafka: параметры", javax.swing.JOptionPane.OK_CANCEL_OPTION,
                    javax.swing.JOptionPane.PLAIN_MESSAGE, null, opts, opts[0]);
            if (r == 0) {
                result[0] = fBootstrap.getText().trim();
                result[1] = fGroup.getText().trim();
                result[2] = fTopic.getText().trim();
                result[3] = fKey.getText().trim();
                result[4] = fMessage.getText();
            }
        };
        try {
            if (javax.swing.SwingUtilities.isEventDispatchThread()) {
                show.run();
            } else {
                javax.swing.SwingUtilities.invokeAndWait(show);
            }
        } catch (Throwable t) {
            log("Kafka.DebugOptions: " + t);
            return;
        }
        if (result[0] == null) {
            return;                                  // отмена
        }
        copyInto(z(result[0]), bootstrap);
        copyInto(z(result[1]), group);
        copyInto(z(result[2]), topic);
        copyInto(z(result[3]), key);
        copyInto(z(result[4]), message);
        saveSettings();
        log("Kafka: параметры сохранены (bootstrap=" + bootstrapValue() + ")");
        show("Kafka: options",
                "Параметры сохранены в переменных модуля `KafkaWork` и в реестре.\r\r"
                        + "bootstrap = " + str(bootstrap) + "\r"
                        + "group     = " + str(group) + "\r"
                        + "topic     = " + str(topic) + "\r"
                        + "key       = " + str(key) + "\r"
                        + "message   = " + str(message) + "\r\r"
                        + "Проверить: KafkaWork.Demo.\r");
    }

    /** {@code Help}: документация подсистемы `Kafka`. */
    public static void Help() {
        try {
            char[] title = new char[64];
            copy("Kafka", title);
            CP.StdCmds.StdCmds.OpenAux(z("Kafka/Docu/KafkaWork"), title);
        } catch (Throwable t) {
            log("Kafka.Help: " + t);
        }
    }

    // -------------------------------------------------------------- утилиты

    private static void show(String title, String text) {
        try {
            CP.TextModels.TextModels_Model m = CP.TextModels.TextModels.dir.NewFromString(z(text));
            CP.TextViews.TextViews_View v = CP.TextViews.TextViews.dir.New(m);
            CP.Views.Views.OpenAux(v, z(title));
        } catch (Throwable t) {
            log("Kafka: cannot open result document: " + t);
        }
    }

    private static void log(String s) {
        try {
            CP.StdLog.StdLog.String(z(s));
            CP.StdLog.StdLog.Ln();
        } catch (Throwable t) {
            System.err.println(s);
        }
    }

    private static void copy(String s, char[] out) {
        if (out == null) {
            return;
        }
        if (s == null) {
            s = "";
        }
        int limit = out.length - 1;
        int n = Math.min(s.length(), limit);
        s.getChars(0, n, out, 0);
        out[n] = 0;
    }

    private static void copyInto(char[] src, char[] dst) {
        copy(str(src), dst);
    }

    static String str(char[] c) {
        if (c == null) {
            return "";
        }
        int n = 0;
        while (n < c.length && c[n] != 0) {
            n++;
        }
        return new String(c, 0, n);
    }

    static char[] z(String s) {
        char[] c = new char[s.length() + 1];
        s.getChars(0, s.length(), c, 0);
        return c;
    }

    private KafkaWork() {
    }
}
