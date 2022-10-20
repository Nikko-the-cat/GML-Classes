// GML-Classes v1.0.5
// This script adds some OOP functionality that allows you to define classes,
// their constructor and destructor, and call parent methods in overridden methods.
// Developed by NikkoTC 2022.
// Documentation: https://github.com/Nikko-the-cat/GML-Classes/wiki

#region gmlc_macroses

#macro class function
#macro extends ():
#macro define ()constructor
#macro register_as_super __gmlc_register_as_super
#macro singleton __gmlc_register_as_singleton()

#endregion

#region gmlc_private

global.gmlc = {
	constructorName: "_constructor",
	destructorName: "_destructor",
	classesIDOffset: 100000,
	methodsIDOffsetDefault: 100000,
	methodsIDOffsetHTML5: 0,
	
	initialized: false,
	classes: [],
	methods: [],
	methodsIDOffset: 100000,
	classNameToClassID: ds_map_create()
};

#macro GMLC global.gmlc

/// @ignore
/// @param {String} str
/// @returns {Bool}
function __gmlc_string_has_class_prefix(str)
{
	// c_ or cls_ or cX, where X is any upper character
	var c1 = string_char_at(str, 1);
	var c2 = string_char_at(str, 2);
	return (
		( c1=="c" && (c2=="_" || c2==string_upper(c2)) ) ||
		( c1=="c" && c2=="l" && string_char_at(str,3)=="s" && string_char_at(str,4)=="_")
	);
}

/// @ignore
/// @param {Struct.GMLCClassInfo} classInfo
function __gmlc_register_class_info(classInfo)
{
	GMLC.classes[classInfo.classID - GMLC.classesIDOffset] = classInfo;
	GMLC.classNameToClassID[? classInfo.className ] = classInfo.classID;
}

/// @ignore
/// @param {Struct.GMLCMethodInfo} methodInfo
function __gmlc_register_method_info(methodInfo)
{
	gml_pragma("forceinline");
	GMLC.methods[methodInfo.methodID - GMLC.methodsIDOffset] = methodInfo;
}

/// @ignore
/// @param {Asset.GMScript} classID
/// @returns {Struct.GMLCClassInfo,Undefined}
function __gmlc_get_class_info(classID)
{
	gml_pragma("forceinline");
	return GMLC.classes[classID - GMLC.classesIDOffset];
}

/// @ignore
/// @param {Asset.GMScript} methodID
/// @returns {Struct.GMLCMethodInfo,Undefined}
function __gmlc_get_method_info(methodID)
{
	gml_pragma("forceinline");
	return GMLC.methods[methodID - GMLC.methodsIDOffset];
}

/// @ignore
/// @param {Any} parent
function __gmlc_register_as_super(parent)
{
	gml_pragma("forceinline");
	gmlcSUPER = parent;
}

/// @ignore
function __gmlc_register_as_singleton()
{
	gml_pragma("forceinline");
	gmlcSINGLETON = true;
}

/// @ignore
/// @param {Any} classID    The unique class ID.
/// @returns {Struct}
function __gmlc_create_inst(classID)
{
	gml_pragma("forceinline");
	return new classID();
}

/// @ignore
/// @returns {Struct,Id.Instance}
function __gmlc_self_struct()
{
	gml_pragma("forceinline");
	return self;
}

/// @ignore
function __gmlc_constructor_and_destructor_highlight()
{
	function _constructor() {}
	function _destructor() {}
}

/// @ignore
/// @param {String} className
function GMLCClassInfo(className) constructor
{
	self.className = className;
	self.classID = asset_get_index(className);
	self.parentClassID = undefined;
	self.single = false;
	self.constructorMethodID = undefined;
	self.destructorMethodID = undefined;
	self.methodIDs = [];
}

