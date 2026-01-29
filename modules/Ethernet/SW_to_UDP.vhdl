LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

-- AXI master
-- "heavily" inspired from
-- https://www.kampis-elektroecke.de/2020/04/axi-stream-interface/

ENTITY SW_to_UDP IS
    GENERIC (
        LENGTH : INTEGER := 5 -- length of UDP packet to send
    );
    PORT (
        clk    : IN STD_LOGIC; -- global clock
        reset_n : IN STD_LOGIC; -- reset signal belonging to ACLK

        switches : IN STD_LOGIC_VECTOR (15 DOWNTO 0);

        Trigger : IN STD_LOGIC;

        TDATA_TXD  : OUT STD_LOGIC_VECTOR(7 DOWNTO 0); -- data, which is transmitted
        TREADY_TXD : IN STD_LOGIC;                     -- is slave ready for new data
        TVALID_TXD : OUT STD_LOGIC;                    -- master signaling valid data
        TLAST_TXD  : OUT STD_LOGIC                     -- last data of packet
    );
END SW_to_UDP;

ARCHITECTURE behavioral OF SW_to_UDP IS

    TYPE State_t IS (Reset, WaitForTriggerHigh, WaitForTriggerLow, WaitForReady, WaitForSlave);
    SIGNAL NextState : State_t := Reset;

    SIGNAL Counter : INTEGER := 0;

BEGIN

    PROCESS
    BEGIN
        WAIT UNTIL rising_edge(clk);

        IF (reset_n = '0') THEN
            NextState <= Reset;
        ELSE
            CASE NextState IS
                WHEN Reset =>
                    Counter    <= 0;
                    TDATA_TXD  <= (OTHERS => '0');
                    TVALID_TXD <= '0';
                    TLAST_TXD  <= '0';
                    NextState  <= WaitForTriggerHigh;

                WHEN WaitForTriggerHigh =>
                    IF (Trigger = '1') THEN
                        NextState <= WaitForTriggerLow;
                    ELSE
                        NextState <= WaitForTriggerHigh;
                    END IF;

                WHEN WaitForTriggerLow =>
                    IF (Trigger = '0') THEN
                        NextState <= WaitForReady;
                    ELSE
                        NextState <= WaitForTriggerLow;
                    END IF;

                WHEN WaitForReady =>
                    TDATA_TXD  <= STD_LOGIC_VECTOR(to_unsigned(Counter, 8));
                    TVALID_TXD <= '1';

                    IF (Counter < (LENGTH - 1)) THEN
                        TLAST_TXD <= '0';
                    ELSE
                        TLAST_TXD <= '1';
                    END IF;

                    NextState <= WaitForSlave;

                WHEN WaitForSlave =>
                    IF (TREADY_TXD = '1') THEN
                        TVALID_TXD <= '0';
                        TLAST_TXD  <= '0';

                        IF (Counter < (LENGTH - 1)) THEN
                            Counter   <= Counter + 1;
                            NextState <= WaitForReady;
                        ELSE
                            Counter   <= 0;
                            NextState <= WaitForTriggerHigh;
                        END IF;
                    ELSE
                        NextState <= WaitForSlave;
                    END IF;
            END CASE;
        END IF;
    END PROCESS;
END behavioral;
