// GML-Classes v1.0.3
// This script adds some OOP functionality that allows you to define classes,
// their constructor and destructor, and call parent methods in overridden methods.
// Developed by NikkoTC 2021.
// Documentation: https://github.com/Nikko-the-cat/GML-Classes/wiki

#region gmlc_macroses

#macro class function
#macro extends ():
#macro define ()constructor
#macro register_as_super __gmlc_register_as_super
#macro singleton __gmlc_singleton=true

#endregion

#region gmlc_private

#macro __gmlc_constructor_name "_constructor"
#macro __gmlc_destructor_name "_destructor"

#macro __gmlc_classes_id_offset 100000
#macro __gmlc_methods_id_offset 100000
#macro __gmlc_methods_id_offset_html5 0

global.__gmlc_initialized = false;
global.__gmlc_classes = [];
global.__gmlc_methods = [];
global.__gmlc_methods_id_offset_gvar = __gmlc_classes_id_offset;
global.__gmcs_class_name_to_class_id = ds_map_create();

function __gmlc_register_class_info(class_info)
{
	global.__gmlc_classes[class_info.class_id - __gmlc_classes_id_offset] = class_info;
	global.__gmcs_class_name_to_class_id[? class_info.class_name ] = class_info.class_id;
}

function __gmlc_register_method_info(method_info)
{
	gml_pragma("forceinline");
	global.__gmlc_methods[method_info.method_id - global.__gmlc_methods_id_offset_gvar] = method_info;
}

function __gmlc_get_class_info(class_id)
{
	gml_pragma("forceinline");
	return global.__gmlc_classes[class_id - __gmlc_classes_id_offset];
}

function __gmlc_get_method_info(method_id)
{
	gml_pragma("forceinline");
	return global.__gmlc_methods[method_id - global.__gmlc_methods_id_offset_gvar];
}

function __gmlc_register_as_super(parent)
{
	gml_pragma("forceinline");
	global.__gmlc_super = parent;
}

function __gmlc_strange_fix_for_html5()
{
	function register_method() {}
	function _constructor() {}
	function _destructor() {}
	register_method(_constructor);
	register_method(_destructor);
}

