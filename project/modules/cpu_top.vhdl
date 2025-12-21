LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

ENTITY cpu_top IS
    PORT (
        clk : IN STD_LOGIC;
        reset, int : IN STD_LOGIC;
        in_port : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
        out_port : OUT STD_LOGIC_VECTOR(31 DOWNTO 0)
    );
END cpu_top;

ARCHITECTURE arch OF cpu_top IS
    COMPONENT forwarding_unit IS
        PORT (
            id_ex_rs : IN STD_LOGIC_VECTOR(2 DOWNTO 0);
            id_ex_rt : IN STD_LOGIC_VECTOR(2 DOWNTO 0);
            ex_mem_rd : IN STD_LOGIC_VECTOR(2 DOWNTO 0);
            mem_wb_rd : IN STD_LOGIC_VECTOR(2 DOWNTO 0);
            counter : IN STD_LOGIC;
            ex_mem_reg_write : IN STD_LOGIC;
            mem_wb_reg_write : IN STD_LOGIC;
            forward_a : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
            forward_b : OUT STD_LOGIC_VECTOR(1 DOWNTO 0)
        );
    END COMPONENT;

    COMPONENT one_bit_counter IS
        PORT (
            clk : IN STD_LOGIC;
            counter_enable : IN STD_LOGIC;
            count_out : OUT STD_LOGIC);
    END COMPONENT;

    COMPONENT pipeline_reg IS
        GENERIC (n : INTEGER := 32);
        PORT (
            clk : IN STD_LOGIC;
            enable : IN STD_LOGIC;
            data_in : IN STD_LOGIC_VECTOR(n - 1 DOWNTO 0);
            data_out : OUT STD_LOGIC_VECTOR(n - 1 DOWNTO 0)
        );
    END COMPONENT;

    COMPONENT memory IS PORT (
        clk : IN STD_LOGIC;
        reset : IN STD_LOGIC;
        in_data : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
        out_data : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
        address : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
        mem_write : IN STD_LOGIC;
        mem_read : IN STD_LOGIC
        );
    END COMPONENT;

    COMPONENT alu IS
        GENERIC (n : INTEGER := 32);
        PORT (
            reset : IN STD_LOGIC;
            clk : IN STD_LOGIC;
            data_in1 : IN STD_LOGIC_VECTOR(n - 1 DOWNTO 0);
            data_in2 : IN STD_LOGIC_VECTOR(n - 1 DOWNTO 0);
            operation : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
            counter : IN STD_LOGIC;
            data_out : OUT STD_LOGIC_VECTOR(n - 1 DOWNTO 0);
            Restore : OUT STD_LOGIC;
            store : OUT STD_LOGIC;
            flag_values : OUT STD_LOGIC_VECTOR(2 DOWNTO 0) --NZC 
        );
    END COMPONENT;

    COMPONENT control_unit_v1 IS
        PORT (
            opcode : IN STD_LOGIC_VECTOR(9 DOWNTO 0);
            reset : IN STD_LOGIC;
            HLT : OUT STD_LOGIC;
            stop_pc : OUT STD_LOGIC;
            ALU_op : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
            out_port_en : OUT STD_LOGIC;
            in_port_en : OUT STD_LOGIC;
            reg_write_en : OUT STD_LOGIC;
            MEM_ALU : OUT STD_LOGIC;
            swap_sel : OUT STD_LOGIC;
            ALU_immediate : OUT STD_LOGIC;
            R2_sel : OUT STD_LOGIC;
            exe_counter_en : OUT STD_LOGIC;
            mem_counter_en : OUT STD_LOGIC;
            flush_decode_decode : OUT STD_LOGIC;
            flush_decode_execute : OUT STD_LOGIC;
            flush_decode_mem : OUT STD_LOGIC;
            flush_branch_branch : OUT STD_LOGIC;
            mem_write_en : OUT STD_LOGIC;
            pc_address : OUT STD_LOGIC;
            write_data_or_pc : OUT STD_LOGIC;
            sp_sel : OUT STD_LOGIC;
            sp_alu_op : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
            branch_unit_en : OUT STD_LOGIC;
            branch_type : OUT STD_LOGIC_VECTOR(2 DOWNTO 0);
            branch_sel : OUT STD_LOGIC;
            pc_form_mem : OUT STD_LOGIC;
            index_sel : OUT STD_LOGIC
        );
    END COMPONENT;

    COMPONENT reg32 IS
        PORT (
            clk : IN STD_LOGIC; -- Clock signal
            reset : IN STD_LOGIC; -- always 0
            en : IN STD_LOGIC; -- Write enable
            d : IN STD_LOGIC_VECTOR(31 DOWNTO 0); -- 32-bit Data input
            q : OUT STD_LOGIC_VECTOR(31 DOWNTO 0) -- 32-bit Data output
        );
    END COMPONENT;

    COMPONENT reg_file IS
        PORT (
            clk : IN STD_LOGIC;
            write_enable : IN STD_LOGIC;
            read_reg_address_1 : IN STD_LOGIC_VECTOR(2 DOWNTO 0);
            read_reg_address_2 : IN STD_LOGIC_VECTOR(2 DOWNTO 0);
            write_reg_address : IN STD_LOGIC_VECTOR(2 DOWNTO 0);
            write_data : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
            read_data_1 : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
            read_data_2 : OUT STD_LOGIC_VECTOR(31 DOWNTO 0)
        );
    END COMPONENT;
    COMPONENT branching_unit IS
        PORT (
            en : IN STD_LOGIC;
            flags : IN STD_LOGIC_VECTOR(2 DOWNTO 0); -- zero, negative, carry
            branch_type : IN STD_LOGIC_VECTOR(2 DOWNTO 0);
            branch_sel : OUT STD_LOGIC;
            flush_decode_execute_branch : OUT STD_LOGIC
        );
    END COMPONENT;

    COMPONENT Reg3BitStoreRestore IS
        PORT (
            clk : IN STD_LOGIC;
            rst : IN STD_LOGIC;
            store : IN STD_LOGIC; -- Save current data to cache
            restore : IN STD_LOGIC; -- Load data from cache to main
            load : IN STD_LOGIC; -- Standard write enable
            data_in : IN STD_LOGIC_VECTOR(2 DOWNTO 0);
            data_out : OUT STD_LOGIC_VECTOR(2 DOWNTO 0)
        );
    END COMPONENT;

    SIGNAL enable_pc : STD_LOGIC; --
    SIGNAL pc_next_data : STD_LOGIC_VECTOR(31 DOWNTO 0); --
    SIGNAL pc : STD_LOGIC_VECTOR(31 DOWNTO 0); --

    SIGNAL sp_next_data : STD_LOGIC_VECTOR(31 DOWNTO 0); --
    SIGNAL sp : STD_LOGIC_VECTOR(31 DOWNTO 0); --
    SIGNAL mem_next_data : STD_LOGIC_VECTOR(31 DOWNTO 0); --
    SIGNAL mem_data : STD_LOGIC_VECTOR(31 DOWNTO 0); --
    SIGNAL mem_address : STD_LOGIC_VECTOR(31 DOWNTO 0); --
    SIGNAL mem_write : STD_LOGIC; --
    SIGNAL mem_read : STD_LOGIC;

    SIGNAL fetchDecode_pipe_enable : STD_LOGIC; --
    SIGNAL fetchDecode_pipe_input : STD_LOGIC_VECTOR(63 DOWNTO 0); --
    SIGNAL fetchDecode_pipe_output : STD_LOGIC_VECTOR(63 DOWNTO 0); --

    SIGNAL mem_data_in : STD_LOGIC_VECTOR(31 DOWNTO 0); --
    SIGNAL mem_data_out : STD_LOGIC_VECTOR(31 DOWNTO 0); --
    SIGNAL reg_file_write_enable : STD_LOGIC;
    SIGNAL R1_reg_file_in : STD_LOGIC_VECTOR(2 DOWNTO 0);
    SIGNAL R2_reg_file_in : STD_LOGIC_VECTOR(2 DOWNTO 0);
    SIGNAL WB_address_reg_file_in : STD_LOGIC_VECTOR(2 DOWNTO 0);
    SIGNAL WB_data_reg_file_in : STD_LOGIC_VECTOR(31 DOWNTO 0);

    SIGNAL R1_reg_file_out : STD_LOGIC_VECTOR(31 DOWNTO 0);
    SIGNAL R2_reg_file_out : STD_LOGIC_VECTOR(31 DOWNTO 0);

    SIGNAL opcode : STD_LOGIC_VECTOR(9 DOWNTO 0);
    SIGNAL HLT_cu : STD_LOGIC;
    SIGNAL stop_pc_cu : STD_LOGIC;
    SIGNAL ALU_op_cu : STD_LOGIC_VECTOR(3 DOWNTO 0);
    SIGNAL out_port_en_cu : STD_LOGIC;
    SIGNAL in_port_en_cu : STD_LOGIC;
    SIGNAL reg_write_en_cu : STD_LOGIC;
    SIGNAL MEM_ALU_cu : STD_LOGIC;
    SIGNAL swap_sel_cu : STD_LOGIC;
    SIGNAL ALU_immediate_cu : STD_LOGIC;
    SIGNAL R2_sel_cu : STD_LOGIC;
    SIGNAL exe_counter_en_cu : STD_LOGIC;
    SIGNAL mem_counter_en_cu : STD_LOGIC;
    SIGNAL flush_decode_decode_cu : STD_LOGIC;
    SIGNAL flush_decode_execute_cu : STD_LOGIC;
    SIGNAL flush_decode_mem_cu : STD_LOGIC;
    SIGNAL flush_branch_branch_cu : STD_LOGIC;
    SIGNAL mem_write_en_cu : STD_LOGIC;
    SIGNAL pc_address_cu : STD_LOGIC;
    SIGNAL write_data_or_pc_cu : STD_LOGIC;
    SIGNAL sp_sel_cu : STD_LOGIC;
    SIGNAL sp_alu_op_cu : STD_LOGIC_VECTOR(1 DOWNTO 0);
    SIGNAL branch_unit_en_cu : STD_LOGIC;
    SIGNAL branch_type_cu : STD_LOGIC_VECTOR(2 DOWNTO 0);
    SIGNAL branch_sel_cu : STD_LOGIC;
    SIGNAL pc_form_mem_cu : STD_LOGIC;
    SIGNAL index_sel_cu : STD_LOGIC;

    SIGNAL branch_sel_bu : STD_LOGIC; --

    SIGNAL decodeExecute_pipe_enable : STD_LOGIC; --
    SIGNAL decodeExecute_pipe_input : STD_LOGIC_VECTOR(234 DOWNTO 0); --
    SIGNAL decodeExecute_pipe_output : STD_LOGIC_VECTOR(234 DOWNTO 0); --
    SIGNAL exe_counter_out : STD_LOGIC; --

    SIGNAL alu_data_out : STD_LOGIC_VECTOR(31 DOWNTO 0); --
    SIGNAL restore_alu : STD_LOGIC; --
    SIGNAL store_alu : STD_LOGIC; --
    SIGNAL flag_values_alu : STD_LOGIC_VECTOR(2 DOWNTO 0); -- NZC

    SIGNAL flagas_reg_out : STD_LOGIC_VECTOR(2 DOWNTO 0); -- NZC

    SIGNAL flush_decode_execute_branch : STD_LOGIC; --

    SIGNAL executeMemory_pipe_input : STD_LOGIC_VECTOR(199 DOWNTO 0); --
    SIGNAL executeMemory_pipe_output : STD_LOGIC_VECTOR(199 DOWNTO 0);
    SIGNAL executeMemory_pipe_enable : STD_LOGIC; --

    SIGNAL memWB_pipe_input : STD_LOGIC_VECTOR(199 DOWNTO 0); --
    SIGNAL memWB_pipe_output : STD_LOGIC_VECTOR(199 DOWNTO 0); --
    SIGNAL memWB_pipe_enable : STD_LOGIC; --

    SIGNAL forward_a : STD_LOGIC_VECTOR(1 DOWNTO 0);
    SIGNAL forward_b : STD_LOGIC_VECTOR(1 DOWNTO 0);
    -- pc connections --
    SIGNAL pc_data : STD_LOGIC_VECTOR(31 DOWNTO 0);

    -- memory connections --
    SIGNAL pc_or_address : STD_LOGIC_VECTOR(31 DOWNTO 0);
    SIGNAL flush_decode : STD_LOGIC;
    SIGNAL alu_inport_imm : STD_LOGIC_VECTOR(31 DOWNTO 0);
    SIGNAL r2_or_imm : STD_LOGIC_VECTOR(31 DOWNTO 0);
    SIGNAL alu_data_in1 : STD_LOGIC_VECTOR(31 DOWNTO 0);
    SIGNAL alu_data_in2 : STD_LOGIC_VECTOR(31 DOWNTO 0);
    SIGNAL r1_or_index : STD_LOGIC_VECTOR(31 DOWNTO 0);

    SIGNAL r1_or_r2 : STD_LOGIC_VECTOR(2 DOWNTO 0);
    SIGNAL r1_r2_or_rdest : STD_LOGIC_VECTOR(2 DOWNTO 0);
    SIGNAL mem_counter_out : STD_LOGIC;
    SIGNAL debug : STD_LOGIC_VECTOR(31 downto 0);
    SIGNAL debug1 : STD_LOGIC;
