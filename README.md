The need for this package arose while looking into an issue with Emacs Ada Mode on macOS.

To support fontification, indentation etc Emacs Ada Mode works out the detailed structure of the code using a parser program, which runs as a subprocess of Emacs itself. Under some circumstances, an exception was occurring which made the suprocess fail.

Ideally, you would attach a debugger to the subprocess, set it to catch exceptions, and then provoke the error; when (if!) the exception is caught, you could examine the call stack to gain insight as to how the error came about.

Unfortunately, GDB doesn't handle the case of position-independent executables (PIE - where the actual load address of the executable is randomised at run time, to make life more difficult for evildoers). While GDB handles PIE when it loads the program itself, it doesn't do so when it attaches to a running process, so that it can't work out the actual address of a particular symbol.

macOS doesn't support non-PIE links.

The parser program can already print out the stack trace when an exception occurs, using `GNAT.Traceback.Symbolic.Symbolic_Traceback`.

Now, if the OS supports symbolic traceback, that would be great; unfortunately, although Linux and Windows do, macOS doesn't. Instead, you get a hex listing. A typical report from an unhandled exception from e.g.
```
with Ada.Text_IO;
procedure Raiser is
   procedure Inner(N: Natural) is
   begin
      if N <= 5 then
         raise Constraint_Error with "a message";
      end if;
      Inner(N - 1);
   end Inner;
begin
   Inner(10);
end Raiser;
```
would be
```
Execution of ./raiser terminated by unhandled exception
raised CONSTRAINT_ERROR : a message
Load address: 0x1042b8000
Call stack traceback locations:
0x1042bc578 0x1042bc5a0 0x1042bc5a0 0x1042bc5a0 0x1042bc5a0 0x1042bc5a0 0x1042bc5cc 0x1042bc4f4
```
which is decoded using `atos`:
```
$ atos \
  -o raiser \
  -l 0x1042b8000 \
  0x1042bc578 0x1042bc5a0 0x1042bc5a0 0x1042bc5a0 0x1042bc5a0 0x1042bc5a0 0x1042bc5cc 0x1042bc4f4
raiser__inner.0 (in raiser) (raiser.adb:6)
raiser__inner.0 (in raiser) (raiser.adb:8)
raiser__inner.0 (in raiser) (raiser.adb:8)
raiser__inner.0 (in raiser) (raiser.adb:8)
raiser__inner.0 (in raiser) (raiser.adb:8)
raiser__inner.0 (in raiser) (raiser.adb:8)
_ada_raiser (in raiser) (raiser.adb:11)
main (in raiser) (b~raiser.adb:233)
```
(`-o` gives the executable name, `-l` gives the load address, the remaining arcuments ar the actual stack trace).

`GNAT.Traceback.Symbolic.Symbolic_Traceback` only reports the actual stack trace, so we need to find the load address.

From searching the GNAT runtime, in `a-exexda.adb` (`Ada.Exceptions.Exception_Data`) there's a useful subprogram
```
   function Get_Executable_Load_Address return System.Address;
   pragma Import (C, Get_Executable_Load_Address,
                  "__gnat_get_executable_load_address");
   --  Get the load address of the executable, or Null_Address if not known
```
and the first release of this package provides
```
   function Load_Address return String;
```
so we can include it in the exception report.

---
In due course, it would be good if this functionality could be provided in the version of `GNAT.Traceback.Symbolic.Symbolic_Traceback`.
