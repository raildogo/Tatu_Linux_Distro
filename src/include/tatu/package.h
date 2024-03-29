#pragma once

#include <tatu/common.h>

/* Structure for YAML document:

nome: glibc
version: 2.39
repo: core
is_group: false
no_source: false
source: https://ftp.gnu.org/gnu/glibc/glibc-2.39.tar.xz

deps: [

]
mkdeps: [

]
extras: [
  'https://www.linuxfromscratch.org/patches/lfs/12.1/glibc-2.39-fhs-1.patch',
  https://www.iana.org/time-zones/repository/releases/tzdata2024a.tar.gz'
]

*/

typedef struct {
    char *name;
    char *version;
    char *repo;
    char *source;
    bool is_group;
    bool no_package;
    str_list deps;
    str_list mkdeps;
    str_list extras;

} tatu_package;

u32 tatu_package_to_string(tatu_package *pck, char *buffer, u32 max_size);
tatu_package *package_load(char *root, char *name);

typedef struct package_list_entry_ {
    tatu_package *pck;
    struct package_list_entry_ *next;
} package_list_entry;

typedef struct {
    package_list_entry *head;
    package_list_entry *tail;
} package_list;

bool package_load_all(char *root, package_list *list);
tatu_package *package_list_find(package_list *list, char *name);
package_list_entry *package_list_add(package_list *list, tatu_package *pck);
bool package_is_installed(char *root, char *name);