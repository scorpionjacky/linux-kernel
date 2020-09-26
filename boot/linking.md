# How Linker Works with C/C++

https://www.lurklurk.org/linkers/linkers.html

https://www.tenouk.com/ModuleW.html
- https://www.tenouk.com/download.html
- https://www.tenouk.com/Sitemap.html

https://citeseerx.ist.psu.edu/viewdoc/download?doi=10.1.1.369.339&rep=rep1&type=pdf

[Introduction to System Software, Summer 2004](http://homepage.divms.uiowa.edu/~jones/syssoft/notes/)
- [Chapter 7, Linkers and Loaders](http://homepage.divms.uiowa.edu/~jones/syssoft/notes/07link.html)
- http://homepage.divms.uiowa.edu/~jones/

https://lwn.net/Articles/276782/

https://www.embhack.com/difference-between-linker-and-loader/

[Google Interview Questions Deconstructed: The Knight’s Dialer](https://alexgolec.dev/google-interview-questions-deconstructed-the-knights-dialer/)

http://labe.felk.cvut.cz/~stepan/AE3B33OSD/

http://doursat.free.fr/docs/CS446_S06/CS446_S06_3_Memory2.pdf

https://www.ics.uci.edu/~aburtsev/cs5460/

**compiler+link**

A declaration of a function or a variable is a promise to the C compiler that somewhere else in the program is a definition for that function or variable, and that the linker's jobs is to make good on that promise.

`nm` can show all symbols and their types and status in an object file.

*Duplicate Symbols*

If the linker cannot find a definition for a symbol to join to references to that symbol, then it will give an error message. So what happens if there are two definitions for a symbol when it comes to link time?

In C++, the situation is straightforward. The language has a constraint known as the one definition rule, which says that there has to be exactly one definition for a symbol when it comes to link time, no more and no less. (The relevant section of the C++ standard is 3.2, which also mentions some exceptions that we'll come to later on.)

For C, things are slightly less clear. There has to be exactly one definition of any functions or initialized global variables, but the definition of an uninitialized global variable can be treated as a tentative definition. C then allows (or at least does not forbid) different source files to have tentative definitions for the same object.

However, linkers also have to cope with other programming languages than just C and C++, and the one definition rule isn't always appropriate for them. For example, the normal model for Fortran code is effectively to have a copy of each global variable in every file that references it; the linker is required to fold duplicates by picking one of the copies (the largest version, if they are different sizes) and throw away the rest. (This model is sometimes known as the "common model" of linking, after the Fortran COMMON keyword.)

As a result, it's actually quite common for UNIX linkers not to complain about duplicate definitions of symbols—at least, not when the duplicate symbol is an uninitialized global variable (this is sometimes known as the "relaxed ref/def model" of linking). If this worries you (and it probably should), check the documentation for your compiler linker—there may well be a --work-properly option that tightens up the behavior. For example, for the GNU toolchain the -fno-common option to the compiler forces it to put uninitialized variables into the BSS segment rather than generating these common blocks.
