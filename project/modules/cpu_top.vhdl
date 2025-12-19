architecture arch of cpu_top is

    -- =========================================================================
    --                          COMPONENT DECLARATIONS
    -- =========================================================================
    
    -- (Previous components: pipeline_reg, memory, alu, control_unit, reg32, reg_file, branching_unit are assumed declared as per your snippet)

    -- Adding the Missing Forwarding Unit (Based on your XML analysis)
    component forwarding_unit is
        Port (
            id_ex_rs : in STD_LOGIC_VECTOR(2 downto 0);
            id_ex_rt : in STD_LOGIC_VECTOR(2 downto 0);
            ex_mem_rd : in STD_LOGIC_VECTOR(2 downto 0);
            mem_wb_rd : in STD_LOGIC_VECTOR(2 downto 0);
            ex_mem_reg_write : in STD_LOGIC;
            mem_wb_reg_write : in STD_LOGIC;
            forward_a : out STD_LOGIC_VECTOR(1 downto 0);
            forward_b : out STD_LOGIC_VECTOR(1 downto 0)
        );
    end component;

    -- =========================================================================
    --                              SIGNALS
    -- =========================================================================

    -- --- IF Stage Signals ---
    signal pc_current, pc_next, pc_plus_1 : std_logic_vector(31 downto 0);
    signal instruction : std_logic_vector(31 downto 0);
    signal if_flush : std_logic := '0';

    -- --- ID Stage Signals (Inputs from Pipeline Reg) ---
    signal if_id_pc, if_id_instr : std_logic_vector(31 downto 0);
    
    -- Decode Outputs
    signal read_data1, read_data2 : std_logic_vector(31 downto 0);
    signal sign_ext_imm : std_logic_vector(31 downto 0);
    signal write_reg_addr : std_logic_vector(2 downto 0);
    
    -- Control Signals (Wired from Control Unit)
    signal cu_alu_op : std_logic_vector(3 downto 0);
    signal cu_reg_write, cu_mem_read, cu_mem_write, cu_alu_src, cu_mem_to_reg : std_logic;
    signal cu_branch_sel, cu_sp_sel : std_logic;
    signal cu_hlt, cu_stop_pc : std_logic;
    -- (Add other CU signals as needed from your entity)

    -- --- EX Stage Signals (Inputs from Pipeline Reg) ---
    signal id_ex_pc, id_ex_data1, id_ex_data2, id_ex_imm : std_logic_vector(31 downto 0);
    signal id_ex_rs, id_ex_rt, id_ex_rd : std_logic_vector(2 downto 0);
    signal id_ex_alu_op : std_logic_vector(3 downto 0);
    signal id_ex_ctrl_signals : std_logic_vector(10 downto 0); -- Bundle controls

    -- ALU Inputs/Outputs
    signal alu_in_a, alu_in_b : std_logic_vector(31 downto 0);
    signal alu_result : std_logic_vector(31 downto 0);
    signal alu_flags : std_logic_vector(2 downto 0);
    signal alu_zero : std_logic;
    
    -- Forwarding Logic
    signal forward_a_sel, forward_b_sel : std_logic_vector(1 downto 0);
    signal forwarded_a_val, forwarded_b_val : std_logic_vector(31 downto 0);

    -- --- MEM Stage Signals (Inputs from Pipeline Reg) ---
    signal ex_mem_alu_result, ex_mem_write_data : std_logic_vector(31 downto 0);
    signal ex_mem_rd : std_logic_vector(2 downto 0);
    signal ex_mem_reg_write, ex_mem_mem_read, ex_mem_mem_write : std_logic;
    
    -- Memory Data
    signal mem_read_data : std_logic_vector(31 downto 0);
    signal mem_address : std_logic_vector(31 downto 0);
    
    -- SP Logic
    signal sp_current, sp_next : std_logic_vector(31 downto 0);
    signal sp_alu_result : std_logic_vector(31 downto 0);

    -- --- WB Stage Signals (Inputs from Pipeline Reg) ---
    signal mem_wb_read_data, mem_wb_alu_result : std_logic_vector(31 downto 0);
    signal mem_wb_rd : std_logic_vector(2 downto 0);
    signal mem_wb_reg_write, mem_wb_mem_to_reg : std_logic;

    -- Final Write Back
    signal wb_final_data : std_logic_vector(31 downto 0);

