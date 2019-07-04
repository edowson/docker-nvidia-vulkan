# CLion Multi-Module CMake Project

## Step 01.00: Createa a top-level container project

Create a top-level container project, with the following files:

File: `CMakeLists.txt`
```cmake
cmake_minimum_required(VERSION 3.5.0)

project(overview-cpp-11-14
        LANGUAGES CXX C
        VERSION 1.0.0.0)

# specify default install location
IF(CMAKE_INSTALL_PREFIX_INITIALIZED_TO_DEFAULT)
    SET(CMAKE_INSTALL_PREFIX "${CMAKE_BINARY_DIR}/install" CACHE PATH "Specify install location." FORCE)
ENDIF(CMAKE_INSTALL_PREFIX_INITIALIZED_TO_DEFAULT)

# defines CMAKE_INSTALL_LIBDIR, CMAKE_INSTALL_BINDIR and many other useful macros.
# see https://cmake.org/cmake/help/latest/module/GNUInstallDirs.html
include(GNUInstallDirs)

# control where libraries and executables are placed during the build.
# with the following settings executables are placed in <the top level of the
# build tree>/bin and libraries/archives in <top level of the build tree>/lib.
set(CMAKE_LIBRARY_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/${CMAKE_INSTALL_LIBDIR}")
set(CMAKE_ARCHIVE_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/${CMAKE_INSTALL_LIBDIR}")
set(CMAKE_RUNTIME_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/${CMAKE_INSTALL_BINDIR}")

# build position independent code.
set(CMAKE_POSITION_INDEPENDENT_CODE ON)

# disable C and C++ compiler extensions.
set(CMAKE_C_EXTENSIONS OFF)
set(CMAKE_CXX_EXTENSIONS OFF)

# include additional cmake modules
list(APPEND CMAKE_MODULE_PATH ${CMAKE_CURRENT_SOURCE_DIR}/cmake)

# options
option(BUILD_SHARED_LIBS "Build libraries as shared as opposed to static" ON)
option(BUILD_TESTING "Create tests using CMake" ON)

# enable RPATH support for installed binaries and libraries
include(AddInstallRPATHSupport)
add_install_rpath_support(
        BIN_DIRS "${CMAKE_INSTALL_FULL_BINDIR}"
        LIB_DIRS "${CMAKE_INSTALL_FULL_LIBDIR}"
        INSTALL_NAME_DIR "${CMAKE_INSTALL_FULL_LIBDIR}"
        USE_LINK_PATH)

# encourage user to specify a build type (e.g. Release, Debug, etc.), otherwise set it to Release.
if(NOT CMAKE_CONFIGURATION_TYPES)
    if(NOT CMAKE_BUILD_TYPE)
        message(STATUS "Setting build type to 'Release' as none was specified.")
        set_property(CACHE CMAKE_BUILD_TYPE PROPERTY VALUE "Release")
    endif()
endif()

# add subdirectories
add_subdirectory(src)

# add the uninstall target
include(AddUninstallTarget)

```

File: `Makefile`:
```make
default:
	[[ -d build ]] && rm -r build || true;
	mkdir build && cd build; cmake .. -DCMAKE_BUILD_TYPE=Debug -DCMAKE_INSTALL_PREFIX=../install -DBUILD_SHARED_LIBS=ON && make
```

Create the following folders:
```
cmake
doc
src
```

Inside the `src` folder, create a `CMakeLists.txt` file with the following contents
to add additional subdirectories:
```cmake
# add subdirectories
add_subdirectory(add)
add_subdirectory(add-app)
```

---

## Step 02.00: Create a library project

Create a subfolder `src\add` for the library project, and add the following files:

File: `add\CmakeLists.txt`
```
cmake_minimum_required(VERSION 3.5.0)
project(add
        LANGUAGES CXX C
        VERSION 1.0.0.0)

set(CMAKE_CXX_STANDARD 14)

set(LIBRARY_TARGET_NAME lib${PROJECT_NAME})

set(${LIBRARY_TARGET_NAME}_HDR
        include/add.hpp
        )

set(${LIBRARY_TARGET_NAME}_SRC
        src/add.cpp)

add_library(${LIBRARY_TARGET_NAME}
        ${${LIBRARY_TARGET_NAME}_SRC}
        ${${LIBRARY_TARGET_NAME}_HDR}
        )

add_library(${PROJECT_NAME}::${LIBRARY_TARGET_NAME}
        ALIAS ${LIBRARY_TARGET_NAME})

set_target_properties(${LIBRARY_TARGET_NAME} PROPERTIES
        VERSION ${${PROJECT_NAME}_VERSION}
        PUBLIC_HEADER ${${LIBRARY_TARGET_NAME}_HDR})

# specify include directories for both compilation and installation process.
target_include_directories(${LIBRARY_TARGET_NAME}
        PUBLIC
        "$<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/include>"
        "$<INSTALL_INTERFACE:$<INSTALL_PREFIX>/${CMAKE_INSTALL_INCLUDEDIR}>")

# Specify installation targets, typology and destination folders.
install(TARGETS ${LIBRARY_TARGET_NAME}
        EXPORT  ${PROJECT_NAME}
        LIBRARY       DESTINATION "${CMAKE_INSTALL_LIBDIR}"                            COMPONENT shlib
        ARCHIVE       DESTINATION "${CMAKE_INSTALL_LIBDIR}"                            COMPONENT lib
        RUNTIME       DESTINATION "${CMAKE_INSTALL_BINDIR}"                            COMPONENT bin
        PUBLIC_HEADER DESTINATION "${CMAKE_INSTALL_INCLUDEDIR}/${LIBRARY_TARGET_NAME}" COMPONENT dev)

if(BUILD_TESTING)
    add_subdirectory(test)
endif()

message(STATUS "Created target ${LIBRARY_TARGET_NAME} for export ${PROJECT_NAME}.")
```

