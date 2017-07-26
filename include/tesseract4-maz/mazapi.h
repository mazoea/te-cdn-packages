#pragma once

#if defined(_WIN32) || defined(__CYGWIN__)
    #if defined(TESS_MAZ_EXPORTS)
        #define TESS_MAZ_API __declspec(dllexport)
    #elif defined(TESS_MAZ_IMPORTS)
        #define TESS_MAZ_API __declspec(dllimport)
    #else
        #define TESS_MAZ_API
    #endif
#else
    #if defined(TESS_MAZ_EXPORTS) || defined(TESS_MAZ_IMPORTS)
        #define TESS_MAZ_API  __attribute__ ((visibility ("default")))
    #else
        #define TESS_MAZ_API
    #endif
#endif


#include <string>

namespace maz
{
    class TESS_MAZ_API ocrengine
    {
    
    public:
        void version(std::string& s);

    };

}