library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity display_controller is
    port (
        clk         : in  std_logic;
        reset_n     : in  std_logic;
        voltage_in  : in  std_logic_vector(15 downto 0);  -- Voltage in millivolts
        number_in   : in  std_logic_vector(15 downto 0);  -- Number to display (0-23)
        display_mode: in  std_logic;                       -- '0' = voltage, '1' = number
        hex0        : out std_logic_vector(6 downto 0);   -- Least significant digit
        hex1        : out std_logic_vector(6 downto 0);
        hex2        : out std_logic_vector(6 downto 0);
        hex3        : out std_logic_vector(6 downto 0);
        hex4        : out std_logic_vector(6 downto 0);
        hex5        : out std_logic_vector(6 downto 0)    -- Most significant digit
    );
end entity display_controller;

architecture rtl of display_controller is
    
    -- Function to convert 4-bit binary to 7-segment display
    function bin_to_7seg(digit : std_logic_vector(3 downto 0)) return std_logic_vector is
    begin
        case digit is
            when "0000" => return "1000000"; -- 0
            when "0001" => return "1111001"; -- 1
            when "0010" => return "0100100"; -- 2
            when "0011" => return "0110000"; -- 3
            when "0100" => return "0011001"; -- 4
            when "0101" => return "0010010"; -- 5
            when "0110" => return "0000010"; -- 6
            when "0111" => return "1111000"; -- 7
            when "1000" => return "0000000"; -- 8
            when "1001" => return "0010000"; -- 9
            when others => return "1111111"; -- blank
        end case;
    end function;
    
    -- Signals for BCD conversion
    signal voltage_reg : unsigned(15 downto 0);
    signal number_reg  : unsigned(15 downto 0);
    signal display_value : unsigned(15 downto 0);  -- Selected value based on mode
    signal temp_value : unsigned(15 downto 0);
    
    -- BCD digits
    signal ones, tens, hundreds, thousands, ten_thousands, hundred_thousands : unsigned(3 downto 0);
    
