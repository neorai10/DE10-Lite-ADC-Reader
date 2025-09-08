library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity averaging_unit is
    port (
        clk             : in  std_logic;
        reset_n         : in  std_logic;
        
        -- Control signals
        enable          : in  std_logic;  -- Enable averaging
        sample_trigger  : in  std_logic;  -- 5-second trigger from timing_controller
        
        -- 5 channel inputs from ADC controller
        channel_0_value : in  std_logic_vector(11 downto 0);
        channel_1_value : in  std_logic_vector(11 downto 0);
        channel_2_value : in  std_logic_vector(11 downto 0);
        channel_3_value : in  std_logic_vector(11 downto 0);
        channel_4_value : in  std_logic_vector(11 downto 0);
        data_valid      : in  std_logic;  -- New data available
        
        -- Averaged outputs (updated every 5 seconds)
        avg_channel_0   : out std_logic_vector(11 downto 0);
        avg_channel_1   : out std_logic_vector(11 downto 0);
        avg_channel_2   : out std_logic_vector(11 downto 0);
        avg_channel_3   : out std_logic_vector(11 downto 0);
        avg_channel_4   : out std_logic_vector(11 downto 0);
        
        -- Status outputs
        averaging_active : out std_logic;  -- Currently collecting samples
        average_ready    : out std_logic   -- New averages available
    );
end entity averaging_unit;

architecture rtl of averaging_unit is
    
    -- Sample counters and accumulators for each channel
    -- 24 bits can hold up to 4096 samples of 12-bit values
    signal ch0_accumulator : unsigned(23 downto 0);
    signal ch1_accumulator : unsigned(23 downto 0);
    signal ch2_accumulator : unsigned(23 downto 0);
    signal ch3_accumulator : unsigned(23 downto 0);
    signal ch4_accumulator : unsigned(23 downto 0);
    
    signal sample_count    : unsigned(15 downto 0);   -- Count of samples collected
    
    -- Output registers
    signal avg_ch0_reg     : std_logic_vector(11 downto 0);
    signal avg_ch1_reg     : std_logic_vector(11 downto 0);
    signal avg_ch2_reg     : std_logic_vector(11 downto 0);
    signal avg_ch3_reg     : std_logic_vector(11 downto 0);
    signal avg_ch4_reg     : std_logic_vector(11 downto 0);
    
    -- Control signals
    signal averaging_active_reg : std_logic;
    signal average_ready_reg    : std_logic;
    signal sample_trigger_prev  : std_logic;
    signal sample_trigger_edge  : std_logic;
    
    -- For division - temporary signals
    signal ch0_average : unsigned(23 downto 0);
    signal ch1_average : unsigned(23 downto 0);
    signal ch2_average : unsigned(23 downto 0);
    signal ch3_average : unsigned(23 downto 0);
    signal ch4_average : unsigned(23 downto 0);
    
    -- DEBUG: Add a flag to know if we've completed at least one period
    signal first_period_complete : std_logic;
    
begin

    -- Edge detection for sample_trigger (start of new 5-second period)
    process(clk, reset_n)
    begin
        if reset_n = '0' then
            sample_trigger_prev <= '0';
        elsif rising_edge(clk) then
            sample_trigger_prev <= sample_trigger;
        end if;
    end process;
    
    sample_trigger_edge <= sample_trigger and not sample_trigger_prev;

    -- Main averaging process
    process(clk, reset_n)
    begin
        if reset_n = '0' then
            -- Reset all accumulators
            ch0_accumulator <= (others => '0');
            ch1_accumulator <= (others => '0');
            ch2_accumulator <= (others => '0');
            ch3_accumulator <= (others => '0');
            ch4_accumulator <= (others => '0');
            
            sample_count <= (others => '0');
            
            -- Reset output registers
            avg_ch0_reg <= (others => '0');
            avg_ch1_reg <= (others => '0');
            avg_ch2_reg <= (others => '0');
            avg_ch3_reg <= (others => '0');
            avg_ch4_reg <= (others => '0');
            
            -- Reset control signals
            averaging_active_reg <= '0';
            average_ready_reg <= '0';
            first_period_complete <= '0';
            
        elsif rising_edge(clk) then
            -- Default values
            average_ready_reg <= '0';
            
            if enable = '1' then
                if sample_trigger_edge = '1' then
                    -- Start of new 5-second period
                    
                    -- Only calculate averages if we have completed at least one period
                    if first_period_complete = '1' and sample_count > 0 then
                        -- Protection against division by zero
                        -- Divide full accumulator by sample count, then resize to 12 bits
                        ch0_average <= ch0_accumulator / sample_count;
                        ch1_average <= ch1_accumulator / sample_count;
                        ch2_average <= ch2_accumulator / sample_count;
                        ch3_average <= ch3_accumulator / sample_count;
                        ch4_average <= ch4_accumulator / sample_count;
                        
                        -- Store the 12-bit result
                        avg_ch0_reg <= std_logic_vector(resize(ch0_average, 12));
                        avg_ch1_reg <= std_logic_vector(resize(ch1_average, 12));
                        avg_ch2_reg <= std_logic_vector(resize(ch2_average, 12));
                        avg_ch3_reg <= std_logic_vector(resize(ch3_average, 12));
                        avg_ch4_reg <= std_logic_vector(resize(ch4_average, 12));
                        
                        average_ready_reg <= '1';
                    end if;
                    
                    -- Mark that we've completed at least one period
                    first_period_complete <= '1';
                    
                    -- Reset accumulators for new period
                    ch0_accumulator <= (others => '0');
                    ch1_accumulator <= (others => '0');
                    ch2_accumulator <= (others => '0');
                    ch3_accumulator <= (others => '0');
                    ch4_accumulator <= (others => '0');
                    sample_count <= (others => '0');
                    averaging_active_reg <= '1';
                    
                elsif data_valid = '1' and averaging_active_reg = '1' then
                    -- Accumulate new samples
                    -- Only accumulate if we won't overflow (safety check)
                    if sample_count < 4095 then  -- Prevent overflow
                        ch0_accumulator <= ch0_accumulator + unsigned(channel_0_value);
                        ch1_accumulator <= ch1_accumulator + unsigned(channel_1_value);
                        ch2_accumulator <= ch2_accumulator + unsigned(channel_2_value);
                        ch3_accumulator <= ch3_accumulator + unsigned(channel_3_value);
                        ch4_accumulator <= ch4_accumulator + unsigned(channel_4_value);
                        sample_count <= sample_count + 1;
                    end if;
                end if;
                
            else
                -- Reset when disabled
                averaging_active_reg <= '0';
                ch0_accumulator <= (others => '0');
                ch1_accumulator <= (others => '0');
                ch2_accumulator <= (others => '0');
                ch3_accumulator <= (others => '0');
                ch4_accumulator <= (others => '0');
                sample_count <= (others => '0');
                first_period_complete <= '0';
            end if;
        end if;
    end process;
    
    -- Output assignments
    avg_channel_0 <= avg_ch0_reg;
    avg_channel_1 <= avg_ch1_reg;
    avg_channel_2 <= avg_ch2_reg;
    avg_channel_3 <= avg_ch3_reg;
    avg_channel_4 <= avg_ch4_reg;
    
    averaging_active <= averaging_active_reg;
    average_ready <= average_ready_reg;
    
end architecture rtl;