#test.py
#=============================================================================
# Codigo de verificacion con Cocotb para NanoCpuSys
#=============================================================================
# Actualizacion para operar con cocotb 2.0 y versiones posteriores
#=============================================================================
#=============================================================================
# Author: Gerardo A. Laguna S.
# Universidad Autonoma Metropolitana
# Unidad Lerma
# 12.dic.2025
#=============================================================================

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles


@cocotb.test()
async def test_project(dut):
    dut._log.info("Start")

    # Set the clock period to 10 us (100 KHz)
    clock = Clock(dut.clk, 10, unit="us")
    cocotb.start_soon(clock.start())

    # Reset
    dut._log.info("Reset")
    dut.ena.value = 1
    dut.ui_in.value = 0
    dut.uio_in.value = 0
    dut.rst_n.value = 0
    await ClockCycles(dut.clk, 2)
    dut.rst_n.value = 1

    dut._log.info("Test project behavior")

    #!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
    #Masks definitions according to the pinout:
    #!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
    #
    # Inputs:
    #   ui[0]: "OUT_CTRL0"
    #   ui[1]: "OUT_CTRL1"
    #   ui[2]: "OUT_CTRL2"
    #   ui[3]: "SPI_SCK"
    #   ui[4]: "SPI_MOSI"
    #   ui[5]: "SPI_CS"
    #   ui[6]: "RUN"
    #   ui[7]: "MODE"
    #
    # Outputs:
    #   uo[0]: "OUT8B0"
    #   uo[1]: "OUT8B1"
    #   uo[2]: "OUT8B2"
    #   uo[3]: "OUT8B3"
    #   uo[4]: "OUT8B4"
    #   uo[5]: "OUT8B5"
    #   uo[6]: "OUT8B6"
    #   uo[7]: "OUT8B7"
    #
    # Bidirectional pins as otputs:
    #   uio[0]: "OUT4B0"
    #   uio[1]: "OUT4B1"
    #   uio[2]: "OUT4B2"
    #   uio[3]: "OUT4B3"
    #   uio[7]: "SPI_MISO"

    # Bidirectional pins as inputs:
    #   uio[4]: "EINT0"
    #   uio[5]: "EINT1"
    #   uio[6]: "EINT2"

    MSK_SPI_SCK_TO_ON = 0x08
    MSK_SPI_SCK_TO_OFF = 0xF7
    MSK_SPI_MOSI_TO_ON = 0x10
    MSK_SPI_MOSI_TO_OFF = 0xEF
    MSK_SPI_CS_TO_ON = 0x20
    MSK_SPI_CS_TO_OFF = 0xDF
    MSK_RUN_TO_ON = 0x40
    MSK_RUN_TO_OFF = 0xBF
    MSK_MODE_TO_ON = 0x80
    MSK_MODE_TO_OFF = 0x7F

    #!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
    # OUT8b and OUT4B setting
    #!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
    #   +--------+-------------+--------------------+
    #   |out_ctrl|    OUT8B    |       OUT4B        |
    #   +--------+-------------+--------------------+
    #   |   0    |  State_reg  |     R_reg[3:0]     | 
    #   +--------+-------------+--------------------+
    #   |   1    |  State_reg  |     R_reg[7:4]     | 
    #   +--------+-------------+--------------------+
    #   |   2    |  State_reg  |     R_reg[11:8]    |
    #   +--------+-------------+--------------------+
    #   |   3    |  State_reg  |     R_reg[15:12]   |
    #   +--------+-------------+--------------------+
    #   |   4    | R_reg[7:0]  |     F_reg[3:0]     |
    #   +--------+-------------+--------------------+
    #   |   5    | R_reg[15:8] |     F_reg[3:0]     | 
    #   +--------+-------------+--------------------+
    #   |   6    | R_reg[23:16]|     F_reg[7:4]     |
    #   +--------+-------------+--------------------+
    #   |   7    | R_reg[31:24]|     F_reg[7:4]     |
    #   +--------+-------------+--------------------+

    MSK_OUT_CTRL_TO_0 = 0xF8

    #!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
    #!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!


    #+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    #+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    # Programing mode (MODE=0) with OUT_CTRL=0 (OUT8B = State_reg, OUT4B = R_reg[3:0])
    #+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    #+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

    #Master SPI initial values:  
    dut.ui_in.value  = MSK_SPI_SCK_TO_ON | MSK_SPI_CS_TO_ON | MSK_SPI_MOSI_TO_ON
    await ClockCycles(dut.clk, 16)

    #+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    # Sequence of ROM write SPI commands to store Nano intructions
    #+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    #
    #    |-------------------------------|
    #    |         4 Bytes SPI word      |
    #    |-------------------------------|
    #    | RW  |  Address  |     Data    |                                                        
    #    | bit |   bits    |     bits    |                                                    
    #    |-----|-----------|-------------|
    #    | b31 | [b30:b16] |  [b15:b00]  |
    #    |-----|-----------|-------------|
    #
    #+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    #     SPI 15 bits address map:
    #
    #     -----+-----------+----------
    #    0x0000|           |                                                                  
    #          |  CPU ROM  |   SPI                                                              
    #    0x0FFF|           |   Code                                                          
    #     -----|-----------|   space
    #          |           |                                                             
    #          | Reserved  |                                                             
    #    0x3FFF|           |                                                             
    #     -----|-----------|---------
    #    0x4000|           |    
    #          |  CPU RAM  |   SPI                                                              
    #    0x47FF|           |   Data                                                          
    #     -----|-----------|   space
    #          |           |                                                             
    #          | Reserved  |                                                             
    #    0x7FFF|           |                                                                 
    #     -----|-----------|---------
    #    
    #+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

    #+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    # Write STOP intruction (0xFF) in loc 0x00 of CPU space code
    # SPI command word: 00000000000000000000000011111111 
    #+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
       #SCK period #1:
    dut.ui_in.value = dut.ui_in.value.integer &   MSK_SPI_CS_TO_OFF  &   MSK_SPI_MOSI_TO_OFF
    await ClockCycles(dut.clk, 1)
    ###SCK falling edge:
    dut.ui_in.value = dut.ui_in.value.integer &  MSK_SPI_SCK_TO_OFF
    await ClockCycles(dut.clk, 4)
    ###SCK rising edge:
    dut.ui_in.value = dut.ui_in.value.integer |  MSK_SPI_SCK_TO_ON
    await ClockCycles(dut.clk, 4)
    
    #SCK period #2:
    dut.ui_in.value = dut.ui_in.value.integer &  MSK_SPI_MOSI_TO_OFF
    await ClockCycles(dut.clk, 1)
    ###SCK falling edge:
    dut.ui_in.value = dut.ui_in.value.integer &  MSK_SPI_SCK_TO_OFF
    await ClockCycles(dut.clk, 4)
    ###SCK rising edge:
    dut.ui_in.value = dut.ui_in.value.integer |  MSK_SPI_SCK_TO_ON
    await ClockCycles(dut.clk, 4)

    #SCK period #3:
    dut.ui_in.value = dut.ui_in.value.integer &  MSK_SPI_MOSI_TO_OFF
    await ClockCycles(dut.clk, 1)
    ###SCK falling edge:
    dut.ui_in.value = dut.ui_in.value.integer &  MSK_SPI_SCK_TO_OFF
    await ClockCycles(dut.clk, 4)
    ###SCK rising edge:
    dut.ui_in.value = dut.ui_in.value.integer |  MSK_SPI_SCK_TO_ON
    await ClockCycles(dut.clk, 4)

    #SCK period #4:
    dut.ui_in.value = dut.ui_in.value.integer &  MSK_SPI_MOSI_TO_OFF
    await ClockCycles(dut.clk, 1)
    ###SCK falling edge:
    dut.ui_in.value = dut.ui_in.value.integer &  MSK_SPI_SCK_TO_OFF
    await ClockCycles(dut.clk, 4)
    ###SCK rising edge:
    dut.ui_in.value = dut.ui_in.value.integer |  MSK_SPI_SCK_TO_ON
    await ClockCycles(dut.clk, 4)

    #SCK period #5:
    dut.ui_in.value = dut.ui_in.value.integer &  MSK_SPI_MOSI_TO_OFF
    await ClockCycles(dut.clk, 1)
    ###SCK falling edge:
    dut.ui_in.value = dut.ui_in.value.integer &  MSK_SPI_SCK_TO_OFF
    await ClockCycles(dut.clk, 4)
    ###SCK rising edge:
    dut.ui_in.value = dut.ui_in.value.integer |  MSK_SPI_SCK_TO_ON
    await ClockCycles(dut.clk, 4)

    #SCK period #6:
    dut.ui_in.value = dut.ui_in.value.integer &  MSK_SPI_MOSI_TO_OFF
    await ClockCycles(dut.clk, 1)
    ###SCK falling edge:
    dut.ui_in.value = dut.ui_in.value.integer &  MSK_SPI_SCK_TO_OFF
    await ClockCycles(dut.clk, 4)
    ###SCK rising edge:
    dut.ui_in.value = dut.ui_in.value.integer |  MSK_SPI_SCK_TO_ON
    await ClockCycles(dut.clk, 4)

    #SCK period #7:
    dut.ui_in.value = dut.ui_in.value.integer &  MSK_SPI_MOSI_TO_OFF
    await ClockCycles(dut.clk, 1)
    ###SCK falling edge:
    dut.ui_in.value = dut.ui_in.value.integer &  MSK_SPI_SCK_TO_OFF
    await ClockCycles(dut.clk, 4)
    ###SCK rising edge:
    dut.ui_in.value = dut.ui_in.value.integer |  MSK_SPI_SCK_TO_ON
    await ClockCycles(dut.clk, 4)

    #SCK period #8:
    dut.ui_in.value = dut.ui_in.value.integer &  MSK_SPI_MOSI_TO_OFF
    await ClockCycles(dut.clk, 1)
    ###SCK falling edge:
    dut.ui_in.value = dut.ui_in.value.integer &  MSK_SPI_SCK_TO_OFF
    await ClockCycles(dut.clk, 4)
    ###SCK rising edge:
    dut.ui_in.value = dut.ui_in.value.integer |  MSK_SPI_SCK_TO_ON
    await ClockCycles(dut.clk, 4)

    #SCK period #9:
    dut.ui_in.value = dut.ui_in.value.integer &  MSK_SPI_MOSI_TO_OFF
    await ClockCycles(dut.clk, 1)
    ###SCK falling edge:
    dut.ui_in.value = dut.ui_in.value.integer &  MSK_SPI_SCK_TO_OFF
    await ClockCycles(dut.clk, 4)
    ###SCK rising edge:
    dut.ui_in.value = dut.ui_in.value.integer |  MSK_SPI_SCK_TO_ON
    await ClockCycles(dut.clk, 4)

    #SCK period #10:
    dut.ui_in.value = dut.ui_in.value.integer &  MSK_SPI_MOSI_TO_OFF
    await ClockCycles(dut.clk, 1)
    ###SCK falling edge:
    dut.ui_in.value = dut.ui_in.value.integer &  MSK_SPI_SCK_TO_OFF
    await ClockCycles(dut.clk, 4)
    ###SCK rising edge:
    dut.ui_in.value = dut.ui_in.value.integer |  MSK_SPI_SCK_TO_ON
    await ClockCycles(dut.clk, 4)

    #SCK period #11:
    dut.ui_in.value = dut.ui_in.value.integer &  MSK_SPI_MOSI_TO_OFF
    await ClockCycles(dut.clk, 1)
    ###SCK falling edge:
    dut.ui_in.value = dut.ui_in.value.integer &  MSK_SPI_SCK_TO_OFF
    await ClockCycles(dut.clk, 4)
    ###SCK rising edge:
    dut.ui_in.value = dut.ui_in.value.integer |  MSK_SPI_SCK_TO_ON
    await ClockCycles(dut.clk, 4)

    #SCK period #12:
    dut.ui_in.value = dut.ui_in.value.integer &  MSK_SPI_MOSI_TO_OFF
    await ClockCycles(dut.clk, 1)
    ###SCK falling edge:
    dut.ui_in.value = dut.ui_in.value.integer &  MSK_SPI_SCK_TO_OFF
    await ClockCycles(dut.clk, 4)
    ###SCK rising edge:
    dut.ui_in.value = dut.ui_in.value.integer |  MSK_SPI_SCK_TO_ON
    await ClockCycles(dut.clk, 4)

    #SCK period #13:
    dut.ui_in.value = dut.ui_in.value.integer &  MSK_SPI_MOSI_TO_OFF
    await ClockCycles(dut.clk, 1)
    ###SCK falling edge:
    dut.ui_in.value = dut.ui_in.value.integer &  MSK_SPI_SCK_TO_OFF
    await ClockCycles(dut.clk, 4)
    ###SCK rising edge:
    dut.ui_in.value = dut.ui_in.value.integer |  MSK_SPI_SCK_TO_ON
    await ClockCycles(dut.clk, 4)

    #SCK period #14:
    dut.ui_in.value = dut.ui_in.value.integer &  MSK_SPI_MOSI_TO_OFF
    await ClockCycles(dut.clk, 1)
    ###SCK falling edge:
    dut.ui_in.value = dut.ui_in.value.integer &  MSK_SPI_SCK_TO_OFF
    await ClockCycles(dut.clk, 4)
    ###SCK rising edge:
    dut.ui_in.value = dut.ui_in.value.integer |  MSK_SPI_SCK_TO_ON
    await ClockCycles(dut.clk, 4)

    #SCK period #15:
    dut.ui_in.value = dut.ui_in.value.integer &  MSK_SPI_MOSI_TO_OFF
    await ClockCycles(dut.clk, 1)
    ###SCK falling edge:
    dut.ui_in.value = dut.ui_in.value.integer &  MSK_SPI_SCK_TO_OFF
    await ClockCycles(dut.clk, 4)
    ###SCK rising edge:
    dut.ui_in.value = dut.ui_in.value.integer |  MSK_SPI_SCK_TO_ON
    await ClockCycles(dut.clk, 4)

    #SCK period #16:
    dut.ui_in.value = dut.ui_in.value.integer &  MSK_SPI_MOSI_TO_OFF
    await ClockCycles(dut.clk, 1)
    ###SCK falling edge:
    dut.ui_in.value = dut.ui_in.value.integer &  MSK_SPI_SCK_TO_OFF
    await ClockCycles(dut.clk, 4)
    ###SCK rising edge:
    dut.ui_in.value = dut.ui_in.value.integer |  MSK_SPI_SCK_TO_ON
    await ClockCycles(dut.clk, 4)

    #SCK period #17:
    dut.ui_in.value = dut.ui_in.value.integer &  MSK_SPI_MOSI_TO_OFF
    await ClockCycles(dut.clk, 1)
    ###SCK falling edge:
    dut.ui_in.value = dut.ui_in.value.integer &  MSK_SPI_SCK_TO_OFF
    await ClockCycles(dut.clk, 4)
    ###SCK rising edge:
    dut.ui_in.value = dut.ui_in.value.integer |  MSK_SPI_SCK_TO_ON
    await ClockCycles(dut.clk, 4)

    #SCK period #18:
    dut.ui_in.value = dut.ui_in.value.integer &  MSK_SPI_MOSI_TO_OFF
    await ClockCycles(dut.clk, 1)
    ###SCK falling edge:
    dut.ui_in.value = dut.ui_in.value.integer &  MSK_SPI_SCK_TO_OFF
    await ClockCycles(dut.clk, 4)
    ###SCK rising edge:
    dut.ui_in.value = dut.ui_in.value.integer |  MSK_SPI_SCK_TO_ON
    await ClockCycles(dut.clk, 4)

    #SCK period #19:
    dut.ui_in.value = dut.ui_in.value.integer &  MSK_SPI_MOSI_TO_OFF
    await ClockCycles(dut.clk, 1)
    ###SCK falling edge:
    dut.ui_in.value = dut.ui_in.value.integer &  MSK_SPI_SCK_TO_OFF
    await ClockCycles(dut.clk, 4)
    ###SCK rising edge:
    dut.ui_in.value = dut.ui_in.value.integer |  MSK_SPI_SCK_TO_ON
    await ClockCycles(dut.clk, 4)

    #SCK period #20:
    dut.ui_in.value = dut.ui_in.value.integer &  MSK_SPI_MOSI_TO_OFF
    await ClockCycles(dut.clk, 1)
    ###SCK falling edge:
    dut.ui_in.value = dut.ui_in.value.integer &  MSK_SPI_SCK_TO_OFF
    await ClockCycles(dut.clk, 4)
    ###SCK rising edge:
    dut.ui_in.value = dut.ui_in.value.integer |  MSK_SPI_SCK_TO_ON
    await ClockCycles(dut.clk, 4)

    #SCK period #21:
    dut.ui_in.value = dut.ui_in.value.integer &  MSK_SPI_MOSI_TO_OFF
    await ClockCycles(dut.clk, 1)
    ###SCK falling edge:
    dut.ui_in.value = dut.ui_in.value.integer &  MSK_SPI_SCK_TO_OFF
    await ClockCycles(dut.clk, 4)
    ###SCK rising edge:
    dut.ui_in.value = dut.ui_in.value.integer |  MSK_SPI_SCK_TO_ON
    await ClockCycles(dut.clk, 4)

    #SCK period #22:
    dut.ui_in.value = dut.ui_in.value.integer &  MSK_SPI_MOSI_TO_OFF
    await ClockCycles(dut.clk, 1)
    ###SCK falling edge:
    dut.ui_in.value = dut.ui_in.value.integer &  MSK_SPI_SCK_TO_OFF
    await ClockCycles(dut.clk, 4)
    ###SCK rising edge:
    dut.ui_in.value = dut.ui_in.value.integer |  MSK_SPI_SCK_TO_ON
    await ClockCycles(dut.clk, 4)

    #SCK period #23:
    dut.ui_in.value = dut.ui_in.value.integer &  MSK_SPI_MOSI_TO_OFF
    await ClockCycles(dut.clk, 1)
    ###SCK falling edge:
    dut.ui_in.value = dut.ui_in.value.integer &  MSK_SPI_SCK_TO_OFF
    await ClockCycles(dut.clk, 4)
    ###SCK rising edge:
    dut.ui_in.value = dut.ui_in.value.integer |  MSK_SPI_SCK_TO_ON
    await ClockCycles(dut.clk, 4)

    #SCK period #24:
    dut.ui_in.value = dut.ui_in.value.integer &  MSK_SPI_MOSI_TO_OFF
    await ClockCycles(dut.clk, 1)
    ###SCK falling edge:
    dut.ui_in.value = dut.ui_in.value.integer &  MSK_SPI_SCK_TO_OFF
    await ClockCycles(dut.clk, 4)
    ###SCK rising edge:
    dut.ui_in.value = dut.ui_in.value.integer |  MSK_SPI_SCK_TO_ON
    await ClockCycles(dut.clk, 4)

    #SCK period #25:
    dut.ui_in.value = dut.ui_in.value.integer |  MSK_SPI_MOSI_TO_ON
    await ClockCycles(dut.clk, 1)
    ###SCK falling edge:
    dut.ui_in.value = dut.ui_in.value.integer &  MSK_SPI_SCK_TO_OFF
    await ClockCycles(dut.clk, 4)
    ###SCK rising edge:
    dut.ui_in.value = dut.ui_in.value.integer |  MSK_SPI_SCK_TO_ON
    await ClockCycles(dut.clk, 4)

    #SCK period #26:
    dut.ui_in.value = dut.ui_in.value.integer |  MSK_SPI_MOSI_TO_ON
    await ClockCycles(dut.clk, 1)
    ###SCK falling edge:
    dut.ui_in.value = dut.ui_in.value.integer &  MSK_SPI_SCK_TO_OFF
    await ClockCycles(dut.clk, 4)
    ###SCK rising edge:
    dut.ui_in.value = dut.ui_in.value.integer |  MSK_SPI_SCK_TO_ON
    await ClockCycles(dut.clk, 4)

    #SCK period #27:
    dut.ui_in.value = dut.ui_in.value.integer |  MSK_SPI_MOSI_TO_ON
    await ClockCycles(dut.clk, 1)
    ###SCK falling edge:
    dut.ui_in.value = dut.ui_in.value.integer &  MSK_SPI_SCK_TO_OFF
    await ClockCycles(dut.clk, 4)
    ###SCK rising edge:
    dut.ui_in.value = dut.ui_in.value.integer |  MSK_SPI_SCK_TO_ON
    await ClockCycles(dut.clk, 4)

    #SCK period #28:
    dut.ui_in.value = dut.ui_in.value.integer |  MSK_SPI_MOSI_TO_ON
    await ClockCycles(dut.clk, 1)
    ###SCK falling edge:
    dut.ui_in.value = dut.ui_in.value.integer &  MSK_SPI_SCK_TO_OFF
    await ClockCycles(dut.clk, 4)
    ###SCK rising edge:
    dut.ui_in.value = dut.ui_in.value.integer |  MSK_SPI_SCK_TO_ON
    await ClockCycles(dut.clk, 4)

    #SCK period #29:
    dut.ui_in.value = dut.ui_in.value.integer |  MSK_SPI_MOSI_TO_ON
    await ClockCycles(dut.clk, 1)
    ###SCK falling edge:
    dut.ui_in.value = dut.ui_in.value.integer &  MSK_SPI_SCK_TO_OFF
    await ClockCycles(dut.clk, 4)
    ###SCK rising edge:
    dut.ui_in.value = dut.ui_in.value.integer |  MSK_SPI_SCK_TO_ON
    await ClockCycles(dut.clk, 4)

    #SCK period #30:
    dut.ui_in.value = dut.ui_in.value.integer |  MSK_SPI_MOSI_TO_ON
    await ClockCycles(dut.clk, 1)
    ###SCK falling edge:
    dut.ui_in.value = dut.ui_in.value.integer &  MSK_SPI_SCK_TO_OFF
    await ClockCycles(dut.clk, 4)
    ###SCK rising edge:
    dut.ui_in.value = dut.ui_in.value.integer |  MSK_SPI_SCK_TO_ON
    await ClockCycles(dut.clk, 4)

    #SCK period #31:
    dut.ui_in.value = dut.ui_in.value.integer |  MSK_SPI_MOSI_TO_ON
    await ClockCycles(dut.clk, 1)
    ###SCK falling edge:
    dut.ui_in.value = dut.ui_in.value.integer &  MSK_SPI_SCK_TO_OFF
    await ClockCycles(dut.clk, 4)
    ###SCK rising edge:
    dut.ui_in.value = dut.ui_in.value.integer |  MSK_SPI_SCK_TO_ON
    await ClockCycles(dut.clk, 4)

    #SCK period #32:
    dut.ui_in.value = dut.ui_in.value.integer |  MSK_SPI_MOSI_TO_ON
    await ClockCycles(dut.clk, 1)
    ###SCK falling edge:
    dut.ui_in.value = dut.ui_in.value.integer &  MSK_SPI_SCK_TO_OFF
    await ClockCycles(dut.clk, 4)
    ###SCK rising edge:
    dut.ui_in.value = dut.ui_in.value.integer |  MSK_SPI_SCK_TO_ON
    await ClockCycles(dut.clk, 4)

    ###Last SCK falling edge:
    dut.ui_in.value = dut.ui_in.value.integer &  MSK_SPI_SCK_TO_OFF
    await ClockCycles(dut.clk, 4)
    #Master SPI final values:
    dut.ui_in.value = MSK_SPI_CS_TO_ON  | MSK_SPI_MOSI_TO_ON | MSK_SPI_SCK_TO_ON
    await ClockCycles(dut.clk, 4)

    await ClockCycles(dut.clk, 16)

    expected_state = 0x00    #Stop state
    assert dut.uo_out.value == expected_state

    #+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    # Write NOP intruction (0x0) in loc 0x01 of CPU space code
    # SPI command word: 00000000000000010000000000000000 
    #+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
       #SCK period #1:
    dut.ui_in.value = dut.ui_in.value.integer &   MSK_SPI_CS_TO_OFF  &   MSK_SPI_MOSI_TO_OFF
    await ClockCycles(dut.clk, 1)
    ###SCK falling edge:
    dut.ui_in.value = dut.ui_in.value.integer &  MSK_SPI_SCK_TO_OFF
    await ClockCycles(dut.clk, 4)
    ###SCK rising edge:
    dut.ui_in.value = dut.ui_in.value.integer |  MSK_SPI_SCK_TO_ON
    await ClockCycles(dut.clk, 4)
    
    #SCK period #2:
    dut.ui_in.value = dut.ui_in.value.integer &  MSK_SPI_MOSI_TO_OFF
    await ClockCycles(dut.clk, 1)
    ###SCK falling edge:
    dut.ui_in.value = dut.ui_in.value.integer &  MSK_SPI_SCK_TO_OFF
    await ClockCycles(dut.clk, 4)
    ###SCK rising edge:
    dut.ui_in.value = dut.ui_in.value.integer |  MSK_SPI_SCK_TO_ON
    await ClockCycles(dut.clk, 4)

    #SCK period #3:
    dut.ui_in.value = dut.ui_in.value.integer &  MSK_SPI_MOSI_TO_OFF
    await ClockCycles(dut.clk, 1)
    ###SCK falling edge:
    dut.ui_in.value = dut.ui_in.value.integer &  MSK_SPI_SCK_TO_OFF
    await ClockCycles(dut.clk, 4)
    ###SCK rising edge:
    dut.ui_in.value = dut.ui_in.value.integer |  MSK_SPI_SCK_TO_ON
    await ClockCycles(dut.clk, 4)

    #SCK period #4:
    dut.ui_in.value = dut.ui_in.value.integer &  MSK_SPI_MOSI_TO_OFF
    await ClockCycles(dut.clk, 1)
    ###SCK falling edge:
    dut.ui_in.value = dut.ui_in.value.integer &  MSK_SPI_SCK_TO_OFF
    await ClockCycles(dut.clk, 4)
    ###SCK rising edge:
    dut.ui_in.value = dut.ui_in.value.integer |  MSK_SPI_SCK_TO_ON
    await ClockCycles(dut.clk, 4)

    #SCK period #5:
    dut.ui_in.value = dut.ui_in.value.integer &  MSK_SPI_MOSI_TO_OFF
    await ClockCycles(dut.clk, 1)
    ###SCK falling edge:
    dut.ui_in.value = dut.ui_in.value.integer &  MSK_SPI_SCK_TO_OFF
    await ClockCycles(dut.clk, 4)
    ###SCK rising edge:
    dut.ui_in.value = dut.ui_in.value.integer |  MSK_SPI_SCK_TO_ON
    await ClockCycles(dut.clk, 4)

    #SCK period #6:
    dut.ui_in.value = dut.ui_in.value.integer &  MSK_SPI_MOSI_TO_OFF
    await ClockCycles(dut.clk, 1)
    ###SCK falling edge:
    dut.ui_in.value = dut.ui_in.value.integer &  MSK_SPI_SCK_TO_OFF
    await ClockCycles(dut.clk, 4)
    ###SCK rising edge:
    dut.ui_in.value = dut.ui_in.value.integer |  MSK_SPI_SCK_TO_ON
    await ClockCycles(dut.clk, 4)

    #SCK period #7:
    dut.ui_in.value = dut.ui_in.value.integer &  MSK_SPI_MOSI_TO_OFF
    await ClockCycles(dut.clk, 1)
    ###SCK falling edge:
    dut.ui_in.value = dut.ui_in.value.integer &  MSK_SPI_SCK_TO_OFF
    await ClockCycles(dut.clk, 4)
    ###SCK rising edge:
    dut.ui_in.value = dut.ui_in.value.integer |  MSK_SPI_SCK_TO_ON
    await ClockCycles(dut.clk, 4)

    #SCK period #8:
    dut.ui_in.value = dut.ui_in.value.integer &  MSK_SPI_MOSI_TO_OFF
    await ClockCycles(dut.clk, 1)
    ###SCK falling edge:
    dut.ui_in.value = dut.ui_in.value.integer &  MSK_SPI_SCK_TO_OFF
    await ClockCycles(dut.clk, 4)
    ###SCK rising edge:
    dut.ui_in.value = dut.ui_in.value.integer |  MSK_SPI_SCK_TO_ON
    await ClockCycles(dut.clk, 4)

    #SCK period #9:
    dut.ui_in.value = dut.ui_in.value.integer &  MSK_SPI_MOSI_TO_OFF
    await ClockCycles(dut.clk, 1)
    ###SCK falling edge:
    dut.ui_in.value = dut.ui_in.value.integer &  MSK_SPI_SCK_TO_OFF
    await ClockCycles(dut.clk, 4)
    ###SCK rising edge:
    dut.ui_in.value = dut.ui_in.value.integer |  MSK_SPI_SCK_TO_ON
    await ClockCycles(dut.clk, 4)

    #SCK period #10:
    dut.ui_in.value = dut.ui_in.value.integer &  MSK_SPI_MOSI_TO_OFF
    await ClockCycles(dut.clk, 1)
    ###SCK falling edge:
    dut.ui_in.value = dut.ui_in.value.integer &  MSK_SPI_SCK_TO_OFF
    await ClockCycles(dut.clk, 4)
    ###SCK rising edge:
    dut.ui_in.value = dut.ui_in.value.integer |  MSK_SPI_SCK_TO_ON
    await ClockCycles(dut.clk, 4)

    #SCK period #11:
    dut.ui_in.value = dut.ui_in.value.integer &  MSK_SPI_MOSI_TO_OFF
    await ClockCycles(dut.clk, 1)
    ###SCK falling edge:
    dut.ui_in.value = dut.ui_in.value.integer &  MSK_SPI_SCK_TO_OFF
    await ClockCycles(dut.clk, 4)
    ###SCK rising edge:
    dut.ui_in.value = dut.ui_in.value.integer |  MSK_SPI_SCK_TO_ON
    await ClockCycles(dut.clk, 4)

    #SCK period #12:
    dut.ui_in.value = dut.ui_in.value.integer &  MSK_SPI_MOSI_TO_OFF
    await ClockCycles(dut.clk, 1)
    ###SCK falling edge:
    dut.ui_in.value = dut.ui_in.value.integer &  MSK_SPI_SCK_TO_OFF
    await ClockCycles(dut.clk, 4)
    ###SCK rising edge:
    dut.ui_in.value = dut.ui_in.value.integer |  MSK_SPI_SCK_TO_ON
    await ClockCycles(dut.clk, 4)

    #SCK period #13:
    dut.ui_in.value = dut.ui_in.value.integer &  MSK_SPI_MOSI_TO_OFF
    await ClockCycles(dut.clk, 1)
    ###SCK falling edge:
    dut.ui_in.value = dut.ui_in.value.integer &  MSK_SPI_SCK_TO_OFF
    await ClockCycles(dut.clk, 4)
    ###SCK rising edge:
    dut.ui_in.value = dut.ui_in.value.integer |  MSK_SPI_SCK_TO_ON
    await ClockCycles(dut.clk, 4)

    #SCK period #14:
    dut.ui_in.value = dut.ui_in.value.integer &  MSK_SPI_MOSI_TO_OFF
    await ClockCycles(dut.clk, 1)
    ###SCK falling edge:
    dut.ui_in.value = dut.ui_in.value.integer &  MSK_SPI_SCK_TO_OFF
    await ClockCycles(dut.clk, 4)
    ###SCK rising edge:
    dut.ui_in.value = dut.ui_in.value.integer |  MSK_SPI_SCK_TO_ON
    await ClockCycles(dut.clk, 4)

    #SCK period #15:
    dut.ui_in.value = dut.ui_in.value.integer &  MSK_SPI_MOSI_TO_OFF
    await ClockCycles(dut.clk, 1)
    ###SCK falling edge:
    dut.ui_in.value = dut.ui_in.value.integer &  MSK_SPI_SCK_TO_OFF
    await ClockCycles(dut.clk, 4)
    ###SCK rising edge:
    dut.ui_in.value = dut.ui_in.value.integer |  MSK_SPI_SCK_TO_ON
    await ClockCycles(dut.clk, 4)

    #SCK period #16:
    dut.ui_in.value = dut.ui_in.value.integer |  MSK_SPI_MOSI_TO_ON
    await ClockCycles(dut.clk, 1)
    ###SCK falling edge:
    dut.ui_in.value = dut.ui_in.value.integer &  MSK_SPI_SCK_TO_OFF
    await ClockCycles(dut.clk, 4)
    ###SCK rising edge:
    dut.ui_in.value = dut.ui_in.value.integer |  MSK_SPI_SCK_TO_ON
    await ClockCycles(dut.clk, 4)

    #SCK period #17:
    dut.ui_in.value = dut.ui_in.value.integer &  MSK_SPI_MOSI_TO_OFF
    await ClockCycles(dut.clk, 1)
    ###SCK falling edge:
    dut.ui_in.value = dut.ui_in.value.integer &  MSK_SPI_SCK_TO_OFF
    await ClockCycles(dut.clk, 4)
    ###SCK rising edge:
    dut.ui_in.value = dut.ui_in.value.integer |  MSK_SPI_SCK_TO_ON
    await ClockCycles(dut.clk, 4)

    #SCK period #18:
    dut.ui_in.value = dut.ui_in.value.integer &  MSK_SPI_MOSI_TO_OFF
    await ClockCycles(dut.clk, 1)
    ###SCK falling edge:
    dut.ui_in.value = dut.ui_in.value.integer &  MSK_SPI_SCK_TO_OFF
    await ClockCycles(dut.clk, 4)
    ###SCK rising edge:
    dut.ui_in.value = dut.ui_in.value.integer |  MSK_SPI_SCK_TO_ON
    await ClockCycles(dut.clk, 4)

    #SCK period #19:
    dut.ui_in.value = dut.ui_in.value.integer &  MSK_SPI_MOSI_TO_OFF
    await ClockCycles(dut.clk, 1)
    ###SCK falling edge:
    dut.ui_in.value = dut.ui_in.value.integer &  MSK_SPI_SCK_TO_OFF
    await ClockCycles(dut.clk, 4)
    ###SCK rising edge:
    dut.ui_in.value = dut.ui_in.value.integer |  MSK_SPI_SCK_TO_ON
    await ClockCycles(dut.clk, 4)

    #SCK period #20:
    dut.ui_in.value = dut.ui_in.value.integer &  MSK_SPI_MOSI_TO_OFF
    await ClockCycles(dut.clk, 1)
    ###SCK falling edge:
    dut.ui_in.value = dut.ui_in.value.integer &  MSK_SPI_SCK_TO_OFF
    await ClockCycles(dut.clk, 4)
    ###SCK rising edge:
    dut.ui_in.value = dut.ui_in.value.integer |  MSK_SPI_SCK_TO_ON
    await ClockCycles(dut.clk, 4)

    #SCK period #21:
    dut.ui_in.value = dut.ui_in.value.integer &  MSK_SPI_MOSI_TO_OFF
    await ClockCycles(dut.clk, 1)
    ###SCK falling edge:
    dut.ui_in.value = dut.ui_in.value.integer &  MSK_SPI_SCK_TO_OFF
    await ClockCycles(dut.clk, 4)
    ###SCK rising edge:
    dut.ui_in.value = dut.ui_in.value.integer |  MSK_SPI_SCK_TO_ON
    await ClockCycles(dut.clk, 4)

    #SCK period #22:
    dut.ui_in.value = dut.ui_in.value.integer &  MSK_SPI_MOSI_TO_OFF
    await ClockCycles(dut.clk, 1)
    ###SCK falling edge:
    dut.ui_in.value = dut.ui_in.value.integer &  MSK_SPI_SCK_TO_OFF
    await ClockCycles(dut.clk, 4)
    ###SCK rising edge:
    dut.ui_in.value = dut.ui_in.value.integer |  MSK_SPI_SCK_TO_ON
    await ClockCycles(dut.clk, 4)

    #SCK period #23:
    dut.ui_in.value = dut.ui_in.value.integer &  MSK_SPI_MOSI_TO_OFF
    await ClockCycles(dut.clk, 1)
    ###SCK falling edge:
    dut.ui_in.value = dut.ui_in.value.integer &  MSK_SPI_SCK_TO_OFF
    await ClockCycles(dut.clk, 4)
    ###SCK rising edge:
    dut.ui_in.value = dut.ui_in.value.integer |  MSK_SPI_SCK_TO_ON
    await ClockCycles(dut.clk, 4)

    #SCK period #24:
    dut.ui_in.value = dut.ui_in.value.integer &  MSK_SPI_MOSI_TO_OFF
    await ClockCycles(dut.clk, 1)
    ###SCK falling edge:
    dut.ui_in.value = dut.ui_in.value.integer &  MSK_SPI_SCK_TO_OFF
    await ClockCycles(dut.clk, 4)
    ###SCK rising edge:
    dut.ui_in.value = dut.ui_in.value.integer |  MSK_SPI_SCK_TO_ON
    await ClockCycles(dut.clk, 4)

    #SCK period #25:
    dut.ui_in.value = dut.ui_in.value.integer &  MSK_SPI_MOSI_TO_OFF
    await ClockCycles(dut.clk, 1)
    ###SCK falling edge:
    dut.ui_in.value = dut.ui_in.value.integer &  MSK_SPI_SCK_TO_OFF
    await ClockCycles(dut.clk, 4)
    ###SCK rising edge:
    dut.ui_in.value = dut.ui_in.value.integer |  MSK_SPI_SCK_TO_ON
    await ClockCycles(dut.clk, 4)

    #SCK period #26:
    dut.ui_in.value = dut.ui_in.value.integer &  MSK_SPI_MOSI_TO_OFF
    await ClockCycles(dut.clk, 1)
    ###SCK falling edge:
    dut.ui_in.value = dut.ui_in.value.integer &  MSK_SPI_SCK_TO_OFF
    await ClockCycles(dut.clk, 4)
    ###SCK rising edge:
    dut.ui_in.value = dut.ui_in.value.integer |  MSK_SPI_SCK_TO_ON
    await ClockCycles(dut.clk, 4)

    #SCK period #27:
    dut.ui_in.value = dut.ui_in.value.integer &  MSK_SPI_MOSI_TO_OFF
    await ClockCycles(dut.clk, 1)
    ###SCK falling edge:
    dut.ui_in.value = dut.ui_in.value.integer &  MSK_SPI_SCK_TO_OFF
    await ClockCycles(dut.clk, 4)
    ###SCK rising edge:
    dut.ui_in.value = dut.ui_in.value.integer |  MSK_SPI_SCK_TO_ON
    await ClockCycles(dut.clk, 4)

    #SCK period #28:
    dut.ui_in.value = dut.ui_in.value.integer &  MSK_SPI_MOSI_TO_OFF
    await ClockCycles(dut.clk, 1)
    ###SCK falling edge:
    dut.ui_in.value = dut.ui_in.value.integer &  MSK_SPI_SCK_TO_OFF
    await ClockCycles(dut.clk, 4)
    ###SCK rising edge:
    dut.ui_in.value = dut.ui_in.value.integer |  MSK_SPI_SCK_TO_ON
    await ClockCycles(dut.clk, 4)

    #SCK period #29:
    dut.ui_in.value = dut.ui_in.value.integer &  MSK_SPI_MOSI_TO_OFF
    await ClockCycles(dut.clk, 1)
    ###SCK falling edge:
    dut.ui_in.value = dut.ui_in.value.integer &  MSK_SPI_SCK_TO_OFF
    await ClockCycles(dut.clk, 4)
    ###SCK rising edge:
    dut.ui_in.value = dut.ui_in.value.integer |  MSK_SPI_SCK_TO_ON
    await ClockCycles(dut.clk, 4)

    #SCK period #30:
    dut.ui_in.value = dut.ui_in.value.integer &  MSK_SPI_MOSI_TO_OFF
    await ClockCycles(dut.clk, 1)
    ###SCK falling edge:
    dut.ui_in.value = dut.ui_in.value.integer &  MSK_SPI_SCK_TO_OFF
    await ClockCycles(dut.clk, 4)
    ###SCK rising edge:
    dut.ui_in.value = dut.ui_in.value.integer |  MSK_SPI_SCK_TO_ON
    await ClockCycles(dut.clk, 4)

    #SCK period #31:
    dut.ui_in.value = dut.ui_in.value.integer &  MSK_SPI_MOSI_TO_OFF
    await ClockCycles(dut.clk, 1)
    ###SCK falling edge:
    dut.ui_in.value = dut.ui_in.value.integer &  MSK_SPI_SCK_TO_OFF
    await ClockCycles(dut.clk, 4)
    ###SCK rising edge:
    dut.ui_in.value = dut.ui_in.value.integer |  MSK_SPI_SCK_TO_ON
    await ClockCycles(dut.clk, 4)

    #SCK period #32:
    dut.ui_in.value = dut.ui_in.value.integer &  MSK_SPI_MOSI_TO_OFF
    await ClockCycles(dut.clk, 1)
    ###SCK falling edge:
    dut.ui_in.value = dut.ui_in.value.integer &  MSK_SPI_SCK_TO_OFF
    await ClockCycles(dut.clk, 4)
    ###SCK rising edge:
    dut.ui_in.value = dut.ui_in.value.integer |  MSK_SPI_SCK_TO_ON
    await ClockCycles(dut.clk, 4)

    ###Last SCK falling edge:
    dut.ui_in.value = dut.ui_in.value.integer &  MSK_SPI_SCK_TO_OFF
    await ClockCycles(dut.clk, 4)
    #Master SPI final values:
    dut.ui_in.value = MSK_SPI_CS_TO_ON  | MSK_SPI_MOSI_TO_ON | MSK_SPI_SCK_TO_ON
    await ClockCycles(dut.clk, 4)

    await ClockCycles(dut.clk, 16)

    expected_state = 0x00    #Stop state
    assert dut.uo_out.value == expected_state

    #+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    #+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    # Execution mode (MODE=1) with OUT_CTRL=0 (OUT8B = State_reg, OUT4B = R_reg[3:0])
    #+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    #+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

    dut.ui_in.value = MSK_MODE_TO_ON & MSK_OUT_CTRL_TO_0
    await ClockCycles(dut.clk, 16)

    #+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    # Run the coded program (Just the STOP instruction)
    #+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

    dut.ui_in.value = dut.ui_in.value.integer | MSK_RUN_TO_ON	#Press RUN

    while(dut.uo_out.value == 0): #While Stop state
        await ClockCycles(dut.clk, 1)

    expected_state = 0x01   #Start state
    assert dut.uo_out.value == expected_state

    dut.ui_in.value = dut.ui_in.value.integer &  MSK_RUN_TO_OFF	#Release RUN

    while(dut.uo_out.value == 1): #While Start state
        await ClockCycles(dut.clk, 1)

    expected_state = 0x02   #Fetch-decode state
    assert dut.uo_out.value == expected_state

    while(dut.uo_out.value == 2): #While Fetch-decode state
        await ClockCycles(dut.clk, 1)

    expected_state = 0x00   #Stop state
    assert dut.uo_out.value == expected_state

