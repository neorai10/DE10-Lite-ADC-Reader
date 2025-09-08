library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity timing_controller is
    port (
        clk         : in  std_logic;  -- 50MHz clock
        reset_n     : in  std_logic;  -- Active low reset
        enable      : in  std_logic;  -- Enable timing (from SW[0])
        
        -- Outputs
        sample_trigger : out std_logic;  -- Pulse every 5 seconds (CHANGED)
        seconds_count  : out std_logic_vector(3 downto 0);  -- Current second (0-4, but 4 bits for compatibility)
        timing_active  : out std_logic   -- LED indicator that timing is running
    );
end entity timing_controller;

architecture rtl of timing_controller is
    
    -- Constants for timing (CHANGED for 5 seconds)
    constant CLOCK_FREQ     : integer := 50_000_000;  -- 50MHz
    constant SECONDS_TARGET : integer := 5;           -- 5 seconds (CHANGED)
    constant CLOCKS_PER_SEC : integer := CLOCK_FREQ;  -- 50M clocks = 1 second
    
    -- Internal signals
    signal clock_counter    : unsigned(25 downto 0);  -- Counter for 1 second (up to 67M)
    signal second_counter   : unsigned(3 downto 0);   -- Counter for seconds (0-4)
    signal sample_pulse     : std_logic;
    signal timing_running   : std_logic;
    signal trigger_extend   : unsigned(23 downto 0);  -- Extend trigger pulse for visibility
    
begin
    
    -- Main timing process
    process(clk, reset_n)
    begin
        if reset_n = '0' then
            clock_counter <= (others => '0');
            second_counter <= (others => '0');
            sample_pulse <= '0';
            timing_running <= '0';
            trigger_extend <= (others => '0');
            
        elsif rising_edge(clk) then
            -- Default values
            sample_pulse <= '0';
            
            -- Extend trigger pulse for LED visibility
            if trigger_extend > 0 then
                trigger_extend <= trigger_extend - 1;
                sample_pulse <= '1';  -- Keep pulse extended
            end if;
            
            if enable = '1' then
                timing_running <= '1';
                
                -- Count clock cycles for 1 second
                if clock_counter >= (CLOCKS_PER_SEC - 1) then
                    -- One second has passed
                    clock_counter <= (others => '0');
                    
                    -- Count seconds
                    if second_counter >= (SECONDS_TARGET - 1) then
                        -- 5 seconds completed
                        second_counter <= (others => '0');
                        sample_pulse <= '1';  -- Generate trigger pulse
                        trigger_extend <= to_unsigned(25_000_000, 24);  -- Extend for 0.5 seconds (visible on LED)
                    else
                        second_counter <= second_counter + 1;
                    end if;
                    
                else
                    clock_counter <= clock_counter + 1;
                end if;
                
            else
                -- Reset when disabled
                timing_running <= '0';
                clock_counter <= (others => '0');
                second_counter <= (others => '0');
                trigger_extend <= (others => '0');
            end if;
        end if;
    end process;
    
    -- Output assignments
    sample_trigger <= sample_pulse;
    seconds_count <= std_logic_vector(resize(second_counter, 4));
    timing_active <= timing_running;
    
end architecture rtl;