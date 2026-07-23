module CPT
(
    input         clk                ,
    input         rst                ,
    input         actual_jump_flag              ,
    input         GLOBAL             ,
    input         AREA              ,
    input  [5:0]  GPT_index          ,
    input  [5:0]  GPT_index_update   ,
    input         is_branch             ,
    input  [31:0] pc_from_ex              ,
    
    output        CPT_predict
);

    parameter GLOBAL_GPT_INDEX      = 6;

    reg  [1:0]                      CPT         [ 2**GLOBAL_GPT_INDEX-1 : 0 ];
    wire [ GLOBAL_GPT_INDEX-1 : 0 ] CPT_index;
    wire [1:0]                      CPT_predict_tmp;
    integer i;

    assign CPT_index = GPT_index; //use same of GLOBAL

 
always @ (posedge clk or negedge rst)   
    begin
        if (~rst) begin
            for (i=0; i < 2**GLOBAL_GPT_INDEX; i=i+1) 
            begin
                CPT[i] <= 'd0;
            end
        end
        else begin
            if((pc_from_ex[1:0] == 2'b00) && (is_branch)) begin
                if (CPT[GPT_index_update] == 2'b11) begin  //Strongly GLOBAL
                    if ((GLOBAL ^ actual_jump_flag) & (~(AREA ^ actual_jump_flag))) begin
                        CPT[GPT_index_update] <= CPT[GPT_index_update] - 1'b1;
                    end
                    else begin
                    CPT[GPT_index_update] <= CPT[GPT_index_update];
                    end
                end
                else begin
                    if (CPT[GPT_index_update] == 2'b10) begin  //Weakly GLOBAL
                        if ((GLOBAL ^ actual_jump_flag) & (~(AREA ^ actual_jump_flag))) begin
                            CPT[GPT_index_update] <= CPT[GPT_index_update] - 1'b1; 
                        end
                        else begin
                            if (~(GLOBAL ^ actual_jump_flag) & (AREA ^ actual_jump_flag)) begin
                                CPT[GPT_index_update] <= CPT[GPT_index_update] + 1'b1;
                            end
                            else begin
                                CPT[GPT_index_update] <= CPT[GPT_index_update];
                            end
                        end
                    end
                    else begin
                        if (CPT[GPT_index_update] == 2'b01) begin //Weakly AREA
                            if ((GLOBAL ^ actual_jump_flag) & (~(AREA ^ actual_jump_flag))) begin
                                CPT[GPT_index_update] <= CPT[GPT_index_update] - 1'b1; 
                            end
                            else begin
                                if (~(GLOBAL ^ actual_jump_flag) & (AREA ^ actual_jump_flag)) begin
                                    CPT[GPT_index_update] <= CPT[GPT_index_update] + 1'b1;
                                end
                                else begin
                                    CPT[GPT_index_update] <= CPT[GPT_index_update];
                                end
                            end 
                        end
                        else begin //Strongly AREA
                            if (~(GLOBAL ^ actual_jump_flag) & (AREA ^ actual_jump_flag)) begin
                                CPT[GPT_index_update] <= CPT[GPT_index_update] + 1'b1;
                            end
                            else begin
                                CPT[GPT_index_update] <= CPT[GPT_index_update];
                            end
                        end 
                    end
                end
            end
            else begin
                CPT[GPT_index_update] <= CPT[GPT_index_update];
            end
        end
    end
  
    assign	CPT_predict_tmp  = CPT[CPT_index]    ;	
    assign  CPT_predict      = CPT_predict_tmp[1];  

endmodule 

