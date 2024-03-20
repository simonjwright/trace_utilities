--  Copyright (C) 2024 Simon Wright <simon@pushface.org>
--  SPDX: GPL-3.0-or-later WITH GCC-exception-3.1

--  Some code taken from Ada.Exceptions.Exception_Data.

with System.Storage_Elements;
with Ada.Text_IO;

package body Trace_Utilities is

   function Hex_Address (A : System.Address) return String;

   function Load_Address return String
   is
      function Get_Executable_Load_Address return System.Address;
      pragma Import (C, Get_Executable_Load_Address,
                     "__gnat_get_executable_load_address");
      --  Get the load address of the executable, or Null_Address if not known
   begin
      return Hex_Address (Get_Executable_Load_Address);
   end Load_Address;

   function Hex_Address (A : System.Address) return String
   is
      S : String (1 .. 18);
      P : Natural;
      N : System.Storage_Elements.Integer_Address;

      H : constant array (Integer range 0 .. 15) of Character :=
            "0123456789abcdef";

      use type System.Storage_Elements.Integer_Address;
   begin
      P := S'Last;
      N := System.Storage_Elements.To_Integer (A);
      loop
         S (P) := H (Integer (N mod 16));
         P := P - 1;
         N := N / 16;
         exit when N = 0;
      end loop;

      S (P - 1) := '0';
      S (P) := 'x';

      return S (P - 1 .. S'Last);
   end Hex_Address;

end Trace_Utilities;
