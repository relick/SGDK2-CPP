#include <cstddef>
#include <cstdint>
#include <new>

extern "C"
{
    void* MEM_alloc(uint16_t size);
    void MEM_free(void* ptr);
}

// new and delete wrap SGDK's memory management
void* operator new  (std::size_t size)                                 { return MEM_alloc(size); }
void* operator new[](std::size_t size)                                 { return operator new(size); }
void* operator new  (std::size_t size, std::nothrow_t const&) noexcept { return operator new(size); }
void* operator new[](std::size_t size, std::nothrow_t const&) noexcept { return operator new(size); }

void operator delete  (void* p)                        noexcept { MEM_free(p); }
void operator delete[](void* p)                        noexcept { operator delete(p); }
void operator delete  (void* p, std::nothrow_t const&) noexcept { operator delete(p); }
void operator delete  (void* p, std::size_t size)      noexcept { operator delete(p); }
void operator delete[](void* p, std::size_t size)      noexcept { operator delete(p); }
void operator delete[](void* p, std::nothrow_t const&) noexcept { operator delete(p); }

// Stub C++ ABI
void __cxa_pure_virtual() {}
void __cxa_atexit() {}
void __cxa_throw(void *thrown_exception, void *pvtinfo, void (*dest)(void *)) {}
