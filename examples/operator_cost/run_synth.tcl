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
    {op_srl16x23      u_srl_delay}
    {op_ffdelay16x23_reset u_ff_delay}
    {op_lutram32x8    u_lutram}
    {op_bram576x23    u_bram}
}

create_project -in_memory -part xc7z020clg484-1
read_verilog $rtl_file
synth_design -top operator_cost_all -part xc7z020clg484-1 \
    -mode out_of_context -flatten_hierarchy none

set hier_text [report_utilization -hierarchical -return_string]
set summary [open [file join $result_dir summary.tsv] w]
fconfigure $summary -translation lf
puts $summary "top\tCLB_LUT\tLUT_LOGIC\tLUTRAM\tSRL\tCARRY4\tFF\tDSP48E1\tRAMB36E1\tRAMB18E1"

foreach block $blocks {
    lassign $block top inst
    set block_cells [get_cells -hier -filter "NAME =~ $inst/*"]
    set carry_n [llength [filter $block_cells {REF_NAME == CARRY4}]]
    set found 0
    set pattern [format {^\|\s+%s\s+\|[^|]*\|\s*([0-9]+)\s*\|\s*([0-9]+)\s*\|\s*([0-9]+)\s*\|\s*([0-9]+)\s*\|\s*([0-9]+)\s*\|\s*([0-9]+)\s*\|\s*([0-9]+)\s*\|\s*([0-9]+)\s*\|} $inst]
    foreach line [split $hier_text "\n"] {
        if {[regexp $pattern $line match lut_n logic_n lutram_n srl_n ff_n r36_n r18_n dsp_n]} {
            set found 1
            break
        }
    }
    if {!$found} {
        error "Could not parse hierarchical utilization for $inst"
    }
    puts $summary "$top\t$lut_n\t$logic_n\t$lutram_n\t$srl_n\t$carry_n\t$ff_n\t$dsp_n\t$r36_n\t$r18_n"
}

close $summary
set util_report [open [file join $result_dir operator_cost_utilization_hier.rpt] w]
fconfigure $util_report -translation lf
puts -nonewline $util_report $hier_text
close $util_report
close_project
puts "OPERATOR_COST_SYNTHESIS_PASS"
