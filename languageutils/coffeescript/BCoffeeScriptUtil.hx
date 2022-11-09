package languageutils.coffeescript;

#if sys
import sys.io.File;
import sys.FileSystem;
#end
import lexing.BLexer.BToken;

using StringTools;

class BCoffeeScriptUtil {
	public static var coffeeScriptData:Array<String> = ["class", "main()"];
	static var specificValues:Array<Dynamic> = [];
	static var oldValues:Array<Dynamic> = [];
	static public var extension:Dynamic = null;
	public static var fileName:String = null;

	public static function toCoffeeScript(AST:Dynamic) {
		for (i in 0...coffeeScriptData.length) {
			if (coffeeScriptData[i] == "class") {
				coffeeScriptData[i] = 'class ${fileName.replace(".bl", '')}';
				if (extension != null) {
					coffeeScriptData[i] = coffeeScriptData[i] + " extends " + extension;
				}
				break;
			}
		}
		var parsedAST = haxe.Json.parse(AST);
		if (parsedAST.label == "Variable") {
			var reg = ~/"([^"]*?)"/g;
			if (!Std.string(parsedAST.name).contains("[")
				&& (!coffeeScriptData.join('\n').contains(parsedAST.name + " = ") && !Std.string(parsedAST.name).contains("/"))
				|| (coffeeScriptData.join('\n').contains(~/[A-Z0-9]/ + parsedAST.name)
					|| coffeeScriptData.join('\n').contains(parsedAST.name + ~/[A-Z0-9]/))) {
				if (!Std.string(parsedAST.value).replace(' ', '').replace("", "").startsWith("[")) {
					if (Std.string(parsedAST.value).split("[")[0].replace(' ', '') != ""
						&& Std.string(parsedAST.value).split("[")[0].replace(' ', '') != " "
						&& !Std.string(parsedAST.value).contains('"')) {
						for (i in 1...Std.string(parsedAST.value).split("[").length) {
							parsedAST.value = Std.string(parsedAST.value)
								.replace(reg.replace(Std.string(parsedAST.value), '""').split("[")[i].split("]")[0],
									reg.replace(Std.string(parsedAST.value), '""').split("[")[i].split("]")[0] + " - 1");
						}
					}
				}
				coffeeScriptData.push(Std.string(parsedAST.name).replace("\n", "") + ' = ' + Std.string(parsedAST.value));
			} else if (coffeeScriptData.join('\n').contains(parsedAST.name + " = ")
				&& !coffeeScriptData.join('\n').contains(~/[A-Z0-9]/ + parsedAST.name)
				&& !coffeeScriptData.join('\n').contains(parsedAST.name + ~/[A-Z0-9]/)
				|| Std.string(parsedAST.name).contains("/")
				|| Std.string(parsedAST.name).contains("[")) {
				if (Std.string(parsedAST.value).split("[")[0].replace(' ', '') != ""
					&& Std.string(parsedAST.value).split("[")[0].replace(' ', '') != " "
					&& !Std.string(parsedAST.value).contains('"')) {
					for (i in 1...Std.string(parsedAST.value).split("[").length) {
						parsedAST.value = Std.string(parsedAST.value)
							.replace(reg.replace(Std.string(parsedAST.value), '""').split("[")[i].split("]")[0],
								reg.replace(Std.string(parsedAST.value), '""').split("[")[i].split("]")[0] + " - 1");
					}
					for (i in 1...Std.string(parsedAST.name).split("[").length) {
						parsedAST.value = Std.string(parsedAST.value)
							.replace(reg.replace(Std.string(parsedAST.name), '""').split("[")[i].split("]")[0],
								reg.replace(Std.string(parsedAST.name), '""').split("[")[i].split("]")[0] + " - 1");
					}
				}
				coffeeScriptData.push(Std.string(parsedAST.name).replace("public var", "") + '=' + Std.string(Std.string(parsedAST.value)));
			}
		}

		if (parsedAST.label == "Method" || parsedAST.label == "ClassMethod") {
			if (parsedAST.args[0] == null) {
				coffeeScriptData.push('${parsedAST.name}: () ->');
			} else {
				coffeeScriptData.push(('${parsedAST.name}: (${parsedAST.args[0].join(", ")}) ->').replace("()", "()"));
			}
		}
		if (parsedAST.label == "Throw") {
			coffeeScriptData.push('throw ${Std.string(parsedAST.value)}');
		}
		if (parsedAST.label == "Try") {
			coffeeScriptData.push('try');
		}
		if (parsedAST.label == "Catch") {
			coffeeScriptData.push('catch(${Std.string(parsedAST.value)})');
		}
		if (parsedAST.label == "If") {
			coffeeScriptData.push('if ${Std.string(parsedAST.condition)}');
		}
		if (parsedAST.label == "Otherwise If") {
			coffeeScriptData.push('else if ${Std.string(parsedAST.condition)}');
		}
		if (parsedAST.label == "Continue") {
			coffeeScriptData.push('continue');
		}
		if (parsedAST.label == "Stop") {
			coffeeScriptData.push('break');
		}
		if (parsedAST.label == "For") {
			coffeeScriptData.push(('${parsedAST.iterator} for ${parsedAST.iterator} in [${parsedAST.numberOne}...${parsedAST.numberTwo}]').replace("\n", "")
				.replace("\r", ""));
		}
		if (parsedAST.label == "Return") {
			coffeeScriptData.push('return ${Std.string(parsedAST.value)}');
		}
		if (parsedAST.label == "Comment") {
			coffeeScriptData.push('// ${Std.string(parsedAST.value)}');
		}
		if (parsedAST.label == "Main") {
			if (parsedAST.args[0] == null) {
				coffeeScriptData.push('main: () ->');
			} else {
				coffeeScriptData.push(('main: (${parsedAST.args[0].join(", ")}) ->').replace("()", "()"));
			}
		}
		if (parsedAST.label == "New") {
			if (parsedAST.args[0] == null) {
				coffeeScriptData.push('new ${Std.string(parsedAST.value)}');
			} else {
				coffeeScriptData.push(('new ${Std.string(parsedAST.value)}(${parsedAST.args[0].join(", ")})').replace("()", "()"));
			}
		}
		if (parsedAST.label == "Constructor") {
			if (parsedAST.args[0] == null) {
				coffeeScriptData.push('constructor: () -> ');
			} else {
				coffeeScriptData.push(('constructor: (${parsedAST.args[0].join(", ")}) ->').replace("()", "()"));
			}
		}
		if (parsedAST.label == "Else") {
			coffeeScriptData.push('else');
		}
		if (parsedAST.label == "FunctionCall") {
			var args = "";
			var reg = ~/"([^"]*?)"/g;
			var formattedValue = reg.replace(Std.string(parsedAST.value), '""');
			for (i in 0...reg.replace(Std.string(parsedAST.value), '""').split(",").length) {
				if (!reg.replace(Std.string(parsedAST.value), '""').split(",")[i].split(',')[0].replace(" ", "").contains('"')) {
					for (j in 1...reg.replace(Std.string(parsedAST.value), '""').split("[").length) {
						if (!Math.isNaN(Std.parseFloat(reg.replace(Std.string(parsedAST.value), '""')))) {
							if (!Math.isNaN(Std.parseFloat(reg.replace(Std.string(parsedAST.value), '""')
								.split(",")[i].split(',')[0].split("[")[j].split("]")[0].replace(" ", "")))
								&& reg.replace(Std.string(parsedAST.value), '""')
									.split(",")[i].split(',')[0].split("[")[j].split("]")[0].replace(" ", "") != "0") {
								parsedAST.value = reg.replace(Std.string(parsedAST.value), '""')
									.replace(reg.replace(Std.string(parsedAST.value), '""').split(",")[i].split(',')[0].split("[")[j].split("]")[0],
										(Std.string(Std.parseInt(reg.replace(Std.string(parsedAST.value), '""')
											.split(",")[i].split(',')[0].split("[")[j].split("]")[0])
											- 1)));
							}
						} else {
							parsedAST.value = reg.replace(Std.string(parsedAST.value), '""')
								.replace(reg.replace(Std.string(parsedAST.value), '""').split("[")[j].split("]")[0],
									reg.replace(Std.string(parsedAST.value), '""').split("[")[j].split("]")[0] + " - 1");
						}
					}
				}
				var arr = reg.replace(Std.string(parsedAST.value), '""').split(",")[i].replace(" ", "").split("");
				if (i < reg.replace(Std.string(parsedAST.value), '""').split(",").length - 1) {
					args = args + arr.join("") + ",";
				} else {
					args = args + arr.join("");
				}
			}
			formattedValue = args;
			var arr = formattedValue.split('');
			for (i in 0...formattedValue.split('"').length) {
				if (formattedValue.split('"')[i].split('"')[0] == '' && Std.string(parsedAST.value).split('"')[i].split('"')[0] != '') {
					for (j in 0...arr.length) {
						if (arr[j] == '"' && arr[j + 1] == '"') {
							arr.insert(j + 1, Std.string(parsedAST.value).split('"')[i].split('"')[0]);
							break;
						}
					}
				}
			}

			formattedValue = arr.join('');
			coffeeScriptData.push('$formattedValue)');
		}

		if (parsedAST.label == "Super") {
			if (parsedAST.args[0] == null) {
				coffeeScriptData.push('super');
			} else {
				coffeeScriptData.push(('super(${parsedAST.args[0].join(", ")})').replace("()", "()"));
			}
		}

		if (parsedAST.label == "Print") {
			if (!Std.string(parsedAST.value).contains('"')) {
				for (i in 0...Std.string(parsedAST.value).split("[").length) {
					if (new EReg("[0-9+]", "").match(Std.string(parsedAST.value).split("[")[i].split("]")[0].replace(' ', ''))
						&& Std.string(parsedAST.value).split("[")[i].split("]")[0].replace(' ', '') != "0") {
						parsedAST.value = Std.string(parsedAST.value)
							.replace(Std.string(parsedAST.value).split("[")[i].split("]")[0],
								(Std.string(Std.parseInt(Std.string(parsedAST.value).split("[")[i].split("]")[0]) - 1)));
					}
				}
			}
			coffeeScriptData.push('console.log ${parsedAST.value}');
		}
		if (parsedAST.label == "Class") {
			if (parsedAST.value == null) {
				coffeeScriptData.push('${Std.string(parsedAST.name)} =');
			} else {
				coffeeScriptData.push('${Std.string(parsedAST.name)} =');
			}
		}
		if (parsedAST.label == "CodeInjection") {
			coffeeScriptData.push('${parsedAST.value}');
		}
	}

	static public function buildCoffeeScriptFile() {
		FileSystem.createDirectory("export/coffeescriptsrc");
		sys.io.File.write('export/coffeescriptsrc/${fileName.replace(".bl", ".coffee")}', false);
		sys.io.File.saveContent('export/coffeescriptsrc/${fileName.replace(".bl", ".coffee")}', coffeeScriptData.join('\n').replace('\n{\n}', "\n{"));
	}
}
