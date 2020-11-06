
#ifndef _crc16_h_
#define _crc16_h_
/* the file from u-boot */
/* lib/crc16.c - 16 bit CRC with polynomial x^16+x^12+x^5+1 (CRC-CCITT) */
uint16_t crc16_ccitt(uint16_t crc_start, const unsigned char *s, int len);
/**
 * crc16_ccitt_wd_buf - Perform CRC16-CCIT on an input buffer and return the
 *                      16-bit result (network byte-order) in an output buffer
 *
 * @in:	input buffer
 * @len: input buffer length
 * @out: output buffer (at least 2 bytes)
 * @chunk_sz: ignored
 */
void crc16_ccitt_wd_buf(const uint8_t *in, uint len,
			uint8_t *out, uint chunk_sz);
#endif
