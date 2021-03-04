cmake_minimum_required(VERSION 3.15)

set(SOLUTIONTITLE shrec CACHE TYPE STRING)

project(${SOLUTIONTITLE})

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED True)

file(GLOB FILES_SRC
        "src/*.cpp"
        "include/*.h"
        )
find_package(PCL REQUIRED)
#find_package(MathGeoLib REQUIRED)
find_package(libLAS REQUIRED)
#find_package( OpenCV REQUIRED )

add_executable(${SOLUTIONTITLE}   ${FILES_SRC} include/filenames.h include/utils.h)

include_directories( ${CMAKE_SOURCE_DIR}/include/)
include_directories( ${CMAKE_SOURCE_DIR})
include_directories( ${PCL_INCLUDE_DIRS} )

#include_directories(/home/stagakis/MathGeoLib/src)

message("\n =========================================================================")
message( ${PCL_INCLUDE_DIRS} )
message("\n =========================================================================")
message( ${PCL_DEFINITIONS} )
message("\n =========================================================================")
message( ${PCL_LIBRARY_DIRS} )
message("\n =========================================================================")
message( ${PCL_LIBRARIES} )
message("\n =========================================================================")

target_link_libraries( ${SOLUTIONTITLE}


        ${PCL_LIBRARIES}
        ${libLAS_LIBRARIES}
)


add_definitions( ${PCL_DEFINITIONS} )
add_definitions( -DPCL_NO_PRECOMPILE )
link_directories( ${PCL_LIBRARY_DIRS} )
