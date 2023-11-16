/* SPDX-License-Identifier: Apache-2.0 */

#include <unistd.h>

#include <ctype.h>
#include <errno.h>
#include <limits.h>
#include <stdbool.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include <UDK2017/MdePkg/Include/Uefi/UefiBaseType.h>

#include "guids.h"
#include "storage.h"
#include "vs.h"

enum data_type {
    DATA_TYPE_BOOL,
    DATA_TYPE_UINT8,
    DATA_TYPE_ASCII,
    DATA_TYPE_UNICODE,
    DATA_TYPE_RAW,
};

struct subcommand_t {
    const char *name;
    const char *description;
    void (*print_help)(FILE *f, const struct subcommand_t *info);
    int (*process)(int argc, char *argv[], const char store_file[]);
};

static void help_get(FILE *f, const struct subcommand_t *info);
static void help_guids(FILE *f, const struct subcommand_t *info);
static void help_help(FILE *f, const struct subcommand_t *info);
static void help_list(FILE *f, const struct subcommand_t *info);
static void help_remove(FILE *f, const struct subcommand_t *info);
static void help_set(FILE *f, const struct subcommand_t *info);
static int process_get(int argc, char *argv[], const char store_file[]);
static int process_guids(int argc, char *argv[], const char store_file[]);
static int process_help(int argc, char *argv[], const char store_file[]);
static int process_list(int argc, char *argv[], const char store_file[]);
static int process_remove(int argc, char *argv[], const char store_file[]);
static int process_set(int argc, char *argv[], const char store_file[]);

static const struct subcommand_t sub_commands[] = {
    {
        .name = "get",
        .description = "display current value of a variable",
        .print_help = &help_get,
        .process = &process_get,
    },
    {
        .name = "guids",
        .description = "show GUID to alias mapping",
        .print_help = &help_guids,
        .process = &process_guids,
    },
    {
        .name = "help",
        .description = "provide built-in help",
        .print_help = &help_help,
        .process = &process_help,
    },
    {
        .name = "list",
        .description = "list variables present in the store",
        .print_help = &help_list,
        .process = &process_list,
    },
    {
        .name = "remove",
        .description = "remove a variable from the store",
        .print_help = &help_remove,
        .process = &process_remove,
    },
    {
        .name = "set",
        .description = "add or updates a variable in the store",
        .print_help = &help_set,
        .process = &process_set,
    },
};

static const int sub_command_count = ARRAY_SIZE(sub_commands);

static const char *USAGE_FMT = "Usage: %s smm-store-file sub-command\n"
                               "       %s -h|--help\n";

static const char *program_name;

// The parameter can be NULL.
static void print_usage(const char sub_command[])
{
    if (sub_command == NULL) {
        fprintf(stderr, USAGE_FMT, program_name, program_name);
        exit(EXIT_FAILURE);
    }

    fprintf(stderr, "\n");
    fprintf(stderr, USAGE_FMT, program_name, program_name);
    fprintf(stderr, "\n");

    for (int i = 0; i < sub_command_count; ++i) {
        const struct subcommand_t *cmd = &sub_commands[i];
        if (!str_eq(cmd->name, sub_command))
            continue;

        cmd->print_help(stderr, cmd);
        break;
    }

    exit(EXIT_FAILURE);
}

static void print_help(void)
{
    printf(USAGE_FMT, program_name, program_name);

    printf("\n");
    printf("Sub-commands:\n");
    for (int i = 0; i < sub_command_count; ++i) {
        const struct subcommand_t *cmd = &sub_commands[i];
        printf(" * %-6s - %s\n", cmd->name, cmd->description);
    }
}

static void print_data(const uint8_t data[],
                       size_t data_size,
                       enum data_type type)
{
    if (data_size == 0)
        return;

