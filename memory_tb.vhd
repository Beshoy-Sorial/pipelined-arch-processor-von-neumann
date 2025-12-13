LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

ENTITY tb_memory IS
END ENTITY;

ARCHITECTURE sim OF tb_memory IS

    SIGNAL clk       : STD_LOGIC := '0';
    SIGNAL reset     : STD_LOGIC := '1';
    SIGNAL in_data   : STD_LOGIC_VECTOR(31 DOWNTO 0);
    SIGNAL out_data  : STD_LOGIC_VECTOR(31 DOWNTO 0);
    SIGNAL address   : STD_LOGIC_VECTOR(31 DOWNTO 0);
    SIGNAL mem_write : STD_LOGIC;
    SIGNAL mem_read  : STD_LOGIC;

    CONSTANT CLK_PERIOD : TIME := 10 ns;

BEGIN

    -- Clock
    clk <= NOT clk AFTER CLK_PERIOD / 2;

    -- DUT
    uut : ENTITY work.memory
        PORT MAP (
            clk       => clk,
            reset     => reset,
            in_data   => in_data,
            out_data  => out_data,
            address   => address,
            mem_write => mem_write,
            mem_read  => mem_read
        );

    -- Stimulus
    PROCESS
    BEGIN
        -- Init
        mem_write <= '0';
        mem_read  <= '0';
        address   <= (OTHERS => '0');
        in_data   <= (OTHERS => '0');

        -- Reset
        reset <= '1';
        WAIT FOR 20 ns;
        reset <= '0';

        -- Write DEADBEEF @ address 4
        WAIT UNTIL rising_edge(clk);
        address   <= x"00000004";
        in_data   <= x"DEADBEEF";
        mem_write <= '1';

        WAIT UNTIL rising_edge(clk);
        mem_write <= '0';

        -- Read it back
        WAIT UNTIL rising_edge(clk);
        mem_read <= '1';

        WAIT UNTIL rising_edge(clk);
        mem_read <= '0';

        -- Write 12345678 @ address 8
        WAIT UNTIL rising_edge(clk);
        address   <= x"00000008";
        in_data   <= x"12345678";
        mem_write <= '1';

        WAIT UNTIL rising_edge(clk);
        mem_write <= '0';

        -- Read it back
        WAIT UNTIL rising_edge(clk);
        mem_read <= '1';

        WAIT UNTIL rising_edge(clk);
        mem_read <= '0';

        WAIT FOR 40 ns;
        ASSERT FALSE REPORT "Simulation finished OK" SEVERITY FAILURE;
    END PROCESS;

END ARCHITECTURE;
