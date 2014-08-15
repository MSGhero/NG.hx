package saves;

/**
 * ...
 * @author MSGHero
 */
class SaveFile{

	public var data:Dynamic;
	
	public var id(default, null):UInt;
	public var name(default, null):String;
	public var authorId(default, null):UInt;
	public var authorName(default, null):String;
	public var createdDate(default, null):String;
	public var updatedDate(default, null):String;
	public var views(default, null):UInt;
	public var status(default, null):UInt;
	public var file(default, null):String;
	public var thumb(default, null):String;
	public var description(default, null):String;
	public var keys(default, null):Array<SaveKey>;
	// public var ratings(default, null):Array<SaveKey>;
	public var group(default, null):SaveGroup;
	
	public function new(fileData:Dynamic) {
		
		data = { };
		
		id = fileData.save_id;
		name = fileData.filename;
		authorId = fileData.user_id;
		authorName = fileData.user_name;
		createdDate = Date.fromTime(fileData.created).toString();
		updatedDate = Date.fromTime(fileData.last_update).toString();
		views = fileData.views;
		description = fileData.description;
		group = API.getSaveGroupById(fileData.group_id);
		
		// keys -> getKeyById after getting savegroup
		// ratings -> getRatingById after getting savegroup
	}
	
	/*
status - 1=private, 2=shared, 3=unapproved, 4=approved
file - The relative path (from http://www.ngads.com/) to the save file
thumb - The relative path (from http://www.ngads.com/) to the thumbnail image
keys - An array of key objects associated with this file, each containing the following properties:
	id - The ID of the key
	value - The value of the key
ratings - An array of rating objects attached to this file, each with the following properties:
	id - The ID of the rating
	votes - The total number of votes cast to this rating
	score - The score value of this rating
	 * 
	 * 
	 * 
	 * Methods
attachIcon:DisplayObjectContainer->Sprite // might not be needed
clone:Void->SaveFile
createIcon:IBitmapDrawable(DisplayObject & BitmapData)->Void
load:Void->Void
save:Void->Void
sendVote:String->Float->Void
toString:Void->String

Properties
_imageFilePath (static)
_saveFilePath (static)
bytesLoaded
bytesTotal
currentFile (static)
draft // unused
iconLoaded
icon
keys
ratings
readOnly

Constants
DEFAULT_ICON:BitmapData
ICON_HEIGHT = 90
ICON_WIDTH = 90
	 * 
	*/
}