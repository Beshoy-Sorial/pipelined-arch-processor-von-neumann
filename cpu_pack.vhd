LIBRARY ieee;
USE ieee.std_logic_1164.ALL;

PACKAGE cpu_pkg IS
    TYPE instruction_array IS ARRAY (natural range <>) OF STD_LOGIC_VECTOR(9 DOWNTO 0);
END PACKAGE;

PACKAGE BODY cpu_pkg IS
END PACKAGE BODY;