/*

*/
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include <fcntl.h>
#include <getopt.h>

#include <sys/ioctl.h>
#include <sys/stat.h>
#include <sys/types.h>
#include <errno.h>
#include <unistd.h>
#include <stdint.h>
#include "crc16.h"
#include <linux/i2c.h>
#include <linux/types.h>

#define VERSION "1.0.0"

struct i2c_rdwr_ioctl_data {
    struct i2c_msg *msgs;
    uint32_t nmsgs;
};

/* I2C IOCTL from Kernel */
#define I2C_RETRIES	    0x0701	/* number of times a device address should
				               be polled when not acknowledging */
#define I2C_TIMEOUT	    0x0702	/* set timeout in units of 10 ms */
#define I2C_SLAVE	    0x0703	/* Use this slave address */
#define I2C_SLAVE_FORCE	0x0706	/* Use this slave address, even if it
				                is already in use by a driver! */
#define I2C_TENBIT	    0x0704	/* 0 for 7 bit addrs, != 0 for 10 bit */
#define I2C_FUNCS	    0x0705	/* Get the adapter functionality mask */
#define I2C_RDWR	    0x0707	/* Combined R/W transfer (one STOP only) */
#define I2C_PEC		    0x0708	/* != 0 to use PEC with SMBus */
#define I2C_SMBUS	    0x0720	/* SMBus transfer */

#define DEFAULT_I2CBUS      (0)
#define DEFAULT_EEPROM_ADDR (0x57)

#define HEADER_SIZE 160
#define LINE_SIZE   80

/* prefix AAEON MAC address */
const static char prefixAAEON[] = "000732";

union _FLAGS_OPT {
    uint32_t flags;
    struct {
        uint32_t boardName : 1;
        uint32_t manufacturer : 1;
        uint32_t serialNumber : 1;
        uint32_t eth0 : 1;
        uint32_t eth1 : 1;
        uint32_t bluetooth : 1;
        uint32_t wlan : 1;
        uint32_t hwCfg : 1;
        uint32_t swCfg : 1;
        uint32_t hwRev : 1;
        uint32_t swVer : 1;
        uint32_t dump : 1;
        uint32_t verbose: 1;
        uint32_t force : 1;
        uint32_t help : 1;
    } member;
};

static union _FLAGS_OPT optFlag = {0};
static union _FLAGS_OPT optSetFlag = {0};

static int isForce(void) {
    return (optFlag.member.force) ? 1 : 0;
}

static int isHelp(void) {
    return (optFlag.member.help) ? 1 : 0;
}

static int isVerbose(void) {
    return (optFlag.member.verbose) ? 1 : 0;
}

static int isDump(void) {
    return (optFlag.member.dump) ? 1 : 0;
}

typedef struct __attribute__((__packed__)) _eeprom_t {
    uint8_t magic[4];
    uint8_t rev[2];
    uint8_t bname[32];
    uint8_t serial[16];
    uint8_t manufacturer[32];
    uint8_t macEth0[6];
    uint8_t macEth1[6];
    uint8_t macBt[6];
    uint8_t macWlan[6];
    uint8_t hwRev[2];
    uint8_t hwCfg[4];
    uint8_t swVer[2];
    uint8_t swCfg[4];
    uint8_t reservedCus[32];
    uint8_t bootCount[4];
    uint8_t crc16[2];
} EEPROM_HDR;

static EEPROM_HDR epr;
static EEPROM_HDR optBuf;
static uint8_t eeBuff[256];

typedef int (*CMD_FUNCTION)(EEPROM_HDR *, char *);

