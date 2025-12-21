LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

ENTITY alu IS 
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
END ENTITY;

ARCHITECTURE alu_behave OF alu IS

    SIGNAL result : STD_LOGIC_VECTOR(n - 1 DOWNTO 0);
    SIGNAL neg_flag, zero_flag, carry_flag : STD_LOGIC;
    SIGNAL temp_and, temp_not : STD_LOGIC_VECTOR(n - 1 DOWNTO 0);
    SIGNAL add_result, sub_result, inc_result, add2_result : STD_LOGIC_VECTOR(n DOWNTO 0);

BEGIN

    -- Arithmetic operations with carry detection (use n+1 bits)
    add_result <= std_logic_vector(unsigned('0' & data_in1) + unsigned('0' & data_in2));
    sub_result <= std_logic_vector(unsigned('0' & data_in1) - unsigned('0' & data_in2));
    inc_result <= std_logic_vector(unsigned('0' & data_in1) + 1);
    add2_result <= std_logic_vector(unsigned('0' & data_in1) + 2);
    
    -- Logic operations
    temp_and <= data_in1 AND data_in2;
    temp_not <= NOT data_in1;

    -- ============================================
    -- RESULT SELECTION
    -- ============================================
    result <= (OTHERS => '0') WHEN reset = '1' ELSE
              add_result(n - 1 DOWNTO 0) WHEN operation = "0001" ELSE  -- ADD
              sub_result(n - 1 DOWNTO 0) WHEN operation = "0010" ELSE  -- SUB
              temp_and WHEN operation = "0011" ELSE   -- AND
              data_in1 WHEN operation = "0100" ELSE   -- First/MOV
              data_in2 WHEN operation = "0101" ELSE   -- Second
              data_in2 WHEN (operation = "0110" AND counter = '1') ELSE  -- SWAP with counter
              data_in1 WHEN operation = "0110" ELSE   -- SWAP without counter
              data_in1 WHEN operation = "0111" ELSE   -- SetC
              inc_result(n - 1 DOWNTO 0) WHEN operation = "1000" ELSE  -- INC
              temp_not WHEN operation = "1001" ELSE   -- NOT
              add2_result(n - 1 DOWNTO 0) WHEN operation = "1010" ELSE  -- Add 2
              data_in1 WHEN operation = "1011" ELSE   -- Restore
              data_in1;  -- Default

    -- ============================================
    -- FLAG GENERATION
    -- ============================================
    neg_flag <= '0' WHEN reset = '1' ELSE
                add_result(n - 1) WHEN operation = "0001" ELSE  -- ADD
                sub_result(n - 1) WHEN operation = "0010" ELSE  -- SUB
                temp_and(n - 1) WHEN operation = "0011" ELSE   -- AND
                data_in1(n - 1) WHEN operation = "0100" ELSE   -- First/MOV
                data_in2(n - 1) WHEN operation = "0101" ELSE   -- Second
                data_in1(n - 1) WHEN operation = "0111" ELSE   -- SetC
                inc_result(n - 1) WHEN operation = "1000" ELSE  -- INC
                temp_not(n - 1) WHEN operation = "1001" ELSE   -- NOT
                add2_result(n - 1) WHEN operation = "1010" ELSE  -- Add 2
                '0';

    zero_flag <= '0' WHEN reset = '1' ELSE
                 '1' WHEN (operation = "0001" AND add_result(n - 1 DOWNTO 0) = std_logic_vector(to_unsigned(0, n))) ELSE
                 '1' WHEN (operation = "0010" AND sub_result(n - 1 DOWNTO 0) = std_logic_vector(to_unsigned(0, n))) ELSE
                 '1' WHEN (operation = "0011" AND temp_and = std_logic_vector(to_unsigned(0, n))) ELSE
                 '1' WHEN (operation = "0100" AND data_in1 = std_logic_vector(to_unsigned(0, n))) ELSE
                 '1' WHEN (operation = "0101" AND data_in2 = std_logic_vector(to_unsigned(0, n))) ELSE
                 '1' WHEN (operation = "1000" AND inc_result(n - 1 DOWNTO 0) = std_logic_vector(to_unsigned(0, n))) ELSE
                 '1' WHEN (operation = "1001" AND temp_not = std_logic_vector(to_unsigned(0, n))) ELSE
                 '1' WHEN (operation = "1010" AND add2_result(n - 1 DOWNTO 0) = std_logic_vector(to_unsigned(0, n))) ELSE
                 '0';

    carry_flag <= '0' WHEN reset = '1' ELSE
                  add_result(n) WHEN operation = "0001" ELSE  -- ADD (carry from bit n)
                  '1' WHEN operation = "0111" ELSE    -- SetC
                  inc_result(n) WHEN operation = "1000" ELSE  -- INC (carry from bit n)
                  add2_result(n) WHEN operation = "1010" ELSE  -- Add 2 (carry from bit n)
                  '0';

    -- ============================================
    -- CONTROL SIGNALS
    -- ============================================
    store <= '0' WHEN reset = '1' ELSE
             '1' WHEN operation = "0001" ELSE  -- ADD
             '1' WHEN operation = "0010" ELSE  -- SUB
             '1' WHEN operation = "0011" ELSE  -- AND
             '1' WHEN operation = "0100" ELSE  -- First/MOV
             '1' WHEN operation = "0101" ELSE  -- Second
             '1' WHEN operation = "0110" ELSE  -- SWAP
             '1' WHEN operation = "0111" ELSE  -- SetC
             '1' WHEN operation = "1000" ELSE  -- INC
             '1' WHEN operation = "1001" ELSE  -- NOT
             '1' WHEN operation = "1010" ELSE  -- Add 2
             '0';

    Restore <= '0' WHEN reset = '1' ELSE
               '1' WHEN operation = "1011" ELSE  -- Restore
               '0';

    -- ============================================
    -- DIRECT COMBINATIONAL OUTPUTS (NO REGISTERS)
    -- ============================================
    data_out <= result;
    flag_values <= neg_flag & zero_flag & carry_flag;

END ARCHITECTURE;