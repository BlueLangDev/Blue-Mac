package lexing;

import blue.Blue;
#if sys
import sys.FileSystem;
import sys.io.File;
#end
import languageutils.js.BJSUtil;
import languageutils.go.BGoUtil;
import languageutils.cpp.BCPPUtil;
import languageutils.coffeescript.BCoffeeScriptUtil;
import languageutils.haxe.BHaxeUtil;
import languageutils.groovy.BGroovyUtil;
import cpp.Pointer;

using StringTools;

enum BToken {
	Method(name:String, args:Array<Dynamic>);
	MainMethod(args:Array<Dynamic>);
	Array(entries:Array<Dynamic>);
	Variable(name:String, value:Dynamic, type:String);
	MethodVariable(name:String, value:Dynamic, type:String);
	ForStatement(iterator:Dynamic, numberOne:String, numberTwo:String);
	IfStatement(condition:Dynamic);
	Use(value:Dynamic);
	Add(a:Dynamic, b:Dynamic);
	Subtract(a:Dynamic, b:Dynamic);
	Multiply(a:Dynamic, b:Dynamic);
	Divide(a:Dynamic, b:Dynamic);
	End;
	Try;
	Catch(value:Dynamic);
	CodeInjection(value:Dynamic);
	Continue;
	Stop;
	Property(a:Dynamic, b:Dynamic);
	Print(stringToPrint:Dynamic);
	Return(value:Dynamic);
	Comment(value:Dynamic);
	Throw(value:Dynamic);
	New(value:Dynamic, args:Array<Dynamic>);
	Else;
	FunctionC(value:Dynamic);
	Super(args:Dynamic);
	OtherwiseIf(condition:Dynamic);
}

class BLexer {
	private static var current:String = null;

	private var end:String = null;

	private static var privateVars:Array<Dynamic> = [];
	private static var publicVars:Array<Dynamic> = [];

	private static var localVars:Array<Dynamic> = ["return", "null"];

	private static var paramVars:Array<Dynamic> = [];
	private static var paramTypes:Map<String, String> = [];

	private static var localMethods:Array<Dynamic> = [];

	private static var iterators:Array<Dynamic> = [];

	private static var privateMethods:Array<Dynamic> = [];
	private static var publicMethods:Array<Dynamic> = [];
	private static var staticMethods:Array<Dynamic> = [];

	private static var gotErrors:Bool = false;

	public static var content:String;
	static var last:Bool = false;

	private var number:Float = 0;

	private static var regular = ~/\b(_*[A-Z]\w*)\b/;

