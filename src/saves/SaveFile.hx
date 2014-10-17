package saves;
import haxe.ds.StringMap;
import haxe.Http;
import haxe.io.Bytes;
import haxe.io.BytesInput;
import haxe.io.BytesOutput;
import haxe.Json;
import haxe.Utf8;
import haxe.zip.Compress;
import haxe.zip.InflateImpl;
import format.amf3.Reader;
import format.amf3.Tools;
import format.amf3.Writer;

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
	public var filePath(default, null):String;
	public var thumb(default, null):String;
	public var thumbPath(default, null):String;
	// thumb bytes, maybe abstract fromBytes/fromString
	public var description(default, null):String;
	public var keys(default, null):Array<SaveKey>;
	public var ratings(default, null):Array<SaveKey>;
	public var group(default, null):SaveGroup;
	
	public static inline var DEFAULT_ICON:String = "iVBORw0KGgoAAAANSUhEUgAAAFoAAABaCAIAAAC3ytZVAAAAAXNSR0IArs4c6QAAAARnQU1BAACxjwv8YQUAAAAJcEhZcwAADsMAAA7DAcdvqGQAAAAvSURBVHhe7cExAQAAAMKg9U9tDQ8gAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA4UQNfRgAB+7kmYgAAAABJRU5ErkJggg==";
	public static inline var ICON_WIDTH:Int = 90;
	public static inline var ICON_HEIGHT:Int = 90;
	
	public function new(fileData:Dynamic) {
		
		data = { };
		
		id = fileData.save_id;
		name = fileData.filename;
		authorId = fileData.user_id;
		authorName = fileData.user_name;
		createdDate = fileData.created;
		updatedDate = fileData.last_update;
		views = fileData.views;
		
		if (fileData.file != null) filePath = fileData.file;
		else fileData = { };
		if (fileData.thumb != null) thumbPath = fileData.thumb;
		else thumb = DEFAULT_ICON;
		
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
		API.sendEncrypted(getSaveData(), setSaveStuff);
	}
	
	public function load():Void {
		
		if (filePath != null) {
			API.log("http://www.ngads.com/" + filePath);
			var h = new Http("http://www.ngads.com/" + filePath);
			h.onData = uncompress;
			h.request(false);
		}
		if (thumbPath != null) {
			var h = new Http(API.IMAGE_FILE_PATH + thumbPath);
			h.onData = getThumbnail;
			h.onError = API.log;
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
		var o = new Reader(new BytesInput(out));
		var sm:StringMap<Dynamic> = Tools.decode(o.read());
		
		for (k in sm.keys()) {
			API.log([k, sm.get(k)]);
			Reflect.setField(data, k, sm.get(k));
		}
		
		// + extra callback
	}
	
	private function compress():String {
		
		data = {s:"175450"};
		
		var d = Tools.encode(data);
		var o = new BytesOutput();
		var i = new Writer(o);
		i.write(d);
		
		return Compress.run(o.getBytes(), 9).toHex(); // zip level compression
	}
	
	private function getSaveData():Dynamic {
		
		// log msg
		
		API.log([group.id, id, name, compress()]);
		
		return {
			command_id : "saveFile",
			group : group.id,
			save_id : id, // overwrite file: save_id: id
			filename : name,
			file : compress(),
			thumbnail : 'data:image/png;base64,$DEFAULT_ICON',
			// optional desc
			// optional status
			// optional keys
		}
	}
	
	private function setSaveStuff(s:String):Void {
		API.log(s);
		var o = Json.parse(s);
		
		if (o.success == 1) {
			group = API.getSaveGroupById(o.group_id);
			id = o.save_id;
			name = o.filename;
			filePath = o.file_url;
			thumbPath = o.thumbnail;
			// iconpath = o.icon;
		}
	}
	
	private function getThumbnail(s:String):Void {
		thumb = s;
		
		save();
	}
	
	public function setThumbnail(imgBytes:Bytes):String {
		
		var o = new BytesOutput();
		var w = new format.png.Writer(o);
		w.write(format.png.Tools.build32ARGB(ICON_WIDTH, ICON_HEIGHT, imgBytes));
		// thumbbytes
		return thumb = o.getBytes().toString();
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
	 * 
	*/
}