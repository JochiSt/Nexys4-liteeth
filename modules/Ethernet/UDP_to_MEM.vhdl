LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.std_logic_unsigned.ALL;

--------------------------------------------------------------------------------
-- UDP to LED writer
-- receives UDP packets and writes data to on Board LEDs
--------------------------------------------------------------------------------
ENTITY UDP_to_MEM IS
    GENERIC (
        NUM_ELEMENTS : INTEGER := 16 -- number of elements in the memory
    );
    PORT (
        -- system clock and reset
        clk     : IN STD_LOGIC;
        reset_n : IN STD_LOGIC;

        -- data from liteeth UDP core
        udp_source_valid : IN STD_LOGIC;
        udp_source_last  : IN STD_LOGIC;
        udp_source_ready : OUT STD_LOGIC;
        udp_source_data  : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
        udp_source_error : IN STD_LOGIC;

        address : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
        data    : OUT STD_LOGIC_VECTOR(7 DOWNTO 0)
    );
END UDP_to_MEM;

ARCHITECTURE arch OF UDP_to_MEM IS
    TYPE UDP_state_t IS (STATE_WAIT_PACKET, STATE_READ_DATA);
    SIGNAL UDP_state : UDP_state_t := STATE_WAIT_PACKET;

    TYPE memory_t IS ARRAY(NATURAL RANGE <>) OF STD_LOGIC_VECTOR(7 DOWNTO 0);
    SIGNAL memory : memory_t(NUM_ELEMENTS - 1 DOWNTO 0) := (OTHERS => (OTHERS => '0'));

    SIGNAL addr_counter : INTEGER RANGE 0 TO NUM_ELEMENTS - 1 := 0;
BEGIN

    PROCESS BEGIN
        WAIT UNTIL rising_edge(clk);

        -- RESET
        IF (reset_n = '0') THEN
            udp_source_ready <= '0';
            UDP_state        <= STATE_WAIT_PACKET;
            memory           <= (OTHERS => (OTHERS => '0'));
            addr_counter     <= 0;
        ELSE
            -- handle data
            CASE UDP_state IS
                WHEN STATE_WAIT_PACKET =>
                    udp_source_ready <= '1'; -- signal ready to receive data
                    IF (udp_source_valid = '1') THEN
                        IF (udp_source_last = '0') THEN -- force at least 2 bytes
                            memory(addr_counter) <= udp_source_data;
                            addr_counter         <= addr_counter + 1;
                            UDP_state            <= STATE_READ_DATA;
                        END IF;
                    END IF;

                WHEN STATE_READ_DATA =>
                    IF (udp_source_valid = '1') THEN
                        memory(addr_counter) <= udp_source_data;
                        addr_counter         <= addr_counter + 1;
                        UDP_state            <= STATE_READ_DATA;
                    END IF;

                    IF (udp_source_last = '1') THEN -- if only 2 bytes, last will be high here
                        udp_source_ready <= '0';        -- stop receiving data
                        addr_counter     <= 0;
                        UDP_state        <= STATE_WAIT_PACKET;
                    END IF;
            END CASE;
        END IF;

        -- output data from memory
        data <= memory(CONV_INTEGER(address) MOD NUM_ELEMENTS);

    END PROCESS;

END ARCHITECTURE; -- arch
