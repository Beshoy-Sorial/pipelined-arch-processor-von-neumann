LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;
ENTITY reg_file IS
  PORT (
    clk : IN STD_LOGIC;
    write_enable : IN STD_LOGIC;
    read_reg_address_1 : IN STD_LOGIC_VECTOR(2 DOWNTO 0);
    read_reg_address_2 : IN STD_LOGIC_VECTOR(2 DOWNTO 0);
    write_reg_address : IN STD_LOGIC_VECTOR(2 DOWNTO 0);
    write_data : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
    read_data_1 : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
    read_data_2 : OUT STD_LOGIC_VECTOR(31 DOWNTO 0)
  );
END reg_file;

ARCHITECTURE arch_reg_file OF reg_file IS
  TYPE type_array IS ARRAY (0 TO 7) OF STD_LOGIC_VECTOR (31 DOWNTO 0);
  SIGNAL register_file : type_array := (OTHERS => (OTHERS => '0'));
BEGIN
  write_process : PROCESS (clk)
  BEGIN
    IF rising_edge(clk) THEN
      IF write_enable = '1' THEN
        register_file(to_integer(unsigned(write_reg_address))) <= write_data;
      END IF;
    END IF;
  END PROCESS;
  read_process : PROCESS (clk)
  BEGIN
    IF falling_edge(clk) THEN
      read_data_1 <= register_file(to_integer(unsigned(read_reg_address_1)));
      read_data_2 <= register_file(to_integer(unsigned(read_reg_address_2)));
    END IF;
  END PROCESS;

END arch_reg_file;