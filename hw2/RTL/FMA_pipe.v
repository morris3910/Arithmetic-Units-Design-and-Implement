module FMA_pipe (
    input  clk, rst,
    input  [31:0] a,
    input  [31:0] b,
    input  [31:0] c,
    output [31:0] d 
);
    wire sc, sp;
    wire [7:0] ec, ep;
    wire [75:0] mc_aligned, mp;
    wire nan, zero_a, zero_b, zero_c, neg_inf, pos_inf;
    stage1 s1 (a, b, c, nan, zero_a, zero_b, zero_c, neg_inf, pos_inf, sc, sp, ec, ep, mc_aligned, mp);

    reg sc_reg1, sp_reg1;
    reg [7:0] ec_reg1, ep_reg1;
    reg [75:0] mc_aligned_reg1, mp_reg1;
    reg nan_reg1, zero_a_reg1, zero_b_reg1, zero_c_reg1, neg_inf_reg1, pos_inf_reg1;
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            sc_reg1 <= 0;
            sp_reg1 <= 0;
            ec_reg1 <= 0;
            ep_reg1 <= 0;
            mc_aligned_reg1 <= 0;
            mp_reg1 <= 0;
            nan_reg1 <= 0;
            zero_a_reg1 <= 0;
            zero_b_reg1 <= 0;
            zero_c_reg1 <= 0;
            neg_inf_reg1 <= 0;
            pos_inf_reg1 <= 0;
        end else begin
            sc_reg1 <= sc;
            sp_reg1 <= sp;
            ec_reg1 <= ec;
            ep_reg1 <= ep;
            mc_aligned_reg1 <= mc_aligned;
            mp_reg1 <= mp;
            nan_reg1 <= nan;
            zero_a_reg1 <= zero_a;
            zero_b_reg1 <= zero_b;
            zero_c_reg1 <= zero_c;
            neg_inf_reg1 <= neg_inf;
            pos_inf_reg1 <= pos_inf;
        end
    end

    wire sd;
    wire [76:0] m_d;
    stage2 s2 (sc_reg1, sp_reg1, mc_aligned_reg1, mp_reg1, sd, m_d);

    reg sd_reg2;
    reg [7:0] ep_reg2;
    reg [76:0] m_d_reg2;
    reg nan_reg2, zero_a_reg2, zero_b_reg2, zero_c_reg2, neg_inf_reg2, pos_inf_reg2;
     always @(posedge clk or posedge rst) begin
        if (rst) begin
            sd_reg2 <= 0;
            ep_reg2 <= 0;
            m_d_reg2 <= 0;
            nan_reg2 <= 0;
            zero_a_reg2 <= 0;
            zero_b_reg2 <= 0;
            zero_c_reg2 <= 0;
            neg_inf_reg2 <= 0;
            pos_inf_reg2 <= 0;
        end else begin
            sd_reg2 <= sd;
            ep_reg2 <= ep_reg1;
            m_d_reg2 <= m_d;
            nan_reg2 <= nan_reg1;
            zero_a_reg2 <= zero_a_reg1;
            zero_b_reg2 <= zero_b_reg1;
            zero_c_reg2 <= zero_c_reg1;
            neg_inf_reg2 <= neg_inf_reg1;
            pos_inf_reg2 <= pos_inf_reg1;
        end
    end

    wire [7:0] ed;
    wire [47:0] m_d_normalized;
    stage3 s3 (ep_reg2, m_d_reg2, ed, m_d_normalized);

    reg sd_reg3;
    reg [7:0] ed_reg3;
    reg [47:0] m_d_normalized_reg3;
    reg nan_reg3, zero_a_reg3, zero_b_reg3, zero_c_reg3, neg_inf_reg3, pos_inf_reg3;
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            sd_reg3 <= 0;
            ed_reg3 <= 0;
            m_d_normalized_reg3 <= 0;
            nan_reg3 <= 0;
            zero_a_reg3 <= 0;
            zero_b_reg3 <= 0;
            zero_c_reg3 <= 0;
            neg_inf_reg3 <= 0;
            pos_inf_reg3 <= 0;
        end else begin
            sd_reg3 <= sd_reg2;
            ed_reg3 <= ed;
            m_d_normalized_reg3 <= m_d_normalized;
            nan_reg3 <= nan_reg2;
            zero_a_reg3 <= zero_a_reg2;
            zero_b_reg3 <= zero_b_reg2;
            zero_c_reg3 <= zero_c_reg2;
            neg_inf_reg3 <= neg_inf_reg2;
            pos_inf_reg3 <= pos_inf_reg2;
        end
    end
    
    stage4 s4 (
        sd_reg3, ed_reg3, m_d_normalized_reg3, 
        nan_reg3, zero_a_reg3, zero_b_reg3, zero_c_reg3, neg_inf_reg3, pos_inf_reg3,
        d
    );

