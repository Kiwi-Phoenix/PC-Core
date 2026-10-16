# Run this to set up the XPR project file for a Board
BOARD=$2

vivado -mode batch -source scripts/create_project.tcl -tclargs $BOARD
vivado -mode batch -source scripts/add_sources.tcl -tclargs $BOARD
