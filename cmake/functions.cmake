# Copyright 2016 The Cartographer Authors
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

include(CMakeParseArguments)
# 추가적으로 전달한 Arguments를 include

macro(_parse_arguments ARGS)
  set(OPTIONS)
  set(ONE_VALUE_ARG)
  set(MULTI_VALUE_ARGS SRCS)
  cmake_parse_arguments(ARG
    "${OPTIONS}" "${ONE_VALUE_ARG}" "${MULTI_VALUE_ARGS}" ${ARGS})
endmacro(_parse_arguments)
# _parse_arguments 이름의 매크로 생성
# ARGS를 인수로 받음
# TODO /// 뭔 뜻인지 모르겠음 ㅠㅠㅠㅠ

macro(_common_compile_stuff)
  set(TARGET_COMPILE_FLAGS "${TARGET_COMPILE_FLAGS} ${GOOG_CXX_FLAGS}")

  set_target_properties(${NAME} PROPERTIES
    COMPILE_FLAGS ${TARGET_COMPILE_FLAGS})

  target_include_directories(${NAME} PUBLIC ${PROJECT_NAME})
  target_link_libraries(${NAME} PUBLIC ${PROJECT_NAME})
endmacro(_common_compile_stuff)
# _common_compile_stuff 이름의 매크로 생성
# TARGET_COMPILE_FLAGS 라는 변수에 기존 TARGET_COMPILE_FLAGS와 GOOG_CXX_FLAGS를 할당
# NAME 변수 값의 TARGET에 대해 COMPILE_FLAG라는 속성을 TARGET_COMPILE_FLAGS로 설정
# NAME 변수 값의 TARGET에 PROJECT_NAME의 include directory로 추가
# NAME 변수 값의 TARGET에 PROJECT_NAME의 link_library 추가?
# TODO /// 이것도 뭔지 잘 모르겠음


function(google_test NAME ARG_SRC)
  add_executable(${NAME} ${ARG_SRC})
  _common_compile_stuff()

  # Make sure that gmock always includes the correct gtest/gtest.h.
  target_include_directories("${NAME}" SYSTEM PRIVATE
    "${GMOCK_INCLUDE_DIRS}")
  target_link_libraries("${NAME}" PUBLIC ${GMOCK_LIBRARIES})

  add_test(${NAME} ${NAME})
endfunction()
# google_test 이름의 함수 정의
# NAME ARG_SRC를 입력으로 받는 듯?
# 입력받은 ARG_SRC 파일로 NAME이름의 실행 파일 생성
# 위에서 정의한 _common_compile_stuff 실행
# Google Test를 수행하기 위해 GMOCK을 INCLUDE 및 Library 링크
# 테스트 추가 (? 어떤 의미인지 잘 모르겠음)
# TODO /// add_test 부분의 동작이 이해가 안됨

function(google_binary NAME)
  _parse_arguments("${ARGN}")

  add_executable(${NAME} ${ARG_SRCS})

  _common_compile_stuff()

  install(TARGETS "${NAME}" RUNTIME DESTINATION bin)
endfunction()
# google_binary 이름의 함수 정의
# NAME을 입력으로 받음
# ARG_SRCS를 이용하여 NAME이름의 실행 파일 생성
# _common_compile_stuff 실행
# 실행 가능한 파일을 bin 폴더에 설치 (복사)

# Create a variable 'VAR_NAME'='FLAG'. If VAR_NAME is already set, FLAG is
# appended.
function(google_add_flag VAR_NAME FLAG)
  if (${VAR_NAME})
    set(${VAR_NAME} "${${VAR_NAME}} ${FLAG}" PARENT_SCOPE)
  else()
    set(${VAR_NAME} "${FLAG}" PARENT_SCOPE)
  endif()
endfunction()
# google_add_flag 이름으 ㅣ함수 정의
# VAR_NAME이 존재할 경우, VAR_NAME을 VAR_NAME과 FLAG으로 설정, 부모에서 볼 수 있도록 설정
# VAR_NAME이 없는 경우, 단순히 VAR_NAME을 FLAG로 설정, 마찬가지로 부모에서 볼 수 있도록 설정

