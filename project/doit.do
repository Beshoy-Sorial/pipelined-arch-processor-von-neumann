# ModelSim Do File for cpu_top Testing
# This script initializes ALL signals (inputs and internal) to zero with reset active for 2 clock cycles

# Set up time unit
quietly set PERIOD 100ns

# Force clock to start at 0
force -freeze clk 0 0, 1 {50ns} -r 100ns

# ========================================
# ADD WAVES FIRST - Before Forcing
# ========================================

# Add Register File Contents
add wave -divider "REGISTER FILE CONTENTS"
add wave -radix hexadecimal sim:/cpu_top/RegFile/register_file(0)
add wave -radix hexadecimal sim:/cpu_top/RegFile/register_file(1)
add wave -radix hexadecimal sim:/cpu_top/RegFile/register_file(2)
add wave -radix hexadecimal sim:/cpu_top/RegFile/register_file(3)
add wave -radix hexadecimal sim:/cpu_top/RegFile/register_file(4)
add wave -radix hexadecimal sim:/cpu_top/RegFile/register_file(5)
add wave -radix hexadecimal sim:/cpu_top/RegFile/register_file(6)
add wave -radix hexadecimal sim:/cpu_top/RegFile/register_file(7)
add wave -radix hexadecimal sim:/cpu_top/MYAlu/*
add wave -radix hexadecimal sim:/cpu_top/controlUnit/reg_write_en
# Add all signals to wave window
add wave -position insertpoint sim:/cpu_top/*

# ========== FORCE INPUT SIGNALS ==========
force -freeze reset 1
force -freeze int 0
# Force in_port to stay at 0x0000000E (will NOT be released later)
force -freeze in_port 32'h0000000E

# ========== FORCE INTERNAL SIGNALS ==========

# PC and SP signals
force -freeze /cpu_top/enable_pc 0
force -freeze /cpu_top/pc_next_data 32'h00000000
force -freeze /cpu_top/pc 32'h00000000
force -freeze /cpu_top/sp_next_data 32'h00000000
force -freeze /cpu_top/sp 32'h00000000

# Memory signals
force -freeze /cpu_top/mem_next_data 32'h00000000
force -freeze /cpu_top/mem_data 32'h00000000
force -freeze /cpu_top/mem_address 32'h00000000
force -freeze /cpu_top/mem_write 0
force -freeze /cpu_top/mem_read 0
force -freeze /cpu_top/mem_data_in 32'h00000000
force -freeze /cpu_top/mem_data_out 32'h00000000

# Pipeline register signals - Fetch/Decode
force -freeze /cpu_top/fetchDecode_pipe_enable 0
force -freeze /cpu_top/fetchDecode_pipe_input 64'h0000000000000000
force -freeze /cpu_top/fetchDecode_pipe_output 64'h0000000000000000

# Register file signals
force -freeze /cpu_top/reg_file_write_enable 0
force -freeze /cpu_top/R1_reg_file_in 3'b000
force -freeze /cpu_top/R2_reg_file_in 3'b000
force -freeze /cpu_top/WB_address_reg_file_in 3'b000
force -freeze /cpu_top/WB_data_reg_file_in 32'h00000000
force -freeze /cpu_top/R1_reg_file_out 32'h00000000
force -freeze /cpu_top/R2_reg_file_out 32'h00000000

# Opcode and Control Unit signals
force -freeze /cpu_top/opcode 10'b0000000000
force -freeze /cpu_top/HLT_cu 0
force -freeze /cpu_top/stop_pc_cu 0
force -freeze /cpu_top/ALU_op_cu 4'b0000
force -freeze /cpu_top/out_port_en_cu 0
force -freeze /cpu_top/in_port_en_cu 0
force -freeze /cpu_top/reg_write_en_cu 0
force -freeze /cpu_top/MEM_ALU_cu 0
force -freeze /cpu_top/swap_sel_cu 0
force -freeze /cpu_top/ALU_immediate_cu 0
force -freeze /cpu_top/R2_sel_cu 0
force -freeze /cpu_top/exe_counter_en_cu 0
force -freeze /cpu_top/mem_counter_en_cu 0
force -freeze /cpu_top/flush_decode_decode_cu 0
force -freeze /cpu_top/flush_decode_execute_cu 0
force -freeze /cpu_top/flush_decode_mem_cu 0
force -freeze /cpu_top/flush_branch_branch_cu 0
force -freeze /cpu_top/mem_write_en_cu 0
force -freeze /cpu_top/pc_address_cu 0
force -freeze /cpu_top/write_data_or_pc_cu 0
force -freeze /cpu_top/sp_sel_cu 0
force -freeze /cpu_top/sp_alu_op_cu 2'b00
force -freeze /cpu_top/branch_unit_en_cu 0
force -freeze /cpu_top/branch_type_cu 3'b000
force -freeze /cpu_top/branch_sel_cu 0
force -freeze /cpu_top/pc_form_mem_cu 0
force -freeze /cpu_top/index_sel_cu 0

# Branch unit signals
force -freeze /cpu_top/branch_sel_bu 0

# Pipeline register signals - Decode/Execute
force -freeze /cpu_top/decodeExecute_pipe_enable 0
force -freeze /cpu_top/decodeExecute_pipe_input 235'h00000000000000000000000000000000000000000000000000000000000
force -freeze /cpu_top/decodeExecute_pipe_output 235'h00000000000000000000000000000000000000000000000000000000000

# Execute stage signals
force -freeze /cpu_top/exe_counter_out 0
force -freeze /cpu_top/alu_data_out 32'h00000000
force -freeze /cpu_top/restore_alu 0
force -freeze /cpu_top/store_alu 0
force -freeze /cpu_top/flag_values_alu 3'b000
force -freeze /cpu_top/flagas_reg_out 3'b000
force -freeze /cpu_top/flush_decode_execute_branch 0

# Pipeline register signals - Execute/Memory
force -freeze /cpu_top/executeMemory_pipe_input 200'h0000000000000000000000000000000000000000000000000000
force -freeze /cpu_top/executeMemory_pipe_output 200'h0000000000000000000000000000000000000000000000000000
force -freeze /cpu_top/executeMemory_pipe_enable 0

# Pipeline register signals - Memory/WB
force -freeze /cpu_top/memWB_pipe_input 200'h0000000000000000000000000000000000000000000000000000
force -freeze /cpu_top/memWB_pipe_output 200'h0000000000000000000000000000000000000000000000000000
force -freeze /cpu_top/memWB_pipe_enable 0

# Memory stage counter
force -freeze /cpu_top/mem_counter_out 0

# Forwarding unit signals
force -freeze /cpu_top/forward_a 2'b00
force -freeze /cpu_top/forward_b 2'b00

# Additional connection signals
force -freeze /cpu_top/pc_data 32'h00000000
force -freeze /cpu_top/pc_or_address 32'h00000000
force -freeze /cpu_top/flush_decode 0
force -freeze /cpu_top/alu_inport_imm 32'h00000000
force -freeze /cpu_top/r2_or_imm 32'h00000000
force -freeze /cpu_top/alu_data_in1 32'h00000000
force -freeze /cpu_top/alu_data_in2 32'h00000000
force -freeze /cpu_top/r1_or_index 32'h00000000
force -freeze /cpu_top/r1_or_r2 3'b000
force -freeze /cpu_top/r1_r2_or_rdest 3'b000

# Run for 2 clock cycles (200ns)
run 200ns

echo "=========================================="
echo "Releasing reset and setting it to 0"
echo "=========================================="

# Release reset and set it to 0 (inactive)
force -freeze reset 0
run 100ns

echo "=========================================="
echo "Releasing all forced signals after 2 clock cycles"
echo "=========================================="

# ========== RELEASE ALL FORCES ==========

# Release input signals - EXCEPT in_port which stays at 0x0000000E
noforce reset
noforce int
# Keep in_port forced to 0x0000000E
# noforce in_port

# Release PC and SP signals
noforce /cpu_top/enable_pc
noforce /cpu_top/pc_next_data
noforce /cpu_top/pc
noforce /cpu_top/sp_next_data
noforce /cpu_top/sp

# Release Memory signals
noforce /cpu_top/mem_next_data
noforce /cpu_top/mem_data
noforce /cpu_top/mem_address
noforce /cpu_top/mem_write
noforce /cpu_top/mem_read
noforce /cpu_top/mem_data_in
noforce /cpu_top/mem_data_out

# Release Fetch/Decode pipeline
noforce /cpu_top/fetchDecode_pipe_enable
noforce /cpu_top/fetchDecode_pipe_input
noforce /cpu_top/fetchDecode_pipe_output

# Release Register file signals
noforce /cpu_top/reg_file_write_enable
noforce /cpu_top/R1_reg_file_in
noforce /cpu_top/R2_reg_file_in
noforce /cpu_top/WB_address_reg_file_in
noforce /cpu_top/WB_data_reg_file_in
noforce /cpu_top/R1_reg_file_out
noforce /cpu_top/R2_reg_file_out

# Release Control Unit signals
noforce /cpu_top/opcode
noforce /cpu_top/HLT_cu
noforce /cpu_top/stop_pc_cu
noforce /cpu_top/ALU_op_cu
noforce /cpu_top/out_port_en_cu
noforce /cpu_top/in_port_en_cu
noforce /cpu_top/reg_write_en_cu
noforce /cpu_top/MEM_ALU_cu
noforce /cpu_top/swap_sel_cu
noforce /cpu_top/ALU_immediate_cu
noforce /cpu_top/R2_sel_cu
noforce /cpu_top/exe_counter_en_cu
noforce /cpu_top/mem_counter_en_cu
noforce /cpu_top/flush_decode_decode_cu
noforce /cpu_top/flush_decode_execute_cu
noforce /cpu_top/flush_decode_mem_cu
noforce /cpu_top/flush_branch_branch_cu
noforce /cpu_top/mem_write_en_cu
noforce /cpu_top/pc_address_cu
noforce /cpu_top/write_data_or_pc_cu
noforce /cpu_top/sp_sel_cu
noforce /cpu_top/sp_alu_op_cu
noforce /cpu_top/branch_unit_en_cu
noforce /cpu_top/branch_type_cu
noforce /cpu_top/branch_sel_cu
noforce /cpu_top/pc_form_mem_cu
noforce /cpu_top/index_sel_cu

# Release Branch unit signals
noforce /cpu_top/branch_sel_bu

# Release Decode/Execute pipeline
noforce /cpu_top/decodeExecute_pipe_enable
noforce /cpu_top/decodeExecute_pipe_input
noforce /cpu_top/decodeExecute_pipe_output

# Release Execute stage signals
noforce /cpu_top/exe_counter_out
noforce /cpu_top/alu_data_out
noforce /cpu_top/restore_alu
noforce /cpu_top/store_alu
noforce /cpu_top/flag_values_alu
noforce /cpu_top/flagas_reg_out
noforce /cpu_top/flush_decode_execute_branch

# Release Execute/Memory pipeline
noforce /cpu_top/executeMemory_pipe_input
noforce /cpu_top/executeMemory_pipe_output
noforce /cpu_top/executeMemory_pipe_enable

# Release Memory/WB pipeline
noforce /cpu_top/memWB_pipe_input
noforce /cpu_top/memWB_pipe_output
noforce /cpu_top/memWB_pipe_enable

# Release Memory stage counter
noforce /cpu_top/mem_counter_out

# Release Forwarding unit signals
noforce /cpu_top/forward_a
noforce /cpu_top/forward_b

# Release Additional connection signals
noforce /cpu_top/pc_data
noforce /cpu_top/pc_or_address
noforce /cpu_top/flush_decode
noforce /cpu_top/alu_inport_imm
noforce /cpu_top/r2_or_imm
noforce /cpu_top/alu_data_in1
noforce /cpu_top/alu_data_in2
noforce /cpu_top/r1_or_index
noforce /cpu_top/r1_or_r2
noforce /cpu_top/r1_r2_or_rdest

echo "=========================================="
echo "Initialization complete - All signals released"
echo "in_port remains at 0x0000000E (14 decimal)"
echo "Clock continues running"
echo "Ready for testing"
echo "=========================================="

# Re-force in_port to ensure it stays at the correct value
force -freeze in_port 32'h0000000E

# Run for many more cycles to observe CPU behavior
run 3us

echo "=========================================="
echo "Simulation complete - 30 cycles executed"
echo "=========================================="

# Save the waveform
# Uncomment the following line if you want to automatically save the waveform
# write wave wave.do