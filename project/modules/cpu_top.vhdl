library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity cpu_top is
    Port ( 
        clk : in STD_LOGIC;
        reset, int : in STD_LOGIC;
        in_port : in std_logic_vector(31 downto 0);
        out_port: out std_logic_vector(31 downto 0)
    );
end cpu_top;

architecture arch of cpu_top is

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
            flag_values : OUT STD_LOGIC_VECTOR(2 DOWNTO 0)
        );
    END component;

    component control_unit is
        port (
            opcode : in  std_logic_vector(9 downto 0);
            int: in std_logic;
            HLT    : out std_logic; 
            stop_pc : out std_logic;
            ALU_op : out std_logic_vector(3 downto 0);
            out_port_en : out std_logic;
            in_port_en  : out std_logic;
            reg_write_en : out std_logic;
            MEM_ALU : out std_logic;
            swap_sel : out std_logic;
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
            clk    : in  STD_LOGIC;
            reset  : in  STD_LOGIC;
            en     : in  STD_LOGIC;
            d      : in  STD_LOGIC_VECTOR(31 downto 0);
            q      : out STD_LOGIC_VECTOR(31 downto 0)
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
            flags   : in  std_logic_vector(2 downto 0);
            branch_type : in std_logic_vector(2 downto 0);
            branch_sel : out std_logic;
            flush_decode_execute_branch : out std_logic
        );
    end component;

    component Reg3BitStoreRestore is
        Port (
            clk      : in  STD_LOGIC;
            rst      : in  STD_LOGIC;
            store    : in  STD_LOGIC;
            restore  : in  STD_LOGIC;
            load     : in  STD_LOGIC;
            data_in  : in  STD_LOGIC_VECTOR(2 downto 0);
            data_out : out STD_LOGIC_VECTOR(2 downto 0)
        );
    end component;

    -- Program Counter signals
    signal enable_pc : std_logic;
    signal pc_next : std_logic_vector(31 downto 0);
    signal pc : std_logic_vector(31 downto 0);

    -- Stack Pointer signals
    signal sp_next : std_logic_vector(31 downto 0);
    signal sp : std_logic_vector(31 downto 0);

    -- Memory signals
    signal mem_data_in : std_logic_vector(31 downto 0);
    signal mem_data_out : std_logic_vector(31 downto 0);
    signal mem_address : std_logic_vector(31 downto 0);
    signal mem_write : std_logic;
    signal mem_read : std_logic;

    -- Instruction signals
    signal instruction : std_logic_vector(31 downto 0);
    signal opcode : std_logic_vector(9 downto 0);
    signal rdest : std_logic_vector(2 downto 0);
    signal rsrc1 : std_logic_vector(2 downto 0);
    signal rsrc2 : std_logic_vector(2 downto 0);
    signal immediate : std_logic_vector(31 downto 0);
    signal index_bit : std_logic;

    -- Register file signals
    signal reg_write_enable : std_logic;
    signal reg_read_addr1 : std_logic_vector(2 downto 0);
    signal reg_read_addr2 : std_logic_vector(2 downto 0);
    signal reg_write_addr : std_logic_vector(2 downto 0);
    signal reg_write_data : std_logic_vector(31 downto 0);
    signal reg_read_data1 : std_logic_vector(31 downto 0);
    signal reg_read_data2 : std_logic_vector(31 downto 0);

    -- Control Unit signals
    signal HLT_cu : std_logic;
    signal stop_pc_cu : std_logic;
    signal ALU_op_cu : std_logic_vector(3 downto 0);
    signal out_port_en_cu : std_logic;
    signal in_port_en_cu : std_logic;
    signal reg_write_en_cu : std_logic;
    signal MEM_ALU_cu : std_logic;
    signal swap_sel_cu : std_logic;
    signal ALU_immediate_cu : std_logic;
    signal R2_sel_cu : std_logic;
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

    -- ALU signals
    signal alu_in1 : std_logic_vector(31 downto 0);
    signal alu_in2 : std_logic_vector(31 downto 0);
    signal alu_out : std_logic_vector(31 downto 0);
    signal alu_restore : std_logic;
    signal alu_store : std_logic;
    signal alu_flags : std_logic_vector(2 downto 0);

    -- Flag register signals
    signal flags : std_logic_vector(2 downto 0);

    -- Branch unit signals
    signal branch_sel : std_logic;
    signal flush_branch : std_logic;

    -- Internal logic signals
    signal r2_or_imm : std_logic_vector(31 downto 0);
    signal r1_or_index : std_logic_vector(31 downto 0);
    signal alu_mem_inport : std_logic_vector(31 downto 0);

