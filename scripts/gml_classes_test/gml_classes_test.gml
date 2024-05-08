class MyClassA define
{
	static _constructor = function() {
		show_debug_message("MyClassA constructor");
	}
	
	static _destructor = function() {
		show_debug_message("MyClassA destructor");
	}
	
	static do_something = function() {
		show_debug_message("MyClassA do_something");
	}
}

class MyClassB extends MyClassA define
{
	static _constructor = function() {
		super._constructor();
		show_debug_message("MyClassB constructor");
	}
	
	static _destructor = function() {
		show_debug_message("MyClassB destructor");
		super._destructor();
	}
	
	static do_something = function() {
		super.do_something();
		show_debug_message("MyClassB do_something");
	}
}

class MyClassC extends MyClassB define
{
	static _constructor = function() {
		super._constructor();
		show_debug_message("MyClassC constructor");
	}
	
	static _destructor = function() {
		show_debug_message("MyClassC destructor");
		super._destructor();
	}
	
	static do_something = function() {
		super.do_something();
		show_debug_message("MyClassC do_something");
	}
}

