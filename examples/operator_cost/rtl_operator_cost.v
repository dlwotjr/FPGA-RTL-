//============================================================================
//
//  AUTHOR      : JaeSeok Lee
//  SPEC        : Small RTL operators for post-synthesis resource experiments
//  HISTORY     : 2026-09-07
//
//  Copyright (c) 2026 Crypto & Security Engineering Laboratory. MIT license
//
//============================================================================

module operator_cost_all (
    input  wire         clk,
    input  wire         rst,
    input  wire         ce,
    input  wire         mem_we,
    input  wire [22:0]  a,
    input  wire [22:0]  b,
    input  wire [22:0]  c,
    input  wire [22:0]  d,
    input  wire [22:0]  q,
    input  wire [4:0]   sh,
    input  wire [1:0]   sel,
    input  wire [9:0]   mem_waddr,
    input  wire [9:0]   mem_raddr,
    input  wire [7:0]   mem_din,
    output wire [280:0] observed
);
    wire [22:0] add_y, sub_y, mux2_y, mux4_y;
    wire [22:0] shift_const_y, shift_var_y, modsub_y;
    wire [38:0] mul_y;
    wire eq_y, lt_y, ge_const_y, reduce_or_y;
    wire [22:0] srl_delay_y, ff_delay_y, bram_y;
    wire [7:0] lutram_y;

    (* keep_hierarchy = "yes", dont_touch = "true" *)
    op_add23 u_add (.clk(clk), .a(a), .b(b), .y(add_y));
    (* keep_hierarchy = "yes", dont_touch = "true" *)
    op_sub23 u_sub (.clk(clk), .a(a), .b(b), .y(sub_y));
    (* keep_hierarchy = "yes", dont_touch = "true" *)
    op_eq23 u_eq (.clk(clk), .a(a), .b(b), .y(eq_y));
    (* keep_hierarchy = "yes", dont_touch = "true" *)
    op_lt23 u_lt (.clk(clk), .a(a), .b(b), .y(lt_y));
    (* keep_hierarchy = "yes", dont_touch = "true" *)
    op_ge_const23 u_ge_const (.clk(clk), .a(a), .y(ge_const_y));
    (* keep_hierarchy = "yes", dont_touch = "true" *)
    op_mux2_23 u_mux2 (
        .clk(clk), .a(a), .b(b), .sel(sel[0]), .y(mux2_y)
    );
    (* keep_hierarchy = "yes", dont_touch = "true" *)
    op_mux4_23 u_mux4 (
        .clk(clk), .a(a), .b(b), .c(c), .d(d), .sel(sel), .y(mux4_y)
    );
    (* keep_hierarchy = "yes", dont_touch = "true" *)
    op_shift_const23 u_shift_const (
        .clk(clk), .a(a), .y(shift_const_y)
    );
    (* keep_hierarchy = "yes", dont_touch = "true" *)
    op_shift_var23 u_shift_var (
        .clk(clk), .a(a), .sh(sh), .y(shift_var_y)
    );
    (* keep_hierarchy = "yes", dont_touch = "true" *)
    op_mul23x16 u_mul (
        .clk(clk), .a(a), .b(b[15:0]), .y(mul_y)
    );
    (* keep_hierarchy = "yes", dont_touch = "true" *)
    op_modsub23 u_modsub (
        .clk(clk), .a(a), .b(b), .q(q), .y(modsub_y)
    );
    (* keep_hierarchy = "yes", dont_touch = "true" *)
    op_reduce_or13 u_reduce_or (
        .clk(clk), .a(a[12:0]), .y(reduce_or_y)
    );
    (* keep_hierarchy = "yes", dont_touch = "true" *)
    op_srl16x23 u_srl_delay (
        .clk(clk), .ce(ce), .a(a), .y(srl_delay_y)
    );
    (* keep_hierarchy = "yes", dont_touch = "true" *)
    op_ffdelay16x23_reset u_ff_delay (
        .clk(clk), .rst(rst), .ce(ce), .a(a), .y(ff_delay_y)
    );
    (* keep_hierarchy = "yes", dont_touch = "true" *)
    op_lutram32x8 u_lutram (
        .clk(clk), .we(mem_we),
        .waddr(mem_waddr[4:0]), .raddr(mem_raddr[4:0]),
        .wdata(mem_din), .rdata(lutram_y)
    );
    (* keep_hierarchy = "yes", dont_touch = "true" *)
    op_bram576x23 u_bram (
        .clk(clk), .we(mem_we),
        .waddr(mem_waddr), .raddr(mem_raddr),
        .wdata(a), .rdata(bram_y)
    );

    assign observed = {
        add_y, sub_y, eq_y, lt_y, ge_const_y, mux2_y, mux4_y,
        shift_const_y, shift_var_y, mul_y, modsub_y, reduce_or_y,
        srl_delay_y, ff_delay_y, lutram_y, bram_y
    };
