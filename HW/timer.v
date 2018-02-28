module timer(
    input clk,
    input rst,
    input [31:0] interval,
    output reg timeout
);


reg [31:0] counter;

always@(posedge clk)begin
    if(rst == 1 )begin
        counter <= 0;
        timeout <= 0;
    end
    else begin
        if(counter < interval)begin
            counter <= counter + 1;
            timeout <= 0;
        end
        else begin 
            counter <= 0;
            timeout <= 1;
        end
    end
end


endmodule