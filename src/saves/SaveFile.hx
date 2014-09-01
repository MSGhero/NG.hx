package saves;
import format.amf.Reader;
import haxe.Http;
import haxe.io.Bytes;
import haxe.io.BytesInput;
import haxe.Utf8;
import haxe.zip.InflateImpl;
import openfl.Lib;
import openfl.utils.ByteArray;
import openfl.utils.Endian;
import tools.AMF3Reader;
import tools.Tools;

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
	public var ratings(default, null):Array<SaveKey>;
	public var group(default, null):SaveGroup;
	
	public function new(fileData:Dynamic) {
		
		data = { };
		
		id = fileData.save_id;
		name = fileData.filename;
		authorId = fileData.user_id;
		authorName = fileData.user_name;
		Lib.trace(fileData.created);
		createdDate = fileData.created;
		updatedDate = fileData.last_update;
		views = fileData.views;
		
		file = fileData.file;
		thumb = fileData.thumb;
		
		description = fileData.description;
		group = API.getSaveGroupById(fileData.group_id);
		
		keys = [];
		var fileKeys = (fileData.keys:Array<Dynamic>);
		if (fileKeys == null) fileKeys = [];
		for (key in fileKeys) {
			keys.push(group.getKeyById(key.id));
			// key.value?
		}
		
		// ratings -> getRatingById after getting savegroup
	}
	
	public function save():Void {
		API.sendEncrypted(getSaveData()); // callback?
	}
	
	public function load():Void {
		if (file != null) {
			Lib.trace(file);
			var h = new Http("http://www.ngads.com/" + file);
			h.onData = uncompress;
			h.request(false);
		}
	}
	
	private function uncompress(s:String):Void {
		
		var a = [];
		for (i in 0...s.length) {
			a.push(Utf8.charCodeAt(s, i));
		}
		
		var b = Bytes.alloc(a.length);
		
		for (i in 0...a.length) {
			b.set(i, a[i]);
		}
		
		var out = InflateImpl.run(new BytesInput(b));
		Lib.trace(out.toHex());
		Lib.trace(out.toString());
		// FORMAT.AMF.READER.READOBJECT!!!
		// need amf3 tho, not amf0
		
		var o = new AMF3Reader(new BytesInput(out));
		Lib.trace(Tools.string(o.read()));
		/*var ba = new ByteArray();
		ba.writeUTFBytes(out.toString());
		ba.position = 0;
		var o = ba.readObject();*/
		
		
		// + extra callback
	}
	
	private function getSaveData():Dynamic {
		
		// log msg
		
		return {
			command_id:"saveFile",
			group:group.id,
			save_id:id, // overwrite file: save_id: id
			filename:name,
			// optional desc
			// optional status
			// optional keys
			// file: "binary file or text blob"?
			// thumbnail
		}
	}
	
	/*
status - 1=private, 2=shared, 3=unapproved, 4=approved
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