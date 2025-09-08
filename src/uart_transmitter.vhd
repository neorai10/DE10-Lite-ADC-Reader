library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity uart_transmitter is
    generic (
        CLK_FREQ  : integer := 50_000_000;  -- 50MHz clock
        BAUD_RATE : integer := 9600        -- 9600 baud
    );
    port (
        clk         : in  std_logic;
        reset_n     : in  std_logic;
        
        -- Data interface
        data_in     : in  std_logic_vector(7 downto 0);  -- Byte to send
        send        : in  std_logic;                      -- Pulse to start sending
        busy        : out std_logic;                      -- High when transmitting
        
        -- UART output
        tx          : out std_logic
    );
end entity uart_transmitter;

architecture rtl of uart_transmitter is
    
    -- Calculate bit period in clock cycles
    constant BIT_PERIOD : integer := CLK_FREQ / BAUD_RATE;
    
    -- State machine
    type tx_state_t is (IDLE, START_BIT, DATA_BITS, STOP_BIT);
    signal state : tx_state_t;
    
    -- Internal signals
    signal bit_counter : integer range 0 to 7;
    signal clk_counter : integer range 0 to BIT_PERIOD-1;
    signal data_reg    : std_logic_vector(7 downto 0);
    signal busy_reg    : std_logic;
    
begin

    process(clk, reset_n)
    begin
        if reset_n = '0' then
            state <= IDLE;
            tx <= '1';  -- UART idle is high
            bit_counter <= 0;
            clk_counter <= 0;
            data_reg <= (others => '0');
            busy_reg <= '0';
            
        elsif rising_edge(clk) then
            case state is
                when IDLE =>
                    tx <= '1';  -- Keep line high
                    busy_reg <= '0';
                    
                    if send = '1' then
                        data_reg <= data_in;  -- Capture data
                        state <= START_BIT;
                        clk_counter <= 0;
                        busy_reg <= '1';
                    end if;
                
                when START_BIT =>
                    tx <= '0';  -- Start bit is low
                    
                    if clk_counter >= BIT_PERIOD-1 then
                        clk_counter <= 0;
                        bit_counter <= 0;
                        state <= DATA_BITS;
                    else
                        clk_counter <= clk_counter + 1;
                    end if;
                
                when DATA_BITS =>
                    tx <= data_reg(bit_counter);  -- Send LSB first
                    
                    if clk_counter >= BIT_PERIOD-1 then
                        clk_counter <= 0;
                        
                        if bit_counter >= 7 then
                            state <= STOP_BIT;
                        else
                            bit_counter <= bit_counter + 1;
                        end if;
                    else
                        clk_counter <= clk_counter + 1;
                    end if;
                
                when STOP_BIT =>
                    tx <= '1';  -- Stop bit is high
                    
                    if clk_counter >= BIT_PERIOD-1 then
                        clk_counter <= 0;
                        state <= IDLE;
                    else
                        clk_counter <= clk_counter + 1;
                    end if;
                    
                when others =>
                    state <= IDLE;
            end case;
        end if;
    end process;
    
    -- Output assignment
    busy <= busy_reg;
    
end architecture rtl;