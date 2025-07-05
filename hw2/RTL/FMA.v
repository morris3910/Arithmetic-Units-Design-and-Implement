module FMA (
    input [31:0] a,
    input [31:0] b,
    input [31:0] c,
    output reg [31:0] d 
);

    // Step 1: Extract
    wire sa = a[31];
    wire [7:0] ea = a[30:23];
    wire [23:0] ma = {1'b1, a[22:0]};

    wire sb = b[31];
    wire [7:0] eb = b[30:23];
    wire [23:0] mb = {1'b1, b[22:0]};

    wire sc = c[31];
    wire [7:0] ec = c[30:23];
    wire [23:0] mc = {1'b1, c[22:0]};

    // Special case
    wire nan;
    wire zero_a, zero_b, zero_c;
    wire neg_inf, pos_inf;
    assign nan = {sa, ea, a[22:0]} == 32'hFFFFFFFF || {sb, eb, b[22:0]} == 32'hFFFFFFFF || {sc, ec, c[22:0]} == 32'hFFFFFFFF ? 1:0;
    assign zero_a = {sa, ea, a[22:0]} == 0 ? 1:0;
    assign zero_b = {sb, eb, b[22:0]} == 0 ? 1:0;
    assign zero_c = {sc, ec, c[22:0]} == 0 ? 1:0; 
    assign neg_inf = (sa^sb == 1) && (ea >= 8'hfe || eb >= 8'hfe) ? 1:0;
    assign pos_inf = (sa^sb == 0) && (ea >= 8'hfe || eb >= 8'hfe) ? 1:0;

    // Step 2: Compute Product
    wire sp = sa ^ sb;
    wire [7:0] ep = ea + eb - 127;
    wire [75:0] mp = ma * mb; // Q2.46

    // Step 3: Alignment
    wire [75:0] mc_aligned;
    wire [7:0] exp_diff = ep > ec ? (ep - ec) : (ec - ep);
    assign mc_aligned = ep > ec ? {29'b0, mc, 23'b0} >> exp_diff : {29'b0, mc, 23'b0} << exp_diff; // Q28.48

    // Step 4: Add aligned mantissa of c to mantissa of P
    wire [76:0] m_d = sp == sc ? (mp + mc_aligned) : (mp > mc_aligned ? (mp - mc_aligned) : (mc_aligned - mp));
    wire sd = mp >= mc_aligned ? sp : sc;
    
    // Step 5: Normalize
    reg [47:0] m_d_normalized;
    reg [7:0] e_d;
    integer shifts;

    always @(*) begin
        shifts = 0;
        while (m_d[76-shifts] == 0 && shifts <= 76) begin
            shifts = shifts + 1;
        end
        if (shifts <= 29) begin
            m_d_normalized = m_d >> (29 - shifts);
            e_d = ep - shifts + 29 + 1;
        end else begin
            m_d_normalized = m_d << (shifts - 29);
            e_d = ep - shifts + 29 + 1;
        end
    end

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
            d = 0;
        end else begin
            d = {sd, e_d, m_d_rounded};
        end
    end

endmodule
