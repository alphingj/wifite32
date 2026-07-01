#!/usr/bin/env python3
from __future__ import annotations
import os, shutil, subprocess, pathlib, zipfile, argparse

parser = argparse.ArgumentParser()
parser.add_argument('--abi', default='universal', choices=['universal','arm64-v8a','armeabi-v7a','x86','x86_64'])
args = parser.parse_args()

JAVA11 = pathlib.Path("/usr/lib/jvm/java-11-openjdk-amd64/bin")
JAVAC  = JAVA11 / "javac"
os.environ["JAVA_HOME"] = str(JAVA11.parent)
os.environ["PATH"] = str(JAVA11) + ":" + os.environ.get("PATH","")

SDK = pathlib.Path(os.environ.get("ANDROID_HOME","/home/gj/Android/Sdk"))
PLAT = SDK/"platforms/android-35/android.jar"
BT  = SDK/"build-tools/34.0.0"
D8  = BT/"d8";  AAPT2 = BT/"aapt2"
ZIP = BT/"zipalign";  APKSIGNER = BT/"apksigner"

ROOT = pathlib.Path("/home/gj/wifite32")
OUT=pathlib.Path("/home/gj/wifite32/build/android")
RES=pathlib.Path("/home/gj/wifite32/android/app/src/main/res")
SRC=pathlib.Path("/home/gj/wifite32/android/app/src/main/java")
(out_res:=OUT/"res").mkdir(parents=True,exist_ok=True)
(out_tmp:=OUT/"tmp").mkdir(parents=True,exist_ok=True)

if out_res.exists(): shutil.rmtree(out_res)
shutil.copytree(RES, out_res)
subprocess.run([str(AAPT2),"compile","--dir",str(out_res),"-o",str(OUT/"res.zip")],check=False)

flat=[]
with zipfile.ZipFile(OUT/"res.zip") as zf:
    for n in zf.namelist():
        p2=OUT/n; p2.parent.mkdir(parents=True,exist_ok=True); p2.write_bytes(zf.read(n))
        if p2.suffix==".flat": flat.append(str(p2))
print(f"[+] resources: {len(flat)} flats")

(OUT/"tmp/java/com/wifite32/android").mkdir(parents=True,exist_ok=True)
(OUT/"tmp/java/com/wifite32/android").joinpath("R.java").write_text(
    "package com.wifite32.android;\npublic final class R {}\n")

java_files = [str(p) for p in SRC.rglob("*.java")]
print("[+] javac:", len(java_files), "files")
jar_out = OUT/"tmp/classes/app.jar"
(OUT/"tmp/classes").mkdir(parents=True,exist_ok=True)
r = subprocess.run([str(JAVAC),"-source","8","-target","8",
                    "-bootclasspath",str(PLAT),"-d",str(OUT/"tmp/classes"),
                    *java_files],capture_output=True,text=True)
print("javac rc",r.returncode)
if r.returncode!=0: print(r.stderr[-3000:])

cls=[str(p) for p in (OUT/"tmp/classes").rglob("*.class")]
if cls:
    subprocess.run(["jar","cf",str(jar_out),*cls],check=False)

dexdir=OUT/"tmp/dex2"; dexdir.mkdir(exist_ok=True)
if jar_out.exists() and jar_out.stat().st_size > 0:
    print("[+] D8")
    dr=subprocess.run([str(D8),"--min-api","26","--lib",str(PLAT),
                       "--output",str(dexdir),str(jar_out)],
                      capture_output=True,text=True)
    print("D8 rc",dr.returncode); print(dr.stderr[-1000:])
print("[+] dex:",sorted(p.name for p in dexdir.iterdir() if p.is_file())[:20])

# ABI-specific lib directory
abi = args.abi
abi_dir = OUT/f"tmp/lib/{abi}"
if abi != 'universal':
    abi_dir.mkdir(parents=True,exist_ok=True)
    print(f"[+] ABI filter: {abi}")

apk_u=OUT/"app-unsigned.apk"
link=[str(AAPT2),"link","-I",str(PLAT),"-o",str(apk_u),
      "--manifest",str(ROOT/"android/app/src/main/AndroidManifest.xml"),
      "--auto-add-overlay"]
link+=flat
# DEX files are NOT valid inputs for aapt2 link; add after
lp=subprocess.run(link,capture_output=True,text=True)
print("aapt2 rc",lp.returncode); print(lp.stderr[-2000:])
if apk_u.exists(): print("apk unsigned raw:",apk_u.stat().st_size)

# Merge dex into unsigned APK (aapt2 only links resources/manifest)
dex_files = sorted(str(p) for p in dexdir.glob("*.dex") if p.is_file())
if dex_files and apk_u.exists():
    dex_apk = OUT/"app-with-dex-unsigned.apk"
    with zipfile.ZipFile(apk_u, 'r') as zin:
        with zipfile.ZipFile(dex_apk, 'w', zipfile.ZIP_DEFLATED) as zout:
            for item in zin.infolist():
                zout.writestr(item, zin.read(item.filename))
            for dex in dex_files:
                zout.write(dex, "classes.dex")
    apk_u.unlink()
    dex_apk.rename(apk_u)
    print("apk unsigned with dex:",apk_u.stat().st_size)

KEYS=pathlib.Path("/tmp/wifite32-keystore"); KEYS.mkdir(parents=True,exist_ok=True); KS=KEYS/"debug.keystore"
if not KS.exists():
    subprocess.run(["keytool","-genkeypair","-keystore",str(KS),"-alias","androiddebugkey",
                    "-storepass","android","-keypass","android","-keyalg","RSA",
                    "-validity","10000","-dname","CN=Wifite32"],check=False)
aligned=OUT/"app-aligned-unsigned.apk"; out_apk=OUT/f"wifite32-{abi}-debug.apk"
if apk_u.exists() and apk_u.stat().st_size>100:
    subprocess.run([str(ZIP),"-p","4",str(apk_u),str(aligned)],check=False)
    if aligned.exists():
        subprocess.run([str(APKSIGNER),"sign","--ks",str(KS),"--ks-key-alias","androiddebugkey",
                        "--ks-pass","pass:android","--key-pass","pass:android",
                        "--min-sdk-version","26","--out",str(out_apk),str(aligned)],check=False)

apk=out_apk
print("\n=== APK ===",apk,(apk.stat().st_size if apk.exists() else 0))
