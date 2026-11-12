<!DOCTYPE html>
<html lang="zh-CN">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>S.M.S. // Screensaver v1.0</title>
<!-- S.M.S. Screensaver v1.0 · https://github.com/nonetail22/sms-screensaver -->
<style>
:root{
  --period:12s;
  --persp:1400px;   /* 拉近透视：让字母绕直径翻转时有可见的近大远小，而不像单纯压扁 */
  --size:52;
  --glow:1;
  --g1:5px; --g2:22px; --g3:48px;
  --alpha:0.6;   /* 字母不透明度，边框恒为 1 */
  --thick:4;     /* 笔画加粗，单位 = SVG viewBox 用户单位 */
  --scan:1;
  --hudb:.42;    /* HUD 文字亮度（面板「HUD 亮度」滑块，?hb=） */
  --tuib:1;      /* 终端层亮度（面板「终端亮度」滑块，?tb=） */
  --amb:255,190,84;  /* 终端暗琥珀（与徽标同一黄色系，只调亮度层级） */
  --yellow:#ffd21e;
}
*{box-sizing:border-box}
html,body{height:100%;margin:0;overflow:hidden}
body{
  background:#08090a;color:#cfd2d4;min-height:100vh;
  font:12px/1.6 ui-monospace,"SF Mono",Menlo,Consolas,monospace;
  -webkit-font-smoothing:antialiased;
}
body::before{
  content:"";position:fixed;inset:0;pointer-events:none;
  background:radial-gradient(ellipse at 50% 48%,#14161a 0%,#0b0c0e 45%,#050506 100%);
}
body::after{
  content:"";position:fixed;inset:0;pointer-events:none;
  background:repeating-linear-gradient(to bottom,rgba(0,0,0,.55) 0 1px,transparent 1px 4px);
  opacity:calc(var(--scan) * .32);
}

#stage{
  position:fixed;inset:0;min-height:100vh;display:grid;place-items:center;
  perspective:var(--persp);perspective-origin:50% 50%;
  -webkit-perspective:var(--persp);
}
#plate{
  width:calc(var(--size) * 1vmin);
  height:calc(var(--size) * __RATIO__vmin);   /* 与 viewBox 同比，不依赖 aspect-ratio */
  aspect-ratio:__W__ / __H__;
  position:relative;
  transform-style:preserve-3d;
  animation:revolve var(--period) linear infinite;
}
@keyframes revolve{from{transform:rotateY(0)}to{transform:rotateY(360deg)}}
/* 摆动模式：不翻面，左右匀速来回（原片只有 2 秒，无法排除这种可能） */
@keyframes swing{from{transform:rotateY(-62deg)}to{transform:rotateY(62deg)}}
body.swing #plate{animation-name:swing;animation-duration:calc(var(--period) / 2);animation-direction:alternate}

.layer{position:absolute;inset:0;width:100%;height:100%;transform-style:preserve-3d;-webkit-transform-style:preserve-3d}
svg{display:block;width:100%;height:100%;overflow:visible}
/* 整体加厚：沿轮廓描同色边，笔画变粗、镂空收窄，视觉更厚重 */
.plate-svg path{
  stroke:#ffd21e;stroke-width:var(--thick);paint-order:stroke fill;
}
.plate-svg{
  filter:
    drop-shadow(0 0 var(--g1) rgba(255,214,40,.9))
    drop-shadow(0 0 var(--g2) rgba(255,176,0,.5))
    drop-shadow(0 0 var(--g3) rgba(255,150,0,.22));
  -webkit-filter:
    drop-shadow(0 0 var(--g1) rgba(255,214,40,.9))
    drop-shadow(0 0 var(--g2) rgba(255,176,0,.5))
    drop-shadow(0 0 var(--g3) rgba(255,150,0,.22));
}
body.noback .layer{backface-visibility:hidden}

/* 外框：完整一整层绕竖直轴 3D 翻转，始终不透明。
   字母层不套在这层里（否则外框侧面时字母会被一起压成线），
   改由每个 tile 自己的 keyframes 做「轴心平移 + 自身翻牌」。 */
body:not(.spin) .spinlayer,body:not(.spin) .letterlayer{display:none}
body.spin .whole{display:none}
/* 自转模式下由外框层接替整体公转，避免两层旋转叠加成双倍速 */
body.spin #plate{animation:none}
body.spin.framespin .spinlayer{
  animation:revolve var(--period) linear infinite;
  transform-origin:50% 50%;
}
.spinlayer .frame{position:absolute;inset:0;opacity:1}

/* 每个 tile = translateX(轴心位移) + rotateY(真实 3D 自转)。
   轴心位移 (c-1)(x-50)%，c=k+(1-k)|cosθ|；follow=1 ⇒ 外框侧面时 c=0，
   三个轴心全压到中线，两个 S 完全重合。
   所有 tile 动画周期统一 P/2（与 |cosθ| 同周期，轴心才同步）：
     S(1/2)：rotateY(2θ+ph)，一周期转 1 圈 = 2ω（脱离外框 ω 独立自转）
     M(3)  ：rotateY(4θ)，一周期转 2 圈 = 4ω
   ⇒ S 的自转角速度正好是 M 的 1/2；θ=90°（外框侧面）时 S 转到 180°、
     即全宽背面，两个 S 重合且半透明可辨。t=0 三者角度都是 0，
     外框 + 两个 S + M 全部正面，组成完整初始图案。?ph=90 可给 S 加相位偏移。 */
