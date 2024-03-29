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
extra: [
  'https://www.linuxfromscratch.org/patches/lfs/12.1/glibc-2.39-fhs-1.patch',
  https://www.iana.org/time-zones/repository/releases/tzdata2024a.tar.gz'
]