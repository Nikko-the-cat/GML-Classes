
show_debug_message("\nGML-Classes test begin\n");

var inst = NEW(MyClassC);

inst.do_something();

DELETE(inst);

show_debug_message("\nGML-Classes test end\n");


gml_classes_performance_test();

