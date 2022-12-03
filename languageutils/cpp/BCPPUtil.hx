package languageutils.cpp;

#if sys
import sys.io.File;
import sys.FileSystem;
#end
import lexing.BLexer.BToken;

using StringTools;

class BCPPUtil {
	private static var variablesToFree:Array<String> = [""];
	private static var arraysToInsert:Array<String> = [];
	public static var cppData:Array<String> = [
		"#include <cstddef>",
		"#include <cstdio>",
		"#include <iostream>",
		"#include <sstream>",
		"#include <string>",
		"#include <array>",
		"#include <variant>",
		"using namespace std;\n"
	];
	private static var iteratorQueue:Array<String> = [];
	static var specificValues:Array<Dynamic> = [];
	static var oldValues:Array<Dynamic> = [];
	static public var extension:Dynamic = null;
	public static var fileName:String = null;
	private static var iteratorVars:Map<String, String> = [];

	public static function toCPP(AST:Dynamic) {
		var parsedAST = haxe.Json.parse(AST);
		if (parsedAST.label == "Variable" || parsedAST.label == "MethodVariable") {
			if (Std.string(parsedAST.value).replace(" ", "").startsWith("[")) {
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
							if (strElement == "[" && (i >= endIndex || i <= startIndex)) {
								strArr[i] = "{";
							}
							if (strElement == "]" && (i >= endIndex || i <= startIndex)) {
								strArr[i] = "}";
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
				} else {
					for (i in 0...Std.string(parsedAST.value).split(" ").length) {
						var str = Std.string(parsedAST.value).split(" ")[i].split(" ")[0];
						var strArr = Std.string(str).replace(" ", "").split("");
						var startIndex = Std.string(str).indexOf('"');
						var endIndex = Std.string(str).indexOf('"', Std.string(str).indexOf('"') + 1);
						for (i in 0...strArr.length) {
							var strElement = strArr[i];
							if (strElement == "[" && (i >= endIndex || i <= startIndex)) {
								strArr[i] = "{";
							}
							if (strElement == "]" && (i >= endIndex || i <= startIndex)) {
								strArr[i] = "}";
							}
						}
						str = strArr.join("");
						parsedAST.value = Std.string(parsedAST.value).replace(Std.string(parsedAST.value).split(" ")[i], str);
					}
				}
			}
			var reg = ~/"([^"]*?)"/g;
			for (i in 0...Std.string(parsedAST.value).split("[").length) {
				if (reg.replace(cppData.join("\n"), '""').contains("for (int " + Std.string(parsedAST.value).split("[")[i].split("]")[0] + " = 0;")) {
					iteratorQueue.push(Std.string(parsedAST.value).split("[")[i].split("]")[0]);
					iteratorVars.set(Std.string(parsedAST.name), Std.string(parsedAST.value).replace(" ", ""));
				}
			}
			if (!Std.string(parsedAST.name).contains("[")
				&& (!cppData.join('\n').contains(parsedAST.name + " = ") && !Std.string(parsedAST.name).contains("."))
				|| (cppData.join('\n').contains(~/[A-Z0-9]/ + parsedAST.name)
					|| cppData.join('\n').contains(parsedAST.name + ~/[A-Z0-9]/))) {
				if (!Std.string(parsedAST.value).replace(' ', '').replace("", "").startsWith("(")) {
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
				if (Std.string(parsedAST.value).replace(' ', '').replace("", "").startsWith("{")
					&& !Std.string(parsedAST.value).replace(' ', '').replace("", "").startsWith("contains")) {
					cppData.push(('vector<std::variant<int, string, bool, double, float, const char *>> '
						+ Std.string(parsedAST.name).replace("\n", "")
						+ ' = '
						+ Std.string(parsedAST.value)));
				} else {
					if (parsedAST.label != "ClassVariable")
						cppData.push(('auto ' + " " + Std.string(parsedAST.name).replace("\n", "") + ' = ' + Std.string(parsedAST.value)));
					else
						cppData.push(('auto' + " " + Std.string(parsedAST.name).replace("\n", "") + ' = ' + Std.string(parsedAST.value)));
				}
			} else if (cppData.join('\n').contains(parsedAST.name + " = ")
				&& !cppData.join('\n').contains(~/[A-Z0-9]/ + parsedAST.name)
				&& !cppData.join('\n').contains(parsedAST.name + ~/[A-Z0-9]/)
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
				if (Std.string(parsedAST.value).replace(' ', '').replace("", "").startsWith("(")
					&& !Std.string(parsedAST.value).replace(' ', '').replace("", "").startsWith("contains")) {
					cppData.push((Std.string(parsedAST.name).replace("\n", "") + ' = unszd_raw_array' + Std.string(parsedAST.value)));
				} else
					cppData.push(Std.string(parsedAST.name).replace("public var", "") + ' = ' + Std.string(parsedAST.value));
			}
		}

