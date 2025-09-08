library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity number_sender_extended is
    port (
        clk           : in  std_logic;
        reset_n       : in  std_logic;
        
        -- Input interface - 6 values
        result        : in  std_logic_vector(4 downto 0);   -- 0-23 (5 bits)
        avg_thumb     : in  std_logic_vector(11 downto 0);  -- 12-bit ADC value
        avg_index     : in  std_logic_vector(11 downto 0);  -- 12-bit ADC value
        avg_middle    : in  std_logic_vector(11 downto 0);  -- 12-bit ADC value
        avg_ring      : in  std_logic_vector(11 downto 0);  -- 12-bit ADC value
        avg_pinky     : in  std_logic_vector(11 downto 0);  -- 12-bit ADC value
        send_trigger  : in  std_logic;                      -- Pulse to send all values
        
        -- Status
        sending       : out std_logic;                      -- High while sending
        
        -- UART output
        uart_tx       : out std_logic
    );
end entity number_sender_extended;

architecture rtl of number_sender_extended is
    
    -- States for sending sequence
    type send_state_t is (
        IDLE,
        -- Send result (0-23)
        SEND_RESULT_TENS, WAIT_RESULT_TENS, SEND_RESULT_ONES, WAIT_RESULT_ONES,
        SEND_COMMA1, WAIT_COMMA1,
        -- Send thumb
        SEND_THUMB_THOUSANDS, WAIT_THUMB_THOUSANDS,
        SEND_THUMB_HUNDREDS, WAIT_THUMB_HUNDREDS,
        SEND_THUMB_TENS, WAIT_THUMB_TENS,
        SEND_THUMB_ONES, WAIT_THUMB_ONES,
        SEND_COMMA2, WAIT_COMMA2,
        -- Send index
        SEND_INDEX_THOUSANDS, WAIT_INDEX_THOUSANDS,
        SEND_INDEX_HUNDREDS, WAIT_INDEX_HUNDREDS,
        SEND_INDEX_TENS, WAIT_INDEX_TENS,
        SEND_INDEX_ONES, WAIT_INDEX_ONES,
        SEND_COMMA3, WAIT_COMMA3,
        -- Send middle
        SEND_MIDDLE_THOUSANDS, WAIT_MIDDLE_THOUSANDS,
        SEND_MIDDLE_HUNDREDS, WAIT_MIDDLE_HUNDREDS,
        SEND_MIDDLE_TENS, WAIT_MIDDLE_TENS,
        SEND_MIDDLE_ONES, WAIT_MIDDLE_ONES,
        SEND_COMMA4, WAIT_COMMA4,
        -- Send ring
        SEND_RING_THOUSANDS, WAIT_RING_THOUSANDS,
        SEND_RING_HUNDREDS, WAIT_RING_HUNDREDS,
        SEND_RING_TENS, WAIT_RING_TENS,
        SEND_RING_ONES, WAIT_RING_ONES,
        SEND_COMMA5, WAIT_COMMA5,
        -- Send pinky
        SEND_PINKY_THOUSANDS, WAIT_PINKY_THOUSANDS,
        SEND_PINKY_HUNDREDS, WAIT_PINKY_HUNDREDS,
        SEND_PINKY_TENS, WAIT_PINKY_TENS,
        SEND_PINKY_ONES, WAIT_PINKY_ONES,
        -- End of line
        SEND_CR, WAIT_CR, SEND_LF, WAIT_LF
    );
    signal state : send_state_t;
    
    -- UART signals
    signal uart_data    : std_logic_vector(7 downto 0);
    signal uart_send    : std_logic;
    signal uart_busy    : std_logic;
    
    -- Internal signals
    signal result_reg     : unsigned(4 downto 0);
    signal thumb_reg      : unsigned(11 downto 0);
    signal index_reg      : unsigned(11 downto 0);
    signal middle_reg     : unsigned(11 downto 0);
    signal ring_reg       : unsigned(11 downto 0);
    signal pinky_reg      : unsigned(11 downto 0);
    signal sending_reg    : std_logic;
    
    -- ASCII constants
    constant ASCII_0     : std_logic_vector(7 downto 0) := x"30";  -- '0'
    constant ASCII_COMMA : std_logic_vector(7 downto 0) := x"2C";  -- ','
    constant ASCII_CR    : std_logic_vector(7 downto 0) := x"0D";  -- '\r'
    constant ASCII_LF    : std_logic_vector(7 downto 0) := x"0A";  -- '\n'
    
    -- Function to extract decimal digit from a 12-bit number
    function get_digit(value : unsigned(11 downto 0); position : integer) return unsigned is
        variable temp : unsigned(11 downto 0);
    begin
        case position is
            when 3 => -- Thousands
                return resize(value / 1000, 4);
            when 2 => -- Hundreds
                temp := value mod 1000;
                return resize(temp / 100, 4);
            when 1 => -- Tens
                temp := value mod 100;
                return resize(temp / 10, 4);
            when 0 => -- Ones
                return resize(value mod 10, 4);
            when others =>
                return "0000";
        end case;
    end function;
    
    -- Function to get result digit (0-23)
    function get_result_digit(value : unsigned(4 downto 0); position : integer) return unsigned is
    begin
        if position = 1 then  -- Tens
            if value >= 20 then
                return to_unsigned(2, 4);
            elsif value >= 10 then
                return to_unsigned(1, 4);
            else
                return to_unsigned(0, 4);
            end if;
        else  -- Ones
            return resize(value mod 10, 4);
        end if;
    end function;
    
