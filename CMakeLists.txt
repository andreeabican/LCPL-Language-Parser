project(lcpl-parser CXX)

cmake_minimum_required(VERSION 3.4.3)

include(CheckCXXCompilerFlag)
set(CXX11_FLAG "-std=c++11" CACHE STRING "Compiler flag to enable C++ 11")
CHECK_CXX_COMPILER_FLAG(${CXX11_FLAG} HAVE_CXX11)
if (HAVE_CXX11)
  add_definitions(${CXX11_FLAG})
else()
  message(FATAL_ERROR
    "The compiler doesn't seem to have C++ 11 support (try setting the C++11 flag manually?)")
endif()

set(INCLUDE_DIR include)
include_directories(${INCLUDE_DIR})

set(BISON_OUTPUT lcpl.tab.cpp)
set(BISON_HEADER_OUTPUT lcpl.tab.hpp)
add_custom_command(
  OUTPUT ${BISON_HEADER_OUTPUT} ${BISON_OUTPUT}
  COMMAND bison -d ${CMAKE_CURRENT_SOURCE_DIR}/lcpl.y -o ${BISON_OUTPUT}
  DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/lcpl.y
  )

set(FLEX_OUTPUT lex.yy.cpp)
add_custom_command(
  OUTPUT ${FLEX_OUTPUT}
  COMMAND flex -o ${FLEX_OUTPUT} ${CMAKE_CURRENT_SOURCE_DIR}/lcpl.l
  DEPENDS ${BISON_OUTPUT} ${CMAKE_CURRENT_SOURCE_DIR}/lcpl.l
  )

set(PARSER_FILES
  ${FLEX_OUTPUT}

  ${BISON_HEADER_OUTPUT}
  ${BISON_OUTPUT}
  )

add_subdirectory(lcpl-AST)

include_directories(lcpl-AST/include)

add_executable(lcpl-parser ${PARSER_FILES})
target_link_libraries(lcpl-parser lcpl-ast)
