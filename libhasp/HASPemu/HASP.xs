#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "VNHASP.h"

#include <time.h>

int _getDateTime(int *s, int *min, int *h, int *d, int *mon, int *y)
{
	int p1, p2, p3, p4;

	time_t ctime = time(NULL);
	struct tm *time = localtime(&ctime);
	*s 	= time->tm_sec;
	*min	= time->tm_min;	
	*h	= time->tm_hour;
	*d 	= time->tm_mday;
	*mon 	= time->tm_mon;
	*y	= time->tm_year;

	return 0;
}

int _setDateTime(int s, int min, int h, int d, int mon, int y)
{
	int p1, p2, p3, p4;

	return 0;
}

MODULE = VN::HASP		PACKAGE = VN::HASP		

int
Attached()
    PREINIT:
    CODE:
	RETVAL = 0;
quit:
    OUTPUT:
	RETVAL

int
DecodeData(data)
	SV *data;
    PREINIT:
    CODE:
	RETVAL = 1;
    OUTPUT:
	RETVAL

int
EncodeData(data)
	SV *data;
    PREINIT:
    CODE:
	RETVAL = 1;
    OUTPUT:
	RETVAL

int
Id(id)
	SV *id;
    PREINIT:
    CODE:
	sv_setiv(id, 0);
	SvSETMAGIC(id);
	RETVAL = 0;
    OUTPUT:
	RETVAL

int
ReadBlock(data, length, addr)
	int length;
	int addr;
	SV *data;
    PREINIT:
	size_t p1, p2, p3, p4;
	int r_a;
	char *buff;
	FILE *f;
    CODE:
	if(length < 0) length = 0;
	if(addr < 0) addr = 0;
//	p1 = addr / sizeof(WORD); r_a = addr % sizeof(WORD);
//	p2 = (length + r_a) / sizeof(WORD); p2 += (p2*sizeof(WORD) == (length + r_a)) ? 0 : 1;
	r_a = 0;
	p3 = 0;
//	New(0, buff, p2 * sizeof(WORD), char); p4 = (int) buff;
	New(0, buff, length * sizeof(WORD), char); p4 = (size_t) buff;
//	memset(buff, 0, p2*sizeof(WORD));
//	hasp(MEMOHASP_READBLOCK, SEEDCODE, 0, PASS1, PASS2, &p1, &p2, &p3, &p4);
//	if( f = fopen(HASP_DATA_FILE, "rb") ) {
	if( f = fopen(HASP_DATA_FILE, "r") ) {
		fseek(f, addr, SEEK_SET);
		fread(buff, 1, length, f); 
		fclose(f);
		*(buff+length) = 0;
//		fprintf(stderr, "readed %d from %d: '%s'\n", length, addr, buff);
	} else {
		p3 = errno;
	}
	sv_setpvn(data, buff + r_a, length);
	SvSETMAGIC(data);
	Safefree(buff);
	RETVAL = p3;
    OUTPUT:
	RETVAL


int
WriteBlock(data, addr)
	int addr;
	SV *data;
    PREINIT:
	size_t p1, p2, p3, p4;
	char *tmp, *buff;
	STRLEN len;
	int r_a;
	FILE *f;
    CODE:
	if(addr < 0) addr = 0;
	tmp = SvPV(data, len);
	p1 = addr / sizeof(WORD); r_a = addr % sizeof(WORD);
	p2 = (len + r_a) / sizeof(WORD); p2 += (p2*sizeof(WORD) == (len + r_a)) ? 0 : 1;
	New(0, buff, p2 * sizeof(WORD), char); p4 = (size_t) buff;
//	hasp(MEMOHASP_READBLOCK, SEEDCODE, 0, PASS1, PASS2, &p1, &p2, &p3, &p4);
	Copy(tmp, buff + r_a, len, char); p4 = (size_t) buff;
//	hasp(MEMOHASP_WRITEBLOCK, SEEDCODE, 0, PASS1, PASS2, &p1, &p2, &p3, &p4);
	if( f = fopen(HASP_DATA_FILE, "wb") ) {
		fseek(f, p1, SEEK_SET);
		fwrite(buff, 1, p2, f); 
		fclose(f);
	}
	RETVAL = 0;
	Safefree(buff);
    OUTPUT:
	RETVAL

int
SetDateTime(s, min, h, d, mon, y)
	int s;
	int min;
	int h;
	int d;
	int mon;
	int y;
    CODE:
	RETVAL = _setDateTime(s, min, h, d, mon, y);
    OUTPUT:
	RETVAL

int
GetDateTime(s, min, h, d, mon, y)
	SV* s;
	SV* min;
	SV* h;
	SV* d;
	SV* mon;
	SV* y;
    PREINIT:
	int s_1, min_1, h_1, d_1, mon_1, y_1;
	int rv;
    CODE:
	rv = _getDateTime(&s_1, &min_1, &h_1, &d_1, &mon_1, &y_1);
	if(rv == 0) {
		sv_setiv(s, (IV) s_1);
		sv_setiv(min, (IV) min_1);
		sv_setiv(h, (IV) h_1);
		sv_setiv(d, (IV) d_1);
		sv_setiv(mon, (IV) mon_1);
		sv_setiv(y, (IV) y_1);
	}
	RETVAL = rv;
    OUTPUT:
	RETVAL

# compare time in arguments with current time from hasp
# arguments: s, min, h, d, mon, y - time to compare
#            res - result of comparison: 
#                    1 - time is grater than current time
#                    0 - times are equal
#                    -1 - current time is grater than time
# return values: 
#               0 - operation completed successfully
#               other - hasp error

int
CompareTimeWithCurrent(s, min, h, d, mon, y, res)
	int s;
	int min;
	int h;
	int d;
	int mon;
	int y;
	SV* res;
    PREINIT:
	int s_1, min_1, h_1, d_1, mon_1, y_1;
	int rv;
    CODE:
	rv = _getDateTime(&s_1, &min_1, &h_1, &d_1, &mon_1, &y_1);
	if(rv == 0) {
		long date, date1, time, time1;
		date = y*10000 + mon*100 + d;
		date1 = y_1*10000 + mon_1*100 + d_1;
		time = h*10000 + min*100 + s;
		time1 = h_1*10000 + min_1*100 + s_1;
		if(date > date1 || ((date == date1) && (time > time1))) {
			sv_setiv(res, (IV) 1);
		} else if(date1 > date || ((date == date1) && (time1 > time))) {
			sv_setiv(res, (IV) -1);
		} else {
			sv_setiv(res, (IV) 0);
		}
	}
	RETVAL = rv;
    OUTPUT:
	RETVAL
