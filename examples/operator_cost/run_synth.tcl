# Vivado 2020.2 post-synthesis resource micro-benchmark.
set script_dir [file dirname [file normalize [info script]]]
set rtl_file   [file join $script_dir rtl_operator_cost.v]
set result_dir [file join $script_dir results]
file mkdir $result_dir

set blocks {
    {op_add23         u_add}
    {op_sub23         u_sub}
    {op_eq23          u_eq}
    {op_lt23          u_lt}
    {op_ge_const23    u_ge_const}
    {op_mux2_23       u_mux2}
    {op_mux4_23       u_mux4}
    {op_shift_const23 u_shift_const}
    {op_shift_var23   u_shift_var}
    {op_mul23x16      u_mul}
    {op_modsub23      u_modsub}
    {op_reduce_or13   u_reduce_or}
}

create_project -in_memory -part xc7z020clg484-1
read_verilog $rtl_file
synth_design -top operator_cost_all -part xc7z020clg484-1 \
    -mode out_of_context -flatten_hierarchy none

set summary [open [file join $result_dir summary.tsv] w]
puts $summary "top\tLUT\tCARRY4\tFF\tDSP48E1\tRAMB36E1\tRAMB18E1"

foreach block $blocks {
    lassign $block top inst
    set block_cells [get_cells -hier -filter "NAME =~ $inst/*"]
    set lut_n   [llength [filter $block_cells {REF_NAME =~ LUT*}]]
    set carry_n [llength [filter $block_cells {REF_NAME == CARRY4}]]
    set ff_n    [llength [filter $block_cells {REF_NAME =~ FD*}]]
    set dsp_n   [llength [filter $block_cells {REF_NAME == DSP48E1}]]
    set r36_n   [llength [filter $block_cells {REF_NAME == RAMB36E1}]]
    set r18_n   [llength [filter $block_cells {REF_NAME == RAMB18E1}]]
    puts $summary "$top\t$lut_n\t$carry_n\t$ff_n\t$dsp_n\t$r36_n\t$r18_n"
}

close $summary
report_utilization -hierarchical \
    -file [file join $result_dir operator_cost_utilization_hier.rpt]
close_project
puts "OPERATOR_COST_SYNTHESIS_PASS"