static int i2c_read(int fd, int addr, unsigned char reg, int len, unsigned char *buffer) {
    int ret = 0;

    /* for random read */
    struct i2c_msg rdwr_msgs[2] = {
        {// Start address
         .addr = addr,
         .flags = 0, // write
         .len = 1,
         .buf = &reg},
        {// Read buffer
         .addr = addr,
         .flags = I2C_M_RD, // read
         .len = len,
         .buf = buffer}};

    struct i2c_rdwr_ioctl_data rdwr_data = {
        .msgs = rdwr_msgs,
        .nmsgs = 2};

    ret = ioctl(fd, I2C_RDWR, &rdwr_data);
    if (ret < 0) {
        fprintf(stderr, "I2C_RDWR failed, %s\n", strerror(errno));
        return ret;
    }

    return len;
}

static int i2c_write(int fd, int addr, unsigned char reg, unsigned char val) {
    uint8_t outbuf[2];
    struct i2c_msg msgs[1];
    struct i2c_rdwr_ioctl_data msgset[1];

    outbuf[0] = reg;
    outbuf[1] = val;

    msgs[0].addr = addr;
    msgs[0].flags = 0;
    msgs[0].len = 2;
    msgs[0].buf = outbuf;

    msgset[0].msgs = msgs;
    msgset[0].nmsgs = 1;

    if (ioctl(fd, I2C_RDWR, &msgset) < 0) {
        fprintf(stderr, "I2C_RDWR in i2c_write, %s", strerror(errno));
        return -1;
    }

    return 1;
}

static unsigned char convHex(char v) {
    if (v >= '0' && v <= '9')
        return v - '0';

    if (v >= 'A' && v <= 'F')
        return (v - 'A') + 0x0a;

    if (v >= 'a' && v <= 'f')
        return (v - 'a') + 0x0a;

    return 0xFF;
}

static int set_eeprom_SwCFG(EEPROM_HDR *e, char *cfg) {
    char **ptr;
    unsigned long dwCfg = strtoul(cfg, ptr, 0);
    *((unsigned long *)e->swCfg) = dwCfg;
    return 0;
}

static int set_eeprom_SwVer(EEPROM_HDR *e, char ver[2]) {
    e->swVer[0] = ver[0];
    e->swVer[1] = ver[1];
    return 0;
}

static int set_eeprom_HwCFG(EEPROM_HDR *e, char *cfg) {
    char **ptr;
    unsigned long dwCfg = strtoul(cfg, ptr, 0);
    *((unsigned long *)e->hwCfg) = dwCfg;
    return 0;
}

static int set_eeprom_HwRev(EEPROM_HDR *e, char ver[2]) {
    e->hwRev[0] = ver[0];
    e->hwRev[1] = ver[1];
    return 0;
}

static int convMAC(uint8_t addr[6], char *mac) {

    int values[6];

    if ((mac == NULL) || (addr == NULL)) {
        return -1;
    }

    if (strlen(mac) == 12) {
        unsigned char t;
        for (int i = 0; i < 6; i++) {
            /* high nibble */
            t = convHex(mac[i * 2]);
            if (t == 0xFF) return -1;
            addr[i] = t << 4;;
            /* low nibble */
            t = convHex(mac[i * 2 + 1]);
            if (t == 0xFF) return -1;
            addr[i] += t;
        }
        return 0;
    }
    
    if( 6 == sscanf( mac, "%x:%x:%x:%x:%x:%x%*c",
        &values[0], &values[1], &values[2],
        &values[3], &values[4], &values[5] ) )
    {
        /* convert to uint8_t */
        for(int i = 0; i < 6; ++i )
            addr[i] = (uint8_t) values[i];

        return 0;
    }
    /* invalid mac */
    return -1;
}

static int set_eeprom_wlan(EEPROM_HDR *e, char *mac) {
    return convMAC(e->macWlan, mac);
}

static int set_eeprom_bt(EEPROM_HDR *e, char *mac) {
    return convMAC(e->macBt, mac);
}

static int set_eeprom_eth1(EEPROM_HDR *e, char *mac) {
    return convMAC(e->macEth1, mac);
}

static int set_eeprom_eth0(EEPROM_HDR *e, char *mac) {
    return  convMAC(e->macEth0, mac);
}

