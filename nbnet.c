#include <stdarg.h>
#include <stdio.h>

#ifdef NBNET_LOG

    #define LOG_FORMATED(_Log_Function_)\
    {\
        va_list args;\
        va_start(args, fmt);\
        vsnprintf(nbn_log_buffer, nbn_log_length, fmt, args);\
        va_end(args);\
        _Log_Function_(nbn_log_buffer);\
    }

    char* nbn_log_buffer;
    size_t nbn_log_length;

    char NBN_Log_Allocate_Buffer(size_t length);
    void NBN_Log_Free_Buffer();

    void _NBN_LogTrace(char* text);
    void _NBN_LogDebug(char* text);
    void _NBN_LogInfo(char* text);
    void _NBN_LogWarning(char* text);
    void _NBN_LogError(char* text);

    void NBN_LogTrace(const char* fmt, ...) LOG_FORMATED(_NBN_LogTrace)
    void NBN_LogDebug(const char* fmt, ...) LOG_FORMATED(_NBN_LogDebug)
    void NBN_LogInfo(const char* fmt, ...) LOG_FORMATED(_NBN_LogInfo)
    void NBN_LogWarning(const char* fmt, ...) LOG_FORMATED(_NBN_LogWarning)
    void NBN_LogError(const char* fmt, ...) LOG_FORMATED(_NBN_LogError)

#else

    #define NBN_LogTrace(...)
    #define NBN_LogDebug(...)
    #define NBN_LogInfo(...)
    #define NBN_LogWarning(...)
    #define NBN_LogError(...)

#endif

void* _NBN_Allocator(size_t _Size);
void* _NBN_Reallocator(void* _Block, size_t _Size);
void _NBN_Deallocator(void* _Block);

#define NBN_Allocator _NBN_Allocator
#define NBN_Reallocator _NBN_Reallocator
#define NBN_Deallocator _NBN_Deallocator

#define NBNET_IMPL
#include "../nbnet/nbnet.h"
#include "../nbnet/net_drivers/udp.h"

#ifdef NBNET_LOG

    char NBN_Log_Allocate_Buffer(size_t length)
    {
        nbn_log_buffer = NBN_Allocator(length);
        nbn_log_length = length;
        return nbn_log_buffer != NULL;
    }

    void NBN_Log_Free_Buffer()
    {
        if(nbn_log_buffer == NULL){return;}
        NBN_Deallocator(nbn_log_buffer);
    }

#endif