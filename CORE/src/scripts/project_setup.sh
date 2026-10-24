# Run this to set up the XPR project file for a Board
BOARD=$2

#vivado -mode batch -source scripts/create_project.tcl -tclargs $BOARD
#vivado -mode batch -source scripts/add_sources.tcl -tclargs $BOARD

/mnt/c/AMDDesignTools/2026.1/Vivado/bin/vivado.bat -mode batch -source scripts/create_project.tcl -tclargs $BOARD

#source /mnt/c/AMDDesignTools/2026.1/Vivado/settings64.sh -mode batch -source scripts/create_project.tcl -tclargs $BOARD



#& 'C:\AMDDesignTools\2026.1\Vivado\bin\vivado.bat' -mode batch -source Testbench/build_hr_video_write_vio.tcl -tclargs 18 writewatch