.letterlayer .tile{
  position:absolute;inset:0;
  animation-timing-function:linear;
  animation-iteration-count:infinite;
  animation-duration:calc(var(--period) / 2);   /* 三层统一周期，与 |cosθ| 同步 */
  animation-delay:0s;
  opacity:var(--alpha);
  transform-style:preserve-3d;-webkit-transform-style:preserve-3d;
}
.letterlayer .tile:nth-of-type(1){animation-name:leaf1;transform-origin:__O0__}
.letterlayer .tile:nth-of-type(2){animation-name:leaf2;transform-origin:__O1__}
.letterlayer .tile:nth-of-type(3){animation-name:leaf3;transform-origin:__O2__}
/* 可选：统一翻转轴到整体中心 */
body.centeraxis .letterlayer .tile{transform-origin:50% 50%}
/* 可选：错相（默认关，打开会破坏两个 S 的同步） */
body.stagger .letterlayer .tile:nth-of-type(2){animation-delay:calc(var(--period) / -3)}
body.stagger .letterlayer .tile:nth-of-type(3){animation-delay:calc(var(--period) / -1.5)}

/* !important 必须保留：body.spin.framespin .spinlayer 的 animation 简写
   会把 animation-play-state 重置回 running 且特异性更高，不加会被压掉，
   表现为「暂停后边框还在转」。终端层的扫描扇形/光标/接触波纹一并冻结。 */
body.paused #plate,body.paused .spinlayer,body.paused .letterlayer,body.paused .tile,
body.paused .sweep,body.paused .crt,body.paused #contact i,
body.paused .starlayer,body.paused #twk i,body.paused .lk,body.paused .meteor{animation-play-state:paused !important}

/* ===== 深空星域层（第二批：三层视差星空 / 闪烁星 / 偶发流星 / 徽标锁定框） =====
   #deep 在 #tui 之前 ⇒ 星空画在雷达环和徽标后面。
   星点是 JS 生成的 box-shadow 场（种子固定，每次刷新同一片星空），
   三层以不同速度向左漂移 = 舰船缓慢前行；亮色限于暖白/暗琥珀，不破坏配色纪律。 */
#deepfx{position:fixed;inset:0;pointer-events:none;overflow:hidden;
      opacity:var(--tuib,1);display:none;z-index:0}
body.deep #deepfx{display:block}
#starfield,#meteorbox{position:absolute;inset:0;overflow:hidden}
/* 星点形状 = 元素本体（JS 按层设定直径），border-radius:50% 画圆。
   不能用「1px 元素 + box-shadow spread」：0.5px 圆角会被取整成直角，星星变方。 */
.starlayer{position:absolute;top:0;left:0;border-radius:50%;animation:drift linear infinite}
@keyframes drift{to{transform:translateX(calc(-1 * var(--sw)))}}
#twk i{position:absolute;width:2px;height:2px;border-radius:50%;
  background:rgba(255,248,230,.95);animation:twk 4s ease-in-out infinite}
@keyframes twk{0%,100%{opacity:.08}50%{opacity:.95}}
.meteor{position:absolute;height:1.5px;border-radius:1px;
  background:linear-gradient(to right,rgba(255,244,214,0),rgba(255,244,214,.9));
  animation:meteorfly 1s linear forwards}
@keyframes meteorfly{
  0%{transform:translate(var(--x0),var(--y0)) rotate(var(--rot));opacity:0}
  12%{opacity:1}
  100%{transform:translate(calc(var(--x0) + var(--dx)),calc(var(--y0) + var(--dy))) rotate(var(--rot));opacity:0}}
/* 锁定框：贴着徽标四角的 L 括号 + 目标标签 + 每 14s 闪一次的 LOCK */
#lock{position:absolute;left:50%;top:50%;
  width:min(calc(var(--size) * 1.18vmin),92vmin);aspect-ratio:390 / 405;
  transform:translate(-50%,-50%)}
#lock .lb{position:absolute;width:22px;height:22px;border:1px solid rgba(var(--amb),.55)}
#lock .lb1{top:-8px;left:-8px;border-right:0;border-bottom:0}
#lock .lb2{top:-8px;right:-8px;border-left:0;border-bottom:0}
#lock .lb3{bottom:-8px;left:-8px;border-right:0;border-top:0}
#lock .lb4{bottom:-8px;right:-8px;border-left:0;border-top:0}
#lock .lt,#lock .lk{position:absolute;top:-21px;font-size:8px;letter-spacing:.22em;
  white-space:nowrap;color:rgba(var(--amb),.75)}
#lock .lt{left:0}
#lock .lk{right:0;color:rgba(var(--amb),.95);opacity:0;animation:lockblink 14s linear infinite}
@keyframes lockblink{0%,5.5%,9.5%,15.5%,100%{opacity:0}
  6.5%,8.5%{opacity:1}11%,13.5%{opacity:1}}

/* ===== 军用终端层（第一批：机框 / 状态栏 / 遥测 / 雷达环 / 日志） =====
   配色纪律：整屏只有黄色一个色相 —— 徽标亮黄，终端元素全部暗琥珀，
   亮度 10%~50%，保证徽标永远是唯一主角。
   #tui 在 #stage 之前 ⇒ 雷达环画在徽标正后方，与徽标同心「自我锁定」。 */
