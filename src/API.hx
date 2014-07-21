package;
import flash.Lib;
import haxe.crypto.Md5;
import haxe.Http;
import haxe.io.Bytes;
import haxe.Json;
import haxe.Log;

/**
 * ...
 * @author MSGHero
 */
class API {

	var apiId:String = "37760:VcasLmE5"; // params for a test project I just made
	var encryptionKey:String = "blnNtJNPbE9t2JAfxM0Dpx0yMxQL4rVW";
	
	var username:String;
	var userId:UInt;
	var sessionId:String;
	
	var medals:Array<Medal>;
	
	inline static var radix79:String = "/g8236klvBQ#&|;Zb*7CEA59%s`Oue1wziFp$rDVY@TKxUPWytSaGHJ>dmoMR^<0~4qNLhc(I+fjn)X";
	
	public function new() {
		
		var h = new Http("http://www.ngads.com/gateway_v2.php");
		h.onData = onRequest;
		h.onError = showError;
		h.onStatus = showStatus;
		h.setHeader("Content-type", "application/x-www-form-urlencoded"); // no idea if this does anything
		h.addParameter("tracker_id", apiId);
		h.addParameter("command_id", "connectMovie"); // command_ids: http://www.newgrounds.com/wiki/creator-resources/newgrounds-apis/developer-gateway
		h.addParameter("host", "LocalHost"); // temp of course
		h.addParameter("preload", "1"); // gives us the medals and stuff
		h.addParameter("movie_version", "1"); // should be a parameter
		h.addParameter("skip_ads", "1"); // temp
		
		h.request(true); // post
		
		var params = Lib.current.loaderInfo.parameters;
		
		if (params == null) {
			username = null;
			userId = 0;
			sessionId = null;
		}
		
		else {
			username = params.NewgroundsAPI_UserName;
			userId = Std.parseInt(params.NewgroundsAPI_UserID);
			sessionId = params.NewgroundsAPI_SessionID;
		}
		
		log("====== Newgrounds API v0.1 HAXE ======"); // more like version epsilon
		log("Connecting to the Newgrounds API Gateway...");
	}
	
	function onRequest(s:String):Void {
		
		var o = Json.parse(s);
		
		if (o.success == 0) return; // just in case
		
		log('----- ${o.movie_name} -----');
		
		medals = [];
		var medalData = (o.medals:Array<Dynamic>);
		for (i in 0...medalData.length) {
			medals.push(new Medal(medalData[i], i));
			log(medals[i]);
		}
		
		log('${medals.length} medals initialized.'); // always plural, w/e
		
		// "n scoreboards initialized."
		// savegroups: "SaveGroup: Name  Keys:   Ratings: "
		// "n save group initialized."
		
		log("Connection complete!");
	}
	
	function showError(s:String):Void {
		log("Error when sending command:");
		log(s);
		log("Unable to connect to the API.");
	}
	
	function showStatus(i:Int):Void {
		// Log.trace(i);
	}
	
	function sendEncrypted(unsecure:Dynamic, seedLen:Int = 16, ?requestCallback:String->Void):Void {
		
		// unsecure is has everything needed except for seed and sessionid
		
		// messy
		var seed = getKey(seedLen);
		unsecure.session_id = sessionId;
		var secure = Json.stringify(unsecure);
		
		var secureRC4 = Bytes.alloc(secure.length);
		var secureBytes = Bytes.ofString(secure);
		
		var rc4 = new ArcFour(Bytes.ofString(encryptionKey));
		rc4.run(secureBytes, 0, secureBytes.length, secureRC4, 0);
		
		var encrypted = Md5.encode(seed) + secureRC4.toHex();
		
		var sixhex:String, decimal:Int, four:String;
		var compressed = "";
		for (i in 0...Math.ceil(encrypted.length / 6)) {
			
			sixhex = '0x${encrypted.substr(i * 6, 6)}';
			decimal = Std.parseInt(sixhex);
			four = toBase79(decimal);
			
			while (four.length < 4) four = '${radix79.charAt(0)}${four}'; // there's a bug here if the last iteration grabs less than 6 chars, will look into it
			compressed += four;
		}
		
		compressed = '${encrypted.length % 6}${compressed}';
		
		var h = new Http("http://www.ngads.com/gateway_v2.php");
		h.onData = requestCallback;
		h.onError = showError;
		h.onStatus = showStatus;
		h.setHeader("Content-type", "application/x-www-form-urlencoded"); // no idea if this does anything
		h.addParameter("command_id", "securePacket");
		h.addParameter("tracker_id", apiId);
		h.addParameter("seed", seed);
		h.addParameter("secure", compressed);
		
		h.request(true);
	}
	
	function getKey(length:Int):String {
		var key = "";
		for (i in 0...length) {
			key += radix79.charAt(Std.int(Math.random() * 79));
		}
		return key;
	}
	
	function toBase79(dec:Int):String {
		
		var res = "";
		var r:Int;
		while (dec > 0) {
			r = dec % 79;
			res = '${radix79.charAt(r)}${res}';
			dec = Std.int(dec / 79);
		}
		
		return res;
	}
	
	inline function log(any:Dynamic):Void {
		Log.trace('[Newgrounds API] :: ${any}');
	}
}