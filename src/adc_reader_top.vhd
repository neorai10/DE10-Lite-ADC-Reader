library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity adc_reader_top is
    port (
        -- Clock inputs
        MAX10_CLK1_50   : in  std_logic;  -- 50MHz main clock
        
        -- Reset input  
        KEY             : in  std_logic_vector(1 downto 0);  -- KEY[0] is reset
        
        -- LEDs for status indication
        LEDR            : out std_logic_vector(9 downto 0);  -- Red LEDs
        
        -- Switches for control
        SW              : in  std_logic_vector(9 downto 0);  -- Switches
        
        -- Seven segment displays for voltage value
        HEX0            : out std_logic_vector(6 downto 0);
        HEX1            : out std_logic_vector(6 downto 0);
        HEX2            : out std_logic_vector(6 downto 0);
        HEX3            : out std_logic_vector(6 downto 0);
        HEX4            : out std_logic_vector(6 downto 0);
        HEX5            : out std_logic_vector(6 downto 0);
        
        -- UART output to ESP32
        Arduino_IO      : out std_logic_vector(1 downto 1)  -- Arduino_IO[1] for TX
    );
end entity adc_reader_top;

architecture rtl of adc_reader_top is
    
    -- Component declaration for QSYS-generated ADC
    component adc_reader is
        port (
            clk_clk                     : in  std_logic;
            reset_reset_n               : in  std_logic;
            adc_0_adc_slave_write       : in  std_logic;
            adc_0_adc_slave_readdata    : out std_logic_vector(31 downto 0);
            adc_0_adc_slave_writedata   : in  std_logic_vector(31 downto 0);
            adc_0_adc_slave_address     : in  std_logic_vector(2 downto 0);
            adc_0_adc_slave_waitrequest : out std_logic;
            adc_0_adc_slave_read        : in  std_logic
        );
    end component adc_reader;
    
    -- Clock and reset signals
    signal clk_50         : std_logic;
    signal reset_n        : std_logic;
    
    -- ADC interface signals
    signal adc_write      : std_logic;
    signal adc_read       : std_logic;
    signal adc_readdata   : std_logic_vector(31 downto 0);
    signal adc_writedata  : std_logic_vector(31 downto 0);
    signal adc_address    : std_logic_vector(2 downto 0);
    signal adc_waitrequest: std_logic;
    
    -- Timing controller signals
    signal sample_trigger : std_logic;
    signal seconds_count  : std_logic_vector(3 downto 0);  -- 4-bit for 10 seconds (0-9)
    signal timing_active  : std_logic;
    
    -- ADC Controller signals - 5 channels
    signal channel_0_value : std_logic_vector(11 downto 0);
    signal channel_1_value : std_logic_vector(11 downto 0);
    signal channel_2_value : std_logic_vector(11 downto 0);
    signal channel_3_value : std_logic_vector(11 downto 0);
    signal channel_4_value : std_logic_vector(11 downto 0);
    signal adc_data_valid  : std_logic;
    signal current_channel : std_logic_vector(2 downto 0);
    signal reading_active  : std_logic;
    
    -- Averaging unit signals - NEW
    signal avg_channel_0   : std_logic_vector(11 downto 0);
    signal avg_channel_1   : std_logic_vector(11 downto 0);
    signal avg_channel_2   : std_logic_vector(11 downto 0);
    signal avg_channel_3   : std_logic_vector(11 downto 0);
    signal avg_channel_4   : std_logic_vector(11 downto 0);
    signal averaging_active : std_logic;
    signal average_ready    : std_logic;
    
    -- Channel selector signals
    signal selected_channel   : std_logic_vector(2 downto 0);
    signal selected_adc_value : std_logic_vector(11 downto 0);
    
    -- Data processing signals
    signal voltage_display: std_logic_vector(15 downto 0);  -- Processed voltage for display
    
    -- Calculation unit signals
    signal calc_result      : std_logic_vector(4 downto 0);  -- 0-23 (24 options)
    signal calc_valid       : std_logic;
    
    -- Average outputs from calculation unit
    signal calc_avg_thumb   : std_logic_vector(11 downto 0);
    signal calc_avg_index   : std_logic_vector(11 downto 0);
    signal calc_avg_middle  : std_logic_vector(11 downto 0);
    signal calc_avg_ring    : std_logic_vector(11 downto 0);
    signal calc_avg_pinky   : std_logic_vector(11 downto 0);
    
    -- UART signals
    signal uart_sending     : std_logic;
    
    -- Display selection and mode
    signal display_value    : std_logic_vector(11 downto 0);
    signal display_mode     : std_logic;  -- '0' = voltage, '1' = number
    signal number_display   : std_logic_vector(15 downto 0);  -- For number display
    