#tui{position:fixed;inset:0;pointer-events:none;overflow:hidden;
     opacity:var(--tuib,1);display:none;z-index:0}
body.terminal #tui{display:block}
.bracket{position:absolute;width:30px;height:30px;border:1px solid rgba(var(--amb),.45)}
.bracket.tl{top:12px;left:12px;border-right:0;border-bottom:0}
.bracket.tr{top:12px;right:12px;border-left:0;border-bottom:0}
.bracket.bl{bottom:12px;left:12px;border-right:0;border-top:0}
.bracket.br{bottom:12px;right:12px;border-left:0;border-top:0}
/* 刻度尺：短刻度 12px 间隔（5px 高），::after 长刻度 60px 间隔（9px 高） */
.ruler{position:absolute}
.ruler.h{left:54px;right:54px;height:9px;
  background:repeating-linear-gradient(90deg,rgba(var(--amb),.3) 0 1px,transparent 1px 12px) 0 100%/100% 5px no-repeat}
.ruler.h::after{content:"";position:absolute;inset:0;
  background:repeating-linear-gradient(90deg,rgba(var(--amb),.45) 0 1px,transparent 1px 60px) 0 0/100% 9px no-repeat}
.ruler.h.top{top:24px}
.ruler.h.bot{bottom:24px}
.ruler.v{top:66px;bottom:66px;width:9px;
  background:repeating-linear-gradient(0deg,rgba(var(--amb),.3) 0 1px,transparent 1px 12px) 100% 0/5px 100% no-repeat}
.ruler.v::after{content:"";position:absolute;inset:0;
  background:repeating-linear-gradient(0deg,rgba(var(--amb),.45) 0 1px,transparent 1px 60px) 0 0/9px 100% no-repeat}
.ruler.v.left{left:16px}
.ruler.v.right{right:16px}
#statusbar{position:absolute;top:9px;left:50%;transform:translateX(-50%);
  white-space:nowrap;font-size:9px;letter-spacing:.18em;color:rgba(var(--amb),.5)}
#statusbar s{text-decoration:none;color:rgba(var(--amb),.25);margin:0 .6ch}
#statusbar em{color:rgba(var(--amb),.85)}
.crt{display:inline-block;width:6px;height:9px;margin-left:9px;vertical-align:-1px;
  background:rgba(var(--amb),.65);animation:crt 1.2s steps(1) infinite}
@keyframes crt{50%{opacity:0}}
.tele{position:absolute;top:50%;transform:translateY(-50%);
  font-size:9px;line-height:2.1;letter-spacing:.14em;color:rgba(var(--amb),.42)}
.tele.left{left:34px}
.tele.right{right:34px;text-align:right}
.tele .k{opacity:.6}
.tele .v{color:rgba(var(--amb),.72);font-variant-numeric:tabular-nums;
  display:inline-block;min-width:7ch;text-align:right}
.tele.right .v{text-align:left}
#log{position:absolute;left:50%;bottom:70px;transform:translateX(-50%);
  width:82%;text-align:center;font-size:9px;letter-spacing:.16em;
  color:rgba(var(--amb),.55);line-height:1.9}
#log .line{animation:login .7s ease-out}
#log .line.dim{opacity:.38}
@keyframes login{from{opacity:0;transform:translateY(5px)}}
/* 雷达环：直径 ≈1.9× 徽标宽，超出视口封顶 96vmin；扫描扇形 24s 一圈 */
#tactical{position:absolute;left:50%;top:50%;
  width:min(calc(var(--size) * 1.9vmin),96vmin);aspect-ratio:1;
  transform:translate(-50%,-50%)}
#tactical .ring{position:absolute;border:1px solid rgba(var(--amb),.13);border-radius:50%}
#tactical .r1{inset:0}
#tactical .r2{inset:18.5%}
#tactical .r3{inset:37%}
#tactical .ticks{position:absolute;inset:-1.2%;border-radius:50%;
  background:repeating-conic-gradient(rgba(var(--amb),.32) 0deg .4deg,transparent .4deg 5deg);
  -webkit-mask:radial-gradient(circle,transparent 63%,#000 63.4%,#000 65.4%,transparent 65.8%);
          mask:radial-gradient(circle,transparent 63%,#000 63.4%,#000 65.4%,transparent 65.8%)}
#tactical .sweep{position:absolute;inset:0;border-radius:50%;
  background:conic-gradient(from 0deg,rgba(var(--amb),.09),transparent 62deg 360deg);
  animation:sweep 24s linear infinite}
@keyframes sweep{to{transform:rotate(360deg)}}
#tactical .cross{position:absolute;inset:0;
  background:linear-gradient(rgba(var(--amb),.09),rgba(var(--amb),.09)) 50% 50%/100% 1px no-repeat,
             linear-gradient(rgba(var(--amb),.09),rgba(var(--amb),.09)) 50% 50%/1px 100% no-repeat}
/* 偶发「接触目标」：30~70s 一次，亮 3.4s 后消失；落到 r1 环上 */
#contact{position:absolute;display:none}
#contact i{position:absolute;left:-3px;top:-3px;width:6px;height:6px;border-radius:50%;
  background:rgba(var(--amb),.95);animation:ping 1.1s ease-out infinite}
#contact span{position:absolute;left:10px;top:-7px;white-space:nowrap;
  font-size:8px;letter-spacing:.2em;color:rgba(var(--amb),.8)}
