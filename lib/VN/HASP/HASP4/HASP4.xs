#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "VNHASP.h"

#include "ppport.h"

#include "const-c.inc"

int _getDateTime(int *s, int *min, int *h, int *d, int *mon, int *y)
{
	int p1, p2, p3, p4;

	hasp(TIMEHASP_GETDATE, SEEDCODE, 0, PASS1, PASS2, &p1, &p2, &p3, &p4);
	if(p3 == 0) {
		*d = p1; *mon = p2 - 1; *y = p4;
		if(*y < 92) *y += 100;
		hasp(TIMEHASP_GETTIME, SEEDCODE, 0, PASS1, PASS2, &p1, &p2, &p3, &p4);
		if(p3 == 0) {
			*s = p1; *min = p2; *h = p4;
		}
	}

	return p3;
}

int _setDateTime(int s, int min, int h, int d, int mon, int y)
{
	int p1, p2, p3, p4;

	p1 = d; p2 = mon+1; p4 = y;
	if(p4 >= 100) p4 = p4 - 100;
	hasp(TIMEHASP_SETDATE, SEEDCODE, 0, PASS1, PASS2, &p1, &p2, &p3, &p4);
	if(p3 == 0) {
		p1 = s; p2 = min; p4 = h;               
		hasp(TIMEHASP_SETTIME, SEEDCODE, 0, PASS1, PASS2, &p1, &p2, &p3, &p4);
	}

	return p3;
}

MODULE = VN::HASP::HASP4		PACKAGE = VN::HASP::HASP4		

INCLUDE: const-xs.inc

int
Attached()
    PREINIT:
	int p1, p2, p3, p4;
    CODE:
	hasp(LOCALHASP_ISHASP, SEEDCODE, 0, PASS1, PASS2, &p1, &p2, &p3, &p4);
	if(p1 == 0) { RETVAL = p3 ? p3 : -3; goto quit; }
	hasp(MEMOHASP_HASPID, SEEDCODE, 0, PASS1, PASS2, &p1, &p2, &p3, &p4);
	if(p3 != 0) { RETVAL = p3; goto quit; }
	RETVAL = HASPID - (65536*p2 + p1);
quit:
    OUTPUT:
	RETVAL

int
DecodeData(data)
	SV *data;
    PREINIT:
	int p1, p2, p3, p4;
	STRLEN len;
	char *tmp, *buff;
    CODE:
	tmp = SvPV(data, len);
	New(0, buff, len, char); Copy(tmp, buff, len, char);
	p1 = 0; p2 = len; p4 = (int) buff;
	hasp(LOCALHASP_DECODEDATA, SEEDCODE, 0, PASS1, PASS2, &p1, &p2, &p3, &p4);
	RETVAL = p3;
	sv_setpvn(data, buff, len);
	SvSETMAGIC(data);
	Safefree(buff);
    OUTPUT:
	RETVAL

int
EncodeData(data)
	SV *data;
    PREINIT:
	int p1, p2, p3, p4;
	STRLEN len;
	char *tmp, *buff;
    CODE:
	tmp = SvPV(data, len);
	New(0, buff, len, char); Copy(tmp, buff, len, char);
	p1 = 0; p2 = len; p4 = (int) buff;
	hasp(LOCALHASP_ENCODEDATA, SEEDCODE, 0, PASS1, PASS2, &p1, &p2, &p3, &p4);
	RETVAL = p3;
	sv_setpvn(data, buff, len);
	SvSETMAGIC(data);
	Safefree(buff);
    OUTPUT:
	RETVAL

int
Id(id)
	SV *id;
    PREINIT:
	int p1, p2, p3, p4;
    CODE:
	hasp(MEMOHASP_HASPID, SEEDCODE, 0, PASS1, PASS2, &p1, &p2, &p3, &p4);
	sv_setiv(id, p2*65536 + p1);
	SvSETMAGIC(id);
	RETVAL = p3;
    OUTPUT:
	RETVAL

int
ReadBlock(data, length, addr)
	int length;
	int addr;
	SV *data;
    PREINIT:
	int p1, p2, p3, p4;
	int r_a;
	char *buff;
    CODE:
	if(length < 0) length = 0;
	if(addr < 0) addr = 0;
	p1 = addr / sizeof(WORD); r_a = addr % sizeof(WORD);
	p2 = (length + r_a) / sizeof(WORD); p2 += (p2*sizeof(WORD) == (length + r_a)) ? 0 : 1;
	New(0, buff, p2 * sizeof(WORD), char); p4 = (int) buff;
	hasp(MEMOHASP_READBLOCK, SEEDCODE, 0, PASS1, PASS2, &p1, &p2, &p3, &p4);
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
	int p1, p2, p3, p4;
	char *tmp, *buff;
	STRLEN len;
	int r_a;
    CODE:
	if(addr < 0) addr = 0;
	tmp = SvPV(data, len);
	p1 = addr / sizeof(WORD); r_a = addr % sizeof(WORD);
	p2 = (len + r_a) / sizeof(WORD); p2 += (p2*sizeof(WORD) == (len + r_a)) ? 0 : 1;
	New(0, buff, p2 * sizeof(WORD), char); p4 = (int) buff;
	hasp(MEMOHASP_READBLOCK, SEEDCODE, 0, PASS1, PASS2, &p1, &p2, &p3, &p4);
	Copy(tmp, buff + r_a, len, char); p4 = (int) buff;
	hasp(MEMOHASP_WRITEBLOCK, SEEDCODE, 0, PASS1, PASS2, &p1, &p2, &p3, &p4);
	RETVAL = p3;
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

void
Init(p1, p2)
	int p1;
	int p2;
  CODE:
	PASS1 = p1;
	PASS2 = p2;