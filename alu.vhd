LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;
ENTITY alu IS GENERIC (n : INTEGER := 32);
PORT (
    reset : IN STD_LOGIC;
    clk : IN STD_LOGIC;
    data_in1 : IN STD_LOGIC_VECTOR(n - 1 DOWNTO 0);
    data_in2 : IN STD_LOGIC_VECTOR(n - 1 DOWNTO 0);
    operation : IN STD_LOGIC_VECTOR(2 DOWNTO 0);
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

    sub_sel <= '1' WHEN operation = "011" ELSE
    '0';

    adder_in1 <= data_in1;
    adder_in2 <= data_in2 XOR (n - 1 DOWNTO 0 => sub_sel);

    U_ADDER : genFullAdder
    GENERIC MAP(n => n)
    PORT MAP(
        a => adder_in1,
        b => adder_in2,
        cin => sub_sel,
        f => adder_out,
        cout => carry
    );

    PROCESS (clk, reset)
    BEGIN
        IF reset = '1' THEN
            data_out <= (OTHERS => '0');
            flag_values <= (OTHERS => '0');

            ELSIF rising_edge(clk) THEN
            CASE operation IS

                WHEN "000" => -- MOV A
                    result <= data_in1;

                WHEN "001" => -- MOV B
                    result <= data_in2;

                WHEN "010" => -- ADD
                    result <= adder_out;
                    flag_values(2) <= carry;

                WHEN "011" => -- SUB
                    result <= adder_out;
                    flag_values(2) <= carry;

                WHEN "100" => -- AND
                    result <= data_in1 AND data_in2;

                WHEN OTHERS =>
                    result <= (OTHERS => '0');

            END CASE;

            -- Zero flag
            IF adder_out = (n - 1 DOWNTO 0 => '0') THEN
                flag_values(1) <= '1';
                ELSE
                flag_values(1) <= '0';
            END IF;

            -- Negative flag
            flag_values(0) <= result(n - 1);
            data_out <= result;

        END IF;
    END PROCESS;

END ARCHITECTURE;