endmodule

module stage1 (
    input [31:0] a, b, c, 
    output nan, zero_a, zero_b, zero_c, neg_inf, pos_inf,
    output sc, sp,
    output [7:0] ec, ep,
    output [75:0] mc_aligned, mp
);
    // Extract
    wire sa = a[31];
    wire [7:0] ea = a[30:23];
    wire [23:0] ma = {1'b1, a[22:0]};

    wire sb = b[31];
    wire [7:0] eb = b[30:23];
    wire [23:0] mb = {1'b1, b[22:0]};

    assign sc = c[31];
    assign ec = c[30:23];
    wire [23:0] mc = {1'b1, c[22:0]};

    // Special case
    assign nan = {sa, ea, a[22:0]} == 32'hFFFFFFFF || {sb, eb, b[22:0]} == 32'hFFFFFFFF || {sc, ec, c[22:0]} == 32'hFFFFFFFF ? 1:0;
    assign zero_a = {sa, ea, a[22:0]} == 0 ? 1:0;
    assign zero_b = {sb, eb, b[22:0]} == 0 ? 1:0;
    assign zero_c = {sc, ec, c[22:0]} == 0 ? 1:0; 
    assign neg_inf = (sa^sb == 1) && (ea >= 8'hfe || eb >= 8'hfe) ? 1:0;
    assign pos_inf = (sa^sb == 0) && (ea >= 8'hfe || eb >= 8'hfe) ? 1:0;

    // Compute Product
    assign sp = sa ^ sb;
    assign ep = ea + eb - 127;
    assign mp = ma * mb; // Q2.46

    // Alignment
    wire [7:0] exp_diff = ep > ec ? (ep - ec) : (ec - ep);
    assign mc_aligned = ep > ec ? {29'b0, mc, 23'b0} >> exp_diff : {29'b0, mc, 23'b0} << exp_diff; // Q28.48
endmodule

module stage2 (
    input sc, sp,
    input [75:0] mc_aligned, mp,
    output sd,
    output [76:0] m_d
);
    assign m_d = sp == sc ? (mp + mc_aligned) : (mp > mc_aligned ? (mp - mc_aligned) : (mc_aligned - mp));
    assign sd = mp >= mc_aligned ? sp : sc;
endmodule

module stage3 (
    input [7:0] ep,
    input [76:0] m_d,
    output reg [7:0] ed,
    output reg [47:0] m_d_normalized

);
    integer shifts;
    always @(*) begin
        shifts = 0;
        while (m_d[76-shifts] == 0 && shifts <= 76) begin
            shifts = shifts + 1;
        end
        if (shifts <= 29) begin
            m_d_normalized = m_d >> (29 - shifts);
            ed = ep - shifts + 29 + 1;
        end else begin
            m_d_normalized = m_d << (shifts - 29);
            ed = ep - shifts + 29 + 1;
        end
    end
endmodule

module stage4 (
    input sd,
    input [7:0] ed,
    input [47:0] m_d_normalized,
    input nan, zero_a, zero_b, zero_c, neg_inf, pos_inf,
    output reg [31:0] d
);
    reg [22:0] m_d_rounded;
    always @(*) begin
        if ({m_d_normalized[46:24]+1'b1, 24'b0} - m_d_normalized > m_d_normalized - {m_d_normalized[46:24], 24'b0}) begin
            m_d_rounded = m_d_normalized[46:24];
        end else if({m_d_normalized[46:24]+1'b1, 24'b0} - m_d_normalized < m_d_normalized - {m_d_normalized[46:24], 24'b0}) begin
            m_d_rounded = m_d_normalized[46:24] + 1'b1;
        end else begin
            if(m_d_normalized[24]) begin
                m_d_rounded = m_d_normalized[46:24] + 1'b1;
            end else begin
                m_d_rounded = m_d_normalized[46:24];
            end
        end
    end

    always @(*) begin
        if (nan || ((neg_inf || pos_inf) && (zero_a || zero_b))) begin
            d = 32'hFFFFFFFF;
        end else if (neg_inf && zero_c) begin
            d = {1'b1, 8'b1, 23'b0};
        end else if ((zero_a || zero_b) && zero_c) begin
            d = 32'b0;
        end else begin
            d = {sd, ed, m_d_rounded};
        end
    end
endmodule