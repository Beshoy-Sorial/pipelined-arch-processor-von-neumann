library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity control_unit is
    port (
     opcode : in  std_logic_vector(9 downto 0);

     -- output signals
     HLT    : out std_logic; 
     
     -- fetch stage signals
     stop_pc : out std_logic;
    --
     -- alu signals 
     ALU_op : out std_logic_vector(3 downto 0);
     --map 
     -- 0001 -> ADD
     -- 0010 -> SUB
     -- 0011 -> AND
     -- 0100 -> First
     -- 0101 -> Second
     -- 0110 -> First until counter
     -- 0111 -> SetC
     -- 1000 -> inc 
     -- 1001 -> NOT
     -- 1010 -> Add 2 and cache flags
     -- 1011 -> Restore flags


     --ports signals 
     out_port_en : out std_logic;
     in_port_en  : out std_logic;

     --register file signals
     reg_write_en : out std_logic;

     -- MUX selection signals for calcs
     MEM_ALU : out std_logic;
     ALU_immediate : out std_logic;
      -- these 2 selectors chooses which value will be written back to the register file
      -- there is a big mux choosing alu/immediate/input_port , then is muxed with memory output

     R2_sel  : out std_logic;  -- select between Rsrc2 and immediate value

     --counter signals
     exe_counter_en : out std_logic;
     mem_counter_en : out std_logic;

     -- flush signals 
     flush_decode_decode : out std_logic;
     flush_decode_execute : out std_logic;  --used in INT and RTI
     flush_decode_mem : out std_logic;

     --signal memory read/write
     mem_write_en : out std_logic;
     pc_address : out std_logic;  --this is for the mux the chooses the either the pc to fetch next instruction or a diffrent address
     -- ^ name in file is fetch/mem
     write_data_or_pc : out std_logic;  --used to choose to write the data or the pc itself 0 -> data , 1 -> pc

    -- stack signals 
    sp_sel :out std_logic; -- select to use the sp when reading from memory or not 
    sp_alu_op : out std_logic_vector(1 downto 0); -- select the operation to be done on the sp (00 -> no change , 01 -> increment , 10 -> decrement)

    -- branch signals 
    branch_unit_en : out std_logic;
    branch_type : out std_logic_vector(2 downto 0);

    --non branch changing pc signals
    branch_sel : out std_logic;
    pc_form_mem : out std_logic; -- select to get the pc from memory or not

    --INT 
    index_sel : out std_logic
    );
end control_unit;

architecture rtl of control_unit is

    -- opcode fields
    signal instr_type : std_logic_vector(1 downto 0);
    signal instr_id   : std_logic_vector(2 downto 0);

