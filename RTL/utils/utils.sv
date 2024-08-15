module utils #(
    parameter W = 16
)();
    

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

endmodule



