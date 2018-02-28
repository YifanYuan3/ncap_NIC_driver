module rx_counter(
    input clk,
    input rst,
    input [255:0] rx_tdata,
    input         rx_tvalid,
    input         rx_tlast,
    input         rx_tready,

    output reg [31:0]  rx_count
);



reg is_first;

always@(posedge clk)begin
    if(rst == 1)begin
        is_first <= 0;
    end
    else begin
        if( rx_tvalid == 1 && rx_tready == 1)begin
            if(rx_tlast == 1)begin 
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
        rx_count <= 0;
    end
    else begin                                                          //tos
        if(is_first == 1 && rx_tvalid == 1 && rx_tready == 1 && rx_tdata[127:120] == 8'h28 )begin
            rx_count <= rx_count + 1;
        end
        else begin 
            rx_count <= rx_count;
        end
    end
end

endmodule