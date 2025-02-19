module MyDesign (
//---------------------------------------------------------------------------
//Control signals
  input   wire dut_run                    , 
  output  reg dut_busy                   ,
  input   wire reset_b                    ,  
  input   wire clk                        ,
 
//---------------------------------------------------------------------------
//Input SRAM interface
  output reg        input_sram_write_enable    ,//0
  output reg [11:0] input_sram_write_addresss  ,
  output reg [15:0] input_sram_write_data      ,
  output reg [11:0] input_sram_read_address    ,//<= 0
  input wire [15:0] input_sram_read_data       ,// 1 clk -> data at addr 0

output reg [7:0] data1,
output reg [7:0] data2,
//---------------------------------------------------------------------------
//Output SRAM interface
  output reg        output_sram_write_enable    ,
  output reg [11:0] output_sram_write_addresss  ,
  output reg [15:0] output_sram_write_data      ,
  output reg [11:0] output_sram_read_address    ,
  input wire [15:0] output_sram_read_data       ,

//---------------------------------------------------------------------------
//Scratchpad SRAM interface
  output reg        scratchpad_sram_write_enable    ,
  output reg [11:0] scratchpad_sram_write_addresss  ,
  output reg [15:0] scratchpad_sram_write_data      ,
  output reg [11:0] scratchpad_sram_read_address    ,
  input wire [15:0] scratchpad_sram_read_data       ,

//---------------------------------------------------------------------------
//Weights SRAM interface                                                       
  output reg        weights_sram_write_enable    ,
  output reg [11:0] weights_sram_write_addresss  ,
  output reg [15:0] weights_sram_write_data      ,
  output reg [11:0] weights_sram_read_address    ,
  input wire [15:0] weights_sram_read_data       

);


  //YOUR CODE HERE
//always@(posedge clk or posedge reset_b) begin//(@posedge clk)
  //input_sram_read_address <= 'b11;
  //input_sram_write_enable <= 0;
  //dut_busy <=1;
  //x <=1;
  //for current_state to next_state transition

  ////if(reset_b)
  //current_state<=A;
  //else if(!reset_b)
 // current_state<=next_state;

  
//end

//data path

//always@(posedge clk)begin
/*
STATE A: DEFAULT STATE

Resetting counter/ starting counter-6bit 


1. capturing N 
if(!input_sram_write_enable && input_sram_read_address=='b00)
Size_N<=input_sram_read_data;

else if(!input_sram_write_enable && input_sram_read_address== (((Size_N*Size_N)/2)+1)

*/

//state declarations
    
parameter IDLE = 2'b00;
parameter FETCH_SIZE = 2'b01;
parameter FETCH_DATA = 2'b10;
parameter FETCH_NEXT_MATRIX_SIZE = 2'b11;


    
reg current_state, next_state;
reg [15:0] matrix_size; // Matrix size (NxN) cant be more than 64-16bits
reg [7:0] fetch_address; // address pointer
reg matrix_counter; // Matrix counter 
reg done; //flag to mark the completion of data fetching from input sram
reg size_check;
    
// State transitions from current_state to next_state
always @(posedge clk or posedge reset_b) begin
  if (reset_b) begin
      current_state <= IDLE;
      input_sram_read_address <= 'b0;
      matrix_counter <= 0;
      fetch_address <= 'b0;
      input_sram_write_enable <= 'b0;
      dut_busy<=0;
      done <= 0;
      size_check<=0;
      end 
  else begin
      current_state <= next_state;
      end
  end

//Control path 

always @(posedge clk) begin
next_state = current_state;
  case (current_state)
  IDLE: begin
        if (dut_run) begin
        dut_busy = 1;
        if(dut_busy==1)begin
        next_state = FETCH_SIZE;
        end
        else
        next_state = IDLE;
        end
        end
            
  FETCH_SIZE: begin
              if(size_check!=0)begin
              next_state = FETCH_DATA;
              end
              end
            
  FETCH_DATA: begin
  // Check if address pointer has reached (NxN)/2
      if (fetch_address <= (matrix_size * matrix_size) / 2) begin
          next_state = FETCH_NEXT_MATRIX_SIZE;
                end
  end
      
            
  FETCH_NEXT_MATRIX_SIZE: begin
  // Continue to the next matrix by fetching the size
          next_state = FETCH_SIZE;
          if(done)begin
          next_state = IDLE;
                end
            end
          
                
        
  
  
  
  default: next_state = IDLE;
            
        endcase
    end


//Data path 
  always @(*) begin
  next_state = current_state;
  case (current_state) 
    IDLE: begin
      //dut_busy<= 0;
      input_sram_write_enable<=0;
      data1<=0;
      data2<=0;
          end
            
            
    FETCH_SIZE: begin
    if(!input_sram_write_enable)begin       
    input_sram_read_address<=fetch_address;
    matrix_size <= input_sram_read_data;// Assuming the size is stored here
    if(matrix_size!=0)begin
      size_check=1;
    end
               end
    end
            
    FETCH_DATA: begin
               

                input_sram_read_address <= fetch_address + 1; // Fetch data from the next address
                data1 <= input_sram_read_data[7:0];
                data2 <= input_sram_read_data[15:8];
                fetch_address <= fetch_address + 1;  // incrementing the address pointer
                if(input_sram_read_data== 16'hFFFF)begin
                done<=1;
                end
                
                end
           
            
            FETCH_NEXT_MATRIX_SIZE: begin
                // Reset the matrix counter when address reaches (NxN)/2
                if (fetch_address == (matrix_size * matrix_size) / 2) begin
                    matrix_counter <= 0; // Reset matrix counter
                end
                
                // Fetch the address of the next matrix (from (NxN)/2 - 1)
                fetch_address <= (matrix_size * matrix_size) / 2 - 1; // Next matrix address is stored here
                matrix_counter <= matrix_counter + 1; // Increment the matrix counter

                end
            
            
            default: begin
                //dut_busy<=0;
                data1<=0;
                data2<=0;
            
            end
endcase
end    
endmodule

