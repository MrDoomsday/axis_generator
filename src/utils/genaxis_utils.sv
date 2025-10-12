module genaxis_utils #(
    parameter W = 16
)(
    input   logic [W-1:0] in,
    output  logic [W-1:0] out
);
    

    function logic [W-1:0] get_thermo_left(logic [W-1:0] vector);
        logic [W-1:0] result;
        result[W-1] = vector[W-1];        
        for(int i = W-2; i > -1; i--) begin
            result[i] = vector[i] | result[i+1];
        end
        return result;
    endfunction

    assign out = get_thermo_left(in);
    
endmodule



