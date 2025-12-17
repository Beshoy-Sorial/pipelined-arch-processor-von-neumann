LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE ieee.numeric_std.ALL;
USE work.cpu_pkg.ALL;
ENTITY cpu_top IS
    GENERIC (n : INTEGER := 32);
    PORT (
        clk : IN STD_LOGIC;
        reset : IN STD_LOGIC;
        instructions : instruction_array;
        idk : OUT STD_LOGIC
    );
END ENTITY;
ARCHITECTURE cpu_behave OF cpu_top IS
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
    COMPONENT pipeline_reg IS
        PORT (
            clk : IN STD_LOGIC;
            enable : IN STD_LOGIC;
            data_in : IN STD_LOGIC_VECTOR(n - 1 DOWNTO 0);
            data_out : OUT STD_LOGIC_VECTOR(n - 1 DOWNTO 0));
    END COMPONENT;
    -- main registers
    SIGNAL pc : STD_LOGIC_VECTOR(31 DOWNTO 0);
    SIGNAL sp : STD_LOGIC_VECTOR(31 DOWNTO 0);
    -- memory signals
    SIGNAL data_in_memory : STD_LOGIC_VECTOR(31 DOWNTO 0);
    SIGNAL data_out_memory : STD_LOGIC_VECTOR(31 DOWNTO 0);
    SIGNAL address : STD_LOGIC_VECTOR(10 DOWNTO 0);
    SIGNAL mem_write : STD_LOGIC;
    -- registres signals
    SIGNAL write_enable : STD_LOGIC;
    SIGNAL read_reg_address_1 : STD_LOGIC_VECTOR(2 DOWNTO 0);
    SIGNAL read_reg_address_2 : STD_LOGIC_VECTOR(2 DOWNTO 0);
    SIGNAL write_reg_address : STD_LOGIC_VECTOR(2 DOWNTO 0);
    SIGNAL write_data : STD_LOGIC_VECTOR(31 DOWNTO 0);
    SIGNAL read_data_1 : STD_LOGIC_VECTOR(31 DOWNTO 0);
    SIGNAL read_data_2 : STD_LOGIC_VECTOR(31 DOWNTO 0);
    -- pipeline f/d
    SIGNAL enable_fd : STD_LOGIC;
    SIGNAL data_in_fd : STD_LOGIC_VECTOR(n - 1 DOWNTO 0);
    SIGNAL data_out_fd : STD_LOGIC_VECTOR(n - 1 DOWNTO 0);
    -- pipeline d/e
    SIGNAL enable_de : STD_LOGIC;
    SIGNAL data_in_de : STD_LOGIC_VECTOR(n - 1 DOWNTO 0);
    SIGNAL data_out_de : STD_LOGIC_VECTOR(n - 1 DOWNTO 0);
    -- pipeline e/mem
    SIGNAL enable_emem : STD_LOGIC;
    SIGNAL data_in_emem : STD_LOGIC_VECTOR(n - 1 DOWNTO 0);
    SIGNAL data_out_emem c: STD_LOGIC_VECTOR(n - 1 DOWNTO 0);
    -- pipeline mem/wb
    SIGNAL enable_memwb : STD_LOGIC;
    SIGNAL data_in_memwb : STD_LOGIC_VECTOR(n - 1 DOWNTO 0);
    SIGNAL data_out_memwb : STD_LOGIC_VECTOR(n - 1 DOWNTO 0);
BEGIN
    memo_map : memory PORT MAP(
        clk => clk,
        reset => reset,
        data_in => data_in_memory,
        data_out => data_out_memory,
        mem_write => mem_write,
        mem_read => NOT mem_write,
        address => address
    );
    reg_file_map : reg_file PORT MAP
    (
        write_enable => write_enable,
        read_reg_address_1 => read_reg_address_1,
        read_reg_address_2 => read_reg_address_2,
        write_reg_address => write_reg_address,
        write_data => write_data,
        read_data_1 => read_data_1,
        read_data_2 => read_data_2
    );
    f_d : pipeline_reg PORT MAP(
        data_in => data_in_fd,
        data_out => data_out_fd,
        enable => enable_fd
    );

    d_e : pipeline_reg PORT MAP(
        data_in => data_in_de,
        data_out => data_out_de,
        enable => enable_de
    );

    e_mem : pipeline_reg PORT MAP(
        data_in => data_in_emem,
        data_out => data_out_emem,
        enable => enable_emem
    );

    mem_wb : pipeline_reg PORT MAP(
        data_in => data_in_memwb,
        data_out => data_out_memwb,
        enable => enable_memwb
    );
END ARCHITECTURE;