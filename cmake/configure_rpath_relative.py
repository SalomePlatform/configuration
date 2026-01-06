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
This module provides functionality to configure relative RPATHs for binaries.

It includes:
- Logging setup for debugging and tracking.
- Regular expressions to identify system paths.
- An abstract base class for path conversion strategies.
- Path converter
- RPath manager to handle all RPATH processing for a list of directories.

The main purpose of this module is to convert absolute paths to relative paths
based on the binary directory, which is useful for creating relocatable binaries.

It could be called from a CMake script at the end of install step after all the binaries are 
already installed in the target directory, or manually from the command line.
"""

import os
import sys
import subprocess
import logging
import re

from typing import List, Set
from abc import ABC, abstractmethod

SYSTEM_PATH_REGEX = re.compile(
    r'^(/lib|/usr|/lib64|/bin|/sbin|/usr/sbin|/usr/local/lib|/usr/local/bin)')

class PathConversionStrategy(ABC):
    """
    Abstract base class for path conversion strategies.
    """
    @abstractmethod
    def convert(self, path: str, binary_dir: str) -> str:
        """
        Converts the given path to a relative path based on the binary directory.

        Args:
            path (str): The original path to be converted.
            binary_dir (str): The directory relative to which the path should be converted.

        Returns:
            str: The converted relative path.
        """

    def relative_path_to_origin(self, path: str) -> str:
        """
        Make the given relative path using the $ORIGIN keyword.
        """
        return os.path.join('$ORIGIN', path)

class SystemPathConversionStrategy(PathConversionStrategy):
    """
    Strategy for system paths.
    """
    def convert(self, path: str, binary_dir: str) -> str:
        logging.debug("Returning system path %s as is", path)
        return path

class OriginPathConversionStrategy(PathConversionStrategy):
    """
    Strategy for paths starting with $ORIGIN.
    """
    def convert(self, path: str, binary_dir: str) -> str:
        logging.debug("Returning origin path %s as is", path)
        return path

class AbsolutePathConversionStrategy(PathConversionStrategy):
    """
    Strategy for absolute paths.
    """
    def convert(self, path: str, binary_dir: str) -> str:
        relative_path = os.path.relpath(path, binary_dir)
        converted_path = self.relative_path_to_origin(relative_path)
        logging.debug("Converted absolute path %s to %s", path, converted_path)
        return converted_path

class RelativePathConversionStrategy(PathConversionStrategy):
    """
    Strategy for relative paths.
    """
    def convert(self, path: str, binary_dir: str) -> str:
        converted_path = self.relative_path_to_origin(path)
        logging.debug("Converted relative path %s to %s", path, converted_path)
        return converted_path

class PathConverter:
    """
    Handles RPATH conversion using different strategies.
    """
    def __init__(self):
        self.strategies = {
            'system': SystemPathConversionStrategy(),
            'origin': OriginPathConversionStrategy(),
            'absolute': AbsolutePathConversionStrategy(),
            'relative': RelativePathConversionStrategy()
        }

    def is_system_path(self, path: str) -> bool:
        """
        Check if the given path is a system path using a regular expression.
        """
        return bool(SYSTEM_PATH_REGEX.match(path))

    def get_strategy(self, path: str) -> PathConversionStrategy:
        """
        Get the appropriate strategy for the path.
        """
        if self.is_system_path(path):
            return self.strategies['system']
        elif path.startswith('$ORIGIN'):
            return self.strategies['origin']
        elif os.path.isabs(path):
            return self.strategies['absolute']
        else:
            return self.strategies['relative']

    def convert_rpath(self, rpath_old: str, binary_dir: str) -> Set[str]:
        """
        Convert the old RPATH to a new set of paths.
        """
        rpath_new: Set[str] = set()

        for path in rpath_old.split(':'):
            logging.debug("Processing path %s...", path)
            strategy = self.get_strategy(path)
            converted_path = strategy.convert(path, binary_dir)
            rpath_new.add(converted_path)
            logging.debug("Added path %s", converted_path)

        return rpath_new


class RPathManager:
    """
    Handles all RPATH processing for a list of directories:
    - Recursively search for shared libraries in the directories.
    - Read the RPATH from the ELF header.
    - Convert the RPATH to a new one using PathConverter.
    - Check the size of the new RPATH and compare it with the old RPATH size.
    - Set the new RPATH using the patchelf command.
    """

    def __init__(self, max_rpath_size: int):
        self.count_bigger_rpath = 0
        self.max_rpath_size = max_rpath_size


    def get_shared_libraries(self, directory: str) -> List[str]:
        """
        Recursively get a list of all shared libraries inside the directory and subdirectories.

        Args:
            directory (str): The directory to search for shared libraries.

        Returns:
            List[str]: A list of paths to shared libraries.
        """
        shared_libs = []
        for root, _, files in os.walk(directory):
            for file in files:
                if file.endswith('.so') or '.so.' in file:
                    shared_libs.append(os.path.join(root, file))
        return shared_libs
    
    def get_binary_executables(self, directory: str) -> List[str]:
        def is_binary_executable( fname ):
            p = subprocess.Popen(["file","-b",fname] , env = {"LANG":"en_EN:UTF-8"},stdout = subprocess.PIPE)
            out,_ = p.communicate()
            if p.returncode != 0:
                return False
            return "ELF" == out.decode()[:3] and "executable" in out.decode().lower()

        ret = []
        for root, _, files in os.walk(directory):
            for file in files:
                candidate = os.path.join(root, file)
                if is_binary_executable( candidate ):
                    ret.append( candidate )
        return ret

    def read_rpath(self, lib_path: str) -> str:
        """
        Read RPATH or RUNPATH from the ELF header using the readelf command.

        Args:
            lib_path (str): The path to the shared library.

        Returns:
            str: The RPATH or RUNPATH value, or an empty string if not found.
        """
        try:
            result = subprocess.run(
                ['readelf', '-d', lib_path], capture_output=True, text=True, check=True)

            for line in result.stdout.splitlines():
                if 'RUNPATH' in line or 'RPATH' in line:
                    return line.split('[')[1].split(']')[0]
        except subprocess.CalledProcessError as e:
            logging.error("Error reading %s: %s", lib_path, e)
        return ""

    def check_rpath_size(self, lib: str, rpath_old: str, rpath_new_str: str):
        """
        Check the size of the new RPATH and compare it with the old RPATH size.
    
        Args:
            lib (str): The path to the shared library.
            rpath_old (str): The old RPATH string.
            rpath_new_str (str): The new RPATH string.
    
        Raises:
            ValueError: If the new RPATH size exceeds the maximum allowed size.
        """
        # Calculate the size in bytes
        rpath_old_size = len(rpath_old.encode('utf-8'))
        rpath_new_size = len(rpath_new_str.encode('utf-8'))

        logging.debug("New RPATH: %s", rpath_new_str)
        logging.debug("RPATH size (bytes): old %d, new %d", rpath_old_size, rpath_new_size)
        if rpath_new_size > rpath_old_size:
            logging.debug("New RPATH for %s is bigger than the old one.", lib)
            self.count_bigger_rpath += 1

        if rpath_new_size > self.max_rpath_size:
            logging.error(
                "New RPATH size for %s (%d bytes) exceeds the maximum allowed size (%d bytes).",
                lib, rpath_new_size, self.max_rpath_size
            )
            raise ValueError(f"New RPATH size for {lib} exceeds the maximum allowed size.")

    def configure_rpath_lib(self, lib: str):
        """
        Process a single shared library to update its RPATH.

        Args:
            lib (str): The path to the shared library.
        """

        logging.debug("Processing library %s...", lib)

        # Get old RPATH
        rpath_old = self.read_rpath(lib)
        logging.debug("Old RPATH: %s", rpath_old)
        if not rpath_old:
            logging.warning("RPATH not found for %s. Skipping.", lib)
            return

        # Convert RPATH
        binary_dir = os.path.dirname(lib)
        rpath_new = PathConverter().convert_rpath(rpath_old, binary_dir)
        rpath_new_str = ':'.join(rpath_new)

        # Don't update if the new RPATH is the same as the old one
        if rpath_new_str == rpath_old:
            logging.debug("New RPATH is the same as the old RPATH for %s. Skipping.", lib)
            return

        # Check RPATH size
        self.check_rpath_size(lib, rpath_old, rpath_new_str)

        # Set new RPATH
        try:
            #subprocess.run(['patchelf', '--set-rpath', rpath_new_str, lib], check=True)
            subprocess.run(['chrpath', '-r', rpath_new_str, lib], check=True)
        except subprocess.CalledProcessError as e:
            logging.error("Error setting RPATH for %s: %s", lib, e)

    def configure_rpath(self, dirs: List[str]):
        """
        Configure the RPATH for all shared libraries in the given directories.

        Args:
            dirs (List[str]): A list of directories to process.
        """

        logging.debug("Configuring RPATH for the given directories: %s", dirs)
        if not dirs:
            logging.warning("No directories provided.")
            return

        for directory in dirs:
            logging.debug("Processing directory %s...", directory)

            if not os.path.exists(directory):
                logging.warning("Directory %s does not exist.", directory)
                continue

            shared_libs = self.get_shared_libraries(directory)
            for lib in shared_libs:
                logging.info( f"Processing lib ...{lib}" )
                self.configure_rpath_lib(lib)

            binaries = self.get_binary_executables( directory )
            for binary in binaries:
                logging.info( f"Processing binary ...{binary}" )
                self.configure_rpath_lib(binary)

            logging.info("Summary: Processed %d binaries.", len(shared_libs))

        logging.info("Number of cases where new RPATH is bigger: %d", self.count_bigger_rpath)


def main(max_rpath_size: int, libs_directories: str):
    """
    Main function to initialize RPathManager and configure RPATH for the given directories.

    Args:
        libs_directories (str): A semicolon-separated string of directories to process.
        max_rpath_size (int): The maximum allowed size for RPATH in bytes.
    """

    logging.debug("Max RPATH size: %d", max_rpath_size)
    logging.debug("Directories: %s", libs_directories)
    libs_directories = libs_directories.replace(';', ' ').split()
    logging.debug("Directories list: %s", libs_directories)

    manager = RPathManager(max_rpath_size)
    try:
        manager.configure_rpath(libs_directories)
    except ValueError as e:
        logging.error(e)
        sys.exit(1)


if __name__ == "__main__":
    logging.basicConfig(level=logging.INFO,
format='%(filename)s:%(lineno)d:%(levelname)s: %(message)s',
handlers=[
    logging.StreamHandler(sys.stdout),
    logging.FileHandler("configure_rpath_relative.log")
])
    if len(sys.argv) < 3:
        print("Usage: python configure_rpath_relative.py <max_rpath_size> "
              "<directory1>;<directory2>;...")
        sys.exit(1)

    max_size = int(sys.argv[1])
    directories = sys.argv[2]
    main(max_size, directories)
