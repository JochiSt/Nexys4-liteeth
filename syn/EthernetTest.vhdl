LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL; -- signed / unsigned

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
    SIGNAL CLK50MHZ                    : STD_LOGIC                                := '0';
    SIGNAL CLK125MHz                   : STD_LOGIC                                := '0';

    ----------------------------------------------------------------------------
    -- RESET
    ----------------------------------------------------------------------------
    SIGNAL reset_cnt                   : INTEGER RANGE 0 TO RESET_RELEASE_CNT + 1 := 0; -- counter for releasing the reset signal
    SIGNAL sys_reset                   : STD_LOGIC                                := '1';

    ----------------------------------------------------------------------------
    -- SIGNALS
    ----------------------------------------------------------------------------
    -- signals for FPGA -> PC
    SIGNAL streamer1_sink_data         : STD_LOGIC_VECTOR (15 DOWNTO 0)           := (OTHERS => '0');
    SIGNAL streamer1_sink_dst_port     : STD_LOGIC_VECTOR (15 DOWNTO 0)           := (OTHERS => '0');
    SIGNAL streamer1_sink_ip_address   : STD_LOGIC_VECTOR (31 DOWNTO 0)           := (OTHERS => '0');
    SIGNAL streamer1_sink_last         : STD_LOGIC                                := '0';
    SIGNAL streamer1_sink_last_be      : STD_LOGIC_VECTOR (1 DOWNTO 0)            := (OTHERS => '0');
    SIGNAL streamer1_sink_length       : STD_LOGIC_VECTOR (15 DOWNTO 0)           := (OTHERS => '0');
    SIGNAL streamer1_sink_ready        : STD_LOGIC                                := '0';
    SIGNAL streamer1_sink_src_port     : STD_LOGIC_VECTOR (15 DOWNTO 0)           := (OTHERS => '0');
    SIGNAL streamer1_sink_valid        : STD_LOGIC                                := '0';

    -- signals for PC -> FPGA
    SIGNAL streamer1_source_data       : STD_LOGIC_VECTOR (15 DOWNTO 0)           := (OTHERS => '0');
    SIGNAL streamer1_source_dst_port   : STD_LOGIC_VECTOR (15 DOWNTO 0)           := (OTHERS => '0');
    SIGNAL streamer1_source_error      : STD_LOGIC                                := '0';
    SIGNAL streamer1_source_ip_address : STD_LOGIC_VECTOR (31 DOWNTO 0)           := (OTHERS => '0');
    SIGNAL streamer1_source_last       : STD_LOGIC                                := '0';
    SIGNAL streamer1_source_last_be    : STD_LOGIC_VECTOR (1 DOWNTO 0)            := (OTHERS => '0');
    SIGNAL streamer1_source_length     : STD_LOGIC_VECTOR (15 DOWNTO 0)           := (OTHERS => '0');
    SIGNAL streamer1_source_ready      : STD_LOGIC                                := '1';
    SIGNAL streamer1_source_src_port   : STD_LOGIC_VECTOR (15 DOWNTO 0)           := (OTHERS => '0');
    SIGNAL streamer1_source_valid      : STD_LOGIC                                := '0';

    CONSTANT fpga_mac                  : STD_LOGIC_VECTOR (47 DOWNTO 0)           := x"00_18_3e_01_ff_71"; -- FPGA's MAC address
    CONSTANT fpga_ip                   : STD_LOGIC_VECTOR (31 DOWNTO 0)           := x"C0_A8_01_0C";       -- FPGA's IP4 address 192.168.1.12
    ----------------------------------------------------------------------------
    -- liteeth core
    ----------------------------------------------------------------------------
    COMPONENT liteeth_core IS
        PORT (
            --ip_address                  : IN STD_LOGIC_VECTOR (31 DOWNTO 0);
            --mac_address                 : IN STD_LOGIC_VECTOR (47 DOWNTO 0);

            rmii_clocks_ref_clk         : IN STD_LOGIC;
            rmii_crs_dv                 : IN STD_LOGIC;
            rmii_mdc                    : OUT STD_LOGIC;
            rmii_mdio                   : INOUT STD_LOGIC;
            rmii_rst_n                  : OUT STD_LOGIC;
            rmii_rx_data                : IN STD_LOGIC_VECTOR (1 DOWNTO 0);
            rmii_tx_data                : OUT STD_LOGIC_VECTOR (1 DOWNTO 0);
            rmii_tx_en                  : OUT STD_LOGIC;

            streamer1_sink_data         : IN STD_LOGIC_VECTOR (15 DOWNTO 0);
            streamer1_sink_dst_port     : IN STD_LOGIC_VECTOR (15 DOWNTO 0);
            streamer1_sink_ip_address   : IN STD_LOGIC_VECTOR (31 DOWNTO 0);
            streamer1_sink_last         : IN STD_LOGIC;
            streamer1_sink_last_be      : IN STD_LOGIC_VECTOR (1 DOWNTO 0);
            streamer1_sink_length       : IN STD_LOGIC_VECTOR (15 DOWNTO 0);
            streamer1_sink_ready        : OUT STD_LOGIC;
            streamer1_sink_src_port     : IN STD_LOGIC_VECTOR (15 DOWNTO 0);
            streamer1_sink_valid        : IN STD_LOGIC;

            streamer1_source_data       : OUT STD_LOGIC_VECTOR (15 DOWNTO 0);
            streamer1_source_dst_port   : OUT STD_LOGIC_VECTOR (15 DOWNTO 0);
            streamer1_source_error      : OUT STD_LOGIC;
            streamer1_source_ip_address : OUT STD_LOGIC_VECTOR (31 DOWNTO 0);
            streamer1_source_last       : OUT STD_LOGIC;
            streamer1_source_last_be    : OUT STD_LOGIC_VECTOR (1 DOWNTO 0);
            streamer1_source_length     : OUT STD_LOGIC_VECTOR (15 DOWNTO 0);
            streamer1_source_ready      : IN STD_LOGIC;
            streamer1_source_src_port   : OUT STD_LOGIC_VECTOR (15 DOWNTO 0);
            streamer1_source_valid      : OUT STD_LOGIC;

            sys_clock                   : IN STD_LOGIC;
            sys_reset                   : IN STD_LOGIC
        );
    END COMPONENT; -- liteeth_core

    COMPONENT Ethernet_PLL IS
        PORT (
            CLK100MHz : IN STD_LOGIC;

            CLK125MHz : OUT STD_LOGIC;
            CLK50MHz  : OUT STD_LOGIC
        );
    END COMPONENT;

    COMPONENT readEthernetPacket IS
        GENERIC (
            PORT_MSB : NATURAL := 102
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
            udp_source_data       : IN STD_LOGIC_VECTOR(15 DOWNTO 0);

            udp_source_error      : IN STD_LOGIC;
            led                   : OUT STD_LOGIC_VECTOR(15 DOWNTO 0)
        );
    END COMPONENT;
    ----------------------------------------------------------------------------