		if (parsedAST.label == "Method" || parsedAST.label == "ClassMethod") {
			if (parsedAST.args[0] == null) {
				cppData.push('auto ${parsedAST.name}() {');
			} else {
				var args = [];
				if (parsedAST.args[0] != null && parsedAST.args[0].length > 0) {
					for (i in 0...parsedAST.args[0].length) {
						args.push("auto " + parsedAST.args[0][i]);
					}
				}
				cppData.push(('auto ${parsedAST.name}(${args.join(", ")}) {').replace("(auto )", "()"));
			}
		}
		if (parsedAST.label == "Throw") {
			cppData.push('throw ${Std.string(parsedAST.value)};');
		}
		if (parsedAST.label == "End") {
			cppData.push('}');
		}
		if (parsedAST.label == "ClassEnd") {
			cppData.push('};');
		}
		if (parsedAST.label == "Try") {
			cppData.push('try {');
		}
		if (parsedAST.label == "Catch") {
			cppData.push('} catch(${Std.string(parsedAST.value)}) {');
		}
		if (parsedAST.label == "Continue") {
			cppData.push('continue;');
		}
		if (parsedAST.label == "Stop") {
			cppData.push('break;');
		}
		if (parsedAST.label == "If") {
			cppData.push('if (${Std.string(parsedAST.condition)}) {');
		}
		if (parsedAST.label == "Otherwise If") {
			cppData.push('} else if (${Std.string(parsedAST.condition)}) {');
		}
		if (parsedAST.label == "For") {
			cppData.push(('for (int ${parsedAST.iterator} = ${parsedAST.numberOne}; ${parsedAST.iterator} < ${parsedAST.numberTwo}; ${parsedAST.iterator}++) {')
				.replace("\n", "")
				.replace("\r", ""));
		}
		if (parsedAST.label == "Return") {
			cppData.push('return ${Std.string(parsedAST.value)}');
		}
		if (parsedAST.label == "Comment") {
			cppData.push('// ${Std.string(parsedAST.value)}');
		}
		if (parsedAST.label == "Main") {
			if (parsedAST.args == null) {
				cppData.push('int main() {');
			} else {
				var args = [];
				if (parsedAST.args[0] != null && parsedAST.args[0].length > 0) {
					for (i in 0...parsedAST.args[0].length) {
						args.push("auto " + parsedAST.args[0][i]);
					}
				}
				cppData.push(('int main(${args.join(", ")}) {').replace("(auto )", "()"));
			}
		}
		if (parsedAST.label == "Else") {
			cppData.push('} else {');
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
			cppData.push('$formattedValue);');
		}
		if (parsedAST.label == "Print") {
			cppData.push('cout << ${Std.string(parsedAST.value)} << ' + 'endl;');
		}
		if (parsedAST.label == "CodeInjection") {
			cppData.push('${Std.string(parsedAST.value)}');
		}
	}

	static public function buildCPPFile() {
		FileSystem.createDirectory("export/cppsrc");
		sys.io.File.write('export/cppsrc/${fileName.replace(".bl", ".cpp")}', false);
		sys.io.File.saveContent('export/cppsrc/${fileName.replace(".bl", ".cpp")}', cppData.join('\n').replace('\n{\n}', "\n{"));
	}
}
