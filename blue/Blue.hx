package blue;

import languageutils.js.BJSUtil;
import languageutils.go.BGoUtil;
import languageutils.cpp.BCPPUtil;
import languageutils.coffeescript.BCoffeeScriptUtil;
import languageutils.haxe.BHaxeUtil;
import languageutils.groovy.BGroovyUtil;
#if sys
import sys.FileSystem;
import sys.io.File;
#end

using StringTools;

class Blue {
	public static var target:String = "Haxe";
	public static var supportedTargets:Array<String> = ["cpp", "coffeescript", "go", "groovy", "haxe", "javascript"];

	public static var targetUtilityClass:Dynamic = BHaxeUtil;

	private static var currentMappedFiles:Array<String> = [];
	private static var currentMappedLines:Array<Array<String>> = [];
	private static var fileNumber:Int = 0;
	public static var directory:String = "";

	static var mainFile = "Main";
	static var libs = [];

	static var gotErrors:Bool = false;

	public static var currentFile:String = "";

	public static var currentFile_Noerr:String = "";

	static var buildCommand:String = "";

	static var completeSyntax:Array<String> = [
		"method ", "loop ", "if ", "+", "-", "mult", "div", "end", "else", "stop", "continue", "then", "not", "=", "use", "try", "catch", "print!", "return",
		"***", "main(", "throw", "or", "[", "/", "(", "else if ", "<<", ">>", "null", "break", "continue", "open ", "close ", "targetInject!"
	];

	public static function main() {
		Console.logPrefix = "";
		if (!FileSystem.exists("project_config.json")) {
			File.saveContent("project_config.json", projectConfig);
		}
		if (!FileSystem.exists("target_scripts")) {
			FileSystem.createDirectory("target_scripts");
		}
		if (!FileSystem.exists("target_libraries")) {
			FileSystem.createDirectory("target_libraries");
		}
		if (Sys.args()[1] != null) {
			var target = Sys.args()[1];
			if (supportedTargets.contains(target)) {
				Blue.target = target;
			} else {
				Console.log('<b><red>Error:</></> <light_white>$target is not a supported target,'
					+ " type: 'blue targetlist' to see a list of supported targets </>");
				Sys.exit(1);
			}
		}
		if (Sys.args()[0] != null) {
			var folder = Sys.args()[0];
			if (folder == "targetlist") {
				Console.log("<light_white>Supported targets as of Blue 22: " + supportedTargets.join(", ") + "</>");
			} else if (FileSystem.exists(folder) && FileSystem.isDirectory(folder)) {
				mapSource(folder);
			} else {
				Console.log("<b><red>Error:</></> <light_white>" + folder + " either does not exist or is not a directory </>");
				Sys.exit(1);
			}
		} else {
			Console.log("<b><red>Usage:</></> <light_white>blue 'source-folder-name' 'target'</>");
			Sys.exit(1);
		}
	}

	static var projectConfig:String = '
	{
		"build_commands":{
		   "c":{
			  "command":"gcc -w -o export/bin/Main export/csrc/Main.c"
		   },
		   "coffeescript":{
			  "command":"coffee --compile export/coffeescriptsrc/."
		   },
		   "cpp":{
			  "command":"g++ -w -o export/bin/Main export/cppsrc/Main.cpp -std=c++20"
		   },
		   "go":{
			  "command":"go build -o bin/Main.exe"
		   },
		   "groovy":{
			  "command":"groovyc export/groovysrc/Main.groovy"
		   },
		   "haxe":{
			  "command":"haxe -cp src --main'
		+ "'export.hxsrc.Main'"
		+ '--cpp export/bin"
		   }
		}
    } ';

