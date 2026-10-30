#! /usr/bin/env python3
# Copyright (C) 2025-2026  CEA, EDF
#
# This library is free software; you can redistribute it and/or
# modify it under the terms of the GNU Lesser General Public
# License as published by the Free Software Foundation; either
# version 2.1 of the License, or (at your option) any later version.
#
# This library is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# Lesser General Public License for more details.
#
# You should have received a copy of the GNU Lesser General Public
# License along with this library; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307 USA
#
# See http://www.salome-platform.org/ or email : webmaster.salome@opencascade.com
#

"""
macOS counterpart of configure_rpath_relative.py (which handles ELF files only).

For every Mach-O file (executable, dylib, bundle) found in the given directories:

  1. LC_RPATH entries are rewritten:
       $ORIGIN...           -> @loader_path...  (dyld does not know $ORIGIN:
                                                 the INSTALL_RPATH "$ORIGIN..." set
                                                 on the targets resolve nothing)
       a:b (one entry)      -> two entries      (a colon-separated INSTALL_RPATH
                                                 is a single LC_RPATH on macOS)
       absolute path        -> @loader_path relative path, if it is under the
                                                 search root (sibling products of
                                                 the install prefix); kept otherwise
       relative path        -> @loader_path/<path>
       duplicates           -> removed           (rejected by recent dyld)
  2. every @rpath/<name> dependency that is still unresolved is looked for in
     the search root (default: the parent of the install prefix, i.e. the sat
     INSTALL directory: <root>/*/lib and <root>/*/*/lib, e.g.
     SALOMEBOOTSTRAP/__RUN_SALOME__/lib/salome) and in --search-dir
     directories; a relative rpath to the
     directory that provides it is added (e.g. libKERNELBasics.dylib provided by
     SALOMEBOOTSTRAP).
  3. modified files whose code signature became invalid are re-signed ad hoc.

It is called at the end of the install step (ConfigureRPathPostEx.cmake) or by hand:

  configure_rpath_macos.py --prefix INSTALL/KERNEL INSTALL/KERNEL/bin/salome INSTALL/KERNEL/lib
"""

import argparse
import glob
import logging
import os
import struct
import subprocess
import sys

MH_MAGIC, MH_MAGIC_64 = 0xfeedface, 0xfeedfacf
FAT_MAGIC, FAT_MAGIC_64 = 0xcafebabe, 0xcafebabf
LINKABLE_FILETYPES = (2, 6, 8)        # MH_EXECUTE, MH_DYLIB, MH_BUNDLE
LOAD_DYLIB_CMDS = ("LC_LOAD_DYLIB", "LC_LOAD_WEAK_DYLIB", "LC_REEXPORT_DYLIB",
                   "LC_LAZY_LOAD_DYLIB", "LC_LOAD_UPWARD_DYLIB")
SYSTEM_PREFIXES = ("/usr/lib", "/System/", "/Library/Developer/",
                   "/Applications/Xcode")
ORIGIN_TOKENS = ("${ORIGIN}", "$ORIGIN")
LIB_EXTENSIONS = (".dylib", ".so")


def macho_filetype(path):
    '''Mach-O file type of path (first architecture of a universal file),
       None if path is not a Mach-O file'''
    try:
        with open(path, "rb") as f:
            head = f.read(32)
            if len(head) < 16:
                return None
            magic = struct.unpack("<I", head[:4])[0]
            if magic in (MH_MAGIC, MH_MAGIC_64):
                return struct.unpack("<I", head[12:16])[0]
            magic = struct.unpack(">I", head[:4])[0]
            if magic not in (FAT_MAGIC, FAT_MAGIC_64):
                return None
            nfat = struct.unpack(">I", head[4:8])[0]
            if not 0 < nfat < 32:          # Java class files share FAT_MAGIC
                return None
            if magic == FAT_MAGIC:
                offset = struct.unpack(">I", head[16:20])[0]
            else:
                offset = struct.unpack(">Q", head[16:24])[0]
            f.seek(offset)
            sub = f.read(16)
            if len(sub) < 16 or struct.unpack("<I", sub[:4])[0] not in (MH_MAGIC, MH_MAGIC_64):
                return None
            return struct.unpack("<I", sub[12:16])[0]
    except (IOError, OSError, struct.error):
        return None


def run(cmd):
    return subprocess.run(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE,
                          universal_newlines=True)


