LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;

ENTITY readEthernetPacket IS
    GENERIC (
        PORT_MSB   : NATURAL := 102;
        DATA_WIDTH : NATURAL := 16 -- WIDTH of the data to be handled
    );
    PORT (
        clk                   : IN STD_LOGIC;
        reset                 : IN STD_LOGIC;

        udp_source_valid      : IN STD_LOGIC;
        udp_source_last       : IN STD_LOGIC;
        udp_source_ready      : OUT STD_LOGIC;

        udp_source_src_port   : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
        udp_source_dst_port   : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
        udp_source_ip_address : IN STD_LOGIC_VECTOR(31 DOWNTO 0);

        udp_source_length     : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
        udp_source_data       : IN STD_LOGIC_VECTOR(DATA_WIDTH - 1 DOWNTO 0);

        udp_source_error      : IN STD_LOGIC;

        led                   : OUT STD_LOGIC_VECTOR(15 DOWNTO 0)
    );

END ENTITY;

ARCHITECTURE implementation OF readEthernetPacket IS
    TYPE UDP_STATE_T IS (STATE_WAIT_PACKET, STATE_READ_DATA);
    SIGNAL udp_state : UDP_STATE_T := STATE_WAIT_PACKET;

    SIGNAL leds      : STD_LOGIC_VECTOR(15 DOWNTO 0);
BEGIN

    -- PROCESS (clk)
    -- BEGIN
    --     IF rising_edge(clk) THEN
    --         IF reset = '1' THEN
    --             leds(1 DOWNTO 0) <= (OTHERS => '0');
    --             udp_source_ready <= '0';
    --             udp_state        <= STATE_WAIT_PACKET;
    --         ELSE
    --             CASE udp_state IS
    --                 WHEN STATE_WAIT_PACKET =>
    --                     udp_source_ready <= '1';
    --                     leds(1 DOWNTO 0) <= "01";
    --                     IF udp_source_valid = '1' THEN
    --                         IF udp_source_last = '0' THEN
    --                             udp_state <= STATE_READ_DATA;
    --                         END IF;
    --                     END IF;

    --                 WHEN STATE_READ_DATA =>
    --                     leds(1 DOWNTO 0) <= "10";
    --                     IF udp_source_valid = '1' THEN
    --                         IF udp_source_last = '1' THEN
    --                             udp_state <= STATE_WAIT_PACKET;
    --                         END IF;
    --                     END IF;
    --             END CASE;
    --         END IF;
    --     END IF;
    -- END PROCESS;

    udp_source_ready <= '1'; -- always ready

    PROCESS (clk) BEGIN
        IF rising_edge(clk) THEN
            IF reset = '1' THEN
                leds(15 DOWNTO 13) <= (OTHERS => '0');
            ELSE
                IF leds(15) = '0' THEN
                    leds(15) <= udp_source_valid;
                END IF;
                IF leds(14) = '0' THEN
                    leds(14) <= udp_source_last;
                END IF;
                IF leds(13) = '0' THEN
                    leds(13) <= udp_source_error;
                END IF;
            END IF;
        END IF;
    END PROCESS;

    leds(12 DOWNTO 0) <= udp_source_data(12 DOWNTO 0);

    led               <= leds;

END;