BEGIN

    PC_REG : reg32
    PORT MAP(
        clk => clk,
        reset => reset,
        en => enable_pc,
        d => pc_next_data,
        q => pc
    );

    SP_REG : reg32
    PORT MAP(
        clk => clk,
        reset => reset,
        en => '1',
        d => sp_next_data,
        q => sp
    );

    mem_read <= NOT mem_write;
    MemoryINS : memory
    PORT MAP(
        clk => clk,
        reset => '0',
        in_data => mem_data_in,
        out_data => mem_data,
        address => mem_next_data,
        mem_write => mem_write,
        mem_read => mem_read
    );
    mem_data_in <= executeMemory_pipe_output(199 DOWNTO 168) WHEN (executeMemory_pipe_output(159) = '0') ELSE
        executeMemory_pipe_output(31 DOWNTO 0);
    -- fetchDecode_pipe_input(31 downto 0) <= mem_data;
    fetchDecode_pipe_input(63 DOWNTO 32) <= STD_LOGIC_VECTOR(unsigned(pc) + 1);
    fetchDecode : pipeline_reg
    GENERIC MAP(
        n => 64
    )
    PORT MAP(
        clk => clk,
        enable => fetchDecode_pipe_enable,
        data_in => fetchDecode_pipe_input,
        data_out => fetchDecode_pipe_output
    );

    RegFile : reg_file
    PORT MAP(
        clk => clk,
        write_enable => reg_file_write_enable,
        read_reg_address_1 => R1_reg_file_in,
        read_reg_address_2 => R2_reg_file_in,
        write_reg_address => WB_address_reg_file_in,
        write_data =>  WB_data_reg_file_in,
        read_data_1 => R1_reg_file_out,
        read_data_2 => R2_reg_file_out
    );

    opcode <= fetchDecode_pipe_output(31 DOWNTO 22);
    controlUnit : control_unit_v1
    PORT MAP(
        opcode => opcode,
        reset => reset,
        HLT => HLT_cu,
        stop_pc => stop_pc_cu,
        ALU_op => ALU_op_cu,
        out_port_en => out_port_en_cu,
        in_port_en => in_port_en_cu,
        reg_write_en => reg_write_en_cu,
        MEM_ALU => MEM_ALU_cu,
        ALU_immediate => ALU_immediate_cu,
        R2_sel => R2_sel_cu,
        exe_counter_en => exe_counter_en_cu,
        mem_counter_en => mem_counter_en_cu,
        flush_decode_decode => flush_decode_decode_cu,
        flush_decode_execute => flush_decode_execute_cu,
        flush_decode_mem => flush_decode_mem_cu,
        flush_branch_branch => flush_branch_branch_cu,
        mem_write_en => mem_write_en_cu,
        pc_address => pc_address_cu,
        write_data_or_pc => write_data_or_pc_cu,
        sp_sel => sp_sel_cu,
        sp_alu_op => sp_alu_op_cu,
        branch_unit_en => branch_unit_en_cu,
        branch_type => branch_type_cu,
        branch_sel => branch_sel_cu,
        pc_form_mem => pc_form_mem_cu,
        index_sel => index_sel_cu
    );

    -- 1. DATA SIGNALS (Bits 0 to 142)
    decodeExecute_pipe_input(31 DOWNTO 0) <= R1_reg_file_out;
    decodeExecute_pipe_input(63 DOWNTO 32) <= R2_reg_file_out;
    decodeExecute_pipe_input(95 DOWNTO 64) <= fetchDecode_pipe_output(63 DOWNTO 32); -- PC + 1
    -- decodeExecute_pipe_input(125 downto 96) <= mem_data_out; -- Immediate / Offset value
    decodeExecute_pipe_input(128 DOWNTO 126) <= fetchDecode_pipe_output(21 DOWNTO 19); -- Rdest
    decodeExecute_pipe_input(131 DOWNTO 129) <= fetchDecode_pipe_output(18 DOWNTO 16); -- Rsrc1
    decodeExecute_pipe_input(134 DOWNTO 132) <= fetchDecode_pipe_output(15 DOWNTO 13); -- Rsrc2
    decodeExecute_pipe_input(135) <= reg_file_write_enable;

    -- 2. CONTROL UNIT SIGNALS (In port map order)
    -- Starting from bit 136...
    decodeExecute_pipe_input(136) <= HLT_cu;
    decodeExecute_pipe_input(137) <= stop_pc_cu;
    decodeExecute_pipe_input(141 DOWNTO 138) <= ALU_op_cu;
    decodeExecute_pipe_input(142) <= out_port_en_cu;
    decodeExecute_pipe_input(143) <= in_port_en_cu;
    decodeExecute_pipe_input(144) <= reg_write_en_cu;
    decodeExecute_pipe_input(145) <= MEM_ALU_cu;
    decodeExecute_pipe_input(146) <= fetchDecode_pipe_output(0); -- index
    decodeExecute_pipe_input(147) <= swap_sel_cu;
    decodeExecute_pipe_input(149) <= ALU_immediate_cu;
    decodeExecute_pipe_input(150) <= R2_sel_cu;
    decodeExecute_pipe_input(151) <= exe_counter_en_cu;
    decodeExecute_pipe_input(152) <= mem_counter_en_cu;
    decodeExecute_pipe_input(153) <= flush_decode_decode_cu;
    decodeExecute_pipe_input(154) <= flush_decode_execute_cu;
    decodeExecute_pipe_input(155) <= flush_decode_mem_cu;
    decodeExecute_pipe_input(156) <= flush_branch_branch_cu;
    decodeExecute_pipe_input(157) <= mem_write_en_cu;
    decodeExecute_pipe_input(158) <= pc_address_cu;
    decodeExecute_pipe_input(159) <= write_data_or_pc_cu;
    decodeExecute_pipe_input(160) <= sp_sel_cu;
    decodeExecute_pipe_input(162 DOWNTO 161) <= sp_alu_op_cu;
    decodeExecute_pipe_input(163) <= branch_unit_en_cu;
    -- decodeExecute_pipe_input(164)            <= branch_type_cu;
    decodeExecute_pipe_input(165) <= branch_sel_cu;
    decodeExecute_pipe_input(166) <= pc_form_mem_cu;
    decodeExecute_pipe_input(167) <= index_sel_cu;

    decodeExecute_pipe_input(199 DOWNTO 168) <= fetchDecode_pipe_output(63 DOWNTO 32); -- PC + 1 backup for branch instructions
    decodeExecute_pipe_input(202 DOWNTO 200) <= branch_type_cu;
    decodeExecute_pipe_input(234 DOWNTO 203) <= mem_data;
    decodeExecute : pipeline_reg
    GENERIC MAP(
        n => 235
    )
    PORT MAP(
        clk => clk,
        enable => decodeExecute_pipe_enable,
        data_in => decodeExecute_pipe_input,
        data_out => decodeExecute_pipe_output
    );

    exeCounter : one_bit_counter
    PORT MAP(
        clk => clk,
        counter_enable => decodeExecute_pipe_output(151),
        count_out => exe_counter_out
    );

    MYAlu : alu
    GENERIC MAP(
        n => 32
    )
    PORT MAP(
        reset => '0',
        clk => clk,
        data_in1 => alu_data_in1,
        data_in2 => alu_data_in2,
        operation => decodeExecute_pipe_output(141 DOWNTO 138),
        counter => exe_counter_out,
        data_out => alu_data_out,
        Restore => restore_alu,
        store => store_alu,
        flag_values => flag_values_alu --NZC 
    );

    flagreg : Reg3BitStoreRestore
    PORT MAP(
        clk => clk,
        rst => '0',
        store => store_alu,
        restore => restore_alu,
        load => '1',
        data_in => flag_values_alu,
        data_out => flagas_reg_out -- NZC
    );

    branchingUnit : branching_unit
    PORT MAP(
        en => decodeExecute_pipe_output(162),
        flags => flagas_reg_out,
        branch_type => decodeExecute_pipe_output(163 DOWNTO 161),
        branch_sel => branch_sel_bu,
        flush_decode_execute_branch => flush_decode_execute_branch
    );

    executeMemory_pipe_input(31 DOWNTO 0) <= alu_data_out;
    executeMemory_pipe_input(63 DOWNTO 32) <= in_port;
    executeMemory_pipe_input(95 DOWNTO 64) <= decodeExecute_pipe_output(234 DOWNTO 203);
    executeMemory_pipe_input(128 DOWNTO 126) <= r1_r2_or_rdest; -- Rdest
    executeMemory_pipe_input(167 DOWNTO 136) <= decodeExecute_pipe_output(167 DOWNTO 136); -- control signals
    executeMemory_pipe_input(199 DOWNTO 168) <= decodeExecute_pipe_output(199 DOWNTO 168); -- PC + 1 backup for branch i
    executeMemory : pipeline_reg
    GENERIC MAP(
        n => 200
    )
    PORT MAP(
        clk => clk,
        enable => executeMemory_pipe_enable,
        data_in => executeMemory_pipe_input,
        data_out => executeMemory_pipe_output
    );

    memCounter : one_bit_counter
    PORT MAP(
        clk => clk,
        counter_enable => executeMemory_pipe_output(152),
        count_out => mem_counter_out
    );
    memWB_pipe_input(31 DOWNTO 0) <= executeMemory_pipe_output(31 DOWNTO 0); -- ALU result
    memWB_pipe_input(63 DOWNTO 32) <= executeMemory_pipe_output(63 DOWNTO 32); -- in_port data
    memWB_pipe_input(95 DOWNTO 64) <= executeMemory_pipe_output(95 DOWNTO 64); -- immediate
    memWB_pipe_input(127 DOWNTO 96) <= mem_data; -- mem data
    memWB_pipe_input(130 DOWNTO 128) <= executeMemory_pipe_output(128 DOWNTO 126); -- Rdest
    memWB_pipe_input(167 DOWNTO 136) <= executeMemory_pipe_output(167 DOWNTO 136); -- control signals
    memWB_pipe_input(199 DOWNTO 168) <= executeMemory_pipe_output(199 DOWNTO 168); -- PC + 1 backup for branch i
    MemoryWB : pipeline_reg
    GENERIC MAP(
        n => 200
    )
    PORT MAP(
        clk => clk,
        enable => '0',
        data_in => memWB_pipe_input,
        data_out => memWB_pipe_output
    );
    FWDunit : forwarding_unit
    PORT MAP(
        id_ex_rs => decodeExecute_pipe_output(131 DOWNTO 129),
        id_ex_rt => decodeExecute_pipe_output(134 DOWNTO 132),
        ex_mem_rd => executeMemory_pipe_output(128 DOWNTO 126),
        mem_wb_rd => memWB_pipe_output(128 DOWNTO 126),
        counter => exe_counter_out,
        ex_mem_reg_write => executeMemory_pipe_output(135),
        mem_wb_reg_write => memWB_pipe_output(135),
        forward_a => forward_a,
        forward_b => forward_b
    );

    -- CONNECTIONS --

    -- program counter connections --
    pc_next_data <= mem_data WHEN (executeMemory_pipe_output(166) = '1' OR reset = '1')
        ELSE
        pc_data;

    pc_data <= decodeExecute_pipe_output(234 DOWNTO 203) WHEN branch_sel_bu = '1' OR branch_sel_cu = '1'
        ELSE
        STD_LOGIC_VECTOR(unsigned(pc) + 1);

    enable_pc <= NOT executeMemory_pipe_output(137) AND NOT HLT_cu;

    -- stack pointer connections --
    sp_next_data <= STD_LOGIC_VECTOR(unsigned(sp) + 1) WHEN executeMemory_pipe_output(161 DOWNTO 160) = "01"
        ELSE
        STD_LOGIC_VECTOR(unsigned(sp) - 1) WHEN executeMemory_pipe_output(161 DOWNTO 160) = "10"
        ELSE
        sp;

    -- memory connections --
    pc_or_address <= pc WHEN executeMemory_pipe_output(158) = '0'
        ELSE
        executeMemory_pipe_output(31 DOWNTO 0);

    mem_next_data <= (OTHERS => '0') WHEN reset = '1'
        ELSE
        pc_or_address WHEN executeMemory_pipe_output(160) = '0'
        ELSE
        sp;
    mem_write <= executeMemory_pipe_output(157) AND NOT exe_counter_out;

    fetchDecode_pipe_input(31 DOWNTO 0) <= mem_data WHEN flush_decode = '0'
