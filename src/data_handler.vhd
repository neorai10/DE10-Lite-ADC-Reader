library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity data_handler is
    port (
        clk         : in  std_logic;
        reset_n     : in  std_logic;
        adc_value   : in  std_logic_vector(11 downto 0);
        voltage_out : out std_logic_vector(15 downto 0)
    );
end entity data_handler;

architecture rtl of data_handler is
    
    signal voltage_reg : unsigned(15 downto 0);
    
begin

    process(clk, reset_n)
    begin
        if reset_n = '0' then
            voltage_reg <= (others => '0');
            
        elsif rising_edge(clk) then
            -- Simple scaling: multiply by 5 to get approximate millivolts
            -- ADC 4095 = 5V, so roughly: voltage_mV = adc_value * 5000/4095 ≈ adc_value * 1.22
            -- For simplicity: voltage_mV ≈ adc_value + (adc_value >> 2) 
            -- This gives approximately correct scaling
            
            voltage_reg <= resize(unsigned(adc_value), 16) + 
                          resize(unsigned(adc_value) srl 2, 16) +
                          resize(unsigned(adc_value) srl 4, 16);
        end if;
    end process;
    
    -- Output assignment
    voltage_out <= std_logic_vector(voltage_reg);
    
end architecture rtl;