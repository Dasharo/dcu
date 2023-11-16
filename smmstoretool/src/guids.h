/* SPDX-License-Identifier: Apache-2.0 */

#ifndef SMMSTORETOOL__GUIDS_H__
#define SMMSTORETOOL__GUIDS_H__

#include <stdbool.h>

#include <UDK2017/MdePkg/Include/Uefi/UefiBaseType.h>

#define GUID_LEN 35

struct guid_alias_t {
    const char *alias;
    EFI_GUID guid;
};

extern struct guid_alias_t known_guids[];

extern const int known_guid_count;

char * format_guid(const EFI_GUID *guid, bool use_alias);

bool parse_guid(const char str[], EFI_GUID *guid);

#endif // SMMSTORETOOL__GUIDS_H__