function __gmlc_init_classes()
{
	gml_pragma("global", "__gmlc_init_classes()");
	
	if(global.__gmlc_initialized)
	{
		return;
	}
	global.__gmlc_initialized = true;
	
	// prepare structures
	var classes = [];
	var methods = [];
	
	var global_var_names = variable_instance_get_names(global);
	var global_var_names_num = array_length(global_var_names);
	for(var i=0; i<global_var_names_num; i++)
	{
		var global_var_name = global_var_names[i];
		var c1 = string_char_at(global_var_name, 1);
		var c2 = string_char_at(global_var_name, 2);
		
		if(c1=="c" && (c2=="_" || c2==string_upper(c2)))
		{
			var global_var_value = variable_instance_get(global, global_var_name);
			if(is_method(global_var_value))
			{
				// class
				var class_info = {
					class_name: global_var_name,
					class_id: asset_get_index(global_var_name),
					parent_id: undefined,
					single: false,
					constructor_method_id: undefined,
					destructor_method_id: undefined,
					method_ids: []
				};
				
				var class_inst = new global_var_value();
				
				var class_var_names = variable_struct_get_names(class_inst);
				var class_var_names_num = array_length(class_var_names);
				
				var single = false;
				
				for(var j=0; j<class_var_names_num; j++)
				{
					var class_var_name = class_var_names[j];
					var class_var_value = variable_struct_get(class_inst, class_var_name);
					
					if(!is_method(class_var_value) && class_var_name=="__gmlc_super")
					{
						class_info.parent_id = class_inst.__gmlc_super;
					}
					else if(!is_method(class_var_value) && class_var_name=="__gmlc_singleton")
					{
						class_info.single = class_inst.__gmlc_singleton;
					}
					else
					{
						// method
						var method_info = {
							method_name: class_var_name,
							method_id: method_get_index(class_var_value),
							method_func: class_var_value,
							parent_method_id: undefined
						};
						
						array_push(class_info.method_ids, method_info.method_id);
						array_push(methods, method_info);
					}
				}
				
				array_push(classes, class_info);
				delete class_inst;
			}
		}
	}
	
	var classes_num = array_length(classes);
	var methods_num = array_length(methods);
	
	// init private gmlc structures
	var classes_max_id = 1;
	for(var i=0; i<classes_num; i++)
	{
		var class_info = classes[i];
		if(class_info.class_id > classes_max_id)
		{
			classes_max_id = class_info.class_id;
		}
	}
	
	var methods_max_id = 1;
	for(var i=0; i<methods_num; i++)
	{
		var method_info = methods[i];
		if(method_info.method_id > methods_max_id)
		{
			methods_max_id = method_info.method_id;
		}
	}
	
	global.__gmlc_methods_id_offset_gvar = os_browser==browser_not_a_browser ? __gmlc_methods_id_offset : __gmlc_methods_id_offset_html5;
	global.__gmlc_classes = array_create(classes_max_id + 1 - __gmlc_classes_id_offset, undefined);
	global.__gmlc_methods = array_create(methods_max_id + 1 - global.__gmlc_methods_id_offset_gvar, undefined);
	
	for(var i=0; i<classes_num; i++)
	{
		__gmlc_register_class_info(classes[i]);
	}
	
	for(var i=0; i<methods_num; i++)
	{
		__gmlc_register_method_info(methods[i]);
	}
	
	// check parents are ok
	for(var i=0; i<classes_num; i++)
	{
		var class_info = classes[i];
		var parent_id = class_info.parent_id;
		if(parent_id!=undefined)
		{
			var parent_info = __gmlc_get_class_info(parent_id);
			if(parent_info==undefined)
			{
				throw("\nError in '"+class_info.class_name+"' definition.\nParent was not defined!");
			}
		}
	}
	
	// link parent methods
	for(var i=0; i<classes_num; i++)
	{
		var class_info = classes[i];
		
		var method_ids = class_info.method_ids;
		var method_num = array_length(method_ids);
		
		for(var j=0; j<method_num; j++)
		{
			var method_id = method_ids[j];
			var method_info = __gmlc_get_method_info(method_id);
			
			var parent_id = class_info.parent_id;
			while(parent_id!=undefined && method_info.parent_method_id==undefined)
			{
				var parent_class_info = __gmlc_get_class_info(parent_id);

				var parent_method_ids = parent_class_info.method_ids;
				var parent_method_num = array_length(parent_method_ids);
				for(var k=0; k<parent_method_num; k++)
				{
					var parent_method_id = parent_method_ids[k];
					var parent_method_info = __gmlc_get_method_info(parent_method_id);
					if(parent_method_info!=undefined)
					{
						if(method_info.method_name==parent_method_info.method_name)
						{
							if(method_id!=parent_method_id)
							{
								method_info.parent_method_id = parent_method_id;
							}
							else
							{
								break;
							}
						}
					}
				}
					
				parent_id = parent_class_info.parent_id;
			}
		}
	}
	
	// assign constructor end destructor
	for(var i=0; i<classes_num; i++)
	{
		var class_info = classes[i];
		
		var method_ids = class_info.method_ids;
		var methods_num = array_length(method_ids);
		for(var j=0; j<methods_num; j++)
		{
			var method_id = method_ids[j];
			var method_info = __gmlc_get_method_info(method_id);
			
			if(method_info.method_name==__gmlc_constructor_name)
			{
				class_info.constructor_method_id = method_info.method_id;
			}
			else if(method_info.method_name==__gmlc_destructor_name)
			{
				class_info.destructor_method_id = method_info.method_id;
			}
		}
	}
	
	// show registered classes and their methods
	show_debug_message("\nGML-CLASSES:");
	
	for(var i=0; i<classes_num; i++)
	{
		var class_info = classes[i];
		
		var parent_id = class_info.parent_id;
		var parent_class_info = undefined;
		if(parent_id!=undefined)
		{
			parent_class_info = __gmlc_get_class_info(parent_id);
		}
		
		if(parent_class_info==undefined)
		{
			show_debug_message("\tclass " + class_info.class_name + (class_info.single ? " [singleton]" : "") );
		}
		else
		{
			show_debug_message("\tclass " + class_info.class_name + " extends " + parent_class_info.class_name + (class_info.single ? " [singleton]" : "") );
		}
		
		var method_ids = class_info.method_ids;
		var methods_num = array_length(method_ids);
		for(var j=0; j<methods_num; j++)
		{
			var method_id = method_ids[j];
			var method_info = __gmlc_get_method_info(method_id);
			
			if(method_info.parent_method_id==undefined)
			{
				show_debug_message("\t\t+ " + method_info.method_name);
			}
			else
			{
				show_debug_message("\t\t* " + method_info.method_name);
			}
		}
		
		show_debug_message("");
	}
	
	show_debug_message("GML-CLASSES init singletons:");
	for(var i=0; i<classes_num; i++)
	{
		var class_info = classes[i];
		if(class_info.single)
		{
			var globalvarName = class_info.class_name;
			var singletonInst = create(class_info.class_id);
			variable_global_set(globalvarName, singletonInst);
			show_debug_message("\t" + globalvarName);
		}
	}
	show_debug_message("");
}

