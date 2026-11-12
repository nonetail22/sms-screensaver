"""从正面帧抠出 SMS 徽标 -> 二值掩膜 -> 轮廓分层矢量化 -> SVG path

分层依据（cv2 RETR_TREE 的轮廓深度）：
  depth 0 = 六边形外框外沿
  depth 1 = 外框内沿（洞）
  depth>=2 = 洞里的字母笔画（及其内部小洞）
=> frame  = depth<=1，evenodd 填充得到完整环形外框
   letters = depth>=2，按 120° 扇区分成 S/M/S 三块
"""
import cv2, numpy as np, json, math, os, subprocess

SRC = '/tmp/smsframes/hi/h_019.png'          # t≈0.90s，接近正面
if not os.path.exists(SRC):                   # 首次运行：直接从源视频抽这一帧
    import imageio_ffmpeg
    os.makedirs(os.path.dirname(SRC), exist_ok=True)
    video = os.path.join(os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__)))),
                         'petal_20261110_151255.mp4')
    subprocess.run([imageio_ffmpeg.get_ffmpeg_exe(), '-y', '-loglevel', 'error',
                     '-ss', '0.90', '-i', video, '-frames:v', '1', SRC], check=True)

ROI = (300, 95, 690, 500)                      # x0,y0,x1,y1（原图坐标）
                                               # 下边界留到 500：黄色底尖在原图 y≈491，
                                               # 旧的 490 会把尖角切平成一条横边
JUNCTION = (195, 200)                         # 三叶交点（ROI 坐标）
SCALE = 3                                     # 上采样倍数，平滑锯齿
REG_EPS = 9.0                                 # 外框规整容差（ROI 像素）
LET_EPS = 3.0                                 # 字母规整容差：比外框小，保留圆头/斜切
LET_JUMP = 9.0                                # 字母角点最大外推距离，防止端头被削
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))  # sms_screensaver/

a = cv2.imread(SRC)[:, :, ::-1]
x0, y0, x1, y1 = ROI
roi = a[y0:y1, x0:x1]
R, G, B = roi[:, :, 0].astype(int), roi[:, :, 1].astype(int), roi[:, :, 2].astype(int)
mask = ((R > 150) & (G > 120) & (B < 120) & ((R - B) > 70)).astype(np.uint8) * 255

# 竖向闭运算填掉拍屏摩尔纹的细横条；竖向开运算去小噪点；中值平滑边缘
mask = cv2.morphologyEx(mask, cv2.MORPH_CLOSE, cv2.getStructuringElement(cv2.MORPH_RECT, (1, 7)))
mask = cv2.morphologyEx(mask, cv2.MORPH_OPEN, cv2.getStructuringElement(cv2.MORPH_RECT, (2, 2)))
mask = cv2.medianBlur(mask, 5)
mask = cv2.copyMakeBorder(mask, 4, 4, 4, 4, cv2.BORDER_CONSTANT, value=0)
H, W = mask.shape

# 平滑后取轮廓，同时保留层级深度
up = cv2.resize(mask, (W * SCALE, H * SCALE), interpolation=cv2.INTER_LINEAR)
up = cv2.GaussianBlur(up, (0, 0), 1.6)
up = (up > 127).astype(np.uint8) * 255
cnts, hier = cv2.findContours(up, cv2.RETR_TREE, cv2.CHAIN_APPROX_SIMPLE)
hier = hier[0]

def depth_of(i):
    d, p = 0, hier[i][3]
    while p != -1:
        d += 1
        p = hier[p][3]
    return d


