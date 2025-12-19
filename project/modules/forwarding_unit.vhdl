library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity Forwarding_Unit is
    Port (
        id_ex_rs          : in  STD_LOGIC_VECTOR(2 downto 0);
        id_ex_rt          : in  STD_LOGIC_VECTOR(2 downto 0);
        ex_mem_rd         : in  STD_LOGIC_VECTOR(2 downto 0);
        mem_wb_rd         : in  STD_LOGIC_VECTOR(2 downto 0);
        counter           : in  STD_LOGIC;
        ex_mem_reg_write  : in  STD_LOGIC;
        mem_wb_reg_write  : in  STD_LOGIC;
        forward_a         : out STD_LOGIC_VECTOR(1 downto 0);
        forward_b         : out STD_LOGIC_VECTOR(1 downto 0)
    );
end Forwarding_Unit;

architecture Behavioral of Forwarding_Unit is
begin
    process (id_ex_rs, id_ex_rt, ex_mem_rd, mem_wb_rd, 
             counter, ex_mem_reg_write, mem_wb_reg_write)
    begin
        -- Default values (No Forwarding)
        forward_a <= "00";
        forward_b <= "00";

        -- Logic only active when counter is NOT 1
        if (counter = '0') then
            
            -----------------------------------------------------------
            -- FORWARD A Logic (Source Register Rs)
            -----------------------------------------------------------
            
            -- EX Hazard: Forward from EX/MEM stage pipeline register
            if (ex_mem_reg_write = '1' and 
                unsigned(ex_mem_rd) /= 0 and 
                ex_mem_rd = id_ex_rs) then
                
                forward_a <= "10";
            
            -- MEM Hazard: Forward from MEM/WB stage pipeline register
            -- Note: The 'elsif' structure handles the "and not (EX Hazard)" 
            -- requirement automatically. If the EX hazard is true, this block is skipped.
            elsif (mem_wb_reg_write = '1' and 
                   unsigned(mem_wb_rd) /= 0 and 
                   mem_wb_rd = id_ex_rs) then
                   
                forward_a <= "01";
            end if;

            -----------------------------------------------------------
            -- FORWARD B Logic (Source Register Rt)
            -----------------------------------------------------------

            -- EX Hazard
            if (ex_mem_reg_write = '1' and 
                unsigned(ex_mem_rd) /= 0 and 
                ex_mem_rd = id_ex_rt) then
                
                forward_b <= "10";

            -- MEM Hazard
            elsif (mem_wb_reg_write = '1' and 
                   unsigned(mem_wb_rd) /= 0 and 
                   mem_wb_rd = id_ex_rt) then
                   
                forward_b <= "01";
            end if;

        else
            -- When counter is 1, force outputs to 00
            forward_a <= "00";
            forward_b <= "00";
        end if;
    end process;
end Behavioral;