@keyframes ping{from{box-shadow:0 0 0 0 rgba(var(--amb),.45)}
                to{box-shadow:0 0 0 14px rgba(var(--amb),0)}}

/* HUD */
.hud{position:fixed;pointer-events:none;color:#8b9096;letter-spacing:.22em;
     text-transform:uppercase;font-size:10px;opacity:var(--hudb,.42);transition:opacity .5s}
body.nohud .hud{opacity:0}
.hud.tl{top:22px;left:26px}
.hud.tr{top:22px;right:26px;text-align:right}
.hud.bc{bottom:26px;left:0;right:0;text-align:center;font-size:11px;letter-spacing:.42em}
/* 终端模式下 HUD 让位，避免与刻度尺/日志重叠：
   顶部横刻度尺占 y24~33 ⇒ 左上/右上 HUD 下移到 44，并左右内缩躲开竖刻度尺；
   底部刻度尺占 y727~736 ⇒ 底部 HUD 上移到 44（日志 70，三层互不接触） */
body.terminal .hud.tl{top:44px;left:36px}
body.terminal .hud.tr{top:44px;right:36px}
body.terminal .hud.bc{bottom:44px}
.hud.tl b{color:var(--yellow);font-weight:600}

/* 调参面板 */
#panel{
  position:fixed;top:58px;right:26px;width:252px;padding:16px 16px 12px;
  background:rgba(16,18,21,.88);border:1px solid rgba(255,210,30,.18);
  border-radius:10px;backdrop-filter:blur(14px);-webkit-backdrop-filter:blur(14px);
  box-shadow:0 12px 40px rgba(0,0,0,.6);
  transition:opacity .45s;z-index:10;
  max-height:calc(100vh - 92px);overflow-y:auto;
}
body.idle #panel{opacity:0;pointer-events:none}
body.hidepanel #panel{display:none}
body.collapsed #panel{display:none}
#fab{
  position:fixed;bottom:22px;left:26px;right:auto;z-index:11;width:auto;flex:none;
  padding:5px 13px;font-size:10px;letter-spacing:.12em;
  color:#cfd2d4;background:rgba(18,21,24,.85);border:1px solid #3a3f45;border-radius:6px;
  transition:opacity .4s;
}
#fab:hover{border-color:var(--yellow);color:var(--yellow)}
body.hidepanel #fab{opacity:.14}
body.hidepanel #fab:hover{opacity:1}
body.idle #fab{opacity:0;pointer-events:none}
#panel h1{margin:0 0 12px;font-size:11px;letter-spacing:.2em;color:var(--yellow);font-weight:600}
#panel h1 span{display:block;color:#6c7176;letter-spacing:.08em;font-size:9px;font-weight:400;margin-top:3px}
.row{display:flex;align-items:center;justify-content:space-between;gap:8px;margin:6px 0;font-size:11px}
.row label{color:#a9aeb3;white-space:nowrap}
.row output{color:var(--yellow);min-width:48px;text-align:right;font-variant-numeric:tabular-nums}
input[type=range]{-webkit-appearance:none;appearance:none;width:100%;height:3px;margin:0 0 6px;
  background:#34383d;border-radius:3px;outline:none}
input[type=range]::-webkit-slider-thumb{-webkit-appearance:none;width:11px;height:11px;
  border-radius:50%;background:var(--yellow);cursor:pointer;box-shadow:0 0 8px rgba(255,210,30,.6)}
.checks{display:grid;grid-template-columns:1fr 1fr;gap:6px 10px;margin:12px 0 10px}
.checks label{display:flex;align-items:center;gap:6px;font-size:11px;color:#a9aeb3;cursor:pointer}
input[type=checkbox]{accent-color:#ffd21e;width:13px;height:13px;margin:0;cursor:pointer}
.btns{display:flex;gap:6px;margin-top:6px}
button{flex:1;background:#22262b;color:#cfd2d4;border:1px solid #3a3f45;border-radius:5px;
  padding:6px 4px;font:inherit;font-size:10px;cursor:pointer}
button:hover{border-color:#ffd21e;color:#ffd21e}
.hint{margin-top:10px;font-size:9px;color:#62676c;line-height:1.7;letter-spacing:.02em}
body.idle{cursor:none}
</style>
</head>
<body>

<div id="deepfx" aria-hidden="true">
  <div id="starfield"></div>
  <div id="twk"></div>
  <div id="meteorbox"></div>
  <div id="lock">
    <div class="lb lb1"></div><div class="lb lb2"></div>
    <div class="lb lb3"></div><div class="lb lb4"></div>
    <div class="lt">TGT: S.M.S. // IDENT VERIFIED</div>
    <div class="lk">● LOCK</div>
  </div>
</div>

<div id="tui" aria-hidden="true">
  <div id="tactical">
    <div class="cross"></div>
    <div class="ring r1"></div><div class="ring r2"></div><div class="ring r3"></div>
    <div class="ticks"></div>
    <div class="sweep"></div>
    <div id="contact"><i></i><span>UNK-042</span></div>
  </div>
  <div class="bracket tl"></div><div class="bracket tr"></div>
  <div class="bracket bl"></div><div class="bracket br"></div>
  <div class="ruler h top"></div><div class="ruler h bot"></div>
  <div class="ruler v left"></div><div class="ruler v right"></div>
  <div id="statusbar">S.M.S. TACTICAL DISPLAY v2.4<s>//</s>NODE: MFR-25<s>//</s>LINK: <em>SECURE</em><s>//</s>PWR <em id="pwr">98.2%</em><i class="crt"></i></div>
  <div class="tele left" id="teleL"></div>
  <div class="tele right" id="teleR"></div>
  <div id="log"></div>
</div>

<div id="stage">
  <div id="plate">
    <div class="layer whole">
      <svg class="plate-svg" width="100%" height="100%" viewBox="__VB__" preserveAspectRatio="xMidYMid meet" aria-label="S.M.S. emblem">
        <path fill="#ffd21e" fill-rule="evenodd" d="__FULL__"/>
      </svg>
    </div>
    <div class="layer spinlayer">
      <svg class="frame plate-svg" width="100%" height="100%" viewBox="__VB__" preserveAspectRatio="xMidYMid meet">
        <path fill="#ffd21e" fill-rule="evenodd" d="__FRAME__"/>
      </svg>
    </div>
    <div class="layer letterlayer">
      <div class="tile"><svg class="plate-svg" width="100%" height="100%" viewBox="__VB__" preserveAspectRatio="xMidYMid meet"><path fill="#ffd21e" fill-rule="evenodd" d="__L0__"/></svg></div>
      <div class="tile"><svg class="plate-svg" width="100%" height="100%" viewBox="__VB__" preserveAspectRatio="xMidYMid meet"><path fill="#ffd21e" fill-rule="evenodd" d="__L1__"/></svg></div>
      <div class="tile"><svg class="plate-svg" width="100%" height="100%" viewBox="__VB__" preserveAspectRatio="xMidYMid meet"><path fill="#ffd21e" fill-rule="evenodd" d="__L2__"/></svg></div>
    </div>
  </div>
</div>

<div class="hud tl"><b>S.M.S.</b><br>STRATEGIC MILITARY SERVICES<br>MACROSS FRONTIER // 2059</div>
<div class="hud tr">MFR-25 / IDLE<br>DISPLAY 01 / STANDBY</div>
<div class="hud bc">STRATEGIC MILITARY SERVICES</div>

<button id="fab" type="button">收起</button>

<div id="panel">
  <h1>S.M.S. 屏保<span>参数实时生效 · 自动写入地址栏</span></h1>
  <div class="row"><label for="period">一圈周期</label><output id="period_v"></output></div>
  <input type="range" id="period" min="2" max="20" step="0.1" value="12">
  <div class="row"><label for="persp">透视距离</label><output id="persp_v"></output></div>
  <input type="range" id="persp" min="800" max="6000" step="100" value="1400">
  <div class="row"><label for="size">标志尺寸</label><output id="size_v"></output></div>
  <input type="range" id="size" min="25" max="85" step="1" value="52">
  <div class="row"><label for="glow">发光强度</label><output id="glow_v"></output></div>
  <input type="range" id="glow" min="0" max="2" step="0.05" value="1">
  <div class="row"><label for="follow">轴心跟随</label><output id="follow_v"></output></div>
  <input type="range" id="follow" min="0" max="1" step="0.05" value="1">
  <div class="row"><label for="alpha">字母透明度</label><output id="alpha_v"></output></div>
  <input type="range" id="alpha" min="0.1" max="1" step="0.05" value="0.6">
  <div class="row"><label for="thick">图形厚度</label><output id="thick_v"></output></div>
  <input type="range" id="thick" min="0" max="12" step="0.5" value="4">
  <div class="row"><label for="hudb">HUD 亮度</label><output id="hudb_v"></output></div>
  <input type="range" id="hudb" min="0" max="1" step="0.05" value="0.42">
  <div class="row"><label for="tb">叠加亮度</label><output id="tb_v"></output></div>
  <input type="range" id="tb" min="0" max="1" step="0.05" value="1">
  <div class="row"><label for="terminal">显示终端层</label><input type="checkbox" id="terminal"></div>
  <div class="row"><label for="deep">显示星域</label><input type="checkbox" id="deep"></div>
  <div class="checks">
    <label><input type="checkbox" id="spin" checked>三字母各自转</label>
    <label><input type="checkbox" id="frameSpin" checked>整体一起转</label>
    <label><input type="checkbox" id="centerAxis">字母同轴</label>
    <label><input type="checkbox" id="stagger">字母错相</label>
    <label><input type="checkbox" id="back" checked>显示背面</label>
    <label><input type="checkbox" id="scan" checked>扫描线</label>
    <label><input type="checkbox" id="hud" checked>HUD 文字</label>
    <label><input type="checkbox" id="swing">左右摆动</label>
    <label><input type="checkbox" id="panelOn" checked>调参面板</label>
  </div>
  <div class="btns">
    <button id="pause">暂停</button>
    <button id="full">全屏</button>
    <button id="reset">复位</button>
  </div>
  <div class="hint">t=0 全部正面组成完整图案；<b>S 自转 2ω、M 自转 4ω</b>（S 是 M 的一半）<br>外框侧面时两 S 全宽重合、半透明可辨 ·「厚度」= 笔画加粗<br>终端层 ?tui=0 · 星域（星空/流星/锁定框）?deep=0<br>H 折叠 · F 全屏 · 空格 暂停 · R 复位 · ?ph=90 相位偏移 · ?panel=0 纯净屏保</div>
</div>

<script>
(function(){
  var root=document.documentElement, body=document.body;
  var q=new URLSearchParams(location.search);
  function num(k,d){var v=parseFloat(q.get(k));return isFinite(v)?v:d;}
  function flag(k,d){return q.has(k)?q.get(k)==='1':d;}
  var OX=__ORIGINS__;   /* 三个字母块的面积加权质心 x（%） */

  var cfg={
    period:num('p',12), persp:num('ps',1400), size:num('s',52),
    glow:num('g',1), follow:num('fl',1), alpha:num('al',0.6), thick:num('th',4),
    hudb:num('hb',0.42), tb:num('tb',1),
    terminal:flag('tui',true), deep:flag('deep',true),
    sPhase:num('ph',0),
    spin:flag('spin',true), back:flag('b',true),
    scan:flag('sc',true), hud:flag('h',true), panel:flag('panel',true),
    swing:flag('sw',false), collapsed:flag('c',false),
    frameSpin:flag('fs',true), centerAxis:flag('ax',false),
    stagger:flag('stag',false)
  };
  var ranges=['period','persp','size','glow','follow','alpha','thick','hudb','tb'];
  var checks=['spin','frameSpin','centerAxis','stagger','back','scan','hud','swing','terminal','deep'];

  /* 三套 keyframes，周期统一 P/2 ⇒ θ=2πt/P 在一个周期内走 0..π
       轴心位移 pct=(c-1)(x-50)，c=k+(1-k)|cosθ|，k=1-follow
       S(1/2)：rotateY(2θ+ph) —— 一周期转 1 圈 = 2ω
       M(3)  ：rotateY(4θ)    —— 一周期转 2 圈 = 4ω，正好是 S 的 2 倍
     用真实 rotateY 而非 scaleX：透视形变让「自转」在视觉上成立；
     纯 translate + 3D rotate，无补偿除法，c=0 也不会数值发散。 */
  var dyn=document.createElement('style');
  document.head.appendChild(dyn);
  var dynCache=null;
  function buildDyn(f,ph){
    var key=f+'|'+ph;
    if(dynCache===key)return;
    dynCache=key;
    var k=1-Math.max(0,Math.min(1,f));
    var phase=ph*Math.PI/180;
    var N=120, out=[], t, i, frac, th, c, pct, ang, frames, isM;
    for(t=0;t<3;t++){
      isM=(t===2);
      frames=[];
      for(i=0;i<=N;i++){
        frac=i/N;
        th=Math.PI*frac;                       /* θ ∈ [0,π]，与 |cosθ| 周期一致 */
        c=k+(1-k)*Math.abs(Math.cos(th));
        pct=(c-1)*(OX[t]-50);
        ang=(isM?4*th:2*th+phase)*180/Math.PI;
        frames.push((frac*100).toFixed(3)+'%{transform:translateX('+
                     pct.toFixed(4)+'%) rotateY('+ang.toFixed(4)+'deg)}');
      }
      out.push('@keyframes leaf'+(t+1)+'{'+frames.join('')+'}');
    }
    dyn.textContent=out.join('');
  }

  function apply(){
    root.style.setProperty('--period',cfg.period+'s');
    root.style.setProperty('--persp',cfg.persp+'px');
    root.style.setProperty('--size',cfg.size);
    root.style.setProperty('--glow',cfg.glow);
    root.style.setProperty('--g1',(5*cfg.glow).toFixed(2)+'px');
    root.style.setProperty('--g2',(22*cfg.glow).toFixed(2)+'px');
    root.style.setProperty('--g3',(48*cfg.glow).toFixed(2)+'px');
    root.style.setProperty('--alpha',cfg.alpha);
    root.style.setProperty('--hudb',cfg.hudb);
    root.style.setProperty('--tuib',cfg.tb);
    root.style.setProperty('--thick',cfg.thick);
    root.style.setProperty('--scan',cfg.scan?1:0);
    body.classList.toggle('spin',cfg.spin);
    body.classList.toggle('noback',!cfg.back);
    body.classList.toggle('nohud',!cfg.hud);
    body.classList.toggle('terminal',cfg.terminal);
    body.classList.toggle('deep',cfg.deep);
    body.classList.toggle('swing',cfg.swing);
    body.classList.toggle('framespin',cfg.frameSpin);
    body.classList.toggle('centeraxis',cfg.centerAxis);
    body.classList.toggle('stagger',cfg.stagger);
    buildDyn(cfg.follow,cfg.sPhase);
    body.classList.toggle('hidepanel',!cfg.panel);
    body.classList.toggle('collapsed',cfg.collapsed);
    document.getElementById('panelOn').checked=cfg.panel;
    document.getElementById('fab').textContent=cfg.collapsed?'参数':'收起';

    ranges.forEach(function(k){
      var el=document.getElementById(k);
      el.value=cfg[k];
      document.getElementById(k+'_v').textContent=
        k==='persp'? cfg.persp+'px' :
        k==='size' ? cfg.size+'vmin' :
        k==='glow' ? cfg.glow.toFixed(2) :
        k==='follow'||k==='alpha'||k==='hudb'||k==='tb' ? Math.round(cfg[k]*100)+'%' :
        k==='thick' ? cfg[k].toFixed(1) : cfg[k].toFixed(1)+'s';
    });
    checks.forEach(function(k){document.getElementById(k).checked=cfg[k];});

    try{
      var u=new URLSearchParams();
      u.set('p',cfg.period);u.set('ps',cfg.persp);u.set('s',cfg.size);
      u.set('g',cfg.glow);u.set('fl',cfg.follow);u.set('ph',cfg.sPhase);
      u.set('al',cfg.alpha);u.set('th',cfg.thick);u.set('hb',cfg.hudb);u.set('tb',cfg.tb);
      u.set('spin',cfg.spin?1:0);u.set('b',cfg.back?1:0);
      u.set('sc',cfg.scan?1:0);u.set('h',cfg.hud?1:0);u.set('panel',cfg.panel?1:0);
      u.set('sw',cfg.swing?1:0);u.set('c',cfg.collapsed?1:0);
      u.set('fs',cfg.frameSpin?1:0);
      u.set('ax',cfg.centerAxis?1:0);
      u.set('stag',cfg.stagger?1:0);
      u.set('tui',cfg.terminal?1:0);u.set('deep',cfg.deep?1:0);
      history.replaceState(null,'',location.pathname+'?'+u.toString());
    }catch(e){}
  }

  ranges.forEach(function(k){
    document.getElementById(k).addEventListener('input',function(e){
      cfg[k]=parseFloat(e.target.value);apply();
    });
  });
  checks.forEach(function(k){
    document.getElementById(k).addEventListener('change',function(e){
      cfg[k]=e.target.checked;apply();
    });
  });
  document.getElementById('panelOn').addEventListener('change',function(e){
    cfg.panel=e.target.checked;apply();
  });

  function togglePause(){
    body.classList.toggle('paused');
    document.getElementById('pause').textContent=body.classList.contains('paused')?'继续':'暂停';
  }
  function toggleCollapse(){
    if(!cfg.panel){cfg.panel=true;cfg.collapsed=false;}
    else{cfg.collapsed=!cfg.collapsed;}
    apply();
  }
  document.getElementById('fab').addEventListener('click',toggleCollapse);
  function goFull(){
    if(document.fullscreenElement){document.exitFullscreen();}
    else if(document.documentElement.requestFullscreen){document.documentElement.requestFullscreen().catch(function(){});}
  }
  document.getElementById('pause').addEventListener('click',togglePause);
  document.getElementById('full').addEventListener('click',goFull);
  document.getElementById('reset').addEventListener('click',function(){location.search='';});

  document.addEventListener('keydown',function(e){
    var k=e.key.toLowerCase();
    if(k==='h'){toggleCollapse();}
    else if(k==='f'){goFull();}
    else if(k==='r'){location.search='';}
    else if(e.code==='Space'){e.preventDefault();togglePause();}
  });

  var idle;
  function poke(){
    body.classList.remove('idle');
    clearTimeout(idle);
    idle=setTimeout(function(){body.classList.add('idle');},8000);
  }
  ['mousemove','mousedown','keydown','touchstart'].forEach(function(ev){
    window.addEventListener(ev,poke,{passive:true});
  });
  /* ===== 终端动态（第一批）：遥测随机游走 / PWR / 日志 / 接触目标 =====
     全部低频（≥2.2s 一步）；暂停时空格冻结动画，这里同步冻结数字。
     节奏纪律：90% 时间静止，偶发事件间隔 22~70s，不同时发生两个。 */
  var TELE=[
    ['teleL',[
      ['VEL',0.081,'c',function(v){return v.toFixed(3);},0.0004,0.075,0.09],
      ['ALT',41203,'M',function(v){return Math.round(v).toLocaleString('en-US');},26,40500,42000],
      ['HDG',214.7,'°',function(v){return v.toFixed(1);},0.3,0,360]]],
    ['teleR',[
      ['FUEL',87.3,'%',function(v){return v.toFixed(1);},0.05,85,90],
      ['SHLD','NOMINAL','',null,0],
      ['CREW',257,'',null,0]]]
  ];
  var cells=[];
  TELE.forEach(function(g){
    var host=document.getElementById(g[0]);
    if(!host)return;
    g[1].forEach(function(r){
      var row=document.createElement('div');
      row.innerHTML='<span class="k">'+r[0]+'</span> <span class="v"></span> <span class="k">'+r[2]+'</span>';
      host.appendChild(row);
      cells.push({r:r,out:row.querySelector('.v'),v:r[1]});
    });
  });
  function teleStep(){
    if(!body.classList.contains('paused')){
      cells.forEach(function(c){
        if(!c.r[3])return;                        /* 无格式化函数 = 静态字段 */
        c.v=Math.min(c.r[6],Math.max(c.r[5],c.v+(Math.random()-0.5)*2*c.r[4]));
        c.out.textContent=c.r[3](c.v);
      });
      var p=document.getElementById('pwr');
      if(p)p.textContent=(96+Math.random()*3.5).toFixed(1)+'%';
    }
  }
  function teleTick(){teleStep();setTimeout(teleTick,2400);}
  var LOGS=[
    function(){return 'SWEEP SECTOR '+(1+Math.random()*12|0)+' … NO CONTACTS';},
    function(){return 'LONG-RANGE SCAN … STANDBY';},
    function(){return 'LINK INTEGRITY 100% … NOMINAL';},
    function(){return 'PATROL ROUTE '+'ABCDEFGH'[Math.random()*8|0]+' … COMPLETED';},
    function(){return 'DOCKING CLAMPS … SECURED';},
    function(){return 'TELEMETRY SYNC … OK';},
    function(){return 'CREW ROSTER … 257 ACTIVE';},
    function(){return 'NAV DATA UPDATED … '+(1+Math.random()*6|0)+' NODES';}
  ];
  function addLog(){
    if(!body.classList.contains('paused')){
      var box=document.getElementById('log');
      if(box){
        var d=document.createElement('div');
        d.className='line';
        d.textContent='>> '+LOGS[Math.random()*LOGS.length|0]();
        box.appendChild(d);
        while(box.children.length>3)box.removeChild(box.firstChild);
        var n=box.children.length,i;
        for(i=0;i<n;i++)box.children[i].className='line'+(i===n-1?'':' dim');
      }
    }
    setTimeout(addLog,22000+Math.random()*26000);
  }
  function contactPing(){
    if(!body.classList.contains('paused')){
      var c=document.getElementById('contact');
      if(c){
        var a=Math.random()*Math.PI*2,R=45+Math.random()*3;
        c.style.left=(50+R*Math.sin(a))+'%';
        c.style.top=(50-R*Math.cos(a))+'%';
        c.querySelector('span').textContent='UNK-0'+(41+Math.random()*58|0);
        c.style.display='block';
        setTimeout(function(){c.style.display='none';},3400);
      }
    }
    setTimeout(contactPing,30000+Math.random()*40000);
  }
  teleStep();teleTick();setTimeout(addLog,4000);setTimeout(contactPing,15000);

  /* ===== 星域动态（第二批）：三层 box-shadow 星空 / 闪烁星 / 偶发流星 =====
     种子固定 ⇒ 每次刷新是同一片星空；暂停时漂移/闪烁/流星一并冻结。 */
  var sfBox=document.getElementById('starfield');
  function mulberry(a){return function(){a|=0;a=a+0x6D2B79F5|0;
    var t=Math.imul(a^a>>>15,1|a);t=t+Math.imul(t^t>>>7,61|t)^t;
    return((t^t>>>14)>>>0)/4294967296}}
  var LAYERS=[[130,3,.4,260],[90,4.2,.55,170],[55,5.4,.75,110]];  /* 数量/直径px/透明度/周期s */
  function buildStars(){
    if(!sfBox)return;
    sfBox.querySelectorAll('.starlayer').forEach(function(e){e.remove()});
    var W=Math.max(900,innerWidth),H=Math.max(520,innerHeight);
    LAYERS.forEach(function(cfg,li){
      var d=document.createElement('div');
      d.className='starlayer';
      d.style.animationDuration=cfg[3]+'s';
      d.style.setProperty('--sw',W+'px');          /* 漂移一个视口宽，无缝循环 */
      d.style.width=d.style.height=cfg[1]+'px';    /* 星点直径，圆由 border-radius 画 */
      var sh=[],r=mulberry(1000+li*77);
      for(var i=0;i<cfg[0];i++){
        var c=r()<.75?'255,244,214':'255,214,140'; /* 暖白为主，少量暗琥珀 */
        sh.push((r()*W*2).toFixed(1)+'px '+(r()*H).toFixed(1)+'px 0 0 rgba('+c+','+cfg[2]+')');
      }
      d.style.boxShadow=sh.join(',');
      sfBox.appendChild(d);
    });
  }
  buildStars();
  var starRT;
  addEventListener('resize',function(){clearTimeout(starRT);starRT=setTimeout(buildStars,300)});
  (function(){
    var host=document.getElementById('twk');
    if(!host)return;
    var r=mulberry(4242);
    for(var i=0;i<14;i++){
      var s=document.createElement('i');
      s.style.left=(4+r()*92).toFixed(1)+'%';
      s.style.top=(4+r()*88).toFixed(1)+'%';
      s.style.animationDuration=(2.5+r()*3.5).toFixed(2)+'s';
      s.style.animationDelay=(-r()*6).toFixed(2)+'s';
      host.appendChild(s);
    }
  })();
  function spawnMeteor(){
    if(!body.classList.contains('paused')){
      var box=document.getElementById('meteorbox');
      if(box){
        var m=document.createElement('div');
        m.className='meteor';
        var x0=(0.08+Math.random()*0.74)*innerWidth;
        var y0=(0.04+Math.random()*0.32)*innerHeight;
        var ang=(20+Math.random()*30)*Math.PI/180;      /* 向左下方划过 */
        var dist=innerWidth*0.35;
        m.style.setProperty('--x0',x0.toFixed(0)+'px');
        m.style.setProperty('--y0',y0.toFixed(0)+'px');
        m.style.setProperty('--rot',(Math.atan2(Math.sin(ang),-Math.cos(ang))*180/Math.PI).toFixed(1)+'deg');
        m.style.setProperty('--dx',(-Math.cos(ang)*dist).toFixed(0)+'px');
        m.style.setProperty('--dy',(Math.sin(ang)*dist).toFixed(0)+'px');
        m.style.width=(220+Math.random()*180).toFixed(0)+'px';
        m.style.animationDuration=(0.9+Math.random()*0.7).toFixed(2)+'s';
        box.appendChild(m);
        setTimeout(function(){m.remove();},1900);
      }
    }
    setTimeout(spawnMeteor,14000+Math.random()*16000);
  }
  setTimeout(spawnMeteor,6000);

  poke();
  apply();
})();
</script>
</body>
</html>
