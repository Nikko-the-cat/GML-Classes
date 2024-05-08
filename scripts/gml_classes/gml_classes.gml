// GML-Classes v1.2.0
// Game Maker Runtime: v2024.2.163
// This script provides some OOP functionality that allows you to define classes,
// their constructor and destructor, and call parent methods in overridden methods.
// Developed by NikkoTC 2024.
// Documentation: https://github.com/Nikko-the-cat/GML-Classes/wiki

// Set this macro to "true" if you want to see registered classes in the output window.
#macro gml_classes_debug true

#region gmlc_private

#macro class __gmlc_keyword_class()[array_length(__gmlc_keyword_class())]=function
#macro extends ():
#macro define ()constructor
#macro super __gmlc_super[$ asset_get_tags(_GMFUNCTION_)[0] ]

#macro NEW __create
#macro DELETE __destroy

/// @ignore
/// @returns {Array}
function __gmlc_keyword_class()
{
	static classes = [];
	return classes;
}

/// @ignore
function __gmlc_syntax_highlight()
{
	function _constructor() {};
	function _destructor() {};
}

/// @ignore
global.__gmlc_classes = {};

/// @ignore
function __gmlc_init()
{
	gml_pragma("global", "__gmlc_init()");
	
	var structGetMethodNames = function(struct) {
		var methodNames = {
			arr: [],
			add: function(name, value) {
				if(is_method(value) && name!="constructor") array_push(arr, name);
			}
		};
		struct_foreach(struct, methodNames.add);
		return methodNames.arr;
	}
	
	var getParentStruct = function(struct) {
		if(os_browser==browser_not_a_browser)
		{
			return instanceof(struct)!="Object" ? static_get(struct) : undefined;
		}
		
		var parentStruct = static_get(struct);
		return instanceof(parentStruct)!=undefined ? parentStruct : undefined;
	}
	
	// Init classes.
	var classNames = [];
	var constructors = __gmlc_keyword_class();
	for(var i=0, n=array_length(constructors); i<n; i++)
	{
		// Init statics.
		var inst = new constructors[i]();
		var className = instanceof(inst);
		var staticStruct = static_get(inst);
		delete inst;
		
		// Write class name as a tag in the script asset of each method.
		var methodNames = structGetMethodNames(staticStruct);
		for(var j=0, m=array_length(methodNames); j<m; j++)
		{
			var methodFunc = staticStruct[$ methodNames[j]];
			if(methodFunc)
			{
				var scriptName = os_browser==browser_not_a_browser
					? script_get_name(methodFunc)
					: "gml_Script_" + script_get_name(method_get_index(methodFunc));
				asset_add_tags(scriptName, className);
			}
		}
		
		// Collect class info.
		var classID = asset_get_index(className);
		var parentStruct = getParentStruct(staticStruct);
		var parentName = "";
		if(parentStruct)
		{
			parentName = os_browser==browser_not_a_browser ? instanceof(staticStruct) : instanceof(parentStruct);
		}
		
		while(parentStruct)
		{
			var parentMethodNames = structGetMethodNames(parentStruct);
			methodNames = array_union(methodNames, parentMethodNames);
			parentStruct = getParentStruct(parentStruct);
		}
		
		var classInfo = {
			classID,
			className,
			staticStruct,
			parentName,
			parentInfo: undefined,
			methodNames
		}
		
		global.__gmlc_classes[$ className] = classInfo;
		array_push(classNames, className);
	}
	
	// Link parent infos.
	array_foreach(classNames, function(className, idx){
		var classInfo = global.__gmlc_classes[$ className];
		if(classInfo.parentName!="")
		{
			classInfo.parentInfo = global.__gmlc_classes[$ classInfo.parentName];
		}
	});
	
	// Show registered classes and their methods.
	if(gml_classes_debug)
	{
		show_debug_message("\nGML-CLASSES:");
		
		array_foreach(classNames, function(className, idx){
			var classInfo = global.__gmlc_classes[$ className];
			show_debug_message("\tclass {0}{1}{2}", className, (classInfo.parentName!="" ? " extends " : ""), classInfo.parentName);
			
			var parentMethodNames = classInfo.parentInfo ? classInfo.parentInfo.methodNames : [];
			for(var i=0, n=array_length(classInfo.methodNames); i<n; i++)
			{
				var methodName = classInfo.methodNames[i];
				show_debug_message("\t\t{0} {1}", (array_contains(parentMethodNames, methodName) ? "*" : "+"), methodName);
			}
			show_debug_message("");
		});
	}
}

#endregion

#region gmlc_functions

