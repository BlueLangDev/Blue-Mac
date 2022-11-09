package languageutils.haxe;

#if sys
import sys.io.File;
import sys.FileSystem;
#end
import lexing.BLexer.BToken;

using StringTools;

class BHaxeUtil {
	public static var haxeData:Array<String> = ["", "", "class", "{"];
	static var specificValues:Array<Dynamic> = [];
	static var oldValues:Array<Dynamic> = [];
	static public var extension:Dynamic = null;
	public static var fileName:String = null;

	public static function toHaxe(AST:Dynamic) {
		for (i in 0...haxeData.length) {
			if (haxeData[i] == "class") {
				haxeData[i] = 'class ${fileName.replace(".bl", '')}';
				if (extension != null) {
					haxeData[i] = haxeData[i] + " extends  " + extension;
				}
				break;
			}
		}
		var parsedAST = haxe.Json.parse(AST);
		if (parsedAST.label == "Variable" || parsedAST.label == "MethodVariable") {
			var reg = ~/"([^"]*?)"/g;
			if (!Std.string(parsedAST.name).contains("[")
				&& (!haxeData.join('\n').contains(parsedAST.name + " =   "))
				|| (haxeData.join('\n').contains(~/[A-Z0-9]/i + parsedAST.name)
					|| haxeData.join('\n').contains(parsedAST.name + ~/[A-Z0-9]/i))) {
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
				if (!Std.string(parsedAST.name).contains("/")) {
					if (parsedAST.label == "MethodVariable")
						haxeData.push(('var' + " " + Std.string(parsedAST.name).replace("\n", "") + ':Dynamic = ' + parsedAST.value));
					else
						haxeData.push(('public static var' + " " + Std.string(parsedAST.name).replace("\n", "") + ':Dynamic = ' + parsedAST.value));
				} else {
					haxeData.push((Std.string(parsedAST.name).replace("\n", "") + ' = ' + parsedAST.value));
				}
			} else if (haxeData.join('\n').contains(parsedAST.name + " = ")
				&& !haxeData.join('\n').contains(~/[A-Z0-9]/i + parsedAST.name)
				&& !haxeData.join('\n').contains(parsedAST.name + ~/[A-Z0-9]/i)
				|| Std.string(parsedAST.name).contains("[")) {
				if (Std.string(parsedAST.name).contains("[") && Std.string(parsedAST.name).contains("]")) {
					for (i in 0...Std.string(parsedAST.name).split("[").length) {
						if (!Math.isNaN(Std.parseFloat(Std.string(parsedAST.value).split("[")[i].split("]")[0]))) {
							if (new EReg("[0-9+]", "").match(Std.string(parsedAST.name).split("[")[i].split("]")[0].replace(' ', ''))
								&& Std.string(parsedAST.name).split("[")[i].split("]")[0].replace(' ', '') != "0") {
								parsedAST.name = Std.string(parsedAST.name)
									.replace(Std.string(parsedAST.name).split("[")[i].split("]")[0],
										(Std.string(Std.parseInt(Std.string(parsedAST.name).split("[")[i].split("]")[0]) - 1)));
							}
						} else {
							parsedAST.value = reg.replace(Std.string(parsedAST.value), '""')
								.replace(reg.replace(Std.string(parsedAST.value), '""').split("[")[i].split("]")[0],
									reg.replace(Std.string(parsedAST.value), '""').split("[")[i].split("]")[0] + " - 1");
						}
					}
				}
				if (Std.string(parsedAST.value).split("[")[0].replace(' ', '') != ""
					&& Std.string(parsedAST.value).split("[")[0].replace(' ', '') != " "
					&& !Std.string(parsedAST.value).contains('"')) {
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
				}
				haxeData.push(Std.string(parsedAST.name).replace("public static var", "") + ' =' + parsedAST.value);
			}
		}

		if (parsedAST.label == "Method") {
			if (parsedAST.args[0] == null) {
				haxeData.push('public static function ${parsedAST.name}():Dynamic {');
			} else {
				haxeData.push(('public static function ${parsedAST.name}(${parsedAST.args[0].join(":Dynamic, ") + ":Dynamic"}):Dynamic {\n')
					.replace("(:Dynamic)", "()"));
			}
		}
		if (parsedAST.label == "Throw") {
			haxeData.push('throw(${parsedAST.value});');
		}
		if (parsedAST.label == "End") {
			haxeData.push('}');
		}
		if (parsedAST.label == "Try") {
			haxeData.push('try {');
		}
		if (parsedAST.label == "Catch") {
			haxeData.push('} catch(${parsedAST.value}) {');
		}
		if (parsedAST.label == "Continue") {
			haxeData.push('continue;');
		}
		if (parsedAST.label == "Stop") {
			haxeData.push('break;');
		}
		if (parsedAST.label == "If") {
			haxeData.push('if (${Std.string(parsedAST.condition)}) {');
		}
		if (parsedAST.label == "Otherwise If") {
			haxeData.push('} else if (${Std.string(parsedAST.condition)}) {');
		}
		if (parsedAST.label == "For") {
			haxeData.push(('for (${parsedAST.iterator} in ${parsedAST.numberOne}...${parsedAST.numberTwo}) {').replace("\n", "").replace("\r", ""));
		}
		if (parsedAST.label == "Return") {
			haxeData.push('return ${parsedAST.value}');
		}
		if (parsedAST.label == "Comment") {
			haxeData.push('// ${parsedAST.value}');
		}
		if (parsedAST.label == "Main") {
			haxeData.push('public static function main() {');
		}
		if (parsedAST.label == "New") {
			if (parsedAST.args[0] == null) {
				haxeData.push('new ${parsedAST.value}();');
			} else {
				haxeData.push(('new ${parsedAST.value}(${parsedAST.args[0].join(", ")});').replace("(:Dynamic)", "()"));
			}
		}
		if (parsedAST.label == "Constructor") {
			if (parsedAST.args[0] == null) {
				haxeData.push('public function new() {');
			} else {
				haxeData.push(('public function new(${parsedAST.args[0].join(":Dynamic, ") + ":Dynamic"}) {').replace("(:Dynamic)", "()"));
			}
		}
		if (parsedAST.label == "Else") {
			haxeData.push('} else {');
		}
		if (parsedAST.label == "FunctionCall") {
			var args = "";
			var reg = ~/"([^"]*?)"/g;
			var formattedValue = reg.replace(Std.string(parsedAST.value), '""');
			for (i in 0...reg.replace(Std.string(parsedAST.value), '""').split(",").length) {
				if (!reg.replace(Std.string(parsedAST.value), '""').split(",")[i].split(',')[0].replace(" ", "").contains('"')) {
					for (i in 1...Std.string(parsedAST.name).split("[").length) {
						parsedAST.value = reg.replace(Std.string(parsedAST.value), '""')
							.replace(reg.replace(Std.string(parsedAST.value), '""').split("[")[i].split("]")[0],
								reg.replace(Std.string(parsedAST.value), '""').split("[")[i].split("]")[0] + " - 1");
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
			haxeData.push('$formattedValue);');
		}

		if (parsedAST.label == "Super") {
			if (parsedAST.args[0] == null) {
				haxeData.push('super();');
			} else {
				haxeData.push(('super(${parsedAST.args[0].join(", ")});').replace("(:Dynamic)", "()"));
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
			haxeData.push('Sys.println(${parsedAST.value});');
		}
		if (parsedAST.label == "CodeInjection") {
			haxeData.push('${parsedAST.value}');
		}
		if (parsedAST.label == "Class") {
			if (parsedAST.value == null) {
				haxeData.push('public static var ${Std.string(parsedAST.name)} = {');
			} else {
				haxeData.push('public static var ${Std.string(parsedAST.name)} = {');
			}
		}
	}

	static public function buildHaxeFile() {
		FileSystem.createDirectory("export/hxsrc");
		sys.io.File.write('export/hxsrc/${fileName.replace(".bl", ".hx")}', false);
		sys.io.File.saveContent('export/hxsrc/${fileName.replace(".bl", ".hx")}', haxeData.join('\n').replace('\n{\n}', "\n{") + '\n}');
	}
}
