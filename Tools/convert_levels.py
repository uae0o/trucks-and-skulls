import plistlib
from plistlib import UID
import os
import json

APP_DIR = r"c:\Users\hunter\Downloads\trey\Trucks and Skulls v2.3.1 IPHONE  HS.ipa\Payload\TrucksAndSkulls.app"
OUT_DIR = r"C:\Users\hunter\Downloads\TrucksAndSkulls_Unity\Assets\StreamingAssets"
LEVELS_OUT = os.path.join(OUT_DIR, "Levels")
os.makedirs(LEVELS_OUT, exist_ok=True)

def decode_nk(pl):
    objs = pl[chr(36)+'objects']
    def resolve(ref, depth=0):
        if depth > 50: return None
        if isinstance(ref, UID):
            return resolve(objs[ref.data], depth+1)
        if isinstance(ref, dict):
            if 'NS.keys' in ref and 'NS.objects' in ref:
                keys = [resolve(k, depth+1) for k in ref['NS.keys']]
                vals = [resolve(v, depth+1) for v in ref['NS.objects']]
                return dict(zip(keys, vals))
            if 'NS.objects' in ref:
                return [resolve(v, depth+1) for v in ref['NS.objects']]
            if 'NS.time' in ref:
                return ref['NS.time']
            result = {}
            for k, v in ref.items():
                if k.startswith(chr(36)): continue
                result[k] = resolve(v, depth+1)
            return result
        if isinstance(ref, list):
            return [resolve(i, depth+1) for i in ref]
        return ref
    root_ref = pl[chr(36)+'top']['root']
    return resolve(root_ref)

# 1. Convert Episodes.plist
episodes_plist = os.path.join(APP_DIR, "Episodes.plist")
if os.path.exists(episodes_plist):
    with open(episodes_plist, 'rb') as f:
        ep_data = plistlib.load(f)
    episodes_list = []
    for ep in ep_data.get('Episodes', []):
        episodes_list.append({
            'name': ep.get('VisibleName', ''),
            'levels': ep.get('Levels', []),
            'background': ep.get('MenuBackground', ''),
            'thumbnail': ep.get('Thumbnail', '')
        })
    with open(os.path.join(OUT_DIR, "episodes.json"), 'w', encoding='utf-8') as f:
        json.dump(episodes_list, f, indent=2)
    print(f"Exported {len(episodes_list)} episodes to episodes.json")

# 2. Convert all Levels/*.POND
levels_in = os.path.join(APP_DIR, "Levels")
converted_count = 0
level_index = []

for fname in sorted(os.listdir(levels_in)):
    if not fname.endswith('.POND'): continue
    file_base = os.path.splitext(fname)[0]
    in_path = os.path.join(levels_in, fname)
    try:
        with open(in_path, 'rb') as f:
            pl = plistlib.load(f)
        level_raw = decode_nk(pl)
        
        parts_raw = level_raw.get('structurePartDescriptorDicts', [])
        if not isinstance(parts_raw, list):
            parts_raw = [parts_raw] if parts_raw else []
            
        parts = []
        for p in parts_raw:
            if not isinstance(p, dict): continue
            pos = p.get('Position', {'X': 0.0, 'Y': 0.0})
            parts.append({
                'name': p.get('Name', ''),
                'x': float(pos.get('X', 0.0)),
                'y': float(pos.get('Y', 0.0)),
                'angle': float(p.get('Angle', 0.0)),
                'hinged': bool(p.get('Hinged', False))
            })
            
        projs_raw = level_raw.get('projectileDescriptors', [])
        if not isinstance(projs_raw, list):
            projs_raw = [projs_raw] if projs_raw else []
        projectiles = [str(x) for x in projs_raw if isinstance(x, str)]
        
        dims = level_raw.get('dimensions', {'Width': 2034.0, 'Height': 768.0})
        launcher = level_raw.get('launcherStart', {'X': -600.0, 'Y': -180.0})
        
        clean_level = {
            'file': file_base,
            'name': level_raw.get('visibleName', file_base),
            'theme': level_raw.get('themeName', ''),
            'width': float(dims.get('Width', 2034.0)),
            'height': float(dims.get('Height', 768.0)),
            'launcherX': float(launcher.get('X', -600.0)),
            'launcherY': float(launcher.get('Y', -180.0)),
            'projectiles': projectiles,
            'parts': parts
        }
        
        out_file = os.path.join(LEVELS_OUT, f"{file_base}.json")
        with open(out_file, 'w', encoding='utf-8') as f:
            json.dump(clean_level, f, indent=2)
            
        level_index.append({
            'file': file_base,
            'name': clean_level['name'],
            'theme': clean_level['theme'],
            'partsCount': len(parts),
            'projectilesCount': len(projectiles)
        })
        converted_count += 1
    except Exception as e:
        print(f"Failed {fname}: {e}")

with open(os.path.join(OUT_DIR, "levels_index.json"), 'w', encoding='utf-8') as f:
    json.dump(level_index, f, indent=2)

print(f"Successfully converted {converted_count} levels to JSON!")
