(
var prefetch = {
	arg q;
	var l, result;

	l = ("nix-prefetch-git" + "--quiet" + "--url" + q.url).unixCmdGetStdOutLines;
	l.do({arg item, i; result = result ++ item.stripWhiteSpace});

	result
};

var parseQuarkFromNix = {
	arg q, src;
	var path, qfp, result;

	path = src.parseJSON.at("path");
	qfp = path +/+ q.name ++ ".quark";
	q = Quark.fromLocalPath(path);
	thisProcess.interpreter.compileFile(qfp).value;
};

var toNix = {
	arg q;
	var deps, name, author, summary, version, src;

	src = prefetch.value(q);

	name = q.name;
	author = "";
	summary = "";
	version = "0.1.0";
	deps = "[]";

	try { q = parseQuarkFromNix.value(q, src); } { arg error; error.dump };

	try { name = q.name; } { arg error; error.dump };
	try { author = q.author; } { arg error; error.dump };
	try { summary = q.summary; } { arg error; error.dump };
	try { version = q.version; } { arg error; error.dump };

	format(
		"{%: \"%\", %: \"%\", %: \"%\", %: %}",

		"name".quote,
		name,

		"author".quote,
		author,

		"version".quote,
		version,

		"src".quote,
		src
	);
};

var fetchAll = {
	var l, f;

	f = File("quarks.json", "w");
	f.write("{" ++ "quarks".quote ++ ":");

	Quarks.all.do({
		arg item, i;
		item.postln;
		if (i > 0, { f.write(",") }, { f.write("[") });
		f.write(toNix.value(item));
	});

	f.write("]}");
	f.close;

};

fetchAll.value;
)