begin

    instr_type <= opcode(9 downto 8); -- instruction category
    instr_id   <= opcode(7 downto 5); -- instruction inside category

    process(opcode, instr_type, instr_id)
    begin
        ------------------------------------------------------------------
        -- DEFAULT VALUES (everything zero)
        ------------------------------------------------------------------
        HLT <= '0';
        stop_pc <= '0';

        ALU_op <= "0000";

        out_port_en <= '0';
        in_port_en  <= '0';

        reg_write_en <= '0';

        MEM_ALU <= '0';
        ALU_immediate <= '0';
        R2_SEL <= '0';

        exe_counter_en <= '0';
        mem_counter_en <= '0';

        flush_decode_decode <= '0';
        flush_decode_execute <= '0';
        flush_decode_mem <= '0';

        mem_write_en <= '0';
        pc_address <= '0';
        write_data_or_pc <= '0';

        sp_sel <= '0';
        sp_alu_op <= "00";

        branch_unit_en <= '0';
        branch_type <= "000";
        branch_sel <= '0';
        pc_form_mem <= '0';

        index_sel <= '0';


        ------------------------------------------------------------------
        -- DECODE
        ------------------------------------------------------------------
        case instr_type is

            ------------------------------------------------------------------
            -- ONE OPERAND INSTRUCTIONS
            ------------------------------------------------------------------
            when "00" =>
                case instr_id is
                    when "000" =>  -- NOP
                        null;

                    when "001" =>  -- HLT
                        HLT <= '1';

                    when "010" =>  -- SETC
                        ALU_op <= "0111";

                    when "011" =>  -- NOT
                        ALU_op <= "1001";
                        reg_write_en <= '1';

                    when "100" =>  -- INC
                        ALU_op <= "0011";
                        reg_write_en <= '1';

                    when "101" =>  -- OUT
                        out_port_en <= '1';

                    when "110" =>  -- IN
                        in_port_en <= '1';
                        reg_write_en <= '1';
                        MEM_ALU <= '1';

                    when others =>
                        null;
                end case;

            ------------------------------------------------------------------
            -- TWO OPERAND / ALU INSTRUCTIONS
            ------------------------------------------------------------------
            when "01" =>
                reg_write_en <= '1';
                MEM_ALU <= '1';

                case instr_id is
                    when "000" => ALU_op <= "0001"; -- ADD
                    when "001" => ALU_op <= "0010"; -- SUB
                    when "010" => ALU_op <= "0011"; -- AND
                    when "011" => ALU_op <= "0100"; -- MOV

                    when "100" =>      --IADD
                    ALU_op <= "0001";
                    R2_sel <= '1';
                    flush_decode_decode <= '1';

                     --
                    when "101" => --swap
                        ALU_op <= "0110";
                        exe_counter_en <= '1';
                        stop_pc <= '1';
                    when others =>
                        null;
                end case;

            ------------------------------------------------------------------
            -- MEMORY / STACK INSTRUCTIONS
            ------------------------------------------------------------------
            when "10" =>
                case instr_id is
                    when "000" => -- PUSH
                        sp_sel <= '1';
                        sp_alu_op <= "10";
                        mem_write_en <= '1';
                        pc_address <= '1';
                        write_data_or_pc <= '0';
                        flush_decode_mem <= '1';
                        alu_op <= "0100";
                        stop_pc <= '1';

                    when "001" => -- POP
                        sp_sel <= '1';
                        sp_alu_op <= "01";
                        pc_address <= '1';
                        flush_decode_mem <= '1';
                        alu_op <= "0100";
                        reg_write_en <= '1';
                        stop_pc <= '1';

                    when "010" => -- LDM
                        R2_SEL <= '1';
                        alu_op <= "0101";
                        alu_immediate <= '1';
                        mem_alu <= '1';
                        flush_decode_decode <= '1';


                    when "011" => -- LDD
                       reg_write_en <= '1';
                       alu_op <= "0001";
                       flush_decode_decode <= '1';
                       R2_sel <= '1';
                       stop_pc <= '1';
                       pc_address <= '1';
                       flush_decode_mem <= '1';
                      

                    when "100" => -- STD
                       alu_op <= "0001";
                       flush_decode_decode <= '1';
                       R2_sel <= '1';
                       stop_pc <= '1';
                       pc_address <= '1';
                       flush_decode_mem <= '1';
                       mem_write_en <= '1';
                       write_data_or_pc <= '1';

                    when others =>
                        null;
                end case;

            ------------------------------------------------------------------
            -- BRANCH / PC MANIPULATION
            ------------------------------------------------------------------
            when "11" =>
                if instr_id(2) = '0' then
                branch_unit_en <= '1';
                flush_decode_decode <= '1';
                branch_type <= instr_id;
                
                else

                case instr_id is
                  
                    when "100" => -- CALL
                        stop_pc <= '1';
                        sp_sel <= '1';
                        pc_address <= '1';
                        mem_write_en <= '1';
                        sp_alu_op <= "10";
                        branch_sel <= '1';
                        flush_decode_decode <= '1';



                    when "101" => -- RET
                        sp_sel <= '1';
                        sp_alu_op <= "01";
                        pc_form_mem <= '1';
                        pc_address <= '1';
                        flush_decode_decode <= '1';
                        flush_decode_execute <= '1';
                        stop_pc <= '1';
                        flush_decode_mem <= '1'; -- check this 


                    when "110" => -- INT
                        index_sel <= '1';
                        stop_pc <= '1';
                        sp_sel <= '1';
                        alu_op <= "1010";
                        pc_address <= '1';
                        mem_write_en <= '1';
                        sp_alu_op <= "10";
                        flush_decode_decode <= '1';
                        flush_decode_execute <= '1';
                        flush_decode_mem <= '1';
                        pc_form_mem <= '1';
                        mem_counter_en <= '1';


                    when "111" => -- RTI
                        stop_pc <= '1';
                        alu_op <= "1011";
                        sp_sel <= '1';
                        sp_alu_op <= "01";
                        pc_address <= '1';
                        flush_decode_decode <= '1';
                        flush_decode_execute <= '1';
                        flush_decode_mem <= '1';
                        pc_form_mem <= '1';

                    when others =>
                        null;
                end case;

end if;
            when others =>
                null;
        end case;

    end process;

end rtl;
