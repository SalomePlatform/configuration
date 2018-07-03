import os

li=[]
for root,dirs,fis in os.walk(os.getcwd()):
  if "link.txt" in fis:
    li.append(os.path.join(root,"link.txt"))

for f in li:
  fid=file(f)
  lines=fid.readlines()
  for ii,st in enumerate(lines):
    st=st.replace("-Wl,--export-dynamic;","-Wl,--export-dynamic")
    st=st.replace("--enable-new-dtags;","--enable-new-dtags")
    lines[ii]=st
    pass
  fid=file(f,"w") ; fid.writelines(lines)

