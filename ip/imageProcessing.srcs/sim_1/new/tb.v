`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 04/02/2020 08:11:41 PM
// Design Name: 
// Module Name: tb
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

`define headerSize 1080
`define imageSize 512*512

module tb(

    );
    
 
 reg clk;
 reg reset;
 reg [7:0] imgData;
 integer file,file1,file2,i;
 reg imgDataValid;
 integer sentSize;
 wire intr;
 wire [7:0] outData;
 wire outDataValid;
 integer receivedData=0;

 initial
 begin
    clk = 1'b0;
    forever
    begin
        #5 clk = ~clk;
    end
 end
 
 initial
 begin
    reset = 0;
    sentSize = 0;
    imgDataValid = 0;
    #100;
    reset = 1;
    #100;
    file = $fopen("lena_gray.bmp","rb");
    file1 = $fopen("blurred_lena.bmp","wb");
    file2 = $fopen("imageData.h","w");
    for(i=0;i<`headerSize;i=i+1)
    begin
        $fscanf(file,"%c",imgData);
        $fwrite(file1,"%c",imgData);
    end
    
    for(i=0;i<4*512;i=i+1)
    begin
        @(posedge clk);
        $fscanf(file,"%c",imgData);
        $fwrite(file2,"%0d,",imgData);
        imgDataValid <= 1'b1;
    end
    sentSize = 4*512;
    @(posedge clk);
    imgDataValid <= 1'b0;
    while(sentSize < `imageSize)
    begin
        @(posedge intr);
        for(i=0;i<512;i=i+1)
        begin
            @(posedge clk);
            $fscanf(file,"%c",imgData);
            $fwrite(file2,"%0d,",imgData);
            imgDataValid <= 1'b1;    
        end
        @(posedge clk);
        imgDataValid <= 1'b0;
        sentSize = sentSize+512;
    end
    @(posedge clk);
    imgDataValid <= 1'b0;
    @(posedge intr);
    for(i=0;i<512;i=i+1)
    begin
        @(posedge clk);
        imgData <= 0;
        imgDataValid <= 1'b1;
        $fwrite(file2,"%0d,",0);    
    end
    @(posedge clk);
    imgDataValid <= 1'b0;
    @(posedge intr);
    for(i=0;i<512;i=i+1)
    begin
        @(posedge clk);
        imgData <= 0;
        imgDataValid <= 1'b1; 
        $fwrite(file2,"%0d,",0);   
    end
    @(posedge clk);
    imgDataValid <= 1'b0;
    $fclose(file);
    $fclose(file2);
 end
 
 always @(posedge clk)
 begin
     if(outDataValid)
     begin
         $fwrite(file1,"%c",outData);
         receivedData = receivedData+1;
     end 
     if(receivedData == `imageSize)
     begin
        $fclose(file1);
        $stop;
     end
 end
 
 imageProcessTop dut(
    .axi_clk(clk),
    .axi_reset_n(reset),
    //slave interface
    .i_data_valid(imgDataValid),
    .i_data(imgData),
    .o_data_ready(),
    //master interface
    .o_data_valid(outDataValid),
    .o_data(outData),
    .i_data_ready(1'b1),
    //interrupt
    .o_intr(intr)
);   
    
endmodule


//`timescale 1ns / 1ps
////////////////////////////////////////////////////////////////////////////////////
//// Company: 
//// Engineer: 
//// 
//// Create Date: 04/02/2020 08:11:41 PM
//// Design Name: 
//// Module Name: tb
//// Project Name: 
//// Target Devices: 
//// Tool Versions: 
//// Description: 
//// A testbench for testing image data passthrough in `imageProcessTop`.
//// 
////////////////////////////////////////////////////////////////////////////////////

//`define headerSize 1080
//`define imageSize 512*512

//module tb();

//    // Clock and Reset
//    reg clk;
//    reg reset;

//    // Input data and control
//    reg [7:0] imgData;
//    reg imgDataValid;

//    // File handlers and counters
//    integer file, file1, fileLog, i;
//    integer sentSize = 0;

//    // DUT output
//    wire intr;
//    wire [7:0] outData;
//    wire outDataValid;
//    integer receivedData = 0;

//    // Clock generation
//    initial begin
//        clk = 1'b0;
//        forever #5 clk = ~clk; // 10 ns clock period
//    end

//    // Reset initialization
//    initial begin
//        reset = 0;
//        #100; // Wait 100 ns
//        reset = 1; // De-assert reset
//    end

//    // Test procedure
//    initial begin
//        imgDataValid = 0;

//        // Open files
//        file = $fopen("lena_gray.bmp", "rb");
//        if (file == 0) begin
//            $display("ERROR: Could not open input file lena_gray.bmp");
//            $stop;
//        end

//        file1 = $fopen("blurred_lena.bmp", "wb");
//        if (file1 == 0) begin
//            $display("ERROR: Could not create output file blurred_lena.bmp");
//            $stop;
//        end

//        fileLog = $fopen("simulation_log.txt", "w");
//        if (fileLog == 0) begin
//            $display("ERROR: Could not create log file simulation_log.txt");
//            $stop;
//        end

//        // Log start
//        $fwrite(fileLog, "Simulation started.\n");

//        // Copy BMP header directly to output
//        for (i = 0; i < `headerSize; i = i + 1) begin
//            $fscanf(file, "%c", imgData);
//            $fwrite(file1, "%c", imgData);
//            $fwrite(fileLog, "Header byte %d: %d\n", i, imgData);
//        end

//        // Send pixel data to DUT
//        for (i = 0; i < `imageSize; i = i + 1) begin
//            @(posedge clk);
//            $fscanf(file, "%c", imgData);
//            imgDataValid <= 1'b1; // Set valid signal
//            $fwrite(fileLog, "Sent data byte %d: %d\n", sentSize, imgData);
//            @(posedge clk);
//            imgDataValid <= 1'b0; // Clear valid signal
//            sentSize = sentSize + 1;
//        end

//        $fclose(file); // Close input file
//        $fwrite(fileLog, "All input data sent to DUT.\n");
//    end

//    // Capture DUT output
//    always @(posedge clk) begin
//        if (outDataValid) begin
//            $fwrite(file1, "%c", outData); // Write output data to file
//            $fwrite(fileLog, "Received data byte %d: %d\n", receivedData, outData);
//            receivedData = receivedData + 1;
//        end
//        if (receivedData == `imageSize) begin
//            $fwrite(fileLog, "All output data written to blurred_lena.bmp.\n");
//            $fclose(file1); // Close output file
//            $fclose(fileLog); // Close log file
//            $stop; // Stop simulation
//        end
//    end

//    // DUT instantiation
//    imageProcessTop dut (
//        .axi_clk(clk),
//        .axi_reset_n(reset),
//        // Slave interface
//        .i_data_valid(imgDataValid),
//        .i_data(imgData),
//        .o_data_ready(),
//        // Master interface
//        .o_data_valid(outDataValid),
//        .o_data(outData),
//        .i_data_ready(1'b1), // Always ready to accept output
//        // Interrupt
//        .o_intr(intr)
//    );

//endmodule
