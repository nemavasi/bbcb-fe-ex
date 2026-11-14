MODULE i21sysText;
	IMPORT  Log := StdLog,  In := i21sysIn,  Ports,  Strings,  TextControllers,  M := TextModels;
	
	PROCEDURE Offset0*;
	(** guard: TextCmds.SelectionGuard **)
		VAR  c: TextControllers.Controller;  t: M.Model;  rd: M.Reader;
			beg, end: INTEGER;  a, new: M.Attributes;  ch: CHAR;  
	BEGIN
		c := TextControllers.Focus();
		IF (c # NIL) & c.HasSelection() THEN
			c.GetSelection(beg, end);
			t := c.text;  
			rd := t.NewReader(rd);
			rd.SetPos(end - 1);
			rd.ReadChar(ch);
			a := rd.attr;
			new := M.NewOffset(a, 0);
			t.SetAttr(beg, end, new);
			c.SetSelection(beg, end);
		END
	END Offset0;

	PROCEDURE Raise*;
	(** guard: TextCmds.SelectionGuard **)
		VAR  c: TextControllers.Controller;  t: M.Model;  rd: M.Reader;
			beg, end: INTEGER;  a, new: M.Attributes;  ch: CHAR;
	BEGIN
		c := TextControllers.Focus();
		IF (c # NIL) & c.HasSelection() THEN
			c.GetSelection(beg, end);
			t := c.text;  rd := t.NewReader(rd);
			rd.SetPos(end - 1);
			rd.ReadChar(ch);
			a := rd.attr;
			new := M.NewOffset(a, a.offset + Ports.point DIV 2);
			t.SetAttr(beg, end, new);
			c.SetSelection(beg, end)
		END
	END Raise;

	PROCEDURE Lower*;
	(** guard: TextCmds.SelectionGuard **)
		VAR  c: TextControllers.Controller;  t: M.Model;  rd: M.Reader;
			beg, end: INTEGER;  a, new: M.Attributes;  ch: CHAR;
	BEGIN
		c := TextControllers.Focus();
		IF  (c # NIL) & c.HasSelection()  THEN
			c.GetSelection(beg, end);
			t := c.text;
			rd := t.NewReader(rd);
			rd.SetPos(end - 1);
			rd.ReadChar(ch);
			a := rd.attr;
			new := M.NewOffset(a, a.offset - Ports.point DIV 2);
			t.SetAttr(beg, end, new);
			c.SetSelection(beg, end);
		END
	END Lower;
	
	
END i21sysText.