endmodule

module op_add23 (
    input wire clk, input wire [22:0] a, input wire [22:0] b,
    output reg [22:0] y
);
    (* dont_touch = "true" *) reg [22:0] a_q, b_q;
    always @(posedge clk) begin
        a_q <= a; b_q <= b; y <= a_q + b_q;
    end
endmodule

module op_sub23 (
    input wire clk, input wire [22:0] a, input wire [22:0] b,
    output reg [22:0] y
);
    (* dont_touch = "true" *) reg [22:0] a_q, b_q;
    always @(posedge clk) begin
        a_q <= a; b_q <= b; y <= a_q - b_q;
    end
endmodule

module op_eq23 (
    input wire clk, input wire [22:0] a, input wire [22:0] b,
    output reg y
);
    (* dont_touch = "true" *) reg [22:0] a_q, b_q;
    always @(posedge clk) begin
        a_q <= a; b_q <= b; y <= (a_q == b_q);
    end
endmodule

module op_lt23 (
    input wire clk, input wire [22:0] a, input wire [22:0] b,
    output reg y
);
    (* dont_touch = "true" *) reg [22:0] a_q, b_q;
    always @(posedge clk) begin
        a_q <= a; b_q <= b; y <= (a_q < b_q);
    end
endmodule

module op_ge_const23 (
    input wire clk, input wire [22:0] a,
    output reg y
);
    (* dont_touch = "true" *) reg [22:0] a_q;
    always @(posedge clk) begin
        a_q <= a; y <= (a_q >= 23'd8380417);
    end
endmodule

module op_mux2_23 (
    input wire clk, input wire [22:0] a, input wire [22:0] b,
    input wire sel, output reg [22:0] y
);
    (* dont_touch = "true" *) reg [22:0] a_q, b_q;
    (* dont_touch = "true" *) reg sel_q;
    always @(posedge clk) begin
        a_q <= a; b_q <= b; sel_q <= sel;
        y <= sel_q ? b_q : a_q;
    end
endmodule

module op_mux4_23 (
    input wire clk,
    input wire [22:0] a, input wire [22:0] b,
    input wire [22:0] c, input wire [22:0] d,
    input wire [1:0] sel, output reg [22:0] y
);
    (* dont_touch = "true" *) reg [22:0] a_q, b_q, c_q, d_q;
    (* dont_touch = "true" *) reg [1:0] sel_q;
    reg [22:0] mux_w;
    always @* begin
        case (sel_q)
            2'd0: mux_w = a_q;
            2'd1: mux_w = b_q;
            2'd2: mux_w = c_q;
            default: mux_w = d_q;
        endcase
    end
    always @(posedge clk) begin
        a_q <= a; b_q <= b; c_q <= c; d_q <= d; sel_q <= sel;
        y <= mux_w;
    end
endmodule

module op_shift_const23 (
    input wire clk, input wire [22:0] a,
    output reg [22:0] y
);
    (* dont_touch = "true" *) reg [22:0] a_q;
    always @(posedge clk) begin
        a_q <= a; y <= a_q << 5;
    end
endmodule

module op_shift_var23 (
    input wire clk, input wire [22:0] a, input wire [4:0] sh,
    output reg [22:0] y
);
    (* dont_touch = "true" *) reg [22:0] a_q;
    (* dont_touch = "true" *) reg [4:0] sh_q;
    always @(posedge clk) begin
        a_q <= a; sh_q <= sh; y <= a_q << sh_q;
    end
endmodule

module op_mul23x16 (
    input wire clk, input wire [22:0] a, input wire [15:0] b,
    output reg [38:0] y
);
    (* dont_touch = "true" *) reg [22:0] a_q;
    (* dont_touch = "true" *) reg [15:0] b_q;
    (* use_dsp = "yes" *) wire [38:0] product_w;
    assign product_w = a_q * b_q;
    always @(posedge clk) begin
        a_q <= a; b_q <= b; y <= product_w;
    end
endmodule

module op_modsub23 (
    input wire clk,
    input wire [22:0] a, input wire [22:0] b, input wire [22:0] q,
    output reg [22:0] y
);
    (* dont_touch = "true" *) reg [22:0] a_q, b_q, q_q;
    wire [23:0] diff_w = {1'b0, a_q} - {1'b0, b_q};
    wire [23:0] corrected_w = {1'b0, diff_w[22:0]} + {1'b0, q_q};
    wire [22:0] result_w = diff_w[23] ? corrected_w[22:0]
                                      : diff_w[22:0];
    always @(posedge clk) begin
        a_q <= a; b_q <= b; q_q <= q; y <= result_w;
    end
endmodule

module op_reduce_or13 (
    input wire clk, input wire [12:0] a,
    output reg y
);
    (* dont_touch = "true" *) reg [12:0] a_q;
    always @(posedge clk) begin
        a_q <= a; y <= |a_q;
    end
endmodule

module op_srl16x23 (
    input wire clk, input wire ce, input wire [22:0] a,
    output wire [22:0] y
);
    genvar g;
    generate
        for (g = 0; g < 23; g = g + 1) begin : gen_srl
            (* shreg_extract = "yes" *) reg [15:0] delay_q;
            always @(posedge clk)
                if (ce)
                    delay_q <= {delay_q[14:0], a[g]};
            assign y[g] = delay_q[15];
        end
    endgenerate
endmodule

module op_ffdelay16x23_reset (
    input wire clk, input wire rst, input wire ce, input wire [22:0] a,
    output wire [22:0] y
);
    genvar g;
    generate
        for (g = 0; g < 23; g = g + 1) begin : gen_ff_delay
            (* shreg_extract = "no" *) reg [15:0] delay_q;
            always @(posedge clk) begin
                if (rst)
                    delay_q <= 16'd0;
                else if (ce)
                    delay_q <= {delay_q[14:0], a[g]};
            end
            assign y[g] = delay_q[15];
        end
    endgenerate
endmodule

module op_lutram32x8 (
    input wire clk, input wire we,
    input wire [4:0] waddr, input wire [4:0] raddr,
    input wire [7:0] wdata, output wire [7:0] rdata
);
    (* ram_style = "distributed" *) reg [7:0] mem [0:31];
    always @(posedge clk)
        if (we)
            mem[waddr] <= wdata;
    assign rdata = mem[raddr];
endmodule

module op_bram576x23 (
    input wire clk, input wire we,
    input wire [9:0] waddr, input wire [9:0] raddr,
    input wire [22:0] wdata, output reg [22:0] rdata
);
    (* ram_style = "block" *) reg [22:0] mem [0:575];
    always @(posedge clk) begin
        if (we)
            mem[waddr] <= wdata;
        rdata <= mem[raddr];
    end
endmodule
