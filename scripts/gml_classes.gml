// GML-Classes v1.1.0
// This script provides some OOP functionality that allows you to define classes,
// their constructor and destructor, and call parent methods in overridden methods.
// Developed by NikkoTC 2023.
// Documentation: https://github.com/Nikko-the-cat/GML-Classes/wiki

// Set this macro to "false" if you don't want to see registered classes in the output window.
#macro gml_classes_debug true

#region gmlc_private

#macro class __gmlc_keyword_class()[array_length(__gmlc_keyword_class())]=function
#macro extends ():
#macro define ()constructor
#macro super __gmlc_super[$ __gmlc_funcname_to_classname(_GMFUNCTION_)]

/// @ignore
/// @returns {Array}
function __gmlc_keyword_class()
{
	static classes = [];
	return classes;
}

/// @ignore
function __gmlc_syntax_highlights()
{
	function _constructor() {};
	function _destructor() {};
}

/// @ignore
/// @param {String} funcname
function __gmlc_funcname_to_classname(funcname)
{
	var n = string_length(funcname);
	var i = 5; // "anon_"
	while(i<n)
	{
		if(string_char_at(funcname, ++i)=="_")
		{
			return string_delete(funcname, 1, i + (n+1-i)/2);
		}
	}
	return funcname;
}

/// @ignore
function __gmlc_struct()
{
	static struct = {
		classInfos: {},
		classNames: []
	};
	return struct;
}

/// @ignore
function __gmlc_init()
{
	gml_pragma("global", "__gmlc_init()");
	
	var classInfos = __gmlc_struct().classInfos;
	
	var classFuncs = __gmlc_keyword_class();
	var classFuncsNum = array_length(classFuncs);
	for(var i=0; i<classFuncsNum; i++)
	{
		var classFunc = classFuncs[i];
		if(is_method(classFunc))
		{
			var classInst = new classFunc();
			
			var className = instanceof(classInst);
			var classInfo = __gmlc_struct().classInfos[$ className];
			if(classInfo==undefined)
			{
				classInfo = {};
				__gmlc_struct().classInfos[$ className] = classInfo;
			}
			
			var parentName = undefined;
			if(os_browser==browser_not_a_browser)
			{
				var name = instanceof(static_get(classInst));
				parentName = name!="Object" ? name : undefined;
				// Unfortunately, the class name "Object" will have to be avoided.
			}
			else
			{
				// HTML5. This solution for getting the parent's name is terrible, but it seems to be the only way.
				var str = string(static_get(static_get(classInst)));
				static constructorSubstr = "constructor : ";
				var pos = string_pos(constructorSubstr, str);
				if(pos!=0)
				{
					var digits = "";
					var k = pos + string_length(constructorSubstr);
					var c = string_char_at(str, k);
					while(c==string_digits(c))
					{
						digits += c;
						c = string_char_at(str, ++k);
					}
					
					if(digits!="")
					{
						parentName = script_get_name(real(digits));
					}
				}
			}
			
			var parentInfo = parentName!=undefined ? __gmlc_struct().classInfos[$ parentName] : undefined;
			if(parentName!=undefined && parentInfo==undefined)
			{
				parentInfo = {};
				__gmlc_struct().classInfos[$ parentName] = parentInfo;
			}
			
			array_push(__gmlc_struct().classNames, className);
			classInfo.className = className;
			classInfo.classID = asset_get_index(className);
			classInfo.parentInfo = parentInfo;
			classInfo.methodNames = [];
			classInfo.methods = {};
			
			var classVarNames = struct_get_names(classInst);
			var classVarNamesNum = array_length(classVarNames);
			for(var j=0; j<classVarNamesNum; j++)
			{
				var classVarName = classVarNames[j];
				var classVarValue = struct_get(classInst, classVarName);
				if(is_method(classVarValue))
				{
					struct_set(classInfo.methods, classVarName, classVarValue);
					array_push(classInfo.methodNames, classVarName);
				}
			}
			
			delete classInst;
		}
	}
	
	if(!gml_classes_debug)
	{
		return;
	}
	
	// Show registered classes and their methods.
	show_debug_message("\nGML-CLASSES:");
	var classNamesArr = __gmlc_struct().classNames;
	var classesNum = array_length(classNamesArr);
	for(var i=0; i<classesNum; i++)
	{
		var className = classNamesArr[i];
		var classInfo = classInfos[$ className];
		
		var parentClassInfo = classInfo.parentInfo;
		var parentClassName = parentClassInfo!=undefined ? parentClassInfo.className : undefined;
		
		var extendsStr = parentClassInfo!=undefined ? " extends " + parentClassName : "";
		show_debug_message("\tclass " + className + extendsStr);
		
		var n = array_length(classInfo.methodNames);
		for(var j=0; j<n; j++)
		{
			var methodName = classInfo.methodNames[j];
			var c = (parentClassInfo!=undefined && array_contains(parentClassInfo.methodNames, methodName)) ? "*" : "+";
			show_debug_message("\t\t"+c+" " + methodName);
		}
		
		show_debug_message("");
	}
}

