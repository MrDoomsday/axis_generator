module genaxis_utils #(
    parameter W = 16
)(
    input   logic [W-1:0] in,
    output  logic [W-1:0] out
);
    

    function logic [W-1:0] get_thermo_left(logic [W-1:0] vector);
        logic [W-1:0] result;
        result = {W{1'b1}};        
        for(int i = W-1; i > -1; i--) begin
            if(vector[i]) begin
                result >>= (W-1-i);
                return result;
            end
        end
        return {W{1'b1}};
    endfunction

    assign out = get_thermo_left(in);
    
endmodule



