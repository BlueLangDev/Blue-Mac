package languageutils.go;

#if sys
import sys.FileSystem;
#end

using StringTools;

class BGoUtil {
	public static var goData:Array<String> = ['import "fmt"'];
	static var specificValues:Array<Dynamic> = [];
	static var oldValues:Array<Dynamic> = [];
	static public var extension:Dynamic = null;
	public static var fileName:String = null;

	public static function toGo(AST:Dynamic) {
		var parsedAST = haxe.Json.parse(AST);
		if (parsedAST.label == "Variable") {
			var reg = ~/"([^"]*?)"/g;
			if (Std.string(parsedAST.value).replace(" ", "").startsWith("[")) {
				if (Std.string(parsedAST.value).contains(",")) {
					var reg = ~/"([^"]*?)"/g;
					var formattedValue = reg.replace(Std.string(parsedAST.value), '""');
					if (reg.replace(Std.string(parsedAST.value), '""').contains(",")) {
						for (i in 0...reg.replace(Std.string(parsedAST.value), '""').split(",").length) {
							var str = reg.replace(Std.string(parsedAST.value), '""').split(",")[i];
							var strArr = Std.string(str).replace(" ", "").split("");
							var startIndex = Std.string(str).indexOf('"');
							var endIndex = Std.string(str).indexOf('"', Std.string(str).indexOf('"') + 1);
							for (i in 0...strArr.length) {
								var strElement = strArr[i];
								if (strElement == "]" && (i >= endIndex || i <= startIndex)) {
									strArr[i] = "}";
								}
								if (strElement == "[" && (i >= endIndex || i <= startIndex)) {
									strArr[i] = "[]dynamic{";
								}
							}
							str = strArr.join("");
							formattedValue = formattedValue.replace(formattedValue.split(",")[i], str);
						}
						var arr = formattedValue.split('');
						for (i in 0...formattedValue.split('"').length) {
							if (formattedValue.split('"')[i].split('"')[0] == ''
								&& Std.string(parsedAST.value).split('"')[i].split('"')[0] != '') {
								for (j in 0...arr.length) {
									if (arr[j] == '"' && arr[j + 1] == '"') {
										arr.insert(j + 1, Std.string(parsedAST.value).split('"')[i].split('"')[0]);
										break;
									}
								}
							}
						}
						formattedValue = arr.join('');
						parsedAST.value = formattedValue;
					}
				} else {
					for (i in 0...Std.string(parsedAST.value).split(" ").length) {
						var str = Std.string(parsedAST.value).split(" ")[i].split(" ")[0];
						var strArr = Std.string(str).replace(" ", "").split("");
						var startIndex = Std.string(str).indexOf('"');
						var endIndex = Std.string(str).indexOf('"', Std.string(str).indexOf('"') + 1);
						for (i in 0...strArr.length) {
							var strElement = strArr[i];
							if (strElement == "]" && (i >= endIndex || i <= startIndex)) {
								strArr[i] = "}";
							}
							if (strElement == "[" && (i >= endIndex || i <= startIndex)) {
								strArr[i] = "[]dynamic{";
							}
						}
						str = strArr.join("");
						parsedAST.value = Std.string(parsedAST.value).replace(Std.string(parsedAST.value).split(" ")[i], str);
					}
				}
			}
			if (!Std.string(parsedAST.name).contains("[")
				&& (!goData.join('\n').contains(parsedAST.name + " = ") && !Std.string(parsedAST.name).contains("/"))
				|| (goData.join('\n').contains(~/[A-Z0-9]/ + parsedAST.name)
					|| goData.join('\n').contains(parsedAST.name + ~/[A-Z0-9]/))) {
				var arr = Std.string(parsedAST.value).split("");
				arr.reverse();
				arr.remove(";");
				arr.reverse();
				parsedAST.value = arr.join("");
				if (!Std.string(parsedAST.value).replace(' ', '').replace("", "").startsWith("[]dynamic{")) {
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
				goData.push(('var' + " " + Std.string(parsedAST.name).replace("|", ":").replace("\n", "") + ' = ' + Std.string(parsedAST.value)));
			} else if (goData.join('\n').contains(parsedAST.name + " = ")
				&& !goData.join('\n').contains(~/[A-Z0-9]/ + parsedAST.name)
				&& !goData.join('\n').contains(parsedAST.name + ~/[A-Z0-9]/)
				|| Std.string(parsedAST.name).contains("/")
				|| Std.string(parsedAST.name).contains("[")) {
				if (Std.string(parsedAST.name).contains("[") && Std.string(parsedAST.name).contains("]")) {
					for (i in 1...Std.string(parsedAST.name).split("[").length) {
						parsedAST.value = reg.replace(Std.string(parsedAST.value), '""')
							.replace(reg.replace(Std.string(parsedAST.value), '""').split("[")[i].split("]")[0],
								reg.replace(Std.string(parsedAST.value), '""').split("[")[i].split("]")[0] + " - 1");
					}
				}
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
				var arr = Std.string(parsedAST.value).split("");
				arr.reverse();
				arr.remove(";");
				arr.reverse();
				parsedAST.value = arr.join("");
				goData.push(Std.string(parsedAST.name).replace("public var", "") + '=' + Std.string(parsedAST.value));
			}
		}

		if (parsedAST.label == "Method") {
			if (!goData.join("\n").contains("func")) {
				if (parsedAST.args[0] == null) {
					goData.push('func ${parsedAST.name}() dynamic {\nfmt.Print("")');
				} else {
					var args = [];
					if (parsedAST.args[0] != null && parsedAST.args[0].length > 0) {
						for (i in 0...parsedAST.args[0].length) {
							args.push(parsedAST.args[0][i]);
						}
					}
					goData.push(('func ${parsedAST.name}(${args.join(" dynamic, ") + " dynamic"}) dynamic {\nfmt.Print("")').replace("( dynamic)", "()"));
				}
			} else {
				if (parsedAST.args[0] == null) {
					goData.push('func ${parsedAST.name}() dynamic {\n');
				} else {
					var args = [];
					if (parsedAST.args[0] != null && parsedAST.args[0].length > 0) {
						for (i in 0...parsedAST.args[0].length) {
							args.push(parsedAST.args[0][i]);
						}
					}
					goData.push(('func ${parsedAST.name}(${args.join(" dynamic, ") + " dynamic"}) dynamic {\n').replace("( dynamic)", "()"));
				}
			}
		}
		if (parsedAST.label == "End") {
			goData.push('}');
		}
		if (parsedAST.label == "Continue") {
			goData.push('continue');
		}
		if (parsedAST.label == "Stop") {
			goData.push('break');
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
			goData.push('if ($condition) {');
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
			goData.push('} else if ($condition) {');
		}
		if (parsedAST.label == "For") {
			goData.push(('for ${parsedAST.iterator} := ${parsedAST.numberOne}; ${parsedAST.iterator} < ${parsedAST.numberTwo}; ${parsedAST.iterator}++ {')
				.replace("\n", "")
				.replace("\r", ""));
		}
		if (parsedAST.label == "Return") {
			goData.push('return ${Std.string(parsedAST.value)}');
		}
		if (parsedAST.label == "Main") {
			if (parsedAST.args[0] == null) {
				goData.push('func main()\nfmt.Print("") {');
			} else {
				var args = [];
				if (parsedAST.args[0] != null && parsedAST.args[0].length > 0) {
					for (i in 0...parsedAST.args[0].length) {
						args.push(parsedAST.args[0][i]);
					}
				}
				goData.push(('func main(${args.join(" dynamic, ") + " dynamic"}) {').replace("( dynamic)", "()") + '\nfmt.Print("")');
			}
		}
		if (parsedAST.label == "Else") {
			goData.push('} else {');
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
			goData.push('$formattedValue)');
		}
		if (parsedAST.label == "New") {
			if (parsedAST.args[0] == null) {
				goData.push('constructor();');
			} else {
				var args = [];
				if (parsedAST.args[0] != null && parsedAST.args[0].length > 0) {
					for (i in 0...parsedAST.args[0].length) {
						args.push("dynamic? " + parsedAST.args[0][i]);
					}
				}
				goData.push(('constructor(${parsedAST.value}(${args.join(", ")});'));
			}
		}

		if (parsedAST.label == "Constructor") {
			if (parsedAST.args[0] == null) {
				goData.push('public constructor() {');
			} else {
				var args = [];
				if (parsedAST.args[0] != null && parsedAST.args[0].length > 0) {
					for (i in 0...parsedAST.args[0].length) {
						args.push("dynamic? " + parsedAST.args[i]);
					}
				}
				goData.push(('public constructor(${args.join(", ")}) {'));
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
			goData.push('fmt.Print(${Std.string(parsedAST.value)})');
			goData.push('fmt.Print("\\n")');
		}
		if (parsedAST.label == "CodeInjection") {
			goData.push('${Std.string(parsedAST.value)}');
		}
		if (parsedAST.label == "Class") {
			if (parsedAST.value == null) {
				goData.push('type ${Std.string(parsedAST.name)} struct {');
			} else {
				goData.push('type ${Std.string(parsedAST.name)} struct {');
			}
		}
	}

	static public function buildGoFile() {
		FileSystem.createDirectory("export/gosrc");
		sys.io.File.write('export/gosrc/${fileName.replace(".bl", ".go")}', false);
		sys.io.File.saveContent('export/gosrc/${fileName.replace(".bl", ".go")}', goData.join('\n').replace('\n{\n}', "\n{"));
	}
}