def straighten(P, eps=REG_EPS, trim=0.18, maxjump=14.0):
    """外框轮廓规整：把拍屏掩膜的锯齿长边拉直，并把角点交成真正的尖角。

    1) 加大 RDP 容差取「主顶点」（约 12 个），中间那些 4~25px 的短折线是锯齿/圆角过渡；
    2) 每两个主顶点之间取中段点做 TLS 直线拟合，得到这条边的真实方向；
    3) 相邻两条拟合直线求交点作为新角点 —— 被 ROI 裁平的底尖会自然被外推成交点。
    外框用大容差（REG_EPS=9）得到完全平直的锐利多边形；
    字母用小容差（LET_EPS=3）+ 更小的 maxjump，只收掉拍屏凹口，保留圆头/斜切。
    """
    A = cv2.approxPolyDP(P.astype(np.float32).reshape(-1, 1, 2), eps, True).reshape(-1, 2)
    idx = sorted(set(int(np.argmin(((P - a) ** 2).sum(1))) for a in A))
    m, n = len(idx), len(P)
    if m < 3:
        return P
    lines = []
    for k in range(m):
        i0, i1 = idx[k], idx[(k + 1) % m]
        seq, i = [], i0
        while True:
            seq.append(i)
            if i == i1 or len(seq) > n:
                break
            i = (i + 1) % n
        Q = P[seq]
        if len(Q) >= 5:                     # 两端可能是圆角过渡，只用中段拟合
            t = int(len(Q) * trim)
            if len(Q) - 2 * t >= 2:
                Q = Q[t:-t]
        if len(Q) >= 2:
            c = Q.mean(0)
            _, _, vh = np.linalg.svd(Q - c, full_matrices=False)
            d = vh[0] / np.linalg.norm(vh[0])
            lines.append((c, d))
        else:
            a, b = P[idx[k]], P[idx[(k + 1) % m]]
            dv = b - a
            if np.linalg.norm(dv) < 1e-6:
                dv = P[(idx[k] + 1) % n] - a
            lines.append((a, dv / np.linalg.norm(dv)))
    V = []
    for k in range(m):
        p1, d1 = lines[(k - 1) % m]
        p2, d2 = lines[k]
        cr = d1[0] * d2[1] - d1[1] * d2[0]
        q = None
        if abs(cr) > 1e-5:
            t = ((p2[0] - p1[0]) * d2[1] - (p2[1] - p1[1]) * d2[0]) / cr
            q = p1 + t * d1
        o = P[idx[k]]
        V.append(o if q is None or np.linalg.norm(q - o) > maxjump else q)
    return np.array(V)


items = []   # (depth, d_string, area, cx, cy)  坐标已折算回 ROI 像素
for i, c in enumerate(cnts):
    area = cv2.contourArea(c)
    if area < 40:
        continue
    p = cv2.approxPolyDP(c, 1.6 * SCALE, True).reshape(-1, 2) / SCALE - 4
    dep = depth_of(i)
    if dep <= 1:
        p = straighten(p, REG_EPS, maxjump=14.0)      # 外框：完全拉直 + 尖角
    else:
        p = straighten(p, LET_EPS, maxjump=LET_JUMP)  # 字母：轻度规整，保住圆头/斜切
    if len(p) < 3:
        continue
    m = cv2.moments(c)
    cx = (m['m10'] / m['m00'] / SCALE - 4) if m['m00'] else p[:, 0].mean()
    cy = (m['m01'] / m['m00'] / SCALE - 4) if m['m00'] else p[:, 1].mean()
    d = 'M' + 'L'.join(f'{px:.1f},{py:.1f}' for px, py in p) + 'Z'
    items.append((dep, d, area, cx, cy))

# ---- 底部尖角对齐：M 的 V 底尖、外框底尖、几何中心必须落在同一条竖线上 ----
# 拍屏透视让三者分别落在 x=194 / 197 / 195，放大后中间那个尖儿明显歪；
# 且 M 的 V 形两臂不等长（左 10、右 13.7），也会让尖儿看着偏左。
AXIS = (x1 - x0) / 2.0

def d_to_pts(s):
    return np.array([[float(v) for v in tok.split(',')]
                     for tok in s[1:-1].split('L')], float)

def pts_to_d(P):
    return 'M' + 'L'.join(f'{px:.1f},{py:.1f}' for px, py in P) + 'Z'

def align_apex(s, symmetric):
    """把最低点移到中轴；symmetric=True 时同时把 V 形两臂拉成左右等长。"""
    P = d_to_pts(s)
    k = int(P[:, 1].argmax())
    if not symmetric:                    # 外框外沿：只把底尖单点校到中轴
        P[k, 0] = AXIS
        return pts_to_d(P)
    n = len(P)
    a, b, c = (k - 1) % n, k, (k + 1) % n
    if not (P[a, 1] < P[b, 1] and P[c, 1] < P[b, 1]):
        return s                         # 不是 V 形底，不动
    if abs(P[a, 1] - P[c, 1]) > 15:
        return s
    w = ((P[b, 0] - P[a, 0]) + (P[c, 0] - P[b, 0])) / 2.0
    if w <= 0:
        return s
    yy = (P[a, 1] + P[c, 1]) / 2.0
    P[a, 0], P[c, 0] = AXIS - w, AXIS + w
    P[a, 1] = P[c, 1] = yy
    P[b, 0] = AXIS
    return pts_to_d(P)

for idx, it in enumerate(items):
    if it[0] == 0 and d_to_pts(it[1])[:, 1].max() > 0.9 * (y1 - y0):
        items[idx] = (it[0], align_apex(it[1], False), it[2], it[3], it[4])