BEGIN

    liteeth_core_0 : liteeth_core
    PORT MAP(
        -- reference clock of the PHY
        rmii_clocks_ref_clk         => CLK50MHZ,

        -- RMII interface to the PHY
        rmii_crs_dv                 => PhyCrs,
        rmii_mdc                    => PhyMdc,
        rmii_mdio                   => PhyMdio,
        rmii_rst_n                  => PhyRstn,
        rmii_rx_data                => PhyRxd,
        rmii_tx_data                => PhyTxd,
        rmii_tx_en                  => PhyTxEn,

        -- FPGA to PC interface
        streamer1_sink_data         => streamer1_sink_data,
        streamer1_sink_dst_port     => streamer1_sink_dst_port,
        streamer1_sink_ip_address   => streamer1_sink_ip_address,
        streamer1_sink_last         => streamer1_sink_last,
        streamer1_sink_last_be      => streamer1_sink_last_be,
        streamer1_sink_length       => streamer1_sink_length,
        streamer1_sink_ready        => streamer1_sink_ready,
        streamer1_sink_src_port     => streamer1_sink_src_port,
        streamer1_sink_valid        => streamer1_sink_valid,

        -- PC to FPGA interface
        streamer1_source_data       => streamer1_source_data,
        streamer1_source_dst_port   => streamer1_source_dst_port,
        streamer1_source_error      => streamer1_source_error,
        streamer1_source_ip_address => streamer1_source_ip_address,
        streamer1_source_last       => streamer1_source_last,
        streamer1_source_last_be    => streamer1_source_last_be,
        streamer1_source_length     => streamer1_source_length,
        streamer1_source_ready      => streamer1_source_ready,
        streamer1_source_src_port   => streamer1_source_src_port,
        streamer1_source_valid      => streamer1_source_valid,

        -- configuration of IP and MAC
        --ip_address                  => fpga_ip,
        --mac_address                 => fpga_mac,

        -- system clock and the system reset
        sys_clock                   => CLK125MHz,
        sys_reset                   => sys_reset
    );

    readEthernetPacket_0 : readEthernetPacket
    GENERIC MAP(
        PORT_MSB => 102
    )
    PORT MAP(
        clk                   => CLK125MHz,
        reset                 => sys_reset,

        udp_source_valid      => streamer1_source_valid,
        udp_source_last       => streamer1_source_last,
        udp_source_ready      => streamer1_source_ready,

        udp_source_src_port   => streamer1_source_src_port,
        udp_source_dst_port   => streamer1_source_dst_port,
        udp_source_ip_address => streamer1_source_ip_address,

        udp_source_length     => streamer1_source_length,
        udp_source_data       => streamer1_source_data,

        udp_source_error      => streamer1_source_error,

        led                   => led
    );

    RGB1_Blue  <= streamer1_sink_valid;
    RGB1_Green <= streamer1_sink_ready;

    RGB2_Blue  <= streamer1_source_valid;
    RGB2_Green <= streamer1_source_ready;
    RGB2_Red   <= streamer1_source_error;

    --led        <= streamer1_source_dst_port;

    -- generate  50 MHz clock needed for the PHY
    -- generate 200 MHz for the liteeth
    Ethernet_PLL_0 : Ethernet_PLL
    PORT MAP(
        CLK100MHz => CLK100MHZ,

        CLK125MHz => CLK125MHz,
        CLK50MHz  => CLK50MHZ
    );

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
