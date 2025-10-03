# Definitional proc to organize widgets for parameters.
proc init_gui { IPINST } {
  ipgui::add_param $IPINST -name "Component_Name"
  #Adding Page
  set Page_0 [ipgui::add_page $IPINST -name "Page 0"]
  set DATA_WIDTH [ipgui::add_param $IPINST -name "DATA_WIDTH" -parent ${Page_0}]
  set_property tooltip {Axis tdata bus width} ${DATA_WIDTH}
  set ID_WIDTH [ipgui::add_param $IPINST -name "ID_WIDTH" -parent ${Page_0}]
  set_property tooltip {Axis tid bus width} ${ID_WIDTH}
  set TKEEP_WIDTH [ipgui::add_param $IPINST -name "TKEEP_WIDTH" -parent ${Page_0}]
  set_property tooltip {Axis tkeep bus width} ${TKEEP_WIDTH}


}

proc update_PARAM_VALUE.DATA_WIDTH { PARAM_VALUE.DATA_WIDTH } {
	# Procedure called to update DATA_WIDTH when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.DATA_WIDTH { PARAM_VALUE.DATA_WIDTH } {
	# Procedure called to validate DATA_WIDTH
	return true
}

proc update_PARAM_VALUE.ID_WIDTH { PARAM_VALUE.ID_WIDTH } {
	# Procedure called to update ID_WIDTH when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.ID_WIDTH { PARAM_VALUE.ID_WIDTH } {
	# Procedure called to validate ID_WIDTH
	return true
}

proc update_PARAM_VALUE.TKEEP_WIDTH { PARAM_VALUE.TKEEP_WIDTH } {
	# Procedure called to update TKEEP_WIDTH when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.TKEEP_WIDTH { PARAM_VALUE.TKEEP_WIDTH } {
	# Procedure called to validate TKEEP_WIDTH
	return true
}


proc update_MODELPARAM_VALUE.ID_WIDTH { MODELPARAM_VALUE.ID_WIDTH PARAM_VALUE.ID_WIDTH } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.ID_WIDTH}] ${MODELPARAM_VALUE.ID_WIDTH}
}

proc update_MODELPARAM_VALUE.DATA_WIDTH { MODELPARAM_VALUE.DATA_WIDTH PARAM_VALUE.DATA_WIDTH } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.DATA_WIDTH}] ${MODELPARAM_VALUE.DATA_WIDTH}
}

proc update_MODELPARAM_VALUE.TKEEP_WIDTH { MODELPARAM_VALUE.TKEEP_WIDTH PARAM_VALUE.TKEEP_WIDTH } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.TKEEP_WIDTH}] ${MODELPARAM_VALUE.TKEEP_WIDTH}
}