# M 组（下方扇区）里最低的那个子路径，就是中间竖笔的 V 底尖
mids = [i for i, it in enumerate(items) if it[0] >= 2 and it[4] > 0.60 * (y1 - y0)]
if mids:
    tgt = max(mids, key=lambda i: d_to_pts(items[i][1])[:, 1].max())
    it = items[tgt]
    items[tgt] = (it[0], align_apex(it[1], True), it[2], it[3], it[4])

# ---- M 左右两笔底尖：等高 + 关于中轴镜像（只改这两个点，不动字形） ----
# 拍屏透视让左右笔底尖差 2.6px、距中轴也不等，周围不对称会把中间 V 尖「带偏」。
# 注意：不做整组镜像替换 —— 那会让 M 的三笔形状大变，偏离原片。
mlow = []
for i, it in enumerate(items):
    if it[0] >= 2 and it[4] > 0.60 * (y1 - y0):       # 下方扇区 = M 组
        P = d_to_pts(it[1])
        mlow.append([i, P, int(P[:, 1].argmax())])
if len(mlow) >= 3:
    mid_i = max(mlow, key=lambda t: t[1][t[2], 1])[0]  # 中间竖笔的 V 尖
    sides = sorted([t for t in mlow if t[0] != mid_i],
                   key=lambda t: t[1][t[2], 0])
    li, LP, lk = sides[0]
    ri, RP, rk = sides[-1]
    yy = (LP[lk, 1] + RP[rk, 1]) / 2.0                 # 两肩取平均高度
    xx = (RP[rk, 0] + (2 * AXIS - LP[lk, 0])) / 2.0    # 右 x 与「左的镜像」取平均
    LP[lk] = [2 * AXIS - xx, yy]
    RP[rk] = [xx, yy]
    for i, P in [(li, LP), (ri, RP)]:
        it = items[i]
        items[i] = (it[0], pts_to_d(P), it[2], it[3], it[4])

# ---- 下叶底尖大 V：右肩校到与左肩等高（只改外框两条轮廓各 1 个点） ----
# 拍屏透视让底 V 的右肩偏高（外沿 2.9px、内沿 1.0px），整个底部看着往右歪，
# 连套在里面的 M 中间竖笔小 V 都会被「带」成右肩高。
# 注意 M 小 V 的两肩本来就是严格等高（y=350.6），这里一个字母点都不动。
for i, it in enumerate(items):
    if it[0] > 1:                                    # 只处理外框外沿 / 内沿
        continue
    P = d_to_pts(it[1])
    k = int(P[:, 1].argmax())                       # 底尖
    n = len(P)
    a, b = (k - 1) % n, (k + 1) % n                 # V 的两个肩
    left, right = (a, b) if P[a, 0] < P[b, 0] else (b, a)
    P[right, 1] = P[left, 1]
    items[i] = (it[0], pts_to_d(P), it[2], it[3], it[4])

def join(group):
    return ''.join(it[1] for it in group)

# 三个 120° 扇区：上左 / 上右 / 下
def sector(cx, cy):
    ang = math.degrees(math.atan2(cy - JUNCTION[1], cx - JUNCTION[0]))
    if ang >= 150 or ang <= -90: return 0
    if -90 < ang <= 30: return 1
    return 2

frame_items = [it for it in items if it[0] <= 1]
letter_items = [it for it in items if it[0] >= 2]
letters = [[], [], []]
for it in letter_items:
    letters[sector(it[3], it[4])].append(it)

# 每块字母的自转轴：按轮廓面积加权的质心
origins = []
for grp in letters:
    wa = sum(it[2] for it in grp) or 1
    ox = sum(it[2] * it[3] for it in grp) / wa
    oy = sum(it[2] * it[4] for it in grp) / wa
    origins.append([round(100 * ox / (x1 - x0), 2), round(100 * oy / (y1 - y0), 2)])

data = {
    'w': x1 - x0, 'h': y1 - y0,
    'full': join(items),          # 默认整块旋转
    'frame': join(frame_items),   # 自转模式下保持完整的外框
    'letters': [join(g) for g in letters],
    'origins': origins,
}
with open(os.path.join(ROOT, 'assets', 'paths.json'), 'w') as f:
    json.dump(data, f)

svg = f'''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {x1-x0} {y1-y0}" width="{x1-x0}" height="{y1-y0}">
<rect width="100%" height="100%" fill="#0a0a0a"/>
<path d="{data['full']}" fill="#ffd21e" fill-rule="evenodd"/>
</svg>'''
open(os.path.join(ROOT, 'assets', 'emblem.svg'), 'w').write(svg)

print('contours', len(items), '| frame', len(frame_items), '| letters', [len(g) for g in letters])
print('origins %', origins)