begin
    
    -- Clock and reset assignment
    clk_50  <= MAX10_CLK1_50;
    reset_n <= KEY(0);  -- KEY[0] is active low reset
    
    -- Instantiate QSYS ADC component
    u_adc_reader : adc_reader
        port map (
            clk_clk                     => clk_50,
            reset_reset_n               => reset_n,
            adc_0_adc_slave_write       => adc_write,
            adc_0_adc_slave_readdata    => adc_readdata,
            adc_0_adc_slave_writedata   => adc_writedata,
            adc_0_adc_slave_address     => adc_address,
            adc_0_adc_slave_waitrequest => adc_waitrequest,
            adc_0_adc_slave_read        => adc_read
        );
    
    -- Instantiate timing controller (10 second intervals)
    u_timing_controller : entity work.timing_controller
        port map (
            clk           => clk_50,
            reset_n       => reset_n,
            enable        => SW(0),           -- SW[0] enables timing
            sample_trigger => sample_trigger,
            seconds_count => seconds_count,
            timing_active => timing_active
        );
    
    -- Instantiate ADC controller (5 channels)
    u_adc_controller : entity work.adc_controller
        port map (
            clk             => clk_50,
            reset_n         => reset_n,
            enable          => SW(0),         -- SW[0] enables ADC reading
            sample_trigger  => sample_trigger,
            
            -- ADC interface
            adc_write       => adc_write,
            adc_read        => adc_read,
            adc_readdata    => adc_readdata,
            adc_writedata   => adc_writedata,
            adc_address     => adc_address,
            adc_waitrequest => adc_waitrequest,
            
            -- 5 Channel outputs
            channel_0_value => channel_0_value,
            channel_1_value => channel_1_value,
            channel_2_value => channel_2_value,
            channel_3_value => channel_3_value,
            channel_4_value => channel_4_value,
            
            -- Control signals
            data_valid      => adc_data_valid,
            current_channel => current_channel,
            reading_active  => reading_active
        );
    
    -- Instantiate averaging unit (NEW)
    u_averaging_unit : entity work.averaging_unit
        port map (
            clk             => clk_50,
            reset_n         => reset_n,
            enable          => SW(0),           -- Same enable as timing and ADC
            sample_trigger  => sample_trigger,
            
            -- 5 channel inputs from ADC controller
            channel_0_value => channel_0_value,
            channel_1_value => channel_1_value,
            channel_2_value => channel_2_value,
            channel_3_value => channel_3_value,
            channel_4_value => channel_4_value,
            data_valid      => adc_data_valid,
            
            -- 5 separate averaged outputs
            avg_channel_0   => avg_channel_0,
            avg_channel_1   => avg_channel_1,
            avg_channel_2   => avg_channel_2,
            avg_channel_3   => avg_channel_3,
            avg_channel_4   => avg_channel_4,
            
            -- Status outputs
            averaging_active => averaging_active,
            average_ready    => average_ready
        );
    
    -- Instantiate channel selector (chooses which channel to display)
    u_channel_selector : entity work.channel_selector
        port map (
            clk             => clk_50,
            reset_n         => reset_n,
            
            -- Switch inputs for channel selection
            channel_select  => SW(5 downto 1),  -- SW[1] to SW[5] select channels 0-4
            
            -- 5 channel inputs - NOW FROM AVERAGES (CHANGED)
            channel_0_value => avg_channel_0,
            channel_1_value => avg_channel_1,
            channel_2_value => avg_channel_2,
            channel_3_value => avg_channel_3,
            channel_4_value => avg_channel_4,
            
            -- Outputs
            selected_channel => selected_channel,
            selected_value   => selected_adc_value
        );
    
    -- Instantiate calculation unit
    u_calculation_unit : entity work.calculation_unit
        port map (
            clk           => clk_50,
            reset_n       => reset_n,
            
            -- Averaged inputs
            avg_channel_0 => avg_channel_0,
            avg_channel_1 => avg_channel_1,
            avg_channel_2 => avg_channel_2,
            avg_channel_3 => avg_channel_3,
            avg_channel_4 => avg_channel_4,
            
            -- Control
            calculate     => average_ready,
            
            -- Result
            result        => calc_result,
            result_valid  => calc_valid,
            
            -- Average outputs
            avg_thumb_out  => calc_avg_thumb,
            avg_index_out  => calc_avg_index,
            avg_middle_out => calc_avg_middle,
            avg_ring_out   => calc_avg_ring,
            avg_pinky_out  => calc_avg_pinky
        );
    
    -- Instantiate extended number sender for UART (sends result + 5 averages)
    u_number_sender : entity work.number_sender_extended
        port map (
            clk          => clk_50,
            reset_n      => reset_n,
            result       => calc_result,
            avg_thumb    => calc_avg_thumb,
            avg_index    => calc_avg_index,
            avg_middle   => calc_avg_middle,
            avg_ring     => calc_avg_ring,
            avg_pinky    => calc_avg_pinky,
            send_trigger => calc_valid,
            sending      => uart_sending,
            uart_tx      => Arduino_IO(1)
        );
    
    -- Display selection logic
    -- SW[9] OFF = show voltage (default), SW[9] ON = show calculation result (0-23)
    display_mode <= SW(9);
    display_value <= selected_adc_value;  -- Always pass ADC value for voltage conversion
    
    -- Convert calc_result (0-23) to display format for number mode
    number_display <= std_logic_vector(resize(unsigned(calc_result), 16));  -- Simple resize to 16-bit
    
    -- Instantiate data handler for voltage conversion
    u_data_handler : entity work.data_handler
        port map (
            clk         => clk_50,
            reset_n     => reset_n,
            adc_value   => display_value,
            voltage_out => voltage_display
        );
    
    -- Instantiate seven segment display controller  
    u_display_controller : entity work.display_controller
        port map (
            clk         => clk_50,
            reset_n     => reset_n,
            voltage_in  => voltage_display,
            number_in   => number_display,
            display_mode => display_mode,  -- '0' = voltage, '1' = number
            hex0        => HEX0,
            hex1        => HEX1,
            hex2        => HEX2,
            hex3        => HEX3,
            hex4        => HEX4,
            hex5        => HEX5
        );
    
    -- Status LEDs assignment
    LEDR(0) <= adc_data_valid;                    -- New ADC data available
    LEDR(1) <= timing_active;                     -- Timing controller active (5-second timer)
    LEDR(2) <= reading_active;                    -- ADC reading active
    LEDR(5 downto 3) <= current_channel;          -- Current channel being read (0-4)
    LEDR(6) <= averaging_active;                  -- NEW: Averaging unit active
    LEDR(7) <= average_ready;                     -- NEW: New averages ready (pulse every 5 seconds)
    LEDR(8) <= uart_sending;                      -- UART transmission active
    LEDR(9) <= sample_trigger;                    -- 5-second trigger pulse (will blink)
    
end architecture rtl;