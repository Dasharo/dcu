/* SPDX-License-Identifier: Apache-2.0 */

#ifndef SMMSTORETOOL__UTILS_H__
#define SMMSTORETOOL__UTILS_H__

#include <stddef.h>
#include <stdbool.h>
#include <stdint.h>

#define ARRAY_SIZE(array) (sizeof(array)/sizeof((array)[0]))

struct mem_range_t {
    uint8_t *start;
    size_t length;
};

void * xmalloc(size_t size);

char * to_chars(const uint16_t uchars[], size_t size);

uint16_t * to_uchars(const char chars[], size_t *size);

bool str_eq(const char lhs[], const char rhs[]);

struct mem_range_t map_file(const char path[], bool rw);

void unmap_file(struct mem_range_t store);

#endif // SMMSTORETOOL__UTILS_H__
