package;
import flash.Lib;
import haxe.Http;
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
		
		var medals = (o.medals:Array<Dynamic>);
		for (medal in medals) {
			// medals: "Medal: 01. Name (locked, 5pts, Easy)" Easy, Moderate, Challenging, Difficult, Brutal correspond to medal difficulties 1,2,3,4,5
			log('Medal: ${medal.medal_value}. ${medal.medal_name}    (${medal.unlocked ? "unlocked" : "locked"})');
			// store medal objects
		}
		
		log('${medals.length} medals initialized.');
		
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
	
	inline function log(s:String):Void {
		Log.trace('[Newgrounds API] :: ${s}');
	}
}