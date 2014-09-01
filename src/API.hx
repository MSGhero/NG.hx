package;
import flash.Lib;
import format.tools.ArcFour;
import haxe.crypto.Md5;
import haxe.Http;
import haxe.io.Bytes;
import haxe.Json;
import haxe.Log;
import saves.SaveFile;
import saves.SaveGroup;
import saves.SaveQuery;

/**
 * The Newgrounds API for Haxe.
 * @author MSGHero
 */
class API {

	static var api:API;
	
	static var apiId:String;
	static var encryptionKey:String;
	
	static var username:String;
	static var userId:UInt;
	static var sessionId:String;
	static var publisherId:Int;
	
	static var medals:Array<Medal>;
	static var groups:Array<SaveGroup>;
	
	inline static var RADIX79:String = "/g8236klvBQ#&|;Zb*7CEA59%s`Oue1wziFp$rDVY@TKxUPWytSaGHJ>dmoMR^<0~4qNLhc(I+fjn)X";
	
	function new(_apiId:String, _encryptionKey:String) {
		
		apiId = _apiId;
		encryptionKey = _encryptionKey;
		
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
		
		if (params != null) {
			username = params.NewgroundsAPI_UserName;
			userId = Std.parseInt(params.NewgroundsAPI_UserID);
			sessionId = params.NewgroundsAPI_SessionID;
			publisherId = Std.parseInt(params.NewgroundsAPI_PublisherID);
		}
		
		// defaults I think
		if (username == null) username = "API-Debugger";
		if (userId == 0) userId = 10;
		if (sessionId == null) sessionId = "D3bu64p1U53R"; // OMG IT SAYS DEBUG_API_USER
		if (publisherId == 0) publisherId = 1;
		
		log("====== Newgrounds API v0.1 HAXE ======"); // more like version epsilon
		log("Connecting to the Newgrounds API Gateway...");
	}
	
	public static function connect(apiId:String, encryptionKey:String):Void { // movie version
		api = new API(apiId, encryptionKey);
	}
	
	public static function unlockMedal(medalName:String):Void {
		
		var medal:Medal = null;
		for (m in medals)
			if (m.name == medalName) medal = m;
		
		if (medal == null) return; // do something else? log?
		sendEncrypted(medal.getUnlockMedalData(), medal.unlockMedal);
	}
	
	public static function log(any:Dynamic):Void {
		Log.trace('[Newgrounds API] :: ${any}');
		// not sure how to make the project preview debug output recognize these, prolly some externalinterface call
	}
	
	public static function createSaveFile(groupName:String):SaveFile {
		// idk
		return null;
	}
	
	public static function loadSaveFile(saveId:UInt, loadContents:Bool):Void {
		
		// callback after loading metadata, or callback after loading file contents?
		
		var h = new Http("http://www.ngads.com/gateway_v2.php");
		
		// log msg
		h.setParameter("command_id", "loadSaveFile");
		h.setParameter("save_id", Std.string(saveId));
		// sendunencrypted
		// idk
	}
	
	public static function getSaveGroupByName(groupName:String):SaveGroup {
		for (group in groups)
			if (group.name == groupName) return group;
		return null;
	}
	
	public static function getSaveGroupById(id:UInt):SaveGroup {
		for (group in groups)
			if (group.id == id) return group;
		return null;
	}
	
	
	// private, @:access
	
	static function onRequest(s:String):Void {
		
		var o = Json.parse(s);
		
		if (o.success == 0) return; // just in case
		
		log('----- ${o.movie_name} -----');
		log(o);
		medals = [];
		var medalData = (o.medals:Array<Dynamic>);
		if (medalData == null) medalData = [];
		for (i in 0...medalData.length) {
			medals.push(new Medal(medalData[i]));
			log(medals[i]);
		}
		
		log('${medals.length} medals initialized.'); // always plural, w/e
		
		// "n scoreboards initialized."
		
		groups = [];
		var groupData = (o.save_groups:Array<Dynamic>);
		if (groupData == null) groupData = [];
		for (i in 0...medalData.length) {
			groups.push(new SaveGroup(groupData[i]));
			// log(groups[i]);
		}
		// savegroups: "SaveGroup: Name  Keys:   Ratings: "
		
		log('${groups.length} save groups initialized.'); // double check, assumed it was this
		
		log("Connection complete!");
		
		var q = new SaveQuery(groups[0]);
		// q.addCondition(AUTHOR_ID, EQUALS, 3611941);
		q.execute(lookAtFiles);
	}
	
	static function lookAtFiles(sq:SaveQuery):Void {
		for (save in sq.files) {
			log([save.authorId, save.id, save.description]);
		}
		
		sq.files[sq.files.length - 1].load();
	}
	
	static function showError(s:String):Void {
		log("Error when sending command:");
		log(s);
		log("Unable to connect to the API.");
	}
	
	static function showStatus(i:Int):Void {
		// Log.trace(i);
	}
	
	@:allow(saves)
	static function sendUnencrypted(http:Http, ?requestCallback:String->Void):Void {
		
		if (requestCallback != null) http.onData = requestCallback;
		http.onError = showError;
		http.onStatus = showStatus;
		http.setHeader("Content-type", "application/x-www-form-urlencoded");
		http.addParameter("tracker_id", apiId);
		http.addParameter("publisher_id", Std.string(publisherId));
		
		http.request(true);
	}
	
	@:allow(saves)
	static function sendEncrypted(unsecure:Dynamic, ?requestCallback:String->Void, seedLen:Int = 16):Void {
		
		// unsecure is has everything needed except for seed, publisherid, and sessionid
		
		// messy
		var seed = getKey(seedLen);
		unsecure.session_id = sessionId;
		unsecure.publisher_id = publisherId;
		unsecure.seed = seed;
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
			
			while (sixhex.length == 8 && four.length < 4) four = '${RADIX79.charAt(0)}${four}';
			compressed += four;
		}
		
		compressed = '${encrypted.length % 6}${compressed}';
		
		var h = new Http("http://www.ngads.com/gateway_v2.php");
		if (requestCallback != null) h.onData = requestCallback;
		h.onError = showError;
		h.onStatus = showStatus;
		h.setHeader("Content-type", "application/x-www-form-urlencoded");
		h.addParameter("command_id", "securePacket");
		h.addParameter("tracker_id", apiId);
		h.addParameter("seed", seed);
		h.addParameter("secure", compressed);
		
		h.request(true);
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