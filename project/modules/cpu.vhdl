library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity cpu_top is
    Port ( 
            clk : in STD_LOGIC;
            reset, int : in STD_LOGIC;
            in_port : in std_logic_vector(3 downto 0);
            out_port: out std_logic_vector(3 downto 0);
        );
end cpu_top;

architecture arch of cpu_top is


    component forwarding_unit is
        Port (
            id_ex_rs : in STD_LOGIC_VECTOR(2 downto 0);
            id_ex_rt : in STD_LOGIC_VECTOR(2 downto 0);
            ex_mem_rd : in STD_LOGIC_VECTOR(2 downto 0);
            mem_wb_rd : in STD_LOGIC_VECTOR(2 downto 0);
            counter: in STD_LOGIC;
            ex_mem_reg_write : in STD_LOGIC;
            mem_wb_reg_write : in STD_LOGIC;
            forward_a : out STD_LOGIC_VECTOR(1 downto 0);
            forward_b : out STD_LOGIC_VECTOR(1 downto 0)
        );
    end component;

    component one_bit_counter is
        Port ( clk : in STD_LOGIC;
            counter_enable : in STD_LOGIC;
            count_out : out STD_LOGIC);
    end component;

    component pipeline_reg is 
    generic (n:integer :=32);
    port(
            clk:in std_logic;
            enable:in std_logic;
            data_in: in std_logic_vector(n-1 downto 0);
            data_out:out std_logic_vector(n-1 downto 0)
        );
    end component;

    component memory IS PORT (
        clk : IN STD_LOGIC;
        reset : IN STD_LOGIC;
        in_data : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
        out_data : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
        address : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
        mem_write : IN STD_LOGIC;
        mem_read : IN STD_LOGIC
    );
    END component;

    component alu IS 
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
    END component;


    
    component control_unit is
        port (
            opcode : in  std_logic_vector(9 downto 0);
            int: in std_logic in;
            HLT    : out std_logic; 
            stop_pc : out std_logic;
            ALU_op : out std_logic_vector(3 downto 0);
            out_port_en : out std_logic;
            in_port_en  : out std_logic;
            reg_write_en : out std_logic;
            MEM_ALU : out std_logic;
            ALU_immediate : out std_logic;
            R2_sel  : out std_logic;  
            exe_counter_en : out std_logic;
            mem_counter_en : out std_logic;
            flush_decode_decode : out std_logic;
            flush_decode_execute : out std_logic;  
            flush_decode_mem : out std_logic;
            flush_branch_branch : out std_logic;
            mem_write_en : out std_logic;
            pc_address : out std_logic; 
            write_data_or_pc : out std_logic;  
            sp_sel :out std_logic; 
            sp_alu_op : out std_logic_vector(1 downto 0);  
            branch_unit_en : out std_logic;
            branch_type : out std_logic_vector(2 downto 0);
            branch_sel : out std_logic;
            pc_form_mem : out std_logic; 
            index_sel : out std_logic
        );
    end component;

    component reg32 is
        Port (
            clk    : in  STD_LOGIC;                     -- Clock signal
            reset  : in  STD_LOGIC;                     -- always 0
            en     : in  STD_LOGIC;                     -- Write enable
            d      : in  STD_LOGIC_VECTOR(31 downto 0); -- 32-bit Data input
            q      : out STD_LOGIC_VECTOR(31 downto 0)  -- 32-bit Data output
        );
    end component;
    
    component reg_file IS
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
    END component;


    component branching_unit is
        port (
            en      : in  std_logic;
            flags   : in  std_logic_vector(2 downto 0); -- zero, negative, carry
            branch_type : in std_logic_vector(2 downto 0);
            branch_sel : out std_logic;
            flush_decode_execute_branch : out std_logic;
        );
    end component;

    component Reg3BitStoreRestore is
        Port (
            clk      : in  STD_LOGIC;
            rst      : in  STD_LOGIC;
            store    : in  STD_LOGIC; -- Save current data to cache
            restore  : in  STD_LOGIC; -- Load data from cache to main
            load     : in  STD_LOGIC; -- Standard write enable
            data_in  : in  STD_LOGIC_VECTOR(2 downto 2);
            data_out : out STD_LOGIC_VECTOR(2 downto 0)
        );
    end component;

    signal enable_pc : std_logic; --
    signal pc_next_data : std_logic_vector(31 downto 0); --
    signal pc : std_logic; --

    signal sp_next_data : std_logic_vector(31 downto 0); --
    signal sp : std_logic; --
    

    signal mem_next_data : std_logic_vector(31 downto 0); --
    signal mem_data : std_logic_vector(31 downto 0); --
    signal mem_address : std_logic_vector(31 downto 0); --
    signal mem_write : std_logic; --
    signal mem_read : std_logic;

    signal fetchDecode_pipe_enable : std_logic; --
    signal fetchDecode_pipe_input : std_logic_vector(63 downto 0); --
    signal fetchDecode_pipe_output : std_logic_vector(63 downto 0); --
    
    signal mem_data_in : std_logic_vector(31 downto 0); --
    signal mem_data_out : std_logic_vector(31 downto 0); --


    signal reg_file_write_enable : std_logic;
    signal R1_reg_file_in : std_logic_vector(31 downto 0);
    signal R2_reg_file_in : std_logic_vector(31 downto 0);
    signal WB_address_reg_file_in : std_logic_vector(31 downto 0);
    signal WB_data_reg_file_in : std_logic_vector(31 downto 0);

    signal R1_reg_file_out : std_logic_vector(31 downto 0);
    signal R2_reg_file_out : std_logic_vector(31 downto 0);
    
    signal opcode : std_logic_vector(9 downto 0);
    signal int : std_logic;
    
    signal HLT_cu    : std_logic; 
    signal stop_pc_cu : std_logic;
    signal ALU_op_cu : std_logic_vector(3 downto 0);
    signal out_port_en_cu : std_logic;
    signal in_port_en_cu  : std_logic;
    signal reg_write_en_cu : std_logic;
    signal MEM_ALU_cu : std_logic;
    signal ALU_immediate_cu : std_logic;
    signal R2_sel_cu  : std_logic;
    signal exe_counter_en_cu : std_logic;
    signal mem_counter_en_cu : std_logic;
    signal flush_decode_decode_cu : std_logic;
    signal flush_decode_execute_cu : std_logic;
    signal flush_decode_mem_cu : std_logic;
    signal flush_branch_branch_cu : std_logic;
    signal mem_write_en_cu : std_logic;
    signal pc_address_cu : std_logic;
    signal write_data_or_pc_cu : std_logic;
    signal sp_sel_cu : std_logic;
    signal sp_alu_op_cu : std_logic_vector(1 downto 0);
    signal branch_unit_en_cu : std_logic;
    signal branch_type_cu : std_logic_vector(2 downto 0);
    signal branch_sel_cu : std_logic;
    signal pc_form_mem_cu : std_logic;
    signal index_sel_cu : std_logic;
    
    signal branch_sel_bu : std_logic; --

    signal decodeExecute_pipe_enable : std_logic; --
    signal decodeExecute_pipe_input : std_logic_vector(167 downto 0); --
    signal decodeExecute_pipe_output : std_logic_vector(167 downto 0); --
    

    signal exe_counter_out : std_logic; --

    signal alu_data_out : std_logic_vector(31 downto 0); --
    signal restore_alu : std_logic; --
    signal store_alu : std_logic; --
    signal flag_values_alu : std_logic_vector(2 downto 0); -- NZC

    signal flagas_reg_out : std_logic_vector(2 downto 0); -- NZC

    signal flush_decode_execute_branch : std_logic; --

    signal exexecuteMemory_pipe_input : std_logic_vector(167 downto 0); --
    signal exexecuteMemory_pipe_output : std_logic_vector(167 downto 0);
    signal executeMemory_pipe_enable : std_logic; --

    signal memWB_pipe_input : std_logic_vector(167 downto 0); --
    signal memWB_pipe_output : std_logic_vector(167 downto 0); --
    signal memWB_pipe_enable : std_logic; --

    signal forward_a : std_logic_vector(1 downto 0);
    signal forward_b : std_logic_vector(1 downto 0);


    -- pc connections --
    signal pc_data : std_logic_vector(31 downto 0);

    -- memory connections --
    signal pc_or_address : std_logic_vector(31 downto 0);
