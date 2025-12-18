LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE ieee.numeric_std.ALL;

ENTITY memory IS PORT (
        clk : IN STD_LOGIC;
        reset : IN STD_LOGIC;
        in_data : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
        out_data : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
        address : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
        mem_write : IN STD_LOGIC;
        mem_read : IN STD_LOGIC
);
END ENTITY;
ARCHITECTURE mem_behave OF memory IS
        CONSTANT ADDR_WIDTH : INTEGER := 10;
        CONSTANT DATA_WIDTH : INTEGER := 31;
        TYPE mem_array IS ARRAY(0 to (2 ** ADDR_WIDTH)) OF STD_LOGIC_VECTOR(DATA_WIDTH DOWNTO 0);
        SIGNAL main_memory : mem_array;
BEGIN
        memo_main : PROCESS (clk, reset)
        BEGIN
                IF (reset = '1') THEN
                        out_data <= (OTHERS => '0');
                        main_memory <= (OTHERS => (OTHERS => '0'));
                ELSIF rising_edge(clk) THEN
                        IF (mem_write = '1') THEN
                                main_memory(to_integer(unsigned(address))) <= in_data;
                        ELSIF (mem_read = '1') THEN
                                out_data <= main_memory(to_integer(unsigned(address)));
                        END IF;
                END IF;
        END PROCESS memo_main;
END ARCHITECTURE;