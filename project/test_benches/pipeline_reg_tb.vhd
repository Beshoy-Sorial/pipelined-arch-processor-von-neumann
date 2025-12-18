LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

ENTITY pipeline_reg_tb IS
END pipeline_reg_tb;

ARCHITECTURE behavior OF pipeline_reg_tb IS 
    COMPONENT pipeline_reg
    GENERIC (n : integer := 32);
    PORT(
        clk : IN std_logic;
        enable : IN std_logic;
        data_in : IN std_logic_vector(n-1 downto 0);
        data_out : OUT std_logic_vector(n-1 downto 0)
    );
    END COMPONENT;
    
    signal clk : std_logic := '0';
    signal enable : std_logic := '0';
    signal data_in : std_logic_vector(31 downto 0) := (others => '0');
    signal data_out : std_logic_vector(31 downto 0);
    
    constant clk_period : time := 10 ns;
    
BEGIN
    uut: pipeline_reg 
    GENERIC MAP (n => 32)
    PORT MAP (
        clk => clk,
        enable => enable,
        data_in => data_in,
        data_out => data_out
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
        
        report "Test 1: Enable = 0, passing data 0x11111111";
        enable <= '0';
        data_in <= X"11111111";
        wait for clk_period;
        
        report "Test 2: Enable = 0, passing data 0x22222222";
        data_in <= X"22222222";
        wait for clk_period;
        
        report "Test 3: Enable = 0, passing data 0x33333333";
        data_in <= X"33333333";
        wait for clk_period;
        
        report "Test 4: Enable = 1, holding value (should stay 0x33333333)";
        enable <= '1';
        data_in <= X"AAAAAAAA";
        wait for clk_period;
        
        report "Test 5: Enable = 1, holding value (should stay 0x33333333)";
        data_in <= X"BBBBBBBB";
        wait for clk_period;
        
        report "Test 6: Enable = 1, holding value (should stay 0x33333333)";
        data_in <= X"CCCCCCCC";
        wait for clk_period;

        report "Test 7: Enable = 0, passing data 0xDEADBEEF";
        enable <= '0';
        data_in <= X"DEADBEEF";
        wait for clk_period;
        
        report "Test 8: Enable = 0, passing data 0x12345678";
        data_in <= X"12345678";
        wait for clk_period;
        
        report "Test 9: Enable = 1, holding value (should stay 0x12345678)";
        enable <= '1';
        data_in <= X"FFFFFFFF";
        wait for clk_period;
        
        report "Test 10: Enable = 0, passing data 0x00000000";
        enable <= '0';
        data_in <= X"00000000";
        wait for clk_period;
        
        report "Test 11: Enable = 0, passing data 0xFFFFFFFF";
        data_in <= X"FFFFFFFF";
        wait for clk_period;
        
        report "Test 12: Enable = 1, holding value (should stay 0xFFFFFFFF)";
        enable <= '1';
        data_in <= X"55555555";
        wait for clk_period * 3;

        report "Test 13: Enable = 0, passing final data 0xA5A5A5A5";
        enable <= '0';
        data_in <= X"A5A5A5A5";
        wait for clk_period * 2;
        
        report "Simulation Complete";
        
        wait;
    end process;

END behavior;
