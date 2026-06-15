module uart_rx #(parameter CLKS_PER_BIT = 217) (clk,rx,rx_data,rx_valid);
    input clk;
    input rx;
    output [7:0] rx_data;
    output rx_valid;

    parameter STATE_IDLE = 3'b000;
    parameter STATE_START = 3'b001;
    parameter STATE_DATA = 3'b010;
    parameter STATE_STOP = 3'b011;
    parameter STATE_CLEANUP = 3'b100;

    reg [7:0] baud_cnt;
    reg [2:0] bit_cnt;
    reg [7:0] rx_reg;
    reg [2:0] state;
    reg rx_valid_reg;
    
    always @(posedge clk)   begin
    //IMPORTANT thing to keep in mind is to reset the baud_count every time the state is changed 
		case(state)  
		  //initial state OR basically the RESET state where all the signals and registers are reset
		  //if rx goes LOW then move to the next state
		  STATE_IDLE: begin
			baud_cnt<=0;
			rx_valid_reg<=0;
			bit_cnt<=0;
			rx_reg<=0;
			if (!rx) state <= STATE_START;
		  end
		  
		  //Verify if rx signal is LOW at the middle of the bit period and then move to the next STATE_DATA state 
		  STATE_START: begin
		    if (baud_cnt==(CLKS_PER_BIT-1)/2)  begin
				if (!rx) begin
					state<=STATE_DATA;
					baud_cnt<=0;
				end
				else begin
					state<=STATE_IDLE;
					baud_cnt<=0;
				end
			end
			else begin
				baud_cnt<=baud_cnt+1;		
			end
		  end
		  
		  STATE_DATA: begin
		  	//Receive the incoming bit in the whole bit period and store in the register and check if the bit is MSB or not
		  	//because the LSB comes first
		  	if (baud_cnt < CLKS_PER_BIT-1) begin
		  		baud_cnt<=baud_cnt+1;
		  	
		  	end
		  	else if (baud_cnt==CLKS_PER_BIT-1)  begin
		  		baud_cnt<=0;
		  		rx_reg[bit_cnt]<=rx;
		  		if (bit_cnt<3'd7)  begin
		  			bit_cnt<=bit_cnt+1;
		  		
		  		end
		  		else state <= STATE_STOP;
		  	
		  	end

		  end
		  
		  //wait for a complete bit period and then move to the State_Cleanup state 
		  //considering there rx will be high based on the protocol rules we dont wait for the rx to be high
		  STATE_STOP: begin
		  	if (baud_cnt < CLKS_PER_BIT-1) begin
				baud_cnt <= baud_cnt + 1;
				state <= STATE_STOP;
			end
			else begin
			 rx_valid_reg <= 1'b1;
			 baud_cnt <= 0;
			 state <= STATE_CLEANUP;
 			
		  	end	  
		  
		  end
		  STATE_CLEANUP:  begin
		  	 rx_valid_reg<=0;
		  	 state<=STATE_IDLE; 
		     baud_cnt<=0; //Optional 
		  
		  end
		endcase
    end
	assign rx_valid=rx_valid_reg;
	assign rx_data=rx_reg; 
	
endmodule

