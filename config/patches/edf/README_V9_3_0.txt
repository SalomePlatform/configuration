In this directory you can find all the patch used for V9_3_0 building :


CGAL              4.0   : cgal_cmake352.patch
> fix for a dobble / in a path
    # For CGAL < 4.7
    # Patch if build with cmake > 3.5

FREEIMAGE        3.17   : freeimage_3170_sci9.patch and FreeImage3170_Make.patch
> patch to build freeimage

GL2PS           1.4.0   :
> Patch for : if(GLUT_FOUND)

HDF5           1.10.3   : patchHDF5Build.py
> Make links

MATPLOTLIB      2.2.2   : setup_qt5.cfg
> Patch to build matplolib with Qt5 options

OMNIORBPY       4.2.2   : omniORBpy-4.2.1-2-python3.patch
> To python3 version compatiblity

SCOTCH          6.4.0   : scotch604_Make.inc.patch
> Fix esmumps management

SPHINX          1.7.6   : sphinx176_w_intl_napoleon.patch
> Lowering the version number for the required software
