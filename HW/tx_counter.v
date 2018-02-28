module tx_counter(
    input clk,
    input rst,
    input [255:0] tx_tdata,
    input         tx_tvalid,
    input         tx_tlast,
    input         tx_tready,

    output reg [31:0]  tx_count
);



reg is_first;

always@(posedge clk)begin
    if(rst == 1)begin
        is_first <= 0;
    end
    else begin
        if( tx_tvalid == 1 && tx_tready == 1)begin
            if(tx_tlast == 1)begin 
                is_first <= 1;
            end
            else begin
                is_first <= 0;
            end
        end
        else begin
            is_first <= is_first;
        end
    end
end



always@(posedge clk) begin 
    if(rst == 1)begin 
        tx_count <= 0;
    end
    else begin                                                          
        if(is_first == 1 && tx_tvalid == 1 && tx_tready == 1  )begin
            tx_count <= tx_count + 1;
        end
        else begin 
            tx_count <= tx_count;
        end
    end
end

endmodule