module ncapp_top(
    input clk,
    input rst,

    //varibales from OS
    input [31:0] interval,
    input [31:0] threshold_high_rx,
    input [31:0] threshold_high_tx,
    input [31:0] threshold_low_rx,
    input [31:0] threshold_safeguard,
    input        aggressive_mode,
    input [31:0] interval_speculative,
    // packets

    input tx_tvalid,
    input tx_tlast,
    input [255:0] tx_tdata,
    input tx_tready,

    input rx_tvalid,
    input rx_tlast,
    input [255:0] rx_tdata,
    input rx_tready,

    output interrupt_z,
    output reg [1:0] interrupt_type,
    output [31:0] rx_count,
    output reg [5:0] state

);

parameter IDLE =       6'b000001;
parameter TEMP1      = 6'b000010;
parameter HIGH_PERF =  6'b000100;
parameter TEMP2      = 6'b001000;
parameter GOTO_LOW  =  6'b010000;
parameter TEMP3      = 6'b100000;



parameter INTR_HIGH = 1;
parameter INTR_LOW  = 0;

wire timeout;
wire [31:0] tx_count;

wire [31:0] t1_value;

reg interrupt_speculative;

assign interrupt_z = interrupt_speculative | interrupt;


reg  [31:0] count_safeguard;

reg interrupt;


timer timer_inst(
    .clk(clk),
    .rst(rst),
    .interval(interval),
    .timeout(timeout )
);

timer_1 timer_speculative(
    .clk(clk),
    .rst(rst | interrupt_z ),
    .counter(t1_value)
);

always@(posedge clk)begin
    if(rst ==1)begin
        interrupt_speculative <= 0;
    end
    else begin  
        if(rx_tvalid == 1 && rx_tready == 1 && rx_tdata[127:96] == 32'h28_45_00_08 && t1_value > interval_speculative )begin
            interrupt_speculative <= 1;
        end
        else begin
            interrupt_speculative <= 0;
        end
    end
end


always@(posedge clk)begin
    case({interrupt, interrupt_speculative})
        2'b10:begin
            interrupt_type[1] <= 0;
        end
        2'b01:begin
            interrupt_type[1] <= 1;
        end
        default:begin
            interrupt_type[1] <= interrupt_type[1];
        end
    endcase
end



tx_counter tc_inst(
    .clk(clk),
    .rst(rst | timeout),
    .tx_count(tx_count),
    .tx_tvalid(tx_tvalid),
    .tx_tdata (tx_tdata),
    .tx_tlast (tx_tlast),
    .tx_tready(tx_tready)
);


rx_counter rc_inst(
    .clk(clk),
    .rst(rst | timeout),
    .rx_count(rx_count),
    .rx_tvalid(rx_tvalid),
    .rx_tdata (rx_tdata),
    .rx_tlast (rx_tlast),
    .rx_tready(rx_tready)
);



always@(posedge clk)begin
    if(rst == 1)begin
        state <= IDLE;
        interrupt <=0;
        interrupt_type[0] <= INTR_LOW;
        count_safeguard <= 0;
    end
    else begin
        case(state)
            IDLE:begin
                count_safeguard <= 0;
                if(rx_count > threshold_high_rx)begin
                    interrupt <= 1;
                    interrupt_type[0] <= INTR_HIGH;
                    state <= TEMP1;
                end
                else begin
                    interrupt <= 0;
                    interrupt_type[0] <= INTR_LOW;
                    state <= IDLE;
                end
            end
            TEMP1:begin
                interrupt <= 0;
                state <= HIGH_PERF;
                count_safeguard <= 0;
                interrupt_type[0] <= interrupt_type[0];
            end
            HIGH_PERF:begin 
                interrupt <= 0;
                count_safeguard <= 0;
                interrupt_type[0] <= interrupt_type[0];
                if(timeout == 1 && rx_count < threshold_low_rx && tx_count < threshold_high_tx)begin
                    state <= GOTO_LOW;
                end
                else begin
                    state <= HIGH_PERF;
                end
            end
            GOTO_LOW: begin
                if(rx_count > threshold_low_rx || tx_count > threshold_high_tx)begin
                    interrupt <= 1;
                    interrupt_type[0] <= INTR_HIGH;
                    state <= TEMP1;
                    count_safeguard <= 0;
                end
                else if(timeout == 1)begin
                    if(count_safeguard < threshold_safeguard)begin
                        count_safeguard <= count_safeguard + 1;
                        state <= TEMP2;
                        interrupt <= (aggressive_mode == 1)? 0 : 1;
                        interrupt_type[0] <= INTR_LOW;
                    end
                    else begin
                        interrupt <= 1;
                        interrupt_type[0] <= INTR_LOW;
                        state <= TEMP3;
                        count_safeguard <= 0;
                    end
                end
            end
            TEMP2:begin
                interrupt <= 0;
                state <= GOTO_LOW;
                count_safeguard <= count_safeguard;
                interrupt_type[0] <= interrupt_type[0];
            end
            TEMP3:begin
                interrupt <= 0;
                state <= IDLE;
                count_safeguard <= 0;
                interrupt_type[0] <= interrupt_type[0];
            end
            default:begin
                state <= IDLE;
                interrupt <=0;
                interrupt_type[0] <= INTR_LOW;
                count_safeguard <= 0;
            end
        endcase
    end
end

endmodule



module timer_1(
    input clk,
    input rst,
    output reg [31:0] counter
);



always@(posedge clk)begin
    if(rst == 1 )begin
        counter <= 0;
    end
    else begin
            counter <= counter + 1;
    end
end


endmodule
