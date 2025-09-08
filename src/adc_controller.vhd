library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity adc_controller is
    port (
        clk         : in  std_logic;  -- 50MHz system clock
        reset_n     : in  std_logic;  -- Active low reset
        enable      : in  std_logic;  -- Enable from SW[0]
        sample_trigger : in std_logic; -- Pulse every 10 seconds from timing_controller
        
        -- ADC Avalon-MM slave interface  
        adc_write      : out std_logic;
        adc_read       : out std_logic;
        adc_readdata   : in  std_logic_vector(31 downto 0);
        adc_writedata  : out std_logic_vector(31 downto 0);
        adc_address    : out std_logic_vector(2 downto 0);
        adc_waitrequest: in  std_logic;
        
        -- Output data for 5 channels
        channel_0_value : out std_logic_vector(11 downto 0);
        channel_1_value : out std_logic_vector(11 downto 0);
        channel_2_value : out std_logic_vector(11 downto 0);
        channel_3_value : out std_logic_vector(11 downto 0);
        channel_4_value : out std_logic_vector(11 downto 0);
        
        -- Control signals
        data_valid      : out std_logic;  -- Pulse when new data from any channel
        current_channel : out std_logic_vector(2 downto 0);  -- Current channel being read (0-4)
        reading_active  : out std_logic   -- High when actively reading
    );
end entity adc_controller;

architecture rtl of adc_controller is

    -- State machine for ADC reading (based on working original)
    type adc_state_t is (IDLE, ENABLE_AUTO, TRIGGER_UPDATE, READ_DATA, WAIT_READ, NEXT_CHANNEL);
    signal state : adc_state_t;
    
    -- Timing counter for ADC conversion
    signal conversion_counter : unsigned(15 downto 0);
    constant READ_DELAY_CYCLES : unsigned(15 downto 0) := to_unsigned(2500, 16); -- ~50us at 50MHz
    
    -- Channel tracking
    signal current_ch_reg : unsigned(2 downto 0);
    
    -- Channel data registers
    signal ch0_data_reg : std_logic_vector(11 downto 0);
    signal ch1_data_reg : std_logic_vector(11 downto 0);
    signal ch2_data_reg : std_logic_vector(11 downto 0);
    signal ch3_data_reg : std_logic_vector(11 downto 0);
    signal ch4_data_reg : std_logic_vector(11 downto 0);
    
    -- Control signals
    signal data_valid_reg : std_logic;
    signal reading_active_reg : std_logic;
    
    -- ADC register addresses (based on Intel ADC IP documentation - CORRECT ADDRESSES)
    constant ADC_CH0_REG     : std_logic_vector(2 downto 0) := "000";  -- Channel 0 data (offset 0)
    constant ADC_CH1_REG     : std_logic_vector(2 downto 0) := "001";  -- Channel 1 data (offset 4)
    constant ADC_CH2_REG     : std_logic_vector(2 downto 0) := "010";  -- Channel 2 data (offset 8)
    constant ADC_CH3_REG     : std_logic_vector(2 downto 0) := "011";  -- Channel 3 data (offset 12)
    constant ADC_CH4_REG     : std_logic_vector(2 downto 0) := "100";  -- Channel 4 data (offset 16)
    constant ADC_UPDATE_REG  : std_logic_vector(2 downto 0) := "000";  -- Update register (same as CH0 write)
    constant ADC_AUTO_REG    : std_logic_vector(2 downto 0) := "001";  -- Auto-Update register (offset 4)

