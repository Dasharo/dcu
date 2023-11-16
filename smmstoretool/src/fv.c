/* SPDX-License-Identifier: Apache-2.0 */

#include "fv.h"

#include <assert.h>
#include <stdbool.h>
#include <stdint.h>
#include <stdio.h>
#include <string.h>

#include <UDK2017/MdePkg/Include/Uefi/UefiBaseType.h>
#include <UDK2017/MdePkg/Include/Uefi/UefiMultiPhase.h>
#include <UDK2017/MdePkg/Include/Pi/PiFirmwareVolume.h>
#include <UDK2017/MdeModulePkg/Include/Guid/VariableFormat.h>

static const EFI_GUID EfiVariableGuid = EFI_VARIABLE_GUID;

static const EFI_GUID EfiAuthenticatedVariableGuid =
    EFI_AUTHENTICATED_VARIABLE_GUID;

static const EFI_GUID EfiSystemNvDataFvGuid = {
    0xfff12b8d, 0x7696, 0x4c8b,
    { 0xa9, 0x85, 0x27, 0x47, 0x07, 0x5b, 0x4f, 0x50 }
};

static uint16_t calc_checksum(const uint16_t *hdr, size_t size)
{
    assert(size%2 == 0 && "Header can't have odd length.");

    uint16_t checksum = 0;
    for (size_t i = 0; i < size/2; ++i)
        checksum += hdr[i];
    return checksum;
}

bool
fv_init(struct mem_range_t fv)
{
    // UEFI uses this block size, might not be the only option.
    enum { BLOCK_SIZE = 64*1024 };

    if (fv.length%BLOCK_SIZE != 0) {
        fprintf(stderr, "Firmware Volume size is not a multiple of 64KiB\n");
        return false;
    }

    memset(fv.start, 0xff, fv.length);

    const EFI_FIRMWARE_VOLUME_HEADER vol_hdr = {
        .FileSystemGuid = EfiSystemNvDataFvGuid,
        .FvLength = fv.length,
        .Signature = EFI_FVH_SIGNATURE,
        .Attributes = EFI_FVB2_READ_ENABLED_CAP
                    | EFI_FVB2_READ_STATUS
                    | EFI_FVB2_WRITE_ENABLED_CAP
                    | EFI_FVB2_WRITE_STATUS
                    | EFI_FVB2_STICKY_WRITE
                    | EFI_FVB2_MEMORY_MAPPED
                    | EFI_FVB2_ERASE_POLARITY,
        .HeaderLength = sizeof(vol_hdr) + sizeof(EFI_FV_BLOCK_MAP_ENTRY),
        .Revision = EFI_FVH_REVISION,
        .BlockMap[0] = {
            .NumBlocks = fv.length/BLOCK_SIZE,
            .Length = BLOCK_SIZE,
        },
    };

    EFI_FIRMWARE_VOLUME_HEADER *vol_hdr_dst = (void *)fv.start;
    *vol_hdr_dst = vol_hdr;
    vol_hdr_dst->BlockMap[1].NumBlocks = 0;
    vol_hdr_dst->BlockMap[1].Length = 0;

    vol_hdr_dst->Checksum =
        ~calc_checksum((const void *)vol_hdr_dst, vol_hdr.HeaderLength);
    ++vol_hdr_dst->Checksum;

    const VARIABLE_STORE_HEADER var_store_hdr = {
        // Not using authentication fields, but UEFI creates the store like
        // this.
        .Signature = EfiAuthenticatedVariableGuid,
        // Even with CONFIG_SMMSTORE_SIZE=0x40000, it ends up being 64 KiB and
        // EDK2 reformats the store on size mismatch.
        .Size = BLOCK_SIZE - vol_hdr.HeaderLength,
        .Format = VARIABLE_STORE_FORMATTED,
        .State = VARIABLE_STORE_HEALTHY,
    };

    VARIABLE_STORE_HEADER *var_store_hdr_dst =
        (void *)(fv.start + vol_hdr.HeaderLength);
    *var_store_hdr_dst = var_store_hdr;

    return true;
}

static bool guid_eq(const EFI_GUID *lhs, const EFI_GUID *rhs)
{
    return memcmp(lhs, rhs, sizeof(*lhs)) == 0;
}

static bool check_fw_vol_hdr(const EFI_FIRMWARE_VOLUME_HEADER *hdr,
                             size_t max_size)
{
    if (hdr->Revision != EFI_FVH_REVISION ||
        hdr->Signature != EFI_FVH_SIGNATURE ||
        hdr->FvLength > max_size ||
        hdr->HeaderLength > max_size ||
        hdr->HeaderLength%2 != 0) {
        fprintf(stderr, "No firmware volume header present\n");
        return false;
    }

    if (!guid_eq(&hdr->FileSystemGuid, &EfiSystemNvDataFvGuid)) {
        fprintf(stderr, "Firmware volume GUID non-compatible\n");
        return false;
    }

    uint16_t checksum = calc_checksum((const void *)hdr, hdr->HeaderLength);
    if (checksum != 0) {
        fprintf(stderr, "Firmware Volume checksum is non-zero: 0x%04X\n",
                checksum);
        return false;
    }

    return true;
}

static bool check_var_store_hdr(const VARIABLE_STORE_HEADER *hdr,
                                size_t max_size,
                                bool *auth_vars)
{
    *auth_vars = guid_eq(&hdr->Signature, &EfiAuthenticatedVariableGuid);
    if (!*auth_vars && !guid_eq(&hdr->Signature, &EfiVariableGuid)) {
        fprintf(stderr, "Variable store has unexpected GUID\n");
        return false;
    }

    if (hdr->Size > max_size) {
        fprintf(stderr, "Variable store size is too large: %zu > %zu\n",
                (size_t)hdr->Size, max_size);
        return false;
    }

    if (hdr->Format != VARIABLE_STORE_FORMATTED) {
        fprintf(stderr, "Variable store is not formatted\n");
        return false;
    }

    if (hdr->State != VARIABLE_STORE_HEALTHY) {
        fprintf(stderr, "Variable store is not in a healthy state\n");
        return false;
    }

    return true;
}


bool
fv_parse(struct mem_range_t fv, struct mem_range_t *var_store, bool *auth_vars)
{
    const EFI_FIRMWARE_VOLUME_HEADER *vol_hdr = (void *)fv.start;
    if (!check_fw_vol_hdr(vol_hdr, fv.length)) {
        fprintf(stderr, "No valid firmware volume was found\n");
        return false;
    }

    uint8_t *fw_vol_data = fv.start + vol_hdr->HeaderLength;
    size_t volume_size = fv.length - vol_hdr->HeaderLength;
    const VARIABLE_STORE_HEADER *var_store_hdr = (void *)fw_vol_data;
    if (!check_var_store_hdr(var_store_hdr, volume_size, auth_vars)) {
        fprintf(stderr, "No valid variable store was found");
        return false;
    }

    var_store->start = fw_vol_data + sizeof(*var_store_hdr);
    var_store->length = volume_size - sizeof(*var_store_hdr);
    return true;
}
