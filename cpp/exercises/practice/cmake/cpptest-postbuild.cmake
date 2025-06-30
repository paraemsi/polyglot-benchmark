# cpp/exercises/practice/cmake/cpptest-postbuild.cmake
# ====================================================
# Protect against double-include
if(DEFINED _CPPT_HOOK_LOADED)
    return()
endif()
set(_CPPT_HOOK_LOADED TRUE)

# Ensure compile_commands.json is emitted exactly once (top level picks it up)
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

# Find Parasoft
set(CPPTEST_HOME $ENV{CPPTEST_HOME})
if(NOT EXISTS "${CPPTEST_HOME}/cpptestcli")
    message(FATAL_ERROR "cpptestcli not found; export CPPTEST_HOME first")
endif()
set(_CPPTCLI "${CPPTEST_HOME}/cpptestcli")

# Attach a POST_BUILD analysis step to one executable
function(_cpptest_attach TARGET_NAME)
    # Avoid re-attaching if run twice in the same directory
    if(_cpptest_attached_${TARGET_NAME})
        return()
    endif()
    set(_cpptest_attached_${TARGET_NAME} TRUE PARENT_SCOPE)

    add_custom_command(TARGET ${TARGET_NAME} POST_BUILD
        COMMAND "${_CPPTCLI}"
                -input  "${CMAKE_BINARY_DIR}/compile_commands.json"
                -module "${TARGET_NAME}"
                -config "builtin://Recommended Rules"
                -report "${CMAKE_BINARY_DIR}/cpptest_reports/${TARGET_NAME}"
                -workspace "${CMAKE_BINARY_DIR}/cpptest_ws"
        COMMENT "Parasoft C/C++test → ${TARGET_NAME}"
        VERBATIM)
endfunction()

# Loop over **local** targets; hook every executable except those that start with 'test_'
get_property(_tgt_list DIRECTORY PROPERTY BUILDSYSTEM_TARGETS)
foreach(t IN LISTS _tgt_list)
    get_target_property(_kind ${t} TYPE)
    if(_kind STREQUAL "EXECUTABLE" AND NOT t MATCHES "^test_")
        _cpptest_attach(${t})
    endif()
endforeach()
