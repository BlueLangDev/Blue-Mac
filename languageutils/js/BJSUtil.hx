package languageutils.js;

#if sys
import sys.FileSystem;
#end

using StringTools;

class BJSUtil {
	public static var jsData:Array<String> = ["", "main();"];
	static var specificValues:Array<Dynamic> = [];
	static var oldValues:Array<Dynamic> = [];
	static public var extension:Dynamic = null;
	public static var fileName:String = null;

	public static function toJs(AST:Dynamic) {
		var parsedAST = haxe.Json.parse(AST);
		if (parsedAST.label == "Variable") {
			var reg = ~/"([^"]*?)"/g;
			if (!Std.string(parsedAST.name).contains("[")
				&& (!jsData.join('\n').contains(parsedAST.name + " = ") && !Std.string(parsedAST.name).contains("/"))
				|| (jsData.join('\n').contains(~/[A-Z0-9]/ + parsedAST.name)
					|| jsData.join('\n').contains(parsedAST.name + ~/[A-Z0-9]/))) {
				jsData.push(('var' + " " + Std.string(parsedAST.name).replace("\n", "") + ' = ' + parsedAST.value));
			} else if (jsData.join('\n').contains(parsedAST.name + " = ")
				&& !jsData.join('\n').contains(~/[A-Z0-9]/ + parsedAST.name)
				&& !jsData.join('\n').contains(parsedAST.name + ~/[A-Z0-9]/)
				|| Std.string(parsedAST.name).contains("/")
				|| Std.string(parsedAST.name).contains("[")) {
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

					jsData.push(Std.string(parsedAST.name).replace("public var", "") + '=' + parsedAST.value);
				}
			}
		}
		if (parsedAST.label == "Method") {
			if (parsedAST.args[0] == null) {
				jsData.push('function ${parsedAST.name}() {');
			} else {
				jsData.push(('function ${parsedAST.name}(${parsedAST.args[0].join(", ")}) {\n').replace("()", "()"));
			}
		}
		if (parsedAST.label == "Throw") {
			jsData.push('throw ${parsedAST.value};');
		}
		if (parsedAST.label == "End") {
			jsData.push('}');
		}
		if (parsedAST.label == "Try") {
			jsData.push('try {');
		}
		if (parsedAST.label == "Catch") {
			jsData.push('} catch(${parsedAST.value}) {');
		}
		if (parsedAST.label == "Continue") {
			jsData.push('continue;');
		}
		if (parsedAST.label == "Stop") {
			jsData.push('break;');
		}
		if (parsedAST.label == "If") {
			var reg = ~/"([^"]*?)"/g;
			var condition = reg.replace(Std.string(parsedAST.condition), '""');
			for (i in 1...condition.split("[").length) {
				var splitted = condition.split("[")[i].split("]")[0];
				if (!splitted.contains("-1"))
					splitted = splitted + "-1";
				condition = condition.replace(condition.split("[")[i].split("]")[0], splitted);
			}
			var arr = condition.split('');
			for (i in 0...condition.split('"').length) {
				if (condition.split('"')[i].split('"')[0] == '' && Std.string(parsedAST.condition).split('"')[i].split('"')[0] != '') {
					for (j in 0...arr.length) {
						if (arr[j] == '"' && arr[j + 1] == '"') {
							arr.insert(j + 1, Std.string(parsedAST.condition).split('"')[i].split('"')[0]);
							break;
						}
					}
				}
			}
			condition = arr.join('');
			jsData.push('if ($condition) {');
		}
		if (parsedAST.label == "Otherwise If") {
			var reg = ~/"([^"]*?)"/g;
			var condition = reg.replace(Std.string(parsedAST.condition), '""');
			for (i in 1...condition.split("[").length) {
				var splitted = condition.split("[")[i].split("]")[0];
				if (!splitted.contains("-1"))
					splitted = splitted + "-1";
				condition = condition.replace(condition.split("[")[i].split("]")[0], splitted);
			}
			var arr = condition.split('');
			for (i in 0...condition.split('"').length) {
				if (condition.split('"')[i].split('"')[0] == '' && Std.string(parsedAST.condition).split('"')[i].split('"')[0] != '') {
					for (j in 0...arr.length) {
						if (arr[j] == '"' && arr[j + 1] == '"') {
							arr.insert(j + 1, Std.string(parsedAST.condition).split('"')[i].split('"')[0]);
							break;
						}
					}
				}
			}
			condition = arr.join('');
			jsData.push('} else if ($condition) {');
		}
		if (parsedAST.label == "For") {
			jsData.push(('for (${parsedAST.iterator} = ${parsedAST.numberOne}; ${parsedAST.iterator} < ${parsedAST.numberTwo}; ${parsedAST.iterator}++) {')
				.replace("\n", "")
				.replace("\r", ""));
		}
		if (parsedAST.label == "Return") {
			jsData.push('return ${parsedAST.value}');
		}
		if (parsedAST.label == "Else") {
			jsData.push('} else {');
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
			jsData.push('$formattedValue);');
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
			jsData.push('console.log(${parsedAST.value});');
		}
		if (parsedAST.label == "CodeInjection") {
			jsData.push('${parsedAST.value}');
		}
		if (parsedAST.label == "Class") {
			if (parsedAST.value == null) {
				jsData.push('var ${Std.string(parsedAST.name)} = {');
			} else {
				jsData.push('var ${Std.string(parsedAST.name)} = {');
			}
		}
		if (parsedAST.label == "Main") {
			jsData.push('function main() {');
		}
	}

	static public function buildJsFile() {
		FileSystem.createDirectory("export/jssrc");
		sys.io.File.write('export/jssrc/${fileName.replace(".bl", ".js")}', false);
		sys.io.File.saveContent('export/jssrc/${fileName.replace(".bl", ".js")}', jsData.join('\n').replace('\n{\n}', "\n{"));
	}
}
