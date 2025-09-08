library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity channel_selector is
    port (
        clk             : in  std_logic;
        reset_n         : in  std_logic;
        
        -- Switch inputs for channel selection (SW[5:1])
        channel_select  : in  std_logic_vector(4 downto 0);  -- SW[1] to SW[5]
        
        -- 5 channel inputs from ADC controller
        channel_0_value : in  std_logic_vector(11 downto 0);  -- A0
        channel_1_value : in  std_logic_vector(11 downto 0);  -- A1
        channel_2_value : in  std_logic_vector(11 downto 0);  -- A2
        channel_3_value : in  std_logic_vector(11 downto 0);  -- A3
        channel_4_value : in  std_logic_vector(11 downto 0);  -- A4
        
        -- Outputs
        selected_channel : out std_logic_vector(2 downto 0);   -- Which channel is selected (0-4)
        selected_value   : out std_logic_vector(11 downto 0)   -- Value of selected channel
    );
end entity channel_selector;

architecture rtl of channel_selector is
    
    signal selected_ch_reg : unsigned(2 downto 0);
    signal selected_val_reg : std_logic_vector(11 downto 0);
    
begin

    process(clk, reset_n)
    begin
        if reset_n = '0' then
            selected_ch_reg <= (others => '0');
            selected_val_reg <= (others => '0');
            
        elsif rising_edge(clk) then
            -- Priority encoder: highest switch wins
            -- SW[5] = Channel 4 (A4) - highest priority
            -- SW[4] = Channel 3 (A3)
            -- SW[3] = Channel 2 (A2)
            -- SW[2] = Channel 1 (A1)
            -- SW[1] = Channel 0 (A0) - lowest priority
            
            if channel_select(4) = '1' then        -- SW[5] - Channel 4 (A4)
                selected_ch_reg <= to_unsigned(4, 3);
                selected_val_reg <= channel_4_value;
                
            elsif channel_select(3) = '1' then     -- SW[4] - Channel 3 (A3)
                selected_ch_reg <= to_unsigned(3, 3);
                selected_val_reg <= channel_3_value;
                
            elsif channel_select(2) = '1' then     -- SW[3] - Channel 2 (A2)
                selected_ch_reg <= to_unsigned(2, 3);
                selected_val_reg <= channel_2_value;
                
            elsif channel_select(1) = '1' then     -- SW[2] - Channel 1 (A1)
                selected_ch_reg <= to_unsigned(1, 3);
                selected_val_reg <= channel_1_value;
                
            elsif channel_select(0) = '1' then     -- SW[1] - Channel 0 (A0)
                selected_ch_reg <= to_unsigned(0, 3);
                selected_val_reg <= channel_0_value;
                
            else
                -- No switch selected - default to Channel 0
                selected_ch_reg <= to_unsigned(0, 3);
                selected_val_reg <= channel_0_value;
            end if;
        end if;
    end process;
    
    -- Output assignments
    selected_channel <= std_logic_vector(selected_ch_reg);
    selected_value <= selected_val_reg;
    
end architecture rtl;