/// @description                                This function creates an instance of class and returns it.
/// @param {Asset.GMScript,Function} classID    The unique class ID.
/// @returns {Struct}                           The class instance struct.
/// @self any
function __create(classID)
{
	// Create a structure.
	var inst = new classID();
	
	// Initialize the "super" structure.
	var className = instanceof(inst);
	var classInfo = global.__gmlc_classes[$ className];
	if(classInfo)
	{
		var parentInfo = classInfo.parentInfo;
		if(parentInfo)
		{
			inst.__gmlc_super = {};
			while(parentInfo)
			{
				var struct = {};
				
				var i = 0;
				repeat(array_length(parentInfo.methodNames))
				{
					var methodName = parentInfo.methodNames[i++];
					struct[$ methodName] = method(inst, parentInfo.staticStruct[$ methodName]);
				}
				
				inst.__gmlc_super[$ className] = struct;
				className = parentInfo.className;
				parentInfo = parentInfo.parentInfo;
			}
		}
	}
	
	// Execute the "_constrcutor" method.
	static hash = variable_get_hash("_constructor");
	var func = struct_get_from_hash(inst, hash);
	if(func)
	{
		with(inst)
		{
			// Using switch-case instead of method_call with argument array for better performance.
			switch(argument_count)
			{
				case 1: func() break;
				case 2: func(argument[1]) break;
				case 3: func(argument[1], argument[2]) break;
				case 4: func(argument[1], argument[2], argument[3]) break;
				case 5: func(argument[1], argument[2], argument[3], argument[4]) break;
				case 6: func(argument[1], argument[2], argument[3], argument[4], argument[5]) break;
				case 7: func(argument[1], argument[2], argument[3], argument[4], argument[5], argument[6]) break;
				case 8: func(argument[1], argument[2], argument[3], argument[4], argument[5], argument[6], argument[7]) break;
				case 9: func(argument[1], argument[2], argument[3], argument[4], argument[5], argument[6], argument[7], argument[8]) break;
			}
		}
	}
	
	return inst;
}

/// @description            With this function you can destroy the class instance.
/// @param {Struct} inst    The class instance struct.
/// @self any
function __destroy(inst)
{
	// Execute the "_destructor" method.
	static hash = variable_get_hash("_destructor");
	var func = struct_get_from_hash(inst, hash);
	if(func)
	{
		with(inst)
		{
			switch(argument_count)
			{
				case 1: func() break;
				case 2: func(argument[1]) break;
				case 3: func(argument[1], argument[2]) break;
				case 4: func(argument[1], argument[2], argument[3]) break;
				case 5: func(argument[1], argument[2], argument[3], argument[4]) break;
				case 6: func(argument[1], argument[2], argument[3], argument[4], argument[5]) break;
				case 7: func(argument[1], argument[2], argument[3], argument[4], argument[5], argument[6]) break;
				case 8: func(argument[1], argument[2], argument[3], argument[4], argument[5], argument[6], argument[7]) break;
				case 9: func(argument[1], argument[2], argument[3], argument[4], argument[5], argument[6], argument[7], argument[8]) break;
			}
		}
	}
	
	delete inst;
}

/// @description        This function checks if the supplied value is a class.
/// @param {Any} val    The value to check.
/// @returns {Bool}
/// @self any
function is_class(val)
{
	return is_callable(val) ? global.__gmlc_classes[$ script_get_name(val)]!=undefined : false;
}

/// @description        This function checks if the supplied value is a class instance.
/// @param {Any} val    The value to check.
/// @returns {Bool}
/// @self any
function is_class_inst(val)
{
	return is_struct(val) ? global.__gmlc_classes[$ instanceof(val)]!=undefined : false;
}

/// @description                       This function returns the class name of a given class.
/// @param {Asset.GMScript} classID    The unique class ID.
/// @returns {String,Undefined,Any}
/// @self any
function class_get_name(classID)
{
	return script_get_name(classID);
}

/// @description                       This function returns all method names of a given class.
/// @param {Asset.GMScript} classID    The unique class ID.
/// @returns {Array<String>,Undefined,Any}
/// @self any
function class_get_method_names(classID)
{
	var classInfo = global.__gmlc_classes[$ class_get_name(classID)];
	return classInfo ? variable_clone(classInfo.methodNames) : undefined;
}

/// @description                       This function returns true if class has a given method.
/// @param {Asset.GMScript} classID    The unique class ID.
/// @param {String} methodName         The method name as a string.
/// @returns {Bool}
/// @self any
function class_has_method(classID, methodName)
{
	var classInfo = global.__gmlc_classes[$ class_get_name(classID)];
	return classInfo ? array_contains(classInfo.methodNames, methodName) : false;
}

/// @description                 With this function you can get the class ID by its name.
/// @param {String} className    The class name as a string.
/// @returns {Asset.GMScript,Undefined,Any}
/// @self any
function find_class_by_name(className)
{
	var classInfo = global.__gmlc_classes[$ className];
	return classInfo ? classInfo.classID : undefined;
}

/// @description            With this function you can get class ID of a given class instance.
/// @param {Struct} inst    The class instance struct.
/// @returns {Asset.GMScript,Undefined,Any}
/// @self any
function inst_get_class(inst)
{
	return find_class_by_name(inst_get_class_name(inst));
}

/// @description                        This function returns the class name of a given class instance.
/// @param {Struct,Id.Instance} inst    The class instance struct.
/// @returns {String}
/// @self any
function inst_get_class_name(inst)
{
	return instanceof(inst);
}

#endregion