	public static function mapSource(directory:String) {
		Blue.directory = directory;
		var files = [];
		if (FileSystem.exists(directory) && FileSystem.isDirectory(directory)) {
			for (file in FileSystem.readDirectory(directory)) {
				if (!FileSystem.isDirectory(file) && file.endsWith(".bl")) {
					currentFile = file;
					if ((checkForSyntaxErrors(File.getContent(directory + "/" + file))
						&& lexing.BLexer.enumContent(File.getContent(directory + "/" + file), true))
						|| (!checkForSyntaxErrors(File.getContent(directory + "/" + file))
							&& lexing.BLexer.enumContent(File.getContent(directory + "/" + file), true))
						|| (checkForSyntaxErrors(File.getContent(directory + "/" + file))
							&& !lexing.BLexer.enumContent(File.getContent(directory + "/" + file), true))) {
						gotErrors = true;
						break;
						Sys.exit(1);
					} else {
						files.push(file);
					}
				}
			}
			for (file in FileSystem.readDirectory(directory)) {
				if (!FileSystem.isDirectory(file) && file.endsWith(".bl")) {
					currentFile_Noerr = file;
					fileNumber += 1;
					if (!gotErrors) {
						if (!checkForSyntaxErrors(File.getContent(directory + "/" + file), true)
							&& !lexing.BLexer.enumContent(File.getContent(directory + "/" + file), true)) {
							var rawContent = File.getContent(directory + "/" + file);
							mapFile(directory + "/" + file);
							switch (target) {
								case "coffeescript":
									if (fileNumber == 1) {
										if (FileSystem.exists("export/coffeescriptsrc")) {
											for (file in FileSystem.readDirectory("export/coffeescriptsrc")) {
												FileSystem.deleteFile("export/coffeescriptsrc/" + file);
											}
										}
									}
									BCoffeeScriptUtil.fileName = file;
									lexSourceFile(rawContent);
									if (FileSystem.exists(Sys.programPath()
										.replace("Blue\\Blue", "Blue\\")
										.replace("Blue/Blue", "Blue/")
										.replace(".exe", "") + "stdlib/coffeescript")) {
										for (file in FileSystem.readDirectory(Sys.programPath()
											.replace("Blue\\Blue", "Blue\\")
											.replace("Blue/Blue", "Blue/")
											.replace(".exe", "") + "stdlib/coffeescript")) {
											File.copy(Sys.programPath()
												.replace("Blue\\Blue", "Blue\\")
												.replace("Blue/Blue", "Blue/")
												.replace(".exe", "") + "stdlib/coffeescript/"
												+ file,
												'export/coffeescriptsrc/$file');
										}
									}
								case "cpp":
									if (fileNumber == 1) {
										if (FileSystem.exists("export/cppsrc")) {
											for (file in FileSystem.readDirectory("export/cppsrc")) {
												FileSystem.deleteFile("export/cppsrc/" + file);
											}
										}
									}
									BCPPUtil.fileName = file;
									for (includeFile in FileSystem.readDirectory(directory)) {
										if (includeFile.endsWith(".bl")) {
											if (includeFile != file) {
												BCPPUtil.cppData.insert(0, '#include ' + '"${includeFile.replace(".bl", ".cpp")}"' + '');
											}
										}
									}
									BCPPUtil.cppData.insert(0, '#include ' + '"System.cpp"' + '');
									BCPPUtil.cppData.insert(0, '#include ' + '"File.cpp"' + '');
									BCPPUtil.cppData.insert(0, '#include ' + '"MathTools.cpp"' + '');
									BCPPUtil.cppData.insert(0, '#include ' + '"ArrayTools.cpp"' + '');
									BCPPUtil.cppData.insert(0, '#pragma once');
									lexSourceFile(rawContent);
									if (FileSystem.exists(Sys.programPath()
										.replace("Blue\\Blue", "Blue\\")
										.replace("Blue/Blue", "Blue/")
										.replace(".exe", "") + "stdlib/cpp")) {
										for (file in FileSystem.readDirectory(Sys.programPath()
											.replace("Blue\\Blue", "Blue\\")
											.replace("Blue/Blue", "Blue/")
											.replace(".exe", "") + "stdlib/cpp")) {
											File.copy(Sys.programPath()
												.replace("Blue\\Blue", "Blue\\")
												.replace("Blue/Blue", "Blue/")
												.replace(".exe", "") + "stdlib/cpp/"
												+ file,
												'export/cppsrc/$file');
										}
									}
								case "go":
									if (fileNumber == 1) {
										if (FileSystem.exists("export/gosrc")) {
											for (file in FileSystem.readDirectory("export/gosrc")) {
												if (!FileSystem.isDirectory('export/gosrc/$file'))
													FileSystem.deleteFile("export/gosrc/" + file);
												else {
													for (filebin in FileSystem.readDirectory("export/gosrc/" + file)) {
														if (FileSystem.exists('export/gosrc/$file/$filebin'))
															FileSystem.deleteFile('export/gosrc/$file/$filebin');
													}
													FileSystem.deleteDirectory('export/gosrc/$file');
												}
											}
										}
									}
									BGoUtil.fileName = file;
									BGoUtil.goData.insert(0, 'package main');
									lexSourceFile(rawContent);
									if (FileSystem.exists(Sys.programPath()
										.replace("Blue\\Blue", "Blue\\")
										.replace("Blue/Blue", "Blue/")
										.replace(".exe", "") + "stdlib/go")) {
										for (file in FileSystem.readDirectory(Sys.programPath()
											.replace("Blue\\Blue", "Blue\\")
											.replace("Blue/Blue", "Blue/")
											.replace(".exe", "") + "stdlib/go")) {
											File.copy(Sys.programPath()
												.replace("Blue\\Blue", "Blue\\")
												.replace("Blue/Blue", "Blue/")
												.replace(".exe", "") + "stdlib/go/"
												+ file,
												'export/gosrc/$file');
										}
									}
								case "groovy":
									if (fileNumber == 1) {
										if (FileSystem.exists("export/groovysrc")) {
											for (file in FileSystem.readDirectory("export/groovysrc")) {
												FileSystem.deleteFile("export/groovysrc/" + file);
											}
										}
									}
									BGroovyUtil.fileName = file;
									lexSourceFile(rawContent);
									if (FileSystem.exists(Sys.programPath()
										.replace("Blue\\Blue", "Blue\\")
										.replace("Blue/Blue", "Blue/")
										.replace(".exe", "") + "stdlib/groovy")) {
										for (file in FileSystem.readDirectory(Sys.programPath()
											.replace("Blue\\Blue", "Blue\\")
											.replace("Blue/Blue", "Blue/")
											.replace(".exe", "") + "stdlib/groovy")) {
											File.copy(Sys.programPath()
												.replace("Blue\\Blue", "Blue\\")
												.replace("Blue/Blue", "Blue/")
												.replace(".exe", "") + "stdlib/groovy/"
												+ file,
												'export/groovysrc/$file');
										}
									}
								case "haxe":
									if (fileNumber == 1) {
										if (FileSystem.exists("export/hxsrc")) {
											for (file in FileSystem.readDirectory("export/hxsrc")) {
												FileSystem.deleteFile("export/hxsrc/" + file);
											}
										}
									}
									BHaxeUtil.fileName = file;
									BHaxeUtil.haxeData.insert(0, 'package export.hxsrc;');
									BHaxeUtil.haxeData.insert(1, 'import export.hxsrc.' + "File" + ';');
									BHaxeUtil.haxeData.insert(1, 'import export.hxsrc.' + "System" + ';');
									BHaxeUtil.haxeData.insert(1, 'import export.hxsrc.' + "MathTools" + ';');
									BHaxeUtil.haxeData.insert(1, 'import export.hxsrc.' + "ArrayTools" + ';');
									for (includeFile in FileSystem.readDirectory(directory)) {
										if (includeFile.endsWith(".bl")) {
											if (includeFile != file) {
												BHaxeUtil.haxeData.insert(1, 'import export.hxsrc.' + '${includeFile.replace(".bl", "")}' + ';');
											}
										}
									};
									lexSourceFile(rawContent);
									if (FileSystem.exists(Sys.programPath()
										.replace("Blue\\Blue", "Blue\\")
										.replace("Blue/Blue", "Blue/")
										.replace(".exe", "") + "stdlib/haxe")) {
										for (file in FileSystem.readDirectory(Sys.programPath()
											.replace("Blue\\Blue", "Blue\\")
											.replace("Blue/Blue", "Blue/")
											.replace(".exe", "") + "stdlib/haxe")) {
											File.copy(Sys.programPath()
												.replace("Blue\\Blue", "Blue\\")
												.replace("Blue/Blue", "Blue/")
												.replace(".exe", "") + "stdlib/haxe/"
												+ file,
												'export/hxsrc/$file');
										}
									}
								case "javascript":
									if (fileNumber == 1) {
										if (FileSystem.exists("export/jssrc")) {
											for (file in FileSystem.readDirectory("export/jssrc")) {
												FileSystem.deleteFile("export/jssrc/" + file);
											}
										}
									}
									BJSUtil.fileName = file;
									lexSourceFile(rawContent);
									if (FileSystem.exists(Sys.programPath()
										.replace("Blue\\Blue", "Blue\\")
										.replace("Blue/Blue", "Blue/")
										.replace(".exe", "") + "stdlib/js")) {
										for (file in FileSystem.readDirectory(Sys.programPath()
											.replace("Blue\\Blue", "Blue\\")
											.replace("Blue/Blue", "Blue/")
											.replace(".exe", "") + "stdlib/js")) {
											File.copy(Sys.programPath()
												.replace("Blue\\Blue", "Blue\\")
												.replace("Blue/Blue", "Blue/")
												.replace(".exe", "") + "stdlib/js/"
												+ file,
												'export/jssrc/$file');
										}
									}
							}
							switch (target) {
								case "coffeescript":
									Console.log("- " + currentFile_Noerr.replace(".bl", ".coffee"));
								case "cpp":
									Console.log("- " + currentFile_Noerr.replace(".bl", ".cpp"));
								case "go":
									Console.log("- " + currentFile_Noerr.replace(".bl", ".go"));
								case "groovy":
									Console.log("- " + currentFile_Noerr.replace(".bl", ".groovy"));
								case "haxe":
									Console.log("- " + currentFile_Noerr.replace(".bl", ".hx"));
								case "javascript":
									Console.log("- " + currentFile_Noerr.replace(".bl", ".js"));
							}
							if (target == "c" || target == "cpp" || target == "haxe") {
								for (i in 0...rawContent.split("\n").length) {
									var line = rawContent.split("\n")[i];
									if (line.contains("@Extends(")) {
										BHaxeUtil.extension = (line.split("@Extends(")[1].split(")")[0]);
									}
								}
							}
							if (target == "haxe" || target == "go") {
								for (i in 0...rawContent.split("\n").length) {
									var line = rawContent.split("\n")[i];
									if (line.contains("@Package(")) {
										if (target == "haxe") {
											BHaxeUtil.haxeData[0] = 'package ' + (line.split("@Package(")[1].split(")")[0]) + ';';
										} else if (target == "go") {
											BHaxeUtil.haxeData[0] = 'package ' + (line.split("@Package(")[1].split(")")[0]) + ';';
										}
									}
								}
							}
						} else
							Sys.exit(1);
					} else
						Sys.exit(1);
				}
			}
			FileSystem.createDirectory("export/bin");
			var parsedConf = haxe.Json.parse(File.getContent("project_config.json"));
			switch (target) {
				case 'c':
					if (FileSystem.exists("export/csrc") && FileSystem.readDirectory("export/csrc").length == files.length + 8) {
						buildCommand = parsedConf.build_commands.c.command;
						Sys.command(buildCommand);
					}
				case "coffeescript":
					if (FileSystem.exists("export/coffeescriptsrc")
						&& (FileSystem.readDirectory("export/coffeescriptsrc").length == files.length + 4
							|| FileSystem.readDirectory("export/coffeescriptsrc").length == (files.length + 8 + files.length))) {
						buildCommand = parsedConf.build_commands.coffeescript.command;
						Sys.command(buildCommand);
					}
				case "cpp":
					if (FileSystem.exists("export/cppsrc") && FileSystem.readDirectory("export/cppsrc").length == files.length + 4) {
						buildCommand = parsedConf.build_commands.cpp.command;
						Sys.command(buildCommand);
					}
				case "go":
					if (FileSystem.exists("export/gosrc/go.mod")) {
						FileSystem.deleteFile('export/gosrc/go.mod');
					}
					if (FileSystem.exists("export/gosrc")
						&& (FileSystem.readDirectory("export/gosrc").length == files.length + 4
							|| FileSystem.readDirectory("export/gosrc").length == files.length + 5
							|| FileSystem.readDirectory("export/gosrc").length == files.length + 6)) {
						Sys.setCwd(Sys.getCwd() + '/export/gosrc');
						Sys.command('go mod init export/gosrc');
						buildCommand = parsedConf.build_commands.go.command;
						Sys.command(buildCommand);
						Sys.setCwd(Sys.getCwd().split('export/gosrc')[0]);
					}
					if (FileSystem.exists("export/gosrc/go.mod")) {
						FileSystem.deleteFile('export/gosrc/go.mod');
					}
				case "groovy":
					if (FileSystem.exists("export/groovysrc") && FileSystem.readDirectory("export/groovysrc").length == files.length + 4) {
						buildCommand = parsedConf.build_commands.groovy.command;
						Sys.command(buildCommand);
					}
				case "haxe":
					if (FileSystem.exists("export/hxsrc") && FileSystem.readDirectory("export/hxsrc").length == files.length + 4) {
						buildCommand = parsedConf.build_commands.haxe.command;
						Sys.command(buildCommand);
					}
			}
		} else {
			Console.log("<b><red>Error:</></> <light_white>Source folder '" + directory + "' does not exist or is not a directory</>");
		}
	}

