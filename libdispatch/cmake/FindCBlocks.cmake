# Components: private_headers, compiler_support

include (FindPackageHandleStandardArgs)
include (CheckFunctionExists)

# Find GNUstep Local and System domain header locations (e.g. /System/Library/Headers or /usr/include, etc.)

find_program(GNUSTEP_CONFIG gnustep-config)

if (GNUSTEP_CONFIG)
  EXEC_PROGRAM(gnustep-config
    ARGS "--variable=GNUSTEP_SYSTEM_HEADERS"
    OUTPUT_VARIABLE GNUSTEP_SYSTEM_INCLUDE_PATH)
  EXEC_PROGRAM(gnustep-config
    ARGS "--variable=GNUSTEP_LOCAL_HEADERS"
    OUTPUT_VARIABLE GNUSTEP_LOCAL_INCLUDE_PATH)
  EXEC_PROGRAM(gnustep-config
    ARGS "--variable=GNUSTEP_SYSTEM_LIBRARIES"
    OUTPUT_VARIABLE GNUSTEP_SYSTEM_LIBRARY_PATH)
  EXEC_PROGRAM(gnustep-config
    ARGS "--variable=GNUSTEP_LOCAL_LIBRARIES"
    OUTPUT_VARIABLE GNUSTEP_LOCAL_LIBRARY_PATH)
endif ()

message(STATUS "Found GNUstep include paths: ${GNUSTEP_SYSTEM_INCLUDE_PATH} and ${GNUSTEP_LOCAL_INCLUDE_PATH}")

# Determine whether GNUstep Objective-C runtime exists

message(STATUS "Looking for libobjc.so.4 in ${GNUSTEP_SYSTEM_LIBRARY_PATH} and ${GNUSTEP_LOCAL_LIBRARY_PATH}")

# NOTE: CMake doesn't support matching a precise library version e.g.
# find_library(GNUSTEP_LIBOBJC NAMES libobjc.so.4* 
#   PATHS ${GNUSTEP_LOCAL_LIBRARY_PATH} ${GNUSTEP_SYSTEM_LIBRARY_PATH})
file(GLOB SO_FILES ${GNUSTEP_LOCAL_LIBRARY_PATH}/libobjc.so.4* ${GNUSTEP_SYSTEM_LIBRARY_PATH}/libobjc.so.4*)

foreach(file ${SO_FILES})
  find_library(GNUSTEP_LIBOBJC "objc"
    PATHS ${GNUSTEP_LOCAL_LIBRARY_PATH} ${GNUSTEP_SYSTEM_LIBRARY_PATH}
  )
endforeach ()

message(STATUS "Found GNUstep libobjc: ${GNUSTEP_LIBOBJC}")

# Find block support headers from GNUstep Objective-C runtime or libBlocksRuntime

if (GNUSTEP_LIBOBJC)
  find_path(CBLOCKS_PUBLIC_INCLUDE_DIR objc/blocks_runtime.h 
    PATHS ${GNUSTEP_LOCAL_INCLUDE_PATH} ${GNUSTEP_SYSTEM_INCLUDE_PATH} 
    DOC "Path to blocks_runtime.h"
  )
else ()
  find_path(CBLOCKS_PUBLIC_INCLUDE_DIR Block.h DOC "Path to Block.h")
endif ()

if (CBLOCKS_PUBLIC_INCLUDE_DIR)
  list (APPEND CBLOCKS_INCLUDE_DIRS ${CBLOCKS_PUBLIC_INCLUDE_DIR})
endif ()

if (GNUSTEP_LIBOBJC)
  find_path(CBLOCKS_PRIVATE_INCLUDE_DIR objc/blocks_private.h 
    PATHS ${GNUSTEP_LOCAL_INCLUDE_PATH} ${GNUSTEP_SYSTEM_INCLUDE_PATH} 
    DOC "Path to blocks_private.h"
  )
else ()
  find_path(CBLOCKS_PRIVATE_INCLUDE_DIR Block_private.h)
endif ()

if (CBLOCKS_PRIVATE_INCLUDE_DIR)
  list (APPEND CBLOCKS_INCLUDE_DIRS ${CBLOCKS_PRIVATE_INCLUDE_DIR})
  set (CBlocks_private_headers_FOUND TRUE)  # for FPHSA
  set (CBLOCKS_PRIVATE_HEADERS_FOUND TRUE)  # for everyone else
endif ()

# Determine library providing block runtime support

check_function_exists(CBLOCKS_RUNTIME_IN_LIBC _Block_copy)

if (CBLOCKS_RUNTIME_IN_LIBC)
  set (CBLOCKS_LIBRARIES " ")
else ()
  if (GNUSTEP_LIBOBJC)
    find_library(CBLOCKS_LIBRARIES "objc"
      PATHS ${GNUSTEP_LOCAL_LIBRARY_PATH} ${GNUSTEP_SYSTEM_LIBRARY_PATH}
    )
    add_definitions(-DBLOCKS_RUNTIME_FROM_LIBOBJC)
  else ()
    find_library(CBLOCKS_LIBRARIES "BlocksRuntime")
  endif ()
endif ()

check_c_compiler_flag("-fblocks" CBLOCKS_COMPILER_SUPPORT_FOUND)
if (CBLOCKS_COMPILER_SUPPORT_FOUND)
  set (CBLOCKS_COMPILE_FLAGS "-fblocks")
  set (CBlocks_compiler_support_FOUND TRUE)  # for FPHSA
endif ()

find_package_handle_standard_args(CBlocks
  REQUIRED_VARS CBLOCKS_PUBLIC_INCLUDE_DIR
  HANDLE_COMPONENTS
)