    switch (type) {
        case DATA_TYPE_BOOL:
            bool value = false;
            for (size_t i = 0; i < data_size; ++i) {
                if (data[i] != 0) {
                    value = true;
                    break;
                }
            }
            printf("%s\n", value ? "true" : "false");
            break;
        case DATA_TYPE_UINT8:
            if (data_size != 1) {
                fprintf(stderr, "warning: expected size of 1, got %zu\n",
                        data_size);
            }

            printf("%u\n", data[0]);
            break;
        case DATA_TYPE_ASCII:
            for (size_t i = 0; i < data_size; ++i) {
                char c = data[i];
                if (isprint(c))
                    printf("%c", c);
            }
            printf("\n");
            break;
        case DATA_TYPE_UNICODE:
            char *chars = to_chars((const uint16_t *)data, data_size);
            printf("%s\n", chars);
            free(chars);
            break;
        case DATA_TYPE_RAW:
            fwrite(data, 1, data_size, stdout);
            break;
    }
}

static void * make_data(const char source[],
                        size_t *data_size,
                        enum data_type type)
{
    switch (type) {
        uint8_t *data;

        case DATA_TYPE_BOOL:
            bool boolean;
            if (str_eq(source, "true")) {
                boolean = true;
            } else if (str_eq(source, "false")) {
                boolean = false;
            } else {
                fprintf(stderr, "Invalid boolean value: \"%s\"\n", source);
                return NULL;
            }

            *data_size = 1;
            data = xmalloc(*data_size);
            data[0] = boolean;
            return data;
        case DATA_TYPE_UINT8:
            char *end;
            unsigned long long uint8 = strtoull(source, &end, /*base=*/0);
            if (uint8 > UINT8_MAX) {
                fprintf(stderr, "Invalid uint8 value: %llu\n", uint8);
                return NULL;
            }

            *data_size = 1;
            data = xmalloc(*data_size);
            data[0] = uint8;
            return data;
        case DATA_TYPE_ASCII:
            *data_size = strlen(source) + 1;
            return strdup(source);
        case DATA_TYPE_UNICODE:
            return to_uchars(source, data_size);
        case DATA_TYPE_RAW:
            fprintf(stderr, "Raw data type is output only\n");
            return NULL;
    }

    return NULL;
}

static bool parse_data_type(const char str[], enum data_type *type)
{
    if (str_eq(str, "bool"))
        *type = DATA_TYPE_BOOL;
    else if (str_eq(str, "uint8"))
        *type = DATA_TYPE_UINT8;
    else if (str_eq(str, "ascii"))
        *type = DATA_TYPE_ASCII;
    else if (str_eq(str, "unicode"))
        *type = DATA_TYPE_UNICODE;
    else if (str_eq(str, "raw"))
        *type = DATA_TYPE_RAW;
    else
        return false;

    return true;
}

static void print_types(FILE *f)
{
    fprintf(f, "Types and their values:\n");
    fprintf(f, " * bool (true, false)\n");
    fprintf(f, " * uint8 (0-255)\n");
    fprintf(f, " * ascii (NUL-terminated)\n");
    fprintf(f, " * unicode (widened and NUL-terminated)\n");
    fprintf(f, " * raw (output only; raw bytes on output)\n");
}

static void help_set(FILE *f, const struct subcommand_t *info)
{
    fprintf(f, "%s smm-store-file %s \\\n", program_name, info->name);
    fprintf(f, "    -g vendor-guid \\\n");
    fprintf(f, "    -n variable-name \\\n");
    fprintf(f, "    -t variable-type \\\n");
    fprintf(f, "    -v value\n");
    fprintf(f, "\n");
    print_types(f);
}