static int setBoardSerialNumber(EEPROM_HDR *e, char *sn) {
    strncpy(e->serial, sn, sizeof(e->serial));
    return 0;
}

static int setManufacturer(EEPROM_HDR *e, char *m_name) {
    strncpy(e->manufacturer, m_name, sizeof(e->manufacturer));
    return 0;
}

static int setBoardName(EEPROM_HDR *e, char *name) {
    strncpy(e->bname, name, sizeof(e->bname));
    return 0;
}

int setHeaderRev(EEPROM_HDR *e, char rev[2]) {
    e->rev[0] = rev[0];
    e->rev[1] = rev[1];
    return 0;
}

int setHeaderMagic(EEPROM_HDR *e) {
    memset(e, 0, sizeof(EEPROM_HDR));
    e->magic[0] = 'A';
    e->magic[1] = 'I';
    e->magic[2] = 'O';
    e->magic[3] = 'T';
}

int eeprom_dump(EEPROM_HDR *e) {
    int i, j;
    char c;
    unsigned char *p = (unsigned char *)e;

    for (i = 0; i < HEADER_SIZE; i += 16) {
        if (i % 256 == 0)
            printf("     00 01 02 03 04 05 06 07 - 08 09 0a 0b 0c 0d 0e 0f\n");

        printf("%04x ", i);
        for (j = 0; j < 16; j++) {
            printf("%02x ", (int)*(p + i + j));
            if (j == 7)
                printf("- ");
        }
        printf(" | ");
        for (j = 0; j < 16; j++) {
            c = *(p + i + j);
            printf("%c", c < 32 || c > 127 ? '.' : c);
            if (j == 7)
                printf(" ");
        }
        printf("\n");
    }
    printf("\n");
    return 0;
}

static int openAT24C02(void) {
    int f = -1;
    char fname[20] = {0};
    int device = DEFAULT_EEPROM_ADDR;

    snprintf(fname, 19, "/dev/i2c-%d", DEFAULT_I2CBUS);
    /* to getting i2c-bus handler */
    f = open(fname, O_RDWR);
    if (f < 0) {
        fprintf(stderr, "open %s failed\n", fname);
        exit(1);
    }
      
    if (ioctl(f, I2C_TIMEOUT, 10) < 0) {
        fprintf(stderr, "set i2c timeout failed\n");
    }

    if (ioctl(f, I2C_SLAVE, device) < 0) {
        fprintf(stderr, "set device address 0x%02X failed\n", device);
        return -2;
    }

    return f;
}

static int rdFromAT24C02(int f, uint8_t b[256]) {
    int res = 0;

    for (int i = 0; i < 256; i += res) {
        // read 32bytes
        res = i2c_read(f, DEFAULT_EEPROM_ADDR, i, 32, b + i);
        if (res < 0) {
            return -3;
        }
    }
    return 0;
}

static int wr2402Byte(int f, int i, uint8_t v) {
    if (i2c_write(f, DEFAULT_EEPROM_ADDR, i, v) < 0)
        return -3;
    usleep(18000);
    return 0;
}

static int wrIntoAT24C02(int f, uint8_t b[256]) {
    int res = 0;

    for (int i = 0; i < 256; i++) {
        // write 256 byte
        res = i2c_write(f, DEFAULT_EEPROM_ADDR, i, b[i]);
        if (res < 0) {
            return -3;
        }
        usleep(15000); /* we need waiting EEPROM operation */
    }
    return 0;
}

static int isNodata(uint8_t b[256]) {
    for (int i = 0; i < 256; i++) {
        if (b[i] != 0xFF && b[i] != 0x00)
            return -1;
    }
    return 0;
}

static int checkHeaderMagic(const EEPROM_HDR *b) {
    if (b->magic[0] != 'A' || b->magic[1] != 'I' ||
        b->magic[2] != 'O' || b->magic[3] != 'T')
        return -1;
    return 0;
}

