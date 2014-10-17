package saves;
import haxe.Http;
import haxe.Json;
import openfl.Lib;

/**
 * ...
 * @author MSGHero
 */
class SaveQuery{

	var conditions:Array<QueryCondition>;
	var callback:SaveQuery->Void;
	
	public var files(default, null):Array<SaveFile>;
	public var group(default, null):SaveGroup;
	
	public function new(group:SaveGroup) {
		this.group = group;
		reset();
	}
	
	public function addCondition(field:QueryField, operator:QueryOperator, value:Dynamic):Void {
		conditions.push( { field:field, operator:operator, value:value } );
	}
	
	public function reset():Void {
		conditions = [];
		files = [];
	}
	
	public function execute(?onQueryCallback:SaveQuery->Void):Void {
		
		callback = onQueryCallback;
		
		var query = {
			num_results:30,
			page:1,
			first_result:0,
			randomize:false,
			file_conditions:conditions
		};
		
		var h = new Http(API.API_PATH);
		
		h.addParameter("command_id", "lookupSaveFiles");
		h.addParameter("group_id", Std.string(group.id));
		h.addParameter("query", Json.stringify(query));
		
		API.sendUnencrypted(h, setSaveFiles);
	}
	
	private function setSaveFiles(s:String):Void {
		
		var o = Json.parse(s);
		// invalid json parse input: "An internal server error has occurred..." when i have conditions
		
		if (o.success == 1) {
			
			var saveFiles = (o.files:Array<Dynamic>);
			if (saveFiles == null) saveFiles = [];
			for (file in saveFiles) {
				files.push(new SaveFile(file));
			}
		}
		
		if (callback != null) callback(this);
	}
}

typedef QueryCondition = {
	field:QueryField,
	operator:QueryOperator,
	value:Dynamic
}

@:enum
abstract QueryField(String) {
	var AUTHOR_ID = "authorId";
	var AUTHOR_NAME = "authorName";
	var CREATED_ON = "createdOn";
	var FILE_ID = "fileId";
	var FILE_NAME = "fileName";
	var FILE_STATUS = "fileStatus";
	var FILE_VIEWS = "fileViews";
	var UPDATED_ON = "updatedOn";
}

@:enum
abstract QueryOperator(String) {
	var BEGINS_WITH = "*=";
	var CONTAINS = "*";
	var ENDS_WITH = "=*";
	var EQUALS = "=";
	var GREATER_OR_EQUAL = ">=";
	var GREATER_THAN = ">";
	var LESS_OR_EQUAL = "<=";
	var LESS_THAN = "<";
	var NOT_BEGINS_WITH = "!*=";
	var NOT_CONTAINS = "!*";
	var NOT_ENDS_WITH = "!=*";
	var NOT_EQUAL = "!=";
}