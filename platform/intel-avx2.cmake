### Intel Compiler for Haswell, Broadwell...
set(TARGET_SUFFIX               ".cpu")

set(ARCH                        "-xCORE-AVX2")
set(OPENMP_FLAGS                "-qopenmp")
set(LAPACK_FLAGS                "-mkl=parallel")
set(ADDITIONAL_MACRO            "")
set(ADDITIONAL_OPTIMIZE_FLAGS   "")

set(Fortran_FLAGS_General       "-fpp -nogen-interface -std90 -warn all -diag-disable 6187,6477,6916,7025,7416")
set(C_FLAGS_General             "-Wall")

set(Fortran_FLAGS_STENCIL       "-ansi-alias -fno-alias")
set(C_FLAGS_STENCIL             "-restrict -ansi-alias -fno-alias")

set(CMAKE_Fortran_COMPILER      "mpiifort")
set(CMAKE_Fortran_FLAGS_DEBUG   "-O2 -g")
set(CMAKE_Fortran_FLAGS_RELEASE "-O3")
set(CMAKE_C_COMPILER            "mpiicc")
set(CMAKE_C_FLAGS_DEBUG         "-O2 -g")
set(CMAKE_C_FLAGS_RELEASE       "-O3")

set(ENABLE_REDUCE_FOR_MANYCORE 1)


########
# CMake Platform-specific variables
########
set(CMAKE_SYSTEM_NAME "Linux" CACHE STRING "Cross-compiling for Intel Haswell, Broadwell... (AVX2)")
set(CMAKE_SYSTEM_PROCESSOR "avx2")
