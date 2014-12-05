package ;
import haxe.Json;

/**
 * Medals to be unlocked.
 * @author MSGHero
 */
class Medal{

	public var name(default, null):String;
	public var desc(default, null):String;
	public var id(default, null):Int;
	public var unlocked(default, null):Bool;
	public var secret(default, null):Bool;
	public var difficulty(default, null):Int;
	public var iconURL(default, null):String;
	
	static var difficulties:Array<String> = ["Easy", "Moderate", "Challenging", "Difficult", "Brutal"];
	static var points:Array<Int> = [5, 10, 25, 50, 100];
	
	public function new(medalData:Dynamic) {
		
		name = medalData.medal_name;
		desc = medalData.medal_description;
		id = medalData.medal_id;
		unlocked = medalData.unlocked;
		secret = medalData.secret == 1;
		difficulty = Std.int(medalData.medal_difficulty - 1);
		iconURL = medalData.medal_icon;
	}
	
	public function unlockMedal():Void {
		
		if (unlocked) {
			API.log('Medal ($name) already unlocked.');
		}
		
		else {
			var ac = new APICommand("unlockMedal");
			ac.addParam("session_id", API.sessionId, true).addParam("medal_id", id, true);
			ac.onData = unlock;
			ac.send();
		}
	}
	
	function unlock(s:String):Void {
		
		var o = Json.parse(s);
		if (o.success == 1) {
			unlocked = true;
			API.log('Unlocked ${toString()}');
		}
	}
	
	public function toString():String {
		return 'Medal: $name (${unlocked ? "unlocked" : "locked"}, ${points[difficulty]} pts, ${difficulties[difficulty]}).';
	}
	
}