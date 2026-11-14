/*
 * SPDX-License-Identifier: BSD-3-Clause
 * Copyright (c) 2026 nemavasi
 */

package CP.JSDL3Work;

/** Запись {@code JSDL3Work.Event} (ABI CP-модуля, ADR-243). */
public class JSDL3Work_Event {

    public int type;
    public int key;
    public int scancode;
    public boolean down;
    public int x;
    public int y;
    public int button;

    public JSDL3Work_Event() {
    }

    public void __copy__(JSDL3Work_Event other) {
        type = other.type;
        key = other.key;
        scancode = other.scancode;
        down = other.down;
        x = other.x;
        y = other.y;
        button = other.button;
    }
}
