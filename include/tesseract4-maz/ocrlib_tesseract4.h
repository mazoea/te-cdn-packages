//
// author: jm (Mazoea s.r.o.)
// date: 2017
//
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

#include "ocrengine.h"
#include <memory>

namespace maz {
    namespace ocr {

        TESS_MAZ_API std::shared_ptr<engine> tesseract4();

    } // namespace
} // namespace
