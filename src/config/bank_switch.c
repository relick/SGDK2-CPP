#include "config.h"
#include "mapper.h"

void* CONFIG_getFarDataWrapper(void* data)
{
#if (ENABLE_BANK_SWITCH != 0)
    return SYS_getFarData(data);
#else
    return data;
#endif
}

void* CONFIG_getFarDataSafeWrapper(void* data, u32 size)
{
#if (ENABLE_BANK_SWITCH != 0)
    return SYS_getFarDataSafe((void*)(data), size);
#else
    return data;
#endif
}
