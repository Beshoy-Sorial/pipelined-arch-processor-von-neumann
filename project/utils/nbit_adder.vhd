LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
ENTITY genFullAdder IS
    GENERIC (n : INTEGER := 32);
    PORT (
        a, b : IN STD_LOGIC_VECTOR(n - 1 DOWNTO 0);
        cin : IN STD_LOGIC;
        f : OUT STD_LOGIC_VECTOR(n - 1 DOWNTO 0);
        cout : OUT STD_LOGIC
    );
END ENTITY;
ARCHITECTURE genFullAdderbehave OF genFullAdder IS
    COMPONENT full_adder IS
        PORT (
            a, b : IN STD_LOGIC;
            cin : IN STD_LOGIC;
            out1 : OUT STD_LOGIC;
            cout : OUT STD_LOGIC
        );
    END COMPONENT;
    SIGNAL temp : STD_LOGIC_VECTOR(n DOWNTO 0);
BEGIN
    temp(0) <= cin;
    loop1 : FOR i IN 0 TO n - 1 GENERATE
        FA : full_adder PORT MAP(a(i), b(i), temp(i), f(i), temp(i + 1));
    END GENERATE;
    cout <= temp(n); 
END ARCHITECTURE;