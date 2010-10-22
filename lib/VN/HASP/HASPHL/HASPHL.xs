#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "VNHASPHL.h"

#include "ppport.h"

#include "const-c.inc"

hasp_status_t	last_error;

void format_scope_string(char *scope) {
	if(product_id != 0) {
		if(hasp_id != 0)
			sprintf(scope, "<?xml version=\"1.0\" encoding=\"UTF-8\" ?><haspscope><hasp id=\"%d\" /><product id=\"%d\" /></haspscope>", hasp_id, product_id);
		else
			sprintf(scope, "<?xml version=\"1.0\" encoding=\"UTF-8\" ?><haspscope><product id=\"%d\" /></haspscope>", product_id);
	} else if(hasp_id != 0)
		sprintf(scope, "<?xml version=\"1.0\" encoding=\"UTF-8\" ?><haspscope><hasp id=\"%d\" /></haspscope>", hasp_id);
	else
		sprintf(scope, "<?xml version=\"1.0\" encoding=\"UTF-8\" ?><haspscope />");
}

MODULE = VN::HASP::HASPHL		PACKAGE = VN::HASP::HASPHL		

INCLUDE: const-xs.inc

int
LastError()
  CODE:
	RETVAL = last_error;
  OUTPUT:
	RETVAL

int
Attached()
  PREINIT:
	hasp_handle_t   handle;
	char scope[256];
  CODE:
	format_scope_string(scope);
	last_error = hasp_login_scope(feature_id, scope, (hasp_vendor_code_t *) vendor_code, &handle);
	if(last_error == HASP_STATUS_OK) last_error = hasp_logout(handle);
	RETVAL = last_error == HASP_STATUS_OK ? 1 : 0;
  OUTPUT: 
	RETVAL


int
EncodeData(data)
	SV *data;
  PREINIT:
        hasp_handle_t   handle;
	STRLEN len, len_full;
	char *tmp, *buff;
	char scope[256];
    CODE:
        tmp = SvPV(data, len);
	len_full = len < 16 ? 16 : len; 
        New(0, buff, len_full, char); Copy(tmp, buff, len, char);
	format_scope_string(scope);
	if((last_error = hasp_login_scope(feature_id, scope, (hasp_vendor_code_t *) vendor_code, &handle)) != HASP_STATUS_OK) {
		RETVAL = 0;
		goto quit;
	}
	if((last_error = hasp_encrypt(handle, (void *) buff, len_full)) != HASP_STATUS_OK) {
		hasp_logout(handle);
		RETVAL = 0;
		goto quit;
	}
	last_error = hasp_logout(handle);
	sv_setpvn(data, buff, len);
	SvSETMAGIC(data);
	RETVAL = (last_error == HASP_STATUS_OK) ? 1 : 0;
quit:
        Safefree(buff);
    OUTPUT:
        RETVAL

int
DecodeData(data)
	SV *data;
  PREINIT:
        hasp_handle_t   handle;
	STRLEN len, len_full;
	char *tmp, *buff;
	char scope[256];
    CODE:
        tmp = SvPV(data, len);
	len_full = len < 16 ? 16 : len; 
        New(0, buff, len_full, char); Copy(tmp, buff, len, char);
	format_scope_string(scope);
	if((last_error = hasp_login_scope(feature_id, scope, (hasp_vendor_code_t *) vendor_code, &handle)) != HASP_STATUS_OK) {
		RETVAL = 0;
		goto quit;
	}
	if((last_error = hasp_decrypt(handle, (void *) buff, len_full)) != HASP_STATUS_OK) {
		hasp_logout(handle);
		RETVAL = 0;
		goto quit;
	}
	last_error = hasp_logout(handle);
	sv_setpvn(data, buff, len);
	SvSETMAGIC(data);
	RETVAL = (last_error == HASP_STATUS_OK) ? 1 : 0;
quit:
        Safefree(buff);
    OUTPUT:
        RETVAL

int
GetHaspInfo(hasp_info)
	SV *hasp_info;
  PREINIT:
	char *info;
	char scope[256], view[1024];
    CODE:
	format_scope_string(scope);
	sprintf(view, "<haspformat root=\"hasp_info\">\n"
		"  <hasp>\n"
		"    <attribute name=\"id\" />\n"
		"    <attribute name=\"type\" />\n"
		"      <feature>\n"
		"        <attribute name=\"id\" />\n"
		"      </feature>\n"
		"  </hasp>\n"
		"</haspformat>\n");
	if((last_error = hasp_get_info(scope, view, vendor_code, &info)) == HASP_STATUS_OK) {
		sv_setpvn(hasp_info, info, strlen(info));
		SvSETMAGIC(hasp_info);
		hasp_free(info);
		RETVAL = 1;
	} else
		RETVAL = 0;
    OUTPUT:
        RETVAL