begin

    -- Program Counter Register
    PC_REG : reg32
    port map (
        clk => clk,
        reset => '0',
        en => enable_pc,
        d => pc_next,
        q => pc
    );

    -- Stack Pointer Register
    SP_REG : reg32
    port map (
        clk => clk,
        reset => '0',
        en => '1',
        d => sp_next,
        q => sp
    );

    -- Memory
    mem_read <= not mem_write;
    MemoryINS : memory
    port map (
        clk => clk,
        reset => '0',
        in_data => mem_data_in,
        out_data => mem_data_out,
        address => mem_address,
        mem_write => mem_write,
        mem_read => mem_read
    );

    -- Register File
    RegFile : reg_file
    port map (
        clk => clk,
        write_enable => reg_write_enable,
        read_reg_address_1 => reg_read_addr1,
        read_reg_address_2 => reg_read_addr2,
        write_reg_address => reg_write_addr,
        write_data => reg_write_data,
        read_data_1 => reg_read_data1,
        read_data_2 => reg_read_data2
    );

    -- Control Unit
    opcode <= instruction(31 downto 22);
    controlUnit : control_unit
    port map (
        opcode => opcode,
        int => int,
        HLT => HLT_cu,
        stop_pc => stop_pc_cu,
        ALU_op => ALU_op_cu,
        out_port_en => out_port_en_cu,
        in_port_en => in_port_en_cu,
        reg_write_en => reg_write_en_cu,
        MEM_ALU => MEM_ALU_cu,
        swap_sel => swap_sel_cu,
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

    -- ALU
    MYAlu : alu
    generic map (n => 32)
    port map (
        reset => '0',
        clk => clk,
        data_in1 => alu_in1,
        data_in2 => alu_in2,
        operation => ALU_op_cu,
        counter => '0',
        data_out => alu_out,
        Restore => alu_restore,
        store => alu_store,
        flag_values => alu_flags
    );

    -- Flag Register
    flagreg : Reg3BitStoreRestore
    port map (
        clk => clk,
        rst => '0',
        store => alu_store,
        restore => alu_restore,
        load => '1',
        data_in => alu_flags,
        data_out => flags
    );

    -- Branching Unit
    branchingUnit : branching_unit
    port map(
        en => branch_unit_en_cu,
        flags => flags,
        branch_type => branch_type_cu,
        branch_sel => branch_sel,
        flush_decode_execute_branch => flush_branch
    );

    -- ============ DATAPATH CONNECTIONS ============

    -- Instruction Fetch
    instruction <= mem_data_out;
    rdest <= instruction(21 downto 19);
    rsrc1 <= instruction(18 downto 16);
    rsrc2 <= instruction(15 downto 13);
    index_bit <= instruction(0);
    immediate <= mem_data_out; -- Read immediate from memory in next cycle

    -- Register File Address Connections
    reg_read_addr1 <= rsrc1;
    reg_read_addr2 <= rdest when R2_sel_cu = '1' else rsrc2;
    reg_write_addr <= rdest when swap_sel_cu = '0' else 
                      rsrc1 when exe_counter_en_cu = '1' else rsrc2;

    -- ALU Input Selection
    r1_or_index <= reg_read_data1 when index_sel_cu = '0' else
                   (31 downto 1 => '0') & index_bit;
    
    r2_or_imm <= immediate when R2_sel_cu = '1' else reg_read_data2;

    alu_in1 <= r1_or_index;
    alu_in2 <= r2_or_imm;

    -- Write Back Data Selection
    alu_mem_inport <= in_port when in_port_en_cu = '1' else
                      immediate when ALU_immediate_cu = '1' else
                      alu_out;

    reg_write_data <= mem_data_out when MEM_ALU_cu = '1' else alu_mem_inport;
    reg_write_enable <= reg_write_en_cu;

    -- Output Port
    out_port <= reg_read_data1 when out_port_en_cu = '1' else (others => '0');

    -- Memory Address and Data
    mem_address <= pc when pc_address_cu = '0' else alu_out;
    mem_data_in <= pc when sp_sel_cu = '0' else sp;
    mem_write <= mem_write_en_cu;

    -- Program Counter Logic
    enable_pc <= not stop_pc_cu and not HLT_cu;
    
    pc_next <= mem_data_out when (pc_form_mem_cu = '1' or reset = '1') else
               reg_read_data1 when (branch_sel = '1' or branch_sel_cu = '1') else
               std_logic_vector(unsigned(pc) + 1);

    -- Stack Pointer Logic
    sp_next <= std_logic_vector(unsigned(sp) + 1) when sp_alu_op_cu = "01" else
               std_logic_vector(unsigned(sp) - 1) when sp_alu_op_cu = "10" else
               sp;

end arch;