# Small of Shame
This document records our disdain for AMX Mod X and its chosen scripting language.  

Table of contents:  
* [Nearly two decades out of date](#nearly-two-decades-out-of-date)
* [AMX Mod X](#amx-mod-x)
	* [AMXX-Studio](#amxx-studio)
	* [Anything for backwards compatibility](#anything-for-backwards-compatibility)
	* [Bad documentation](#bad-documentation)
	* [Broken standard library](#broken-standard-library)
* [The language](#the-language)
	* [Rules](#rules)
	* [Semicolons - optional until they aren't](#semicolons-optional-until-they-aren-t)
	* [Compiling](#compiling)

## Nearly two decades out of date
AMX Mod X uses an old version of the Small language, a version from around 2005, from before it was renamed to Pawn. This is made clear by the .sma source code extension. People call it Pawn, which is misleading.  
[Repository with "Pawn_Language_Guide.pdf"](https://github.com/compuphase/pawn/tree/master/doc)  
The "Pawn Language Guide", updated in 2016 at the time of writing, is of limited use and is often misleading as it pertains to the language as it has evolved after 2005.  
[(Download) The Small Booklet - The Language (2005)](https://www.doomworld.com/eternity/engine/smalldoc.pdf)  
[(Download) The Small Booklet - Implementor's Guide (2005)](https://www.doomworld.com/eternity/engine/smallguide.pdf)  
The outdated documentation is more representative (The Small Booklet - The Language), however it's unclear precisely what Small version AMX Mod X is derived from, and which changes were made to the syntax by the AMX Mod X team, if any.  

## AMX Mod X
[AMX Mod X](https://www.amxmodx.org/about.php) is a plugin for [Metamod](http://metamod.org/) that makes it possible to write other plugins in Small, which run through the AMX Mod X environment. It includes a programming environment (AMXX-Studio), [API](https://www.amxmodx.org/api/), and compiler.  
It's not very good.  
  
The Sven Co-op team made a wise decision when integrating the more sensible AngelScript language into their mod with their own API, eliminating any possible use case for AMX Mod X.

- AMX Mod X only allows the precache to be interacted with in the plugin_precache forward using the precache_\* natives, offering no means to just check if a model is already precached. This could easily have been made available by exposing a native function that reads from the server_t struct.
	- The engine function accessible with `id = engfunc(EngFunc_ModelIndex, modelpath)` comes close to this functionality, but it's set to raise a system error if the model isn't precached instead of returning a value representing this.

- The natives [get_user_origin](https://www.amxmodx.org/api/amxmodx/get_user_origin) and [set_user_origin](https://www.amxmodx.org/api/amxmodx/set_user_origin) operate on ints, not floats, for reasons unknown. The programmer should always keep this in mind and usually avoid them.  
Getting an int vector is however handy for sending [messages](https://www.amxmodx.org/api/message_const).  
	- Use [entity_set_origin](https://www.amxmodx.org/api/engine/entity_set_origin)(id, EV_VEC_origin, origin) / [entity_set_vector](https://www.amxmodx.org/api/engine/entity_set_vector)(id, EV_VEC_origin, origin) and [entity_get_vector](https://www.amxmodx.org/api/engine/entity_set_vector)(id, EV_VEC_origin, origin) instead to get the player's origin as a float vector.  

- The standard library is missing a file truncate function. If you want to shorten a file, you have to delete the file and rewrite it.

### AMXX-Studio
This software is bundled with the AMX Mod X installation package, and is also featured separately on the downloads page, which implies that it is recommended by the AMX Mod X team.  
It was last updated in 2006, and is soon to be two decades out of date, shipping with documentation for AMX Mod X from that time.  
It has its own fair share of problems, too.  

- It has strange and unfamiliar shortcuts, like click and hold + mouse wheel to resize text instead of ctrl + mouse wheel, and ctrl + delete to close a tab instead of ctrl + w.

- The keyboard shortcuts are written in German.

- AMXX-Studio does not recognise and syntax highlight public functions if they're declared with the @ prefix.

- It does not recognise procedure calling syntax, only recognising function calling syntax to display the function signature.
	- When displaying the function signature, it loses the ability to autocomplete arguments. You can get them while using procedure calling syntax.
	
- It offers indentation support for any amount of spaces, *but only deletes one space at a time*.

- Tab characters are extremely wide and can not be configured.

- It somehow uses a monospace font where the space character is not monospace.

- The customisable toolbar at the top does not save any layout changes and will break itself into a disconnected mess when starting the program, presumably because of the small default window size, which also does not save changes.

- Find & replace all performs each replacement as a separate action, so if you want to undo it, you have to undo each and every single replacement individually.

- By default, notes or per-file configurations are stored inside the opened code file as an appended comment. This setting can be changed, but for some reason the *recommended* setting, storing the information in program configs, is not the default one.

- The code inspector is ignorant of or wrong about many features of the Small language, its problems include but are not limited to:
	- Not understanding static non-assignment declarations
	- Not being aware of tags or special declaration keywords for declarations
	- Sectioning assignment statements wrong such that a final comma or comment is considered part of the assigned expression
	- Not understanding assert statements
	- Incorrectly identifying public functions declared with `@` syntax as being internal and having a "`@`" type
	- Misidentifying procedure call syntax as an invalid function call
	- Misaligning doc comment extraction such that the final character is missing
	- Failing to parse tag lists like `{_, Float}:` in function signatures, representing them as "1"
	- Misidentifying a for loop as being invalid if the increment field is empty
	- Adding its own space to the increment field when editing a for loop and parsing it back again, causing a new space to be added each time an edit is made
	- Causing a runtime error when attempting to edit an inlined for loop
	- Being easily led into nonsense parsing by adding inline doc comments

### Anything for backwards compatibility
The AMX Mod X library has accumulated many mistakes over the years that have not been corrected for the sake of backwards compatibility. They either get left in or an alternative is provided.

- [floatadd](https://www.amxmodx.org/api/float/floatadd) has parameters with wrong names. They were lazily copy & pasted from [floatdiv](https://www.amxmodx.org/api/float/floatdiv).

- [include/tfcconst.inc](https://github.com/alliedmodders/amxmodx/blob/master/plugins/include/tfcconst.inc#L75) provides both the constants TFC_PC_ENGENEER and TFC_PC_ENGINEER.

- [register_event](https://www.amxmodx.org/api/amxmodx/register_event) provides a workaround for a bug, leaving it unfixed.

- [client_disconnect](https://www.amxmodx.org/api/amxmodx/client_disconnect) has been deprecated [since 2015](https://github.com/alliedmodders/amxmodx/commit/ed4faf7c114495db7426023c2b47914523fcdfd1) and will never be removed.

### Bad documentation
The AMX Mod X documentation is very sloppy and is full of grammar and spelling errors and wrong information. Many pages are missing or aren't complete.  
It's often hard to judge whether the problem sits with the documentation or the library. When that happens, it's probably both.

- Formatting rules are undocumented. This is baffling, because it's an extremely important part of the standard library.  
[format](https://www.amxmodx.org/api/string/format), [formatex](https://www.amxmodx.org/api/string/formatex) and [\[MAX_FMT_LENGTH\]fmt](https://www.amxmodx.org/api/string/%5BMAX_FMT_LENGTH%5Dfmt) tell the reader to go find actual information by going to the documentation - in the documentation.  
Similarly, [console_print](https://www.amxmodx.org/api/amxmodx/console_print) and [console_cmd](https://www.amxmodx.org/api/amxmodx/console_cmd) do not have the due diligence to offer any information about what "formatting rules" are, or where information can be found about this special text format.
	- The [SourceMod formatting rules](https://wiki.alliedmods.net/Format_Class_Functions_(SourceMod_Scripting)) can be referenced, however it's for a different standard library so differences are to be expected.

- Documentation for [register_clcmd](https://www.amxmodx.org/api/amxmodx/register_clcmd) and [register_concmd](https://www.amxmodx.org/api/amxmodx/register_clcmd) completely lacks a description of the callback function it should receive. For an example of good documentation that does not have this problem, see [menu_create](https://www.amxmodx.org/api/newmenus/menu_create).
	- The callback function for [register_clcmd](https://www.amxmodx.org/api/amxmodx/register_clcmd) should take a single parameter holding the calling player id: `public <name>(id)`
	- The callback function for [register_concmd](https://www.amxmodx.org/api/amxmodx/register_concmd) should take a calling player id, an admin access flag field, and command id: `public <name>(id, level, cid)`

- The documentation for [get_user_msgid](https://www.amxmodx.org/api/amxmodx/get_user_msgid) neglects to mention where message names can be found.

- [fopen](https://www.amxmodx.org/api/file/fopen) has a wrong example: "Example: "rb" opens a binary file for writing"

- [TE_FIREFIELD](https://www.amxmodx.org/api/message_const#makes-a-field-of-fire) and [TE_PLAYERATTACHMENT](https://www.amxmodx.org/api/message_const#attaches-a-tent-to-a-player-this-is-a-high-priority-tent) have wrong documentation, they mention only one coordinate but there should be three.  
Confused user: https://forums.alliedmods.net/showthread.php?t=14870

- [TE_EXPLODEMODEL](https://www.amxmodx.org/api/message_const#spherical-shower-of-models-picks-from-set) has wrong documentation, it shows 3 velocity coordinates but there should only be one, because the direction is random.  
Complaint: https://forums.alliedmods.net/showthread.php?t=138244
	
- Documentation for [read_argv](https://www.amxmodx.org/api/amxmodx/read_argv), [\*_float](https://www.amxmodx.org/api/amxmodx/read_argv_float) and [\*_int](https://www.amxmodx.org/api/amxmodx/read_argv_int) neglects mentioning what happens when the index is out of bounds.
	- The function [read_argv](https://www.amxmodx.org/api/amxmodx/read_argv) writes an empty string if the argument is out of bounds.
	- The functions [read_argv_int](https://www.amxmodx.org/api/amxmodx/read_argv_int) and [read_argv_float](https://www.amxmodx.org/api/amxmodx/read_argv_float) try to read a number, both returning 0 if that fails.
		- Arguments <= 0 are set to return 0, even if argument 0 would've parsed fine as a number.  
		The number is parsed from the start of the argument, returning fine even if the latter part of the argument is an invalid number, like "`1.0asdf`".  
		Floats can also be parsed from hexadecimal with the 0x prefix and an optional fractional part, or scientific notation.
	
- The documentation for [fwrite](https://www.amxmodx.org/api/file/fwrite) is wrong. The data parameter claims to hold an item (a simple cell) while the mode parameter refers to an array. This is contradictory information.
	- The function actually writes a single cell to a file using mode as the byte width that the cell will occupy in the file, it has nothing to do with arrays. This error probably came from lazy copy pasting of the [fwrite_blocks](https://www.amxmodx.org/api/file/fwrite_blocks) documentation.

- The documentation for [get_user_aiming](https://www.amxmodx.org/api/amxmodx/get_user_aiming) uses the wrong terminology, or centers the description around aiming at clients, making it sound like it can't be used for anything else.
	- This function is in fact used to aim at any entity at all, not just clients.

- The precache_\* family of functions fails to state the reason for there being multiple functions. The function [precache_generic](https://www.amxmodx.org/api/amxmodx/precache_generic) does not work with precaching sprites, and it doesn't clearly state what it's *for* -- what is a generic file, if not also a sprite?
	- Use [precache_model](https://www.amxmodx.org/api/amxmodx/precache_model) to precache sprites. This is also not documented behaviour, unless you're supposed to already know that .spr sprites and .mdl models are considered the one and same type of resource.

- [nvault_get](https://www.amxmodx.org/api/nvault/nvault_get) does not mention what happens when the key does not exist.
	- It returns 0, and it writes 0.0 to a given float reference, and "" to a given string reference.
	
- [fread](https://www.amxmodx.org/api/file/fread) and [fread_raw](https://www.amxmodx.org/api/file/fread_raw) have wrong documentation; it says they returns the number of elements read, but they actually returns the number of bytes read.
	- This error probably came from lazy copy pasting of the documentation from [fread_blocks](https://www.amxmodx.org/api/file/fread_blocks), which correctly returns the number of elements read.
	- The inconsistency in behaviour implies a bug in the library rather than the documentation.
	
- [fread](https://www.amxmodx.org/api/file/fread), [fread_blocks](https://www.amxmodx.org/api/file/fread_blocks), and [fread_raw](https://www.amxmodx.org/api/file/fread_raw) neglect to mention what happens when reading out of bounds.
	- The result is garbage memory, sometimes null but effectively random. The garbage memory elements read do not count in the return value. For example, `fread(empty_file, var_gets_garbage_memory, BLOCK_INT)` returns 0 rather than 4.
	- They also don't mention what they return when the element read is partially out of bounds, like reading a 4 byte int from a 2 byte file. The result for [fread](https://www.amxmodx.org/api/file/fread) and [fread_raw](https://www.amxmodx.org/api/file/fread_raw) is that they return 2, the amount of bytes that were available to read, and [fread_blocks](https://www.amxmodx.org/api/file/fread_blocks) returns 0, it does not count elements that were only partially read.

- [contain](https://www.amxmodx.org/api/string/contain) and [containi](https://www.amxmodx.org/api/string/containi) do not state what happens when an empty substring `""` is checked.
	- The result is no match, even if the source string is also `""`. This is contrary behaviour to some other languages, like Python.

- [TrieIterGetKey](https://www.amxmodx.org/api/celltrie/TrieIterGetKey) has doubly wrong documentation: "Nnumber [sic] of bytes written to the buffer" says A: that it counts the amount of bytes written instead of cells, and implies B: that it includes the zero terminator.
	- The function actually returns the amount of characters inside the string, which is 5 if it wrote the key "model".
	
- [TrieIterGetString](https://www.amxmodx.org/api/celltrie/TrieIterGetString) likewise has wrong documentation: it says the size parameter receives the amount of bytes written.
	- In reality it receives the length of the string written, which is the amount of cells written minus one.

- [get_keyvalue](https://www.amxmodx.org/api/engine/get_keyvalue) has wrong documentation: "Retrieves a value from an entities [sic] keyvalues." - it has nothing to do with entities. It actually gets client/server values.  
[Issue that has been open since 2019](https://github.com/alliedmodders/amxmodx/issues/745)
	- The engine (presumably) does not facilitate reading arbitrary keyvalues back via strings, it only allows you to set them.

- [write_coord](https://www.amxmodx.org/api/messages/write_coord) and [write_coord_f](https://www.amxmodx.org/api/messages/write_coord_f) do not state that [they both write a float](https://github.com/alliedmodders/amxmodx/blob/master/amxmodx/messages.cpp#L491) to the message, and the former converts an integer to float before doing so.
	- This is because message coordinates are always float, and it means that [write_coord_f](https://www.amxmodx.org/api/messages/write_coord_f) is the best and most accurate function to use, while the other is a convenience function for when you already have bad precision.

### Broken standard library
Several AMX Mod X features are broken and provided with no disclaimers due to lack of testing and general carelessness.  

- Not only is the documentation for [fwrite_raw](https://www.amxmodx.org/api/file/fwrite_raw) wrong, the function just doesn't work. The descriptions for the `block` and `mode` parameters are swapped, and the function's code has a wrong pointer that causes it to write garbage data from the stack instead of the cell array to the file.  
This bugged code is in [amxmodx/file.cpp, amx_fwrite_raw](https://github.com/alliedmodders/amxmodx/blob/master/amxmodx/file.cpp#L454), where  
`fp->Write(&data, ...)`  
should have been  
`fp->Write(data, ...)`  
Use [fwrite_blocks](https://www.amxmodx.org/api/file/fwrite_blocks) instead.

- [equal](https://www.amxmodx.org/api/string/equal) and [equali](https://www.amxmodx.org/api/string/equali) return true or false, but are tagged to return integers, not booleans.

## The language
The Small language is not a particularly bad one, but it has some questionable design decisions and strange syntax rules that are always waiting to trip the user.

### Rules
Small has plenty of peculiar features, some inconvenient because they have limitations that appear to stem from being incomplete. The documentation glosses over or does not state why certain limitations are in place.

- You can't create constant arrays.  
This is valid (and is much like a `#define`):  
`const A = 123`  
But this is an error:  
`const A[] = {0, 1, 2}`  
This means that it's impossible to create constant arrays that can be indexed at compile time. You have to create constant variable arrays that will generate unnecessary lookup code when indexed:  
`new const A[] = {0, 1, 2}`  
You can create a `#define` for an array, but this comes at the cost of having space allocated for an entirely separate array each time it's used:  
`#define A "Constant string"`

- Packed strings are considered constant, but packed arrays are not. This means this is valid:  
`new A[3 char] = !"Hi"`, and this is not:  
`new A[3 char] = !{255, 127, 0}`, this forces the programmer to use string escape sequences to write numbers while being careful around the zero terminator:  
`new A[3 char] = !"\255\127" // !"\255\127\0" works too, because the 3 char size is really 4 char, so as to occupy 1 cell.`  
Packed non-string arrays in general are broken. Assigning an already-declared variable to a packed string is valid:  
`A = !"Hi"`, but invalid for packed arrays, as this raises a size mismatch error, despite the array sizes being compatible:  
`A = !{255, 0, 0}`  
Packed string parameters work without a hitch, while packed array parameters result in corrupted memory, with the compiler not even issuing a warning:
```
test_packed() takes_packed !"Ya", !{255, 127, 0}
takes_packed(A[3 char], B[3 char]) console_print 0, "%d %d %d, %d %d %d %d %d", A{0},A{1},A{2}, B{0},B{1},B{2},B{3},B[0]
// Output: 89 97 0, 0 0 0 24 24
```

- Typical programmer errors like interpreting integers as floats are silent when these values are included in variable arguments, because the Small language does not permit type information in this case.  
Variable arguments use the any tag, so all arguments have their types overridden to any, like in this example:  
`function(format_string[], any: ...) {}`
This makes variable argument functions like engfunc and string formatting functions like formatex prone to errors.  
The lack of this feature is surprising considering the effort put into type checking syntax in Small. Take this AMX Mod X code snippet as an example:  
```
TagCheck({_, Float}: x, x_tag = tagof x)
	console_print 0, "x=%d, unused x tag=%d, real x tag=%d, _:=%d, Float:=%d", x, tagof x, x_tag, tagof _:, tagof Float:
RunTagCheck() {
	TagCheck 123
	TagCheck 123.0
}
```

- The compiler rejects array initialisation with variables. This code is invalid:  
`new i = 1`  
`new A[3] = {i, i, i}`  
This forces the programmer to break the initialisation into a loop, or many assignments:  
`new A[3]; A[0] = A[1] = A[2] = i`

### Semicolons - optional until they aren't
The language has lax syntax with optional semicolons. This appears to be a half-baked feature of the language, as this causes strange pitfalls where compiler errors give little to no useful information aside from a line number.

- The compiler jumps the gun on (presumably) vector literal detection and fails to understand one-lined multi-statements with any amount of statements other than zero. This code fails:  
`new V[5]`  
`for (new i; i < sizeof V; i++) {console_print(0, "%d\n", i); V[i] = i}`   
Fixing it requires placing a semicolon after the last statement in the multi-statement, placing a line break so the end brace "`}`" gets separated away, or if there's only one statement, removing the curly braces.  
This problem is generalised to any inner scope.

- Semicolons or parentheses become mandatory when using procedure call syntax followed by an inner scope, as this clashes with packed array indexing syntax. This will fail to compile:
```
message_begin MSG_BROADCAST, SVC_TEMPENTITY
{
	write_byte TE_BEAMENTPOINT
}
```

- Forward declarations have mandatory semicolons:
`public func();`

- Double standard: Null statements are allowed, but not with `;`, only with `{}`.  
This means that a preprocessor macro to, for example, convert an integer vector to a float vector has three possible styles, each with their own downside:  
	1. `#define VEC_TO_FVEC(%1,%2) %2[0] = float(%1[0]); %2[1] = float(%1[1]); %2[2] = float(%1[2])`  
	2. `#define VEC_TO_FVEC(%1,%2) %2[0] = float(%1[0]); %2[1] = float(%1[1]); %2[2] = float(%1[2]);`  
	3. `#define VEC_TO_FVEC(%1,%2) {%2[0] = float(%1[0]); %2[1] = float(%1[1]); %2[2] = float(%1[2]);}`  
These examples show that here is no catch-all solution, aside from redefining the macro as a function ([which fortunately exists already](https://www.amxmodx.org/api/vector/IVecFVec)):
	* `VEC_TO_FVEC(vec_i, vec_f);`
	* `if (id == target) VEC_TO_FVEC(vec_i, vec_f)`
	* `if (id == target) {found = true; VEC_TO_FVEC(vec_i, vec_f);}`

### Compiling
The compiler is just as weird as the language. Some of its problems may have been introduced by the AMX Mod X team.

- The compiler wrongly issues an unreachable code warning because it's blind to labels:
```
goto label
return
label:
```

- The compiler provides a truncated listing of 16 options when requesting help the intended way:  
`amxxpc --help`  
You have to trigger a file lookup failure to get the proper help listing of 29 options:  
`amxxpc --asdf`  

- The compiler's option arguments follow a strange convention that require additional information to be appended onto the same argument. If the user slips up, easy to do if coming from other compilers or if there's a space in the path, the compiler will expose garbage memory and output an unhelpful and corrupted error:
```
amxxpc.exe PLUGIN.sma -o "Output Folder/PLUGIN.amxx"
AMX Mod X Compiler 1.9.0.5294
Copyright (c) 1997-2006 ITB CompuPhase
Copyright (c) 2004-2013 AMX Mod X Team
═^☺└╩^☺`¬ ... ^☺`¬^☺0"^☺(0) : fatal error 100: cannot read from file: "PLUGIN.sma"
Compilation aborted.
1 Error.
Could not locate output file tput Folder/PLUGIN.amx (compile failed).
```
The correct command in this case would be:  
`amxxpc.exe PLUGIN.sma "-oOutput Folder/PLUGIN.amxx"`

- The compiler is generally good at labeling when errors and warnings come from includes, but it reports them as coming from the main source code file if it's an unused symbol warning.