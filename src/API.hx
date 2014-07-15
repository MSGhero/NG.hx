package;
import haxe.Http;
import haxe.Log;

/**
 * ...
 * @author MSGHero
 */
class API {

	var apiId:String = "37760:VcasLmE5"; // params for a test project I just made
	var encryptionKey:String = "blnNtJNPbE9t2JAfxM0Dpx0yMxQL4rVW";
	
	public function new() {
		
		var h = new Http("http://www.ngads.com/gateway_v2.php");
		h.onData = onRequest;
		h.onError = showError;
		h.onStatus = showStatus;
		h.setHeader("Content-type", "application/x-www-form-urlencoded"); // no idea if this does anything
		h.addParameter("tracker_id", apiId);
		h.addParameter("command_id", "preloadSettings"); // not sure if other command_ids exist
		h.request(true); // post
	}
	
	function onRequest(s:String):Void {
		Log.trace(Json.parse(s)); // I added a test medal, should come up under obj.medals
		// connected!
	}
	
	function showError(s:String):Void {
		Log.trace(s);
	}
	
	function showStatus(i:Int):Void {
		Log.trace(i);
	}
	
}