macro(google_initialize_cartographer_project)
  if(CARTOGRAPHER_CMAKE_DIR)
    set(CMAKE_MODULE_PATH ${CMAKE_MODULE_PATH}
        ${CARTOGRAPHER_CMAKE_DIR}/modules)
  else()
    set(CMAKE_MODULE_PATH ${CMAKE_MODULE_PATH}
        ${CMAKE_CURRENT_SOURCE_DIR}/cmake/modules)
  endif()

  if(WIN32)
    # TODO turn on equivalent warnings on Windows
  else()
    set(GOOG_CXX_FLAGS "-pthread -fPIC ${GOOG_CXX_FLAGS}")

    google_add_flag(GOOG_CXX_FLAGS "-Wall")
    google_add_flag(GOOG_CXX_FLAGS "-Wpedantic")

    # Turn some warnings into errors.
    google_add_flag(GOOG_CXX_FLAGS "-Werror=format-security")
    google_add_flag(GOOG_CXX_FLAGS "-Werror=missing-braces")
    google_add_flag(GOOG_CXX_FLAGS "-Werror=reorder")
    google_add_flag(GOOG_CXX_FLAGS "-Werror=return-type")
    google_add_flag(GOOG_CXX_FLAGS "-Werror=switch")
    google_add_flag(GOOG_CXX_FLAGS "-Werror=uninitialized")

    if (CMAKE_CXX_COMPILER_ID MATCHES "Clang" OR CMAKE_CXX_COMPILER_ID MATCHES "AppleClang")
      google_add_flag(GOOG_CXX_FLAGS "-Wthread-safety")
    endif()

    if(NOT CMAKE_BUILD_TYPE OR CMAKE_BUILD_TYPE STREQUAL "")
      set(CMAKE_BUILD_TYPE Release)
    endif()

    if(CMAKE_BUILD_TYPE STREQUAL "Release")
      google_add_flag(GOOG_CXX_FLAGS "-O3 -DNDEBUG")
    elseif(CMAKE_BUILD_TYPE STREQUAL "RelWithDebInfo")
      google_add_flag(GOOG_CXX_FLAGS "-O3 -g -DNDEBUG")
    elseif(CMAKE_BUILD_TYPE STREQUAL "Debug")
      if(FORCE_DEBUG_BUILD)
        message(WARNING "Building in Debug mode, expect very slow performance.")
        google_add_flag(GOOG_CXX_FLAGS "-g")
      else()
        message(FATAL_ERROR
          "Compiling in Debug mode is not supported and can cause severely degraded performance. "
          "You should change the build type to Release. If you want to build in Debug mode anyway, "
          "call CMake with -DFORCE_DEBUG_BUILD=True"
        )
      endif()
    # Support for Debian packaging CMAKE_BUILD_TYPE
    elseif(CMAKE_BUILD_TYPE STREQUAL "None")
      message(WARNING "Building with CMAKE_BUILD_TYPE None, "
          "please make sure you have set CFLAGS and CXXFLAGS according to your needs.")
    else()
      message(FATAL_ERROR "Unknown CMAKE_BUILD_TYPE: ${CMAKE_BUILD_TYPE}")
    endif()

    message(STATUS "Build type: ${CMAKE_BUILD_TYPE}")

    # Add a hook that reruns CMake when source files are added or removed.
    set(LIST_FILES_CMD "find ${PROJECT_SOURCE_DIR}/ -not -iwholename '*.git*' | sort | sed 's/^/#/'")
    set(FILES_LIST_PATH "${PROJECT_BINARY_DIR}/AllFiles.cmake")
    set(DETECT_CHANGES_CMD "bash" "-c" "${LIST_FILES_CMD} | diff -N -q ${FILES_LIST_PATH} - || ${LIST_FILES_CMD} > ${FILES_LIST_PATH}")
    add_custom_target(${PROJECT_NAME}_detect_changes ALL
      COMMAND ${DETECT_CHANGES_CMD}
      VERBATIM
    )
    if(NOT EXISTS ${FILES_LIST_PATH})
      execute_process(COMMAND ${DETECT_CHANGES_CMD})
    endif()
    include(${FILES_LIST_PATH})
  endif()
endmacro()

macro(google_enable_testing)
  enable_testing()
  find_package(GMock REQUIRED)
endmacro()
# google_enable_testing 이름의 매크로 생성
# 테스트를 추가하도록 하며, 이 경우 GMock 패키지를 필수적으로 검색