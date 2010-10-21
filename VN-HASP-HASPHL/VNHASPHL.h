#include <stdio.h>
#include <stdlib.h>
#include <assert.h>
#include "hasp/hasp_api.h"

#include "hasp_vcode.h"

/* Debug level.
	0 - no debug info,
	1 - minimal debug info,
	2 - normal debug info */

#define DEBUGINFOLEVEL 0

/* If defined, turns on asserts, etc */

// #define DEBUG_THIS_MODULE

#ifdef WIN32

#include <windows.h>

#else  /* unix */

#include <unistd.h>
#include <errno.h>

#define WORD signed short

#endif

#ifdef DEBUG_THIS_MODULE
#define ASSERT(q) if(!(q)) printf ("ASSERT FAILED! %s\n", #q)
#else
#define ASSERT(q) ;
#endif

#if DEBUGINFOLEVEL > 1

#define DEBUG2(q,z)	debug(q,z)
#define DEBUG1(q,z)	debug(q,z)

#else

#define DEBUG2(q,z) ;
#if DEBUGINFOLEVEL > 0
#define DEBUG1(q,z)	debug(q,z)
#else
#define DEBUG1(q,z) ;
#endif

#endif