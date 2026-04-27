#ifndef TITANOX_H
#define TITANOX_H

#include <stddef.h>

#ifdef __cplusplus
extern "C" {
#endif

// Titanox Hooking API
// This is a header definition for the Titanox hooking framework.
// libtitanox.dylib must be linked at build time.

void TITANOX_HOOK_FUNCTION(void *target, void *replacement, void **original);

#ifdef __cplusplus
}
#endif

#endif
