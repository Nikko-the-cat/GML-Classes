class PerfTestClassA define
{
	static _constructor = function() {
		Counter = 0;
	}
	
	static _destructor = function() {
		Counter = -1;
	}
	
	static do_something = function() {
		Counter++;
	}
}

class PerfTestClassB extends PerfTestClassA define
{
	static _constructor = function() {
		super._constructor();
	}
	
	static _destructor = function() {
		super._destructor();
	}
	
	static do_something = function() {
		super.do_something();
	}
}

class PerfTestClassC extends PerfTestClassB define
{
	static _constructor = function() {
		super._constructor();
	}
	
	static _destructor = function() {
		super._destructor();
	}
	
	static do_something = function() {
		super.do_something();
	}
}

function PerfTestStructA() constructor
{
	static _constructor = function() {
		Counter = 0;
	}
	
	static _destructor = function() {
		Counter = -1;
	}
	
	static do_something = function() {
		Counter++;
	}
}

function PerfTestStructB() : PerfTestStructA() constructor
{
	static _constructor_PerfTestStructA = _constructor;
	static _constructor = function() {
		_constructor_PerfTestStructA();
	}
	
	static _destructor_PerfTestStructA = _destructor;
	static _destructor = function() {
		_destructor_PerfTestStructA();
	}
	
	static do_something_PerfTestStructA = do_something;
	static do_something = function() {
		do_something_PerfTestStructA();
	}
}

function PerfTestStructC() : PerfTestStructB() constructor
{
	static _constructor_PerfTestStructB = _constructor;
	static _constructor = function() {
		_constructor_PerfTestStructB();
	}
	
	static _destructor_PerfTestStructB = _destructor;
	static _destructor = function() {
		_destructor_PerfTestStructB();
	}
	
	static do_something_PerfTestStructB = do_something;
	static do_something = function() {
		do_something_PerfTestStructB();
	}	
}

function performance_test_begin()
{
	gml_pragma("forceinline");
	global.performance_test_begin_time = get_timer();
}

function performance_test_end(msg=undefined)
{
	gml_pragma("forceinline");
	var endTime = get_timer();
	var totalTime = get_timer() - global.performance_test_begin_time;
	if(msg!=undefined) show_debug_message(msg + " : " + string(totalTime / 1000) + "ms");
	return totalTime;
}

function performance_test_show_comparison(name1, t1, name2, t2)
{
	show_debug_message("[{0}] is {1} than [{2}] in {3}x times", name1, t1>t2 ? "SLOWER" : "FASTER", name2, t1>t2 ? t1/t2 : t2/t1);
}


function new_delete_perf_test()
{
	// class
	performance_test_begin()
	repeat(100000)
	{
		var inst = NEW(PerfTestClassC);
		DELETE(inst);
	}
	var t1 = performance_test_end("new+delete call in classes");
	
	// struct
	performance_test_begin()
	repeat(100000)
	{
		var inst2 = new PerfTestStructC();
		inst2._constructor();
		
		inst2._destructor();
		delete inst2;
	}
	var t2 = performance_test_end("new+delete call in structs");
	
	//  result
	performance_test_show_comparison("new+delete call in classes", t1, "new+delete call in structs", t2);
}

function parent_method_call_perf_test()
{
	// class
	var inst = NEW(PerfTestClassC);

	performance_test_begin()
	repeat(100000) inst.do_something();
	var t1 = performance_test_end("parent method call in classes");

	DELETE(inst);
	
	// struct
	var inst2 = new PerfTestStructC();
	inst2._constructor();
	
	performance_test_begin()
	repeat(100000) inst2.do_something();
	var t2 = performance_test_end("parent method call in structs");
	
	inst2._destructor();
	delete inst2;
	
	//  result
	performance_test_show_comparison("parent method call in classes", t1, "parent method call in structs", t2);
}

function perf_test_total()
{
	// class
	performance_test_begin()
	repeat(100000)
	{
		var inst = NEW(PerfTestClassC);
		inst.do_something();
		DELETE(inst);
	}
	var t1 = performance_test_end("CLASSES");
	
	// struct
	performance_test_begin()
	repeat(100000)
	{
		var inst2 = new PerfTestStructC();
		inst2._constructor();
		inst2.do_something();
		inst2._destructor();
		delete inst2;
	}
	var t2 = performance_test_end("STRUCTS");
	
	//  result
	performance_test_show_comparison("CLASSES", t1, "STRUCTS", t2);
}

function gml_classes_performance_test()
{
	new_delete_perf_test();
	parent_method_call_perf_test();
	perf_test_total();
}

