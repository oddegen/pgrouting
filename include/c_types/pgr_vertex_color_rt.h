/*PGR-GNU*****************************************************************
File: pgr_vertex_color_rt.h

Copyright (c) 2020 Ashish Kumar
Mail: ashishkr23438@gmail.com
------

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.

 ********************************************************************PGR-GNU*/
/*! @file */

#ifndef INCLUDE_C_TYPES_PGR_VERTEX_COLOR_RT_H_
#define INCLUDE_C_TYPES_PGR_VERTEX_COLOR_RT_H_
#pragma once

/* for int64_t */
#ifdef __cplusplus
#   include <cstdint>
#else
#   include <stdint.h>
#endif

typedef struct {
    int64_t node;
    int64_t color;
} pgr_vertex_color_rt;

#endif  // INCLUDE_C_TYPES_PGR_VERTEX_COLOR_RT_H_