/// @ignore
/// @param {String} methodName
/// @param {Function} methodFunc
function GMLCMethodInfo(methodName, methodFunc, parentMethodId=undefined) constructor
{
	self.methodName = methodName;
	self.methodID = method_get_index(methodFunc);
	self.methodFunc = methodFunc;
	self.parentMethodID = parentMethodId;
}

/// @ignore
function __gmlc_init_classes()
{
	gml_pragma("global", "__gmlc_init_classes()");
	
	if(GMLC.initialized)
	{
		return;
	}
	GMLC.initialized = true;
	
	// prepare structures
	var classes = [];
	var methods = [];
	
	var globalVarNames = variable_struct_get_names(global);
	var globalVarNamesNum = array_length(globalVarNames);
	for(var i=0; i<globalVarNamesNum; i++)
	{
		var globalVarName = globalVarNames[i];
		if(__gmlc_string_has_class_prefix(globalVarName))
		{
			var globalVarValue = variable_struct_get(global, globalVarName);
			if(is_method(globalVarValue))
			{
				// class
				var classInfo = new GMLCClassInfo(globalVarName);
				
				var classInst = new globalVarValue();
				
				var classVarNames = variable_struct_get_names(classInst);
				var classVarNamesNum = array_length(classVarNames);
				for(var j=0; j<classVarNamesNum; j++)
				{
					var classVarName = classVarNames[j];
					var classVarValue = variable_struct_get(classInst, classVarName);
					
					if(!is_method(classVarValue) && classVarName=="gmlcSUPER")
					{
						classInfo.parentClassID = classInst.gmlcSUPER;
					}
					else if(!is_method(classVarValue) && classVarName=="gmlcSINGLETON")
					{
						classInfo.single = classInst.gmlcSINGLETON;
					}
					else
					{
						// method
						var methodInfo = new GMLCMethodInfo(classVarName, classVarValue);
						array_push(classInfo.methodIDs, methodInfo.methodID);
						array_push(methods, methodInfo);
					}
				}
				
				array_push(classes, classInfo);
				delete classInst;
			}
		}
	}
	
	var classesNum = array_length(classes);
	var methodsNum = array_length(methods);
	
	// init private gmlc structures
	var classesMaxID = 1;
	for(var i=0; i<classesNum; i++)
	{
		var classInfo = classes[i];
		if(classInfo.classID > classesMaxID)
		{
			classesMaxID = classInfo.classID;
		}
	}
	
	var methodsMaxID = 1;
	for(var i=0; i<methodsNum; i++)
	{
		var methodInfo = methods[i];
		if(methodInfo.methodID > methodsMaxID)
		{
			methodsMaxID = methodInfo.methodID;
		}
	}
	
	GMLC.methodsIDOffset = os_browser==browser_not_a_browser ? GMLC.methodsIDOffsetDefault : GMLC.methodsIDOffsetDefaultHTML5;
	GMLC.classes = array_create(classesMaxID + 1 - GMLC.classesIDOffset, undefined);
	GMLC.methods = array_create(methodsMaxID + 1 - GMLC.methodsIDOffset, undefined);
	
	for(var i=0; i<classesNum; i++)
	{
		__gmlc_register_class_info(classes[i]);
	}
	
	for(var i=0; i<methodsNum; i++)
	{
		__gmlc_register_method_info(methods[i]);
	}
	
	// check parents are ok
	for(var i=0; i<classesNum; i++)
	{
		var classInfo = classes[i];
		var parentClassID = classInfo.parentClassID;
		if(parentClassID!=undefined)
		{
			var parentClassInfo = __gmlc_get_class_info(parentClassID);
			if(parentClassInfo==undefined)
			{
				throw("\nError in '"+classInfo.className+"' definition.\nParent was not defined!");
			}
		}
	}
	
	// link parent methods
	for(var i=0; i<classesNum; i++)
	{
		var classInfo = classes[i];
		
		var methodIDs = classInfo.methodIDs;
		var methodNum = array_length(methodIDs);
		
		for(var j=0; j<methodNum; j++)
		{
			var methodID = methodIDs[j];
			var methodInfo = __gmlc_get_method_info(methodID);
			
			var parentClassID = classInfo.parentClassID;
			while(parentClassID!=undefined && methodInfo.parentMethodID==undefined)
			{
				var parentClassInfo = __gmlc_get_class_info(parentClassID);
				
				var parentMethodIDs = parentClassInfo.methodIDs;
				var parentMethodNum = array_length(parentMethodIDs);
				for(var k=0; k<parentMethodNum; k++)
				{
					var parentMethodID = parentMethodIDs[k];
					var parentMethodInfo = __gmlc_get_method_info(parentMethodID);
					if(parentMethodInfo!=undefined)
					{
						if(methodInfo.methodName==parentMethodInfo.methodName)
						{
							if(methodID!=parentMethodID)
							{
								methodInfo.parentMethodID = parentMethodID;
							}
							else
							{
								break;
							}
						}
					}
				}
					
				parentClassID = parentClassInfo.parentClassID;
			}
		}
	}
	
	// assign constructor end destructor
	for(var i=0; i<classesNum; i++)
	{
		var classInfo = classes[i];
		
		var methodIDs = classInfo.methodIDs;
		var n = array_length(methodIDs);
		for(var j=0; j<n; j++)
		{
			var methodID = methodIDs[j];
			var methodInfo = __gmlc_get_method_info(methodID);
			
			if(methodInfo.methodName==GMLC.constructorName)
			{
				classInfo.constructorMethodID = methodInfo.methodID;
			}
			else if(methodInfo.methodName==GMLC.destructorName)
			{
				classInfo.destructorMethodID = methodInfo.methodID;
			}
		}
	}
	
	// show registered classes and their methods
	show_debug_message("\nGML-CLASSES:");
	
	for(var i=0; i<classesNum; i++)
	{
		var classInfo = classes[i];
		
		var parentClassID = classInfo.parentClassID;
		var parentClassInfo = undefined;
		if(parentClassID!=undefined)
		{
			parentClassInfo = __gmlc_get_class_info(parentClassID);
		}
		
		if(parentClassInfo==undefined)
		{
			show_debug_message("\tclass " + classInfo.className + (classInfo.single ? " [singleton]" : "") );
		}
		else
		{
			show_debug_message("\tclass " + classInfo.className + " extends " + parentClassInfo.className + (classInfo.single ? " [singleton]" : "") );
		}
		
		var methodIDs = classInfo.methodIDs;
		var n = array_length(methodIDs);
		for(var j=0; j<n; j++)
		{
			var methodID = methodIDs[j];
			var methodInfo = __gmlc_get_method_info(methodID);
			
			if(methodInfo.parentMethodID==undefined)
			{
				show_debug_message("\t\t+ " + methodInfo.methodName);
			}
			else
			{
				show_debug_message("\t\t* " + methodInfo.methodName);
			}
		}
		
		show_debug_message("");
	}
	
	show_debug_message("GML-CLASSES init singletons:");
	for(var i=0; i<classesNum; i++)
	{
		var classInfo = classes[i];
		if(classInfo.single)
		{
			var globalvarName = classInfo.className;
			var singletonInst = create(classInfo.classID);
			variable_global_set(globalvarName, singletonInst);
			show_debug_message("\t" + globalvarName);
		}
	}
	show_debug_message("");
}

