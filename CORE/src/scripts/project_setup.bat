rem # Run this to set up the XPR project file for a Board
rem set BOARD=R6

rem #vivado -mode batch -source scripts/create_project.tcl -tclargs $BOARD
rem #vivado -mode batch -source scripts/add_sources.tcl -tclargs $BOARD

rem /mnt/c/AMDDesignTools/2026.1/Vivado/bin/vivado.bat -mode batch -source scripts/create_project.tcl -tclargs $BOARD

rem #source /mnt/c/AMDDesignTools/2026.1/Vivado/settings64.sh -mode batch -source scripts/create_project.tcl -tclargs $BOARD



rem C:\AMDDesignTools\2026.1\Vivado\bin\vivado.bat -mode batch -source create_project.tcl -tclargs "R6"

C:\AMDDesignTools\2026.1\Vivado\bin\vivado.bat -mode batch -source add_sources.tcl -tclargs "R6"

