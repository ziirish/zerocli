var RawDeflate = {};

var l = arguments.length;

if (l < 1) {
	print('Missing engine!');
	quit(1);
}

var engine = arguments[0];

if (l < 2) {
	print('Missing path!');
	quit(2);
}

var path = arguments[1];

load(path+'js/sjcl.js');
load(path+'js/base64.js');
load(path+'js/rawinflate.js');
load(path+'js/rawdeflate.js');
load(path+'js/zerocli.js');

if (l < 3) {
	print('Missing method!');
	quit(3);
}

var method = arguments[2];

if (method == "post") {
	if (l != 4) {
		print('Missing filename!');
		quit(4);
	}

	var filename = arguments[3];
	var t = '';
	if (engine == "rhino") {
		t = readFile(filename);
	} else if (engine == "v8") {
		t = read(filename);
	} else {
		print('Wrong engine!');
		quit(8);
	}
	//print('data: ' + t);
	encrypt_data(t);
} else if (method == "get") {
	if (l != 5) {
		print('Missing key and/or message');
		quit(5);
	}

	var key = arguments[3];
	var datafile = arguments[4];
	var data = '';

	if (engine == "rhino") {
		data = readFile(datafile);
	} else if (engine == "v8") {
		data = read(datafile);
	} else {
		print('Wrong engine!');
		quit(8);
	}
	/*
	print('key: '+key);
	print('data: '+data);
	*/

	print(decrypt_data(key, data));
} else {
	print('Wrong method!');
	quit(6);
}