static int checkHeaderVersion(const EEPROM_HDR *b) {
    if (b->rev[0] != '0' || b->rev[1] != '1')
        return -1;
    return 0;
}

static int checkCRC(const EEPROM_HDR *b) {
    return 0;
}

static int isSupportEEPROM(uint8_t b[256]) {
    EEPROM_HDR *p = (EEPROM_HDR *)b;
    if (checkHeaderMagic(p) < 0)
        return -1;
    if (checkHeaderVersion(p) < 0)
        return -2;
    if (checkCRC(p) < 0)
        return -3;

    return 0;
}

static int writeIntoEEPROM(EEPROM_HDR *e) {
    int f = -1, r = -1;
    uint8_t buff[256];

    if (!e)
        return -1;
    f = openAT24C02();
    if (f < 0) {
        return f;
    }
    memset(buff, 0xff, sizeof(buff));
    memcpy(buff, e, sizeof(EEPROM_HDR));
    for (int i = 0; i < sizeof(EEPROM_HDR); i++) {
        if (buff[i] != eeBuff[i])
            wr2402Byte(f, i, buff[i]);
    }
    close(f);

    return 0;
}

static int readFromEEPROM(EEPROM_HDR *e) {
    int f = -1, r = -1;
    if (!e)
        return -1;

    memset(eeBuff, 0xFF, sizeof(eeBuff));
    f = openAT24C02();
    if (f < 0) {
        return f;
    }
    
    r = rdFromAT24C02(f, eeBuff);
    if (r < 0) {
        close(f);
        return r;
    }
    close(f);

    /* */
    if (isSupportEEPROM(eeBuff) == 0) {
        memcpy(e, eeBuff, sizeof(EEPROM_HDR));
        return 0;
    }
    if (isNodata(eeBuff) == 0) {
        return -1;
    }
    return -2;
}

int eeprom_print_board_info(EEPROM_HDR *e) {
    fprintf(stdout, "1. BoardName (32 bytes)         : %s\n", e->bname);
    fprintf(stdout, "2. Board Manufacturer (32 bytes): %s\n", e->manufacturer);
    fprintf(stdout, "3. Serial Number  (16 bytes)    : %s\n", e->serial);
    fprintf(stdout, "4. MAC of Eth0                  : %02X:%02X:%02X:%02X:%02X:%02X\n",
            e->macEth0[0], e->macEth0[1], e->macEth0[2], e->macEth0[3], e->macEth0[4], e->macEth0[5]);
    fprintf(stdout, "5. MAC of Eth1                  : %02X:%02X:%02X:%02X:%02X:%02X\n",
            e->macEth1[0], e->macEth1[1], e->macEth1[2], e->macEth1[3], e->macEth1[4], e->macEth1[5]);
    fprintf(stdout, "--- \n");
    return 0;
}


static const char *short_options = "n::m::s::0::1::b::w::d::c::r::e::fvahA:B:";
static const struct option long_options[] = {
    {"name", optional_argument, NULL, 'n'},
    {"manu", optional_argument, NULL, 'm'},
    {"sn", optional_argument, NULL, 's'},
    {"eth0", optional_argument, NULL, '0'},
    {"eth1", optional_argument, NULL, '1'},
    {"aeth0", required_argument, NULL, 'A'},
    {"aeth1", required_argument, NULL, 'B'},
    {"bt", optional_argument, NULL, 'b'},
    {"wlan", optional_argument, NULL, 'w'},
    {"hwcfg", optional_argument, NULL, 'd'},
    {"swcfg", optional_argument, NULL, 'c'},
    {"hwrev", optional_argument, NULL, 'r'},
    {"swver", optional_argument, NULL, 'e'},
    {"force", no_argument, NULL, 'f'},
    {"verbose", no_argument, NULL, 'v'},
    {"dump", no_argument, NULL, 'a'},
    {"help", no_argument, NULL, 'h'},
    {NULL, 0, NULL, 0},
};

