----------------------------------------------------------------------------------
-- Company: The Hong Kong Polytechnic University
-- Engineer: Alexandr Melnikov
--
-- Create Date:    16:19:30 02/20/2017
-- Design Name:
-- Module Name:    ethernet_transceiver - Behavioral
-- Project Name:
-- Target Devices:
-- Tool versions:
-- Description:
--
-- Dependencies:
--
-- Revision:
-- Revision 0.01 - File Created

-- UDP echo-server design uses on-board Ethernet port to create a data-link between FPGA board
-- Nexys 4 DDR and MatLAB. Echo-server is capable of reception and transmission data packets
-- using ARP and UDP protocols.
-- MAC address of FPGA board: 00:18:3e:01:ff:71
-- IP4 address of FPGA board: 192.168.1.10
-- Port number used in the design: 58210
-- The echo server will reply back to any data server, which uses correct IP4 address and Port number.
-- MAC address of the board is made discoverable for the data server via ARP protocol
-- This Echo-server design doesn't use any input or output FIFO's as elesticity buffers,
-- both in- and outgoing data packets are parsed/assembled in parallel with Rx/Tx processes,
-- which allows better resource utilisation at the price of more complex design architecture.

-- Additional Comments:
-- Transceiver block is the Top-level block of the Ethernet transceiver design, implementing
-- the VHDL UDP echo-server.
-- Transceiver block itself handles the Power-On Reset operation along with subsequent Hardware Resets
-- on request from the user.
-- Apart from that it incorporates lower-level modules handling different functions required for the echo-server
-- operations: Receiver, Transmitter, Serial Management Interface, Memory and Clock Modules
----------------------------------------------------------------------------------
LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
USE IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
LIBRARY UNISIM;
USE UNISIM.VComponents.ALL;

ENTITY EthernetTest IS
    GENERIC (
        RESET_RELEASE_CNT : INTEGER := 10000 -- count how many clock cycles the reset should be low after startup

    );
    PORT (
        CLK100MHZ   : IN STD_LOGIC;

        PhyRxd      : INOUT STD_LOGIC_VECTOR (1 DOWNTO 0);
        PhyTxd      : INOUT STD_LOGIC_VECTOR (1 DOWNTO 0);
        PhyCrs      : INOUT STD_LOGIC;
        PhyTxEn     : INOUT STD_LOGIC;
        PhyRxErr    : INOUT STD_LOGIC;
        PhyMdc      : OUT STD_LOGIC;
        PhyMdio     : INOUT STD_LOGIC;
        PhyClk50Mhz : OUT STD_LOGIC;
        PhyRstn     : OUT STD_LOGIC;

        -- display signals for ARP and UDP packets
        RGB1_Blue   : OUT STD_LOGIC;
        RGB1_Green  : OUT STD_LOGIC;
        RGB1_Red    : OUT STD_LOGIC;

        RGB2_Blue   : OUT STD_LOGIC;
        RGB2_Green  : OUT STD_LOGIC;
        RGB2_Red    : OUT STD_LOGIC;

        -- Reset and SMI inputs/outputs
        btnCpuReset : IN STD_LOGIC;
        LED         : OUT STD_LOGIC_VECTOR (15 DOWNTO 0);
        sw          : IN STD_LOGIC_VECTOR (15 DOWNTO 0)
    );
END EthernetTest;