	public static function mapFile(input:String) {
		currentMappedFiles.push(input);
	}

	public static function lexSourceFile(content:String) {
		lexing.BLexer.enumContent(content, false);
	}

	public static function checkForSyntaxErrors(input:String, reportErrors:Bool = false):Bool {
		var hasCondition = false;
		var haveErr = false;
		if (input.contains("\n") && reportErrors) {
			for (i in 0...input.split("\n").length) {
				var reg = ~/"([^"]*?)"/g;
				var line = input.split("\n")[i];
				line = reg.replace(line, '""');
				var letters = "abcdefghijklmnopqrstuvwusyz";
				var chars = "#$%^&?|{}`';";

				if (!line.contains("***")) {
					if (line.contains("<<") && !line.contains("<<end>>")) {
						hasCondition = true;
					}
					if (line.contains("<<end>>")) {
						hasCondition = false;
					}
					if (line.replace(" ", "").startsWith("if") && !line.contains("then")) {
						Console.log('<light_white>'
							+ currentFile_Noerr
							+ " - "
							+ "</><b><red>Error [BLE0055]:</></><light_white> Expected 'then' at the end of line "
							+ (i + 1)
							+ '</>');
						haveErr = true;
						Console.log("");
						Console.log("<b><red>" + line.ltrim().trim() + "</></>");
						var squigglyLines = "";
						for (i in 0...line.ltrim().trim().split('').length) {
							squigglyLines += "~";
						}
						Console.log("<red>" + squigglyLines + "</>");
					}

					for (n in 0...chars.split("").length) {
						if (line.contains(chars.split("")[n]) && !completeSyntax[i].contains(chars.split("")[n])) {
							Console.log('<light_white>'
								+ currentFile_Noerr
								+ " - "
								+ "</><b><red>Error [BLE0019]:</></><light_white> Unknown character: '"
								+ chars.split("")[n]
								+ "' at line "
								+ (i + 1)
								+ '</>');
							haveErr = true;
							Console.log("");
							Console.log("<b><red>" + line.ltrim().trim() + "</></>");
							var squigglyLines = "";
							for (i in 0...line.ltrim().trim().split('').length) {
								squigglyLines += "~";
							}
							Console.log("<red>" + squigglyLines + "</>");
							break;
						}
					}

					if (line.contains(".") && !line.split(".")[0].contains("0") && !line.split(".")[1].contains("0") && !line.split(".")[0].contains("1")
						&& !line.split(".")[1].contains("1") && !line.split(".")[0].contains("2") && !line.split(".")[1].contains("2")
						&& !line.split(".")[0].contains("3") && !line.split(".")[1].contains("3") && !line.split(".")[0].contains("4")
						&& !line.split(".")[1].contains("4") && !line.split(".")[0].contains("4") && !line.split(".")[1].contains("5")
						&& !line.split(".")[0].contains("5") && !line.split(".")[1].contains("6") && !line.split(".")[0].contains("6")
						&& !line.split(".")[1].contains("7") && !line.split(".")[0].contains("7") && !line.split(".")[1].contains("8")
						&& !line.split(".")[0].contains("8") && !line.split(".")[1].contains("9") && !line.split(".")[0].contains("9")) {
						Console.log('<light_white>'
							+ currentFile_Noerr
							+ " - "
							+ "</><b><red>Error [BLE0019]:</></><light_white> Unknown character: "
							+ "."
							+ " at line "
							+ (i + 1)
							+ '</>');
						haveErr = true;
						Console.log("");
						Console.log("<b><red>" + line.ltrim().trim() + "</></>");
						var squigglyLines = "";
						for (i in 0...line.ltrim().trim().split('').length) {
							squigglyLines += "~";
						}
						Console.log("<red>" + squigglyLines + "</>");
					}

					if (line.contains("method") && line.contains(":")) {
						Console.log('<light_white>'
							+ currentFile_Noerr
							+ " - "
							+ "</><b><red>Error [BLE0019]:</></><light_white> Unknown character: ':'"
							+ " at line "
							+ (i + 1)
							+ '</>');
						haveErr = true;
						Console.log("");
						Console.log("<b><red>" + line.ltrim().trim() + "</></>");
						var squigglyLines = "";
						for (i in 0...line.ltrim().trim().split('').length) {
							squigglyLines += "~";
						}
						Console.log("<red>" + squigglyLines + "</>");
					}

					if (line.contains("constructor(") && input.split("constructor(")[1].split("end")[0].contains("return ")) {
						Console.log('<light_white>'
							+ currentFile_Noerr
							+ " - "
							+ "</><b><red>Error [BLE0056]:</></><light_white> constructors cannot have a return value at line "
							+ (i + 1)
							+ '</>');
						haveErr = true;
						Console.log("");
						Console.log("<b><red>" + line.ltrim().trim() + "</></>");
						var squigglyLines = "";
						for (i in 0...line.ltrim().trim().split('').length) {
							squigglyLines += "~";
						}
						Console.log("<red>" + squigglyLines + "</>");
					}

					if (line.contains("main(") && reg.replace(input, '""').split("main(")[1].split(")")[0].replace(" ", "") != "") {
						Console.log('<light_white>'
							+ currentFile_Noerr
							+ " - "
							+ "</><b><red>Error [BLE0057]:</></><light_white> The main entry point cannot take arguments at line "
							+ (i + 1)
							+ '</>');
						haveErr = true;
						Console.log("");
						Console.log("<b><red>" + line.ltrim().trim() + "</></>");
						var squigglyLines = "";
						for (i in 0...line.ltrim().trim().split('').length) {
							squigglyLines += "~";
						}
						Console.log("<red>" + squigglyLines + "</>");
					}

					if (line.contains("main(") && reg.replace(input, '""').split("main(")[1].split("end")[0].contains("return")) {
						Console.log('<light_white>'
							+ currentFile_Noerr
							+ " - "
							+ "</><b><red>Error [BLE0058]:</></><light_white> The main entry point cannot have a return value at line "
							+ (i + 1)
							+ '</>');
						haveErr = true;
						Console.log("");
						Console.log("<b><red>" + line.ltrim().trim() + "</></>");
						var squigglyLines = "";
						for (i in 0...line.ltrim().trim().split('').length) {
							squigglyLines += "~";
						}
						Console.log("<red>" + squigglyLines + "</>");
					}

					if (!line.contains("=") && line.contains("method ") && !line.contains("(") && !line.contains(")")) {
						Console.log('<light_white>'
							+ currentFile_Noerr
							+ " - "
							+ "</><b><red>Error [BLE0060]:</></><light_white> Method: "
							+ line.split("method ")[1].split("(")[0].replace(' ', '')
								+ " is missing it's parameter brackets at line "
								+ (i + 1)
								+ '</>');
						haveErr = true;
						Console.log("");
						Console.log("<b><red>" + line.ltrim().trim() + "</></>");
						var squigglyLines = "";
						for (i in 0...line.ltrim().trim().split('').length) {
							squigglyLines += "~";
						}
						Console.log("<red>" + squigglyLines + "</>");
					}

					if (line.contains("method ") && !input.split(line)[1].contains("return")) {
						Console.log("<b><light_white>"
							+ currentFile_Noerr
							+ " - "
							+ "</><b><red>Error [BLE0061]:</></><light_white> A method "
							+ "was provided no return value at line "
							+ (i + 1)
							+ '</>');
						haveErr = true;
						Console.log("");
						Console.log("<b><red>" + line.ltrim().trim() + "</></>");
						var squigglyLines = "";
						for (i in 0...line.ltrim().trim().split('').length) {
							squigglyLines += "~";
						}
						Console.log("<red>" + squigglyLines + "</>");
					}

					if (line.contains("<<")
						&& !line.contains("<<!")
						&& !supportedTargets.contains(line.split("<<")[1].split(">>")[0])
						&& line.split("<<")[1].split(">>")[0] != "end"
						&& line.contains(",")) {
						for (i in 0...line.split(",").length) {
							if (line.split(",")[i].replace("<<", "").replace(">>", "").contains("!")) {
								if (!supportedTargets.contains(line.split(",")[i].split("!")[1].replace("<<", "")
								.replace(">>", "")
								.replace(" ", "")
								.replace("\r", ""))) {
									Console.log('<light_white>'
										+ currentFile_Noerr
										+ " - "
										+ "</><b><red>Error [BLE0062]:</></><light_white> Unknown target: '"
										+ line.split(",")[i].split("!")[1].replace("<<", "")
										.replace(">>", "")
										.replace(" ", "")
										.replace("\r", "")
											+ "'"
											+ " at line "
											+ (i + 1)
											+ '</>');
									haveErr = true;
									Console.log("");
									Console.log("<b><red>" + line.ltrim().trim() + "</></>");
									var squigglyLines = "";
									for (i in 0...line.ltrim().trim().split('').length) {
										squigglyLines += "~";
									}
									Console.log("<red>" + squigglyLines + "</>");
									break;
								}
							}
							if (!line.split(",")[i].replace("<<", "").replace(">>", "").replace(" ", "").contains("!")) {
								if (!supportedTargets.contains(line.split(",")[i].replace("<<", "").replace(">>", "").replace(" ", "").replace("\r", ""))) {
									Console.log('<light_white>'
										+ currentFile_Noerr
										+ " - "
										+ "</><b><red>Error [BLE0062]:</></><light_white> Unknown target: '"
										+ line.split(",")[i].replace("<<", "")
										.replace(">>", "")
										.replace(" ", "")
										.replace("\r", "")
											+ "'"
											+ " at line "
											+ (i + 1)
											+ '</>');
									haveErr = true;
									Console.log("");
									Console.log("<b><red>" + line.ltrim().trim() + "</></>");
									var squigglyLines = "";
									for (i in 0...line.ltrim().trim().split('').length) {
										squigglyLines += "~";
									}
									Console.log("<red>" + squigglyLines + "</>");
									break;
								}
							}
						}
					}

					if (line.contains("<<")
						&& !line.contains("<<!")
						&& !supportedTargets.contains(line.split("<<")[1].split(">>")[0])
						&& line.split("<<")[1].split(">>")[0] != "end"
						&& !line.contains(",")) {
						Console.log('<light_white>'
							+ currentFile_Noerr
							+ " - "
							+ "</><b><red>Error [BLE0062]:</></><light_white> Unknown target: '"
							+ line.split("<<")[1].split(">>")[0]
								+ "'"
								+ " at line "
								+ (i + 1)
								+ '</>');
						haveErr = true;
						Console.log("");
						Console.log("<b><red>" + line.ltrim().trim() + "</></>");
						var squigglyLines = "";
						for (i in 0...line.ltrim().trim().split('').length) {
							squigglyLines += "~";
						}
						Console.log("<red>" + squigglyLines + "</>");
					}
					if (line.contains("<<!")
						&& !supportedTargets.contains(line.split("<<!")[1].split(">>")[0])
						&& line.split("<<!")[1].split(">>")[0] != "end"
						&& !line.contains(",")) {
						Console.log('<light_white>'
							+ currentFile_Noerr
							+ " - "
							+ "</><b><red>Error [BLE0062]:</></><light_white> Unknown target: '"
							+ line.split("<<!")[1].split(">>")[0]
								+ "'"
								+ " at line "
								+ (i + 1)
								+ '</>');
						haveErr = true;
						Console.log("");
						Console.log("<b><red>" + line.ltrim().trim() + "</></>");
						var squigglyLines = "";
						for (i in 0...line.ltrim().trim().split('').length) {
							squigglyLines += "~";
						}
						Console.log("<red>" + squigglyLines + "</>");
					}

					if (line.contains(">>") && !line.contains("<<")) {
						Console.log('<light_white>'
							+ currentFile_Noerr
							+ " - "
							+ "</><b><red>Error [BLE0063]:</></><light_white> Expected conditional compilation block at line "
							+ (i + 1)
							+ '</>');
						haveErr = true;
						Console.log("");
						Console.log("<b><red>" + line.ltrim().trim() + "</></>");
						var squigglyLines = "";
						for (i in 0...line.ltrim().trim().split('').length) {
							squigglyLines += "~";
						}
						Console.log("<red>" + squigglyLines + "</>");
					}

					if (!line.contains(">>") && line.contains("<<")) {
						Console.log('<light_white>'
							+ currentFile_Noerr
							+ " - "
							+ "</><b><red>Error [BLE0063]:</></><light_white> Expected conditional compilation block at line "
							+ (i + 1)
							+ '</>');
						haveErr = true;
						Console.log("");
						Console.log("<b><red>" + line.ltrim().trim() + "</></>");
						var squigglyLines = "";
						for (i in 0...line.ltrim().trim().split('').length) {
							squigglyLines += "~";
						}
						Console.log("<red>" + squigglyLines + "</>");
					}

					if (line.contains("***") && !line.split("***")[1].contains("***")) {
						Console.log('<light_white>'
							+ currentFile_Noerr
							+ " - "
							+ "</><b><red>Error [BLE0064]:</></><light_white> Expected '***' to end comment at line "
							+ (i + 1)
							+ '</>');
						haveErr = true;
						Console.log("");
						Console.log("<b><red>" + line.ltrim().trim() + "</></>");
						var squigglyLines = "";
						for (i in 0...line.ltrim().trim().split('').length) {
							squigglyLines += "~";
						}
						Console.log("<red>" + squigglyLines + "</>");
					}
					if (line.contains("[") && line.contains("]") && line.contains(~/[A-Z0-9]/ + " = " + "[")) {
						if (!line.split("[")[1].split("]")[0].replace(" ", "").contains(~/[A-Z0-9]/ + ",")
							&& !line.split("[")[1].split("]")[0].replace(" ", "").contains(~/[A-Z0-9]/ + "")
							&& line.split("[")[1].split("]")[0].replace(" ", "") != "") {
							Console.log('<light_white>'
								+ currentFile_Noerr
								+ " - "
								+ "</><b><red>Error [BLE0065]:</></><light_white> Invalid array definition at line "
								+ (i + 1)
								+ '</>');
							haveErr = true;
							Console.log("");
							Console.log("<b><red>" + line.ltrim().trim() + "</></>");
							var squigglyLines = "";
							for (i in 0...line.ltrim().trim().split('').length) {
								squigglyLines += "~";
							}
							Console.log("<red>" + squigglyLines + "</>");
						}
					}
				}
				if (line.contains("!") && !line.contains("<<") && !line.contains("print") && !line.contains("addressOf") && !line.contains("fromAddress")
					&& !line.contains("targetInject")) {
					Console.log('<light_white>'
						+ currentFile_Noerr
						+ " - "
						+ "</><b><red>Error [BLE0019]:</></><light_white> Unknown character: '!'"
						+ " at line "
						+ (i + 1)
						+ '</>');
					haveErr = true;
					Console.log("");
					Console.log("<b><red>" + line.ltrim().trim() + "</></>");
					var squigglyLines = "";
					for (i in 0...line.ltrim().trim().split('').length) {
						squigglyLines += "~";
					}
					Console.log("<red>" + squigglyLines + "</>");
				}
			}
		} else if (input.contains("\n") && reportErrors) {
			Console.log('<light_white>'
				+ currentFile_Noerr
				+ " - "
				+ "</><b><red>Error [BLE0066]:</></><light_white> No newline found on file at line 1");
			haveErr = true;
			Console.log("");
			Console.log("<b><red>" + input.ltrim().trim() + "</></>");
			var squigglyLines = "";
			for (i in 0...input.ltrim().trim().split('').length) {
				squigglyLines += "~";
			}
			Console.log("<red>" + squigglyLines + "</>");
			haveErr = true;
			Sys.exit(1);
		}

		if (haveErr)
			return true;

		return false;
	}
}
