"""把 src/template.tpl 的占位符换成 assets/paths.json 的矢量路径，产出根目录的独立单文件 HTML"""
import json, pathlib

HERE = pathlib.Path(__file__).resolve().parent
ROOT = HERE.parent
d = json.loads((ROOT / 'assets' / 'paths.json').read_text())
t = (HERE / 'template.tpl').read_text()
vb = f"0 0 {d['w']} {d['h']}"
subs = [('__VB__', vb), ('__FULL__', d['full']), ('__FRAME__', d['frame'])]
subs += [('__W__', str(d['w'])), ('__H__', str(d['h'])),
         ('__RATIO__', f"{d['h'] / d['w']:.5f}")]
subs += [(f'__L{i}__', p) for i, p in enumerate(d['letters'])]
subs += [(f'__O{i}__', f'{o[0]}% {o[1]}%') for i, o in enumerate(d['origins'])]
subs += [('__ORIGINS__', json.dumps([round(o[0], 4) for o in d['origins']]))]
for k, v in subs:
    t = t.replace(k, v)
assert '__' not in t.replace('--', '')  # 占位符必须全部替换
out = ROOT / 'sms_screensaver.html'
out.write_text(t)
print('wrote', out, len(t), 'bytes')