#endregion

#region gmlc_functions

/// @description                                This function creates an instance of class and returns it.
/// @param {Asset.GMScript,Function} classID    The unique class ID.
/// @returns {Struct}                           The class instance struct.
/// @self any
function create(classID)
{
	var inst = new classID();
	
	var className = instanceof(inst);
	var classInfo = __gmlc_struct().classInfos[$ className];
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
					struct_set(struct, methodName, method(inst, parentInfo.methods[$ methodName]));
				}
				
				inst.__gmlc_super[$ className] = struct;
				className = parentInfo.className;
				parentInfo = parentInfo.parentInfo;
			}
		}
	}
	
	static hash = variable_get_hash("_constructor");
	var c = struct_get_from_hash(inst, hash);
	if(c)
	{
		var arr = array_create(argument_count);
		var i=0;
		repeat(argument_count)
		{
			arr[i] = argument[i];
			i++;
		}
		method_call(c, arr, 1);
	}
	
	return inst;
}

/// @description            With this function you can destroy the class instance.
/// @param {Struct} inst    The class instance struct.
/// @self any
function destroy(inst)
{
	static hash = variable_get_hash("_destructor");
	var d = struct_get_from_hash(inst, hash);
	if(d)
	{
		var arr = array_create(argument_count);
		var i=0;
		repeat(argument_count)
		{
			arr[i] = argument[i];
			i++;
		}
		method_call(d, arr, 1);
	}
	
	delete inst;
}

/// @description        This function checks if the supplied value is a class.
/// @param {Any} val    The value to check.
/// @returns {Bool}
/// @self any
function is_class(val)
{
	if(is_callable(val))
	{
		var className = script_get_name(val);
		return __gmlc_struct().classInfos[$ className]!=undefined;
	}
	return false;
}

/// @description        This function checks if the supplied value is a class instance.
/// @param {Any} val    The value to check.
/// @returns {Bool}
/// @self any
function is_class_inst(val)
{
	if(is_struct(val))
	{
		var className = instanceof(val);
		return __gmlc_struct().classInfos[$ className]!=undefined;
	}
	return false;
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
	var className = script_get_name(classID);
	var classInfo = __gmlc_struct().classInfos[$ className];
	return classInfo ? variable_clone(classInfo.methodNames) : undefined;
}

/// @description                       This function returns true if class has a given method.
/// @param {Asset.GMScript} classID    The unique class ID.
/// @param {String} methodName         The method name as a string.
/// @returns {Bool}
/// @self any
function class_has_method(classID, methodName)
{
	var className = script_get_name(classID);
	var classInfo = __gmlc_struct().classInfos[$ className];
	return classInfo ? array_contains(classInfo.methodNames, methodName) : false;
}

/// @description                 With this function you can get the class ID by its name.
/// @param {String} className    The class name as a string.
/// @returns {Asset.GMScript,Undefined,Any}
/// @self any
function find_class_by_name(className)
{
	var classInfo = __gmlc_struct().classInfos[$ className];
	return classInfo ? classInfo.classID : undefined;
}

/// @description            With this function you can get class ID of a given class instance.
/// @param {Struct} inst    The class instance struct.
/// @returns {Asset.GMScript,Undefined,Any}
/// @self any
function inst_get_class(inst)
{
	return find_class_by_name(instanceof(inst));
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

