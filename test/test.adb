--  Copyright (C) 2024 Simon Wright <simon@pushface.org>
--  SPDX: GPL-3.0-or-later WITH GCC-exception-3.1

with Ada.Text_Io;
with Trace_Utilities;

procedure Test is
begin
   Ada.Text_IO.Put_Line (Trace_Utilities.Load_Address);
end Test;
