package saves;

/**
 * ...
 * @author MSGHero
 */
class SaveKey{

	public var name(default, null):String;
	public var id(default, null):UInt;
	public var type(default, null):SaveKeyType;
	
	public function new(keyData:Dynamic) {
		name = keyData.name;
		id = keyData.id;
		type = keyData.type;
	}
	
	// validateValue:Dynamic->Dynamic ???
	
	// toString:Void->String
}

@:enum
abstract SaveKeyType(UInt) from Int from UInt {
	var TYPE_FLOAT = 1;
	var TYPE_INTEGER = 2;
	var TYPE_STRING = 3;
	var TYPE_BOOLEAN = 4;
}