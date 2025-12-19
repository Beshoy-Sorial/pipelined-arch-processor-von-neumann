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
            flush_branch_branch : out std_logic
        );
    end component;

begin
    
    
    Memory : memory
    port map (

    );

    fetchDecode : pipeline_reg
    generic map (
        n => 256
    )
    port map (
        
    );

    RegFile : reg_file
    port map (
        
    );

    controlUnit : control_unit
    port map (
        
    );


    decodeExecute : pipeline_reg
    generic map (
        n => 256
    )
    port map (
        
    );

    Alu : alu
    generic map (
        n => 256
    )
    port map (
        
    );

    branchingUnit : branching_unit
    port map(

    );

    executeMemory : pipeline_reg
    generic map (
        n => 256
    )
    port map (
        
    );

    MemoryWB : pipeline_reg
    generic map (
        n => 256
    )
    port map (
        
    );


    FWDunit : forwarding_unit
    port map (

    );
end arch;