static int process_set(int argc, char *argv[], const char store_file[])
{
    const char *name = NULL, *value = NULL, *type_str = NULL, *guid_str = NULL;
    int opt;
    while ((opt = getopt(argc, argv, "n:t:v:g:")) != -1) {
        switch (opt) {
            case 'n':
                name = optarg;
                break;
            case 't':
                type_str = optarg;
                break;
            case 'v':
                value = optarg;
                break;
            case 'g':
                guid_str = optarg;
                break;

            case '?': /* parsing error */
                print_usage(argv[0]);
        }
    }

    if (argv[optind] != NULL) {
        fprintf(stderr, "First unexpected positional argument: %s\n",
                argv[optind]);
        print_usage(argv[0]);
    }

    if (name == NULL || value == NULL || type_str == NULL || guid_str == NULL) {
        fprintf(stderr, "All options are required\n");
        print_usage(argv[0]);
    }

    if (name[0] == '\0') {
        fprintf(stderr, "Variable name can't be empty\n");
        print_usage(argv[0]);
    }

    EFI_GUID guid;
    if (!parse_guid(guid_str, &guid)) {
        fprintf(stderr, "Failed to parse GUID: %s\n", guid_str);
        return EXIT_FAILURE;
    }

    enum data_type type;
    if (!parse_data_type(type_str, &type)) {
        fprintf(stderr, "Failed to parse type: %s\n", type_str);
        return EXIT_FAILURE;
    }

    struct storage_t storage;
    if (!storage_open(store_file, &storage, /*rw=*/true))
        return EXIT_FAILURE;

    struct var_t *var = vs_find(&storage.vs, name, &guid);

    if (var == NULL) {
        var = vs_new_var(&storage.vs);
        var->name = to_uchars(name, &var->name_size);
        var->data = make_data(value, &var->data_size, type);
        var->guid = guid;
    } else {
        free(var->data);
        var->data = make_data(value, &var->data_size, type);
    }

    return storage_write_back(&storage) ? EXIT_SUCCESS : EXIT_FAILURE;
}

static void help_list(FILE *f, const struct subcommand_t *info)
{
    fprintf(f, "%s smm-store-file %s\n", program_name, info->name);
}

static int process_list(int argc, char *argv[], const char store_file[])
{
    (void)argc;
    (void)argv;

    struct storage_t storage;
    if (!storage_open(store_file, &storage, /*rw=*/false))
        return EXIT_FAILURE;

    for (struct var_t *var = storage.vs.vars; var != NULL; var = var->next) {
        char *name = to_chars(var->name, var->name_size);
        char *guid = format_guid(&var->guid, /*use_alias=*/true);

        printf("%-*s:%s (%zu %s)\n", GUID_LEN, guid, name, var->data_size,
               var->data_size == 1 ? "byte" : "bytes");

        free(name);
        free(guid);
    }

    storage_drop(&storage);
    return EXIT_SUCCESS;
}

static void help_get(FILE *f, const struct subcommand_t *info)
{
    fprintf(f, "%s smm-store-file %s \\\n", program_name, info->name);
    fprintf(f, "    -g vendor-guid \\\n");
    fprintf(f, "    -n variable-name \\\n");
    fprintf(f, "    -t variable-type\n");
    fprintf(f, "\n");
    print_types(f);
}

static int process_get(int argc, char *argv[], const char store_file[])
{
    const char *name = NULL, *type_str = NULL, *guid_str = NULL;
    int opt;
    while ((opt = getopt(argc, argv, "n:g:t:")) != -1) {
        switch (opt) {
            case 'n':
                name = optarg;
                break;
            case 'g':
                guid_str = optarg;
                break;
            case 't':
                type_str = optarg;
                break;

            case '?': /* parsing error */
                print_usage(argv[0]);
        }
    }

    if (name == NULL || type_str == NULL || guid_str == NULL) {
        fprintf(stderr, "All options are required\n");
        print_usage(argv[0]);
    }

    EFI_GUID guid;
    if (!parse_guid(guid_str, &guid)) {
        fprintf(stderr, "Failed to parse GUID: %s\n", guid_str);
        return EXIT_FAILURE;
    }

    enum data_type type;
    if (!parse_data_type(type_str, &type)) {
        fprintf(stderr, "Failed to parse type: %s\n", type_str);
        return EXIT_FAILURE;
    }

    struct storage_t storage;
    if (!storage_open(store_file, &storage, /*rw=*/false))
        return EXIT_FAILURE;

    int result = EXIT_SUCCESS;

    struct var_t *var = vs_find(&storage.vs, name, &guid);
    if  (var == NULL) {
        result = EXIT_FAILURE;
        fprintf(stderr, "Couldn't find variable \"%s:%s\"\n", guid_str, name);
    } else if (var->data_size == 0) {
        fprintf(stderr, "There is no data to show.\n");
        result = EXIT_FAILURE;
    } else {
        print_data(var->data, var->data_size, type);
    }

    storage_drop(&storage);
    return result;
}

