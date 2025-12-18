LIBRARY ieee;
USE ieee.std_logic_1164.ALL;

ENTITY full_adder IS
    PORT (
        a, b : IN STD_LOGIC;
        cin : IN STD_LOGIC;
        out1 : OUT STD_LOGIC;
        cout : OUT STD_LOGIC
    );
END ENTITY full_adder;
ARCHITECTURE adderbehave OF full_adder IS
BEGIN
    out1 <= (a XOR b) XOR cin;
    cout <= (a AND b) OR (cin AND (a XOR b));
END ARCHITECTURE;