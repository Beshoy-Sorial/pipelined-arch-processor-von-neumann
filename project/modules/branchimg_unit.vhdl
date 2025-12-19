library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity branching_unit is
    port (
        en      : in  std_logic;
        flags   : in  std_logic_vector(2 downto 0); -- zero, negative, carry
        branch_type : in std_logic_vector(2 downto 0);

        branch_sel : out std_logic;
        flush_decode_execute_branch : out std_logic;
        flush_branch_branch : out std_logic
    );
end branching_unit;

architecture rtl of branching_unit is
begin
    process(en, flags, branch_type)
    begin
        -- default outputs (VERY IMPORTANT)
        branch_sel <= '0';
        flush_branch_branch <= '0';
        flush_decode_execute_branch <= '0';

        if en = '1' then
            -- unconditional branch
            if branch_type = "011" then
                branch_sel <= '1';
                flush_branch_branch <= '1';
                flush_decode_execute_branch <= '1';

            -- conditional branches
            elsif (branch_type = "000" and flags(0) = '1') or  -- ZERO
                  (branch_type = "001" and flags(1) = '1') or  -- NEG
                  (branch_type = "010" and flags(2) = '1') then -- CARRY

                branch_sel <= '1';
                flush_branch_branch <= '1';
                flush_decode_execute_branch <= '1';
            end if;
        end if;
    end process;
end rtl;
