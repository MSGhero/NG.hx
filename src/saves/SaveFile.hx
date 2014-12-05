package saves;
import format.amf3.Reader;
import format.amf3.Tools;
import format.amf3.Writer;
import haxe.ds.StringMap;
import haxe.Http;
import haxe.io.Bytes;
import haxe.io.BytesInput;
import haxe.io.BytesOutput;
import haxe.Json;
import haxe.zip.Compress;
import haxe.zip.Uncompress;

/**
 * Stores save data from NG's servers.
 * @author MSGHero
 */
class SaveFile{

	public var data:Dynamic;
	
	public var id(default, null):UInt;
	public var name:String;
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
	
	// needed?
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
		
		if (data == null) data = { };
		
		// encodeData
		// preEncodeObject for bmds
		// encodeObject
		
		var ac = new APICommand("saveFile");
		
		ac.addParam("group", group.id, true).addParam("user_name", API.username, true).addParam("filename", name, true).addParam("description", description, true);
		if (id != -1) ac.addParam("save_id", id, true).addParam("overwrite", true, true);
		// draft?, keys, ratings
		ac.addFile("file", compress(), "file");
		
		// if icon loaded
		// ac.addFile("thumbnail", Bytes.ofString(thumb), "thumbnail"); maybe
		
		ac.onData = setStuff;
		ac.onError = API.log;
		ac.send();
		
		// callback
	}
	
	public function load():Void {
		
		if (filePath != null) {
			var h = new Http("http://www.ngads.com/" + filePath);
			h.onData = uncompress;
			h.onError = API.log;
			h.request(false);
		}
		if (thumbPath != null) {
			var h = new Http(API.IMAGE_FILE_PATH + thumbPath);
			h.onData = getThumbnail;
			h.onError = API.log;
			h.request(false);
		}
	}
	
	function uncompress(s:String):Void {
		
		// there are issues with callback data including 0x00 bytes, have to replace haxe.Http (bleh)
		var o = new Reader(new BytesInput(Uncompress.run(Bytes.ofString(s))));
		var d:Dynamic = Tools.decode(o.read());
		
		if (Std.is(d, StringMap)) {
			
			var sm:StringMap<Dynamic> = d;
			
			for (k in sm.keys()) {
				Reflect.setField(data, k, sm.get(k));
			}
		}
		
		else {
			data = d;
		}
		
		// + extra callback
	}
	
	function compress():Bytes {
		
		var o = new BytesOutput();
		var i = new Writer(o);
		i.write(Tools.encode(data));
		
		return Compress.run(o.getBytes(), 9);
	}
	
	function setStuff(s:String):Void {
		
		var o = Json.parse(s);
		if (o.success == 1) {
			
			group = API.getSaveGroupById(o.group_id);
			id = o.save_id;
			name = o.filename;
			filePath = o.file_url;
			thumbPath = o.thumbnail;
			// 50x50 icon location
		}
	}
	
	// idk
	function getThumbnail(s:String):Void {
		thumb = s;
		// var b = Bytes.ofString(s);
		//save();
	}
	
	public function setThumbnail(imgBytes:Bytes):String {
		
		var o = new BytesOutput();
		var w = new format.png.Writer(o);
		w.write(format.png.Tools.build32ARGB(ICON_WIDTH, ICON_HEIGHT, imgBytes));
		// thumbbytes?
		return thumb = o.getBytes().toString();
	}
}

// need to figure out how to represent images (w,h,pixels or png encoded string?)

/*
 * not implemented yet:
 * 
 * status - 1=private, 2=shared, 3=unapproved, 4=approved
 * keys - An array of key objects associated with this file, each containing the following properties:
	 * id - The ID of the key
	 * value - The value of the key
 * ratings - An array of rating objects attached to this file, each with the following properties:
	 * id - The ID of the rating
	 * votes - The total number of votes cast to this rating
	 * score - The score value of this rating
 * attachIcon:DisplayObjectContainer->Sprite // might not be needed
 * clone:Void->SaveFile
 * createIcon:IBitmapDrawable(DisplayObject & BitmapData)->Void
 * sendVote:String->Float->Void
 * toString:Void->String
 * _imageFilePath (static)
 * _saveFilePath (static)
 * bytesLoaded
 * bytesTotal
 * currentFile (static)
 * draft // unused
 * iconLoaded
 * icon
 * keys
 * ratings
 * readOnly 
*/