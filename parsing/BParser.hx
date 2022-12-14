package parsing;

import languageutils.js.BJSUtil;
import languageutils.go.BGoUtil;
import languageutils.cpp.BCPPUtil;
import languageutils.haxe.BHaxeUtil;
import languageutils.groovy.BGroovyUtil;
import lexing.BLexer.BToken;

typedef ASTStruct = {
	var token:BToken;
	var iterator:Dynamic;
	var numberOne:String;
	var numberTwo:String;
	var valueOne:Dynamic;
	var valueTwo:Dynamic;
	var condition:Dynamic;
	var name:String;
	var args:Array<Dynamic>;
	var value:Dynamic;
	var a:Dynamic;
	var b:Dynamic;
	var entries:Array<Dynamic>;
	var label:String;
	var stringValue:String;
	var type:String;
}

class BParser {
	static var token:BToken;
	static var iterator:Dynamic;
	static var numberOne:String;
	static var numberTwo:String;
	static var valueOne:Dynamic;
	static var valueTwo:Dynamic;
	static var condition:Dynamic;
	static var name:String;
	static var args:Array<Dynamic>;
	static var value:Dynamic;
	static var a:Dynamic;
	static var b:Dynamic;
	static var entries:Array<Dynamic>;
	static var label:String;
	static var stringValue:String;
	static var type:String;

	public static function parse(input:Dynamic, startCollecting:Bool = false) {
		token = null;
		iterator = null;
		numberTwo = null;
		numberOne = null;
		valueOne = null;
		valueTwo = null;
		condition = null;
		name = null;
		args = null;
		type = null;
		value = null;
		a = null;
		b = null;
		entries = null;
		label = null;
		stringValue = null;

		switch (input) {
			case BToken.Variable(name, value, type):
				BParser.name = name;
				BParser.value = value;
				BParser.label = "Variable";

			case BToken.MethodVariable(name, value, type):
				BParser.name = name;
				BParser.value = value;
				BParser.label = "MethodVariable";

			case BToken.Method(name, args):
				BParser.name = name;
				BParser.args = args;
				BParser.label = "Method";

			case BToken.IfStatement(condition):
				BParser.condition = condition;
				BParser.label = "If";

			case BToken.OtherwiseIf(condition):
				BParser.condition = condition;
				BParser.label = "Otherwise If";

			case BToken.ForStatement(iterator, numberOne, numberTwo):
				BParser.iterator = iterator;
				BParser.numberOne = numberOne;
				BParser.numberTwo = numberTwo;
				BParser.label = "For";

			case BToken.Array(entries):
				BParser.entries = entries;
				BParser.label = "Array";

			case BToken.Divide(a, b):
				BParser.a = a;
				BParser.b = b;
				BParser.label = "Div";

			case BToken.Multiply(a, b):
				BParser.a = a;
				BParser.b = b;
				BParser.label = "Mult";

			case BToken.End:
				BParser.label = "End";

			case BToken.Stop:
				BParser.label = "Stop";

			case BToken.Continue:
				BParser.label = "Continue";

			case BToken.Use(value):
				BParser.value = value;
				BParser.label = "Use";

			case BToken.Try:
				BParser.label = "Try";

			case BToken.Catch(value):
				BParser.value = value;
				BParser.label = "Catch";

			case BToken.Print(stringToPrint):
				BParser.value = stringToPrint;
				BParser.label = "Print";

			case BToken.Return(value):
				BParser.value = value;
				BParser.label = "Return";

			case BToken.MainMethod(args):
				BParser.args = args;
				BParser.label = "Main";

			case BToken.Throw(value):
				BParser.value = value;
				BParser.label = "Throw";

			case BToken.New(value, args):
				BParser.value = value;
				BParser.args = args;
				BParser.label = "New";

			case BToken.Else:
				BParser.label = "Else";

			case BToken.FunctionC(value):
				BParser.value = value;
				BParser.label = "FunctionCall";

			case BToken.Property(a, b):
				BParser.a = a;
				BParser.b = b;
				BParser.label = "Property";

			case BToken.Super(args):
				BParser.args = args;
				BParser.label = "Super";

			case BToken.CodeInjection(value):
				BParser.value = value;
				BParser.label = "CodeInjection";

			default:
				return;
		}
		var astStructure:ASTStruct = {
			token: input,
			iterator: iterator,
			numberOne: numberOne,
			numberTwo: numberTwo,
			valueOne: valueOne,
			valueTwo: valueTwo,
			condition: condition,
			value: value,
			args: args,
			name: name,
			entries: entries,
			a: a,
			b: b,
			label: label,
			type: type,
			stringValue: Std.string(value)
		};

		var serializedResult = haxe.Json.stringify(astStructure);

		switch (blue.Blue.target) {
			case "cpp":
				BCPPUtil.toCPP(serializedResult);
				BCPPUtil.buildCPPFile();
			case "go":
				BGoUtil.toGo(serializedResult);
				BGoUtil.buildGoFile();
			case "groovy":
				BGroovyUtil.toGroovy(serializedResult);
				BGroovyUtil.buildGroovyFile();
			case "haxe":
				BHaxeUtil.toHaxe(serializedResult);
				BHaxeUtil.buildHaxeFile();
			case "javascript":
				BJSUtil.toJs(serializedResult);
				BJSUtil.buildJsFile();
		}

		token = null;
		type = null;
		iterator = null;
		numberTwo = null;
		numberOne = null;
		valueOne = null;
		valueTwo = null;
		condition = null;
		name = null;
		args = null;
		value = null;
		a = null;
		b = null;
		entries = null;
		label = null;
		stringValue = null;
	}
}
