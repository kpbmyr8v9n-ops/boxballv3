#!/usr/bin/env bash
# Run once after `npx cap add android`. Locks portrait, adds release signing from env vars, sets versionCode.
set -e
M=android/app/src/main/AndroidManifest.xml
grep -q screenOrientation "$M" || sed -i 's|<activity|<activity android:screenOrientation="portrait"|' "$M"
python3 - <<'PY'
import re,io
p='android/app/build.gradle';s=io.open(p,encoding='utf-8').read()
if 'KEYSTORE_PATH' not in s:
    sc='''    signingConfigs {
        release {
            if (System.getenv("KEYSTORE_PATH")) {
                storeFile file(System.getenv("KEYSTORE_PATH"))
                storePassword System.getenv("KEYSTORE_PASSWORD")
                keyAlias System.getenv("KEY_ALIAS")
                keyPassword System.getenv("KEY_PASSWORD")
            }
        }
    }
'''
    if 'buildTypes {' in s: s=s.replace('buildTypes {',sc+'    buildTypes {',1)
    else: print('WARN: buildTypes not found, signing not patched')
    s=re.sub(r'(buildTypes\s*\{\s*release\s*\{)',r'\1\n            if (System.getenv("KEYSTORE_PATH")) { signingConfig signingConfigs.release }',s,count=1)
    s=re.sub(r'versionCode\s+\d+','versionCode (System.getenv("VERSION_CODE") ?: "1").toInteger()',s,count=1)
    io.open(p,'w',encoding='utf-8').write(s);print('patched build.gradle')
PY
echo "Android patched (portrait + signing + versionCode)."
