/**
 * by Mazoea s.r.o.
 */
#pragma once

// tesseract 3.01, 3.02 support
#ifndef EXPAND
#define DO_EXPAND(VAL) VAL##1
#define EXPAND(VAL) DO_EXPAND(VAL)
#define STRINGIFY(x) #x
#define TOSTRING STRINGIFY(x)
#endif

#if !defined(_TESS_VERSION) || (1 == EXPAND(_TESS_VERSION))
#if defined(_TESS_VERSION)
#undef _TESS_VERSION
#endif
#define _TESS_VERSION 301
#endif

// tesseract define __MSW32__ always
#if defined(_WINDOWS) || defined(_WIN32)
#ifndef __MSW32__
#define __MSW32__
#endif
#endif

// tesseract
#ifdef _WINDOWS
#pragma warning(push)
#pragma warning(disable : 4389 05)
#pragma warning(disable : 4244)
#pragma warning(disable : 4267)
#pragma warning(disable : 4458)
#endif

#include <baseapi.h>
#include <ocrclass.h>
#include <osdetect.h>
#include <pageiterator.h>
#include <resultiterator.h>

#ifdef _WINDOWS
#pragma warning(pop)
#endif
