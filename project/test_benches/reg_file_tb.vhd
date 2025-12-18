LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

ENTITY reg_file_tb IS
END reg_file_tb;

ARCHITECTURE behavior OF reg_file_tb IS 
    COMPONENT reg_file
    PORT(
        clk : IN std_logic;
        write_enable : IN std_logic;
        read_reg_address_1 : IN std_logic_vector(2 downto 0);
        read_reg_address_2 : IN std_logic_vector(2 downto 0);
        write_reg_address : IN std_logic_vector(2 downto 0);
        write_data : IN std_logic_vector(31 downto 0);
        read_data_1 : OUT std_logic_vector(31 downto 0);
        read_data_2 : OUT std_logic_vector(31 downto 0)
    );
    END COMPONENT;
    
    signal clk : std_logic := '0';
    signal write_enable : std_logic := '0';
    signal read_reg_address_1 : std_logic_vector(2 downto 0) := (others => '0');
    signal read_reg_address_2 : std_logic_vector(2 downto 0) := (others => '0');
    signal write_reg_address : std_logic_vector(2 downto 0) := (others => '0');
    signal write_data : std_logic_vector(31 downto 0) := (others => '0');
    signal read_data_1 : std_logic_vector(31 downto 0);
    signal read_data_2 : std_logic_vector(31 downto 0);
    
    constant clk_period : time := 10 ns;
    
BEGIN
    uut: reg_file PORT MAP (
        clk => clk,
        write_enable => write_enable,
        read_reg_address_1 => read_reg_address_1,
        read_reg_address_2 => read_reg_address_2,
        write_reg_address => write_reg_address,
        write_data => write_data,
        read_data_1 => read_data_1,
        read_data_2 => read_data_2
    );

    clk_process :process
    begin
        clk <= '0';
        wait for clk_period/2;
        clk <= '1';
        wait for clk_period/2;
    end process;

    stim_proc: process
    begin        
        wait for 20 ns;
        
        write_enable <= '1';
        write_reg_address <= "000";
        write_data <= X"00000001";
        wait for clk_period;
        
        write_reg_address <= "001";
        write_data <= X"0000000A";
        wait for clk_period;
        
        write_reg_address <= "010";
        write_data <= X"00000014";
        wait for clk_period;
        
        write_reg_address <= "011";
        write_data <= X"0000001E";
        wait for clk_period;
        
        write_reg_address <= "100";
        write_data <= X"00000028";
        wait for clk_period;
        
        write_reg_address <= "101";
        write_data <= X"FFFFFFFF";
        wait for clk_period;
        
        write_reg_address <= "110";
        write_data <= X"AAAAAAAA";
        wait for clk_period;
        
        write_reg_address <= "111";
        write_data <= X"55555555";
        wait for clk_period;
        
        write_enable <= '0';
        wait for clk_period;
        
        read_reg_address_1 <= "000";
        read_reg_address_2 <= "001";
        wait for clk_period;
        
        read_reg_address_1 <= "010";
        read_reg_address_2 <= "011";
        wait for clk_period;
        
        read_reg_address_1 <= "100";
        read_reg_address_2 <= "101";
        wait for clk_period;
        
        read_reg_address_1 <= "110";
        read_reg_address_2 <= "111";
        wait for clk_period;

        write_enable <= '1';
        write_reg_address <= "010";
        write_data <= X"DEADBEEF";
        read_reg_address_1 <= "010";
        read_reg_address_2 <= "011";
        wait for clk_period * 2;
        
        write_reg_address <= "000";
        write_data <= X"12345678";
        read_reg_address_1 <= "000";
        wait for clk_period * 2;
        
        write_enable <= '0';
        read_reg_address_1 <= "010";
        read_reg_address_2 <= "000";
        wait for clk_period * 2;
        
        wait;
    end process;

END behavior;