static void help_help(FILE *f, const struct subcommand_t *info)
{
    fprintf(f, "Display generic help:\n");
    fprintf(f, "  %s smm-store-file %s\n", program_name, info->name);
    fprintf(f, "\n");
    fprintf(f, "Display sub-command help:\n");
    fprintf(f, "  %s smm-store-file %s sub-command\n", program_name, info->name);
}

static int process_help(int argc, char *argv[], const char store_file[])
{
    (void)store_file;

    if (argc == 1) {
        print_help();
        return EXIT_SUCCESS;
    }

    if (argc != 2) {
        print_usage(argv[0]);
        return EXIT_FAILURE;
    }

    const char *sub_command = argv[1];

    for (int i = 0; i < sub_command_count; ++i) {
        const struct subcommand_t *cmd = &sub_commands[i];
        if (!str_eq(cmd->name, sub_command))
            continue;

        cmd->print_help(stdout, cmd);
        return EXIT_SUCCESS;
    }

    fprintf(stderr, "Unknown sub-command: %s\n", sub_command);
    print_help();
    return EXIT_FAILURE;
}

static void help_remove(FILE *f, const struct subcommand_t *info)
{
    fprintf(f, "%s smm-store-file %s \\\n", program_name, info->name);
    fprintf(f, "    -g vendor-guid \\\n");
    fprintf(f, "    -n variable-name\n");
}

static int process_remove(int argc, char *argv[], const char store_file[])
{
    const char *name = NULL, *guid_str = NULL;
    int opt;
    while ((opt = getopt(argc, argv, "n:g:")) != -1) {
        switch (opt) {
            case 'n':
                name = optarg;
                break;
            case 'g':
                guid_str = optarg;
                break;

            case '?': /* parsing error */
                print_usage(argv[0]);
        }
    }

    if (name == NULL || guid_str == NULL) {
        fprintf(stderr, "All options are required\n");
        print_usage(argv[0]);
    }

    EFI_GUID guid;
    if (!parse_guid(guid_str, &guid)) {
        fprintf(stderr, "Failed to parse GUID: %s\n", guid_str);
        return EXIT_FAILURE;
    }

    struct storage_t storage;
    if (!storage_open(store_file, &storage, /*rw=*/true))
        return EXIT_FAILURE;

    int result = EXIT_SUCCESS;

    struct var_t *var = vs_find(&storage.vs, name, &guid);
    if  (var == NULL) {
        result = EXIT_FAILURE;
        fprintf(stderr, "Couldn't find variable \"%s:%s\"\n", guid_str, name);
    } else {
        vs_delete(&storage.vs, var);
    }

    storage_write_back(&storage);
    return result;
}

static void help_guids(FILE *f, const struct subcommand_t *info)
{
    fprintf(f, "%s smm-store-file %s\n", program_name, info->name);
}

static int process_guids(int argc, char *argv[], const char store_file[])
{
    (void)argc;
    (void)argv;
    (void)store_file;

    for (int i = 0; i < known_guid_count; ++i) {
        char *guid = format_guid(&known_guids[i].guid, /*use_alias=*/false);
        printf("%-10s -> %s\n", known_guids[i].alias, guid);
        free(guid);
    }
    return EXIT_SUCCESS;
}

int main(int argc, char *argv[])
{
    program_name = argv[0];

    if (argc > 1 && (str_eq(argv[1], "-h") || str_eq(argv[1], "--help"))) {
        print_help();
        exit(EXIT_SUCCESS);
    }

    if (argc < 3)
        print_usage(NULL);

    const char *store_file = argv[1];
    const char *sub_command = argv[2];

    int sub_command_argc = argc - 2;
    char **sub_command_argv = argv + 2;

    for (int i = 0; i < sub_command_count; ++i) {
        const struct subcommand_t *cmd = &sub_commands[i];
        if (!str_eq(cmd->name, sub_command))
            continue;

        return cmd->process(sub_command_argc, sub_command_argv, store_file);
    }

    fprintf(stderr, "Unknown sub-command: %s\n", sub_command);
    print_help();
    return EXIT_FAILURE;
}