begin
    
    PC_REG : reg32
    port map (
        clk => clk,
        reset => '0',
        en => enable_pc,
        d => pc_next_data,
        q => pc
    );

    SP_REG : reg32
    port map (
        clk => clk,
        reset => '0',
        en => '1',
        d => sp_next_data,
        q => sp
    )

    mem_read <= not mem_write;
    Memory : memory
    port map (
        clk => clk,
        reset => '0',
        in_data => mem_next_data,
        out_data => mem_data,
        address => mem_address,
        mem_write => mem_write,
        mem_read => mem_read
    );

    fetchDecode_pipe_input(31 downto 0) <= mem_data_in;
    fetchDecode_pipe_input(63 downto 32) <= pc + 1;
    fetchDecode : pipeline_reg
    generic map (
        n => 64
    )
    port map (
        clk => clk,
        enable => fetchDecode_pipe_enable,
        data_in => fetchDecode_pipe_input,
        data_out => fetchDecode_pipe_output
    );

    RegFile : reg_file
    port map (
        clk => clk,
        write_enable => reg_file_write_enable,
        read_reg_address_1 => R1_reg_file_in,
        read_reg_address_2 => R2_reg_file_in,
        write_reg_address => WB_address_reg_file_in,
        write_data => WB_data_reg_file_in,
        read_data_1 => R1_reg_file_out,
        read_data_2 => R2_reg_file_out
    );

    opcode <= fetchDecode_pipe_output(31 downto 22);
    controlUnit : control_unit
    port map (
        opcode => opcode,
        int => int,
        HLT    => HLT_cu, 
        stop_pc => stop_pc_cu,
        ALU_op => ALU_op_cu,
        out_port_en => out_port_en_cu,
        in_port_en  => in_port_en_cu,
        reg_write_en => reg_write_en_cu,
        MEM_ALU => MEM_ALU_cu,
        ALU_immediate => ALU_immediate_cu,
        R2_sel  => R2_sel_cu,  
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
    decodeExecute_pipe_input(31 downto 0)   <= R1_reg_file_out;
    decodeExecute_pipe_input(63 downto 32)  <= R2_reg_file_out;
    decodeExecute_pipe_input(95 downto 64)  <= fetchDecode_pipe_output(63 downto 32); -- PC + 1
    decodeExecute_pipe_input(125 downto 96) <= mem_data_out; -- Immediate / Offset value
    decodeExecute_pipe_input(128 downto 126) <= fetchDecode_pipe_output(21 downto 19); -- Rdest
    decodeExecute_pipe_input(131 downto 129) <= fetchDecode_pipe_output(18 downto 16); -- Rsrc1
    decodeExecute_pipe_input(134 downto 132) <= fetchDecode_pipe_output(15 downto 13); -- Rsrc2
    decodeExecute_pipe_input(135)            <= reg_file_write_enable;

    -- 2. CONTROL UNIT SIGNALS (In port map order)
    -- Starting from bit 136...
    decodeExecute_pipe_input(136)            <= HLT_cu;
    decodeExecute_pipe_input(137)            <= stop_pc_cu;
    decodeExecute_pipe_input(141 downto 138) <= ALU_op_cu;
    decodeExecute_pipe_input(142)            <= out_port_en_cu;
    decodeExecute_pipe_input(143)            <= in_port_en_cu;
    decodeExecute_pipe_input(144)            <= reg_write_en_cu;
    decodeExecute_pipe_input(148 downto 145) <= MEM_ALU_cu;
    decodeExecute_pipe_input(149)            <= ALU_immediate_cu;
    decodeExecute_pipe_input(150)            <= R2_sel_cu;
    decodeExecute_pipe_input(151)            <= exe_counter_en_cu;
    decodeExecute_pipe_input(152)            <= mem_counter_en_cu;
    decodeExecute_pipe_input(153)            <= flush_decode_decode_cu;
    decodeExecute_pipe_input(154)            <= flush_decode_execute_cu;
    decodeExecute_pipe_input(155)            <= flush_decode_mem_cu;
    decodeExecute_pipe_input(156)            <= flush_branch_branch_cu;
    decodeExecute_pipe_input(157)            <= mem_write_en_cu;
    decodeExecute_pipe_input(158)            <= pc_address_cu;        
    decodeExecute_pipe_input(159)            <= write_data_or_pc_cu; 
    decodeExecute_pipe_input(160)            <= sp_sel_cu;
    decodeExecute_pipe_input(162 downto 161) <= sp_alu_op_cu;
    decodeExecute_pipe_input(163)            <= branch_unit_en_cu;
    decodeExecute_pipe_input(164)            <= branch_type_cu;
    decodeExecute_pipe_input(165)            <= branch_sel_cu;
    decodeExecute_pipe_input(166)            <= pc_form_mem_cu;
    decodeExecute_pipe_input(167)            <= index_sel_cu;
    generic map (
        n => 168
    )
    port map (
        clk => clk,
        enable => decodeExecute_pipe_enable,
        data_in => decodeExecute_pipe_input,
        data_out => decodeExecute_pipe_output
    );

    exeCounter : one_bit_counter
    port map (
        clk => clk,
        counter_enable => decodeExecute_pipe_output(151),
        count_out => exe_counter_out
    );

    Alu : alu
    generic map (
        n => 32
    )
    port map (
        reset => '0',
        clk => clk,
        data_in1 => decodeExecute_pipe_output(31 downto 0),
        data_in2 => decodeExecute_pipe_output(63 downto 32),
        operation => decodeExecute_pipe_output(141 downto 138),
        counter => exe_counter_out,
        data_out => alu_data_out,
        Restore => restore_alu,
        store => store_alu,
        flag_values => flag_values_alu --NZC 
    );

    flagreg : Reg3BitStoreRestore
    port map (
        clk => clk,
        rst => '0',
        store => store_alu,
        restore => restore_alu,
        load => '1',
        data_in => flag_values_alu(2 downto 2),
        data_out => flagas_reg_out -- NZC
    );

    branchingUnit : branching_unit
    port map(
        en => decodeExecute_pipe_output(162),
        flags => flagas_reg_out,
        branch_type => decodeExecute_pipe_output(163 downto 161),
        branch_sel => branch_sel_bu,
        flush_decode_execute_branch => flush_decode_execute_branch,
    );


    -- i stoped here
    exexecuteMemory_pipe_input(31 downto 0)   <= alu_data_out;
    exexecuteMemory_pipe_input(63 downto 32)  <= in_port;
    exexecuteMemory_pipe_input(95 downto 64)  <= decodeExecute_pipe_input(125 downto 96);
    exexecuteMemory_pipe_input(128 downto 126) <= decodeExecute_pipe_input(128 downto 126); -- Rdest
    exexecuteMemory_pipe_input(167 downto 136) <= decodeExecute_pipe_input(167 downto 136); -- control signals
    executeMemory : pipeline_reg
    generic map (
        n => 168
    )
    port map (
        clk => clk,
        enable => executeMemory_pipe_enable,
        data_in => exexecuteMemory_pipe_input,
        data_out => exexecuteMemory_pipe_output
    );

    memWB_pipe_input(31 downto 0)   <= exexecuteMemory_pipe_output(31 downto 0); -- ALU result
    memWB_pipe_input(63 downto 32)  <= exexecuteMemory_pipe_output(63 downto 32); -- in_port data
    memWB_pipe_input(95 downto 64)  <= exexecuteMemory_pipe_output(95 downto 64); -- immediate
    memWB_pipe_input(127 downto 96) <= mem_data_out; -- mem data
    memWB_pipe_input(130 downto 128) <= exexecuteMemory_pipe_output(128 downto 126); -- Rdest
    memWB_pipe_input(167 downto 136) <= exexecuteMemory_pipe_output(167 downto 136); -- control signals
    MemoryWB : pipeline_reg
    generic map (
        n => 168
    )
    port map (
        clk => clk,
        enable => memWB_pipe_enable,
        data_in => memWB_pipe_input,
        data_out => memWB_pipe_output
    );


    FWDunit : forwarding_unit
    port map (
        id_ex_rs => decodeExecute_pipe_output(131 downto 129),
        id_ex_rt => decodeExecute_pipe_output(134 downto 132),
        ex_mem_rd => exexecuteMemory_pipe_output(128 downto 126),
        mem_wb_rd => memWB_pipe_output(128 downto 126),
        counter => exe_counter_out,
        ex_mem_reg_write => exexecuteMemory_pipe_output(135),
        mem_wb_reg_write => memWB_pipe_output(135),
        forward_a => forward_a,
        forward_b => forward_b
    );



    -- CONNECTIONS --

    -- program counter connections --
    pc_next_data <= mem_data when exexecuteMemory_pipe_output(166) or reset = '1'
                    else pc_data;
    
    pc_data <=  fetchDecode_pipe_output(31 downto 0) when branch_sel_bu = '1' or branch_sel_cu = '1'
                else pc + 1;

    -- stack pointer connections --
    sp_next_data <= sp + 1 when exexecuteMemory_pipe_output(161 downto 160) = "01"
                 else sp - 1 when exexecuteMemory_pipe_output(161 downto 160) = "10"
                 else sp;

    -- memory connections --
    pc_or_address <= pc when exexecuteMemory_pipe_output(166) = '1'
                        else sp when exexecuteMemory_pipe_output(167) = '1'
                        else exexecuteMemory_pipe_output(95 downto 64);

    mem_next_data <= exexecuteMemory_pipe_output(63 downto 32) when exexecuteMemory_pipe_output(159) = '1'
                  else sp when exexecuteMemory_pipe_output(160) = '1' or reset = '1'
                  else exexecuteMemory_pipe_output(95 downto 64);


end arch;