begin

    -- =========================================================================
    --                          1. INSTRUCTION FETCH (IF)
    -- =========================================================================
    
    -- PC MUX (Select between Next Seq, Branch Target, or Stack Return)
    -- Assuming Branch Target comes from EX stage logic or ID stage
    pc_next <= mem_read_data when (cu_stop_pc = '1') else -- Stop/Halt Logic
               alu_result    when (cu_branch_sel = '1') else -- Branch Taken
               pc_plus_1;

    -- PC Register
    PC_Reg : reg32 port map (clk => clk, reset => reset, en => '1', d => pc_next, q => pc_current);

    -- PC Adder
    pc_plus_1 <= std_logic_vector(unsigned(pc_current) + 1);

    -- Instruction Memory Instance
    -- (Assuming 'memory' component is used for both instructions and data, typically distinct in FPGA)
    InstrMem : memory port map (
        clk => clk, reset => reset, 
        in_data => (others => '0'), -- Read Only
        out_data => instruction, 
        address => pc_current, 
        mem_write => '0', mem_read => '1'
    );

    -- IF/ID Pipeline Register
    fetchDecode : pipeline_reg
    generic map (n => 64) -- PC(32) + Instr(32)
    port map (
        clk => clk, enable => '1', -- Add stall logic to enable
        data_in => pc_plus_1 & instruction,
        data_out(63 downto 32) => if_id_pc,
        data_out(31 downto 0)  => if_id_instr
    );

    -- =========================================================================
    --                          2. INSTRUCTION DECODE (ID)
    -- =========================================================================

    -- Control Unit
    controlUnit : control_unit port map (
        opcode => if_id_instr(31 downto 22), -- Assuming Opcode bits
        int => int,
        HLT => cu_hlt,
        stop_pc => cu_stop_pc,
        ALU_op => cu_alu_op,
        reg_write_en => cu_reg_write,
        MEM_ALU => cu_mem_to_reg,
        ALU_immediate => cu_alu_src,
        mem_write_en => cu_mem_write,
        sp_sel => cu_sp_sel,
        branch_sel => cu_branch_sel,
        -- Map other signals...
        out_port_en => open, in_port_en => open
    );

    -- Register File
    RegFile : reg_file port map (
        clk => clk,
        write_enable => mem_wb_reg_write, -- Write comes from WB stage
        read_reg_address_1 => if_id_instr(20 downto 18), -- Rs
        read_reg_address_2 => if_id_instr(17 downto 15), -- Rt
        write_reg_address => mem_wb_rd,    -- Rd from WB
        write_data => wb_final_data,       -- Data from WB
        read_data_1 => read_data1,
        read_data_2 => read_data2
    );

    -- Sign Extension (Assuming 16-bit imm at bottom)
    sign_ext_imm <= std_logic_vector(resize(signed(if_id_instr(15 downto 0)), 32));

    -- Determine Destination Reg (Rt or Rd)
    -- MUX 50 Logic equivalent
    -- write_reg_addr <= if_id_instr(17 downto 15) when (R2_sel = '0') else if_id_instr(14 downto 12);

    -- ID/EX Pipeline Register
    decodeExecute : pipeline_reg
    generic map (n => 150) -- Sum of widths of all signals passing through
    port map (
        clk => clk, enable => '1',
        -- Concatenate Control Signals + Data
        data_in => cu_reg_write & cu_mem_to_reg & cu_mem_write & cu_alu_op & cu_alu_src & 
                   read_data1 & read_data2 & sign_ext_imm & 
                   if_id_instr(20 downto 18) & if_id_instr(17 downto 15) & if_id_instr(14 downto 12), -- Rs, Rt, Rd
        
        -- Slice Output back to signals
        data_out(149) => ex_mem_reg_write, -- Technically this goes to ID_EX signal first, strictly naming
        -- ... (Slice bits to id_ex_data1, id_ex_data2, etc.) ...
        data_out(105 downto 74) => id_ex_data1 -- Example mapping
    );
    -- NOTE: In a real file, you must carefully map bits to the id_ex_* signals declared above.

    -- =========================================================================
    --                          3. EXECUTE (EX)
    -- =========================================================================

    -- Forwarding Unit
    FwdUnit : forwarding_unit port map (
        id_ex_rs => id_ex_rs, 
        id_ex_rt => id_ex_rt,
        ex_mem_rd => ex_mem_rd, 
        mem_wb_rd => mem_wb_rd,
        ex_mem_reg_write => ex_mem_reg_write,
        mem_wb_reg_write => mem_wb_reg_write,
        forward_a => forward_a_sel,
        forward_b => forward_b_sel
    );

    -- Forwarding MUX A (MUX 245)
    with forward_a_sel select
        alu_in_a <= id_ex_data1       when "00",
                    ex_mem_alu_result when "10", -- Forward from Memory Stage
                    wb_final_data     when "01", -- Forward from WB Stage
                    id_ex_data1       when others;

    -- Forwarding MUX B (MUX 264) logic for Source 2
    with forward_b_sel select
        forwarded_b_val <= id_ex_data2       when "00",
                           ex_mem_alu_result when "10",
                           wb_final_data     when "01",
                           id_ex_data2       when others;

    -- ALU Source B Mux (Immediate Selection - MUX 25)
    alu_in_b <= forwarded_b_val when (id_ex_ctrl_signals(0) = '0') else id_ex_imm; -- Assuming bit 0 is alu_src

    -- ALU Instance
    Alu_Inst : alu port map (
        reset => reset, clk => clk,
        data_in1 => alu_in_a,
        data_in2 => alu_in_b,
        operation => id_ex_alu_op,
        counter => '0', -- Wire loop counter here if implemented
        data_out => alu_result,
        flag_values => alu_flags
    );

    -- EX/MEM Pipeline Register
    executeMemory : pipeline_reg generic map (n => 70) 
    port map (
        clk => clk, enable => '1',
        data_in => alu_result & forwarded_b_val & id_ex_rd, -- Pass Result, StoreData, DestReg
        data_out(69 downto 38) => ex_mem_alu_result -- Example slice
    );

    -- =========================================================================
    --                          4. MEMORY (MEM)
    -- =========================================================================

    -- Stack Pointer (SP) Logic
    SP_Reg : reg32 port map (clk => clk, reset => reset, en => '1', d => sp_next, q => sp_current);
    
    -- SP ALU (Simple increment/decrement based on signal)
    -- sp_next <= sp_current - 1 when push, sp_current + 1 when pop...

    -- Memory Address MUX (MUX 232)
    -- Selects between ALU Result and Stack Pointer
    mem_address <= ex_mem_alu_result when (cu_sp_sel = '0') else sp_current;

    -- Data Memory Instance
    DataMem : memory port map (
        clk => clk, reset => reset,
        in_data => ex_mem_write_data, -- Data to store
        out_data => mem_read_data,
        address => mem_address,
        mem_write => ex_mem_mem_write,
        mem_read => ex_mem_mem_read
    );

    -- MEM/WB Pipeline Register
    MemoryWB : pipeline_reg generic map (n => 70)
    port map (
        clk => clk, enable => '1',
        data_in => mem_read_data & ex_mem_alu_result & ex_mem_rd,
        data_out(69 downto 38) => mem_wb_read_data -- Example slice
    );

    -- =========================================================================
    --                          5. WRITE BACK (WB)
    -- =========================================================================

    -- Write Back MUX (MUX 48)
    wb_final_data <= mem_wb_alu_result when (mem_wb_mem_to_reg = '0') else
                     mem_wb_read_data; 
                     -- Add InPort Mux logic here if needed

    -- Output to ports
    out_port <= wb_final_data(3 downto 0); -- Example mapping

end arch;