static void sTitle(void) {
    fprintf(stdout, "SRG-3352x EEPROM Processor " VERSION "\n");
}

static void helper(void) {
    sTitle();
    fprintf(stdout, "\n");
    fprintf(stdout, "\t-n, --name=[value]   set/get board name, 32bytes\n");
    fprintf(stdout,
            "\t-m, --manu=[value]   set/get manufacturer name, 32bytes, default:\"AAEON TECHNOLOGY "
            "INC.\"\n");
    fprintf(stdout, "\t-s, --sn=[value]     set/get serial number, 16bytes\n");
    fprintf(stdout, "\t-0, --eth0=[value]   set/get MAC address of eth0\n");
    fprintf(stdout, "\t-1, --eth1=[value]   set/get MAC address of eth1\n");
    fprintf(stdout, "\t-A  --aeth0=[value]  set AAEON MAC address without common");
    fprintf(stdout, "\t-B  --aeth1=[value]  set AAEON MAC address without common");    
    fprintf(stdout, "\t-b, --bt=[value]     set/get MAC address of bluetooth\n");
    fprintf(stdout, "\t-w, --wlan=[value]   set/get MAC address of wlan\n");
    fprintf(stdout, "\t-g, --hwcfg=[value]  set/get hardware configuration, 32bits\n");
    fprintf(stdout, "\t-c, --swcfg=[value]  set/get software configuration, 32bits\n");
    fprintf(stdout, "\t-r, --hwrev=[value]  set/get hardware revision, 32bits\n");
    fprintf(stdout, "\t-e, --swvev=[value]  set/get software version, 32bits\n");
    fprintf(stdout, "\t-f, --force          force write into EEPROM\n");
    fprintf(stdout, "\t-d, --dump           dump content of EEPROM\n");
    fprintf(stdout, "\t-v, --verbose        verbose message\n");
}

static int preprocess_cmd_option(int argc, char *argv[]) {
    int result = 0;
    int optCount = 0;
    while (1) {
        int c = -1;
        int opt_idx = 0;
        c = getopt_long(argc, argv, short_options, long_options, &opt_idx);
        optCount++;
        if (c == -1) {
            break;
        }

        switch (c) {
        case 'n': {
            optFlag.member.boardName = 1;
            if (optarg) {
                optSetFlag.member.boardName = 1;
                setBoardName(&optBuf, optarg);
            }
        } break;
        case 'm': {
            optFlag.member.manufacturer = 1;
            if (optarg) {
                optSetFlag.member.manufacturer = 1;
                setManufacturer(&optBuf, optarg);
            }
        } break;
        case 's': {
            optFlag.member.serialNumber = 1;
            if (optarg) {
                optSetFlag.member.serialNumber = 1;
                setBoardSerialNumber(&optBuf, optarg);
            }

        } break;
        case '0': {
            optFlag.member.eth0 = 1;
            if (optarg) {
                optSetFlag.member.eth0 = 1;
                set_eeprom_eth0(&optBuf, optarg);
            }
        } break;
        case '1': {
            optFlag.member.eth1 = 1;
            if (optarg) {
                optSetFlag.member.eth1 = 1;
                set_eeprom_eth1(&optBuf, optarg);
            }
        } break;
        case 'A': {
            if (optarg && (6 == strlen(optarg))) {
                char buff[16] = { 0 };
                memcpy(buff, prefixAAEON, 6);
                memcpy(buff+6, optarg, 6);
                if (0 == set_eeprom_eth0(&optBuf, buff)) {
                    optFlag.member.eth0 = 1;
                    optSetFlag.member.eth0 = 1;
                }
            }
        } break;
        case 'B': {
            if (optarg && (6 == strlen(optarg))) {
                char buff[16] = { 0 };
                memcpy(buff, prefixAAEON, 6);
                memcpy(buff+6, optarg, 6);
                if (set_eeprom_eth1(&optBuf, buff) == 0 ) {
                    optFlag.member.eth1 = 1;
                    optSetFlag.member.eth1 = 1;
                }
            }
        } break;
        case 'b': {
            optFlag.member.bluetooth = 1;
            if (optarg) {
                optSetFlag.member.bluetooth = 1;
                set_eeprom_bt(&optBuf, optarg);
            }
        } break;
        case 'w': {
            optFlag.member.wlan = 1;
            if (optarg) {
                optSetFlag.member.wlan = 1;
                set_eeprom_wlan(&optBuf, optarg);
            }
        } break;
        case 'g': {
            optFlag.member.hwCfg = 1;
            if (optarg) {
                optSetFlag.member.hwCfg = 1;
                set_eeprom_HwCFG(&optBuf, optarg);
            }
        } break;
        case 'c': {
            optFlag.member.swCfg = 1;
            if (optarg) {
                optSetFlag.member.swCfg = 1;
                set_eeprom_SwCFG(&optBuf, optarg);
            }
        } break;
        case 'r': {
            optFlag.member.hwRev = 1;
            if (optarg) {
                optSetFlag.member.hwRev = 1;
                set_eeprom_HwRev(&optBuf, optarg);
            }
        } break;
        case 'e': {
            optFlag.member.swVer = 1;
            if (optarg) {
                optSetFlag.member.swVer = 1;
                set_eeprom_SwVer(&optBuf, optarg);
            }
        } break;
        case 'v':
            optFlag.member.verbose = 1;
            break;
        case 'f':
            optFlag.member.force = 1;
            break;
        case 'd':
            optFlag.member.dump = 1;
            break;
        case 'h':
            optFlag.member.help = 1;
            break;
        default:
            return -1;
        }
    }
    return result;
}

