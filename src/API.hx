package;
import flash.Lib;
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

	// debug and debugmode
	
	static var api:API;
	
	// getters, null
	public static var apiId:String;
	public static var encryptionKey:String;
	
	public static var username:String;
	public static var userId:UInt;
	public static var sessionId:String;
	public static var publisherId:Int;
	
	public static var medals:Array<Medal>;
	public static var groups:Array<SaveGroup>;
	
	public inline static var API_PATH:String = "http://www.ngads.com/gateway_v2.php/";
	public inline static var IMAGE_FILE_PATH:String = "http://apifiles.ngfiles.com/savedata/";
	
	function new(_apiId:String, _encryptionKey:String) {
		
		apiId = _apiId;
		encryptionKey = _encryptionKey;
		
		var ac = new APICommand("connectMovie");
		ac.addParam("host", "LocalHost").addParam("preload", true).addParam("movie_version", 1).addParam("skipAds", true);
		ac.onData = onInitRequest;
		ac.onError = showError;
		ac.onStatus = showStatus;
		ac.send();
		
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
		if (sessionId == null) sessionId = "D3bu64p1U53R";
		if (publisherId == 0) publisherId = 1;
		
		log("====== Newgrounds API v0.1 HAXE ======");
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
		medal.unlockMedal();
	}
	
	public static function log(any:Dynamic):Void {
		
		var msg = '[Newgrounds API] :: ${any}';
		
		// haxe.Log.trace is ugly
		// not sure which ones I care about
	#if flash
		flash.Lib.trace(msg);
	#elseif js
		js.Lib.alert(msg);
	#elseif sys
		Sys.println(msg);
	#else
		haxe.Log.trace(msg);
	#end
		
		// not sure how to make the project preview debug output recognize these, prolly some externalinterface call
	}
	
	public static function createSaveFile(groupName:String):SaveFile {
		
		// time zone?
		var date = Date.now().toString();
		
		var data = {
			save_id : 0, // ?
			filename : "",
			user_id : userId,
			user_name : username,
			created_date : date,
			updated_date : date,
			views : 0,
			description : "",
			group_id : getSaveGroupByName(groupName).id,
		}
		
		// save file, get save_id from callback
		
		return new SaveFile(data);
	}
	
	public static function loadSaveFile(saveId:UInt, loadContents:Bool):Void {
		
		var ac = new APICommand("loadSaveFile");
		ac.addParam("save_id", saveId).addParam("get_contents", loadContents);
		ac.onData = populateSaveFile;
		ac.send();
		
		// callback
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
	
	static function onInitRequest(s:String):Void {
		
		var o = Json.parse(s);
		if (o.success == 0) return; // just in case
		
		log('----- ${o.movie_name} -----');
		
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
		
		
		// TESTING
		
		//var m = medals[0];
		//m.unlockMedal();
	}
	
	static function lookAtFiles(sq:SaveQuery):Void {
		for (save in sq.files) {
			log([save.authorId, save.id, save.description]);
			log(save.id);
		}
		
		// sq.files[sq.files.length - 1].load();
	}
	
	static function populateSaveFile(s:String):Void {
		
		var o = Json.parse(s);
		
		if (o.success == 1) {
			o.file.group_id = o.group_id;
			var s = new SaveFile(o.file);
			if (o.get_contents) s.load();
		}
	}
	
	static function showError(s:String):Void {
		log("Error when sending command:");
		log(s);
		log("Unable to connect to the API.");
	}
	
	static function showStatus(i:Int):Void {
		// Log.trace(i);
	}
}