#endregion

#region gmlc_functions

/// @description                                     This function creates an instance of class and returns it.
/// @param {Asset.GMScript,Function,Real} classID    The unique class ID.
/// @returns {Struct}
/// @self any
function create(classID)
{
	var classInfo = __gmlc_get_class_info(classID);
	var constructorMethodID = classInfo.constructorMethodID;
	
	//var inst = new classID();
	var inst = __gmlc_create_inst(classID);
	inst.gmlcCLASS = classID;
	if(constructorMethodID!=undefined)
	{
		var constructorFunc = __gmlc_get_method_info(constructorMethodID).methodFunc;
		var c = method(inst, constructorFunc);
		with(inst)
		{
			switch(argument_count)
			{
				case 1: c(); break;
				case 2: c(argument[1]); break;
				case 3: c(argument[1], argument[2]); break;
				case 4: c(argument[1], argument[2], argument[3]); break;
				case 5: c(argument[1], argument[2], argument[3], argument[4]); break;
				case 6: c(argument[1], argument[2], argument[3], argument[4], argument[5]); break;
				case 7: c(argument[1], argument[2], argument[3], argument[4], argument[5], argument[6]); break;
				case 8: c(argument[1], argument[2], argument[3], argument[4], argument[5], argument[6], argument[7]); break;
				case 9: c(argument[1], argument[2], argument[3], argument[4], argument[5], argument[6], argument[7], argument[8]); break;
			}
		}
	}
	
	return inst;
}