static void process_options(int flag) {
    if (flag < 0) {
        if (isForce()) {
            setHeaderMagic(&epr);
            setHeaderRev(&epr, "01");
            setBoardName(&epr, "SRG-3352");
            setManufacturer(&epr, "AAEON TECHNOLOGY INC.");
            setBoardSerialNumber(&epr, "0123456789ABCDEF");
        } else {
            if (flag == -1) {
                fprintf(stderr, "EEPROM is NULL\n");
                exit(1);
            } else {
                fprintf(stderr, "Unknown content of EEPROM\n");
                exit(2);
            }
        }
    }

    if (optFlag.member.boardName) {
        char buff[40] = { 0 };
        if (optSetFlag.member.boardName) {
            memcpy(&epr.bname, &optBuf.bname, sizeof(epr.bname));
        }
        memcpy(buff, &epr.bname, sizeof(epr.bname));
        fprintf(stdout, "%s\n", buff);
    }

    if (optFlag.member.manufacturer) {
        char buff[40] = { 0 };
        if (optSetFlag.member.manufacturer) {
            memcpy(&epr.manufacturer, &optBuf.manufacturer, sizeof(epr.manufacturer));
        }
        memcpy(buff, &epr.manufacturer, sizeof(epr.manufacturer));
        fprintf(stdout, "%s\n", buff);
    }

    if (optFlag.member.serialNumber) {
        char buff[20] = { 0 };
        if (optSetFlag.member.serialNumber) {
            memcpy(&epr.serial, &optBuf.serial, sizeof(epr.serial));
        }
        memcpy(buff, &epr.serial, sizeof(epr.serial));
        fprintf(stdout, "%s\n", buff);
    }

    if (optFlag.member.eth0) {
        char buff[10] = { 0 };
        if (optSetFlag.member.eth0) {
            memcpy(&epr.macEth0, &optBuf.macEth0, sizeof(epr.macEth0));
        }
        memcpy(buff, &epr.macEth0, sizeof(epr.macEth0));
        fprintf(stdout, "%02X:%02X:%02X:%02X:%02X:%02X\n", 
        buff[0], buff[1], buff[2], buff[3],buff[4], buff[5]);
    }

    if (optFlag.member.eth1) {
        char buff[10] = { 0 };
        if (optSetFlag.member.eth1) {
            memcpy(&epr.macEth1, &optBuf.macEth1, sizeof(epr.macEth1));
        }
        memcpy(buff, &epr.macEth1, sizeof(epr.macEth1));
        fprintf(stdout, "%02X:%02X:%02X:%02X:%02X:%02X\n", 
        buff[0], buff[1], buff[2], buff[3],buff[4], buff[5]);
    }

    if (optFlag.member.bluetooth) {
        char buff[10] = { 0 };
        if (optSetFlag.member.bluetooth) {
            memcpy(&epr.macBt, &optBuf.macBt, sizeof(epr.macBt));
        }
        memcpy(buff, &epr.macBt, sizeof(epr.macBt));
        fprintf(stdout, "%02X:%02X:%02X:%02X:%02X:%02X\n", 
        buff[0], buff[1], buff[2], buff[3],buff[4], buff[5]);        
    }

    if (optFlag.member.wlan) {
        char buff[10] = { 0 };
        if (optSetFlag.member.wlan) {
            memcpy(&epr.macWlan, &optBuf.macWlan, sizeof(epr.macWlan));
        }
        memcpy(buff, &epr.macWlan, sizeof(epr.macWlan));
        fprintf(stdout, "%02X:%02X:%02X:%02X:%02X:%02X\n", 
            buff[0], buff[1], buff[2], buff[3], buff[4], buff[5]);        
    }

    if (optFlag.member.hwCfg) {
        char buff[10] = { 0 };
        if (optSetFlag.member.hwCfg) {
            memcpy(&epr.hwCfg, &optBuf.hwCfg, sizeof(epr.hwCfg));
        }
        memcpy(buff, &epr.hwCfg, sizeof(epr.hwCfg));
        fprintf(stdout, "0x%02X%02X%02X%02X\n",
            buff[0], buff[1], buff[2], buff[3]);        
    }

    if (optFlag.member.swCfg) {
        char buff[10] = { 0 };
        if (optSetFlag.member.swCfg) {
            memcpy(&epr.swCfg, &optBuf.swCfg, sizeof(epr.swCfg));
        }
        memcpy(buff, &epr.swCfg, sizeof(epr.swCfg));
        fprintf(stdout, "0x%02X%02X%02X%02X\n",
            buff[0], buff[1], buff[2], buff[3]);        
    }

    if (optFlag.member.hwRev) {
        char buff[10] = { 0 };
        if (optSetFlag.member.hwRev) {
            memcpy(&epr.hwRev, &optBuf.hwRev, sizeof(epr.hwRev));
        }
        memcpy(buff, &epr.hwRev, sizeof(epr.hwRev));
        fprintf(stdout, "%c%c\n",
            buff[0], buff[1]);          
    }

    if (optFlag.member.swVer) {
        char buff[10] = { 0 };
        if (optSetFlag.member.swVer) {
            memcpy(&epr.swVer, &optBuf.swVer, sizeof(epr.swVer));
        }
        memcpy(buff, &epr.swVer, sizeof(epr.swVer));
        fprintf(stdout, "%c%c\n",
            buff[0], buff[1]);          
    }    

    writeIntoEEPROM(&epr);

    if (isDump()) {
        eeprom_dump(&epr);
    }
}

int main(int argc, char *argv[]) {
    int flag;
    char buffer[LINE_SIZE];
    int cmd_opt = 0;

    memset(&epr, 0xFF, sizeof(epr));
    memset(&optBuf, 0xFF, sizeof(optBuf));

    cmd_opt = preprocess_cmd_option(argc, argv);
    if (cmd_opt != 0 || isHelp()) {
        helper();
        exit(0);
    }

    flag = readFromEEPROM(&epr);
    process_options(flag);
}