begin

    -- State machine process (based on working original)
    process(clk, reset_n)
    begin
        if reset_n = '0' then
            state <= IDLE;
            conversion_counter <= (others => '0');
            current_ch_reg <= (others => '0');
            
            -- Reset ADC interface
            adc_write <= '0';
            adc_read <= '0';
            adc_writedata <= (others => '0');
            adc_address <= (others => '0');
            
            -- Reset data registers
            ch0_data_reg <= (others => '0');
            ch1_data_reg <= (others => '0');
            ch2_data_reg <= (others => '0');
            ch3_data_reg <= (others => '0');
            ch4_data_reg <= (others => '0');
            
            -- Reset control signals
            data_valid_reg <= '0';
            reading_active_reg <= '0';
            
        elsif rising_edge(clk) then
            -- Default values
            adc_write <= '0';
            adc_read <= '0';
            data_valid_reg <= '0';
            
            case state is
                when IDLE =>
                    reading_active_reg <= '0';
                    current_ch_reg <= (others => '0');
                    conversion_counter <= (others => '0');
                    
                    if enable = '1' then
                        state <= ENABLE_AUTO;
                        reading_active_reg <= '1';
                    end if;
                
                when ENABLE_AUTO =>
                    -- Enable auto-update mode (EXACTLY like working original)
                    adc_address <= ADC_AUTO_REG;
                    adc_writedata <= x"00000001";  -- Enable auto-update
                    adc_write <= '1';
                    
                    if adc_waitrequest = '0' then
                        state <= TRIGGER_UPDATE;
                    end if;
                
                when TRIGGER_UPDATE =>
                    -- Trigger an update cycle (EXACTLY like working original)
                    adc_address <= ADC_UPDATE_REG;
                    adc_writedata <= x"00000001";  -- Any value triggers update
                    adc_write <= '1';
                    
                    if adc_waitrequest = '0' then
                        state <= READ_DATA;
                        conversion_counter <= (others => '0');
                    end if;
                
                when READ_DATA =>
                    -- Wait a bit then read from current channel (EXACTLY like working original)
                    conversion_counter <= conversion_counter + 1;
                    
                    if conversion_counter >= READ_DELAY_CYCLES then  -- Wait ~50us at 50MHz
                        case current_ch_reg is
                            when "000" => adc_address <= ADC_CH0_REG;
                            when "001" => adc_address <= ADC_CH1_REG;
                            when "010" => adc_address <= ADC_CH2_REG;
                            when "011" => adc_address <= ADC_CH3_REG;
                            when "100" => adc_address <= ADC_CH4_REG;
                            when others => adc_address <= ADC_CH0_REG;
                        end case;
                        
                        adc_read <= '1';
                        
                        if adc_waitrequest = '0' then
                            state <= WAIT_READ;
                        end if;
                    end if;
                
                when WAIT_READ =>
                    -- Capture read data (EXACTLY like working original)
                    case current_ch_reg is
                        when "000" => ch0_data_reg <= adc_readdata(11 downto 0);
                        when "001" => ch1_data_reg <= adc_readdata(11 downto 0);
                        when "010" => ch2_data_reg <= adc_readdata(11 downto 0);
                        when "011" => ch3_data_reg <= adc_readdata(11 downto 0);
                        when "100" => ch4_data_reg <= adc_readdata(11 downto 0);
                        when others => ch0_data_reg <= adc_readdata(11 downto 0);
                    end case;
                    
                    data_valid_reg <= '1';
                    state <= NEXT_CHANNEL;
                
                when NEXT_CHANNEL =>
                    -- Move to next channel or continue if enabled
                    if current_ch_reg >= 4 then
                        current_ch_reg <= (others => '0');  -- Back to channel 0
                    else
                        current_ch_reg <= current_ch_reg + 1;  -- Next channel
                    end if;
                    
                    if enable = '1' then
                        state <= TRIGGER_UPDATE;  -- Continuous reading if enabled
                    else
                        state <= IDLE;
                    end if;
                
                when others =>
                    state <= IDLE;
            end case;
        end if;
    end process;
    
    -- Output assignments
    channel_0_value <= ch0_data_reg;
    channel_1_value <= ch1_data_reg;
    channel_2_value <= ch2_data_reg;
    channel_3_value <= ch3_data_reg;
    channel_4_value <= ch4_data_reg;
    
    data_valid <= data_valid_reg;
    current_channel <= std_logic_vector(current_ch_reg);
    reading_active <= reading_active_reg;
    
end architecture rtl;