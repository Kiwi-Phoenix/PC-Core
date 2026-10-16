# create_project.tcl
# creates the Vivado xpr project file.

set proj_name "Core-$BOARD"
#set proj_dir "./build/${proj_name}"
set proj_dir [get_property directory [current_project]]

# Delete old projevt if exists
#file delete -force $proj_dir

# Create new project
create_project $proj_name $proj_dir -part xc7a200tfbg484-2

# Set project variables
set_property -name "part" 				-value "xc7a200tfbg484-2"
set_property -name "project_type" 		-value "Default"
set_property -name "target_language"	-value "VHDL"
set_property -name "target_simulator" 	-value "XSim"

puts "Project created at $proj_dir"
