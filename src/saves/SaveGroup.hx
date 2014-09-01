package saves;

/**
 * ...
 * @author MSGHero
 */
class SaveGroup{

	public var name(default, null):String;
	public var id(default, null):UInt;
	public var type(default, null):SaveGroupType;
	public var keys(default, null):Array<SaveKey>;
	// var ratings:Array<SaveKey>;
	
	// var connection:APIConnection ???
	
	public function new(groupData:Dynamic) {
		
		name = groupData.group_name;
		id = groupData.group_id;
		type = groupData.group_type;
		
		keys = [];
		var keyData = (groupData.keys:Array<Dynamic>);
		if (keyData == null) keyData = [];
		for (i in 0...keyData.length) {
			keys.push(new SaveKey(keyData[i]));
			// API.log(keys[i]);
		}
		
		// groupData.ratings
	}
	
	public function getKeyById(id:UInt):SaveKey {
		for (key in keys)
			if (key.id == id) return key;
		return null;
	}
	
	public function getKey(name:String):SaveKey {
		for (key in keys)
			if (key.name == name) return key;
		return null;
	}
	
	// getRatingById:UInt->SaveRating
	// getRating:String->SaveRating
	
	// toString:Void->String
}

@:enum
abstract SaveGroupType(UInt) from Int from UInt {
	var TYPE_SYSTEM = 0;
	var TYPE_PRIVATE = 1;
	var TYPE_PUBLIC = 2;
	var TYPE_MODERATED = 3;
}