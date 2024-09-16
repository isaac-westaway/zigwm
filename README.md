Overview
=====
Simple Dependency free window manager written in Zig

This project is depreceated, due to my lack of knowledge of the X Window System, and will move to another window manager, also in zig, but using a c imported XLib.

> [!WARNING]
> There is an odd error when the window manager is run with a unix stream socket of X1, an out-of-bounds error will occur in ZWM, GrabKeys, KeySymtoKeyCode and KeySymatCol.
> Until I fix this, just make sure when running `startx` that the socket is `X0` by running `startx -- :0`


Todos
=====
- implement teardown logic of x_connection
- CreateCursor
- proper logging ( no more _ = try)
- catch statements should switch between errors instead of just erroring
- send workspace list (desktop_properties) and client list (wmctrl)
- all the todos in the comments
- delete zigwm.log on startup

Credits
======
Juicebox window manager, a lot of inspiration came from there, though the code is (relatively) old so this is an updated version.
Most of the stuff in src/x11 has been copied from Juicebox, or the Xorg reference manual
