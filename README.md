![BLogo](https://user-images.githubusercontent.com/90519370/172873820-f01d13f3-6bd1-4d24-b79b-1c548f024ae9.png)

# This is the repository for the Blue programming language for Mac, The Blue compiler for Mac, and the Blue standard library, all of which are licensed under GNU GPL v3

# For windows and linux versions with scripting capabilities, click [Here](https://github.com/BlueTechnologies/Blue)

# Setting up the Windows Binary

## Installing a target compiler
To use Blue, you need a compiler for the language you are targetting, these are almost always found on the language vendors website.

## Testing it out
Go into the parent directory of the directory containing your .BL source files, open a command line terminal IN THAT FOLDER, and type "blue 'source-code-folder' 'target'", and execute the command. Depending on whether your code has errors, your program should be compiled into an executable file (or simply transpiled, for the javascript target)

# Building from source

## Installing Dependencies
1. Install the latest version of [Haxe](https://haxe.org/)

2. Install [MSVC](https://visualstudio.microsoft.com/downloads/)

3. Open up a terminal and execute the commands below

```
haxelib install hxcpp
haxelib install Console.hx
```

## Compiling the source code
Compiling the blue compiler is pretty simple; Read "Installing dependencies", and then, open a command line terminal inside the source code's folder, then, type 
``` haxe build.hxml ```,
and execute the command. This should build the blue compiler if all the required dependencies are installed.