#endregion

/// @function				create(class_id, [args0..arg7]);
/// @description			This function creates an instance of class and returns it.
/// @param class_id			The unique class ID.
/// @param [arg0..arg7]		Constructor arguments.
function create(class_id)
{
	var class_info = __gmlc_get_class_info(class_id);
	var constructor_id = class_info.constructor_method_id;
	
	var inst = new class_id();
	inst.__class_id = class_id;
	if(constructor_id!=undefined)
	{
		var constructor_func = __gmlc_get_method_info(constructor_id).method_func;
		var c = method(inst, constructor_func);
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

/// @function				destroy(inst, [args0..arg7]);
/// @description			With this function you can destroy the class instance.
/// @param inst				The unique class instance ID.
/// @param [arg0..arg7]		Destructor arguments.
function destroy(inst)
{
	var class_info = __gmlc_get_class_info(inst.__class_id);
	var destructor_id = class_info.destructor_method_id;

	if(destructor_id!=undefined)
	{
		var destructor_func = __gmlc_get_method_info(destructor_id).method_func;
		var d = method(inst, destructor_func);
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

/// @function				super(method_func, [args0..arg7]);
/// @description			This function calls the parent method.
/// @param method_func		The method to call.
/// @param [arg0..arg7]		Method arguments.
function super(method_func)
{
	var result = undefined;
	
	var method_id = method_get_index(method_func);
	var method_info = __gmlc_get_method_info(method_id);
	
	if(method_info!=undefined && method_info.parent_method_id!=undefined)
	{
		var method_save = variable_struct_get(self, method_info.method_name);
		
		var parent_method_info = __gmlc_get_method_info(method_info.parent_method_id);
		variable_struct_set(self, method_info.method_name, parent_method_info.method_func);
		var pm = method(self, parent_method_info.method_func);
		
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
		
		variable_struct_set(self, method_info.method_name, method_save);
	}
	
	return result;
}

/// @function				cast(inst, class_id);
/// @description			With this function you can check if an instance is inherited from a given class.
/// @param inst				The unique class instance ID.
/// @param class_id			The unique class ID.
function cast(inst, class_id)
{
	if(inst.__class_id==class_id)
	{
		return true;
	}
	
	var class_info = __gmlc_get_class_info(inst.__class_id);
	var parent_id = class_info.parent_id;
	while(parent_id!=undefined)
	{
		if(parent_id==class_id)
		{
			return true;
		}
		
		var parent_class_info = __gmlc_get_class_info(parent_id);
		parent_id = parent_class_info.parent_id;
	}
	
	return false;
}

/// @function				is_class(val);
/// @description			This function checks if the supplied value is a class.
/// @param val				The value to check.
function is_class(val)
{
	return ( is_real(val)
		&& val >= __gmlc_classes_id_offset
		&& val < __gmlc_classes_id_offset + array_length(global.__gmlc_classes)
		&&  __gmlc_get_class_info(val) != undefined
	);
}

/// @function				class_get_name(class_id);
/// @description			This function returns the class name (as a string) by a given class ID.
/// @param class_id			The unique class ID.
function class_get_name(class_id)
{
	var class_info = __gmlc_get_class_info(class_id);
	if(class_info!=undefined)
	{
		return class_info.class_name;
	}
	return undefined;
}

/// @function				find_class_by_name(class_name);
/// @description			With this function you can get the class ID by its name.
/// @param class_name		The class name as a string.
function find_class_by_name(class_name)
{
	gml_pragma("forceinline");
	return global.__gmcs_class_name_to_class_id[? class_name];
}

/// @function				inst_get_class(inst);
/// @description			With this function you can get class ID of a given class instance.
/// @param inst				The unique class instance ID.
function inst_get_class(inst)
{
	gml_pragma("forceinline");
	return inst.__class_id;
}

/// @function				inst_get_class_name(inst);
/// @description			This function returns the class name (as a string) of a given class instance.
/// @param inst				The unique class instance ID.
function inst_get_class_name(inst)
{
	gml_pragma("forceinline");
	return class_get_name(inst.__class_id);
}
