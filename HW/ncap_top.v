module ncap_top(
    input clk,
    input rst,

    //varibales from OS
    input [31:0] interval,
    input [31:0] threshold_high_rx,
    input [31:0] threshold_high_tx,
    input [31:0] threshold_low_rx,
    input [31:0] threshold_safeguard,
    input [31:0] aggressive_mode,
    // packets

    input tx_tvalid,
    input tx_tlast,
    input [255:0] tx_tdata,
    input tx_tready,

    input rx_tvalid,
    input rx_tlast,
    input [255:0] rx_tdata,
    input rx_tready,

    output reg interrupt,
    output reg interrupt_type,
    output reg [3:0] state

);

parameter IDLE =      4'b0001;
parameter HIGH_PERF = 4'b0010;
parameter GOTO_LOW  = 4'b0100;
parameter TEMP      = 4'b1000;

parameter INTR_HIGH = 1;
parameter INTR_LOW  = 0;

wire timeout;
wire [31:0] rx_count;
wire [31:0] tx_count;


reg  [31:0] count_safeguard;


reg tx_counter_rst;
reg rx_counter_rst;

reg [3:0] next_state;
reg [3:0] next_state_1;


always@(posedge clk)begin 
    if(rst == 1 || (state != TEMP && state != GOTO_LOW)) begin 
        count_safeguard <= 0;
    end
    else begin 
        if(timeout == 1 )begin
            count_safeguard <= count_safeguard + 1;
        end
        else begin 
            count_safeguard <= count_safeguard;
        end
    end
end

timer timer_inst(
    .clk(clk),
    .rst(rst),
    .interval(interval),
    .timeout(timeout )
);


tx_counter tc_inst(
    .clk(clk),
    .rst(rst /*| tx_counter_rst*/ | timeout),
    .tx_count(tx_count),
    .tx_tvalid(tx_tvalid),
    .tx_tdata (tx_tdata),
    .tx_tlast (tx_tlast),
    .tx_tready(tx_tready)
);


rx_counter rc_inst(
    .clk(clk),
    .rst(rst /*| rx_counter_rst */| timeout),
    .rx_count(rx_count),
    .rx_tvalid(rx_tvalid),
    .rx_tdata (rx_tdata),
    .rx_tlast (rx_tlast),
    .rx_tready(rx_tready)
);

always@(posedge clk)begin 
    if(rst == 1)begin 
        state <= IDLE;
    end
    else begin 
        state <= next_state;
    end
end

always@(posedge clk)begin
    if(rst == 1 )begin
        next_state_1 <= IDLE;
    end
    else begin
        case(state)
            IDLE: begin
                next_state_1 <= HIGH_PERF;
            end
            TEMP: begin
                next_state_1 <= IDLE;
            end
            HIGH_PERF: begin
                next_state_1 <= GOTO_LOW;
            end
            GOTO_LOW:begin
                if(rx_counter_rst == 1 )begin
                    if(interrupt == 1 && interrupt_type == INTR_LOW)begin
                        next_state_1 <= IDLE;
                    end
                    else begin
                        next_state_1 <= HIGH_PERF;
                    end
                end
                else begin 
                    next_state_1 <= GOTO_LOW;
                end
            end
            default: begin
                next_state_1 <= IDLE;
            end
        endcase
    end
end


always@(*)begin 
    case(state)
        IDLE: begin
            tx_counter_rst <= 0;
            rx_counter_rst <= 0;
            interrupt_type <= INTR_HIGH;
            if(rx_count > threshold_high_rx )begin
                interrupt <= 1;
                next_state <= TEMP;
            end
            else begin
                next_state <= IDLE;
                interrupt <= 0;
            end
        end

        TEMP: begin
            interrupt <= 0;
            interrupt_type <= INTR_HIGH;
            rx_counter_rst <= 0;
            tx_counter_rst <= 0;
            next_state <= next_state_1;
        end
        
        HIGH_PERF: begin
            interrupt <= 0;
            interrupt_type <= INTR_HIGH;
            if(rx_count < threshold_low_rx && tx_count < threshold_high_tx && timeout == 1)begin
                rx_counter_rst <= 1;
                tx_counter_rst <= 1;
                next_state <= TEMP;
            end
            else begin 
                rx_counter_rst <= 0;
                tx_counter_rst <= 0;
                next_state <= HIGH_PERF;
            end
        end

        GOTO_LOW: begin
            //timer timeout
            if(timeout == 1)begin
                next_state <= TEMP;
                //stay at goto low, and count safeguard increment 1
                rx_counter_rst <= 0;
                tx_counter_rst <= 0;
                interrupt <= (aggressive_mode == 1)? 0:1;
                interrupt_type <= INTR_LOW;
            end
            else begin
                //go back to high perf
                if(!(rx_count < threshold_low_rx && tx_count < threshold_high_tx) )begin 
                    rx_counter_rst <= 1;
                    tx_counter_rst <= 1;
                    interrupt <= 1;
                    next_state <= TEMP;
                    interrupt_type <= INTR_HIGH;
                end
                // unsafe, go back to idle
                else if(count_safeguard > threshold_safeguard)begin
                    rx_counter_rst <= 1;
                    tx_counter_rst <= 1;
                    next_state <= TEMP;
                    interrupt <= 1;
                    interrupt_type <= INTR_LOW;
                end
                //stay here
                else begin
                    next_state <= GOTO_LOW;
                    rx_counter_rst <= 0;
                    tx_counter_rst <= 0;
                    interrupt <= 0;
                    interrupt_type <= INTR_LOW;
                end
            end
        end
        default: begin
            next_state <= IDLE;
            interrupt <= 0;
            rx_counter_rst <= 0;
            tx_counter_rst <= 0;
            interrupt_type <= 0;
        end
    endcase
end


endmodule
