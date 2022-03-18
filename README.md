This was an experiment in making a debugger wrapper, so that we can use native C++ debugging, and generate additional information so we can translate these stacks to Haxe code.

This project is currently on hold, and it implements a debug adapter that acts as a proxy for the C++ debugger, and allows one to add functionality on top of that