ARCHITECTURE Behavioral OF EthernetTest IS
    ----------------------------------------------------------------------------
    -- CLOCKS
    ----------------------------------------------------------------------------
    SIGNAL CLK50MHZ               : STD_LOGIC                                := '0';

    ----------------------------------------------------------------------------
    -- RESET
    ----------------------------------------------------------------------------
    SIGNAL reset_cnt              : INTEGER RANGE 0 TO RESET_RELEASE_CNT + 1 := 0; -- counter for releasing the reset signal
    SIGNAL sys_reset              : STD_LOGIC                                := '1';

    ----------------------------------------------------------------------------
    -- SIGNALS
    ----------------------------------------------------------------------------
    SIGNAL streamer1_ip_address   : STD_LOGIC_VECTOR(31 DOWNTO 0)            := (OTHERS => '0');
    SIGNAL streamer1_sink_data    : STD_LOGIC_VECTOR(31 DOWNTO 0)            := (OTHERS => '0');
    SIGNAL streamer1_sink_last    : STD_LOGIC                                := '0';
    SIGNAL streamer1_sink_ready   : STD_LOGIC                                := '0';
    SIGNAL streamer1_sink_valid   : STD_LOGIC                                := '0';

    SIGNAL streamer1_source_data  : STD_LOGIC_VECTOR(31 DOWNTO 0)            := (OTHERS => '0');
    SIGNAL streamer1_source_error : STD_LOGIC                                := '0';
    SIGNAL streamer1_source_last  : STD_LOGIC                                := '0';
    SIGNAL streamer1_source_ready : STD_LOGIC                                := '0';
    SIGNAL streamer1_source_valid : STD_LOGIC                                := '0';

    CONSTANT streamer1_udp_port   : STD_LOGIC_VECTOR(15 DOWNTO 0)            := x"00FF";

    CONSTANT fpga_mac             : STD_LOGIC_VECTOR (47 DOWNTO 0)           := x"00183e01ff71"; -- FPGA's MAC address
    CONSTANT fpga_ip              : STD_LOGIC_VECTOR (31 DOWNTO 0)           := x"C0A8010C";     -- FPGA's IP4 address 192.168.1.12
    ----------------------------------------------------------------------------
    -- liteeth core
    ----------------------------------------------------------------------------
    COMPONENT liteeth_core IS
        PORT (
            ip_address             : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
            mac_address            : IN STD_LOGIC_VECTOR(47 DOWNTO 0);

            rmii_clocks_ref_clk    : IN STD_LOGIC;
            rmii_crs_dv            : IN STD_LOGIC;
            rmii_mdc               : OUT STD_LOGIC;
            rmii_mdio              : INOUT STD_LOGIC;
            rmii_rst_n             : OUT STD_LOGIC;
            rmii_rx_data           : IN STD_LOGIC_VECTOR(1 DOWNTO 0);
            rmii_tx_data           : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
            rmii_tx_en             : OUT STD_LOGIC;
            streamer1_ip_address   : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
            streamer1_sink_data    : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
            streamer1_sink_last    : IN STD_LOGIC;
            streamer1_sink_ready   : OUT STD_LOGIC;
            streamer1_sink_valid   : IN STD_LOGIC;
            streamer1_source_data  : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
            streamer1_source_error : OUT STD_LOGIC;
            streamer1_source_last  : OUT STD_LOGIC;
            streamer1_source_ready : IN STD_LOGIC;
            streamer1_source_valid : OUT STD_LOGIC;
            streamer1_udp_port     : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
            sys_clock              : IN STD_LOGIC;
            sys_reset              : IN STD_LOGIC
        );
    END COMPONENT;
    ----------------------------------------------------------------------------

BEGIN

    liteeth_core_0 : liteeth_core
    PORT MAP(
        -- reference clock of the PHY
        rmii_clocks_ref_clk    => CLK50MHZ,

        -- RMII interface to the PHY
        rmii_crs_dv            => PhyCrs,
        rmii_mdc               => PhyMdc,
        rmii_mdio              => PhyMdio,
        rmii_rst_n             => PhyRstn,
        rmii_rx_data           => PhyRxd,
        rmii_tx_data           => PhyTxd,
        rmii_tx_en             => PhyTxEn,

        -- FPGA to PC interface
        streamer1_ip_address   => streamer1_ip_address,
        streamer1_sink_data    => streamer1_sink_data,
        streamer1_sink_last    => streamer1_sink_last,
        streamer1_sink_ready   => streamer1_sink_ready,
        streamer1_sink_valid   => streamer1_sink_valid,

        -- PC to FPGA interface
        streamer1_source_data  => streamer1_source_data,
        streamer1_source_error => streamer1_source_error,
        streamer1_source_last  => streamer1_source_last,
        streamer1_source_ready => streamer1_source_ready,
        streamer1_source_valid => streamer1_source_valid,

        streamer1_udp_port     => streamer1_udp_port,

        -- configuration of IP and MAC
        ip_address             => fpga_ip,
        mac_address            => fpga_mac,

        -- system clock and the system reset
        sys_clock              => CLK100MHZ,
        sys_reset              => sys_reset
    );

    RGB1_Blue  <= streamer1_sink_valid;
    RGB1_Green <= streamer1_sink_ready;

    RGB2_Blue  <= streamer1_source_valid;
    RGB2_Green <= streamer1_source_ready;
    RGB2_Red   <= streamer1_source_error;

    UDP_RX : PROCESS (CLK50MHZ) BEGIN
        IF rising_edge(CLK50MHZ) THEN
            IF (streamer1_source_ready = '0') THEN
                streamer1_source_ready <= '1';
            END IF;

            IF streamer1_source_valid = '1' THEN
                led                    <= streamer1_source_data(15 DOWNTO 0);
                streamer1_source_ready <= '0';
            END IF;
        END IF;
    END PROCESS;

    -- generate the 50MHz clock needed for the PHY
    RMII_clk : PROCESS (CLK100MHZ) BEGIN
        IF rising_edge(CLK100MHZ) THEN
            CLK50MHZ <= NOT CLK50MHZ;
        END IF;
    END PROCESS;
    -- forward the 50MHz clock to the PHY
    PhyClk50Mhz <= CLK50MHZ;

    -- a simple process removing the reset condition
    proc_reset : PROCESS (clk100MHz) BEGIN
        IF rising_edge(clk100MHz) THEN
            IF sys_reset = '1' THEN
                IF reset_cnt < RESET_RELEASE_CNT THEN
                    reset_cnt <= reset_cnt + 1;
                ELSE
                    sys_reset <= '0';
                END IF;
            END IF;
        END IF;
    END PROCESS proc_reset;

END Behavioral;
