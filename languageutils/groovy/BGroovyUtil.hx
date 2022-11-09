package languageutils.groovy;

#if sys
import sys.FileSystem;
#end

using StringTools;

class BGroovyUtil {
	public static var groovyData:Array<String> = ["", "", "class", "{"];
	static var specificValues:Array<Dynamic> = [];
	static var oldValues:Array<Dynamic> = [];
	static public var extension:Dynamic = null;
	public static var fileName:String = null;

	static var lastClass:String = "";

	public static function toGroovy(AST:Dynamic) {
		for (i in 0...groovyData.length) {
			if (groovyData[i] == "class") {
				groovyData[i] = 'class ${fileName.replace(".bl", '')}';
				break;
			}
		}
		var parsedAST = haxe.Json.parse(AST);
		if (parsedAST.label == "Variable") {
			var reg = ~/"([^"]*?)"/g;
			if (!Std.string(parsedAST.name).contains("[")
				&& (!groovyData.join('\n').contains(parsedAST.name + " = ") && !Std.string(parsedAST.name).contains("/"))
				|| (groovyData.join('\n').contains(~/[A-Z0-9]/ + parsedAST.name)
					|| groovyData.join('\n').contains(parsedAST.name + ~/[A-Z0-9]/))) {
				groovyData.push(('def' + " " + Std.string(parsedAST.name).replace("\n", "") + ' = ' + parsedAST.value));
			} else if (groovyData.join('\n').contains(parsedAST.name + " = ")
				&& !groovyData.join('\n').contains(~/[A-Z0-9]/ + parsedAST.name)
				&& !groovyData.join('\n').contains(parsedAST.name + ~/[A-Z0-9]/)
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
				}
				groovyData.push(Std.string(parsedAST.name).replace("public var", "") + '=' + parsedAST.value);
			}
		}

		if (parsedAST.label == "Method") {
			if (parsedAST.args[0] == null) {
				groovyData.push('def ${parsedAST.name}() {');
			} else {
				groovyData.push(('def ${parsedAST.name}(${parsedAST.args[0].join(", ")}) {\n').replace("()", "()"));
			}
		}
		if (parsedAST.label == "Throw") {
			groovyData.push('throw(${parsedAST.value})');
		}
		if (parsedAST.label == "End") {
			groovyData.push('}');
		}
		if (parsedAST.label == "Try") {
			groovyData.push('} try {');
		}
		if (parsedAST.label == "Catch") {
			groovyData.push('catch(${parsedAST.value}) {');
		}
		if (parsedAST.label == "Continue") {
			groovyData.push('continue');
		}
		if (parsedAST.label == "Stop") {
			groovyData.push('break');
		}
		if (parsedAST.label == "If") {
			groovyData.push('if (${Std.string(parsedAST.condition)}) {');
		}
		if (parsedAST.label == "Otherwise If") {
			groovyData.push('} else if (${Std.string(parsedAST.condition)}) {');
		}
		if (parsedAST.label == "For") {
			groovyData.push(('for (${parsedAST.iterator} = ${parsedAST.numberOne}; ${parsedAST.iterator} < ${parsedAST.numberTwo}; ${parsedAST.iterator}++) {')
				.replace("\n", "")
				.replace("\r", ""));
		}
		if (parsedAST.label == "Return") {
			groovyData.push('return ${parsedAST.value}');
		}
		if (parsedAST.label == "Main") {
			if (parsedAST.args[0] == null) {
				groovyData.push('static def main() {');
			} else {
				var args = [];
				if (parsedAST.args[0] != null && parsedAST.args[0].length > 0) {
					for (i in 0...parsedAST.args[0].length) {
						args.push(parsedAST.args[0][i]);
					}
				}
				groovyData.push(('static def main(${args.join(", ")}) {').replace("()", "()"));
			}
		}
		if (parsedAST.label == "New") {
			if (parsedAST.args[0] == null) {
				groovyData.push('new ${parsedAST.value}()');
			} else {
				groovyData.push(('new ${parsedAST.value}(${parsedAST.args[0].join(", ")})').replace("()", "()"));
			}
		}
		if (parsedAST.label == "Constructor") {
			if (parsedAST.args[0] == null) {
				groovyData.push('public $lastClass() {');
			} else {
				var args = [];
				if (parsedAST.args[0] != null && parsedAST.args[0].length > 0) {
					for (i in 0...parsedAST.args[0].length) {
						args.push(parsedAST.args[0][i]);
					}
				}
				groovyData.push(('public $lastClass(${args.join(", ")}) {').replace("()", "()"));
			}
		}
		if (parsedAST.label == "Else") {
			groovyData.push('} else {');
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
			groovyData.push('$formattedValue)');
		}

		if (parsedAST.label == "Super") {
			if (parsedAST.args[0] == null) {
				groovyData.push('super()');
			} else {
				groovyData.push(('super(${parsedAST.args[0].join(", ")})').replace("()", "()"));
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
			groovyData.push('print ${parsedAST.value}');
		}
		if (parsedAST.label == "CodeInjection") {
			groovyData.push('${parsedAST.value}');
		}
		if (parsedAST.label == "Class") {
			lastClass = Std.string(parsedAST.name);
			if (parsedAST.value == null) {
				groovyData.push('class ${Std.string(parsedAST.name)} {');
			} else {
				groovyData.push('class ${Std.string(parsedAST.name)} extends ${Std.string(parsedAST.value)} {');
			}
		}
	}

	static public function buildGroovyFile() {
		FileSystem.createDirectory("export/groovysrc");
		sys.io.File.write('export/groovysrc/${fileName.replace(".bl", ".groovy")}', false);
		sys.io.File.saveContent('export/groovysrc/${fileName.replace(".bl", ".groovy")}', groovyData.join('\n').replace('\n{\n}', "\n{") + "\n}");
	}
}
