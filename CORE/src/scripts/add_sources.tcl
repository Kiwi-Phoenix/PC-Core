# add_sources.tcl
#
# Add the files / sources to the project.

# todo: will be passed in as a parm when calling this script
set BOARD "R6"
#temp - should come thru create_project when that is run prior???
#set proj_name "Core-R6"
set proj_name "Test_Core-$BOARD"
set proj_dir "../../../test_prj"
#set proj_dir [get_property directory [current_project]]

# Set the reference directory for source file relative paths (by default the value is script directory path)
set origin_dir "."


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
#set_property -name "source_mgmt_mode"   -value "None"				-objects $obj

puts "Project created at $proj_dir"


# Set the project name
#set _xil_proj_name_ "CORE-R6"

# Create 'sources_1' fileset (if not found)
if {[string equal [get_filesets -quiet sources_1] ""]} {
  create_fileset -srcset sources_1
}

set fs [get_filesets sources_1]

if { $BOARD eq "R6" } {		
	add_files -fileset sources_1 [glob ../top/top_mega65-r6.vhd]
	set file "top_mega65-r6.vhd"
	set file_obj [get_files -of_objects [get_filesets sources_1] [list $file]]
	set_property -name "file_type" -value "VHDL 2008" -objects $file_obj
	#set_property top_file $file $fs
	#set_property top_file "../top/top_mega65-r6.vhd" $fs
	
} elseif { $BOARD eq "R3" } {
	add_files -fileset sources_1 [glob ../top/top_mega65-r3.vhd]
	set file "top_mega65-r3.vhd"
	set file_obj [get_files -of_objects [get_filesets sources_1] [list $file]]
	set_property -name "file_type" -value "VHDL 2008" -objects $file_obj
	#set_property top_file $file $fs
	
} else {
	error "Unknown board tyope: $BOARD"
}	

# Add RTL sources

# M2M files
#add_files -fileset sources_1 [glob ../vhdl/*.vhd]
#add_files -fileset sources_1 [glob ../../vhdl/*.vhd]
add_files -fileset sources_1 [glob ../../../M2M/vhdl/*.vhd]
add_files -fileset sources_1 [glob ../../../M2M/vhdl/av_pipeline/*.vhd]
add_files -fileset sources_1 [glob ../../../M2M/vhdl/av_pipeline/*.v]
add_files -fileset sources_1 [glob ../../../M2M/vhdl/controllers/**/*.vhd]
add_files -fileset sources_1 [glob ../../../M2M/vhdl/controllers/**/*.v]
add_files -fileset sources_1 [glob ../../../M2M/vhdl/controllers/**/*.sv]
add_files -fileset sources_1 [glob ../../../M2M/vhdl/i2c/*.vhd]
add_files -fileset sources_1 [glob ../../../M2M/vhdl/memory/*.vhd]
add_files -fileset sources_1 [glob ../../../M2M/vhdl/QNICE/*.vhd]
add_files -fileset sources_1 [glob ../../../M2M/QNICE/vhdl/*.vhd]

set obj [get_filesets sources_1]
set files [list \
	[file normalize "${origin_dir}/../vhdl/clk.vhd" ] \
	[file normalize "${origin_dir}/../vhdl/keyboard.vhd" ] \
	[file normalize "${origin_dir}/../vhdl/main.vhd" ] \
	[file normalize "${origin_dir}/../vhdl/mega65.vhd" ] \
	[file normalize "${origin_dir}/../vhdl/pc_core.vhd" ] \
	[file normalize "${origin_dir}/../vhdl/bram.vhd" ] \
	[file normalize "${origin_dir}/../../vhdl/config.vhd" ] \
	[file normalize "${origin_dir}/../../vhdl/globals.vhd" ] 
	]

add_files -norecurse -fileset $obj $files

# set imported_files ""
# foreach f $files {
	# lappend imported_files [import_files -fileset sources_1 $f]
# }


#set file "../../vhdl/globals.vhd"

#NB: clk.vhd to be updated and removed from this property change
set file "clk.vhd"
set file_obj [get_files -of_objects [get_filesets sources_1] [list $file]]
set_property -name "file_type" -value "VHDL 2008" -objects $file_obj

set file "globals.vhd"
set file_obj [get_files -of_objects [get_filesets sources_1] [list $file]]
set_property -name "file_type" -value "VHDL 2008" -objects $file_obj

#set file "../../vhdl/config.vhd"
set file "config.vhd"
set file_obj [get_files -of_objects [get_filesets sources_1] [list $file]]
set_property -name "file_type" -value "VHDL 2008" -objects $file_obj

#set file "../../../M2M/vhdl/vdrives.vhd"
set file "vdrives.vhd"
set file_obj [get_files -of_objects [get_filesets sources_1] [list $file]]
set_property -name "file_type" -value "VHDL 2008" -objects $file_obj





# Additonal CORE files and replacement MiSTer files

#add_files -fileset sources_1 [glob ../verilog/*.v]
add_files -fileset sources_1 [glob ../verilog/**/*.v]
#add_files -fileset sources_1 [glob ../verilog/**/**/*.v]
add_files -fileset sources_1 [glob ../verilog/*.sv]
add_files -fileset sources_1 [glob ../verilog/**/**/*.sv]


# Orig MiSTer RTL files
add_file -fileset sources_1 [glob ../RTL/*.v]
add_file -fileset sources_1 [glob ../RTL/**/*.v]
add_file -fileset sources_1 [glob ../RTL/**/**/*.v]
# add_file -fileset sources_1 [glob ../RTL/**/**/**/*.v]

add_file -fileset sources_1 [glob ../RTL/**/*.sv]
add_file -fileset sources_1 [glob ../RTL/**/**/*.vhd]

# Add Constraints
if {[string equal [get_filesets -quiet constrs_1] ""]} {
	create_fileset -constrset constrs_1
}

if { $BOARD eq "R6" } {
	add_files -fileset constrs_1 [glob ../constraints/MEGA65-R6.xdc]
} elseif { $BOARD eq "R3" } {
	add_files -fileset constrs_1 [glob ../constraints/MEGA65-R3.xdc]
} else {
	error "Unknown board type: $BOARD"
}	
add_files -fileset constrs_1 [glob ../constraints/common.xdc]
add_files -fileset constrs_1 [glob ../constraints/CORE.xdc]

update_compile_order -fileset sources_1







puts "Sources and Constraints added."

