LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;
ENTITY pipeline_reg IS
  GENERIC (n : INTEGER := 32);
  PORT (
    clk : IN STD_LOGIC;
    enable : IN STD_LOGIC;
    data_in : IN STD_LOGIC_VECTOR(n - 1 DOWNTO 0);
    data_out : OUT STD_LOGIC_VECTOR(n - 1 DOWNTO 0));
END pipeline_reg;

ARCHITECTURE arch_pipeline_reg OF pipeline_reg IS
  SIGNAL reg_val : STD_LOGIC_VECTOR(n - 1 DOWNTO 0);
BEGIN
  PROCESS (clk)
  BEGIN
    IF rising_edge(clk) THEN
      IF enable = '0' THEN
        reg_val <= data_in;
      ELSE
        reg_val <= reg_val;

      END IF;
    END IF;
  END PROCESS;
  data_out <= reg_val;
END arch_pipeline_reg;