/// @description            With this function you can destroy the class instance.
/// @param {Struct} inst    The unique class instance ID.
/// @self any
function destroy(inst)
{
	var classInfo = __gmlc_get_class_info(inst.gmlcCLASS);
	var destructorMethodID = classInfo.destructorMethodID;

	if(destructorMethodID!=undefined)
	{
		var destructorFunc = __gmlc_get_method_info(destructorMethodID).methodFunc;
		var d = method(inst, destructorFunc);
		with(inst)
		{
			switch(argument_count)
			{
				case 1: d(); break;
				case 2: d(argument[1]); break;
				case 3: d(argument[1], argument[2]); break;
				case 4: d(argument[1], argument[2], argument[3]); break;
				case 5: d(argument[1], argument[2], argument[3], argument[4]); break;
				case 6: d(argument[1], argument[2], argument[3], argument[4], argument[5]); break;
				case 7: d(argument[1], argument[2], argument[3], argument[4], argument[5], argument[6]); break;
				case 8: d(argument[1], argument[2], argument[3], argument[4], argument[5], argument[6], argument[7]); break;
				case 9: d(argument[1], argument[2], argument[3], argument[4], argument[5], argument[6], argument[7], argument[8]); break;
			}
		}
	}
	
	delete inst;
}

/// @description                    This function calls the parent method.
/// @param {Function} methodFunc    The method to call.
/// @returns {Any}
/// @self any
function super(methodFunc)
{
	var result = undefined;
	
	var methodID = method_get_index(methodFunc);
	var methodInfo = __gmlc_get_method_info(methodID);
	
	if(methodInfo!=undefined && methodInfo.parentMethodID!=undefined)
	{
		var this = __gmlc_self_struct(); // self
		var methodSave = variable_struct_get(this, methodInfo.methodName);
		
		var parentMethodInfo = __gmlc_get_method_info(methodInfo.parentMethodID);
		variable_struct_set(this, methodInfo.methodName, parentMethodInfo.methodFunc);
		var pm = method(this, parentMethodInfo.methodFunc);
		
		switch(argument_count)
		{ 
			case 1: result = pm(); break;
			case 2: result = pm(argument[1]); break;
			case 3: result = pm(argument[1], argument[2]); break;
			case 4: result = pm(argument[1], argument[2], argument[3]); break;
			case 5: result = pm(argument[1], argument[2], argument[3], argument[4]); break;
			case 6: result = pm(argument[1], argument[2], argument[3], argument[4], argument[5]); break;
			case 7: result = pm(argument[1], argument[2], argument[3], argument[4], argument[5], argument[6]); break;
			case 8: result = pm(argument[1], argument[2], argument[3], argument[4], argument[5], argument[6], argument[7]); break;
			case 9: result = pm(argument[1], argument[2], argument[3], argument[4], argument[5], argument[6], argument[7], argument[8]); break;
		}
		
		variable_struct_set(this, methodInfo.methodName, methodSave);
	}
	
	return result;
}

