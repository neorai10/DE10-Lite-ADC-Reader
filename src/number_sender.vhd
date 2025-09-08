library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity number_sender is
    port (
        clk         : in  std_logic;
        reset_n     : in  std_logic;
        
        -- Input interface
        number      : in  std_logic_vector(4 downto 0);  -- 0-23 (5 bits)
        send_trigger: in  std_logic;                      -- Pulse to send number
        
        -- Status
        sending     : out std_logic;                      -- High while sending
        
        -- UART output
        uart_tx     : out std_logic
    );
end entity number_sender;

architecture rtl of number_sender is
    
    -- States for sending sequence
    type send_state_t is (IDLE, SEND_TENS, WAIT_TENS, SEND_ONES, WAIT_ONES, 
                         SEND_CR, WAIT_CR, SEND_LF, WAIT_LF);
    signal state : send_state_t;
    
    -- UART signals
    signal uart_data    : std_logic_vector(7 downto 0);
    signal uart_send    : std_logic;
    signal uart_busy    : std_logic;
    
    -- Internal signals
    signal number_reg   : unsigned(4 downto 0);
    signal tens_digit   : unsigned(3 downto 0);
    signal ones_digit   : unsigned(3 downto 0);
    signal sending_reg  : std_logic;
    
    -- ASCII constants
    constant ASCII_0  : std_logic_vector(7 downto 0) := x"30";  -- '0'
    constant ASCII_CR : std_logic_vector(7 downto 0) := x"0D";  -- '\r'
    constant ASCII_LF : std_logic_vector(7 downto 0) := x"0A";  -- '\n'
    
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

    -- Convert number to two digits (tens and ones) - UPDATED FOR 0-23
    process(number_reg)
        variable temp : unsigned(4 downto 0);
    begin
        temp := number_reg;
        
        -- Enhanced division by 10 for range 0-23
        if temp >= 20 then
            tens_digit <= to_unsigned(2, 4);
            ones_digit <= resize(temp - 20, 4);
        elsif temp >= 10 then
            tens_digit <= to_unsigned(1, 4);
            ones_digit <= resize(temp - 10, 4);
        else
            tens_digit <= to_unsigned(0, 4);
            ones_digit <= resize(temp, 4);
        end if;
    end process;

    -- Main state machine
    process(clk, reset_n)
    begin
        if reset_n = '0' then
            state <= IDLE;
            uart_data <= (others => '0');
            uart_send <= '0';
            number_reg <= (others => '0');
            sending_reg <= '0';
            
        elsif rising_edge(clk) then
            -- Default values - CRITICAL!
            uart_send <= '0';
            
            case state is
                when IDLE =>
                    sending_reg <= '0';
                    if send_trigger = '1' then
                        number_reg <= unsigned(number);
                        state <= SEND_TENS;
                        sending_reg <= '1';
                    end if;
                
                when SEND_TENS =>
                    -- Send tens digit as ASCII
                    uart_data <= std_logic_vector(unsigned(ASCII_0) + tens_digit);
                    uart_send <= '1';
                    state <= WAIT_TENS;
                
                when WAIT_TENS =>
                    -- Wait for UART to finish, then continue
                    if uart_busy = '0' and uart_send = '0' then  -- FIXED: Added uart_send check
                        state <= SEND_ONES;
                    end if;
                
                when SEND_ONES =>
                    -- Send ones digit as ASCII
                    uart_data <= std_logic_vector(unsigned(ASCII_0) + ones_digit);
                    uart_send <= '1';
                    state <= WAIT_ONES;
                
                when WAIT_ONES =>
                    -- Wait for UART to finish, then continue
                    if uart_busy = '0' and uart_send = '0' then  -- FIXED: Added uart_send check
                        state <= SEND_CR;
                    end if;
                
                when SEND_CR =>
                    -- Send carriage return
                    uart_data <= ASCII_CR;
                    uart_send <= '1';
                    state <= WAIT_CR;
                
                when WAIT_CR =>
                    -- Wait for UART to finish, then continue
                    if uart_busy = '0' and uart_send = '0' then  -- FIXED: Added uart_send check
                        state <= SEND_LF;
                    end if;
                
                when SEND_LF =>
                    -- Send line feed
                    uart_data <= ASCII_LF;
                    uart_send <= '1';
                    state <= WAIT_LF;
                
                when WAIT_LF =>
                    -- Wait for UART to finish, then go back to IDLE
                    if uart_busy = '0' and uart_send = '0' then  -- FIXED: Added uart_send check
                        state <= IDLE;  -- FIXED: Go directly to IDLE, not DONE
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