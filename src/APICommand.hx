package;
import format.tools.ArcFour;
import haxe.crypto.Md5;
import haxe.ds.StringMap;
import haxe.Http;
import haxe.io.Bytes;
import haxe.Json;

/**
 * Aid to post data to NG's servers.
 * @author MSGHero
 */
class APICommand{

	var commandType:String;
	var parameters:StringMap<Dynamic>;
	var secureParams:StringMap<Dynamic>;
	var isSecure:Bool;
	
	var files:StringMap<File>;
	
	public dynamic function onData(data:String) { }
	public dynamic function onError(msg:String) { }
	public dynamic function onStatus(status:Int) { }
	
	inline static var RADIX79:String = "/g8236klvBQ#&|;Zb*7CEA59%s`Oue1wziFp$rDVY@TKxUPWytSaGHJ>dmoMR^<0~4qNLhc(I+fjn)X";
	
	public function new(command:String) {
		
		commandType = command;
		parameters = new StringMap<Dynamic>();
		secureParams = new StringMap<Dynamic>();
		
		files = new StringMap<File>();
		isSecure = false;
	}
	
	// cleanup method?
	
	public function addParam(field:String, value:Dynamic, secure:Bool = false):APICommand {
		(secure ? secureParams : parameters).set(field, value);
		if (secure) isSecure = true;
		return this;
	}
	
	public function addFile(filename:String, data:Bytes, dataField:String, contentType:String = "application/octet-stream"):Void {
		files.set(filename, {
			filename:filename,
			data:data,
			dataField:dataField,
			contentType:contentType
		} );
	}
	
	public function send():Void {
		// push to queue
		
		var unsec:Dynamic = { };
		unsec.command_id = commandType;
		unsec.tracker_id = API.apiId;
		unsec.debug = 1; // for now
		
		var v;
		for (k in parameters.keys()) {
			v = parameters.get(k);
			if (Std.is(v, Bool)) v = cast(v, Bool) ? 1 : 0;
			Reflect.setField(unsec, k, v);
		}
		
		if (isSecure) {
			
			var sec:Dynamic = { };
			
			for (k in secureParams.keys()) {
				v = secureParams.get(k);
				if (Std.is(v, Bool)) v = cast(v, Bool) ? 1 : 0;
				Reflect.setField(sec, k, v);
			}
			
			var seed = getKey(16);
			
			sec.command_id = unsec.command_id;
			unsec.command_id = "securePacket";
			// if prevent cache: unsec.seed = Math.random();
			
			sec.session_id = API.sessionId;
			sec.publisher_id = API.publisherId;
			sec.seed = seed;
			
			var j = Json.stringify(sec);
			
			var secureRC4 = Bytes.alloc(j.length);
			var secureBytes = Bytes.ofString(j);
			
			var rc4 = new ArcFour(Bytes.ofString(API.encryptionKey));
			rc4.run(secureBytes, 0, secureBytes.length, secureRC4, 0);
			
			var encrypted = Md5.encode(seed) + secureRC4.toHex();
			
			var sixhex:String, decimal:Int, four:String;
			var compressed = "";
			for (i in 0...Math.ceil(encrypted.length / 6)) {
				
				sixhex = '0x${encrypted.substr(i * 6, 6)}';
				decimal = Std.parseInt(sixhex);
				four = toBase79(decimal);
				
				while (sixhex.length == 8 && four.length < 4) four = '${RADIX79.charAt(0)}${four}';
				compressed += four;
			}
			
			compressed = '${encrypted.length % 6}${compressed}';
			unsec.secure = compressed;
		}
		
		var header:String, data:String = '';
		if (!Lambda.empty(files)) {
			var boundary = getKey(32);
			header = 'multipart/form-data; boundary="$boundary"';
			data = buildMultipartData(boundary, unsec);
		}
		else {
			header = "application/x-www-form-urlencoded";
		}
		
		var http = new Http(API.API_PATH);
		http.setHeader("Content-Type", header);
		if (data.length > 0) http.setPostData(data);
		
		for (field in Reflect.fields(unsec)) {
			http.setParameter(field, Std.string(Reflect.field(unsec, field)));
		}
		
		http.onData = onData;
		http.onError = onError;
		http.onStatus = onStatus;
		
		http.request(true);
	}
	
	function buildMultipartData(boundary:String, unsec:Dynamic):String {
		
		boundary = '--$boundary';
		
		var CRLF = "\r\n";
		var b = new StringBuf();
		
		for (field in Reflect.fields(unsec)) {
			b.add(boundary + CRLF);
			b.add('Content-Disposition: form-data; name="$field"' + CRLF);
			b.add(CRLF);
			b.add(Std.string(Reflect.field(unsec, field)) + CRLF);
		}
		
		if (!Lambda.empty(files)) {
			
			var v;
			for (k in files.keys()) {
				v = files.get(k);
				b.add(boundary + CRLF);
				b.add('Content-Disposition: form-data; name="Filename"' + CRLF);
				b.add(CRLF);
				b.add('${v.filename}' + CRLF);
				b.add(boundary + CRLF);
				b.add('Content-Disposition: form-data; name="' + v.dataField + '"; filename="' + v.filename + '"' + CRLF);
				b.add('Content-Type: ' + v.contentType + CRLF);
				b.add(CRLF);
				b.add(v.data.toHex());
				b.add(CRLF);
			}
			
			b.add(boundary + CRLF + 'Content-Disposition: form-data; name="Upload"' + CRLF + CRLF + 'Submit Query' + CRLF);
			
			b.add(boundary + '--');
		}
		
		return b.toString();
	}
	
	static function getKey(length:Int):String {
		var key = "";
		for (i in 0...length) {
			key += RADIX79.charAt(Std.int(Math.random() * RADIX79.length));
		}
		return key;
	}
	
	static function toBase79(dec:Int):String {
		
		var res = "";
		var r:Int;
		while (dec > 0) {
			r = dec % 79;
			res = '${RADIX79.charAt(r)}${res}';
			dec = Std.int(dec / 79);
		}
		
		return res;
	}
}

typedef File = {
	filename:String,
	data:Bytes,
	dataField:String,
	contentType:String
}