	private static var reg = ~/"([^"]*?)"/g;

	private static var voidMethods:Array<String> = [];

	private static var variableTypes:Map<String, String> = [];
	private static var variableValues:Map<String, String> = [];

	private static var methodParams:Map<String, Array<String>> = [];
	private static var methodTypes:Map<String, String> = [];

	private static var stdNames:Map<String, Array<String>> = [
		"MathTools" => ["arccos", "cosine", "sine", "floorValue"],
		"System" => ["runcmd", "shutdown", "varTrace"],
		"File" => ["read", "write"],
		"ArrayTools" => ["pop", "shift", "arraySize", "addElement"]
	];

	private static var completeStd:Map<String, Array<Int>> = [
		"arccos" => [1], "cosine" => [1], "power" => [1, 1], "sine" => [1], "floorValue" => [1], "runcmd" => [1], "read" => [1], "write" => [1, 1],
		"pop" => [1], "shift" => [1], "varTrace" => [1], "arraySize" => [1], 'addElement' => [1, 1], 'shutdown' => [1]];

	private static var isInMethod:Bool = false;
	private static var isInMain:Bool = false;
	private static var isInLoop:Bool = false;
	private static var isInLibrary:Bool = false;

	private static var isPrivate:Bool = false;
	private static var isPublic:Bool = false;

	private static var closedLibs:Array<String> = ['ArrayTools', "MathTools", "System", "File"];

	private static var needsReturn:Bool = false;

	private static var currentLibrary:String = "";

	private static var endsNeededToEndMethod:Int = 0;

	private static var endsNeededToEndModifier:Int = 0;
	private static var endsNeededToEndLibrary:Int = 0;

	static var tokensToParse:Array<Dynamic> = [];
	static var completeSyntax:Array<String> = [
		"method ", "loop ", "if ", "+", "-", "mult", "div", "end", "else", "stop", "continue", "then", "not", "=", "use", "try", "catch", "print!", "return",
		"***", "main(", "throw", "or", "[", "/", "(", "else if ", "<<", ">>", "null", "break", "continue", "open ", "close ", "targetInject!"
	];

	public static function enumContent(contentToEnum:String, testLex:Bool = false):Bool {
		localVars = ["return", "null"];
		paramVars = [];
		localMethods = [];

		variableTypes = [];
		variableValues = [];
		methodParams = [];

		currentLibrary = "";

		closedLibs = ['ArrayTools', "MathTools", "System", "File"];

		for (file in FileSystem.readDirectory(Blue.directory)) {
			closedLibs.push(file.replace(".bl", ""));
		}

		isInMethod = false;
		isInMain = false;
		isInLoop = false;
		isInLibrary = false;

		needsReturn = false;

		endsNeededToEndMethod = 0;
		endsNeededToEndModifier = 0;
		endsNeededToEndLibrary = 0;

		var currentToken:BToken = null;
		for (j in 0...contentToEnum.split("\n").length) {
			var linenum = j + 1;
			current = contentToEnum.split("\n")[j];
			contentToEnum = contentToEnum + "\n";
			if (current.ltrim().startsWith("<<end>>"))
				current = current.ltrim().replace("<<end>>", "\n\n\n");
			if (reg.replace(current, '""').ltrim().startsWith("<<haxe>>") && Blue.target != "haxe") {
				contentToEnum = contentToEnum.replace(contentToEnum.split('<<haxe>>')[1].split('<<end>>')[0], "");
			} else if (reg.replace(current, '""').ltrim().startsWith("<<c>>") && Blue.target != "c") {
				contentToEnum = contentToEnum.replace(contentToEnum.split('<<c>>')[1].split('<<end>>')[0], "");
			} else if (reg.replace(current, '""').ltrim().startsWith("<<coffeescript>>") && Blue.target != "coffeescript") {
				contentToEnum = contentToEnum.replace(contentToEnum.split('<<coffeescript>>')[1].split('<<end>>')[0], "");
			} else if (reg.replace(current, '""').ltrim().startsWith("<<cpp>>") && Blue.target != "cpp") {
				contentToEnum = contentToEnum.replace(contentToEnum.split('<<cpp>>')[1].split('<<end>>')[0], "");
			} else if (reg.replace(current, '""').ltrim().startsWith("<<cs>>") && Blue.target != "cs") {
				contentToEnum = contentToEnum.replace(contentToEnum.split('<<cs>>')[1].split('<<end>>')[0], "");
			} else if (reg.replace(current, '""').ltrim().startsWith("<<go>>") && Blue.target != "go") {
				contentToEnum = contentToEnum.replace(contentToEnum.split('<<go>>')[1].split('<<end>>')[0], "");
			} else if (reg.replace(current, '""').ltrim().startsWith("<<groovy>>") && Blue.target != "groovy") {
				contentToEnum = contentToEnum.replace(contentToEnum.split('<<groovy>>')[1].split('<<end>>')[0], "");
			} else if (reg.replace(current, '""').ltrim().startsWith("<<java>>") && Blue.target != "java") {
				contentToEnum = contentToEnum.replace(contentToEnum.split('<<java>>')[1].split('<<end>>')[0], "");
			} else if (reg.replace(current, '""').ltrim().startsWith("<<js>>") && Blue.target != "js") {
				contentToEnum = contentToEnum.replace(contentToEnum.split('<<js>>')[1].split('<<end>>')[0], "");
			} else if (reg.replace(current, '""').ltrim().startsWith("<<julia>>") && Blue.target != "julia") {
				contentToEnum = contentToEnum.replace(contentToEnum.split('<<julia>>')[1].split('<<end>>')[0], "");
			} else if (reg.replace(current, '""').ltrim().startsWith("<<lua>>") && Blue.target != "lua") {
				contentToEnum = contentToEnum.replace(contentToEnum.split('<<lua>>')[1].split('<<end>>')[0], "");
			} else if (reg.replace(current, '""').ltrim().startsWith("<<!haxe>>") && Blue.target == "haxe") {
				contentToEnum = contentToEnum.replace(contentToEnum.split('<<!haxe>>')[1].split('<<end>>')[0], "");
			} else if (reg.replace(current, '""').ltrim().startsWith("<<!c>>") && Blue.target == "c") {
				contentToEnum = contentToEnum.replace(contentToEnum.split('<<!c>>')[1].split('<<end>>')[0], "");
			} else if (reg.replace(current, '""').ltrim().startsWith("<<!coffeescript>>") && Blue.target == "coffeescript") {
				contentToEnum = contentToEnum.replace(contentToEnum.split('<<!coffeescript>>')[1].split('<<end>>')[0], "");
			} else if (reg.replace(current, '""').ltrim().startsWith("<<!cpp>>") && Blue.target == "cpp") {
				contentToEnum = contentToEnum.replace(contentToEnum.split('<<!cpp>>')[1].split('<<end>>')[0], "");
			} else if (reg.replace(current, '""').ltrim().startsWith("<<!cs>>") && Blue.target == "cs") {
				contentToEnum = contentToEnum.replace(contentToEnum.split('<<!cs>>')[1].split('<<end>>')[0], "");
			} else if (reg.replace(current, '""').ltrim().startsWith("<<!go>>") && Blue.target == "go") {
				contentToEnum = contentToEnum.replace(contentToEnum.split('<<!go>>')[1].split('<<end>>')[0], "");
			} else if (reg.replace(current, '""').ltrim().startsWith("<<!groovy>>") && Blue.target == "groovy") {
				contentToEnum = contentToEnum.replace(contentToEnum.split('<<!groovy>>')[1].split('<<end>>')[0], "");
			} else if (reg.replace(current, '""').ltrim().startsWith("<<!java>>") && Blue.target == "java") {
				contentToEnum = contentToEnum.replace(contentToEnum.split('<<!java>>')[1].split('<<end>>')[0], "");
			} else if (reg.replace(current, '""').ltrim().startsWith("<<!js>>") && Blue.target == "js") {
				contentToEnum = contentToEnum.replace(contentToEnum.split('<<!js>>')[1].split('<<end>>')[0], "");
			} else if (reg.replace(current, '""').ltrim().startsWith("<<!julia>>") && Blue.target == "julia") {
				contentToEnum = contentToEnum.replace(contentToEnum.split('<<!julia>>')[1].split('<<end>>')[0], "");
			} else if (reg.replace(current, '""').ltrim().startsWith("<<!lua>>") && Blue.target == "lua") {
				contentToEnum = contentToEnum.replace(contentToEnum.split('<<!lua>>')[1].split('<<end>>')[0], "");
			} else if (reg.replace(current, '""').ltrim().startsWith("<<")
				&& reg.replace(current, '""').ltrim().contains(",")
				&& reg.replace(current, '""').ltrim().contains(">>")) {
				for (i in 0...reg.replace(current, '""').ltrim().split(",").length) {
					if (reg.replace(current, '""').ltrim().split(",")[i].split(",")[0].replace("<<", "").replace(">>", "").contains("!")) {
						if (Blue.target == reg.replace(current, '""')
							.ltrim()
							.split(",")[i].split(",")[0].split("!")[1].replace("<<", "").replace(">>", "").replace(" ", "").replace("\r", "")) {
							contentToEnum = contentToEnum.replace(contentToEnum.split(reg.replace(current, '""'))[1].split("<<end>>")[0], "");
							break;
						} else {
							continue;
						}
					} else if (reg.replace(current, '""').ltrim().split(",")[i].split(",")[0].replace("<<", "").replace(">>", "").contains("!")) {
						if (Blue.target != reg.replace(current, '""')
							.ltrim()
							.split(",")[i].split(",")[0].split("!")[1].replace("<<", "").replace(">>", "").replace(" ", "").replace("\r", "")) {
							contentToEnum = contentToEnum.replace(contentToEnum.split(reg.replace(current, '""'))[1].split("<<end>>")[0], "");
							break;
						} else {
							continue;
						}
					}
				}
			}
			for (i in 0...completeSyntax.length) {
				if (reg.replace(current.ltrim(), '""').contains(completeSyntax[i])) {
					switch (completeSyntax[i]) {
						case 'method ':
							var firstIndex = 0;
							var firstIndex2 = 0;
							var firstIndex3 = 0;
							var firstIndex4 = 0;
							var firstIndex5 = 0;
							var firstIndex6 = 0;
							var firstIndex7 = 0;
							var firstIndex8 = 0;
							var firstIndex9 = 0;
							var firstIndex10 = 0;
							if (!isInMethod) {
								if (reg.replace(current, '""').ltrim().replace(' ', "").startsWith('method')
									|| reg.replace(current, '""').ltrim().replace(' ', "").startsWith('static')) {
									isInMethod = true;
									endsNeededToEndMethod = 1;
									var args = [];
									if (reg.replace(current, '"').ltrim().contains(")\r")) {
										for (i in 0...current.ltrim().split('method ')[1].split('(')[1].split(')').length) {
											if (current.ltrim().split('method ')[1].split('(')[1].split(')')[i] != null
												&& current.ltrim().split('method ')[1].split('(')[1].split(')')[i].contains(',')) {
												args.push(current.ltrim().split('method ')[1].split('(')[1].split(')')[i].split(','));
											} else if (current.ltrim().split('method ')[1].split('(')[1].split(')')[i] != null
												&& !current.ltrim().split('method ')[1].split('(')[1].split(')')[i].contains(',')) {
												args.push([current.ltrim().split('method ')[1].split('(')[1].split(')\r')[0]]);
											}
										}
									} else {
										Console.log("<b><light_white>"
											+ Blue.currentFile
											+ " - "
											+ "</><b><red>Error [BLE0001]:</></><light_white> Methods must be ended with a ')' and a newline at line "
											+ (linenum)
											+ "</>");
										gotErrors = true;
										Console.log("");
										var arr = current.ltrim().trim().split("");
										arr.insert(reg.replace(current.ltrim().trim(), '""').indexOf("method", firstIndex), "<b><red>");
										arr.insert(reg.replace(current.ltrim().trim(), '""').indexOf("method", firstIndex) + 7, "</></>");
										Console.log(arr.join(""));
										var squigglyLines = "";
										for (j in 0...reg.replace(current.ltrim().trim(), '""').indexOf("method", firstIndex)) {
											squigglyLines += " ";
										}
										for (j in 0...6) {
											squigglyLines += "~";
										}
										firstIndex += 1;
										Console.log("<red>" + squigglyLines + "</>");
									}
									if (localVars.contains(current.ltrim().split('method ')[1].split('(')[0].replace(" ", ""))) {
										Console.log("<b><light_white>"
											+ Blue.currentFile
											+ " - "
											+ "</><b><red>Error [BLE0069]:</></><light_white> Method names cannot have the same name as a variable at line "
											+ (linenum)
											+ "</>");
										gotErrors = true;
										Console.log("");
										var arr = current.ltrim().trim().split("");
										arr.insert(reg.replace(current.ltrim().trim(), '""').indexOf("method", firstIndex10), "<b><red>");
										arr.insert(reg.replace(current.ltrim().trim(), '""').indexOf("method", firstIndex10) + 7, "</></>");
										Console.log(arr.join(""));
										var squigglyLines = "";
										for (j in 0...reg.replace(current.ltrim().trim(), '""').indexOf("method", firstIndex10)) {
											squigglyLines += " ";
										}
										for (j in 0...6) {
											squigglyLines += "~";
										}
										firstIndex10 += 1;
										Console.log("<red>" + squigglyLines + "</>");
									}
									if (args != null && args[0] != null) {
										for (i in 0...args[0].length) {
											if (args[0][i].replace(" ", "") != "") {
												if (!Math.isNaN(Std.parseFloat(args[0][i])) || completeSyntax.contains(args[0][i])) {
													Console.log("<b><light_white>"
														+ Blue.currentFile
														+ " - "
														+ "</><b><red>Error [BLE0002]:</></><light_white> Invalid parameter at line"
														+ (linenum)
														+ "</>");
													gotErrors = true;
													Console.log("");
													var arr = current.ltrim().trim().split("");
													arr.insert(reg.replace(current.ltrim().trim(), '""').indexOf(args[0][i]), "<b><red>");
													arr.insert(reg.replace(current.ltrim().trim(), '""').indexOf(args[0][i]) + args[0][i].length + 1,
														"</></>");
													Console.log(arr.join(""));
													var squigglyLines = "";
													for (j in 0...reg.replace(current.ltrim().trim(), '""').indexOf(args[0][i], firstIndex2)) {
														squigglyLines += " ";
													}
													for (j in 0...args[0][i].length) {
														squigglyLines += "~";
													}
													firstIndex2 += 1;
													Console.log("<red>" + squigglyLines + "</>");
												}
												paramVars.push(args[0][i]);
												if (localVars.contains(args[0][i])) {
													Console.log("<b><light_white>"
														+ Blue.currentFile
														+ " - "
														+
														"</><b><red>Error [BLE0070]:</></><light_white> Attempted to name a parameter an already existing variable's name at line "
														+ (linenum)
														+ "</>");
													gotErrors = true;
													Console.log("");
													var arr = current.ltrim().trim().split("");
													arr.insert(reg.replace(current.ltrim().trim(), '""').indexOf("method"), "<b><red>");
													arr.insert(reg.replace(current.ltrim().trim(), '""').indexOf("method") + 7, "</></>");
													Console.log(arr.join(""));
													var squigglyLines = "";
													for (j in 0...reg.replace(current.ltrim().trim(), '""').indexOf("method")) {
														squigglyLines += " ";
													}
													for (j in 0...6) {
														squigglyLines += "~";
													}
													firstIndex6 += 1;
													Console.log("<red>" + squigglyLines + "</>");
													break;
												}
											}
										}
										methodParams.set(current.ltrim().split('method ')[1].split('(')[0].replace(" ", ""), args[0]);
										if (!isInLibrary)
											currentToken = BToken.Method(current.ltrim().split('method ')[1].split('(')[0], args);
									} else {
										if (!isInLibrary)
											currentToken = BToken.Method(current.ltrim().split('method ')[1].split('(')[0], null);
									}
									if (contentToEnum.split(contentToEnum.split('\n')[j - 1])[0].contains("method "
										+ current.ltrim().split('method ')[1].split('(')[0])
										|| contentToEnum.split(current)[1].contains("method " + current.ltrim().split('method ')[1].split('(')[0])) {
										Console.log("<b><light_white>"
											+ Blue.currentFile
											+ " - "
											+ "</><b><red>Error [BLE0003]:</></><light_white> Method: "
											+ current.ltrim().split('method ')[1].split('(')[0] + " was defined twice at line " + (j + 1));
										gotErrors = true;
										gotErrors = true;
										Console.log("");
										var arr = current.ltrim().trim().split("");
										arr.insert(reg.replace(current.ltrim().trim(), '""').indexOf(("method"), firstIndex4), "<b><red>");
										arr.insert(reg.replace(current.ltrim().trim(), '""').indexOf(("method"), firstIndex4) + 7, "</></>");
										Console.log(arr.join(""));
										var squigglyLines = "";
										for (j in 0...reg.replace(current.ltrim().trim(), '""').indexOf("method", firstIndex4)) {
											squigglyLines += " ";
										}
										for (j in 0...6) {
											squigglyLines += "~";
										}
										firstIndex4 += 1;
										Console.log("<red>" + squigglyLines + "</>");
									}
									localMethods.push(current.ltrim().split('method ')[1].split('(')[0].replace(' ', ''));
									if (isPublic) {
										publicMethods.push(current.ltrim().split('method ')[1].split('(')[0].replace(' ', ''));
									}
									if (isPrivate) {
										privateMethods.push(current.ltrim().split('method ')[1].split('(')[0].replace(' ', ''));
									}
									if (reg.replace(current, '""').ltrim().replace(' ', "").startsWith('static')) {
										staticMethods.push(current.ltrim().split('method ')[1].split('(')[0].replace(' ', ''));
									}
								} else if (!reg.replace(current, '""').ltrim().replace(' ', "").startsWith('method')
									&& reg.replace(current, '""').ltrim().replace(' ', "").contains('method')) {
									Console.log("<b><light_white>"
										+ Blue.currentFile
										+ " - "
										+ "</><b><red>Error [BLE0004]:</></><light_white> Expected 'end' block at line "
										+ (linenum)
										+ "</>");
									gotErrors = true;
									Console.log("");
									var arr = current.ltrim().trim().split("");
									arr.insert(reg.replace(current.ltrim().trim(), '""').indexOf("method", firstIndex3), "<b><red>");
									arr.insert(reg.replace(current.ltrim().trim(), '""').indexOf("method", firstIndex3) + 4, "</></>");
									Console.log(arr.join(""));
									var squigglyLines = "";
									for (j in 0...reg.replace(current.ltrim().trim(), '""').indexOf("method", firstIndex3)) {
										squigglyLines += " ";
									}
									for (j in 0...6) {
										squigglyLines += "~";
									}
									firstIndex3 += 1;
									Console.log("<red>" + squigglyLines + "</>");
								} else if (reg.replace(current, '""').ltrim().replace(' ', "").startsWith('method')
									&& reg.replace(current, '""')
										.ltrim()
										.replace(' ', "")
										.split('method')[1].contains("method")) {
									Console.log("<b><light_white>"
										+ Blue.currentFile
										+ " - "
										+ "</><b><red>Error [BLE0011]:</></><light_white> Expected expression at line "
										+ (linenum)
										+ "</>");
									gotErrors = true;
									Console.log("");
									var arr = current.ltrim().trim().split("");
									arr.insert(reg.replace(current.ltrim().trim(), '""').indexOf("method", firstIndex5 + 1), "<b><red>");
									arr.insert(reg.replace(current.ltrim().trim(), '""').indexOf("method", firstIndex5 + 1) + 7, "</></>");
									Console.log(arr.join(""));
									var squigglyLines = "";
									for (j in 0...reg.replace(current.ltrim().trim(), '""').indexOf("method", firstIndex5 + 1)) {
										squigglyLines += " ";
									}
									for (j in 0...6) {
										squigglyLines += "~";
									}
									Console.log("<red>" + squigglyLines + "</>");
									firstIndex5 += 1;
								} else if (reg.replace(current, '""').ltrim().replace(' ', "").startsWith('method')
									&& reg.replace(current, '""')
										.ltrim()
										.replace(' ', "")
										.split('method')[1].contains("method")) {
									Console.log("<b><light_white>"
										+ Blue.currentFile
										+ " - "
										+ "</><b><red>Error [BLE0011]:</></><light_white> Expected expression at line "
										+ (linenum)
										+ "</>");
									gotErrors = true;
									Console.log("");
									var arr = current.ltrim().trim().split("");
									arr.insert(reg.replace(current.ltrim().trim(), '""').indexOf("method", firstIndex6 + 1), "<b><red>");
									arr.insert(reg.replace(current.ltrim().trim(), '""').indexOf("method", firstIndex6 + 1) + 7, "</></>");
									Console.log(arr.join(""));
									var squigglyLines = "";
									for (j in 0...reg.replace(current.ltrim().trim(), '""').indexOf("method", firstIndex6 + 1)) {
										squigglyLines += " ";
									}
									for (j in 0...6) {
										squigglyLines += "~";
									}
									firstIndex6 += 1;
									Console.log("<red>" + squigglyLines + "</>");
								}
							} else {
								Console.log("<b><light_white>"
									+ Blue.currentFile
									+ " - "
									+ "</><b><red>Error [BLE0004]:</></><light_white> Expected 'end' block at line "
									+ (linenum)
									+ "</>");
								gotErrors = true;
								Console.log("");
								var arr = current.ltrim().trim().split("");
								arr.insert(reg.replace(current.ltrim().trim(), '""').indexOf("method", firstIndex7), "<b><red>");
								arr.insert(reg.replace(current.ltrim().trim(), '""').indexOf("method", firstIndex7) + 4, "</></>");
								Console.log(arr.join(""));
								var squigglyLines = "";
								for (j in 0...reg.replace(current.ltrim().trim(), '""').indexOf("method", firstIndex7)) {
									squigglyLines += " ";
								}
								for (j in 0...6) {
									squigglyLines += "~";
								}
								firstIndex7 += 1;
								Console.log("<red>" + squigglyLines + "</>");
							}

							if (!testLex) {
								tokensToParse.push(currentToken);
							}

						case 'main(':
							var firstIndex = 0;
							var firstIndex2 = 0;
							var firstIndex3 = 0;
							if (!isInMethod) {
								if (reg.replace(current, '""').ltrim().replace(" ", "").startsWith('main(')) {
									var args = [];
									isInMethod = true;
									isInMain = true;
									endsNeededToEndMethod = 1;
									if (reg.replace(current, '"').ltrim().contains(")\r")) {
										for (i in 0...current.ltrim().split('main')[1].split('(')[1].split(')').length) {
											if (current.ltrim().split('main')[1].split('(')[1].split(')')[i] != null
												&& current.ltrim().split('main')[1].split('(')[1].split(')')[i].contains(',')) {
												args.push(current.ltrim().split('main')[1].split('(')[1].split(')')[i].split(','));
											} else if (current.ltrim().split('main')[1].split('(')[1].split(')')[i] != null
												&& !current.ltrim().split('main')[1].split('(')[1].split(')')[i].contains(',')) {
												args.push([current.ltrim().split('main')[1].split('(')[1].split(')\r')[0]]);
											}
										}
									} else {
										Console.log("<b><light_white>"
											+ Blue.currentFile
											+ " - "
											+ "</><b><red>Error [BLE0005]:</></><light_white> Main methods must be ended with a ')' and a newline at line "
											+ (linenum)
											+ "</>");
										gotErrors = true;
										Console.log("");
										var arr = current.ltrim().trim().split("");
										arr.insert(reg.replace(current.ltrim().trim(), '""').indexOf("main(", firstIndex), "<b><red>");
										arr.insert(reg.replace(current.ltrim().trim(), '""').indexOf("main(", firstIndex) + 6, "</></>");
										Console.log(arr.join(""));
										var squigglyLines = "";
										for (j in 0...reg.replace(current.ltrim().trim(), '""').indexOf("main(", firstIndex)) {
											squigglyLines += " ";
										}
										for (j in 0...5) {
											squigglyLines += "~";
										}
										firstIndex += 1;
										Console.log("<red>" + squigglyLines + "</>");
									}
									if (args != null && args[0] != null) {
										for (i in 0...args[0].length) {
											if (args[0][i].replace(" ", "") != "") {
												if (!Math.isNaN(Std.parseFloat(args[0][i])) || completeSyntax.contains(args[0][i])) {
													Console.log("<b><light_white>"
														+ Blue.currentFile
														+ " - "
														+ "</><b><red>Error [BLE0002]:</></><light_white> Invalid parameter at line"
														+ (linenum)
														+ "</>");
													gotErrors = true;
													Console.log("");
													var arr = current.ltrim().trim().split("");
													arr.insert(reg.replace(current.ltrim().trim(), '""').indexOf(args[0][i], firstIndex2), "<b><red>");
													arr.insert(reg.replace(current.ltrim().trim(), '""').indexOf(args[0][i], firstIndex2)
														+ args[0][i].length + 1,
														"</></>");
													Console.log(arr.join(""));
													var squigglyLines = "";
													for (j in 0...reg.replace(current.ltrim().trim(), '""').indexOf(args[0][i], firstIndex2)) {
														squigglyLines += " ";
													}
													for (j in 0...args[0][i].length) {
														squigglyLines += "~";
													}
													firstIndex2 += 1;
													Console.log("<red>" + squigglyLines + "</>");
												}
												paramVars.push(args[0][i]);
											}
										}
										currentToken = BToken.MainMethod(args);
										if (!testLex) {
											tokensToParse.push(currentToken);
										}
									} else {
										currentToken = BToken.MainMethod(null);
										if (!testLex) {
											tokensToParse.push(currentToken);
										}
									}
								} else if (reg.replace(current, '""').ltrim().replace(' ', "").startsWith('main(')
									&& reg.replace(current, '""')
										.ltrim()
										.replace(' ', "")
										.split('main(')[1].contains("main(")) {
									Console.log("<b><light_white>"
										+ Blue.currentFile
										+ " - "
										+ "</><b><red>Error [BLE0011]:</></><light_white> Expected expression at line "
										+ (linenum)
										+ "</>");
									gotErrors = true;
									Console.log("");
									Console.log("<b><red>" + current.ltrim().trim() + "</></>");
									var squigglyLines = "";
									for (i in 0...current.ltrim().trim().split('').length) {
										squigglyLines += "~";
									}
									Console.log("<red>" + squigglyLines + "</>");
								} else if (!reg.replace(current, '""').ltrim().replace(' ', "").startsWith('main(')
									&& reg.replace(current, '""')
										.ltrim()
										.replace(' ', "")
										.split('main(')[1].contains("main(")) {
									Console.log("<b><light_white>"
										+ Blue.currentFile
										+ " - "
										+ "</><b><red>Error [BLE0011]:</></><light_white> Expected expression at line "
										+ (linenum)
										+ "</>");
									gotErrors = true;
									Console.log("");
									Console.log("<b><red>" + current.ltrim().trim() + "</></>");
									var squigglyLines = "";
									for (i in 0...current.ltrim().trim().split('').length) {
										squigglyLines += "~";
									}
									Console.log("<red>" + squigglyLines + "</>");
								}
							}
						case '=':
							var firstIndex = 0;
							var firstIndex2 = 0;
							var firstIndex3 = 0;
							var firstIndex4 = 0;
							var firstIndex5 = 0;
							var firstIndex6 = 0;
							var firstIndex7 = 0;
							var firstIndex8 = 0;
							var firstIndex9 = 0;
							if (!current.ltrim().split("=")[0].contains('"')
								&& !reg.replace(current, '""').ltrim().startsWith('if ')
								&& !reg.replace(current, '""').ltrim().startsWith('else if ')) {
								var quoteNum:Int = 0;
								var tokenStr:String = current.ltrim().split('=')[1].split("\r")[0];
								var tokenStrLast:String = current.ltrim().split('=')[0].replace(" ", "");
								var trimmedCurrent = "";
								if (isPublic) {
									publicVars.push(current.ltrim().split('=')[0].replace(' ', '').replace("~", ""));
								}
								if (isPrivate) {
									privateVars.push(current.ltrim().split('=')[0].replace(' ', '').replace("~", ""));
								}
								if (reg.replace(current, '"').ltrim().contains('"')) {
									trimmedCurrent = tokenStr.replace(current.ltrim().split('"')[1].split('"')[0],
										current.ltrim().split('"')[1].split('"')[0].replace(' ', ''));
								} else {
									trimmedCurrent = tokenStr;
								}
								if (reg.replace(current, '""').ltrim().replace(' ', '').split('=')[1] == "") {
									Console.log("<b><light_white>"
										+ Blue.currentFile
										+ " - "
										+ "</><b><red>Error [BLE0011]:</></><light_white> Expected expression at line "
										+ (linenum)
										+ "</>");
									gotErrors = true;
									Console.log("");
									Console.log("<b><red>" + current.ltrim().trim() + "</></>");
									var squigglyLines = "";
									for (i in 0...current.ltrim().trim().split('').length) {
										squigglyLines += "~";
									}
									Console.log("<red>" + squigglyLines + "</>");
								}

								if (!isInMethod
									&& (localVars.contains(current.ltrim().split('=')[1].split("\r")[0].replace(' ', ''))
										|| current.ltrim().split('=')[1].split("\r")[0].contains("(")
										|| localMethods.contains(current.ltrim().split('=')[1].split("\r")[0].replace(' ', '').split("(")[0]))) {
									Console.log("<b><light_white>"
										+ Blue.currentFile
										+ " - "
										+ "</><b><red>Error [BLE0006]:</></><light_white> A static variable's initial value must be a constant at line "
										+ (linenum)
										+ "</>");
									gotErrors = true;
									Console.log("");
									var arr = current.ltrim().trim().split("");
									arr.insert(reg.replace(current.ltrim().trim(), '""').indexOf(current.ltrim().split('=')[0].replace(' ', ''), firstIndex),
										"<b><red>");
									arr.insert(reg.replace(current.ltrim().trim(), '""').indexOf(current.ltrim().split('=')[0].replace(' ', ''), firstIndex)
										+ current.ltrim().split('=')[0].replace(' ', '').length + 1,
										"</></>");
									Console.log(arr.join(""));
									var squigglyLines = "";
									for (j in 0...reg.replace(current.ltrim().trim(), '""')
										.indexOf(current.ltrim().split('=')[0].replace(' ', ''), firstIndex)) {
										squigglyLines += " ";
									}
									for (j in 0...current.ltrim().split('=')[0].replace(' ', '').length) {
										squigglyLines += "~";
									}
									firstIndex += 1;
									Console.log("<red>" + squigglyLines + "</>");
								}
								if (reg.replace(current.ltrim().split('=')[1].split("\r")[0].replace(" ", ""), '""').startsWith("[")) {
									if (reg.replace(current.ltrim().split('=')[1].split("\r")[0], '""')
										.split("[")
										.length != reg.replace(current.ltrim().split('=')[1].split("\r")[0], '""')
										.split("]")
										.length) {
										Console.log("<b><light_white>"
											+ Blue.currentFile
											+ " - "
											+ "</><b><red>Error [BLE0007]:</></><light_white> Unclosed array at line "
											+ (linenum)
											+ "</>");
										gotErrors = true;
										Console.log("");
										var arr = current.ltrim().trim().split("");
										arr.insert(reg.replace(current.ltrim().trim(), '""').indexOf(tokenStr, firstIndex2), "<b><red>");
										arr.insert(reg.replace(current.ltrim().trim(), '""').indexOf(tokenStr, firstIndex2) + tokenStr.length + 1, "</></>");
										Console.log(arr.join(""));
										var squigglyLines = "";
										for (j in 0...reg.replace(current.ltrim().trim(), '""').indexOf(tokenStr, firstIndex2)) {
											squigglyLines += " ";
										}
										for (j in 0...tokenStr.length) {
											squigglyLines += "~";
										}
										firstIndex2 += 1;
										Console.log("<red>" + squigglyLines + "</>");
									}
								}
								if (reg.replace(current.ltrim().split('=')[1].split("\r")[0].replace(" ", ""), '""').contains("[")
									&& reg.replace(current.ltrim().split('=')[1].split("\r")[0].replace(" ", ""), '""').split("[").length > 2) {
									Console.log("<b><light_white>"
										+ Blue.currentFile
										+ " - "
										+ "</><b><red>Error [BLE0075]:</></><light_white> Nested arrays are not allowed at line "
										+ (linenum)
										+ "</>");
									gotErrors = true;
									Console.log("");
									Console.log("<b><red>" + current.ltrim().trim() + "</></>");
									var squigglyLines = "";
									for (i in 0...current.ltrim().trim().split('').length) {
										squigglyLines += "~";
									}
									Console.log("<red>" + squigglyLines + "</>");
								}
								if (!reg.replace(current, '""').contains('/')) {
									if (!reg.replace(current, '""').contains('[')) {
										if (!localMethods.contains(tokenStr.replace(" ", "").split("(")[0])) {
											if (variableTypes.exists(current.ltrim().split('=')[0].replace(" ", ""))
												&& variableTypes.exists(tokenStr.replace(" ", ""))) {
												if (variableTypes.get(tokenStr.replace(" ",
													"")) != variableTypes.get(current.ltrim().split('=')[0].replace(" ", ""))
													&& variableTypes.get(tokenStr.replace(" ", "")) != 'null'
													&& variableTypes.get(current.ltrim().split('=')[0].replace(" ", "")) != 'null') {
													Console.log("<b><light_white>"
														+ Blue.currentFile
														+ " - "
														+ "</><b><red>Error [BLE0071]:</></><light_white> Invalid assignment to type '"
														+ variableTypes.get(tokenStr.replace(" ", ""))
														+ "' from type '"
														+ variableTypes.get(current.ltrim().split('=')[0].replace(" ", ""))
														+ "' at line "
														+ (linenum)
														+ "</>");
													gotErrors = true;
													Console.log("");
													Console.log("<b><red>" + current.ltrim().trim() + "</></>");
													var squigglyLines = "";
													for (i in 0...current.ltrim().trim().split('').length) {
														squigglyLines += "~";
													}
													Console.log("<red>" + squigglyLines + "</>");
												}
											}
										}
										if (!localMethods.contains(tokenStr.replace(" ", "").split("(")[0])) {
											if (variableTypes.exists(current.ltrim().split('=')[0].replace(" ", ""))
												&& !variableTypes.exists(tokenStr.replace(" ", ""))) {
												if (typesystem.StaticType.typeOf(tokenStr.replace(" ",
													"")) != variableTypes.get(current.ltrim().split('=')[0].replace(" ", ""))
													&& variableTypes.get(current.ltrim().split('=')[0].replace(" ", "")) != 'null'
													&& typesystem.StaticType.typeOf(tokenStr.replace(" ", "")) != 'null') {
													Console.log("<b><light_white>"
														+ Blue.currentFile
														+ " - "
														+ "</><b><red>Error [BLE0071]:</></><light_white> Invalid assignment to type '"
														+ typesystem.StaticType.typeOf(tokenStr.replace(" ", ""))
														+ "' from type '"
														+ variableTypes.get(current.ltrim().split('=')[0].replace(" ", ""))
														+ "' at line "
														+ (linenum)
														+ "</>");
													gotErrors = true;
													Console.log("");
													Console.log("<b><red>" + current.ltrim().trim() + "</></>");
													var squigglyLines = "";
													for (i in 0...current.ltrim().trim().split('').length) {
														squigglyLines += "~";
													}
													Console.log("<red>" + squigglyLines + "</>");
												}
											}
										}
										if (localMethods.contains(tokenStr.replace(" ", "").split("(")[0])) {
											if (methodTypes.get(tokenStr.replace(" ", "")
												.split("(")[0]) != variableTypes.get(current.ltrim().split('=')[0].replace(" ", ""))) {
												Console.log("<b><light_white>"
													+ Blue.currentFile
													+ " - "
													+ "</><b><red>Error [BLE0071]:</></><light_white> Invalid assignment to type '"
													+ methodTypes.get(tokenStr.replace(" ", ""))
													+ "' from type '"
													+ variableTypes.get(current.ltrim().split('=')[0].replace(" ", ""))
													+ "' at line "
													+ (linenum)
													+ "</>");
												gotErrors = true;
												Console.log("");
												Console.log("<b><red>" + current.ltrim().trim() + "</></>");
												var squigglyLines = "";
												for (i in 0...current.ltrim().trim().split('').length) {
													squigglyLines += "~";
												}
												Console.log("<red>" + squigglyLines + "</>");
											}
										}
									}
									variableValues.set(current.ltrim().split('=')[0].replace(' ', ''),
										current.ltrim().split('=')[1].split("(")[1].split(")")[0].replace(' ', '').replace("~", ""));
									var foundMethod = false;
									for (i in 0...localMethods.length) {
										if (current.ltrim()
											.split('=')[1].split("(")[1].split(")")[0].replace(' ', '').replace("~", "").contains(localMethods[i]))
											foundMethod = true;
									}
									var foundVar = false;
									var firstFound = false;
									for (i in 0...localVars.length) {
										if (current.ltrim().split('=')[1].split("(")[1].split(")")[0].replace(' ', '').replace("~", "").contains(localVars[i]))
											foundVar = true;
										if (current.ltrim().split('=')[0].split("(")[1].split(")")[0].replace(' ', '').replace("~", "").contains(localVars[i]))
											firstFound = true;
									}
									if (!localVars.contains(current.ltrim().split('=')[0].replace(' ', ''))) {
										if (!foundMethod && !foundVar) {
											variableTypes.set(current.ltrim().split('=')[0].replace(' ', ''),
												typesystem.StaticType.typeOf(current.ltrim().split('=')[1].replace(' ', '').replace("~", "")));
										}
										if (foundVar && !firstFound) {
											variableTypes.set(current.ltrim().split('=')[0].replace(' ', ''),
												variableTypes.get(current.ltrim().split('=')[1].replace(" ", "")));
										}
										if (foundMethod) {
											variableTypes.set(current.ltrim().split('=')[0].replace(' ', ''),
												methodTypes.get(current.ltrim().split('=')[1].replace(" ", "").split("(")[0]));
										}
									}
									if (current.split("=")[1].contains("[") && !current.split("=")[1].replace(" ", "").startsWith("[")) {
										if (localVars.contains(current.split("=")[1].split("[")[0].replace(" ", ""))
											|| paramVars.contains(current.split("=")[1].split("[")[0].replace(" ", ""))) {
											if (variableTypes.get(current.split("=")[1].split("[")[0].replace(" ", "")) != "array") {
												Console.log("<b><light_white>"
													+ Blue.currentFile
													+ " - "
													+ "</><b><red>Error [BLE0072]:</></><light_white> Attempted to index a non-array variable at line "
													+ (linenum)
													+ "</>");
												gotErrors = true;
												Console.log("");
												Console.log("<b><red>" + current.ltrim().trim() + "</></>");
												var squigglyLines = "";
												for (i in 0...current.ltrim().trim().split('').length) {
													squigglyLines += "~";
												}
												Console.log("<red>" + squigglyLines + "</>");
											}
										}
									}
								}
								if (!isInMethod)
									localVars.push(current.ltrim().split('=')[0].replace(' ', '').replace("~", ""));
								else
									paramVars.push(current.ltrim().split('=')[0].replace(' ', '').replace("~", ""));

								if (!current.contains('"') && current.contains('null')) {
									Console.log("<b><light_white>"
										+ Blue.currentFile
										+ " - "
										+ "</><b><red>Error [BLE0010]:</></><light_white> Assigning 'null' to variable at line "
										+ (linenum)
										+ "</>");
									gotErrors = true;
									var arr = current.ltrim().trim().split("");
									arr.insert(reg.replace(current.ltrim().trim(), '""').indexOf(tokenStr, firstIndex6), "<b><red>");
									arr.insert(reg.replace(current.ltrim().trim(), '""').indexOf(tokenStr, firstIndex6) + tokenStr.length + 1, "</></>");
									Console.log(arr.join(""));
									var squigglyLines = "";
									for (j in 0...reg.replace(current.ltrim().trim(), '""').indexOf(tokenStr, firstIndex6)) {
										squigglyLines += " ";
									}
									for (j in 0...tokenStr.length) {
										squigglyLines += "~";
									}
									firstIndex6 += 1;
									Console.log("<red>" + squigglyLines + "</>");
								}
								if (!current.ltrim().split('=')[0].startsWith("~")
									&& reg.replace(current.ltrim().split('=')[1].split("\r")[0].replace(" ", ""), '""').startsWith("fromAddress!(")) {
									var valueToGet = variableValues.get("~"
										+ current.ltrim().split('=')[1].replace(" ", "").split("(")[1].split(")")[0].replace("(", "").replace(")", ""));
									if (valueToGet != null) {
										if (valueToGet.contains('"')) {
											trimmedCurrent = trimmedCurrent.replace(current.ltrim().split('=')[1].split("\r")[0].replace(" ", ""), valueToGet);
										} else {
											trimmedCurrent = trimmedCurrent.replace(current.ltrim().split('=')[1].split("\r")[0].replace(" ", ""), valueToGet);
										}
									}
								} else if (!reg.replace(current.ltrim().split('=')[1].split("\r")[0], '""').replace(" ", "").startsWith("fromAddress!(")
									&& reg.replace(current.ltrim().split('=')[1].split("\r")[0], '""').replace(" ", "").contains("fromAddress!")) {
									Console.log("<b><light_white>"
										+ Blue.currentFile
										+ " - "
										+ "</><b><red>Error [BLE0008]:</></><light_white> Unknown method at line "
										+ (linenum)
										+ "</>");
									gotErrors = true;
									var arr = current.ltrim().trim().split("");
									arr.insert(reg.replace(current.ltrim().trim(), '""').indexOf(tokenStr, firstIndex7), "<b><red>");
									arr.insert(reg.replace(current.ltrim().trim(), '""').indexOf(tokenStr, firstIndex7) + tokenStr.length + 1, "</></>");
									Console.log(arr.join(""));
									var squigglyLines = "";
									for (j in 0...reg.replace(current.ltrim().trim(), '""').indexOf(tokenStr, firstIndex7)) {
										squigglyLines += " ";
									}
									for (j in 0...tokenStr.length) {
										squigglyLines += "~";
									}
									firstIndex7 += 1;
									Console.log("<red>" + squigglyLines + "</>");
								}
								if (reg.replace(current.ltrim().split('=')[1].split("\r")[0].replace(" ", ""), '""').contains(",")
									&& reg.replace(current.ltrim().split('=')[1].split("\r")[0].replace(" ", ""), '""').contains("fromAddress!")) {
									Console.log("<b><light_white>"
										+ Blue.currentFile
										+ " - "
										+ "</><b><red>Error [BLE0049]:</></><light_white> Too many parameters for macro: 'fromAddress' at line "
										+ (linenum)
										+ "</>");
									gotErrors = true;
									Console.log("");
									Console.log("<b><red>" + current.ltrim().trim() + "</></>");
									var squigglyLines = "";
									for (i in 0...current.ltrim().trim().split('').length) {
										squigglyLines += "~";
									}
									Console.log("<red>" + squigglyLines + "</>");
								}
								if (reg.replace(current.ltrim().split('=')[1].split("\r")[0].replace(" ", ""), '""').contains("fromAddress!()")) {
									Console.log("<b><light_white>"
										+ Blue.currentFile
										+ " - "
										+ "</><b><red>Error [BLE0049]:</></><light_white> Not enough parameters for macro: 'fromAddress' at line "
										+ (linenum)
										+ "</>");
									gotErrors = true;
									Console.log("");
									Console.log("<b><red>" + current.ltrim().trim() + "</></>");
									var squigglyLines = "";
									for (i in 0...current.ltrim().trim().split('').length) {
										squigglyLines += "~";
									}
									Console.log("<red>" + squigglyLines + "</>");
								}
								if (completeSyntax.contains(current.ltrim().split('=')[0].replace(" ", ""))
									|| localMethods.contains(current.ltrim().split('=')[0].replace(" ", ""))
									|| !Math.isNaN(Std.parseFloat(current.ltrim().split('=')[0].replace(" ", "")))) {
									Console.log("<b><light_white>"
										+ Blue.currentFile
										+ " - "
										+ "</><b><red>Error [BLE0011]:</></><light_white> Expected expression at line "
										+ (linenum)
										+ "</>");
									gotErrors = true;
									Console.log("");
									Console.log("<b><red>" + current.ltrim().trim() + "</></>");
									var squigglyLines = "";
									for (i in 0...current.ltrim().trim().split('').length) {
										squigglyLines += "~";
									}
									Console.log("<red>" + squigglyLines + "</>");
								}

								for (j in 0...trimmedCurrent.split(" ").length) {
									var whitespacesplit = trimmedCurrent.split("\r")[0].split(" ")[j].replace(" ", "");
									if (trimmedCurrent.split(' ')[j] == 'null' && (Blue.target == "c" || Blue.target == "cpp")) {
										whitespacesplit = 'NULL';
										trimmedCurrent = trimmedCurrent.replace(trimmedCurrent.split("\r")[0].split(' ')[j].replace("(", "").replace(")", ""),
											whitespacesplit);
									}
									if (trimmedCurrent.split(' ')[j] == 'null' && Blue.target == "go") {
										whitespacesplit = 'nil';
										trimmedCurrent = trimmedCurrent.replace(trimmedCurrent.split("\r")[0].split(' ')[j].replace("(", "").replace(")", ""),
											whitespacesplit);
									}
									if (trimmedCurrent.split(' ')[j] == 'mult') {
										whitespacesplit = '*';
										trimmedCurrent = trimmedCurrent.replace(trimmedCurrent.split("\r")[0].split(' ')[j].replace("(", "").replace(")", ""),
											whitespacesplit);
									}
									if (trimmedCurrent.split(' ')[j] == 'outof') {
										whitespacesplit = '%';
										trimmedCurrent = trimmedCurrent.replace(trimmedCurrent.split("\r")[0].split(' ')[j].replace("(", "").replace(")", ""),
											whitespacesplit);
									}
									if (regular.match(current)
										&& !current.ltrim().contains("File")
										&& !current.ltrim().contains("MathTools")
										&& !current.ltrim().contains("System")
										&& !current.ltrim().contains("ArrayTools")
										&& current.ltrim().contains("/")
										&& current.ltrim().split('/')[0].contains(whitespacesplit)) {}
									if (trimmedCurrent.split(' ')[j].contains('/')) {
										whitespacesplit = whitespacesplit.replace('/', '.');
										trimmedCurrent = trimmedCurrent.replace(trimmedCurrent.split("\r")[0].split(' ')[j].replace("(", "").replace(")", ""),
											whitespacesplit);
									}
									if (trimmedCurrent.split(' ')[j] == 'div') {
										whitespacesplit = '/';
										trimmedCurrent = trimmedCurrent.replace(trimmedCurrent.split("\r")[0].split(' ')[j].replace("(", "").replace(")", ""),
											whitespacesplit);
									}
								}
								if (trimmedCurrent.contains('/'))
									trimmedCurrent = trimmedCurrent.split('/')[1];
								else if (trimmedCurrent.contains('/'))
									tokenStr = tokenStr.split('/')[1];
								if (reg.replace(current, '"').ltrim().contains('"')) {
									trimmedCurrent = trimmedCurrent.replace(trimmedCurrent.split('"')[1].split('"')[0], tokenStr.split('"')[1].split('"')[0]);
									for (j in 2...trimmedCurrent.split('"').length) {
										trimmedCurrent = trimmedCurrent.replace(trimmedCurrent.split('"')[j + 2].split('"')[0],
											tokenStr.split('"')[j + 2].split('"')[0]);
										if (j == trimmedCurrent.split('"').length - 1) {
											tokenStr = trimmedCurrent;
											if (Blue.target == "c" || Blue.target == "cpp" || Blue.target == "go" || Blue.target == "javascript") {
												if (tokenStr.contains('/')
													&& !tokenStr.contains('"')
													&& (Blue.target == "c" || Blue.target == "cpp" || Blue.target == "go" || Blue.target == "javascript")
													&& regular.match(tokenStr)) {
													tokenStr = tokenStr.split('/')[1];
												}
												if (current.ltrim().split('=')[0].replace(' ', '').replace("~", "").contains("/")
													&& (Blue.target == "c" || Blue.target == "cpp" || Blue.target == "go" || Blue.target == "javascript")
													&& regular.match(tokenStr)) {
													tokenStr = current.split('/')[1];
												}
												if (tokenStr.contains('.')
													&& !tokenStr.contains('"')
													&& (Blue.target == "c" || Blue.target == "cpp" || Blue.target == "go" || Blue.target == "javascript")
													&& regular.match(tokenStr)) {
													tokenStr = tokenStr.split('.')[1];
												}
												if (current.ltrim().split('=')[0].replace(' ', '').replace("~", "").contains(".")
													&& !tokenStr.contains('"')
													&& (Blue.target == "c" || Blue.target == "cpp" || Blue.target == "go" || Blue.target == "javascript")
													&& regular.match(tokenStr)) {
													tokenStr = current.split('.')[1];
												}
											}
											if (regular.match(trimmedCurrent)) {
												if (!isInMethod)
													currentToken = BToken.Variable(current.ltrim().split('=')[0].replace(' ', '').replace("~", ""),
														tokenStr + ";", variableTypes.get(current.ltrim().split('=')[0].replace(' ', '').replace("~", "")));
												else if (Blue.target == "haxe") {
													currentToken = BToken.MethodVariable(current.ltrim().split('=')[0].replace(' ', '').replace("~", ""),
														tokenStr + ";", variableTypes.get(current.ltrim().split('=')[0].replace(' ', '').replace("~", "")));
												} else {
													currentToken = BToken.Variable(current.ltrim().split('=')[0].replace(' ', '').replace("~", ""),
														tokenStr + ";", variableTypes.get(current.ltrim().split('=')[0].replace(' ', '').replace("~", "")));
												}
											} else {
												if (!isInMethod)
													currentToken = BToken.Variable(current.ltrim().split('=')[0].replace(' ', '').replace("~", ""),
														tokenStr + ";", variableTypes.get(current.ltrim().split('=')[0].replace(' ', '').replace("~", "")));
												else if (Blue.target == "haxe") {
													currentToken = BToken.MethodVariable(current.ltrim().split('=')[0].replace(' ', '').replace("~", ""),
														tokenStr + ";", variableTypes.get(current.ltrim().split('=')[0].replace(' ', '').replace("~", "")));
												} else {
													currentToken = BToken.Variable(current.ltrim().split('=')[0].replace(' ', '').replace("~", ""),
														tokenStr + ";", variableTypes.get(current.ltrim().split('=')[0].replace(' ', '').replace("~", "")));
												}
											}
										}
									}
								} else {
									if (Blue.target == "c" || Blue.target == "cpp" || Blue.target == "go" || Blue.target == "javascript") {
										if (trimmedCurrent.contains('/')
											&& !trimmedCurrent.contains('"')
											&& (Blue.target == "c" || Blue.target == "cpp" || Blue.target == "go" || Blue.target == "javascript")
											&& regular.match(trimmedCurrent)) {
											trimmedCurrent = trimmedCurrent.split('/')[1];
										}
										if (current.ltrim().split('=')[0].replace(' ', '').replace("~", "").contains("/")
											&& !trimmedCurrent.contains('"')
											&& (Blue.target == "c" || Blue.target == "cpp" || Blue.target == "go" || Blue.target == "javascript")
											&& regular.match(trimmedCurrent)) {
											current = current.split('/')[1];
										}
										if (trimmedCurrent.contains('.')
											&& !trimmedCurrent.contains('"')
											&& (Blue.target == "c" || Blue.target == "cpp" || Blue.target == "go" || Blue.target == "javascript")
											&& regular.match(trimmedCurrent)) {
											trimmedCurrent = trimmedCurrent.split('.')[1];
										}
										if (current.ltrim().split('=')[0].replace(' ', '').replace("~", "").contains(".")
											&& !trimmedCurrent.contains('"')
											&& (Blue.target == "c" || Blue.target == "cpp" || Blue.target == "go" || Blue.target == "javascript")
											&& regular.match(trimmedCurrent)) {
											current = current.split('.')[1];
										}
									}
									if (regular.match(trimmedCurrent)) {
										if (!isInMethod)
											currentToken = BToken.Variable(current.ltrim().split('=')[0].replace(' ', '').replace("~", ""),
												(trimmedCurrent.replace("/", ".") + ";").replace("()()", "()"),
												variableTypes.get(current.ltrim().split('=')[0].replace(' ', '').replace("~", "")));
										else if (Blue.target == "haxe") {
											currentToken = BToken.MethodVariable(current.ltrim().split('=')[0].replace(' ', '').replace("~", ""),
												(trimmedCurrent.replace("/", ".") + ";").replace("()()", "()"),
												variableTypes.get(current.ltrim().split('=')[0].replace(' ', '').replace("~", "")));
										} else {
											currentToken = BToken.Variable(current.ltrim().split('=')[0].replace(' ', '').replace("~", ""),
												(trimmedCurrent.replace("/", ".") + ";").replace("()()", "()"),
												variableTypes.get(current.ltrim().split('=')[0].replace(' ', '').replace("~", "")));
										}
									} else {
										if (!isInMethod)
											if (Blue.target == "c") {
												var oper = current.split('(')[1].split(')')[0];
												if (Math.isNaN(Std.parseFloat(current.ltrim().split('(')[1].split(')')[0]))) {
													currentToken = BToken.Variable(current.ltrim().split('=')[0].replace(' ', '').replace("~", ""),
														(trimmedCurrent + ";").replace("cosine(",
															"" + Std.string(Math.cos(Std.parseFloat(variableValues.get(current.ltrim()
																.split('(')[1].split(')')[0])))))
															.replace("arcsine(",
																"" + Std.string(Math.asin(Std.parseFloat(variableValues.get(current.ltrim()
																	.split('(')[1].split(')')[0])))))
															.replace("arccos(",
																"" + Std.string(Math.acos(Std.parseFloat(variableValues.get(current.ltrim()
																	.split('(')[1].split(')')[0])))))
															.replace("sine(",
																"" + Std.string(Math.sin(Std.parseFloat(variableValues.get(current.ltrim()
																	.split('(')[1].split(')')[0])))))
															.replace("floorValue(",
																"" + Std.string(Math.floor(Std.parseFloat(variableValues.get(current.ltrim()
																	.split('(')[1].split(')')[0])))))
															.replace(")", "")
															.replace(oper, "")
															.replace("nn", '""'),
														variableTypes.get(current.ltrim().split('=')[0].replace(' ', '').replace("~", "")));
												} else {
													currentToken = BToken.Variable(current.ltrim().split('=')[0].replace(' ', '').replace("~", ""),
														(trimmedCurrent + ";").replace("cosine(",
															"" + Std.string(Math.cos(Std.parseFloat(current.ltrim().split('(')[1].split(')')[0]))))
															.replace("arcsine(",
																"" + Std.string(Math.asin(Std.parseFloat(current.ltrim().split('(')[1].split(')')[0]))))
															.replace("arccos(",
																"" + Std.string(Math.acos(Std.parseFloat(current.ltrim().split('(')[1].split(')')[0]))))
															.replace("sine(",
																"" + Std.string(Math.sin(Std.parseFloat(current.ltrim().split('(')[1].split(')')[0]))))
															.replace("floorValue(",
																"" + Std.string(Math.floor(Std.parseFloat(current.ltrim().split('(')[1].split(')')[0]))))
															.replace(")", "")
															.replace("nn", '""'),
														variableTypes.get(current.ltrim().split('=')[0].replace(' ', '').replace("~", "")));
												}
											} else {
												currentToken = BToken.Variable(current.ltrim().split('=')[0].replace(' ', '').replace("~", ""),
													(trimmedCurrent + ";").replace("()()", "()"),
													variableTypes.get(current.ltrim().split('=')[0].replace(' ', '').replace("~", "")));
											}
										else if (Blue.target == "haxe" || Blue.target == "cs") {
											currentToken = BToken.MethodVariable(current.ltrim().split('=')[0].replace(' ', '').replace("~", ""),
												(trimmedCurrent + ";").replace("()()", "()"),
												variableTypes.get(current.ltrim().split('=')[0].replace(' ', '').replace("~", "")));
										} else {
											if (current.ltrim().split('=')[1].split("(")[1].split(")")[0].contains(".")) {
												if (Blue.target == "c") {
													var oper = current.split('(')[1].split(')')[0];
													if (Math.isNaN(Std.parseFloat(current.ltrim().split('(')[1].split(')')[0]))) {
														currentToken = BToken.Variable(current.ltrim().split('=')[0].replace(' ', '').replace("~", ""),
															(trimmedCurrent + ";").replace("cosine(",
																"" + Std.string(Math.cos(Std.parseFloat(variableValues.get(current.ltrim()
																	.split('(')[1].split(')')[0])))))
																.replace("arcsine(",
																	"" + Std.string(Math.asin(Std.parseFloat(variableValues.get(current.ltrim()
																		.split('(')[1].split(')')[0])))))
																.replace("arccos(",
																	"" + Std.string(Math.acos(Std.parseFloat(variableValues.get(current.ltrim()
																		.split('(')[1].split(')')[0])))))
																.replace("sine(",
																	"" + Std.string(Math.sin(Std.parseFloat(variableValues.get(current.ltrim()
																		.split('(')[1].split(')')[0])))))
																.replace("floorValue(",
																	"" + Std.string(Math.floor(Std.parseFloat(variableValues.get(current.ltrim()
																		.split('(')[1].split(')')[0])))))
																.replace(")", "")
																.replace(oper, "")
																.replace("nn", '""'),
															variableTypes.get(current.ltrim().split('=')[0].replace(' ', '').replace("~", "")));
													} else {
														currentToken = BToken.Variable(current.ltrim().split('=')[0].replace(' ', '').replace("~", ""),
															(trimmedCurrent + ";").replace("cosine(",
																"" + Std.string(Math.cos(Std.parseFloat(current.ltrim().split('(')[1].split(')')[0]))))
																.replace("arcsine(",
																	"" + Std.string(Math.asin(Std.parseFloat(current.ltrim().split('(')[1].split(')')[0]))))
																.replace("arccos(",
																	"" + Std.string(Math.acos(Std.parseFloat(current.ltrim().split('(')[1].split(')')[0]))))
																.replace("sine(",
																	"" + Std.string(Math.sin(Std.parseFloat(current.ltrim().split('(')[1].split(')')[0]))))
																.replace("floorValue(",
																	"" + Std.string(Math.floor(Std.parseFloat(current.ltrim().split('(')[1].split(')')[0]))))
																.replace(")", ""),
															variableTypes.get(current.ltrim().split('=')[0].replace(' ', '').replace("~", "")));
													}
												} else {
													currentToken = BToken.Variable(current.ltrim().split('=')[0].replace(' ', '').replace("~", ""),
														(trimmedCurrent + ";").replace("()()", "()"),
														variableTypes.get(current.ltrim().split('=')[0].replace(' ', '').replace("~", "")));
												}
											} else {
												if (Blue.target == "c") {
													var oper = current.split('(')[1].split(')')[0];
													if (Math.isNaN(Std.parseFloat(current.ltrim().split('(')[1].split(')')[0]))) {
														currentToken = BToken.Variable(current.ltrim().split('=')[0].replace(' ', '').replace("~", ""),
															(trimmedCurrent + ";").replace("cosine(",
																"" + Std.string(Math.cos(Std.parseFloat(variableValues.get(current.ltrim()
																	.split('(')[1].split(')')[0])))))
																.replace("arcsine(",
																	"" + Std.string(Math.asin(Std.parseFloat(variableValues.get(current.ltrim()
																		.split('(')[1].split(')')[0])))))
																.replace("arccos(",
																	"" + Std.string(Math.acos(Std.parseFloat(variableValues.get(current.ltrim()
																		.split('(')[1].split(')')[0])))))
																.replace("sine(",
																	"" + Std.string(Math.sin(Std.parseFloat(variableValues.get(current.ltrim()
																		.split('(')[1].split(')')[0])))))
																.replace("floorValue(",
																	"" + Std.string(Math.floor(Std.parseFloat(variableValues.get(current.ltrim()
																		.split('(')[1].split(')')[0])))))
																.replace(")", "")
																.replace(oper, "")
																.replace("nn", '""'),
															variableTypes.get(current.ltrim().split('=')[0].replace(' ', '').replace("~", "")));
													} else {
														currentToken = BToken.Variable(current.ltrim().split('=')[0].replace(' ', '').replace("~", ""),
															(trimmedCurrent + ";").replace("cosine(",
																"" + Std.string(Math.cos(Std.parseFloat(current.ltrim().split('(')[1].split(')')[0]))))
																.replace("arcsine(",
																	"" + Std.string(Math.asin(Std.parseFloat(current.ltrim().split('(')[1].split(')')[0]))))
																.replace("arccos(",
																	"" + Std.string(Math.acos(Std.parseFloat(current.ltrim().split('(')[1].split(')')[0]))))
																.replace("sine(",
																	"" + Std.string(Math.sin(Std.parseFloat(current.ltrim().split('(')[1].split(')')[0]))))
																.replace("floorValue(",
																	"" + Std.string(Math.floor(Std.parseFloat(current.ltrim().split('(')[1].split(')')[0]))))
																.replace(")", "")
																.replace("nn", '""'),
															variableTypes.get(current.ltrim().split('=')[0].replace(' ', '').replace("~", "")));
													}
												} else {
													currentToken = BToken.Variable(current.ltrim().split('=')[0].replace(' ', '').replace("~", ""),
														(trimmedCurrent + ";").replace("()()", "()"),
														variableTypes.get(current.ltrim().split('=')[0].replace(' ', '').replace("~", "")));
												}
											}
										}
									}
								}
								if (reg.replace(current, '""').ltrim().replace(' ', "").split('=')[1].contains("=")) {
									Console.log("<b><light_white>"
										+ Blue.currentFile
										+ " - "
										+ "</><b><red>Error [BLE0011]:</></><light_white> Expected expression at line "
										+ (linenum)
										+ "</>");
									gotErrors = true;
									Console.log("");
									Console.log("<b><red>" + current.ltrim().trim() + "</></>");
									var squigglyLines = "";
									for (i in 0...current.ltrim().trim().split('').length) {
										squigglyLines += "~";
									}
									Console.log("<red>" + squigglyLines + "</>");
								}
								if (!closedLibs.contains(reg.replace(current.ltrim(), '""')
									.split('/')[0].replace(current.split("=")[1], "").replace("=", '').replace(' ', ''))) {
									if (regular.match(current)
										&& !reg.replace(current.ltrim(), '""').contains("File")
										&& !reg.replace(current.ltrim(), '""').contains("MathTools")
										&& !reg.replace(current.ltrim(), '""').contains("System")
										&& !reg.replace(current.ltrim(), '""').contains("ArrayTools")
										&& current.ltrim().contains("/")) {
										if (FileSystem.exists(Blue.directory
											+ "/"
											+ reg.replace(current.ltrim(), '""').split('/')[0].split("=")[1].replace(" ", "") + ".bl")) {
											if (!reg.replace(File.getContent(Blue.directory
												+ "/"
												+ reg.replace(current.ltrim(), '""').split('/')[0].split("=")[1].replace(' ', '') + ".bl"),
												'""')
												.replace(" ", "")
												.contains(reg.replace(current.ltrim(), '""').split('/')[1].split("=")[1].replace(' ', "") + "=")) {
												Console.log("<b><light_white>"
													+ Blue.currentFile
													+ " - "
													+ "</><b><red>Error [BLE0074]:</></><light_white> Library does not contain variable at line "
													+ (linenum)
													+ "</>");
												gotErrors = true;
												Console.log("");
												Console.log("<b><red>" + current.ltrim().trim() + "</></>");
												var squigglyLines = "";
												for (i in 0...current.ltrim().trim().split('').length) {
													squigglyLines += "~";
												}
												Console.log("<red>" + squigglyLines + "</>");
											}
										} else {
											Console.log("<b><light_white>"
												+ Blue.currentFile
												+ " - "
												+ "</><b><red>Error [BLE0049]:</></><light_white> Unknown library at line "
												+ (linenum)
												+ "</>");
											gotErrors = true;
											Console.log("");
											Console.log("<b><red>" + current.ltrim().trim() + "</></>");
											var squigglyLines = "";
											for (i in 0...current.ltrim().trim().split('').length) {
												squigglyLines += "~";
											}
											Console.log("<red>" + squigglyLines + "</>");
										}
									}
								} else {
									Console.log("<b><light_white>"
										+ Blue.currentFile
										+ " - "
										+ "</><b><red>Error [BLE0049]:</></><light_white> Unknown library at line "
										+ (linenum)
										+ "</>");
									gotErrors = true;
									Console.log("");
									Console.log("<b><red>" + current.ltrim().trim() + "</></>");
									var squigglyLines = "";
									for (i in 0...current.ltrim().trim().split('').length) {
										squigglyLines += "~";
									}
									Console.log("<red>" + squigglyLines + "</>");
								}

								if (reg.replace(current, '""').ltrim().replace(' ', "").split('=')[1].contains("/")
									&& current.ltrim().split('=')[0].replace(' ', '').contains("~")) {
									Console.log("<b><light_white>"
										+ Blue.currentFile
										+ " - "
										+ "Error: Pointer variable '"
										+ current.ltrim().split('=')[0].replace("~", "").replace(" ", "")
											+ "' expected memory address at line "
											+ (linenum)
											+ "</>");
									gotErrors = true;
									Console.log("");
									var arr = current.ltrim().trim().split("");
									arr.insert(reg.replace(current.ltrim().trim(), '""').indexOf(tokenStrLast, firstIndex4), "<b><red>");
									arr.insert(reg.replace(current.ltrim().trim(), '""').indexOf(tokenStrLast, firstIndex4) + tokenStrLast.length + 1,
										"</></>");
									Console.log(arr.join(""));
									var squigglyLines = "";
									for (j in 0...reg.replace(current.ltrim().trim(), '""').indexOf(tokenStrLast, firstIndex4)) {
										squigglyLines += " ";
									}
									for (j in 0...tokenStrLast.length) {
										squigglyLines += "~";
										Console.log("<red>" + squigglyLines + "</>");
									}

									var linealt = contentToEnum.split("\n")[j];
									if (!new EReg("[A-Z+]" + "=", "i").match(linealt.replace(" ", ""))) {
										Console.log("<b><light_white>"
											+ Blue.currentFile
											+ " - "
											+ "</><b><red>Error [BLE0013]:</></><light_white> Invalid variable definition at line "
											+ (linenum)
											+ "</>");
										gotErrors = true;
										Console.log("");
										Console.log("<b><red>" + current.ltrim().trim() + "</></>");
										var squigglyLines = "";
										for (i in 0...current.ltrim().trim().split('').length) {
											squigglyLines += "~";
										}
										Console.log("<red>" + squigglyLines + "</>");
									}
								} else if (!current.ltrim().split("=")[0].contains('"')
									&& !reg.replace(current, '""').ltrim().startsWith('if ')
									&& !reg.replace(current, '""').ltrim().startsWith('else if ')
									&& reg.replace(current, '""').contains('=')
									&& !new EReg("[A-Z+]", "i").match(reg.replace(current, '""').split('=')[0])) {
									Console.log("<b><light_white>"
										+ Blue.currentFile
										+ " - "
										+ "</><b><red>Error [BLE0011]:</></><light_white> Expected expression at line "
										+ (linenum)
										+ "</>");
									gotErrors = true;
									Console.log("");
									Console.log("<b><red>" + current.ltrim().trim() + "</></>");
									var squigglyLines = "";
									for (i in 0...current.ltrim().trim().split('').length) {
										squigglyLines += "~";
									}
									Console.log("<red>" + squigglyLines + "</>");
								}
								if (!testLex) {
									tokensToParse.push(currentToken);
								}
							}
						case 'loop ':
							if (isInMethod) {
								if (reg.replace(current, '""').ltrim().startsWith("loop ")) {
									if (!new EReg("loop" + "[A-Z+]" + "in" + "[0-9+]" + "until" + '.+', "i").match(current.replace(' ', ''))) {
										Console.log("<b><light_white>"
											+ Blue.currentFile
											+ " - "
											+ "</><b><red>Error [BLE0014]:</></><light_white> Invalid loop at line "
											+ (linenum)
											+ "</>");
										gotErrors = true;
										Console.log("");
										Console.log("<b><red>" + current.ltrim().trim() + "</></>");
										var squigglyLines = "";
										for (i in 0...current.ltrim().trim().split('').length) {
											squigglyLines += "~";
										}
										Console.log("<red>" + squigglyLines + "</>");
									} else {
										endsNeededToEndMethod += 1;
										currentToken = BToken.ForStatement(current.ltrim().split('loop ')[1].split('in')[0].replace(' ', ''),
											current.ltrim().split('loop ')[1].split('in')[1].replace(' ', '').split('until')[0].replace(' ', ''),
											current.ltrim()
												.split('until')[1].replace(' ', '')
												.replace(current.ltrim().split('until')[1].replace(' ', '').split("/")[0] + "/", ""));
										if (!testLex) {
											tokensToParse.push(currentToken);
										}
									}
									paramVars.push(current.ltrim().split('loop ')[1].split(' in')[0]);
									variableTypes.set(current.ltrim().split('loop ')[1].split(' in')[0], "int");
									paramTypes.set(current.ltrim().split('loop ')[1].split(' in')[0], "int");
								} else if (!reg.replace(current, '""').ltrim().startsWith("loop ")
									&& reg.replace(current, '""').contains('loop ')) {
									Console.log("<b><light_white>"
										+ Blue.currentFile
										+ " - "
										+ "</><b><red>Error [BLE0015]:</></><light_white> Expected loop at line "
										+ (linenum)
										+ "</>");
									gotErrors = true;
									Console.log("");
									Console.log("<b><red>" + current.ltrim().trim() + "</></>");
									var squigglyLines = "";
									for (i in 0...current.ltrim().trim().split('').length) {
										squigglyLines += "~";
									}
									Console.log("<red>" + squigglyLines + "</>");
								} else if (reg.replace(current, '""').ltrim().replace(' ', "").startsWith('loop')
									&& reg.replace(current, '""')
										.ltrim()
										.replace(' ', "")
										.split('loop')[1].contains("loop")) {
									Console.log("<b><light_white>"
										+ Blue.currentFile
										+ " - "
										+ "</><b><red>Error [BLE0011]:</></><light_white> Expected expression at line "
										+ (linenum)
										+ "</>");
									gotErrors = true;
									Console.log("");
									Console.log("<b><red>" + current.ltrim().trim() + "</></>");
									var squigglyLines = "";
									for (i in 0...current.ltrim().trim().split('').length) {
										squigglyLines += "~";
									}
									Console.log("<red>" + squigglyLines + "</>");
								} else if (!reg.replace(current, '""').ltrim().replace(' ', "").startsWith('loop')
									&& reg.replace(current, '""')
										.ltrim()
										.replace(' ', "")
										.split('loop')[1].contains("loop")) {
									Console.log("<b><light_white>"
										+ Blue.currentFile
										+ " - "
										+ "</><b><red>Error [BLE0011]:</></><light_white> Expected expression at line "
										+ (linenum)
										+ "</>");
									gotErrors = true;
									Console.log("");
									Console.log("<b><red>" + current.ltrim().trim() + "</></>");
									var squigglyLines = "";
									for (i in 0...current.ltrim().trim().split('').length) {
										squigglyLines += "~";
									}
									Console.log("<red>" + squigglyLines + "</>");
								}
							} else {
								Console.log("<b><light_white>"
									+ Blue.currentFile
									+ " - "
									+ "</><b><red>Error [BLE0016]:</></><light_white> 'loop' expression outside of method at line "
									+ (linenum)
									+ "</>");
								gotErrors = true;
								Console.log("");
								Console.log("<b><red>" + current.ltrim().trim() + "</></>");
								var squigglyLines = "";
								for (i in 0...current.ltrim().trim().split('').length) {
									squigglyLines += "~";
								}
								Console.log("<red>" + squigglyLines + "</>");
							}

						case "if ":
							var firstIndex = 0;
							var firstIndex2 = 0;
							var firstIndex3 = 0;
							if (!reg.replace(current, '""').ltrim().startsWith("else if ")) {
								if (isInMethod) {
									if (reg.replace(current, '""').ltrim().startsWith("if ")) {
										endsNeededToEndMethod += 1;
										var linenum = j + 1;
										var quoteNum:Int = 0;
										var symbols:String = "|~#$%()*+-:;<=>@[]^_.,'!?";
										var tokenStr:String = current.ltrim().split('if ')[1].split('then')[0];
										var trimmedCurrent = "";
										if (reg.replace(current, '"').ltrim().contains('"')) {
											trimmedCurrent = reg.replace(tokenStr, '""');
										} else {
											trimmedCurrent = tokenStr;
										}

										for (j in 0...current.ltrim().split('if ')[1].split('then')[0].split(' ').length) {
											if (reg.replace(current, '"').ltrim().contains('"')) {
												quoteNum = quoteNum + 1;
												if (quoteNum > 1) {
													trimmedCurrent = trimmedCurrent.replace(current.ltrim().split('"')[quoteNum + 1].split('"')[0],
														current.ltrim().split('"')[quoteNum + 1].split('"')[0].replace(' ', ''));
												}
											}
											var whitespacesplit = trimmedCurrent.split(' ')[j];
											var whitespacesplitlast = trimmedCurrent.split(' ')[j - 1];
											if (!completeSyntax.contains(whitespacesplit)
												&& whitespacesplit != 'and'
												&& whitespacesplit != 'outof'
												&& whitespacesplit != 'or'
												&& whitespacesplit != '>'
												&& whitespacesplit != '<'
												&& whitespacesplit != 'true'
												&& whitespacesplit != 'false'
												&& whitespacesplit != 'null'
												&& whitespacesplit != 'not'
												&& whitespacesplit != "/"
												&& !trimmedCurrent.split(' ')[j].contains('/')
												&& !whitespacesplit.contains('"')
												&& whitespacesplit != "div"
												&& whitespacesplit != "mult"
												&& whitespacesplit != "="
												&& whitespacesplit != "-"
												&& whitespacesplit != "+"
												&& whitespacesplit != ""
												&& whitespacesplit != null
												&& Math.isNaN(Std.parseFloat(whitespacesplit))
												&& !localVars.contains(whitespacesplit.replace("(", "").replace(")", ""))
												&& !paramVars.contains(whitespacesplit.replace("(", "").replace(")", ""))
												&& !variableValues.exists(whitespacesplit.replace("(", "").replace(")", ""))) {
												Console.log("<b><light_white>"
													+ Blue.currentFile
													+ " - "
													+ "</><b><red>Error [BLE0017]:</></><light_white> Unknown variable at line "
													+ (linenum)
													+ "</>");
												gotErrors = true;
												var arr = current.ltrim().trim().split("");
												arr.insert(reg.replace(current.ltrim().trim(), '""').indexOf(whitespacesplit, firstIndex), "<b><red>");
												arr.insert(reg.replace(current.ltrim().trim(), '""').indexOf(whitespacesplit, firstIndex)
													+ whitespacesplit.length
													+ 1,
													"</></>");
												Console.log(arr.join(""));
												var squigglyLines = "";
												for (j in 0...reg.replace(current.ltrim().trim(), '""').indexOf(whitespacesplit, firstIndex)) {
													squigglyLines += " ";
												}
												for (j in 0...whitespacesplit.length) {
													squigglyLines += "~";
												}
												firstIndex += 1;
												Console.log("<red>" + squigglyLines + "</>");
											}
											if (trimmedCurrent.split(' ')[j] == 'or') {
												whitespacesplit = ' || ';
												trimmedCurrent = trimmedCurrent.replace(" or ", whitespacesplit);
												if (!Math.isNaN(Std.parseFloat(trimmedCurrent.split(' ')[j + 1].replace(' ', '')))
													|| trimmedCurrent.split(' ')[j + 1].replace(" ", "") == "") {
													Console.log("<b><light_white>"
														+ Blue.currentFile
														+ " - "
														+ "</><b><red>Error [BLE0011]:</></><light_white> Expected expression at line "
														+ (linenum)
														+ "</>");
													gotErrors = true;
													Console.log("");
													Console.log("<b><red>" + current.ltrim().trim() + "</></>");
													var squigglyLines = "";
													for (i in 0...current.ltrim().trim().split('').length) {
														squigglyLines += "~";
													}
													Console.log("<red>" + squigglyLines + "</>");
												}
											}
											if (trimmedCurrent.split(' ')[j] == 'null'
												&& !trimmedCurrent.split(whitespacesplit)[0].contains("=")) {
												Console.log("<b><light_white>"
													+ Blue.currentFile
													+ " - "
													+ "</><b><red>Error [BLE0018]:</></><light_white> Expected '=' at line "
													+ (linenum)
													+ "</>");
												gotErrors = true;
												var arr = current.ltrim().trim().split("");
												arr.insert(reg.replace(current.ltrim().trim(), '""').indexOf(whitespacesplit, firstIndex2), "<b><red>");
												arr.insert(reg.replace(current.ltrim().trim(), '""').indexOf(whitespacesplit, firstIndex2)
													+ whitespacesplit.length
													+ 1,
													"</></>");
												Console.log(arr.join(""));
												var squigglyLines = "";
												for (j in 0...reg.replace(current.ltrim().trim(), '""').indexOf(whitespacesplit, firstIndex2)) {
													squigglyLines += " ";
												}
												for (j in 0...whitespacesplit.length) {
													squigglyLines += "~";
												}
												firstIndex2 += 1;
												Console.log("<red>" + squigglyLines + "</>");
											}
											if (trimmedCurrent.split(' ')[j] == 'null' && (Blue.target == "c" || Blue.target == "cpp")) {
												whitespacesplit = ' NULL ';
												trimmedCurrent = trimmedCurrent.replace(" null ", whitespacesplit);
											}
											if (trimmedCurrent.split(' ')[j] == 'null' && Blue.target == "go") {
												whitespacesplit = ' NULL ';
												trimmedCurrent = trimmedCurrent.replace(" null ", whitespacesplit);
											}
											if (trimmedCurrent.split(' ')[j] == 'outof') {
												whitespacesplit = ' % ';
												trimmedCurrent = trimmedCurrent.replace(" outof ", whitespacesplit);
												if (!Math.isNaN(Std.parseFloat(trimmedCurrent.split(' ')[j + 1].replace(' ', '')))
													|| trimmedCurrent.split(' ')[j + 1].replace(" ", "") == "") {
													Console.log("<b><light_white>"
														+ Blue.currentFile
														+ " - "
														+ "</><b><red>Error [BLE0011]:</></><light_white> Expected expression at line "
														+ (linenum)
														+ "</>");
													gotErrors = true;
													Console.log("");
													Console.log("<b><red>" + current.ltrim().trim() + "</></>");
													var squigglyLines = "";
													for (i in 0...current.ltrim().trim().split('').length) {
														squigglyLines += "~";
													}
													Console.log("<red>" + squigglyLines + "</>");
												}
											}
											if (trimmedCurrent.split(' ')[j] == 'not') {
												whitespacesplit = '!';
												trimmedCurrent = trimmedCurrent.replace("not ", whitespacesplit);
											}
											if (trimmedCurrent.split(' ')[j].contains('/')) {
												if (Blue.target == "c" || Blue.target == "cpp") {
													whitespacesplit = (trimmedCurrent.split(' ')[j].split("/")[0].replace(trimmedCurrent.split(' ')[j].split("(")[0],
														"")
														+ "/");
													trimmedCurrent = trimmedCurrent.replace(whitespacesplit, "");
												} else if (Blue.target != "c" && Blue.target != "cpp") {
													whitespacesplit = '.';
													trimmedCurrent = trimmedCurrent.replace("/", whitespacesplit);
												}
											}
											if (trimmedCurrent.split(' ')[j] == 'div') {
												whitespacesplit = '/';
												trimmedCurrent = trimmedCurrent.replace(" div ", whitespacesplit);
												if (!Math.isNaN(Std.parseFloat(trimmedCurrent.split(' ')[j + 1].replace(' ', '')))
													|| trimmedCurrent.split(' ')[j + 1].replace(" ", "") == "") {
													Console.log("<b><light_white>"
														+ Blue.currentFile
														+ " - "
														+ "</><b><red>Error [BLE0011]:</></><light_white> Expected expression at line "
														+ (linenum)
														+ "</>");
													gotErrors = true;
													Console.log("");
													Console.log("<b><red>" + current.ltrim().trim() + "</></>");
													var squigglyLines = "";
													for (i in 0...current.ltrim().trim().split('').length) {
														squigglyLines += "~";
													}
													Console.log("<red>" + squigglyLines + "</>");
												}
											}
											if (trimmedCurrent.split(' ')[j] == 'mult') {
												whitespacesplit = ' * ';
												trimmedCurrent = trimmedCurrent.replace(" mult ", whitespacesplit);
												if (!Math.isNaN(Std.parseFloat(trimmedCurrent.split(' ')[j + 1].replace(' ', '')))
													|| trimmedCurrent.split(' ')[j + 1].replace(" ", "") == "") {
													Console.log("<b><light_white>"
														+ Blue.currentFile
														+ " - "
														+ "</><b><red>Error [BLE0011]:</></><light_white> Expected expression at line "
														+ (linenum)
														+ "</>");
													gotErrors = true;
													Console.log("");
													Console.log("<b><red>" + current.ltrim().trim() + "</></>");
													var squigglyLines = "";
													for (i in 0...current.ltrim().trim().split('').length) {
														squigglyLines += "~";
													}
													Console.log("<red>" + squigglyLines + "</>");
												}
											}
											if (trimmedCurrent.split(' ')[j] == 'and') {
												whitespacesplit = ' && ';
												trimmedCurrent = trimmedCurrent.replace(" and ", whitespacesplit);
												if (!Math.isNaN(Std.parseFloat(trimmedCurrent.split(' ')[j + 1].replace(' ', '')))
													|| trimmedCurrent.split(' ')[j + 1].replace(" ", "") == "") {
													Console.log("<b><light_white>"
														+ Blue.currentFile
														+ " - "
														+ "</><b><red>Error [BLE0011]:</></><light_white> Expected expression at line "
														+ (linenum)
														+ "</>");
													gotErrors = true;
													Console.log("");
													Console.log("<b><red>" + current.ltrim().trim() + "</></>");
													var squigglyLines = "";
													for (i in 0...current.ltrim().trim().split('').length) {
														squigglyLines += "~";
													}
													Console.log("<red>" + squigglyLines + "</>");
												}
											}
											if (trimmedCurrent.split(' ')[j] == '=') {
												if (whitespacesplitlast != "not") {
													whitespacesplit = ' == ';
													trimmedCurrent = trimmedCurrent.replace(" = ", whitespacesplit);
												} else {
													whitespacesplit = '=';
													trimmedCurrent = trimmedCurrent.replace(" =", whitespacesplit);
												}
											}
											if (trimmedCurrent.split(' ')[j] == '*') {
												Console.log("<b><light_white>"
													+ Blue.currentFile
													+ " - "
													+ "</><b><red>Error [BLE0019]:</></><light_white> Unknown character: '*' at line "
													+ (linenum)
													+ "</>");
												gotErrors = true;
												var arr = current.ltrim().trim().split("");
												arr.insert(reg.replace(current.ltrim().trim(), '""').indexOf(whitespacesplit, firstIndex3), "<b><red>");
												arr.insert(reg.replace(current.ltrim().trim(), '""').indexOf(whitespacesplit, firstIndex3)
													+ whitespacesplit.length
													+ 1,
													"</></>");
												Console.log(arr.join(""));
												var squigglyLines = "";
												for (j in 0...reg.replace(current.ltrim().trim(), '""').indexOf(whitespacesplit, firstIndex3)) {
													squigglyLines += " ";
												}
												for (j in 0...whitespacesplit.length) {
													squigglyLines += "~";
												}
												firstIndex3 += 1;
												Console.log("<red>" + squigglyLines + "</>");
											}
										}
										trimmedCurrent = trimmedCurrent.replace("!==", "!=");
										if (reg.replace(current, '"').ltrim().contains('"')) {
											var arr = trimmedCurrent.split('');
											for (i in 0...trimmedCurrent.split('"').length) {
												if (trimmedCurrent.split('"')[i].split('"')[0] == ''
													&& tokenStr.split('"')[i].split('"')[0] != '') {
													for (j in 0...arr.length) {
														if (arr[j] == '"' && arr[j + 1] == '"') {
															arr.insert(j + 1, tokenStr.split('"')[i].split('"')[0]);
															break;
														}
													}
												}
											}
											tokenStr = arr.join('');
											currentToken = BToken.IfStatement(tokenStr);
										} else {
											tokenStr = trimmedCurrent;
											currentToken = BToken.IfStatement(tokenStr);
										}
										if (!testLex) {
											tokensToParse.push(currentToken);
										}
									} else if (reg.replace(current, '""').contains('if ')
										&& !reg.replace(current, '""').ltrim().startsWith("if ")) {
										Console.log("<b><light_white>"
											+ Blue.currentFile
											+ " - "
											+ "</><b><red>Error [BLE0020]:</></><light_white> Expected 'if' statement at line "
											+ (linenum)
											+ "</>");
										gotErrors = true;
										Console.log("");
										Console.log("<b><red>" + current.ltrim().trim() + "</></>");
										var squigglyLines = "";
										for (i in 0...current.ltrim().trim().split('').length) {
											squigglyLines += "~";
										}
										Console.log("<red>" + squigglyLines + "</>");
									} else if (reg.replace(current, '""').ltrim().replace(' ', "").startsWith('if')
										&& reg.replace(current, '""').ltrim().replace(' ', "").split('if')[1].contains("if")) {
										Console.log("<b><light_white>"
											+ Blue.currentFile
											+ " - "
											+ "</><b><red>Error [BLE0011]:</></><light_white> Expected expression at line "
											+ (linenum)
											+ "</>");
										gotErrors = true;
										Console.log("");
										Console.log("<b><red>" + current.ltrim().trim() + "</></>");
										var squigglyLines = "";
										for (i in 0...current.ltrim().trim().split('').length) {
											squigglyLines += "~";
										}
										Console.log("<red>" + squigglyLines + "</>");
									} else if (!reg.replace(current, '""').ltrim().replace(' ', "").startsWith('if')
										&& reg.replace(current, '""').ltrim().replace(' ', "").split('if')[1].contains("if")) {
										Console.log("<b><light_white>"
											+ Blue.currentFile
											+ " - "
											+ "</><b><red>Error [BLE0011]:</></><light_white> Expected expression at line "
											+ (linenum)
											+ "</>");
										gotErrors = true;
										Console.log("");
										Console.log("<b><red>" + current.ltrim().trim() + "</></>");
										var squigglyLines = "";
										for (i in 0...current.ltrim().trim().split('').length) {
											squigglyLines += "~";
										}
										Console.log("<red>" + squigglyLines + "</>");
									}
								} else {
									Console.log("<b><light_white>"
										+ Blue.currentFile
										+ " - "
										+ "</><b><red>Error [BLE0021]:</></><light_white> 'if' statement outside of method at line "
										+ (linenum)
										+ "</>");
									gotErrors = true;
									Console.log("");
									Console.log("<b><red>" + current.ltrim().trim() + "</></>");
									var squigglyLines = "";
									for (i in 0...current.ltrim().trim().split('').length) {
										squigglyLines += "~";
									}
									Console.log("<red>" + squigglyLines + "</>");
								}
							}

						case "end":
							var firstIndex = 0;
							var firstIndex2 = 0;
							if (reg.replace(current, '""').ltrim().startsWith('end')
								|| reg.replace(current, '""').ltrim().endsWith('end')) {
								currentToken = BToken.End;
								if (isInMethod)
									endsNeededToEndMethod--;
								if (isPublic || isPrivate)
									endsNeededToEndModifier--;
								if (isInLibrary)
									endsNeededToEndLibrary--;
								if (endsNeededToEndMethod == 1) {
									needsReturn = true;
								}
								if (endsNeededToEndModifier == 0) {
									isPublic = false;
									isPrivate = false;
								}
								if (endsNeededToEndLibrary == 0) {
									isInLibrary = false;
								}
								if (endsNeededToEndMethod == 0 && !needsReturn) {
									isInMethod = false;
									paramVars = [];
									for (key in paramTypes.keys()) {
										variableTypes.remove(key);
									}
									paramTypes.clear();
								}
								if (endsNeededToEndMethod == 0 && (!needsReturn || needsReturn) && isInMain) {
									isInMain = false;
									needsReturn = false;
									isInMethod = false;
									paramVars = [];
									for (key in paramTypes.keys()) {
										variableTypes.remove(key);
									}
									paramTypes.clear();
								}

								if (needsReturn && endsNeededToEndMethod == 0) {
									Console.log("<b><light_white>"
										+ Blue.currentFile
										+ " - "
										+ "</><b><red>Error [BLE0061]:</></><light_white> A method "
										+ "was provided no return value at line "
										+ (i + 1)
										+ '</>');
									gotErrors = true;
									Console.log("");
									Console.log("<b><red>" + current.ltrim().trim() + "</></>");
									var squigglyLines = "";
									for (i in 0...current.ltrim().trim().split('').length) {
										squigglyLines += "~";
									}
									Console.log("<red>" + squigglyLines + "</>");
								}
								if (!testLex && (!isPublic || !isPrivate) && !isInLibrary) {
									tokensToParse.push(currentToken);
								}
							} else if (!reg.replace(current, '""').ltrim().startsWith('end')
								&& !reg.replace(current, '""').ltrim().endsWith('end')
								&& reg.replace(current, '""').contains(' end ')) {
								Console.log("<b><light_white>"
									+ Blue.currentFile
									+ " - "
									+ "</><b><red>Error [BLE0022]:</></><light_white> Invalid 'end' block at line "
									+ (linenum)
									+ "</>");
								gotErrors = true;
								var arr = current.ltrim().trim().split("");
								arr.insert(reg.replace(current.ltrim().trim(), '""').indexOf("end", firstIndex), "<b><red>");
								arr.insert(reg.replace(current.ltrim().trim(), '""').indexOf("end", firstIndex) + 4, "</></>");
								Console.log(arr.join(""));
								var squigglyLines = "";
								for (j in 0...reg.replace(current.ltrim().trim(), '""').indexOf("end", firstIndex)) {
									squigglyLines += " ";
								}
								for (j in 0...3) {
									squigglyLines += "~";
								}
								firstIndex += 1;
								Console.log("<red>" + squigglyLines + "</>");
							}
							if (reg.replace(current, '""').ltrim().replace(' ', "").startsWith('end')
								&& reg.replace(current, '""').ltrim().replace(' ', "").split('end')[1].contains("end")) {
								Console.log("<b><light_white>"
									+ Blue.currentFile
									+ " - "
									+ "</><b><red>Error [BLE0011]:</></><light_white> Expected expression at line "
									+ (linenum)
									+ "</>");
								gotErrors = true;
								Console.log("");
								Console.log("<b><red>" + current.ltrim().trim() + "</></>");
								var squigglyLines = "";
								for (i in 0...current.ltrim().trim().split('').length) {
									squigglyLines += "~";
								}
								Console.log("<red>" + squigglyLines + "</>");
							} else if (!reg.replace(current, '""').ltrim().replace(' ', "").startsWith('end')
								&& reg.replace(current, '""').ltrim().replace(' ', "").split('end')[1].contains("end")) {
								Console.log("<b><light_white>"
									+ Blue.currentFile
									+ " - "
									+ "</><b><red>Error [BLE0011]:</></><light_white> Expected expression at line "
									+ (linenum)
									+ "</>");
								gotErrors = true;
								Console.log("");
								Console.log("<b><red>" + current.ltrim().trim() + "</></>");
								var squigglyLines = "";
								for (i in 0...current.ltrim().trim().split('').length) {
									squigglyLines += "~";
								}
								Console.log("<red>" + squigglyLines + "</>");
							}

						case "print!":
							var firstIndex = 0;
							var firstIndex2 = 0;
							if (isInMethod) {
								if (current.ltrim().replace(' ', "").startsWith("print!(")) {
									var symbols:String = "|~#$%()*+-:;<=>@[]^_.,'!?";
									if (reg.replace(current, '"').ltrim().contains(")\r")) {
										if (reg.replace(current, '"').ltrim().contains("print!(")) {
											currentToken = BToken.Print(current.ltrim().split('print!(')[1].split(")\r")[0]);
											if (!current.ltrim().replace(' ', "").contains('"')) {
												Console.log("<b><light_white>"
													+ Blue.currentFile
													+ " - "
													+
													"</><b><red>Error [BLE0023]:</></><light_white> Attempted to call 'print' macro without using a whole string or char at line "
													+ (linenum)
													+ "</>");
												gotErrors = true;
												var arr = current.ltrim().trim().split("");
												arr.insert(reg.replace(current.ltrim().trim(), '""')
													.indexOf(current.ltrim().split('print!(')[1].split(")\r")[0].replace(" ", ""), firstIndex2),
													"<b><red>");
												arr.insert(reg.replace(current.ltrim().trim(), '""')
													.indexOf(current.ltrim().split('print!(')[1].split(")\r")[0].replace(" ", ""),
														firstIndex2) + current.ltrim().split('print!(')[1].split(")\r")[0].length
														+ 1,
													"</></>");
												Console.log(arr.join(""));
												var squigglyLines = "";
												for (j in 0...reg.replace(current.ltrim().trim(), '""')
													.indexOf(current.ltrim().split('print!(')[1].split(")\r")[0].replace(" ", ""), firstIndex2)) {
													squigglyLines += " ";
												}
												for (j in 0...current.ltrim().split('print!(')[1].split(")\r")[0].replace(" ", "").length) {
													squigglyLines += "~";
												}
												firstIndex2 += 1;
												Console.log("<red>" + squigglyLines + "</>");
											}

											if (!testLex) {
												tokensToParse.push(currentToken);
											}
										}
										if (reg.replace(current.ltrim().replace(' ', ""), '""').contains(",")) {
											Console.log("<b><light_white>"
												+ Blue.currentFile
												+ " - "
												+ "</><b><red>Error [BLE0050]:</></><light_white> Too many parameters for method: 'print!"
												+ "' at line "
												+ (linenum)
												+ "</>");
											gotErrors = true;
											Console.log("");
											Console.log("<b><red>" + current.ltrim().trim() + "</></>");
											var squigglyLines = "";
											for (i in 0...current.ltrim().trim().split('').length) {
												squigglyLines += "~";
											}
											Console.log("<red>" + squigglyLines + "</>");
										}
									} else {
										Console.log("<b><light_white>"
											+ Blue.currentFile
											+ " - "
											+ "</><b><red>Error [BLE0024]:</></><light_white> Method calls must be ended with a ')' and a newline at line "
											+ (linenum)
											+ "</>");
										gotErrors = true;
										Console.log("");
										Console.log("<b><red>" + current.ltrim().trim() + "</></>");
										var squigglyLines = "";
										for (i in 0...current.ltrim().trim().split('').length) {
											squigglyLines += "~";
										}
										Console.log("<red>" + squigglyLines + "</>");
									}
								} else if (reg.replace(current, '""').ltrim().replace(' ', "").startsWith('print!(')
									&& reg.replace(current, '""')
										.ltrim()
										.replace(' ', "")
										.split('print!(')[1].contains("print!(")) {
									Console.log("<b><light_white>"
										+ Blue.currentFile
										+ " - "
										+ "</><b><red>Error [BLE0011]:</></><light_white> Expected expression at line "
										+ (linenum)
										+ "</>");
									gotErrors = true;
									Console.log("");
									Console.log("<b><red>" + current.ltrim().trim() + "</></>");
									var squigglyLines = "";
									for (i in 0...current.ltrim().trim().split('').length) {
										squigglyLines += "~";
									}
									Console.log("<red>" + squigglyLines + "</>");
								} else if (!reg.replace(current, '""').ltrim().replace(' ', "").startsWith('print!(')
									&& reg.replace(current, '""')
										.ltrim()
										.replace(' ', "")
										.split('print!(')[1].contains("print!(")) {
									Console.log("<b><light_white>"
										+ Blue.currentFile
										+ " - "
										+ "</><b><red>Error [BLE0011]:</></><light_white> Expected expression at line "
										+ (linenum)
										+ "</>");
									gotErrors = true;
									Console.log("");
									Console.log("<b><red>" + current.ltrim().trim() + "</></>");
									var squigglyLines = "";
									for (i in 0...current.ltrim().trim().split('').length) {
										squigglyLines += "~";
									}
									Console.log("<red>" + squigglyLines + "</>");
								}
							} else {
								Console.log("<b><light_white>"
									+ Blue.currentFile
									+ " - "
									+ "</><b><red>Error [BLE0025]:</></><light_white> Method call outside of method at line"
									+ (linenum)
									+ "</>");
								gotErrors = true;
								Console.log("");
								Console.log("<b><red>" + current.ltrim().trim() + "</></>");
								var squigglyLines = "";
								for (i in 0...current.ltrim().trim().split('').length) {
									squigglyLines += "~";
								}
								Console.log("<red>" + squigglyLines + "</>");
							}

						case "return":
							var firstIndex = 0;
							if (isInMethod) {
								if (reg.replace(current, '""').ltrim().startsWith("return")) {
									var tokenStr:String = current.ltrim().split('return ')[1].replace('\r', ";");
									if ((reg.replace(current, '"').ltrim().contains("return"))) {
										needsReturn = false;
										if (!reg.replace(current, '"').ltrim().contains('"')
											&& (Blue.target == "c" || Blue.target == "cpp")) {
											tokenStr = tokenStr.replace("null", '');
										} else if (!reg.replace(current, '"').ltrim().contains('"') && Blue.target == "go") {
											tokenStr = tokenStr.replace("null", 'nil');
										}
										if (typesystem.StaticType.typeOf(tokenStr.replace(" ", "").replace("\r", "").replace("\n", "")) != "null") {
											methodTypes.set(localMethods[localMethods.length - 1],
												typesystem.StaticType.typeOf(tokenStr.replace(" ", "").replace("\r", "").replace("\n", "")));
										}
										if (typesystem.StaticType.typeOf(tokenStr.replace(" ", "").replace("\r", "").replace("\n", "")) == "null"
											&& tokenStr.replace(" ", "").replace("\r", "").replace("\n", "") == "null") {
											methodTypes.set(localMethods[localMethods.length - 1], "null");
										} else if (typesystem.StaticType.typeOf(tokenStr.replace(" ", "").replace("\r", "").replace("\n", "")) == "null"
											&& tokenStr.replace(" ", "").replace("\r", "").replace("\n", "") != "null") {
											methodTypes.set(localMethods[localMethods.length - 1],
												variableTypes.get(tokenStr.replace(" ", "").replace("\r", "").replace("\n", "")));
										}
										currentToken = BToken.Return(tokenStr);
										if (!testLex)
											tokensToParse.push(currentToken);
									} else {
										Console.log("<b><light_white>"
											+ Blue.currentFile
											+ " - "
											+ "</><b><red>Error [BLE0034]:</></><light_white> Expected 'return' statement at line "
											+ (linenum)
											+ "</>");
										gotErrors = true;
										Console.log("");
										Console.log("<b><red>" + current.ltrim().trim() + "</></>");
										var squigglyLines = "";
										for (i in 0...current.ltrim().trim().split('').length) {
											squigglyLines += "~";
										}
										Console.log("<red>" + squigglyLines + "</>");
									}
									if (reg.replace(current, '""').ltrim().replace(' ', "").startsWith('return')
										&& reg.replace(current, '""')
											.ltrim()
											.replace(' ', "")
											.split('return')[1].contains("return")) {
										Console.log("<b><light_white>"
											+ Blue.currentFile
											+ " - "
											+ "</><b><red>Error [BLE0011]:</></><light_white> Expected expression at line "
											+ (linenum)
											+ "</>");
										gotErrors = true;
										Console.log("");
										Console.log("<b><red>" + current.ltrim().trim() + "</></>");
										var squigglyLines = "";
										for (i in 0...current.ltrim().trim().split('').length) {
											squigglyLines += "~";
										}
										Console.log("<red>" + squigglyLines + "</>");
									} else if (!reg.replace(current, '""').ltrim().replace(' ', "").startsWith('return')
										&& reg.replace(current, '""')
											.ltrim()
											.replace(' ', "")
											.split('return')[1].contains("return")) {
										Console.log("<b><light_white>"
											+ Blue.currentFile
											+ " - "
											+ "</><b><red>Error [BLE0011]:</></><light_white> Expected expression at line "
											+ (linenum)
											+ "</>");
										gotErrors = true;
										Console.log("");
										Console.log("<b><red>" + current.ltrim().trim() + "</></>");
										var squigglyLines = "";
										for (i in 0...current.ltrim().trim().split('').length) {
											squigglyLines += "~";
										}
										Console.log("<red>" + squigglyLines + "</>");
									}
								}
							} else {
								Console.log("<b><light_white>"
									+ Blue.currentFile
									+ " - "
									+ "</><b><red>Error [BLE0035]:</></><light_white> 'return' statement outside of method at line "
									+ (linenum)
									+ "</>");
								gotErrors = true;
								Console.log("");
								Console.log("<b><red>" + current.ltrim().trim() + "</></>");
								var squigglyLines = "";
								for (i in 0...current.ltrim().trim().split('').length) {
									squigglyLines += "~";
								}
								Console.log("<red>" + squigglyLines + "</>");
							}

						case "***":
							if (reg.replace(current, '""').ltrim().startsWith('***')) {
								currentToken = BToken.Comment(current.ltrim().split('*** ')[1].split('***')[0]);
								if (!testLex) {
									tokensToParse.push(currentToken);
								}
							} else if (!reg.replace(current, '""').ltrim().startsWith('***')
								&& reg.replace(current, '""').ltrim().contains('***')) {
								Console.log("<b><light_white>"
									+ Blue.currentFile
									+ " - "
									+ "</><b><red>Error [BLE0036]:</></><light_white> Expected comment at line "
									+ (linenum)
									+ "</>");
								gotErrors = true;
								Console.log("");
								Console.log("<b><red>" + current.ltrim().trim() + "</></>");
								var squigglyLines = "";
								for (i in 0...current.ltrim().trim().split('').length) {
									squigglyLines += "~";
								}
								Console.log("<red>" + squigglyLines + "</>");
							}
							if (reg.replace(current, '""').ltrim().startsWith('***')
								&& !reg.replace(current, '""').trim().endsWith('***')) {
								Console.log("<b><light_white>"
									+ Blue.currentFile
									+ " - "
									+ "</><b><red>Error [BLE0036]:</></><light_white> Expected comment at line "
									+ (linenum)
									+ "</>");
								gotErrors = true;
								Console.log("");
								Console.log("<b><red>" + current.ltrim().trim() + "</></>");
								var squigglyLines = "";
								for (i in 0...current.ltrim().trim().split('').length) {
									squigglyLines += "~";
								}
								Console.log("<red>" + squigglyLines + "</>");
							}

						case 'else if ':
							var firstIndex = 0;
							var firstIndex2 = 0;
							var firstIndex3 = 0;
							if (isInMethod) {
								if (reg.replace(current, '""').ltrim().startsWith("else if ")) {
									endsNeededToEndMethod--;
									endsNeededToEndMethod++;
									var trimmedCurrent:String = "";
									var tokenStr:String = current.ltrim().split('if ')[1].split('then')[0];
									var quoteNum:Int = 0;
									if (reg.replace(current, '"').ltrim().contains('"')) {
										trimmedCurrent = reg.replace(tokenStr, '""');
									} else {
										trimmedCurrent = tokenStr;
									}

									for (j in 0...current.ltrim().split('if ')[1].split('then')[0].split(' ').length) {
										if (reg.replace(current, '"').ltrim().contains('"')) {
											quoteNum = quoteNum + 1;
											if (quoteNum > 1) {
												trimmedCurrent = trimmedCurrent.replace(current.ltrim().split('"')[quoteNum + 1].split('"')[0],
													current.ltrim().split('"')[quoteNum + 1].split('"')[0].replace(' ', ''));
											}
										}
										var whitespacesplit = trimmedCurrent.split(' ')[j];
										var whitespacesplitlast = trimmedCurrent.split(' ')[j - 1];
										if (!completeSyntax.contains(whitespacesplit)
											&& whitespacesplit != 'and'
											&& whitespacesplit != 'outof'
											&& whitespacesplit != 'or'
											&& whitespacesplit != '>'
											&& whitespacesplit != '<'
											&& whitespacesplit != 'true'
											&& whitespacesplit != 'false'
											&& whitespacesplit != 'null'
											&& whitespacesplit != 'not'
											&& whitespacesplit != "/"
											&& !trimmedCurrent.split(' ')[j].contains('/')
											&& !whitespacesplit.contains('"')
											&& whitespacesplit != "div"
											&& whitespacesplit != "mult"
											&& whitespacesplit != "="
											&& whitespacesplit != "-"
											&& whitespacesplit != "+"
											&& whitespacesplit != ""
											&& whitespacesplit != null
											&& Math.isNaN(Std.parseFloat(whitespacesplit))
											&& !localVars.contains(whitespacesplit.replace("(", "").replace(")", ""))
											&& !paramVars.contains(whitespacesplit.replace("(", "").replace(")", ""))
											&& !variableValues.exists(whitespacesplit.replace("(", "").replace(")", ""))) {
											Console.log("<b><light_white>"
												+ Blue.currentFile
												+ " - "
												+ "</><b><red>Error [BLE0017]:</></><light_white> Unknown variable at line "
												+ (linenum)
												+ "</>");
											gotErrors = true;
											var arr = current.ltrim().trim().split("");
											arr.insert(reg.replace(current.ltrim().trim(), '""').indexOf(whitespacesplit, firstIndex), "<b><red>");
											arr.insert(reg.replace(current.ltrim().trim(), '""').indexOf(whitespacesplit, firstIndex)
												+ whitespacesplit.length
												+ 1,
												"</></>");
											Console.log(arr.join(""));
											var squigglyLines = "";
											for (j in 0...reg.replace(current.ltrim().trim(), '""').indexOf(whitespacesplit, firstIndex)) {
												squigglyLines += " ";
											}
											for (j in 0...whitespacesplit.length) {
												squigglyLines += "~";
											}
											firstIndex += 1;
											Console.log("<red>" + squigglyLines + "</>");
										}
										if (trimmedCurrent.split(' ')[j] == 'or') {
											whitespacesplit = ' || ';
											trimmedCurrent = trimmedCurrent.replace(" or ", whitespacesplit);
											if (!Math.isNaN(Std.parseFloat(trimmedCurrent.split(' ')[j + 1].replace(' ', '')))
												|| trimmedCurrent.split(' ')[j + 1].replace(" ", "") == "") {
												Console.log("<b><light_white>"
													+ Blue.currentFile
													+ " - "
													+ "</><b><red>Error [BLE0011]:</></><light_white> Expected expression at line "
													+ (linenum)
													+ "</>");
												gotErrors = true;
												Console.log("");
												Console.log("<b><red>" + current.ltrim().trim() + "</></>");
												var squigglyLines = "";
												for (i in 0...current.ltrim().trim().split('').length) {
													squigglyLines += "~";
												}
												Console.log("<red>" + squigglyLines + "</>");
											}
										}
										if (trimmedCurrent.split(' ')[j] == 'null'
											&& !trimmedCurrent.split(whitespacesplit)[0].contains("=")) {
											Console.log("<b><light_white>"
												+ Blue.currentFile
												+ " - "
												+ "</><b><red>Error [BLE0018]:</></><light_white> Expected '=' at line "
												+ (linenum)
												+ "</>");
											gotErrors = true;
											var arr = current.ltrim().trim().split("");
											arr.insert(reg.replace(current.ltrim().trim(), '""').indexOf(whitespacesplit, firstIndex2), "<b><red>");
											arr.insert(reg.replace(current.ltrim().trim(), '""').indexOf(whitespacesplit, firstIndex2)
												+ whitespacesplit.length
												+ 1,
												"</></>");
											Console.log(arr.join(""));
											var squigglyLines = "";
											for (j in 0...reg.replace(current.ltrim().trim(), '""').indexOf(whitespacesplit, firstIndex2)) {
												squigglyLines += " ";
											}
											for (j in 0...whitespacesplit.length) {
												squigglyLines += "~";
											}
											firstIndex2 += 1;
											Console.log("<red>" + squigglyLines + "</>");
										}
										if (trimmedCurrent.split(' ')[j] == 'null' && (Blue.target == "c" || Blue.target == "cpp")) {
											whitespacesplit = ' NULL ';
											trimmedCurrent = trimmedCurrent.replace(" null ", whitespacesplit);
										}
										if (trimmedCurrent.split(' ')[j] == 'null' && Blue.target == "go") {
											whitespacesplit = ' NULL ';
											trimmedCurrent = trimmedCurrent.replace(" null ", whitespacesplit);
										}
										if (trimmedCurrent.split(' ')[j] == 'outof') {
											whitespacesplit = ' % ';
											trimmedCurrent = trimmedCurrent.replace(" outof ", whitespacesplit);
											if (!Math.isNaN(Std.parseFloat(trimmedCurrent.split(' ')[j + 1].replace(' ', '')))
												|| trimmedCurrent.split(' ')[j + 1].replace(" ", "") == "") {
												Console.log("<b><light_white>"
													+ Blue.currentFile
													+ " - "
													+ "</><b><red>Error [BLE0011]:</></><light_white> Expected expression at line "
													+ (linenum)
													+ "</>");
												gotErrors = true;
												Console.log("");
												Console.log("<b><red>" + current.ltrim().trim() + "</></>");
												var squigglyLines = "";
												for (i in 0...current.ltrim().trim().split('').length) {
													squigglyLines += "~";
												}
												Console.log("<red>" + squigglyLines + "</>");
											}
										}
										if (trimmedCurrent.split(' ')[j] == 'not') {
											whitespacesplit = '!';
											trimmedCurrent = trimmedCurrent.replace("not ", whitespacesplit);
										}
										if (trimmedCurrent.split(' ')[j].contains('/')) {
											if (Blue.target == "c" || Blue.target == "cpp") {
												whitespacesplit = (trimmedCurrent.split(' ')[j].split("/")[0].replace(trimmedCurrent.split(' ')[j].split("(")[0],
													"")
													+ "/");
												trimmedCurrent = trimmedCurrent.replace(whitespacesplit, "");
											} else if (Blue.target != "c" && Blue.target != "cpp") {
												whitespacesplit = '.';
												trimmedCurrent = trimmedCurrent.replace("/", whitespacesplit);
											}
										}
										if (trimmedCurrent.split(' ')[j] == 'div') {
											whitespacesplit = '.';
											trimmedCurrent = trimmedCurrent.replace(" div ", whitespacesplit);
											if (!Math.isNaN(Std.parseFloat(trimmedCurrent.split(' ')[j + 1].replace(' ', '')))
												|| trimmedCurrent.split(' ')[j + 1].replace(" ", "") == "") {
												Console.log("<b><light_white>"
													+ Blue.currentFile
													+ " - "
													+ "</><b><red>Error [BLE0011]:</></><light_white> Expected expression at line "
													+ (linenum)
													+ "</>");
												gotErrors = true;
												Console.log("");
												Console.log("<b><red>" + current.ltrim().trim() + "</></>");
												var squigglyLines = "";
												for (i in 0...current.ltrim().trim().split('').length) {
													squigglyLines += "~";
												}
												Console.log("<red>" + squigglyLines + "</>");
											}
										}
										if (trimmedCurrent.split(' ')[j] == 'mult') {
											whitespacesplit = ' * ';
											trimmedCurrent = trimmedCurrent.replace(" mult ", whitespacesplit);
											if (!Math.isNaN(Std.parseFloat(trimmedCurrent.split(' ')[j + 1].replace(' ', '')))
												|| trimmedCurrent.split(' ')[j + 1].replace(" ", "") == "") {
												Console.log("<b><light_white>"
													+ Blue.currentFile
													+ " - "
													+ "</><b><red>Error [BLE0011]:</></><light_white> Expected expression at line "
													+ (linenum)
													+ "</>");
												gotErrors = true;
												Console.log("");
												Console.log("<b><red>" + current.ltrim().trim() + "</></>");
												var squigglyLines = "";
												for (i in 0...current.ltrim().trim().split('').length) {
													squigglyLines += "~";
												}
												Console.log("<red>" + squigglyLines + "</>");
											}
										}
										if (trimmedCurrent.split(' ')[j] == 'and') {
											whitespacesplit = ' && ';
											trimmedCurrent = trimmedCurrent.replace(" and ", whitespacesplit);
											if (!Math.isNaN(Std.parseFloat(trimmedCurrent.split(' ')[j + 1].replace(' ', '')))
												|| trimmedCurrent.split(' ')[j + 1].replace(" ", "") == "") {
												Console.log("<b><light_white>"
													+ Blue.currentFile
													+ " - "
													+ "</><b><red>Error [BLE0011]:</></><light_white> Expected expression at line "
													+ (linenum)
													+ "</>");
												gotErrors = true;
												Console.log("");
												Console.log("<b><red>" + current.ltrim().trim() + "</></>");
												var squigglyLines = "";
												for (i in 0...current.ltrim().trim().split('').length) {
													squigglyLines += "~";
												}
												Console.log("<red>" + squigglyLines + "</>");
											}
										}
										if (trimmedCurrent.split(' ')[j] == '=') {
											if (whitespacesplitlast != "not") {
												whitespacesplit = ' == ';
												trimmedCurrent = trimmedCurrent.replace(" = ", whitespacesplit);
											} else {
												whitespacesplit = '=';
												trimmedCurrent = trimmedCurrent.replace(" =", whitespacesplit);
											}
										}
										if (trimmedCurrent.split(' ')[j] == '*') {
											Console.log("<b><light_white>"
												+ Blue.currentFile
												+ " - "
												+ "</><b><red>Error [BLE0019]:</></><light_white> Unknown character: '*' at line "
												+ (linenum)
												+ "</>");
											gotErrors = true;
											var arr = current.ltrim().trim().split("");
											arr.insert(reg.replace(current.ltrim().trim(), '""').indexOf(whitespacesplit, firstIndex3), "<b><red>");
											arr.insert(reg.replace(current.ltrim().trim(), '""').indexOf(whitespacesplit, firstIndex3)
												+ whitespacesplit.length
												+ 1,
												"</></>");
											Console.log(arr.join(""));
											var squigglyLines = "";
											for (j in 0...reg.replace(current.ltrim().trim(), '""').indexOf(whitespacesplit, firstIndex3)) {
												squigglyLines += " ";
											}
											for (j in 0...whitespacesplit.length) {
												squigglyLines += "~";
											}
											firstIndex3 += 1;
											Console.log("<red>" + squigglyLines + "</>");
										}
									}
									trimmedCurrent = trimmedCurrent.replace("!==", "!=");
									if (reg.replace(current, '"').ltrim().contains('"')) {
										var arr = trimmedCurrent.split('');
										for (i in 0...trimmedCurrent.split('"').length) {
											if (trimmedCurrent.split('"')[i].split('"')[0] == ''
												&& tokenStr.split('"')[i].split('"')[0] != '') {
												for (j in 0...arr.length) {
													if (arr[j] == '"' && arr[j + 1] == '"') {
														arr.insert(j + 1, tokenStr.split('"')[i].split('"')[0]);
														break;
													}
												}
											}
										}
										tokenStr = arr.join('');
										currentToken = BToken.OtherwiseIf(tokenStr);
									} else {
										tokenStr = trimmedCurrent;
										currentToken = BToken.OtherwiseIf(tokenStr);
									}
									if (!testLex) {
										tokensToParse.push(currentToken);
									}
								} else if (reg.replace(current, '""').ltrim().replace(' ', "").startsWith('else if')
									&& reg.replace(current, '""')
										.ltrim()
										.replace(' ', "")
										.split('else if')[1].contains("else if")) {
									Console.log("<b><light_white>"
										+ Blue.currentFile
										+ " - "
										+ "</><b><red>Error [BLE0011]:</></><light_white> Expected expression at line "
										+ (linenum)
										+ "</>");
									gotErrors = true;
									Console.log("");
									Console.log("<b><red>" + current.ltrim().trim() + "</></>");
									var squigglyLines = "";
									for (i in 0...current.ltrim().trim().split('').length) {
										squigglyLines += "~";
									}
									Console.log("<red>" + squigglyLines + "</>");
								} else if (!reg.replace(current, '""').ltrim().replace(' ', "").startsWith('else if')
									&& reg.replace(current, '""')
										.ltrim()
										.replace(' ', "")
										.split('else if')[1].contains("else if")) {
									Console.log("<b><light_white>"
										+ Blue.currentFile
										+ " - "
										+ "</><b><red>Error [BLE0011]:</></><light_white> Expected expression at line "
										+ (linenum)
										+ "</>");
									gotErrors = true;
									Console.log("");
									Console.log("<b><red>" + current.ltrim().trim() + "</></>");
									var squigglyLines = "";
									for (i in 0...current.ltrim().trim().split('').length) {
										squigglyLines += "~";
									}
									Console.log("<red>" + squigglyLines + "</>");
								}
							} else {
								Console.log("<b><light_white>"
									+ Blue.currentFile
									+ " - "
									+ "</><b><red>Error [BLE0046]:</></><light_white> 'else if' statement outside of method at line "
									+ (linenum)
									+ "</>");
								gotErrors = true;
								Console.log("");
								Console.log("<b><red>" + current.ltrim().trim() + "</></>");
								var squigglyLines = "";
								for (i in 0...current.ltrim().trim().split('').length) {
									squigglyLines += "~";
								}
								Console.log("<red>" + squigglyLines + "</>");
							}

						case 'else':
							if (!reg.replace(current, '""').ltrim().startsWith("else if ")) {
								if (isInMethod) {
									if (reg.replace(current, '""').ltrim().startsWith("else")
										&& !reg.replace(current, '""').ltrim().startsWith("else if ")) {
										currentToken = BToken.Else;
										endsNeededToEndMethod--;
										endsNeededToEndMethod++;
										if (!testLex) {
											tokensToParse.push(currentToken);
										}
									}
								}
							}

						case '(':
							var firstIndex = 0;
							var firstIndex2 = 0;
							var firstIndex3 = 0;
							var firstIndex4 = 0;
							var firstIndex5 = 0;
							var firstIndex6 = 0;
							var firstIndex7 = 0;
							var firstIndex8 = 0;
							var firstIndex9 = 0;
							var linenum = j + 1;
							var currentSymbol = null;
							var whitespacesplit = current.ltrim().split(")\r")[0];
							var symbols:String = "|~#$%()*+-:;<=>@[]^_.,'!?";
							if ((!reg.replace(current, '""').ltrim().startsWith('method '))
								&& (!reg.replace(current, '""').ltrim().replace(" ", "").startsWith('new'))
								&& (!reg.replace(current, '""').ltrim().startsWith('loop '))
								&& (!reg.replace(current, '""').ltrim().replace(" ", "").startsWith('if'))
								&& (!reg.replace(current, '""').ltrim().startsWith('else if'))
								&& (!reg.replace(current, '""').ltrim().replace(" ", "").startsWith('print!('))
								&& (!reg.replace(current, '""').ltrim().replace(" ", "").startsWith('main('))
								&& (!reg.replace(current, '""').ltrim().replace(" ", "").startsWith('@'))
								&& (!reg.replace(current, '""').ltrim().replace(" ", "").startsWith('super('))
								&& (!reg.replace(current, '""').ltrim().replace(" ", "").contains('targetInject!('))) {
								if (isInMethod) {
									if (reg.replace(current, '"').ltrim().contains(')\r')) {
										if (!localMethods.contains(whitespacesplit.replace(" ", "")
											.split("(")[0].replace(current.split("=")[0].replace(" ", ""), "").replace("=", '').replace(' ', ''))
											&& !whitespacesplit.replace(" ", "")
												.split("(")[0].replace(current.split("=")[0], "").replace("=", '').contains("/")) {
											Console.log("<b><light_white>"
												+ Blue.currentFile
												+ " - "
												+ "</><b><red>Error [BLE0008]:</></><light_white> Unknown method at line "
												+ (j + 1));
											gotErrors = true;
											var arr = current.ltrim().trim().split("");
											arr.insert(reg.replace(current.ltrim().trim(), '""')
												.indexOf(whitespacesplit.split("(")[0].replace(" ", ""), firstIndex),
												"<b><red>");
											arr.insert(reg.replace(current.ltrim().trim(), '""')
												.indexOf(whitespacesplit.split("(")[0].replace(" ", ""),
													firstIndex) + whitespacesplit.split("(")[0].replace(" ", "").length
													+ 1,
												"</></>");
											Console.log(arr.join(""));
											var squigglyLines = "";
											for (j in 0...reg.replace(current.ltrim().trim(), '""')
												.indexOf(whitespacesplit.split("(")[0].replace(" ", ""), firstIndex)) {
												squigglyLines += " ";
											}
											for (j in 0...whitespacesplit.split("(")[0].replace(" ", "").length) {
												squigglyLines += "~";
											}
											firstIndex += 1;
											Console.log("<red>" + squigglyLines + "</>");
										}
										if ((!reg.replace(current, '""').ltrim().contains('method'))
											&& (!reg.replace(current, '""').ltrim().contains('main('))
											&& (!reg.replace(current, '""').ltrim().contains('constructor('))
											&& (!reg.replace(current, '""').ltrim().contains('loop '))
											&& (!reg.replace(current, '""').ltrim().contains('if'))
											&& (!reg.replace(current, '""').ltrim().contains('else if'))
											&& (!reg.replace(current, '""').ltrim().contains('print!('))
											&& (!reg.replace(current, '""').ltrim().contains('@'))
											&& (!reg.replace(current, '""').ltrim().contains('super('))) {
											var regu = ~/\([^()]*(?R)?[^()]*\)/g;
											if (methodParams.get(whitespacesplit.replace(" ", "")
												.split("(")[0].replace(current.split("=")[0], "").replace("=", '')) != null) {
												if (methodParams.get(whitespacesplit.replace(" ", "")
													.split("(")[0].replace(current.split("=")[0], "").replace("=", ''))
													.length > regu.replace(current.split("(")[1], '')
													.split(",")
													.length) {
													Console.log("<b><light_white>"
														+ Blue.currentFile
														+ " - "
														+ "</><b><red>Error [BLE0049]:</></><light_white> Not enough parameters for method: '"
														+ whitespacesplit.replace(" ", "").split("(")[0].replace(current.split("=")[0], "").replace("=", '')
															+ "' at line "
															+ (linenum)
															+ "</>");
													gotErrors = true;
													Console.log("");
													Console.log("<b><red>" + current.ltrim().trim() + "</></>");
													var squigglyLines = "";
													for (i in 0...current.ltrim().trim().split('').length) {
														squigglyLines += "~";
													}
													Console.log("<red>" + squigglyLines + "</>");
												}
												if (methodParams.get(whitespacesplit.replace(" ", "")
													.split("(")[0].replace(current.split("=")[0], "").replace("=", ''))
													.length < regu.replace(current.split("(")[1], '')
													.split(",")
													.length) {
													Console.log("<b><light_white>"
														+ Blue.currentFile
														+ " - "
														+ "</><b><red>Error [BLE0050]:</></><light_white> Too many parameters for method: '"
														+ whitespacesplit.replace(" ", "").split("(")[0].replace(current.split("=")[0], "").replace("=", '')
															+ "' at line "
															+ (linenum)
															+ "</>");
													gotErrors = true;
													Console.log("");
													Console.log("<b><red>" + current.ltrim().trim() + "</></>");
													var squigglyLines = "";
													for (i in 0...current.ltrim().trim().split('').length) {
														squigglyLines += "~";
													}
													Console.log("<red>" + squigglyLines + "</>");
												}
											}
											if (completeStd.exists(whitespacesplit.split("(")[0].split("/")[1].replace(" ", "").split("=")[0])) {
												if (completeStd.get(whitespacesplit.split("(")[0].split("/")[1].replace(" ", "").split("=")[0])
													.length > regu.replace(current.split("(")[1], '')
													.split(",")
													.length) {
													Console.log("<b><light_white>"
														+ Blue.currentFile
														+ " - "
														+ "</><b><red>Error [BLE0049]:</></><light_white> Not enough parameters for method: '"
														+ whitespacesplit.split("(")[0].split("/")[1].split("=")[0].replace(" ", "")
															+ "' at line "
															+ (linenum)
															+ "</>");
													gotErrors = true;
													Console.log("");
													Console.log("<b><red>" + current.ltrim().trim() + "</></>");
													var squigglyLines = "";
													for (i in 0...current.ltrim().trim().split('').length) {
														squigglyLines += "~";
													}
													Console.log("<red>" + squigglyLines + "</>");
												}
												if (completeStd.get(whitespacesplit.split("(")[0].split("/")[1].split("=")[0].replace(" ", ""))
													.length < regu.replace(current.split("(")[1], '')
													.split(",")
													.length) {
													Console.log("<b><light_white>"
														+ Blue.currentFile
														+ " - "
														+ "</><b><red>Error [BLE0050]:</></><light_white> Too many parameters for method: '"
														+ whitespacesplit.split("(")[0].split("/")[1].split("=")[0].replace(" ", "")
															+ "' at line "
															+ (linenum)
															+ "</>");
													gotErrors = true;
													Console.log("");
													Console.log("<b><red>" + current.ltrim().trim() + "</></>");
													var squigglyLines = "";
													for (i in 0...current.ltrim().trim().split('').length) {
														squigglyLines += "~";
													}
													Console.log("<red>" + squigglyLines + "</>");
												}
											}
											if (stdNames.exists(whitespacesplit.split("(")[0].split("/")[0].replace(current.split("=")[0], "")
											.replace("=", '')
											.replace(" ", ""))) {
												if (!stdNames.get(whitespacesplit.split("(")[0].split("/")[0].replace(current.split("=")[0], "")
												.replace("=", '')
												.replace(" ", ""))
													.contains(whitespacesplit.split("(")[0].split("/")[1].split("=")[0].replace(" ", ""))) {
													Console.log("<b><light_white>"
														+ Blue.currentFile
														+ " - "
														+ "</><b><red>Error [BLE0049]:</></><light_white> Library does not contain method called at line "
														+ (linenum)
														+ "</>");
													gotErrors = true;
													Console.log("");
													Console.log("<b><red>" + current.ltrim().trim() + "</></>");
													var squigglyLines = "";
													for (i in 0...current.ltrim().trim().split('').length) {
														squigglyLines += "~";
													}
													Console.log("<red>" + squigglyLines + "</>");
												}
											}
										}
									}
									if (!closedLibs.contains(reg.replace(current.ltrim(), '""')
										.split('/')[0].replace(current.split("=")[0], "").replace("=", '').replace(' ', ''))) {
										if (regular.match(current)
											&& !reg.replace(current.ltrim(), '""').contains("File")
											&& !reg.replace(current.ltrim(), '""').contains("MathTools")
											&& !reg.replace(current.ltrim(), '""').contains("System")
											&& !reg.replace(current.ltrim(), '""').contains("ArrayTools")
											&& current.ltrim().contains("/")) {
											if (FileSystem.exists(Blue.directory
												+ "/"
												+ reg.replace(current.ltrim(), '""')
													.split('/')[0].replace(current.split("=")[0], "").replace("=", '').replace(' ', '') + ".bl")
												&& !closedLibs.contains(reg.replace(current.ltrim(), '""')
													.split('/')[0].replace(current.split("=")[0], "").replace("=", '').replace(' ', ''))) {
												if (!reg.replace(File.getContent(Blue.directory
													+ "/"
													+ reg.replace(current.ltrim(), '""')
														.split('/')[0].replace(current.split("=")[0], "").replace("=", '').replace(' ', '') + ".bl"),
													'""')
													.replace(" ", "")
													.contains("method" + whitespacesplit.split("/")[1].split("(")[0].replace(' ', "") + "(")) {
													Console.log("<b><light_white>"
														+ Blue.currentFile
														+ " - "
														+ "</><b><red>Error [BLE0049]:</></><light_white> Library does not contain method called at line "
														+ (linenum)
														+ "</>");
													gotErrors = true;
													Console.log("");
													Console.log("<b><red>" + current.ltrim().trim() + "</></>");
													var squigglyLines = "";
													for (i in 0...current.ltrim().trim().split('').length) {
														squigglyLines += "~";
													}
													Console.log("<red>" + squigglyLines + "</>");
												}
											} else {
												Console.log("<b><light_white>"
													+ Blue.currentFile
													+ " - "
													+ "</><b><red>Error [BLE0049]:</></><light_white> Unknown library at line "
													+ (linenum)
													+ "</>");
												gotErrors = true;
												Console.log("");
												Console.log("<b><red>" + current.ltrim().trim() + "</></>");
												var squigglyLines = "";
												for (i in 0...current.ltrim().trim().split('').length) {
													squigglyLines += "~";
												}
												Console.log("<red>" + squigglyLines + "</>");
											}
										}
									} else {
										Console.log("<b><light_white>"
											+ Blue.currentFile
											+ " - "
											+ "</><b><red>Error [BLE0049]:</></><light_white> Unknown library at line "
											+ (linenum)
											+ "</>");
										gotErrors = true;
										Console.log("");
										Console.log("<b><red>" + current.ltrim().trim() + "</></>");
										var squigglyLines = "";
										for (i in 0...current.ltrim().trim().split('').length) {
											squigglyLines += "~";
										}
										Console.log("<red>" + squigglyLines + "</>");
									}
								} else if (!whitespacesplit.replace(" ", "").split("(")[0].contains("/")) {
									if (new EReg("[A-Z+]" + '\\s+' + "\\(", "i").match(current)) {
										Console.log("<b><light_white>"
											+ Blue.currentFile
											+ " - "
											+ "</><b><red>Error [BLE0008]:</></><light_white> Unknown method at line "
											+ (j + 1));
										gotErrors = true;
										var arr = current.ltrim().trim().split("");
										arr.insert(reg.replace(current.ltrim().trim(), '""')
											.indexOf(whitespacesplit.split("(")[0].replace(" ", ""), firstIndex2),
											"<b><red>");
										arr.insert(reg.replace(current.ltrim().trim(), '""')
											.indexOf(whitespacesplit.split("(")[0].replace(" ", ""),
												firstIndex2) + whitespacesplit.split("(")[0].replace(" ", "").length
												+ 1,
											"</></>");
										Console.log(arr.join("") + ")");
										var squigglyLines = "";
										for (j in 0...reg.replace(current.ltrim().trim(), '""')
											.indexOf(whitespacesplit.split("(")[0].replace(" ", ""), firstIndex2)) {
											squigglyLines += " ";
										}
										for (j in 0...whitespacesplit.split("(")[0].replace(" ", "").length) {
											squigglyLines += "~";
										}
										firstIndex2 += 1;
										Console.log("<red>" + squigglyLines + "</>");
									}
									if (new EReg("[0-9+]" + '\\s+' + "\\(", "i").match(current)) {
										Console.log("<b><light_white>"
											+ Blue.currentFile
											+ " - "
											+ "</><b><red>Error [BLE0008]:</></><light_white> Unknown method at line "
											+ (j + 1));
										gotErrors = true;
										var arr = current.ltrim().trim().split("");
										arr.insert(reg.replace(current.ltrim().trim(), '""')
											.indexOf(whitespacesplit.split("(")[0].replace(" ", ""), firstIndex3),
											"<b><red>");
										arr.insert(reg.replace(current.ltrim().trim(), '""')
											.indexOf(whitespacesplit.split("(")[0].replace(" ", ""),
												firstIndex3) + whitespacesplit.split("(")[0].replace(" ", "").length
												+ 1,
											"</></>");
										Console.log(arr.join("") + ")");
										var squigglyLines = "";
										for (j in 0...reg.replace(current.ltrim().trim(), '""')
											.indexOf(whitespacesplit.split("(")[0].replace(" ", ""), firstIndex3)) {
											squigglyLines += " ";
										}
										for (j in 0...whitespacesplit.split("(")[0].replace(" ", "").length) {
											squigglyLines += "~";
										}
										firstIndex3 += 1;
										Console.log("<red>" + squigglyLines + "</>");
									}
									if (new EReg("[0-9+]" + "\\(", "i").match(current)) {
										Console.log("<b><light_white>"
											+ Blue.currentFile
											+ " - "
											+ "</><b><red>Error [BLE0011]:</></><light_white> Expected expression at line "
											+ (j + 1));
										gotErrors = true;
										Console.log("");
										Console.log("<b><red>" + current.ltrim().trim() + "</></>");
										var squigglyLines = "";
										for (i in 0...current.ltrim().trim().split('').length) {
											squigglyLines += "~";
										}
										Console.log("<red>" + squigglyLines + "</>");
									}
									if (!completeSyntax.contains(whitespacesplit)
										&& Math.isNaN(Std.parseFloat(whitespacesplit))
										&& whitespacesplit != currentSymbol
										&& !whitespacesplit.replace(" ", "").startsWith('[')
										&& whitespacesplit != ""
										&& whitespacesplit != " "
										&& whitespacesplit != 'and'
										&& whitespacesplit != 'outof'
										&& whitespacesplit != 'or'
										&& whitespacesplit != '>'
										&& whitespacesplit != '<'
										&& !whitespacesplit.contains('"')) {
										if (!completeSyntax.contains(whitespacesplit.split("(")[0].replace(" ", ""))
											&& Math.isNaN(Std.parseFloat(whitespacesplit.split("(")[0].replace(" ", "")))
											&& whitespacesplit.split("(")[0].replace(" ", "") != currentSymbol
											&& !whitespacesplit.split("(")[0].replace(" ", "").contains("/")
											&& whitespacesplit.split("(")[0].replace(" ", "") != ""
											&& whitespacesplit.split("(")[0].replace(" ", "") != " "
											&& whitespacesplit.split("(")[0].replace(" ", "") != 'and'
											&& whitespacesplit.split("(")[0].replace(" ", "") != 'outof'
											&& whitespacesplit.split("(")[0].replace(" ", "") != 'or'
											&& whitespacesplit.split("(")[0].replace(" ", "") != '>'
											&& whitespacesplit.split("(")[0].replace(" ", "") != '<'
											&& !whitespacesplit.split("(")[0].replace(" ", "").contains("return")
											&& !whitespacesplit.split("(")[1].split("/")[0].replace(" ", "").contains('"')) {
											if (!reg.replace(current, '"').ltrim().contains('/')
												&& !localMethods.contains(whitespacesplit.split("(")[0].replace(" ", "")
												.replace(whitespacesplit.replace(current.split("=")[0].replace(" ", ""), "").replace("=", ''), '')
												.replace(' ', ''))) {
												Console.log("<b><light_white>"
													+ Blue.currentFile
													+ " - "
													+ "</><b><red>Error [BLE0008]:</></><light_white> Unknown method at line "
													+ (linenum)
													+ "</>");
												gotErrors = true;
												var arr = current.ltrim().trim().split("");
												arr.insert(reg.replace(current.ltrim().trim(), '""')
													.indexOf(whitespacesplit.split("(")[0].replace(" ", ""), firstIndex4),
													"<b><red>");
												arr.insert(reg.replace(current.ltrim().trim(), '""')
													.indexOf(whitespacesplit.split("(")[0].replace(" ", ""),
														firstIndex4) + whitespacesplit.split("(")[0].replace(" ", "").length
														+ 1,
													"</></>");
												Console.log(arr.join("") + ")");
												var squigglyLines = "";
												for (j in 0...reg.replace(current.ltrim().trim(), '""')
													.indexOf(whitespacesplit.split("(")[0].replace(" ", ""), firstIndex4)) {
													squigglyLines += " ";
												}
												for (j in 0...whitespacesplit.split("(")[0].replace(" ", "").length) {
													squigglyLines += "~";
												}
												firstIndex4 += 1;
												Console.log("<red>" + squigglyLines + "</>");
											}
										}
										if (!completeSyntax.contains(whitespacesplit.split("(")[1].split("/")[0].replace(" ", ""))
											&& Math.isNaN(Std.parseFloat(whitespacesplit.split("(")[1].split("/")[0].replace(" ", "")))
											&& whitespacesplit.split("(")[1].split("/")[0].replace(" ", "") != currentSymbol
											&& !whitespacesplit.split("(")[1].split("/")[0].replace(" ", "").contains("/")
											&& whitespacesplit.split("(")[1].split("/")[0].replace(" ", "") != ""
											&& whitespacesplit.split("(")[1].split("/")[0].replace(" ", "") != " "
											&& whitespacesplit.split("(")[1].split("/")[0].replace(" ", "") != 'and'
											&& whitespacesplit.split("(")[1].split("/")[0].replace(" ", "") != 'outof'
											&& whitespacesplit.split("(")[1].split("/")[0].replace(" ", "") != 'or'
											&& whitespacesplit.split("(")[1].split("/")[0].replace(" ", "") != '>'
											&& whitespacesplit.split("(")[1].split("/")[0].replace(" ", "") != '<'
											&& !whitespacesplit.split("(")[1].split("/")[0].replace(" ", "").contains("return")
											&& whitespacesplit.split("(")[1].split("/")[0].replace(" ", "") != 'than'
											&& !whitespacesplit.split("(")[1].split("/")[0].replace(" ", "").contains('"')) {
											if (reg.replace(current, '"').ltrim().contains('/')
												&& !current.ltrim().split("(")[1].split(")")[0].contains("/")
												&& !localMethods.contains(whitespacesplit.split("(")[1].split("/")[0].replace(" ", ""))) {
												Console.log("<b><light_white>"
													+ Blue.currentFile
													+ " - "
													+ "</><b><red>Error [BLE0008]:</></><light_white> Unknown method at line "
													+ (linenum)
													+ "</>");
												gotErrors = true;
												var arr = current.ltrim().trim().split("");
												arr.insert(reg.replace(current.ltrim().trim(), '""')
													.indexOf(whitespacesplit.split("(")[1].split("/")[0].replace(" ", ""), firstIndex5),
													"<b><red>");
												arr.insert(reg.replace(current.ltrim().trim(), '""')
													.indexOf(whitespacesplit.split("(")[1].split("/")[0].replace(" ", ""),
														firstIndex5) + whitespacesplit.split("(")[1].split("/")[0].replace(" ", "").length
														+ 1,
													"</></>");
												Console.log(arr.join("") + ")");
												var squigglyLines = "";
												for (j in 0...reg.replace(current.ltrim().trim(), '""')
													.indexOf(whitespacesplit.split("(")[1].split("/")[0].replace(" ", ""), firstIndex5)) {
													squigglyLines += " ";
												}
												for (j in 0...whitespacesplit.split("(")[1].split("/")[0].replace(" ", "").length) {
													squigglyLines += "~";
												}
												firstIndex5 += 1;
												Console.log("<red>" + squigglyLines + "</>");
											}
										}
										for (i in 0...reg.replace(current.ltrim().trim(), '""').split(",").length) {
											if (reg.replace(current.ltrim().trim(), '""').split(",")[i].replace(" ", "").contains("!(")) {
												if (!reg.replace(current, '"').ltrim().contains(")\r")) {
													Console.log("<b><light_white>"
														+ Blue.currentFile
														+ " - "
														+ "</><b><red>Error [BLE0073]:</></><light_white> Macro used as an argument at line  "
														+ (linenum)
														+ "</>");
													gotErrors = true;
													Console.log("");
													Console.log("<b><red>" + current.ltrim().trim() + "</></>");
													var squigglyLines = "";
													for (i in 0...current.ltrim().trim().split('').length) {
														squigglyLines += "~";
													}
													Console.log("<red>" + squigglyLines + "</>");
												}
											}
											if (reg.replace(current.ltrim().trim(), '""').split(",")[i].replace(" ", "").startsWith("[")) {
												if (!reg.replace(current, '"').ltrim().contains(")\r")) {
													Console.log("<b><light_white>"
														+ Blue.currentFile
														+ " - "
														+ "</><b><red>Error [BLE0074]:</></><light_white> Whole array used as an argument at line  "
														+ (linenum)
														+ "</>");
													gotErrors = true;
													Console.log("");
													Console.log("<b><red>" + current.ltrim().trim() + "</></>");
													var squigglyLines = "";
													for (i in 0...current.ltrim().trim().split('').length) {
														squigglyLines += "~";
													}
													Console.log("<red>" + squigglyLines + "</>");
												}
											}
										}
										if (!completeSyntax.contains(whitespacesplit.split("(")[1].split(")")[0].replace(" ", ""))
											&& Math.isNaN(Std.parseFloat(whitespacesplit.split("(")[1].split(")")[0].replace(" ", "")))
											&& whitespacesplit.split("(")[1].split(")")[0].replace(" ", "") != currentSymbol
											&& !whitespacesplit.split("(")[1].split(")")[0].replace(" ", "").contains("/")
											&& whitespacesplit.split("(")[1].split(")")[0].replace(" ", "") != ""
											&& whitespacesplit.split("(")[1].split(")")[0].replace(" ", "") != " "
											&& whitespacesplit.split("(")[1].split(")")[0].replace(" ", "") != 'and'
											&& whitespacesplit.split("(")[1].split(")")[0].replace(" ", "") != 'outof'
											&& whitespacesplit.split("(")[1].split(")")[0].replace(" ", "") != 'or'
											&& whitespacesplit.split("(")[1].split(")")[0].replace(" ", "") != '>'
											&& whitespacesplit.split("(")[1].split(")")[0].replace(" ", "") != '<'
											&& whitespacesplit.split("(")[1].split(")")[0].replace(" ", "") != 'than'
											&& !whitespacesplit.split("(")[1].split(")")[0].replace(" ", "").contains('"')) {
											if (!reg.replace(current, '"').ltrim().contains(',')
												&& !localVars.contains(whitespacesplit.split("(")[1].split(")")[0].replace(" ", ""))
												&& !paramVars.contains(whitespacesplit.split("(")[1].split(")")[0].replace(" ", ""))) {
												Console.log("<b><light_white>"
													+ Blue.currentFile
													+ " - "
													+ "</><b><red>Error [BLE0017]:</></><light_white> Unknown variable at line "
													+ (linenum)
													+ "</>");
												gotErrors = true;
												var arr = current.ltrim().trim().split("");
												arr.insert(reg.replace(current.ltrim().trim(), '""')
													.indexOf(whitespacesplit.split("(")[1].split(")")[0].replace(" ", ""), firstIndex6),
													"<b><red>");
												arr.insert(reg.replace(current.ltrim().trim(), '""')
													.indexOf(whitespacesplit.split("(")[1].split(")")[0].replace(" ", ""),
														firstIndex6) + whitespacesplit.split("(")[1].split(")")[0].replace(" ", "").length
														+ 1,
													"</></>");
												Console.log(arr.join("") + ")");
												var squigglyLines = "";
												for (j in 0...reg.replace(current.ltrim().trim(), '""')
													.indexOf(whitespacesplit.split("(")[1].split(")")[0].replace(" ", ""), firstIndex6)) {
													squigglyLines += " ";
												}
												for (j in 0...whitespacesplit.split("(")[1].split(")")[0].replace(" ", "").length) {
													squigglyLines += "~";
												}
												firstIndex6 += 1;
												Console.log("<red>" + squigglyLines + "</>");
											} else if (reg.replace(current, '"').ltrim().contains(',')) {
												if (!completeSyntax.contains(whitespacesplit.split("(")[1].split(")")[0].split(',')[i].replace(" ", ""))
													&& Math.isNaN(Std.parseFloat(whitespacesplit.split("(")[1].split(")")[0].split(',')[i].replace(" ", "")))
													&& whitespacesplit.split("(")[1].split(")")[0].split(',')[i].replace(" ", "") != currentSymbol
													&& !whitespacesplit.split("(")[1].split(")")[0].split(',')[i].replace(" ", "").contains("/")
													&& whitespacesplit.split("(")[1].split(")")[0].split(',')[i].replace(" ", "") != ""
													&& whitespacesplit.split("(")[1].split(")")[0].split(',')[i].replace(" ", "") != " "
													&& whitespacesplit.split("(")[1].split(")")[0].split(',')[i].replace(" ", "") != 'and'
													&& whitespacesplit.split("(")[1].split(")")[0].split(',')[i].replace(" ", "") != 'outof'
													&& whitespacesplit.split("(")[1].split(")")[0].split(',')[i].replace(" ", "") != 'or'
													&& whitespacesplit.split("(")[1].split(")")[0].split(',')[i].replace(" ", "") != '>'
													&& whitespacesplit.split("(")[1].split(")")[0].split(',')[i].replace(" ", "") != '<'
													&& whitespacesplit.split("(")[1].split(")")[0].split(',')[i].replace(" ", "") != 'than'
													&& !whitespacesplit.split("(")[1].split(")")[0].split(',')[i].replace(" ", "").contains('"')) {
													for (i in 0...current.ltrim().split("(")[1].split(")")[0].split(',').length) {
														if (!localVars.contains(whitespacesplit.split("(")[1].split(")")[0].split(',')[i].replace(" ", ""))
															&& !paramVars.contains(whitespacesplit.split("(")[1].split(")")[0].split(',')[i].replace(" ",
																""))) {
															Console.log("<b><light_white>"
																+ Blue.currentFile
																+ " - "
																+ "</><b><red>Error [BLE0017]:</></><light_white> Unknown variable at line "
																+ (linenum)
																+ "</>");
															gotErrors = true;
															var arr = current.ltrim().trim().split("");
															arr.insert(reg.replace(current.ltrim().trim(), '""')
																.indexOf(whitespacesplit.split("(")[1].split(")")[0].split(',')[i].replace(" ", ""),
																	firstIndex7),
																"<b><red>");
															arr.insert(reg.replace(current.ltrim().trim(), '""')
																.indexOf(whitespacesplit.split("(")[1].split(")")[0].split(',')[i].replace(" ", ""),
																	firstIndex7) + whitespacesplit.split("(")[1].split(")")[0].split(',')[i].replace(" ", "")
																.length
																	+ 1,
																"</></>");
															Console.log(arr.join("") + ")");
															var squigglyLines = "";
															for (j in 0...reg.replace(current.ltrim().trim(), '""')
																.indexOf(whitespacesplit.split("(")[1].split(")")[0].split(',')[i].replace(" ", ""),
																	firstIndex7)) {
																squigglyLines += " ";
															}
															for (j in 0...whitespacesplit.split("(")[1].split(")")[0].split(',')[i].replace(" ", "").length) {
																squigglyLines += "~";
															}
															Console.log("<red>" + squigglyLines + "</>");
														}
													}
												}
											}
										}
									} else if (whitespacesplit.replace(" ", "").startsWith('[')) {
										Console.log("<b><light_white>"
											+ Blue.currentFile
											+ " - "
											+ "</><b><red>Error [BLE0011]:</></><light_white> Expected expression at line "
											+ (linenum)
											+ "</>");
										gotErrors = true;
										Console.log("");
										Console.log("<b><red>" + current.ltrim().trim() + "</></>");
										var squigglyLines = "";
										for (i in 0...current.ltrim().trim().split('').length) {
											squigglyLines += "~";
										}
										Console.log("<red>" + squigglyLines + "</>");
									}
									if (!reg.replace(current, '"').ltrim().contains(")\r")) {
										Console.log("<b><light_white>"
											+ Blue.currentFile
											+ " - "
											+ "</><b><red>Error [BLE0024]:</></><light_white> Method calls must be ended with a ')' and a newline at line "
											+ (linenum)
											+ "</>");
										gotErrors = true;
										Console.log("");
										Console.log("<b><red>" + current.ltrim().trim() + "</></>");
										var squigglyLines = "";
										for (i in 0...current.ltrim().trim().split('').length) {
											squigglyLines += "~";
										}
										Console.log("<red>" + squigglyLines + "</>");
									}
								}
							} else if (!isInMethod && !reg.replace(current, '""').contains("!(")) {
								Console.log("<b><light_white>"
									+ Blue.currentFile
									+ " - "
									+ "</><b><red>Error [BLE0025]:</></><light_white> Method call outside of method at line "
									+ (linenum)
									+ "</>");
								gotErrors = true;
								Console.log("");
								Console.log("<b><red>" + current.ltrim().trim() + "</></>");
								var squigglyLines = "";
								for (i in 0...current.ltrim().trim().split('').length) {
									squigglyLines += "~";
								}
								Console.log("<red>" + squigglyLines + "</>");
							}
							if ((!reg.replace(current, '""').ltrim().startsWith('method '))
								&& (!reg.replace(current, '""').ltrim().replace(" ", "").startsWith('new'))
								&& (!reg.replace(current, '""').ltrim().startsWith('loop '))
								&& (!reg.replace(current, '""').ltrim().replace(" ", "").startsWith('if'))
								&& (!reg.replace(current, '""').ltrim().startsWith('else if'))
								&& (!reg.replace(current, '""').ltrim().replace(" ", "").startsWith('print!('))
								&& (!reg.replace(current, '""').ltrim().replace(" ", "").startsWith('main('))
								&& (!reg.replace(current, '""').ltrim().replace(" ", "").startsWith('@'))
								&& (!reg.replace(current, '""').ltrim().replace(" ", "").contains('='))
								&& (!reg.replace(current, '""').ltrim().replace(" ", "").startsWith('super('))
								&& (!reg.replace(current, '""').ltrim().replace(" ", "").contains('targetInject!('))) {
								if (current.split("(")[0].replace(" ", "")
								.replace(current.split("=")[0], "")
								.replace("=", '')
								.contains("/") && (Blue.target == "c" || Blue.target == "cpp" || Blue.target == "go")) {
									var newCurrent = reg.replace(current, '""').replace(" ", "").split(")\r")[0];
									newCurrent = newCurrent.replace("ArrayTools/", "").replace("MathTools/", "").replace("System/", "").replace("File/", "");
									for (file in FileSystem.readDirectory(Blue.directory)) {
										var name = file.replace(".bl", "");
										if (newCurrent.contains(name) && !new EReg("[A-Z+]" + name, "i").match(newCurrent))
											newCurrent = newCurrent.replace(file.replace(".bl", "") + "/", "");
									}
									var arr = newCurrent.split("");
									for (i in 0...current.split('"').length) {
										if (newCurrent.split('"')[i].split('"')[0] == '' && current.split('"')[i].split('"')[0] != '') {
											for (j in 0...arr.length) {
												if (arr[j] == '"' && arr[j + 1] == '"') {
													arr.insert(j + 1, current.split('"')[i].split('"')[0]);
													break;
												}
											}
										}
									}
									currentToken = BToken.FunctionC(arr.join(""));
								} else {
									var newCurrent = reg.replace(current, '""').replace(" ", "").split(")\r")[0];
									newCurrent = newCurrent.replace("ArrayTools/", "ArrayTools.")
										.replace("MathTools/", "MathTools.")
										.replace("System/", "System.")
										.replace("File/", "File.");
									for (file in FileSystem.readDirectory(Blue.directory)) {
										var name = file.replace(".bl", "");
										if (newCurrent.contains(name) && !new EReg("[A-Z+]" + name, "i").match(newCurrent))
											newCurrent = newCurrent.replace(file.replace(".bl", "") + "/", file.replace(".bl", "") + ".");
									}
									var arr = newCurrent.split("");
									for (i in 0...current.split('"').length) {
										if (newCurrent.split('"')[i].split('"')[0] == '' && current.split('"')[i].split('"')[0] != '') {
											for (j in 0...arr.length) {
												if (arr[j] == '"' && arr[j + 1] == '"') {
													arr.insert(j + 1, current.split('"')[i].split('"')[0]);
													break;
												}
											}
										}
									}
									currentToken = BToken.FunctionC(arr.join(""));
								}
								if (reg.replace(current, '""').ltrim().replace(" ", "").contains("=")
									&& reg.replace(current, '""')
										.ltrim()
										.replace(" ", "")
										.replace(current.split("=")[0], "")
										.replace("=", '')
										.split("(")[0].replace(' ', "") != "") {
									if (!testLex) {
										tokensToParse.push(currentToken);
									}
								} else if (!reg.replace(current, '""').ltrim().replace(" ", "").contains("=")) {
									if (!testLex) {
										tokensToParse.push(currentToken);
									}
								}
							}
						case 'continue':
							if (isInMethod && reg.replace(current, '""').replace(" ", "").replace("\r", "") == "continue") {
								currentToken = BToken.Continue;
								if (!testLex) {
									tokensToParse.push(currentToken);
								}
							} else {
								Console.log("<b><light_white>"
									+ Blue.currentFile
									+ " - "
									+ "</><b><red>Error [BLE0011]:</></><light_white> Expected expression at line "
									+ (linenum)
									+ "</>");
								gotErrors = true;
								Console.log("");
								Console.log("<b><red>" + current.ltrim().trim() + "</></>");
								var squigglyLines = "";
								for (i in 0...current.ltrim().trim().split('').length) {
									squigglyLines += "~";
								}
								Console.log("<red>" + squigglyLines + "</>");
							}

						case 'break':
							if (isInMethod && reg.replace(current, '""').replace(" ", "").replace("\r", "") == "break") {
								currentToken = BToken.Stop;
								if (!testLex) {
									tokensToParse.push(currentToken);
								}
							} else {
								Console.log("<b><light_white>"
									+ Blue.currentFile
									+ " - "
									+ "</><b><red>Error [BLE0011]:</></><light_white> Expected expression at line "
									+ (linenum)
									+ "</>");
								gotErrors = true;
								Console.log("");
								Console.log("<b><red>" + current.ltrim().trim() + "</></>");
								var squigglyLines = "";
								for (i in 0...current.ltrim().trim().split('').length) {
									squigglyLines += "~";
								}
								Console.log("<red>" + squigglyLines + "</>");
							}

						case "open ":
							if (!isInMethod
								&& reg.replace(current, '""').replace(" ", "").contains("open")
								&& (new EReg("open\\s+" + "[A-Z+]", "i").match(reg.replace(current, '""'))
									|| new EReg("open\\s+" + "[0-9+]", "i").match(reg.replace(current, '""')))) {
								if (closedLibs.contains(current.split("open ")[1].split("\r")[0].replace(" ", "")))
									closedLibs.remove(current.split("open ")[1].split("\r")[0].replace(" ", ""));
								else {
									Console.log("<b><light_white>"
										+ Blue.currentFile
										+ " - "
										+ "</><b><red>Error [BLE0049]:</></><light_white> Unknown library at line "
										+ (linenum)
										+ "</>");
									gotErrors = true;
									Console.log("");
									Console.log("<b><red>" + current.ltrim().trim() + "</></>");
									var squigglyLines = "";
									for (i in 0...current.ltrim().trim().split('').length) {
										squigglyLines += "~";
									}
									Console.log("<red>" + squigglyLines + "</>");
								}
							} else {
								Console.log("<b><light_white>"
									+ Blue.currentFile
									+ " - "
									+ "</><b><red>Error [BLE0011]:</></><light_white> Expected expression at line "
									+ (linenum)
									+ "</>");
								gotErrors = true;
								Console.log("");
								Console.log("<b><red>" + current.ltrim().trim() + "</></>");
								var squigglyLines = "";
								for (i in 0...current.ltrim().trim().split('').length) {
									squigglyLines += "~";
								}
								Console.log("<red>" + squigglyLines + "</>");
							}

						case "close ":
							if (!isInMethod
								&& reg.replace(current, '""').replace(" ", "").contains("close")
								&& (new EReg("close\\s+" + "[A-Z+]", "i").match(reg.replace(current, '""'))
									|| new EReg("close\\s+" + "[0-9+]", "i").match(reg.replace(current, '""')))) {
								if (!closedLibs.contains(current.split("close ")[1].split("\r")[0].replace(" ", "")))
									closedLibs.push(current.split("close ")[1].split("\r")[0].replace(" ", ""));
							} else {
								Console.log("<b><light_white>"
									+ Blue.currentFile
									+ " - "
									+ "</><b><red>Error [BLE0011]:</></><light_white> Expected expression at line "
									+ (linenum)
									+ "</>");
								gotErrors = true;
								Console.log("");
								Console.log("<b><red>" + current.ltrim().trim() + "</></>");
								var squigglyLines = "";
								for (i in 0...current.ltrim().trim().split('').length) {
									squigglyLines += "~";
								}
								Console.log("<red>" + squigglyLines + "</>");
							}
						case 'targetInject!':
							if (reg.replace(current, '""').ltrim().startsWith("targetInject!")) {
								currentToken = BToken.CodeInjection(current.split('targetInject!("')[1].split('")\r')[0].replace("'", '"')
								.replace("\\n", "\n"));
								if (!testLex) {
									tokensToParse.push(currentToken);
								}
								if (!current.ltrim().replace(' ', "").contains('"')) {
									Console.log("<b><light_white>"
										+ Blue.currentFile
										+ " - "
										+
										"</><b><red>Error [BLE0023]:</></><light_white> Attempted to call 'targetInject' macro without using a whole string or char at line "
										+ (linenum)
										+ "</>");
									gotErrors = true;
									var arr = current.ltrim().trim().split("");
									arr.insert(reg.replace(current.ltrim().trim(), '""')
										.indexOf(current.ltrim().split('print!(')[1].split(")\r")[0].replace(" ", "")),
										"<b><red>");
									arr.insert(reg.replace(current.ltrim().trim(), '""')
										.indexOf(current.ltrim()
											.split('print!(')[1].split(")\r")[0].replace(" ", "")) + current.ltrim().split('print!(')[1].split(")\r")[0].length
											+ 1,
										"</></>");
									Console.log(arr.join(""));
									var squigglyLines = "";
									for (j in 0...reg.replace(current.ltrim().trim(), '""')
										.indexOf(current.ltrim().split('print!(')[1].split(")\r")[0].replace(" ", ""))) {
										squigglyLines += " ";
									}
									for (j in 0...current.ltrim().split('print!(')[1].split(")\r")[0].replace(" ", "").length) {
										squigglyLines += "~";
									}
									Console.log("<red>" + squigglyLines + "</>");
								}
								if (reg.replace(current.ltrim().split("\r")[0].replace(" ", ""), '""').contains(",")
									&& reg.replace(current.ltrim().split("\r")[0].replace(" ", ""), '""').contains("targetInject!")) {
									Console.log("<b><light_white>"
										+ Blue.currentFile
										+ " - "
										+ "</><b><red>Error [BLE0049]:</></><light_white> Too many parameters for macro: 'targetInject' at line "
										+ (linenum)
										+ "</>");
									gotErrors = true;
									Console.log("");
									Console.log("<b><red>" + current.ltrim().trim() + "</></>");
									var squigglyLines = "";
									for (i in 0...current.ltrim().trim().split('').length) {
										squigglyLines += "~";
									}
									Console.log("<red>" + squigglyLines + "</>");
								}
								if (reg.replace(current.ltrim().split("\r")[0].replace(" ", ""), '""').contains("targetInject!()")) {
									Console.log("<b><light_white>"
										+ Blue.currentFile
										+ " - "
										+ "</><b><red>Error [BLE0049]:</></><light_white> Not enough parameters for macro: 'targetInject' at line "
										+ (linenum)
										+ "</>");
									gotErrors = true;
									Console.log("");
									Console.log("<b><red>" + current.ltrim().trim() + "</></>");
									var squigglyLines = "";
									for (i in 0...current.ltrim().trim().split('').length) {
										squigglyLines += "~";
									}
									Console.log("<red>" + squigglyLines + "</>");
								}
							} else {
								Console.log("<b><light_white>"
									+ Blue.currentFile
									+ " - "
									+ "</><b><red>Error [BLE0011]:</></><light_white> Expected expression at line "
									+ (linenum)
									+ "</>");
								gotErrors = true;
								Console.log("");
								Console.log("<b><red>" + current.ltrim().trim() + "</></>");
								var squigglyLines = "";
								for (i in 0...current.ltrim().trim().split('').length) {
									squigglyLines += "~";
								}
								Console.log("<red>" + squigglyLines + "</>");
							}
					}
				} else {
					var notFound = true;
					for (j in 0...completeSyntax.length) {
						if (reg.replace(current.ltrim(), '""').contains(completeSyntax[j])) {
							notFound = false;
						}
						if (j == completeSyntax.length - 1 && notFound) {
							if (reg.replace(current.ltrim(), '""').replace(" ", "") != "" && notFound) {
								Console.log("<b><light_white>"
									+ Blue.currentFile
									+ " - "
									+ "</><b><red>Error [BLE0011]:</></><light_white> Expected expression at line "
									+ (linenum)
									+ "</>");
								gotErrors = true;
								Console.log("");
								Console.log("<b><red>" + current.ltrim().trim() + "</></>");
								var squigglyLines = "";
								for (i in 0...current.ltrim().trim().split('').length) {
									squigglyLines += "~";
								}
								Console.log("<red>" + squigglyLines + "</>");
								Sys.exit(1);
							}
						}
					}
				}
			}
		}
		if (tokensToParse != null && !gotErrors && !testLex) {
			for (i in 0...tokensToParse.length) {
				if (i == tokensToParse.length - 1) {
					buildIR(tokensToParse[i], true);
				} else {
					buildIR(tokensToParse[i], false);
				}
			}
		}
		tokensToParse = [];
		BLexer.content = contentToEnum;
		BCoffeeScriptUtil.coffeeScriptData = ["class", "main()"];
		BCPPUtil.cppData = [
			"#include <cstddef>",
			"#include <cstdio>",
			"#include <iostream>",
			"#include <sstream>",
			"#include <string>",
			"#include <array>",
			"#include <vector>",
			"#include <variant>",
			"using namespace std;\n"
		];
		if (Blue.currentFile == "Main.bl") {
			BGoUtil.goData = ['import "fmt"'];
		} else {
			BGoUtil.goData = ['import "fmt"'];
		}
		BGroovyUtil.groovyData = ["", "", "class", "{"];
		BHaxeUtil.haxeData = ["", "", "class", "{"];
		BJSUtil.jsData = ["", "main();"];
		return gotErrors;
	}

	public static function buildIR(input:BToken, collectGarbage:Bool = false) {
		parsing.BParser.parse(input, collectGarbage);
	}
}
