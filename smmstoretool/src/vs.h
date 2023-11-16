/* SPDX-License-Identifier: Apache-2.0 */

#ifndef SMMSTORETOOL__VS_H__
#define SMMSTORETOOL__VS_H__

#include <stdbool.h>

#include <UDK2017/MdePkg/Include/Uefi/UefiBaseType.h>

#include "utils.h"

// Variable store is part of firmware volume.  This unit doesn't deal with its
// header only with data that follows.

struct var_t {
    uint8_t reserved;
    uint32_t attrs;
    EFI_GUID guid;
    uint16_t *name;
    size_t name_size; // in bytes
    uint8_t *data;
    size_t data_size; // in bytes
    struct var_t *next;
};

struct var_store_t {
    struct var_t *vars;
    bool auth_vars;
};

struct var_store_t vs_load(struct mem_range_t vs_data, bool auth_vars);

bool vs_store(struct var_store_t *vs, struct mem_range_t vs_data);

struct var_t * vs_new_var(struct var_store_t *vs);

struct var_t * vs_find(struct var_store_t *vs,
                       const char name[],
                       const EFI_GUID *guid);

void vs_delete(struct var_store_t *vs, struct var_t *var);

void vs_free(struct var_store_t *vs);

#endif // SMMSTORETOOL__VS_H__