File: `add/include/add.hpp`
```c++
#ifndef ADD
#define ADD

int add(int a, int b);

#endif
```


File: `add/src/add.cpp`
```c++
#include "add.hpp"

int add(int a, int b) {
    return (a + b);
}
```

---

Create a set of tests in the `add/test` folder:

File: `add/test/CMakeLists.txt`
```cmake
cmake_minimum_required(VERSION 3.5.0)

if(BUILD_TESTING)
    enable_testing()
endif()

find_package(Threads REQUIRED)
find_package(GTest REQUIRED)
include_directories(${GTEST_INCLUDE_DIRS})
if(NOT GTEST_LIBRARY)
    message(WARNING "gtest not found, download the library, build it and run cmake once again.")
    return()
endif()

set(CMAKE_CXX_STANDARD 14)

file(GLOB TEST_SRC_FILES *.cpp)

# from list of files we'll create tests test_name.cpp -> test_name
foreach(_test_file ${TEST_SRC_FILES})
    get_filename_component(_test_name ${_test_file} NAME_WE)
    add_executable(${_test_name} ${_test_file})
    target_link_libraries(${_test_name} GTest::GTest GTest::Main ${CMAKE_THREAD_LIBS_INIT})
    target_link_libraries(${_test_name} ${LIBRARY_TARGET_NAME})
    add_test(${_test_name} ${_test_name})
    set_tests_properties(${_test_name} PROPERTIES TIMEOUT 5)
endforeach()
```

File: `add/test/test-add.cpp`
```c++
#include <algorithm>
#include <numeric>
#include <unordered_map>
#include <unordered_set>
#include <vector>
#include "gtest/gtest.h"
#include "gmock/gmock.h"
#include "add.hpp"

using namespace std;

using ::testing::AllOf;
using ::testing::ElementsAre;
using ::testing::Ge;
using ::testing::Le;
using ::testing::MatchesRegex;
using ::testing::Pair;
using ::testing::StartsWith;

/*
 * Reference:
 * https://github.com/google/googletest/blob/master/googlemock/docs/CookBook.md
 * https://github.com/google/googletest/blob/master/googlemock/docs/CheatSheet.md
 */

GTEST_TEST(Add, Given){
    int a = 5;
    int b = 5;
    ASSERT_EQ(10, add(a, b));
}

GTEST_TEST(Add, Given2){
    int a = 0;
    int b = 5;
    ASSERT_EQ(5, add(a, b));
}

GTEST_TEST(Add, Given3){
    int a = -5;
    int b =  5;
    ASSERT_EQ(0, add(a, b));
}

GTEST_TEST(Add, Given4){
    int a = -1;
    int b = -1;
    ASSERT_EQ(-2, add(a, b));
}

GTEST_TEST(Add, Given5){
    int a = 0;
    int b = 0;
    ASSERT_EQ(0, add(a, b));
}
```

---

## Step 03.00: Create an executable project that uses the library project

Create a subfolder `src\add-app` for the executable project, and add the following files:

File: `add-app/CMakeLists.txt`
```cmake
cmake_minimum_required(VERSION 3.5.0)
project(add-app
        LANGUAGES CXX C
        VERSION 1.0.0.0)

set(CMAKE_CXX_STANDARD 14)

set(EXE_TARGET_NAME ${PROJECT_NAME})

# sources
set(${EXE_TARGET_NAME}_SRC
        src/main.cpp
        )

# specify executable
add_executable(${EXE_TARGET_NAME} ${${EXE_TARGET_NAME}_SRC})

# link executable with libraries
target_link_libraries(${EXE_TARGET_NAME} add::libadd)

# install target
install(TARGETS ${EXE_TARGET_NAME} DESTINATION bin)
```

File: `add-app/src/main.cpp`
```c++
#include <iostream>
#include "add.hpp"

int main( int argc, char* argv[] )
{
  std::cout << "Simple addition example" << std::endl;

  std::cout << "5 + 6 = " << add(5, 6) << std::endl;

  return(0);
}
```

---

## Tutorials

01. [ROS Setup Tutorial - JetBrains](https://www.jetbrains.com/help/clion/ros-setup-tutorial.html)

---

## Reference

01. [cmake-variables](https://cmake.org/cmake/help/latest/manual/cmake-variables.7.html)

---

## Repositories

01. [cmake-examples - github/ttroy50](https://github.com/ttroy50/cmake-examples)

02. [how-to-export-cpp-library - github/robotology](https://github.com/robotology/how-to-export-cpp-library.git)
