library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity calculation_unit is
    port (
        clk           : in  std_logic;
        reset_n       : in  std_logic;
        
        -- 5 averaged inputs from averaging_unit
        avg_channel_0 : in  std_logic_vector(11 downto 0);  -- Thumb
        avg_channel_1 : in  std_logic_vector(11 downto 0);  -- Index
        avg_channel_2 : in  std_logic_vector(11 downto 0);  -- Middle
        avg_channel_3 : in  std_logic_vector(11 downto 0);  -- Ring
        avg_channel_4 : in  std_logic_vector(11 downto 0);  -- Pinky
        
        -- Trigger input
        calculate     : in  std_logic;  -- Pulse to trigger calculation
        
        -- Result output
        result        : out std_logic_vector(4 downto 0);   -- 0-23 (24 options total)
        result_valid  : out std_logic;                      -- Result ready
        
        -- Average outputs for ESP32
        avg_thumb_out  : out std_logic_vector(11 downto 0);
        avg_index_out  : out std_logic_vector(11 downto 0);
        avg_middle_out : out std_logic_vector(11 downto 0);
        avg_ring_out   : out std_logic_vector(11 downto 0);
        avg_pinky_out  : out std_logic_vector(11 downto 0)
    );
end entity calculation_unit;

architecture rtl of calculation_unit is
    
    -- Internal signals
    signal thumb  : unsigned(11 downto 0);
    signal index_f : unsigned(11 downto 0);
    signal middle : unsigned(11 downto 0);
    signal ring   : unsigned(11 downto 0);
    signal pinky  : unsigned(11 downto 0);
    
    signal result_reg : std_logic_vector(4 downto 0);
    signal valid_reg  : std_logic;
    
