LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

ENTITY alu_tb IS
END ENTITY;

ARCHITECTURE testbench OF alu_tb IS
    
    -- Constants
    CONSTANT n : INTEGER := 32;
    CONSTANT clk_period : TIME := 10 ns;
    
    -- Component Declaration
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
            flag_values : OUT STD_LOGIC_VECTOR(2 DOWNTO 0)
        );
    END COMPONENT;
    
    -- Signals
    SIGNAL reset : STD_LOGIC := '0';
    SIGNAL clk : STD_LOGIC := '0';
    SIGNAL data_in1 : STD_LOGIC_VECTOR(n - 1 DOWNTO 0) := (OTHERS => '0');
    SIGNAL data_in2 : STD_LOGIC_VECTOR(n - 1 DOWNTO 0) := (OTHERS => '0');
    SIGNAL operation : STD_LOGIC_VECTOR(3 DOWNTO 0) := (OTHERS => '0');
    SIGNAL counter : STD_LOGIC := '0';
    SIGNAL data_out : STD_LOGIC_VECTOR(n - 1 DOWNTO 0);
    SIGNAL Restore : STD_LOGIC;
    SIGNAL store : STD_LOGIC;
    SIGNAL flag_values : STD_LOGIC_VECTOR(2 DOWNTO 0);
    
    -- Flag aliases for easier reading
    ALIAS neg_flag : STD_LOGIC IS flag_values(2);
    ALIAS zero_flag : STD_LOGIC IS flag_values(1);
    ALIAS carry_flag : STD_LOGIC IS flag_values(0);
    