class MachOInfo(object):
    '''install name, dependencies and rpaths (first architecture), from otool -l'''

    def __init__(self, path):
        self.id = None
        self.deps = []
        self.rpaths = []                   # file order, duplicates kept
        cmd = None
        arch_sections = 0
        for line in run(["otool", "-l", path]).stdout.splitlines():
            if "(architecture " in line and line.rstrip().endswith(":"):
                arch_sections += 1
                if arch_sections > 1:
                    break
                continue
            s = line.strip()
            if s.startswith("cmd "):
                cmd = s.split()[1]
                continue
            if not s.startswith(("name ", "path ")):
                continue
            value = s[5:].rsplit(" (offset", 1)[0].strip()
            if cmd in LOAD_DYLIB_CMDS:
                self.deps.append(value)
            elif cmd == "LC_ID_DYLIB":
                self.id = value
            elif cmd == "LC_RPATH":
                self.rpaths.append(value)

    def rpath_dependencies(self):
        return [d[len("@rpath/"):] for d in self.deps
                if d.startswith("@rpath/") and d != self.id]


def loader_rpath(file_path, target_dir):
    rel = os.path.relpath(os.path.realpath(target_dir),
                          os.path.realpath(os.path.dirname(file_path)))
    return "@loader_path" if rel == "." else "@loader_path/" + rel


def is_under(path, root):
    path, root = os.path.realpath(path), os.path.realpath(root)
    return path == root or path.startswith(root + os.sep)


class MacOSRPathManager(object):

    def __init__(self, search_root, search_dirs, dry_run=False):
        self.search_root = search_root
        self.search_dirs = [d for d in search_dirs if os.path.isdir(d)]
        self.dry_run = dry_run
        self.index = None                  # library name -> directory
        self.nb_modified = 0
        self.unresolved = []

    # -- libraries available in the search root ---------------------------------
    def lib_roots(self):
        '''--search-dir directories, then <root>/*/lib and <root>/*/*/lib
           (SALOMEBOOTSTRAP installs in __RUN_SALOME__/lib/salome)'''
        roots = list(self.search_dirs)
        if self.search_root and os.path.isdir(self.search_root):
            for pattern in (("*", "lib"), ("*", "*", "lib")):
                roots += sorted(d for d in glob.glob(os.path.join(self.search_root, *pattern))
                                if os.path.isdir(d))
        return roots

    def build_index(self):
        self.index = {}
        for root_dir in self.lib_roots():
            for root, dirs, files in os.walk(root_dir):
                # libraries are not looked for in Python packages, docs...
                dirs[:] = [d for d in dirs
                           if d not in ("site-packages", "pkgconfig", "cmake", "doc")]
                real_root = os.path.realpath(root)
                for name in files:
                    if name.endswith(LIB_EXTENSIONS):
                        self.index.setdefault(name, real_root)

    def find_dir(self, name):
        '''directory D such that D/name exists
           (name = libfoo.dylib or QtCore.framework/Versions/5/QtCore)'''
        if "/" in name:
            for d in self.lib_roots():
                if os.path.exists(os.path.join(d, name)):
                    return os.path.realpath(d)
            return None
        if self.index is None:
            self.build_index()
        return self.index.get(name)

    # -- rpath conversion ----------------------------------------------------------
    def convert(self, path, piece):
        for token in ORIGIN_TOKENS:
            if piece.startswith(token):
                return "@loader_path" + piece[len(token):]
        if piece.startswith("@"):
            return piece
        if os.path.isabs(piece):
            if piece.startswith(SYSTEM_PREFIXES):
                return piece
            if self.search_root and is_under(piece, self.search_root) and os.path.isdir(piece):
                return loader_rpath(path, piece)
            return piece                   # outside of the products: kept
        return "@loader_path/" + piece

    @staticmethod
    def expand(path, rpath):
        if rpath.startswith("@loader_path"):
            return os.path.dirname(path) + rpath[len("@loader_path"):]
        if rpath.startswith("@"):
            return None                    # @executable_path: depends on the process
        return rpath

    def configure_file(self, path):
        info = MachOInfo(path)

        new_rpaths = []
        for rp in info.rpaths:
            for piece in rp.split(":"):
                if not piece:
                    continue
                converted = self.convert(path, piece)
                if converted not in new_rpaths:
                    new_rpaths.append(converted)

        dirs = [self.expand(path, rp) for rp in new_rpaths]
        exe_relative = any(d is None for d in dirs)
        dirs = [d for d in dirs if d]
        for name in info.rpath_dependencies():
            if exe_relative or any(os.path.exists(os.path.join(d, name)) for d in dirs):
                continue
            target = self.find_dir(name)
            if target is None:
                self.unresolved.append((path, name))
                continue
            rp = loader_rpath(path, target)
            if rp not in new_rpaths:
                new_rpaths.append(rp)
                dirs.append(self.expand(path, rp))

        if new_rpaths == info.rpaths:
            return
        logging.debug("%s: %s -> %s", path, info.rpaths, new_rpaths)
        if self.dry_run:
            logging.info("%s: %s -> %s", path, info.rpaths, new_rpaths)
            self.nb_modified += 1
            return

        # 1. remove every old entry (once per occurrence: a duplicated rpath
        #    is deleted by successive calls), 2. add the new ones
        calls = []
        remaining = list(info.rpaths)
        while remaining:
            batch = []
            for rp in list(remaining):
                if rp not in batch:
                    batch.append(rp)
                    remaining.remove(rp)
            calls.append([a for rp in batch for a in ("-delete_rpath", rp)])
        calls.append([a for rp in new_rpaths for a in ("-add_rpath", rp)])
        for args in calls:
            if not args:
                continue
            res = run(["install_name_tool"] + args + [path])
            if res.returncode != 0:
                err = [l for l in res.stderr.splitlines()
                       if "invalidate the code signature" not in l]
                if any("do not fit" in l for l in err):
                    raise RuntimeError("%s: not enough header space, link it with "
                                       "-Wl,-headerpad_max_install_names" % path)
                raise RuntimeError("%s: install_name_tool failed: %s"
                                   % (path, "\n".join(err) or res.returncode))
        if run(["codesign", "-v", path]).returncode != 0:
            run(["codesign", "-f", "-s", "-", path])
        self.nb_modified += 1

    def configure(self, directories):
        files = []
        for directory in directories:
            if not os.path.isdir(directory):
                logging.warning("Directory %s does not exist.", directory)
                continue
            for root, _dirs, names in os.walk(directory):
                for name in names:
                    p = os.path.join(root, name)
                    if not os.path.islink(p) and macho_filetype(p) in LINKABLE_FILETYPES:
                        files.append(p)
        for p in sorted(set(files)):
            self.configure_file(p)
        logging.info("Summary: %d Mach-O files, %d modified.", len(set(files)), self.nb_modified)
        for p, name in self.unresolved:
            logging.warning("%s: @rpath/%s not found under %s", p, name,
                            ", ".join([self.search_root or ""] + self.search_dirs))


