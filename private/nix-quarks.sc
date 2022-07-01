NixQuarks {

	*prefetch {
		arg q;
		var l, result;

		l = ("nix-prefetch-git" + "--quiet" + "--url" + q.url).unixCmdGetStdOutLines;
		l.do({arg item, i; result = result ++ item.stripWhiteSpace});

		^result.parseJSON
	}

	*parseQuarkFromNix {
		arg q, src;
		var path, qfp, result;

		path = src.at("path");
		qfp = path +/+ q.name ++ ".quark";

		if(File.exists(qfp), {
			q = Quark.fromLocalPath(path);
			^thisProcess.interpreter.compileFile(qfp).value;
		}, { ^nil })

	}

	*toNix {
		arg q;
		var name, deps, src;

		name = q.name;
		src = NixQuarks.prefetch(q);
		q = NixQuarks.parseQuarkFromNix(q, src);

		if(q.isNil, { q = (name: name, src: src); }, { q.src = src; });

		^JSON.stringify(q)
	}

	*fetchAll {
		arg path;
		var l, f;

		f = File(path, "w");
		f.write("{" ++ "quarks".quote ++ ":");

		Quarks.all.do({
			arg item, i;
			item.postln;
			if (i > 0, { f.write(",") }, { f.write("[") });
			f.write(NixQuarks.toNix(item));
		});

		f.write("]}");
		f.close;

	}
}