int ReadBlock(data, length, addr)
	SV *data;
	int length;
	int addr;
  PREINIT:
        hasp_handle_t   handle;
	char *buff;
	char scope[256];
  CODE:
	if(length < 0) length = 0;
	if(addr < 0) addr = 0;
        New(0, buff, length, char);
	format_scope_string(scope);
	if((last_error = hasp_login_scope(feature_id, scope, (hasp_vendor_code_t *) vendor_code, &handle)) != HASP_STATUS_OK) {
		RETVAL = 0;
		goto quit;
	}
	if((last_error = hasp_read(handle, HASP_FILEID_RW, addr, length, buff)) != HASP_STATUS_OK) {
		hasp_logout(handle);
		RETVAL = 0;
		goto quit;
	}
        last_error = hasp_logout(handle);
	sv_setpvn(data, buff, length);
	SvSETMAGIC(data);
        RETVAL = (last_error == HASP_STATUS_OK) ? 1 : 0;
quit:
	Safefree(buff);
  OUTPUT:
        RETVAL

int WriteBlock(data, addr)
	SV *data;
	int addr;
  PREINIT:
        hasp_handle_t   handle;
	char *buff;
	STRLEN len;
	char scope[256];
  CODE:
	if(addr < 0) addr = 0;
	buff = SvPV(data, len);
	format_scope_string(scope);
	if((last_error = hasp_login_scope(feature_id, scope, (hasp_vendor_code_t *) vendor_code, &handle)) != HASP_STATUS_OK) {
		RETVAL = 0;
		goto quit;
	}
	if((last_error = hasp_write(handle, HASP_FILEID_RW, addr, len, buff)) != HASP_STATUS_OK) {
		hasp_logout(handle);
		RETVAL = 0;
		goto quit;
	}
        last_error = hasp_logout(handle);
        RETVAL = (last_error == HASP_STATUS_OK) ? 1 : 0;
quit:
	Safefree(buff);
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
	hasp_time_t     time;
	unsigned int    day, month, year, hour, minute, second;
	hasp_handle_t   handle;
	char scope[256];
  CODE:
	format_scope_string(scope);
	if((last_error = hasp_login_scope(feature_id, scope, (hasp_vendor_code_t *) vendor_code, &handle)) != HASP_STATUS_OK) {
		RETVAL = 0;
		goto quit;
	}
	if((last_error = hasp_get_rtc(handle, &time)) != HASP_STATUS_OK) {
		hasp_logout(handle);
		RETVAL = 0;
		goto quit;
	}

	if((last_error = hasp_hasptime_to_datetime(time, &day, &month, &year,
                                         &hour, &minute, &second)) != HASP_STATUS_OK) {
		hasp_logout(handle);
		RETVAL = 0;
		goto quit;
	}
	sv_setiv(s, (IV) second);
	sv_setiv(min, (IV) minute);
	sv_setiv(h, (IV) hour);
	sv_setiv(d, (IV) day);
	sv_setiv(mon, (IV) month);
	sv_setiv(y, (IV) year);
	last_error = hasp_logout(handle);
        RETVAL = (last_error == HASP_STATUS_OK) ? 1 : 0;
quit:
  OUTPUT:
	RETVAL

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
	hasp_time_t     time_hasp, time_usr;
	hasp_handle_t   handle;
	char scope[256];
  CODE:
	format_scope_string(scope);
	if((last_error = hasp_login_scope(feature_id, scope, (hasp_vendor_code_t *) vendor_code, &handle)) != HASP_STATUS_OK) {
		RETVAL = 0;
		goto quit;
	}
	if((last_error = hasp_datetime_to_hasptime(d, mon, y ,h, min, s, &time_usr)) != HASP_STATUS_OK) {
		hasp_logout(handle);
		RETVAL = 0;
		goto quit;
	}
	if((last_error = hasp_get_rtc(handle, &time_hasp)) != HASP_STATUS_OK) {
		hasp_logout(handle);
		RETVAL = 0;
		goto quit;
	}
	if(time_hasp > time_usr) {
		sv_setiv(res, (IV) -1);
	} else if(time_hasp == time_usr) {
		sv_setiv(res, (IV) 0);
	} else {
		sv_setiv(res, (IV) 1);
	}
	last_error = hasp_logout(handle);
        RETVAL = (last_error == HASP_STATUS_OK) ? 1 : 0;
quit:
  OUTPUT:
	RETVAL

void
Init(vcode)
	char *vcode;
  CODE:
	strcpy(vendor_code, vcode);

void
SetFID(fid)
	unsigned int fid;
  CODE:
	feature_id = fid;

void
SetPID(pid)
	unsigned int pid;
  CODE:
	product_id = pid;

void
SetHID(hid)
	unsigned int hid;
  CODE:
	hasp_id = hid;