begin

    process(clk, reset_n)
        variable temp_var : unsigned(15 downto 0);
    begin
        if reset_n = '0' then
            voltage_reg <= (others => '0');
            number_reg <= (others => '0');
            display_value <= (others => '0');
            ones <= (others => '0');
            tens <= (others => '0');
            hundreds <= (others => '0');
            thousands <= (others => '0');
            ten_thousands <= (others => '0');
            hundred_thousands <= (others => '0');
            
        elsif rising_edge(clk) then
            voltage_reg <= unsigned(voltage_in);
            number_reg <= unsigned(number_in);
            
            -- Select display value based on mode
            if display_mode = '1' then
                display_value <= number_reg;  -- Show number (0-22)
            else
                display_value <= voltage_reg; -- Show voltage (mV)
            end if;
            
            temp_var := display_value;
            
            -- Simple BCD conversion using repeated subtraction
            -- Extract ones
            if temp_var >= 10000 then
                ten_thousands <= to_unsigned(1, 4);
                temp_var := temp_var - 10000;
            else
                ten_thousands <= to_unsigned(0, 4);
            end if;
            
            -- Extract thousands
            if temp_var >= 9000 then
                thousands <= to_unsigned(9, 4);
                temp_var := temp_var - 9000;
            elsif temp_var >= 8000 then
                thousands <= to_unsigned(8, 4);
                temp_var := temp_var - 8000;
            elsif temp_var >= 7000 then
                thousands <= to_unsigned(7, 4);
                temp_var := temp_var - 7000;
            elsif temp_var >= 6000 then
                thousands <= to_unsigned(6, 4);
                temp_var := temp_var - 6000;
            elsif temp_var >= 5000 then
                thousands <= to_unsigned(5, 4);
                temp_var := temp_var - 5000;
            elsif temp_var >= 4000 then
                thousands <= to_unsigned(4, 4);
                temp_var := temp_var - 4000;
            elsif temp_var >= 3000 then
                thousands <= to_unsigned(3, 4);
                temp_var := temp_var - 3000;
            elsif temp_var >= 2000 then
                thousands <= to_unsigned(2, 4);
                temp_var := temp_var - 2000;
            elsif temp_var >= 1000 then
                thousands <= to_unsigned(1, 4);
                temp_var := temp_var - 1000;
            else
                thousands <= to_unsigned(0, 4);
            end if;
            
            -- Extract hundreds (similar pattern)
            if temp_var >= 900 then
                hundreds <= to_unsigned(9, 4);
                temp_var := temp_var - 900;
            elsif temp_var >= 800 then
                hundreds <= to_unsigned(8, 4);
                temp_var := temp_var - 800;
            elsif temp_var >= 700 then
                hundreds <= to_unsigned(7, 4);
                temp_var := temp_var - 700;
            elsif temp_var >= 600 then
                hundreds <= to_unsigned(6, 4);
                temp_var := temp_var - 600;
            elsif temp_var >= 500 then
                hundreds <= to_unsigned(5, 4);
                temp_var := temp_var - 500;
            elsif temp_var >= 400 then
                hundreds <= to_unsigned(4, 4);
                temp_var := temp_var - 400;
            elsif temp_var >= 300 then
                hundreds <= to_unsigned(3, 4);
                temp_var := temp_var - 300;
            elsif temp_var >= 200 then
                hundreds <= to_unsigned(2, 4);
                temp_var := temp_var - 200;
            elsif temp_var >= 100 then
                hundreds <= to_unsigned(1, 4);
                temp_var := temp_var - 100;
            else
                hundreds <= to_unsigned(0, 4);
            end if;
            
            -- Extract tens
            if temp_var >= 90 then
                tens <= to_unsigned(9, 4);
                temp_var := temp_var - 90;
            elsif temp_var >= 80 then
                tens <= to_unsigned(8, 4);
                temp_var := temp_var - 80;
            elsif temp_var >= 70 then
                tens <= to_unsigned(7, 4);
                temp_var := temp_var - 70;
            elsif temp_var >= 60 then
                tens <= to_unsigned(6, 4);
                temp_var := temp_var - 60;
            elsif temp_var >= 50 then
                tens <= to_unsigned(5, 4);
                temp_var := temp_var - 50;
            elsif temp_var >= 40 then
                tens <= to_unsigned(4, 4);
                temp_var := temp_var - 40;
            elsif temp_var >= 30 then
                tens <= to_unsigned(3, 4);
                temp_var := temp_var - 30;
            elsif temp_var >= 20 then
                tens <= to_unsigned(2, 4);
                temp_var := temp_var - 20;
            elsif temp_var >= 10 then
                tens <= to_unsigned(1, 4);
                temp_var := temp_var - 10;
            else
                tens <= to_unsigned(0, 4);
            end if;
            
            -- Remainder is ones
            ones <= temp_var(3 downto 0);
            
            -- For values over 10000, show 1 in leftmost digit
            if display_value >= 10000 then
                hundred_thousands <= to_unsigned(1, 4);
            else
                hundred_thousands <= to_unsigned(0, 4);
            end if;
            
        end if;
    end process;
    
    -- Convert BCD digits to 7-segment display
    hex0 <= bin_to_7seg(std_logic_vector(ones));           -- Ones (rightmost)
    hex1 <= bin_to_7seg(std_logic_vector(tens));           -- Tens
    hex2 <= bin_to_7seg(std_logic_vector(hundreds));       -- Hundreds
    hex3 <= bin_to_7seg(std_logic_vector(thousands));      -- Thousands  
    hex4 <= bin_to_7seg(std_logic_vector(ten_thousands));  -- Ten thousands
    hex5 <= bin_to_7seg(std_logic_vector(hundred_thousands)); -- Hundred thousands (leftmost)
    
end architecture rtl;