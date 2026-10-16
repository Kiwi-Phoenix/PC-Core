# add_sources.tcl
#
# Add the files / sources to the project.

# todo: will be passed in as a parm when calling this script
set BOARD "R6"

if { $BOARD eq "R6" } {
	add_files -fileset sources_1 [glob ./src/vhld/top_mega65-r6.vhd]
	set file "./src/vhld/top_mega-r6.vhd"
	set file_obj [get_files -of_objects [get_filesets sources_1] [list "*$file"]]
	set_property -name "file_type" -value "VHDL 2008" -objects $file_obj
	
} elseif { $BOARD eq "R3" } {
	add_files -fileset sources_1 [glob ./src/vhld/top_mega65-r3.vhd]
	set file "./src.vhld/top_mega65-r3.vhd"
	set file_obj [get_files -of_objects [get_filesets sources_1] [list "*$file"]]
	set_property -name "file_type" -value "VHDL 2008" -objects $file_obj
	
} else {
	error "Unknown board tyope: $BOARD"
}	

# Add RTL sources

# M2M files
add_files -fileset sources_1 [glob ./vhdl/*.vhd]
add_files -fileset sources_1 [glob ../M2M/*.vhd]
add_files -fileset sources_1 [glob ../M2M/av_pipeline/*.vhd]
add_files -fileset sources_1 [glob ../M2M/controllers/*.vhd]
add_files -fileset sources_1 [glob ../M2M/i2c/*.vhd]
add_files -fileset sources_1 [glob ../M2M/memory/*.vhd]
add_files -fileset sources_1 [glob ../M2M/QNICE/*.vhd]

set file "./vhdl/globals.vhd"
set file_obj [get_files -of_objects [get_filesets sources_1] [list "*$file"]]
set_property -name "file_type" -value "VHDL 2008" -objects $file_obj

set file "./vhdl/config.vhd"
set file_obj [get_files -of_objects [get_filesets sources_1] [list "*$file"]]
set_property -name "file_type" -value "VHDL 2008" -objects $file_obj

set file "../M2M/vdrives.vhd"
set file_obj [get_files -of_objects [get_filesets sources_1] [list "*$file"]]
set_property -name "file_type" -value "VHDL 2008" -objects $file_obj





# Additonal CORE files and replacement MiSTer files
add_files -fileset sources_1 [glob ./src/vhld/*.vhd]
add_files -fileset sources_1 [glob ./src/verilog/*.v]
add_files -fileset sources_1 [glob ./src/verilog/*.sv]

#NB: clk.vhd to be updated and removed from this property change
set file "./src/vhdl/clk.vhd"
set file_obj [get_files -of_objects [get_filesets sources_1] [list "*$file"]]
set_property -name "file_type" -value "VHDL 2008" -objects $file_obj


# Orig MiSTer RTL files
add_file -fileset sources_1 [glob ./src/RTL/**/*.v
add_file -fileset sources_1 [glob ./src/RTL/**/*.sv
add_file -fileset sources_1 [glob ./src/RTL/**/*.vhd

# Add Constraints
if { $BOARD eq "R6" } {
	add_files -fileset constrs_1 [glob ./constraints/MEGA65-R6.xdc]
} elseif { $BOARD eq "R3" } {
	add_files -fileset constrs_1 [glob ./constraints/MEGA65-R3.xdc]
} else {
	error "Unknown board tyope: $BOARD"
}	
add_files -fileset constrs_1 [glob ./constraints/common.xdc]
add_files -fileset constrs_1 [glob ./constraints/CORE.xdc]

update_compile_order -fileset sources_1







puts "Sources and Constraints added."