begin

    -- Instantiate UART transmitter
    u_uart_tx : entity work.uart_transmitter
        generic map (
            CLK_FREQ  => 50_000_000,
            BAUD_RATE => 9600
        )
        port map (
            clk      => clk,
            reset_n  => reset_n,
            data_in  => uart_data,
            send     => uart_send,
            busy     => uart_busy,
            tx       => uart_tx
        );

    -- Main state machine
    process(clk, reset_n)
    begin
        if reset_n = '0' then
            state <= IDLE;
            uart_data <= (others => '0');
            uart_send <= '0';
            result_reg <= (others => '0');
            thumb_reg <= (others => '0');
            index_reg <= (others => '0');
            middle_reg <= (others => '0');
            ring_reg <= (others => '0');
            pinky_reg <= (others => '0');
            sending_reg <= '0';
            
        elsif rising_edge(clk) then
            -- Default values
            uart_send <= '0';
            
            case state is
                when IDLE =>
                    sending_reg <= '0';
                    if send_trigger = '1' then
                        -- Capture all values
                        result_reg <= unsigned(result);
                        thumb_reg <= unsigned(avg_thumb);
                        index_reg <= unsigned(avg_index);
                        middle_reg <= unsigned(avg_middle);
                        ring_reg <= unsigned(avg_ring);
                        pinky_reg <= unsigned(avg_pinky);
                        state <= SEND_RESULT_TENS;
                        sending_reg <= '1';
                    end if;
                
                -- Send result (0-23)
                when SEND_RESULT_TENS =>
                    uart_data <= std_logic_vector(unsigned(ASCII_0) + get_result_digit(result_reg, 1));
                    uart_send <= '1';
                    state <= WAIT_RESULT_TENS;
                
                when WAIT_RESULT_TENS =>
                    if uart_busy = '0' and uart_send = '0' then
                        state <= SEND_RESULT_ONES;
                    end if;
                
                when SEND_RESULT_ONES =>
                    uart_data <= std_logic_vector(unsigned(ASCII_0) + get_result_digit(result_reg, 0));
                    uart_send <= '1';
                    state <= WAIT_RESULT_ONES;
                
                when WAIT_RESULT_ONES =>
                    if uart_busy = '0' and uart_send = '0' then
                        state <= SEND_COMMA1;
                    end if;
                
                when SEND_COMMA1 =>
                    uart_data <= ASCII_COMMA;
                    uart_send <= '1';
                    state <= WAIT_COMMA1;
                
                when WAIT_COMMA1 =>
                    if uart_busy = '0' and uart_send = '0' then
                        state <= SEND_THUMB_THOUSANDS;
                    end if;
                
                -- Send thumb (4 digits)
                when SEND_THUMB_THOUSANDS =>
                    uart_data <= std_logic_vector(unsigned(ASCII_0) + get_digit(thumb_reg, 3));
                    uart_send <= '1';
                    state <= WAIT_THUMB_THOUSANDS;
                
                when WAIT_THUMB_THOUSANDS =>
                    if uart_busy = '0' and uart_send = '0' then
                        state <= SEND_THUMB_HUNDREDS;
                    end if;
                
                when SEND_THUMB_HUNDREDS =>
                    uart_data <= std_logic_vector(unsigned(ASCII_0) + get_digit(thumb_reg, 2));
                    uart_send <= '1';
                    state <= WAIT_THUMB_HUNDREDS;
                
                when WAIT_THUMB_HUNDREDS =>
                    if uart_busy = '0' and uart_send = '0' then
                        state <= SEND_THUMB_TENS;
                    end if;
                
                when SEND_THUMB_TENS =>
                    uart_data <= std_logic_vector(unsigned(ASCII_0) + get_digit(thumb_reg, 1));
                    uart_send <= '1';
                    state <= WAIT_THUMB_TENS;
                
                when WAIT_THUMB_TENS =>
                    if uart_busy = '0' and uart_send = '0' then
                        state <= SEND_THUMB_ONES;
                    end if;
                
                when SEND_THUMB_ONES =>
                    uart_data <= std_logic_vector(unsigned(ASCII_0) + get_digit(thumb_reg, 0));
                    uart_send <= '1';
                    state <= WAIT_THUMB_ONES;
                
                when WAIT_THUMB_ONES =>
                    if uart_busy = '0' and uart_send = '0' then
                        state <= SEND_COMMA2;
                    end if;
                
                when SEND_COMMA2 =>
                    uart_data <= ASCII_COMMA;
                    uart_send <= '1';
                    state <= WAIT_COMMA2;
                
                when WAIT_COMMA2 =>
                    if uart_busy = '0' and uart_send = '0' then
                        state <= SEND_INDEX_THOUSANDS;
                    end if;
                
                -- Send index (4 digits)
                when SEND_INDEX_THOUSANDS =>
                    uart_data <= std_logic_vector(unsigned(ASCII_0) + get_digit(index_reg, 3));
                    uart_send <= '1';
                    state <= WAIT_INDEX_THOUSANDS;
                
                when WAIT_INDEX_THOUSANDS =>
                    if uart_busy = '0' and uart_send = '0' then
                        state <= SEND_INDEX_HUNDREDS;
                    end if;
                
                when SEND_INDEX_HUNDREDS =>
                    uart_data <= std_logic_vector(unsigned(ASCII_0) + get_digit(index_reg, 2));
                    uart_send <= '1';
                    state <= WAIT_INDEX_HUNDREDS;
                
                when WAIT_INDEX_HUNDREDS =>
                    if uart_busy = '0' and uart_send = '0' then
                        state <= SEND_INDEX_TENS;
                    end if;
                
                when SEND_INDEX_TENS =>
                    uart_data <= std_logic_vector(unsigned(ASCII_0) + get_digit(index_reg, 1));
                    uart_send <= '1';
                    state <= WAIT_INDEX_TENS;
                
                when WAIT_INDEX_TENS =>
                    if uart_busy = '0' and uart_send = '0' then
                        state <= SEND_INDEX_ONES;
                    end if;
                
                when SEND_INDEX_ONES =>
                    uart_data <= std_logic_vector(unsigned(ASCII_0) + get_digit(index_reg, 0));
                    uart_send <= '1';
                    state <= WAIT_INDEX_ONES;
                
                when WAIT_INDEX_ONES =>
                    if uart_busy = '0' and uart_send = '0' then
                        state <= SEND_COMMA3;
                    end if;
                
                when SEND_COMMA3 =>
                    uart_data <= ASCII_COMMA;
                    uart_send <= '1';
                    state <= WAIT_COMMA3;
                
                when WAIT_COMMA3 =>
                    if uart_busy = '0' and uart_send = '0' then
                        state <= SEND_MIDDLE_THOUSANDS;
                    end if;
                
                -- Send middle (4 digits)
                when SEND_MIDDLE_THOUSANDS =>
                    uart_data <= std_logic_vector(unsigned(ASCII_0) + get_digit(middle_reg, 3));
                    uart_send <= '1';
                    state <= WAIT_MIDDLE_THOUSANDS;
                
                when WAIT_MIDDLE_THOUSANDS =>
                    if uart_busy = '0' and uart_send = '0' then
                        state <= SEND_MIDDLE_HUNDREDS;
                    end if;
                
                when SEND_MIDDLE_HUNDREDS =>
                    uart_data <= std_logic_vector(unsigned(ASCII_0) + get_digit(middle_reg, 2));
                    uart_send <= '1';
                    state <= WAIT_MIDDLE_HUNDREDS;
                
                when WAIT_MIDDLE_HUNDREDS =>
                    if uart_busy = '0' and uart_send = '0' then
                        state <= SEND_MIDDLE_TENS;
                    end if;
                
                when SEND_MIDDLE_TENS =>
                    uart_data <= std_logic_vector(unsigned(ASCII_0) + get_digit(middle_reg, 1));
                    uart_send <= '1';
                    state <= WAIT_MIDDLE_TENS;
                
                when WAIT_MIDDLE_TENS =>
                    if uart_busy = '0' and uart_send = '0' then
                        state <= SEND_MIDDLE_ONES;
                    end if;
                
                when SEND_MIDDLE_ONES =>
                    uart_data <= std_logic_vector(unsigned(ASCII_0) + get_digit(middle_reg, 0));
                    uart_send <= '1';
                    state <= WAIT_MIDDLE_ONES;
                
                when WAIT_MIDDLE_ONES =>
                    if uart_busy = '0' and uart_send = '0' then
                        state <= SEND_COMMA4;
                    end if;
                
                when SEND_COMMA4 =>
                    uart_data <= ASCII_COMMA;
                    uart_send <= '1';
                    state <= WAIT_COMMA4;
                
                when WAIT_COMMA4 =>
                    if uart_busy = '0' and uart_send = '0' then
                        state <= SEND_RING_THOUSANDS;
                    end if;
                
                -- Send ring (4 digits)
                when SEND_RING_THOUSANDS =>
                    uart_data <= std_logic_vector(unsigned(ASCII_0) + get_digit(ring_reg, 3));
                    uart_send <= '1';
                    state <= WAIT_RING_THOUSANDS;
                
                when WAIT_RING_THOUSANDS =>
                    if uart_busy = '0' and uart_send = '0' then
                        state <= SEND_RING_HUNDREDS;
                    end if;
                
                when SEND_RING_HUNDREDS =>
                    uart_data <= std_logic_vector(unsigned(ASCII_0) + get_digit(ring_reg, 2));
                    uart_send <= '1';
                    state <= WAIT_RING_HUNDREDS;
                
                when WAIT_RING_HUNDREDS =>
                    if uart_busy = '0' and uart_send = '0' then
                        state <= SEND_RING_TENS;
                    end if;
                
                when SEND_RING_TENS =>
                    uart_data <= std_logic_vector(unsigned(ASCII_0) + get_digit(ring_reg, 1));
                    uart_send <= '1';
                    state <= WAIT_RING_TENS;
                
                when WAIT_RING_TENS =>
                    if uart_busy = '0' and uart_send = '0' then
                        state <= SEND_RING_ONES;
                    end if;
                
                when SEND_RING_ONES =>
                    uart_data <= std_logic_vector(unsigned(ASCII_0) + get_digit(ring_reg, 0));
                    uart_send <= '1';
                    state <= WAIT_RING_ONES;
                
                when WAIT_RING_ONES =>
                    if uart_busy = '0' and uart_send = '0' then
                        state <= SEND_COMMA5;
                    end if;
                
                when SEND_COMMA5 =>
                    uart_data <= ASCII_COMMA;
                    uart_send <= '1';
                    state <= WAIT_COMMA5;
                
                when WAIT_COMMA5 =>
                    if uart_busy = '0' and uart_send = '0' then
                        state <= SEND_PINKY_THOUSANDS;
                    end if;
                
                -- Send pinky (4 digits)
                when SEND_PINKY_THOUSANDS =>
                    uart_data <= std_logic_vector(unsigned(ASCII_0) + get_digit(pinky_reg, 3));
                    uart_send <= '1';
                    state <= WAIT_PINKY_THOUSANDS;
                
                when WAIT_PINKY_THOUSANDS =>
                    if uart_busy = '0' and uart_send = '0' then
                        state <= SEND_PINKY_HUNDREDS;
                    end if;
                
                when SEND_PINKY_HUNDREDS =>
                    uart_data <= std_logic_vector(unsigned(ASCII_0) + get_digit(pinky_reg, 2));
                    uart_send <= '1';
                    state <= WAIT_PINKY_HUNDREDS;
                
                when WAIT_PINKY_HUNDREDS =>
                    if uart_busy = '0' and uart_send = '0' then
                        state <= SEND_PINKY_TENS;
                    end if;
                
                when SEND_PINKY_TENS =>
                    uart_data <= std_logic_vector(unsigned(ASCII_0) + get_digit(pinky_reg, 1));
                    uart_send <= '1';
                    state <= WAIT_PINKY_TENS;
                
                when WAIT_PINKY_TENS =>
                    if uart_busy = '0' and uart_send = '0' then
                        state <= SEND_PINKY_ONES;
                    end if;
                
                when SEND_PINKY_ONES =>
                    uart_data <= std_logic_vector(unsigned(ASCII_0) + get_digit(pinky_reg, 0));
                    uart_send <= '1';
                    state <= WAIT_PINKY_ONES;
                
                when WAIT_PINKY_ONES =>
                    if uart_busy = '0' and uart_send = '0' then
                        state <= SEND_CR;
                    end if;
                
                -- End of line
                when SEND_CR =>
                    uart_data <= ASCII_CR;
                    uart_send <= '1';
                    state <= WAIT_CR;
                
                when WAIT_CR =>
                    if uart_busy = '0' and uart_send = '0' then
                        state <= SEND_LF;
                    end if;
                
                when SEND_LF =>
                    uart_data <= ASCII_LF;
                    uart_send <= '1';
                    state <= WAIT_LF;
                
                when WAIT_LF =>
                    if uart_busy = '0' and uart_send = '0' then
                        state <= IDLE;
                        sending_reg <= '0';
                    end if;
                
                when others =>
                    state <= IDLE;
            end case;
        end if;
    end process;
    
    -- Output
    sending <= sending_reg;
    
end architecture rtl;