def main(argv=None):
    parser = argparse.ArgumentParser(
        description="Relative rpaths (@loader_path) for the Mach-O files of a SALOME module")
    parser.add_argument("--prefix", help="install prefix of the module "
                        "(its parent is the default search root)")
    parser.add_argument("--search-root", help="directory whose */lib and */*/lib subdirectories "
                        "provide the @rpath dependencies (default: parent of --prefix)")
    parser.add_argument("--search-dir", action="append", default=[],
                        help="additional directory providing @rpath dependencies "
                        "(may be repeated; SALOME_RPATH_SEARCH_DIRS is also read, "
                        "colon-separated)")
    parser.add_argument("--dry-run", action="store_true", help="only print the changes")
    parser.add_argument("-v", "--verbose", action="store_true")
    parser.add_argument("directories", nargs="+",
                        help="directories to process (';' separated lists accepted)")
    args = parser.parse_args(argv)

    logging.basicConfig(level=logging.DEBUG if args.verbose else logging.INFO,
                        format="configure_rpath_macos: %(levelname)s: %(message)s",
                        stream=sys.stdout)

    directories = []
    for d in args.directories:
        directories += [os.path.normpath(x) for x in d.replace(";", " ").split() if x]
    search_root = args.search_root
    if not search_root and args.prefix:
        search_root = os.path.dirname(os.path.realpath(args.prefix))
    search_dirs = list(args.search_dir)
    search_dirs += [d for d in os.environ.get("SALOME_RPATH_SEARCH_DIRS", "").split(":") if d]

    manager = MacOSRPathManager(search_root, search_dirs, args.dry_run)
    try:
        manager.configure(directories)
    except RuntimeError as e:
        logging.error(e)
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