/// @description                         With this function you can check if an instance is inherited from a given class.
/// @param {Struct,Id.Instance} inst    The unique class instance ID.
/// @param {Asset.GMScript} classID      The unique class ID.
/// @returns {Bool}
/// @self any
function cast(inst, classID)
{
	if(inst.gmlcCLASS==classID)
	{
		return true;
	}
	
	var classInfo = __gmlc_get_class_info(inst.gmlcCLASS);
	var parentClassID = classInfo.parentClassID;
	while(parentClassID!=undefined)
	{
		if(parentClassID==classID)
		{
			return true;
		}
		
		var parentClassInfo = __gmlc_get_class_info(parentClassID);
		parentClassID = parentClassInfo.parentClassID;
	}
	
	return false;
}

/// @description        This function checks if the supplied value is a class.
/// @param {Any} val    The value to check.
/// @returns {Bool}
/// @self any
function is_class(val)
{
	return ( is_real(val)
		&& val >= GMLC.classesIDOffset
		&& val < GMLC.classesIDOffset + array_length(GMLC.classes)
		&& __gmlc_get_class_info(val) != undefined
	);
}

/// @description        This function checks if the supplied value is a class instance.
/// @param {Any} val    The value to check.
/// @returns {Bool}
/// @self any
function is_class_inst(val)
{
	return ( is_struct(val)
		&& variable_struct_exists(val, "gmlcCLASS")
	);
}

/// @description                       This function returns the class name (as a string) of a given class.
/// @param {Asset.GMScript} classID    The unique class ID.
/// @returns {String}
/// @self any
function class_get_name(classID)
{
	var classInfo = __gmlc_get_class_info(classID);
	if(classInfo!=undefined)
	{
		return classInfo.className;
	}
	return "";
}

/// @description                       This function returns all method names of class (as array of string) of a given class.
/// @param {Asset.GMScript} classID    The unique class ID.
/// @returns {Array<Any>,Undefined}
/// @self any
function class_get_method_names(classID)
{
	var classInfo = __gmlc_get_class_info(classID);
	if(classInfo!=undefined)
	{
		var arr = [];
		var methodIDs = classInfo.methodIDs;
		var n = array_length(methodIDs);
		for(var i=0; i<n; i++)
		{
			var methodInfo = __gmlc_get_method_info(methodIDs[i]);
			array_push(arr, methodInfo.methodName);
		}
		return arr;
	}
	return undefined;
}

/// @description                       This function returns true if class has a given method.
/// @param {Asset.GMScript} classID    The unique class ID.
/// @param {String} methodName         The method name as a string.
/// @returns {Bool}
/// @self any
function class_has_method(classID, methodName)
{
	var arr = class_get_method_names(classID);
	if(arr!=undefined)
	{
		var n = array_length(arr);
		for(var i=0; i<n; i++)
		{
			if(arr[i]==methodName)
			{
				return true;
			}
		}
	}
	return false;
}

/// @description                 With this function you can get the class ID by its name.
/// @param {String} className    The class name as a string.
/// @returns {Asset.GMScript,Undefined}
/// @self any
function find_class_by_name(className)
{
	gml_pragma("forceinline");
	return GMLC.classNameToClassID[? className];
}

/// @description                        With this function you can get class ID of a given class instance.
/// @param {Struct,Id.Instance} inst    The unique class instance ID.
/// @returns {Asset.GMScript,Undefined,Any}
/// @self any
function inst_get_class(inst)
{
	if(is_class_inst(inst))
	{
		return inst.gmlcCLASS;
	}
	return undefined;
}

/// @description                        This function returns the class name (as a string) of a given class instance.
/// @param {Struct,Id.Instance} inst    The unique class instance ID.
/// @returns {String}
/// @self any
function inst_get_class_name(inst)
{
	gml_pragma("forceinline");
	return class_get_name(inst.gmlcCLASS);
}

#endregion

