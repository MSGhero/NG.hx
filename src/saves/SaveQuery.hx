package saves;
import haxe.Json;

/**
 * Sets up a query to NG's servers for save data.
 * @author MSGHero
 */
class SaveQuery{

	var conditions:Array<QueryCondition>;
	var callback:SaveQuery->Void;
	
	public var resultsPerPage:Int;
	public var page:Int;
	
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
		resultsPerPage = 30;
		page = 1;
	}
	
	public function execute(?onQueryCallback:SaveQuery->Void):Void {
		
		callback = onQueryCallback;
		
		// props
		var query:Dynamic = {
			num_results:resultsPerPage,
			page:page,
		};
		
		// randomize=1 if true, no param if false
		if (conditions.length > 0) query.file_conditions = conditions;
		
		var queryString = Json.stringify(query);
		
		var ac = new APICommand("lookupSaveFiles");
		ac.addParam("group_id", group.id).addParam("publisher_id", API.publisherId).addParam("query", queryString);
		ac.onData = setSaveFiles;
		ac.send();
	}
	
	function setSaveFiles(s:String):Void {
		
		var o = Json.parse(s);
		
		if (o.success == 1) {
			
			var i = 0;
			
			var saveFiles = (o.files:Array<Dynamic>);
			if (saveFiles == null) saveFiles = [];
			for (file in saveFiles) {
				files.push(new SaveFile(file));
			}
			files[files.length - 1].load();
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
abstract QueryField(Int) {
	var FILE_ID = 0;
	var AUTHOR_ID = 1;
	var AUTHOR_NAME = 2;
	var FILE_NAME = 3;
	var CREATED_ON = 4;
	var UPDATED_ON = 5;
	var FILE_VIEWS = 6;
	var FILE_STATUS = 7;
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