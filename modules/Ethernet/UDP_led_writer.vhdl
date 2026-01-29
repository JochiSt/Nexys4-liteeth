LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.std_logic_unsigned.ALL;

--------------------------------------------------------------------------------
-- UDP to LED writer
-- receives UDP packets and writes data to on Board LEDs
--------------------------------------------------------------------------------
ENTITY UDP_led_writer IS
    PORT (
        -- system clock and reset
        clk   : IN STD_LOGIC;
        reset : IN STD_LOGIC;

        -- data from liteeth UDP core
        udp0_source_valid : IN STD_LOGIC;
        udp0_source_last  : IN STD_LOGIC;
        udp0_source_ready : OUT STD_LOGIC;
        udp0_source_data  : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
        udp0_source_error : IN STD_LOGIC;

        -- output to the LEDs
        leds : OUT STD_LOGIC_VECTOR(15 DOWNTO 0)
    );
END UDP_led_writer;

ARCHITECTURE arch OF UDP_led_writer IS
    TYPE UDP_state_t IS (STATE_WAIT_PACKET, STATE_READ_DATA);
    SIGNAL UDP_state : UDP_state_t := STATE_WAIT_PACKET;

    SIGNAL data : STD_LOGIC_VECTOR(15 DOWNTO 0);
BEGIN

    PROCESS (clk) BEGIN

        IF risign_edge(clk) THEN
            -- RESET
            IF (reset) THEN
                udp0_source_ready <= '0';
                UDP_state         <= STATE_WAIT_PACKET;
                data              <= (OTHERS => '0');
            ELSE
                -- handle data
                CASE UDP_state IS
                    WHEN STATE_WAIT_PACKET =>
                        udp0_source_ready <= '1'; -- signal ready to receive data
                        IF (udp0_source_valid = '1') THEN
                            IF (udp0_source_last = '0') THEN -- force at least 2 bytes
                                data(15 DOWNTO 8) <= udp0_source_data;
                                UDP_state         <= STATE_READ_DATA;
                            END IF;
                        END IF;

                    WHEN STATE_READ_DATA =>
                        IF (udp0_source_valid = '1') THEN
                            data(7 DOWNTO 0) <= udp0_source_data;
                            UDP_state        <= STATE_READ_DATA;
                        END IF;

                        IF (udp0_source_last = '1') THEN -- if only 2 bytes, last will be high here
                            udp0_source_ready <= '0';        -- stop receiving data
                            UDP_state         <= STATE_WAIT_PACKET;
                        END IF;
                END CASE;
            END IF;

            -- assign LEDs to output
            leds <= data;
        END IF;

    END PROCESS;

END ARCHITECTURE; -- arch
