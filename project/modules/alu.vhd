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

    SIGNAL adder_in1, adder_in2, adder_out : STD_LOGIC_VECTOR(n - 1 DOWNTO 0);
    SIGNAL carry : STD_LOGIC;
    SIGNAL sub_sel : STD_LOGIC;
    SIGNAL result : STD_LOGIC_VECTOR(n - 1 DOWNTO 0);
    SIGNAL neg_flag, zero_flag, carry_flag : STD_LOGIC;
    SIGNAL temp_and, temp_not : STD_LOGIC_VECTOR(n - 1 DOWNTO 0);
    
    COMPONENT genFullAdder IS
        GENERIC (n : INTEGER := 32);
        PORT (
            a : IN STD_LOGIC_VECTOR(n - 1 DOWNTO 0);
            b : IN STD_LOGIC_VECTOR(n - 1 DOWNTO 0);
            cin : IN STD_LOGIC;
            f : OUT STD_LOGIC_VECTOR(n - 1 DOWNTO 0);
            cout : OUT STD_LOGIC
        );
    END COMPONENT;

BEGIN

    -- Instantiate adder component
    FULL_ADDER : genFullAdder
        GENERIC MAP(n => n)
        PORT MAP(
            a => adder_in1,
            b => adder_in2,
            cin => sub_sel,
            f => adder_out,
            cout => carry
        );

    -- Combinational logic for ALU operations
    PROCESS(operation, data_in1, data_in2, counter, adder_out, carry)
    BEGIN
        -- Default values
        adder_in1 <= (OTHERS => '0');
        adder_in2 <= (OTHERS => '0');
        sub_sel <= '0';
        result <= (OTHERS => '0');
        neg_flag <= '0';
        zero_flag <= '0';
        carry_flag <= '0';
        store <= '0';
        Restore <= '0';
        temp_and <= (OTHERS => '0');
        temp_not <= (OTHERS => '0');
        
        CASE operation IS
            -- 0001: ADD
            WHEN "0001" =>
                adder_in1 <= data_in1;
                adder_in2 <= data_in2;
                sub_sel <= '0';
                result <= adder_out;
                carry_flag <= carry;
                IF adder_out = std_logic_vector(to_unsigned(0, n)) THEN
                    zero_flag <= '1';
                ELSE
                    zero_flag <= '0';
                END IF;
                neg_flag <= adder_out(n - 1);
                store <= '1';

            -- 0010: SUB
            WHEN "0010" =>
                adder_in1 <= data_in1;
                adder_in2 <= NOT data_in2;
                sub_sel <= '1';
                result <= adder_out;
                carry_flag <= '0';
                IF adder_out = std_logic_vector(to_unsigned(0, n)) THEN
                    zero_flag <= '1';
                ELSE
                    zero_flag <= '0';
                END IF;
                neg_flag <= adder_out(n - 1);
                store <= '1';

            -- 0011: AND (also used for INC in control unit)
            WHEN "0011" =>
                temp_and <= data_in1 AND data_in2;
                result <= temp_and;
                IF temp_and = std_logic_vector(to_unsigned(0, n)) THEN
                    zero_flag <= '1';
                ELSE
                    zero_flag <= '0';
                END IF;
                neg_flag <= temp_and(n - 1);
                store <= '1';

            -- 0100: First/MOV (output first input unchanged)
            WHEN "0100" =>
                result <= data_in1;
                IF data_in1 = std_logic_vector(to_unsigned(0, n)) THEN
                    zero_flag <= '1';
                ELSE
                    zero_flag <= '0';
                END IF;
                neg_flag <= data_in1(n - 1);
                store <= '1';

            -- 0101: Second (output second input unchanged)
            WHEN "0101" =>
                result <= data_in2;
                IF data_in2 = std_logic_vector(to_unsigned(0, n)) THEN
                    zero_flag <= '1';
                ELSE
                    zero_flag <= '0';
                END IF;
                neg_flag <= data_in2(n - 1);
                store <= '1';

            -- 0110: First until counter (used for SWAP)
            WHEN "0110" =>
                IF counter = '1' THEN
                    result <= data_in2;
                ELSE
                    result <= data_in1;
                END IF;
                store <= '1';

            -- 0111: SetC (Set Carry Flag) - pass through first input
            WHEN "0111" =>
                result <= data_in1;
                carry_flag <= '1';
                IF data_in1 = std_logic_vector(to_unsigned(0, n)) THEN
                    zero_flag <= '1';
                ELSE
                    zero_flag <= '0';
                END IF;
                neg_flag <= data_in1(n - 1);
                store <= '1';

            -- 1000: INC
            WHEN "1000" =>
                adder_in1 <= data_in1;
                adder_in2 <= std_logic_vector(to_unsigned(1, n));
                sub_sel <= '0';
                result <= adder_out;
                carry_flag <= carry;
                IF adder_out = std_logic_vector(to_unsigned(0, n)) THEN
                    zero_flag <= '1';
                ELSE
                    zero_flag <= '0';
                END IF;
                neg_flag <= adder_out(n - 1);
                store <= '1';

            -- 1001: NOT (Bitwise NOT)
            WHEN "1001" =>
                temp_not <= NOT data_in1;
                result <= temp_not;
                IF temp_not = std_logic_vector(to_unsigned(0, n)) THEN
                    zero_flag <= '1';
                ELSE
                    zero_flag <= '0';
                END IF;
                neg_flag <= temp_not(n - 1);
                store <= '1';

            -- 1010: Add 2 and cache flags (for INT instruction)
            WHEN "1010" =>
                adder_in1 <= data_in1;
                adder_in2 <= std_logic_vector(to_unsigned(2, n));
                sub_sel <= '0';
                result <= adder_out;
                carry_flag <= carry;
                IF adder_out = std_logic_vector(to_unsigned(0, n)) THEN
                    zero_flag <= '1';
                ELSE
                    zero_flag <= '0';
                END IF;
                neg_flag <= adder_out(n - 1);
                store <= '1';

            -- 1011: Restore flags (for RTI instruction)
            WHEN "1011" =>
                result <= data_in1;
                Restore <= '1';
                store <= '0';

            -- Default: pass through data_in1
            WHEN OTHERS =>
                result <= data_in1;
                store <= '0';

        END CASE;

    END PROCESS;

    -- Register output on clock edge
    PROCESS(clk, reset)
    BEGIN
        IF reset = '1' THEN
            data_out <= (OTHERS => '0');
            flag_values <= "000";
        ELSIF rising_edge(clk) THEN
            data_out <= result;
            flag_values <= neg_flag & zero_flag & carry_flag;
        END IF;
    END PROCESS;

END ARCHITECTURE;