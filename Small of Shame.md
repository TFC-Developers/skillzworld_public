# Small of Shame
This document records our disdain for AMX Mod X and its chosen scripting language.

## Nearly two decades out of date
AMX Mod X uses an old version of the Small language, a version from around 2005, from before it was renamed to Pawn. This is made clear by the .sma source code extension. People call it Pawn, which is misleading.  
[Repository with "Pawn_Language_Guide.pdf"](https://github.com/compuphase/pawn/tree/master/doc)  
The "Pawn Language Guide", updated in 2016 at the time of writing, is of limited use and is often misleading as it pertains to the language as it has evolved after 2005.  
[(Download) The Small Booklet - The Language (2005)](https://www.doomworld.com/eternity/engine/smalldoc.pdf)  
[(Download) The Small Booklet - Implementor's Guide (2005)](https://www.doomworld.com/eternity/engine/smallguide.pdf)  
The outdated documentation is more representative (The Small Booklet - The Language), however it's unclear precisely what Small version AMX Mod X is derived from, and which changes were made to the syntax by the AMX Mod X team, if any.  

## AMX Mod X
https://www.amxmodx.org/about.php  
AMX Mod X is a plugin for [Metamod](http://metamod.org/) that makes it possible to write other plugins in Small, which run through the AMX Mod X environment. It includes a programming environment (AMXX-Studio), [API](https://www.amxmodx.org/api/), and compiler.  
It's not very good.  
  
The Sven Co-op team made a wise decision when integrating the more sensible AngelScript language into their mod with their own API, eliminating any possible use case for AMX Mod X.

- AMX Mod X only allows the precache to be interacted with in the plugin_precache forward using the precache_\* natives, offering no means to just check if a model is already precached. This could easily have been made available by exposing a native function that reads from the server_t struct.
	- The engine function accessible with `id = engfunc(EngFunc_ModelIndex, modelpath)` comes close to this functionality, but it's set to raise a system error if the model isn't precached instead of returning a value representing this.

- The natives [get_user_origin](https://www.amxmodx.org/api/amxmodx/get_user_origin) and [set_user_origin](https://www.amxmodx.org/api/amxmodx/set_user_origin) operate on ints, not floats, for reasons unknown. The programmer should always keep this in mind and usually avoid them.  
Getting an int vector is however handy for sending [messages](https://www.amxmodx.org/api/message_const).  
Use [entity_set_origin](https://www.amxmodx.org/api/engine/entity_set_origin) / [entity_set_vector](https://www.amxmodx.org/api/engine/entity_set_vector) and [entity_get_vector](https://www.amxmodx.org/api/engine/entity_set_vector) instead to get the player's origin as a float vector.  

- AMXX-Studio does not recognise and syntax highlight public functions if they're declared with the @ prefix.

### Anything for backwards compatibility
The AMX Mod X library has accumulated many mistakes over the years that have not been corrected for the sake of backwards compatibility. They either get left in or an alternative is provided.

- https://www.amxmodx.org/api/float/floatadd  
The parameters have the wrong names, which belong to floatdiv.

- [include/tfcconst.inc](https://github.com/alliedmodders/amxmodx/blob/master/plugins/include/tfcconst.inc#L75) provides both the constants TFC_PC_ENGENEER and TFC_PC_ENGINEER.

- [register_event](https://www.amxmodx.org/api/amxmodx/register_event) provides a workaround for a bug, leaving it unfixed.

- [client_disconnect](https://www.amxmodx.org/api/amxmodx/client_disconnect) has been deprecated [since 2015](https://github.com/alliedmodders/amxmodx/commit/ed4faf7c114495db7426023c2b47914523fcdfd1) and will never be removed.

### Bad documentation
The AMX Mod X documentation is very sloppy and is full of grammar and spelling errors and wrong information. Many pages are missing or aren't complete.

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

### Broken standard library
Several AMX Mod X features are broken and provided with no disclaimers due to lack of testing and general carelessness.

- Not only is the documentation for [fwrite_raw](https://www.amxmodx.org/api/file/fwrite_raw) wrong, the function just doesn't work. The descriptions for the `block` and `mode` parameters are swapped, and the function's code has a wrong pointer that causes it to write garbage data from the stack instead of the cell array to the file.  
This bugged code is in [amxmodx/file.cpp, amx_fwrite_raw](https://github.com/alliedmodders/amxmodx/blob/master/amxmodx/file.cpp#L454), where  
`fp->Write(&data, ...)`  
should have been  
`fp->Write(data, ...)`  
Use [fwrite_blocks](https://www.amxmodx.org/api/file/fwrite_blocks) instead.

- The functions [contain](https://www.amxmodx.org/api/string/contain) and [containi](https://www.amxmodx.org/api/string/containi) use the wrong parameters. The documentation states that the first parameter is the source string to search in, and the latter string is the substring to find, but in reality it's reversed.  
The documentation says to use:  
`contain(original, substring)`  
But you should use:  
`contain(substring, original)`

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

- Semicolons or parentheses become mandatory when using procedure call syntax followed by an inner scope, as this clashes with vector syntax. This will fail to compile:
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
These examples show that here is no catch-all solution, aside from redefining the macro as a function:
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