ELSE
    (OTHERS => '0');

    flush_decode <= '1' WHEN (flush_decode_decode_cu = '1' OR decodeExecute_pipe_output(154) = '1' OR executeMemory_pipe_output(155) = '1' OR flush_decode_execute_branch = '1') ELSE
        '0';
    fetchDecode_pipe_enable <= (NOT reset AND hlt_cu) OR (decodeExecute_pipe_output(152) AND NOT exe_counter_out) OR (executeMemory_pipe_output(152) AND NOT mem_counter_out);

    -- regfile --  
    R1_reg_file_in <= fetchDecode_pipe_output(18 DOWNTO 16);
    R2_reg_file_in <= fetchDecode_pipe_output(21 DOWNTO 19);
    WB_address_reg_file_in <= memWB_pipe_output(130 DOWNTO 128);
    reg_file_write_enable <= memWB_pipe_output(144);

    debug1 <= memWB_pipe_output(149);
    debug <=  memWB_pipe_output(63 DOWNTO 32);
    WB_data_reg_file_in <= memWB_pipe_output(127 DOWNTO 96) WHEN memWB_pipe_output(145) = '1'
        ELSE
        alu_inport_imm;
    alu_inport_imm <= memWB_pipe_output(63 DOWNTO 32) WHEN memWB_pipe_output(143) = '1'
        ELSE
        memWB_pipe_output(95 DOWNTO 64) WHEN memWB_pipe_output(149) = '1'
        ELSE
        memWB_pipe_output(31 DOWNTO 0);

    -- decodeExecute enable --
    decodeExecute_pipe_enable <= (decodeExecute_pipe_output(152) AND NOT exe_counter_out) OR (executeMemory_pipe_output(152) AND NOT mem_counter_out);
    executeMemory_pipe_enable <= (executeMemory_pipe_output(152)  AND NOT mem_counter_out);
    -- executeMemory enable --
    memWB_pipe_enable <= (executeMemory_pipe_output(152) AND NOT mem_counter_out) OR (memWB_pipe_output(152) AND NOT mem_counter_out);

    r2_or_imm <= decodeExecute_pipe_output(234 DOWNTO 203) WHEN decodeExecute_pipe_output(150) = '1'
        ELSE
        decodeExecute_pipe_output(63 DOWNTO 32);

    alu_data_in2 <= r2_or_imm WHEN forward_b = "00"
        ELSE
        memWB_pipe_output(31 DOWNTO 0) WHEN forward_b = "01"
        ELSE
        WB_data_reg_file_in;

    -- R1_reg_file_in <= decodeExecute_pipe_output(125 downto 123);
    -- R2_reg_file_in <= decodeExecute_pipe_output(128 downto 126);
    r1_or_index <= decodeExecute_pipe_output(31 DOWNTO 0) WHEN index_sel_cu = '0'
        ELSE
        (31 DOWNTO 1 => '0') & decodeExecute_pipe_output(146);

    alu_data_in1 <= r1_or_index WHEN forward_a = "00"
        ELSE
        memWB_pipe_output(31 DOWNTO 0) WHEN forward_a = "01"
        ELSE
        WB_data_reg_file_in;

    r1_or_r2 <= decodeExecute_pipe_output(131 DOWNTO 129) WHEN exe_counter_out = '1'
        ELSE
        decodeExecute_pipe_output(134 DOWNTO 132);

    r1_r2_or_rdest <= r1_or_r2 WHEN decodeExecute_pipe_output(147) = '1'
        ELSE
        decodeExecute_pipe_output(128 DOWNTO 126);

    out_port <= decodeExecute_pipe_output(31 DOWNTO 0) WHEN decodeExecute_pipe_output(142) = '1'
        ELSE
        (OTHERS => '0');


END arch;