begin

    process(clk, reset_n)
    begin
        if reset_n = '0' then
            result_reg <= (others => '0');
            valid_reg <= '0';
            
        elsif rising_edge(clk) then
            valid_reg <= '0';
            
            if calculate = '1' then
                -- Convert inputs to unsigned for comparison
                thumb  <= unsigned(avg_channel_0);
                index_f <= unsigned(avg_channel_1);
                middle <= unsigned(avg_channel_2);
                ring   <= unsigned(avg_channel_3);
                pinky  <= unsigned(avg_channel_4);
                
                -- Check all letter patterns (0-21: א-ת)
                if (thumb >= 1446 and thumb <= 1506) and
                   (index_f >= 2140 and index_f <= 2200) and
                   (middle >= 2320 and middle <= 2380) and
                   (ring >= 2733 and ring <= 2793) and
                   (pinky >= 1782 and pinky <= 1842) then
                    result_reg <= "00000";  -- 0: א
                    
                elsif (thumb >= 1436 and thumb <= 1496) and
                      (index_f >= 1595 and index_f <= 1655) and
                      (middle >= 1282 and middle <= 1342) and
                      (ring >= 1858 and ring <= 1918) and
                      (pinky >= 1730 and pinky <= 1790) then
                    result_reg <= "00001";  -- 1: ב
                    
                elsif (thumb >= 1453 and thumb <= 1513) and
                      (index_f >= 1661 and index_f <= 1721) and
                      (middle >= 2411 and middle <= 2471) and
                      (ring >= 2624 and ring <= 2684) and
                      (pinky >= 1772 and pinky <= 1832) then
                    result_reg <= "00010";  -- 2: ג
                    
                elsif (thumb >= 1431 and thumb <= 1491) and
                      (index_f >= 1656 and index_f <= 1716) and
                      (middle >= 1505 and middle <= 1565) and
                      (ring >= 1952 and ring <= 2012) and
                      (pinky >= 1734 and pinky <= 1794) then
                    result_reg <= "00011";  -- 3: ד
                    
                elsif (thumb >= 1426 and thumb <= 1486) and
                      (index_f >= 1536 and index_f <= 1596) and
                      (middle >= 1283 and middle <= 1343) and
                      (ring >= 2533 and ring <= 2593) and
                      (pinky >= 1623 and pinky <= 1683) then
                    result_reg <= "00100";  -- 4: ה
                    
                elsif (thumb >= 1640 and thumb <= 1700) and
                      (index_f >= 1620 and index_f <= 1680) and
                      (middle >= 2351 and middle <= 2411) and
                      (ring >= 2760 and ring <= 2820) and
                      (pinky >= 1820 and pinky <= 1880) then
                    result_reg <= "00101";  -- 5: ו
                    
                elsif (thumb >= 1570 and thumb <= 1630) and
                      (index_f >= 2191 and index_f <= 2251) and
                      (middle >= 2382 and middle <= 2442) and
                      (ring >= 2870 and ring <= 2930) and
                      (pinky >= 1825 and pinky <= 1885) then
                    result_reg <= "00110";  -- 6: ז
                    
                elsif (thumb >= 1570 and thumb <= 1630) and
                      (index_f >= 1620 and index_f <= 1680) and
                      (middle >= 2360 and middle <= 2420) and
                      (ring >= 2570 and ring <= 2630) and
                      (pinky >= 1750 and pinky <= 1810) then
                    result_reg <= "00111";  -- 7: ח
                    
                elsif (thumb >= 1670 and thumb <= 1730) and
                      (index_f >= 2070 and index_f <= 2130) and
                      (middle >= 1320 and middle <= 1380) and
                      (ring >= 1830 and ring <= 1890) and
                      (pinky >= 1720 and pinky <= 1780) then
                    result_reg <= "01000";  -- 8: ט
                    
                elsif (thumb >= 1625 and thumb <= 1685) and
                      (index_f >= 2270 and index_f <= 2330) and
                      (middle >= 2030 and middle <= 2090) and
                      (ring >= 2279 and ring <= 2339) and
                      (pinky >= 1730 and pinky <= 1790) then
                    result_reg <= "01001";  -- 9: י
                    
                elsif (thumb >= 1100 and thumb <= 1250) and
                      (index_f >= 1250 and index_f <= 1350) and
                      (middle >= 1300 and middle <= 1450) and
                      (ring >= 1750 and ring <= 1900) and
                      (pinky >= 1350 and pinky <= 1500) then
                    result_reg <= "01010";  -- 10: כ
                    
                elsif (thumb >= 1440 and thumb <= 1500) and
                      (index_f >= 1620 and index_f <= 1680) and
                      (middle >= 2340 and middle <= 2400) and
                      (ring >= 2670 and ring <= 2730) and
                      (pinky >= 1650 and pinky <= 1710) then
                    result_reg <= "01011";  -- 11: ל
                    
                elsif (thumb >= 1370 and thumb <= 1430) and
                      (index_f >= 2050 and index_f <= 2110) and
                      (middle >= 2095 and middle <= 2155) and
                      (ring >= 2700 and ring <= 2760) and
                      (pinky >= 1647 and pinky <= 1707) then
                    result_reg <= "01100";  -- 12: מ
                    
               elsif (thumb >= 1050 and thumb <= 1200) and
                      (index_f >= 1240 and index_f <= 1500) and
                      (middle >= 1400 and middle <= 1650) and
                      (ring >= 1700 and ring <= 1950) and
                      (pinky >= 1350 and pinky <= 1550) then
                    result_reg <= "01101";  -- 13: נ
                    
                elsif (thumb >= 1695 and thumb <= 1755) and
                      (index_f >= 2140 and index_f <= 2200) and
                      (middle >= 2200 and middle <= 2260) and
                      (ring >= 2822 and ring <= 2882) and
                      (pinky >= 1755 and pinky <= 1815) then
                    result_reg <= "01110";  -- 14: ס
                    
                elsif (thumb >= 1535 and thumb <= 1595) and
                      (index_f >= 2080 and index_f <= 2140) and
                      (middle >= 1970 and middle <= 2030) and
                      (ring >= 2770 and ring <= 2830) and
                      (pinky >= 1750 and pinky <= 1810) then
                    result_reg <= "01111";  -- 15: ע
                    
                elsif (thumb >= 1455 and thumb <= 1515) and
                      (index_f >= 1620 and index_f <= 1680) and
                      (middle >= 1370 and middle <= 1430) and
                      (ring >= 2340 and ring <= 2400) and
                      (pinky >= 1695 and pinky <= 1755) then
                    result_reg <= "10000";  -- 16: פ
                    
                elsif (thumb >= 1430 and thumb <= 1490) and
                      (index_f >= 1584 and index_f <= 1644) and
                      (middle >= 1285 and middle <= 1345) and
                      (ring >= 2335 and ring <= 2395) and
                      (pinky >= 1730 and pinky <= 1790) then
                    result_reg <= "10001";  -- 17: צ
                    
                elsif (thumb >= 1610 and thumb <= 1670) and
                      (index_f >= 1610 and index_f <= 1670) and
                      (middle >= 1550 and middle <= 1610) and
                      (ring >= 2320 and ring <= 2380) and
                      (pinky >= 1380 and pinky <= 1550) then
                    result_reg <= "10010";  -- 18: ק
                    

                  elsif (thumb >= 1150 and thumb <= 1350) and
                      (index_f >= 1150 and index_f <= 1350) and
                      (middle >= 1050 and middle <= 1250) and
                      (ring >= 1800 and ring <= 2050) and
                      (pinky >= 1300 and pinky <= 1650) then
                    result_reg <= "10011";  -- 19: ר
                    
                elsif (thumb >= 1500 and thumb <= 1560) and
                      (index_f >= 1570 and index_f <= 1630) and
                      (middle >= 1310 and middle <= 1370) and
                      (ring >= 1850 and ring <= 1910) and
                      (pinky >= 1790 and pinky <= 1850) then
                    result_reg <= "10100";  -- 20: ש
                    
                elsif (thumb >= 1080 and thumb <= 1250) and
                      (index_f >= 1300 and index_f <= 1550) and
                      (middle >= 1500 and middle <= 1750) and
                      (ring >= 1750 and ring <= 2080) and
                      (pinky >= 1300 and pinky <= 1700) then
                    result_reg <= "10101";  -- 21: ת
                    
                -- 22: Space (רווח) - all fingers straight (low values)
                elsif (thumb < 1300) and
                      (index_f < 1300) and
                      (middle < 1200) and
                      (ring < 1700) and
                      (pinky < 1500) then
                    result_reg <= "10110";  -- 22: Space
                    
                -- 23: Error (שגיאה/טעות בזיהוי) - default for unrecognized patterns
                else
                    result_reg <= "10111";  -- 23: Error/Unrecognized
                end if;
                
                valid_reg <= '1';
            end if;
        end if;
    end process;
    
    -- Output assignments
    result <= result_reg;
    result_valid <= valid_reg;
    
    -- Pass through average values to ESP32
    avg_thumb_out  <= avg_channel_0;
    avg_index_out  <= avg_channel_1;
    avg_middle_out <= avg_channel_2;
    avg_ring_out   <= avg_channel_3;
    avg_pinky_out  <= avg_channel_4;
    
end architecture rtl;