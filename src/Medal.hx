package ;

/**
 * ...
 * @author MSGHero
 */
class Medal{

	var name:String;
	var desc:String;
	var index:String;
	var unlocked:Bool;
	var secret:Bool;
	var difficulty:Int;
	var iconURL:String;
	
	static var difficulties:Array<String> = ["Easy", "Moderate", "Challenging", "Difficult", "Brutal"];
	static var points:Array<Int> = [5, 10, 25, 50, 100];
	
	public function new(medalData:Dynamic, arrayIndex:Int) {
		
		name = medalData.medal_name;
		desc = medalData.medal_description;
		index = '${arrayIndex > 9 ? "" : "0"}${arrayIndex + 1}';
		unlocked = medalData.unlocked;
		secret = medalData.secret == 1;
		difficulty = Std.int(medalData.medal_difficulty - 1);
		iconURL = medalData.medal_icon;
	}
	
	public function toString():String {
		return 'Medal: $index. $name     (${unlocked ? "unlocked" : "locked"}, ${points[difficulty]} pts, ${difficulties[difficulty]}).';
	}
	
}