
# python OCCT_7.3.0p3_post_install.py $(CURDIR)/debian/${OCCT_INSTALL_DIR}/lib/cmake/opencascade

import os,shutil,sys
from glob import glob
dn=sys.argv[1]
fis=glob(os.path.join(dn,"*-release.cmake"))
for fi in fis:
    with open(fi) as f:
        lines = [elt.replace("\\${OCCT_INSTALL_BIN_LETTER}","") for elt in f]
    with open(fi,"w") as f2:
        f2.writelines(lines)
    pass
