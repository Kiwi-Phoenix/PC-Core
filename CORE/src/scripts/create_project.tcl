# create_project.tcl
# creates the Vivado xpr project file.

#set proj_name "Core-$BOARD"
set proj_name "Core-R6"
#set proj_dir "./build/${proj_name}"
#set proj_dir [get_property directory [current_project]]
#set proj_dir [get_property directory [D:\retro\sourcetree\repos\pc-core\core\]]

set proj_dir "../../../test_prj"



# Delete old project if exists
file delete -force $proj_dir

# Create new project
create_project $proj_name $proj_dir -part xc7a200tfbg484-2

# Set project variables
set obj [current_project]
set_property -name "part" 				-value "xc7a200tfbg484-2" 	-objects $obj
set_property -name "project_type" 		-value "Default" 			-objects $obj
set_property -name "target_language"	-value "VHDL" 				-objects $obj
set_property -name "target_simulator" 	-value "XSim" 				-objects $obj

puts "Project created at $proj_dir"
