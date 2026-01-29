# generated from ament/cmake/core/templates/nameConfig.cmake.in

# prevent multiple inclusion
if(_pca_drive_CONFIG_INCLUDED)
  # ensure to keep the found flag the same
  if(NOT DEFINED pca_drive_FOUND)
    # explicitly set it to FALSE, otherwise CMake will set it to TRUE
    set(pca_drive_FOUND FALSE)
  elseif(NOT pca_drive_FOUND)
    # use separate condition to avoid uninitialized variable warning
    set(pca_drive_FOUND FALSE)
  endif()
  return()
endif()
set(_pca_drive_CONFIG_INCLUDED TRUE)

# output package information
if(NOT pca_drive_FIND_QUIETLY)
  message(STATUS "Found pca_drive: 0.0.0 (${pca_drive_DIR})")
endif()

# warn when using a deprecated package
if(NOT "" STREQUAL "")
  set(_msg "Package 'pca_drive' is deprecated")
  # append custom deprecation text if available
  if(NOT "" STREQUAL "TRUE")
    set(_msg "${_msg} ()")
  endif()
  # optionally quiet the deprecation message
  if(NOT ${pca_drive_DEPRECATED_QUIET})
    message(DEPRECATION "${_msg}")
  endif()
endif()

# flag package as ament-based to distinguish it after being find_package()-ed
set(pca_drive_FOUND_AMENT_PACKAGE TRUE)

# include all config extra files
set(_extras "")
foreach(_extra ${_extras})
  include("${pca_drive_DIR}/${_extra}")
endforeach()