BEGIN
    
    -- Instantiate the Unit Under Test (UUT)
    uut: alu 
        GENERIC MAP (n => n)
        PORT MAP (
            reset => reset,
            clk => clk,
            data_in1 => data_in1,
            data_in2 => data_in2,
            operation => operation,
            counter => counter,
            data_out => data_out,
            Restore => Restore,
            store => store,
            flag_values => flag_values
        );
    
    -- Clock generation
    clk_process: PROCESS
    BEGIN
        clk <= '0';
        WAIT FOR clk_period/2;
        clk <= '1';
        WAIT FOR clk_period/2;
    END PROCESS;
    
    -- Stimulus process
    stim_proc: PROCESS
    BEGIN
        -- Initial reset
        reset <= '1';
        WAIT FOR clk_period * 2;
        reset <= '0';
        WAIT FOR clk_period;
        
        REPORT "Starting ALU Tests...";
        
        -- ====================================
        -- Test 1: ADD Operation (0001)
        -- ====================================
        REPORT "Test 1: ADD - 15 + 10 = 25";
        data_in1 <= std_logic_vector(to_unsigned(15, n));
        data_in2 <= std_logic_vector(to_unsigned(10, n));
        operation <= "0001";
        counter <= '0';
        WAIT FOR clk_period;
        ASSERT data_out = std_logic_vector(to_unsigned(25, n))
            REPORT "ADD failed: Expected 25, Got " & INTEGER'IMAGE(to_integer(unsigned(data_out)))
            SEVERITY ERROR;
        ASSERT store = '1' REPORT "ADD: store should be 1" SEVERITY ERROR;
        
        -- Test ADD with carry
        REPORT "Test 1b: ADD with Carry - Max + 1";
        data_in1 <= (OTHERS => '1');  -- Max value
        data_in2 <= std_logic_vector(to_unsigned(1, n));
        operation <= "0001";
        WAIT FOR clk_period;
        ASSERT carry_flag = '1' REPORT "ADD: carry flag should be set" SEVERITY ERROR;
        
        -- ====================================
        -- Test 2: SUB Operation (0010)
        -- ====================================
        REPORT "Test 2: SUB - 20 - 5 = 15";
        data_in1 <= std_logic_vector(to_unsigned(20, n));
        data_in2 <= std_logic_vector(to_unsigned(5, n));
        operation <= "0010";
        WAIT FOR clk_period;
        ASSERT data_out = std_logic_vector(to_unsigned(15, n))
            REPORT "SUB failed: Expected 15, Got " & INTEGER'IMAGE(to_integer(unsigned(data_out)))
            SEVERITY ERROR;
        ASSERT store = '1' REPORT "SUB: store should be 1" SEVERITY ERROR;
        
        -- Test SUB resulting in zero
        REPORT "Test 2b: SUB - Zero result (10 - 10)";
        data_in1 <= std_logic_vector(to_unsigned(10, n));
        data_in2 <= std_logic_vector(to_unsigned(10, n));
        operation <= "0010";
        WAIT FOR clk_period;
        ASSERT zero_flag = '1' REPORT "SUB: zero flag should be set" SEVERITY ERROR;
        
        -- ====================================
        -- Test 3: AND Operation (0011)
        -- ====================================
        REPORT "Test 3: AND - 0xFF AND 0x0F";
        data_in1 <= X"000000FF";
        data_in2 <= X"0000000F";
        operation <= "0011";
        WAIT FOR clk_period;
        ASSERT data_out = X"0000000F"
            REPORT "AND failed" SEVERITY ERROR;
        ASSERT store = '1' REPORT "AND: store should be 1" SEVERITY ERROR;
        
        -- ====================================
        -- Test 4: MOV/First Operation (0100)
        -- ====================================
        REPORT "Test 4: MOV - Pass data_in1";
        data_in1 <= std_logic_vector(to_unsigned(42, n));
        data_in2 <= std_logic_vector(to_unsigned(99, n));
        operation <= "0100";
        WAIT FOR clk_period;
        ASSERT data_out = std_logic_vector(to_unsigned(42, n))
            REPORT "MOV failed" SEVERITY ERROR;
        ASSERT store = '1' REPORT "MOV: store should be 1" SEVERITY ERROR;
        
        -- ====================================
        -- Test 5: Second Operation (0101)
        -- ====================================
        REPORT "Test 5: Second - Pass data_in2";
        data_in1 <= std_logic_vector(to_unsigned(42, n));
        data_in2 <= std_logic_vector(to_unsigned(99, n));
        operation <= "0101";
        WAIT FOR clk_period;
        ASSERT data_out = std_logic_vector(to_unsigned(99, n))
            REPORT "Second operation failed" SEVERITY ERROR;
        ASSERT store = '1' REPORT "Second: store should be 1" SEVERITY ERROR;
        
        -- ====================================
        -- Test 6: SWAP Operation (0110)
        -- ====================================
        REPORT "Test 6a: SWAP - counter = 0 (output data_in1)";
        data_in1 <= std_logic_vector(to_unsigned(100, n));
        data_in2 <= std_logic_vector(to_unsigned(200, n));
        operation <= "0110";
        counter <= '0';
        WAIT FOR clk_period;
        ASSERT data_out = std_logic_vector(to_unsigned(100, n))
            REPORT "SWAP (counter=0) failed" SEVERITY ERROR;
        
        REPORT "Test 6b: SWAP - counter = 1 (output data_in2)";
        counter <= '1';
        WAIT FOR clk_period;
        ASSERT data_out = std_logic_vector(to_unsigned(200, n))
            REPORT "SWAP (counter=1) failed" SEVERITY ERROR;
        ASSERT store = '1' REPORT "SWAP: store should be 1" SEVERITY ERROR;
        counter <= '0';
        
        -- ====================================
        -- Test 7: SetC Operation (0111)
        -- ====================================
        REPORT "Test 7: SetC - Set carry flag";
        data_in1 <= std_logic_vector(to_unsigned(50, n));
        operation <= "0111";
        WAIT FOR clk_period;
        ASSERT carry_flag = '1' REPORT "SetC: carry flag should be set" SEVERITY ERROR;
        ASSERT data_out = std_logic_vector(to_unsigned(50, n))
            REPORT "SetC: data should pass through" SEVERITY ERROR;
        ASSERT store = '1' REPORT "SetC: store should be 1" SEVERITY ERROR;
        
        -- ====================================
        -- Test 8: INC Operation (1000)
        -- ====================================
        REPORT "Test 8: INC - Increment 7 to 8";
        data_in1 <= std_logic_vector(to_unsigned(7, n));
        operation <= "1000";
        WAIT FOR clk_period;
        ASSERT data_out = std_logic_vector(to_unsigned(8, n))
            REPORT "INC failed" SEVERITY ERROR;
        ASSERT store = '1' REPORT "INC: store should be 1" SEVERITY ERROR;
        
        -- ====================================
        -- Test 9: NOT Operation (1001)
        -- ====================================
        REPORT "Test 9: NOT - Invert bits";
        data_in1 <= X"0F0F0F0F";
        operation <= "1001";
        WAIT FOR clk_period;
        ASSERT data_out = X"F0F0F0F0"
            REPORT "NOT failed" SEVERITY ERROR;
        ASSERT store = '1' REPORT "NOT: store should be 1" SEVERITY ERROR;
        
        -- ====================================
        -- Test 10: Add2 Operation (1010)
        -- ====================================
        REPORT "Test 10: Add2 - Add 2 to value";
        data_in1 <= std_logic_vector(to_unsigned(10, n));
        operation <= "1010";
        WAIT FOR clk_period;
        ASSERT data_out = std_logic_vector(to_unsigned(12, n))
            REPORT "Add2 failed" SEVERITY ERROR;
        ASSERT store = '1' REPORT "Add2: store should be 1" SEVERITY ERROR;
        
        -- ====================================
        -- Test 11: Restore Operation (1011)
        -- ====================================
        REPORT "Test 11: Restore - Check Restore signal";
        data_in1 <= std_logic_vector(to_unsigned(123, n));
        operation <= "1011";
        WAIT FOR clk_period;
        ASSERT Restore = '1' REPORT "Restore signal should be 1" SEVERITY ERROR;
        ASSERT store = '0' REPORT "Restore: store should be 0" SEVERITY ERROR;
        ASSERT data_out = std_logic_vector(to_unsigned(123, n))
            REPORT "Restore: data should pass through" SEVERITY ERROR;
        
        -- ====================================
        -- Test 12: Reset functionality
        -- ====================================
        REPORT "Test 12: Reset - All outputs should be zero";
        reset <= '1';
        WAIT FOR clk_period;
        ASSERT data_out = std_logic_vector(to_unsigned(0, n))
            REPORT "Reset: data_out should be 0" SEVERITY ERROR;
        ASSERT flag_values = "000" REPORT "Reset: flags should be 000" SEVERITY ERROR;
        ASSERT store = '0' REPORT "Reset: store should be 0" SEVERITY ERROR;
        ASSERT Restore = '0' REPORT "Reset: Restore should be 0" SEVERITY ERROR;
        reset <= '0';
        WAIT FOR clk_period;
        
        -- ====================================
        -- End of tests
        -- ====================================
        REPORT "All ALU tests completed successfully!";
        WAIT;
        
    END PROCESS;
    
END ARCHITECTURE;