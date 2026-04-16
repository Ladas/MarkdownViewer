# Complex Animation Showcase

> Pushing the limits of inline SVG animation in MarkdownViewer.

---

## 1. Isometric 3D Cube — Rotating Agent Container

<svg width="400" height="400" viewBox="0 0 400 400" xmlns="http://www.w3.org/2000/svg">
  <style>
    @media (prefers-color-scheme: dark) { .cube-bg{fill:#0d1117} .cube-t{fill:#8b949e} .cube-f1{fill:#1f6feb;fill-opacity:0.7} .cube-f2{fill:#238636;fill-opacity:0.6} .cube-f3{fill:#a371f7;fill-opacity:0.5} .cube-edge{stroke:#58a6ff;stroke-opacity:0.4} }
    @media (prefers-color-scheme: light) { .cube-bg{fill:#f6f8fa} .cube-t{fill:#57606a} .cube-f1{fill:#0969da;fill-opacity:0.6} .cube-f2{fill:#1a7f37;fill-opacity:0.5} .cube-f3{fill:#8250df;fill-opacity:0.4} .cube-edge{stroke:#0550ae;stroke-opacity:0.3} }
  </style>
  <rect class="cube-bg" width="400" height="400" rx="12"/>
  <text class="cube-t" x="200" y="28" text-anchor="middle" font-family="system-ui" font-size="13" font-weight="600">3D Container — Isometric View</text>
  <g>
    <animateTransform attributeName="transform" type="rotate" values="0,200,210;360,200,210" dur="20s" repeatCount="indefinite"/>
    <!-- Top face -->
    <polygon class="cube-f3" points="200,100 300,155 200,210 100,155">
      <animate attributeName="opacity" values="0.6;0.8;0.6" dur="5s" repeatCount="indefinite"/>
    </polygon>
    <!-- Left face -->
    <polygon class="cube-f1" points="100,155 200,210 200,320 100,265"/>
    <!-- Right face -->
    <polygon class="cube-f2" points="200,210 300,155 300,265 200,320"/>
    <!-- Edges -->
    <polyline class="cube-edge" points="200,100 300,155 300,265 200,320 100,265 100,155 200,100" fill="none" stroke-width="1.5"/>
    <line class="cube-edge" x1="200" y1="210" x2="200" y2="320" stroke-width="1"/>
    <line class="cube-edge" x1="200" y1="210" x2="100" y2="155" stroke-width="1"/>
    <line class="cube-edge" x1="200" y1="210" x2="300" y2="155" stroke-width="1"/>
    <!-- Inner particles -->
    <circle class="cube-f1" r="4" opacity="0.8">
      <animateMotion dur="3s" repeatCount="indefinite" path="M200,160 L250,190 L200,220 L150,190 Z"/>
    </circle>
    <circle class="cube-f2" r="3" opacity="0.7">
      <animateMotion dur="4s" begin="1s" repeatCount="indefinite" path="M180,170 L220,195 L200,240 L160,200 Z"/>
    </circle>
    <circle class="cube-f3" r="3" opacity="0.7">
      <animateMotion dur="3.5s" begin="2s" repeatCount="indefinite" path="M220,170 L240,200 L200,230 L170,190 Z"/>
    </circle>
  </g>
  <text class="cube-t" x="200" y="375" text-anchor="middle" font-family="system-ui" font-size="10">Agents orbit inside a sandboxed container</text>
</svg>

---

## 2. Multi-Layer Network — Real-Time Routing

<svg width="700" height="350" viewBox="0 0 700 350" xmlns="http://www.w3.org/2000/svg">
  <style>
    @media (prefers-color-scheme: dark) { .net-bg{fill:#0d1117} .net-t{fill:#7d8590} .net-n{fill:#1f6feb} .net-l{stroke:#30363d} .net-p{fill:#3fb950} .net-p2{fill:#f0883e} .net-p3{fill:#a371f7} .net-router{fill:#da3633} }
    @media (prefers-color-scheme: light) { .net-bg{fill:#f8f9fa} .net-t{fill:#57606a} .net-n{fill:#0969da} .net-l{stroke:#d0d7de} .net-p{fill:#1a7f37} .net-p2{fill:#bf8700} .net-p3{fill:#8250df} .net-router{fill:#cf222e} }
  </style>
  <rect class="net-bg" width="700" height="350" rx="10"/>
  <text class="net-t" x="350" y="22" text-anchor="middle" font-family="system-ui" font-size="13" font-weight="600">Agent Network — Multi-Path Routing</text>
  <!-- Network links -->
  <g class="net-l" stroke-width="1" opacity="0.5">
    <line x1="80" y1="100" x2="200" y2="70"/><line x1="80" y1="100" x2="200" y2="170"/>
    <line x1="200" y1="70" x2="350" y2="60"/><line x1="200" y1="70" x2="350" y2="175"/>
    <line x1="200" y1="170" x2="350" y2="175"/><line x1="200" y1="170" x2="350" y2="280"/>
    <line x1="350" y1="60" x2="500" y2="100"/><line x1="350" y1="175" x2="500" y2="100"/>
    <line x1="350" y1="175" x2="500" y2="240"/><line x1="350" y1="280" x2="500" y2="240"/>
    <line x1="500" y1="100" x2="620" y2="175"/><line x1="500" y1="240" x2="620" y2="175"/>
  </g>
  <!-- Nodes -->
  <circle class="net-n" cx="80" cy="100" r="14"/>
  <text x="80" y="104" text-anchor="middle" fill="white" font-family="system-ui" font-size="8" font-weight="600">SRC</text>
  <circle class="net-n" cx="200" cy="70" r="10"/>
  <circle class="net-n" cx="200" cy="170" r="10"/>
  <circle class="net-router" cx="350" cy="60" r="12"/>
  <text x="350" y="64" text-anchor="middle" fill="white" font-family="system-ui" font-size="7">R1</text>
  <circle class="net-router" cx="350" cy="175" r="12"/>
  <text x="350" y="179" text-anchor="middle" fill="white" font-family="system-ui" font-size="7">R2</text>
  <circle class="net-router" cx="350" cy="280" r="12"/>
  <text x="350" y="284" text-anchor="middle" fill="white" font-family="system-ui" font-size="7">R3</text>
  <circle class="net-n" cx="500" cy="100" r="10"/>
  <circle class="net-n" cx="500" cy="240" r="10"/>
  <circle class="net-n" cx="620" cy="175" r="14"/>
  <text x="620" y="179" text-anchor="middle" fill="white" font-family="system-ui" font-size="8" font-weight="600">DST</text>
  <!-- Packet route 1 (top path — fast) -->
  <circle class="net-p" r="5">
    <animateMotion dur="4s" repeatCount="indefinite" path="M80,100 L200,70 L350,60 L500,100 L620,175"/>
  </circle>
  <!-- Packet route 2 (middle path) -->
  <circle class="net-p2" r="5">
    <animateMotion dur="5s" begin="1s" repeatCount="indefinite" path="M80,100 L200,70 L350,175 L500,100 L620,175"/>
  </circle>
  <!-- Packet route 3 (bottom path — slow) -->
  <circle class="net-p3" r="5">
    <animateMotion dur="6s" begin="2s" repeatCount="indefinite" path="M80,100 L200,170 L350,280 L500,240 L620,175"/>
  </circle>
  <!-- Packet route 4 (zigzag) -->
  <circle class="net-p" r="4" opacity="0.6">
    <animateMotion dur="5.5s" begin="0.5s" repeatCount="indefinite" path="M80,100 L200,170 L350,175 L500,240 L620,175"/>
  </circle>
  <!-- Labels -->
  <text class="net-t" x="80" y="130" text-anchor="middle" font-family="system-ui" font-size="9">Source</text>
  <text class="net-t" x="620" y="205" text-anchor="middle" font-family="system-ui" font-size="9">Destination</text>
  <text class="net-t" x="350" y="330" text-anchor="middle" font-family="system-ui" font-size="10">4 concurrent routes — packets find optimal paths through the mesh</text>
</svg>

---

## 3. Concentric Radar — Agent Capability Scan

<svg width="450" height="450" viewBox="0 0 450 450" xmlns="http://www.w3.org/2000/svg">
  <style>
    @media (prefers-color-scheme: dark) { .rd-bg{fill:#0d1117} .rd-t{fill:#7d8590} .rd-ring{stroke:#21262d} .rd-axis{stroke:#30363d} .rd-sweep{fill:#1f6feb} .rd-dot{fill:#3fb950} .rd-area{fill:#1f6feb;stroke:#58a6ff} }
    @media (prefers-color-scheme: light) { .rd-bg{fill:#f6f8fa} .rd-t{fill:#57606a} .rd-ring{stroke:#eaeef2} .rd-axis{stroke:#d0d7de} .rd-sweep{fill:#0969da} .rd-dot{fill:#1a7f37} .rd-area{fill:#0969da;stroke:#0550ae} }
  </style>
  <rect class="rd-bg" width="450" height="450" rx="12"/>
  <text class="rd-t" x="225" y="22" text-anchor="middle" font-family="system-ui" font-size="13" font-weight="600">Agent Capability Radar</text>
  <!-- Concentric rings -->
  <circle class="rd-ring" cx="225" cy="230" r="50" fill="none" stroke-width="0.5"/>
  <circle class="rd-ring" cx="225" cy="230" r="100" fill="none" stroke-width="0.5"/>
  <circle class="rd-ring" cx="225" cy="230" r="150" fill="none" stroke-width="0.5"/>
  <!-- Axes -->
  <line class="rd-axis" x1="225" y1="80" x2="225" y2="380" stroke-width="0.5"/>
  <line class="rd-axis" x1="75" y1="230" x2="375" y2="230" stroke-width="0.5"/>
  <line class="rd-axis" x1="119" y1="124" x2="331" y2="336" stroke-width="0.5"/>
  <line class="rd-axis" x1="331" y1="124" x2="119" y2="336" stroke-width="0.5"/>
  <!-- Capability area -->
  <polygon class="rd-area" points="225,110 310,160 340,230 300,310 225,340 150,300 110,230 160,150" fill-opacity="0.15" stroke-width="1.5"/>
  <!-- Data points -->
  <circle class="rd-dot" cx="225" cy="110" r="5"/><text class="rd-t" x="225" y="95" text-anchor="middle" font-family="system-ui" font-size="9">Reasoning</text>
  <circle class="rd-dot" cx="310" cy="160" r="5"/><text class="rd-t" x="335" y="155" text-anchor="start" font-family="system-ui" font-size="9">Code</text>
  <circle class="rd-dot" cx="340" cy="230" r="5"/><text class="rd-t" x="360" y="234" text-anchor="start" font-family="system-ui" font-size="9">Tools</text>
  <circle class="rd-dot" cx="300" cy="310" r="5"/><text class="rd-t" x="318" y="320" text-anchor="start" font-family="system-ui" font-size="9">Memory</text>
  <circle class="rd-dot" cx="225" cy="340" r="5"/><text class="rd-t" x="225" y="360" text-anchor="middle" font-family="system-ui" font-size="9">Learning</text>
  <circle class="rd-dot" cx="150" cy="300" r="5"/><text class="rd-t" x="132" y="310" text-anchor="end" font-family="system-ui" font-size="9">Comms</text>
  <circle class="rd-dot" cx="110" cy="230" r="5"/><text class="rd-t" x="92" y="234" text-anchor="end" font-family="system-ui" font-size="9">Security</text>
  <circle class="rd-dot" cx="160" cy="150" r="5"/><text class="rd-t" x="142" y="145" text-anchor="end" font-family="system-ui" font-size="9">Planning</text>
  <!-- Rotating sweep line -->
  <line x1="225" y1="230" x2="225" y2="80" stroke-width="2" opacity="0.4">
    <animateTransform attributeName="transform" type="rotate" values="0,225,230;360,225,230" dur="6s" repeatCount="indefinite"/>
    <animate attributeName="opacity" values="0.4;0.1;0.4" dur="6s" repeatCount="indefinite"/>
  </line>
  <!-- Sweep gradient trail -->
  <path d="M225,230 L225,80 A150,150 0 0,1 375,230 Z" opacity="0.05">
    <animateTransform attributeName="transform" type="rotate" values="0,225,230;360,225,230" dur="6s" repeatCount="indefinite"/>
    <animate attributeName="opacity" values="0.08;0.02;0.08" dur="6s" repeatCount="indefinite"/>
  </path>
  <text class="rd-t" x="225" y="430" text-anchor="middle" font-family="system-ui" font-size="10">Scanning agent capabilities across 8 dimensions</text>
</svg>

---

## 4. Swarm Formation — Flock Behavior

<svg width="600" height="300" viewBox="0 0 600 300" xmlns="http://www.w3.org/2000/svg">
  <style>
    @media (prefers-color-scheme: dark) { .fl-bg{fill:#0d1117} .fl-t{fill:#7d8590} .fl-b{fill:#58a6ff} .fl-trail{stroke:#58a6ff} }
    @media (prefers-color-scheme: light) { .fl-bg{fill:#f6f8fa} .fl-t{fill:#57606a} .fl-b{fill:#0969da} .fl-trail{stroke:#0969da} }
  </style>
  <rect class="fl-bg" width="600" height="300" rx="10"/>
  <text class="fl-t" x="300" y="22" text-anchor="middle" font-family="system-ui" font-size="13" font-weight="600">Swarm Formation — Coordinated Movement</text>
  <!-- Leader -->
  <polygon class="fl-b" points="0,-8 -5,5 5,5" opacity="0.9">
    <animateMotion dur="8s" repeatCount="indefinite" path="M100,150 C200,80 400,220 550,130 C400,60 200,250 100,150" rotate="auto"/>
  </polygon>
  <!-- Followers — slightly delayed and offset -->
  <polygon class="fl-b" points="0,-6 -4,4 4,4" opacity="0.7">
    <animateMotion dur="8s" begin="0.3s" repeatCount="indefinite" path="M110,155 C210,85 410,225 540,135 C390,65 210,255 110,155" rotate="auto"/>
  </polygon>
  <polygon class="fl-b" points="0,-6 -4,4 4,4" opacity="0.7">
    <animateMotion dur="8s" begin="0.5s" repeatCount="indefinite" path="M95,145 C195,75 395,215 555,125 C405,55 195,245 95,145" rotate="auto"/>
  </polygon>
  <polygon class="fl-b" points="0,-5 -3,3 3,3" opacity="0.5">
    <animateMotion dur="8s" begin="0.8s" repeatCount="indefinite" path="M115,160 C215,90 415,230 535,140 C385,70 215,260 115,160" rotate="auto"/>
  </polygon>
  <polygon class="fl-b" points="0,-5 -3,3 3,3" opacity="0.5">
    <animateMotion dur="8s" begin="1s" repeatCount="indefinite" path="M90,140 C190,70 390,210 560,120 C410,50 190,240 90,140" rotate="auto"/>
  </polygon>
  <polygon class="fl-b" points="0,-5 -3,3 3,3" opacity="0.4">
    <animateMotion dur="8s" begin="1.3s" repeatCount="indefinite" path="M105,165 C205,95 405,235 530,145 C380,75 205,265 105,165" rotate="auto"/>
  </polygon>
  <polygon class="fl-b" points="0,-4 -3,3 3,3" opacity="0.3">
    <animateMotion dur="8s" begin="1.6s" repeatCount="indefinite" path="M85,135 C185,65 385,205 565,115 C415,45 185,235 85,135" rotate="auto"/>
  </polygon>
  <polygon class="fl-b" points="0,-4 -3,3 3,3" opacity="0.3">
    <animateMotion dur="8s" begin="1.9s" repeatCount="indefinite" path="M120,170 C220,100 420,240 525,150 C375,80 220,270 120,170" rotate="auto"/>
  </polygon>
  <polygon class="fl-b" points="0,-4 -2,2 2,2" opacity="0.2">
    <animateMotion dur="8s" begin="2.2s" repeatCount="indefinite" path="M80,130 C180,60 380,200 570,110 C420,40 180,230 80,130" rotate="auto"/>
  </polygon>
  <text class="fl-t" x="300" y="285" text-anchor="middle" font-family="system-ui" font-size="10">9 agents follow the leader in a V-formation — emergent flocking behavior</text>
</svg>

---

## 5. Encryption Tunnel — Data Protection

<svg width="600" height="200" viewBox="0 0 600 200" xmlns="http://www.w3.org/2000/svg">
  <style>
    @media (prefers-color-scheme: dark) { .enc-bg{fill:#0d1117} .enc-t{fill:#7d8590} .enc-wall{stroke:#30363d;fill:none} .enc-data{fill:#3fb950} .enc-enc{fill:#f0883e} .enc-lock{fill:#f9a825} }
    @media (prefers-color-scheme: light) { .enc-bg{fill:#f8f9fa} .enc-t{fill:#57606a} .enc-wall{stroke:#d0d7de;fill:none} .enc-data{fill:#1a7f37} .enc-enc{fill:#bf8700} .enc-lock{fill:#9a6700} }
  </style>
  <rect class="enc-bg" width="600" height="200" rx="10"/>
  <text class="enc-t" x="300" y="22" text-anchor="middle" font-family="system-ui" font-size="13" font-weight="600">mTLS Encryption Tunnel</text>
  <!-- Tunnel walls -->
  <path class="enc-wall" d="M150,50 L450,50" stroke-width="2" stroke-dasharray="8,4"/>
  <path class="enc-wall" d="M150,150 L450,150" stroke-width="2" stroke-dasharray="8,4"/>
  <ellipse class="enc-wall" cx="150" cy="100" rx="15" ry="50" stroke-width="2"/>
  <ellipse class="enc-wall" cx="450" cy="100" rx="15" ry="50" stroke-width="2"/>
  <!-- Lock icons -->
  <rect class="enc-lock" x="142" y="90" width="16" height="12" rx="2"/>
  <path class="enc-wall" d="M146,90 L146,84 A4,4 0 0,1 154,84 L154,90" stroke-width="1.5"/>
  <rect class="enc-lock" x="442" y="90" width="16" height="12" rx="2"/>
  <path class="enc-wall" d="M446,90 L446,84 A4,4 0 0,1 454,84 L454,90" stroke-width="1.5"/>
  <!-- Plaintext data entering -->
  <circle class="enc-data" r="4">
    <animateMotion dur="1s" repeatCount="indefinite" path="M60,100 L135,100"/>
  </circle>
  <circle class="enc-data" r="4">
    <animateMotion dur="1s" begin="0.3s" repeatCount="indefinite" path="M60,100 L135,100"/>
  </circle>
  <!-- Encrypted data in tunnel -->
  <rect class="enc-enc" width="8" height="8" rx="1">
    <animateMotion dur="2s" repeatCount="indefinite" path="M165,96 L435,96"/>
  </rect>
  <rect class="enc-enc" width="8" height="8" rx="1">
    <animateMotion dur="2s" begin="0.5s" repeatCount="indefinite" path="M165,96 L435,96"/>
  </rect>
  <rect class="enc-enc" width="8" height="8" rx="1">
    <animateMotion dur="2s" begin="1s" repeatCount="indefinite" path="M165,96 L435,96"/>
  </rect>
  <rect class="enc-enc" width="8" height="8" rx="1">
    <animateMotion dur="2s" begin="1.5s" repeatCount="indefinite" path="M165,96 L435,96"/>
  </rect>
  <!-- Decrypted data exiting -->
  <circle class="enc-data" r="4">
    <animateMotion dur="1s" repeatCount="indefinite" path="M465,100 L560,100"/>
  </circle>
  <circle class="enc-data" r="4">
    <animateMotion dur="1s" begin="0.3s" repeatCount="indefinite" path="M465,100 L560,100"/>
  </circle>
  <!-- Labels -->
  <text class="enc-t" x="60" y="80" text-anchor="middle" font-family="system-ui" font-size="9">Plaintext</text>
  <text class="enc-t" x="300" y="80" text-anchor="middle" font-family="system-ui" font-size="9">Encrypted</text>
  <text class="enc-t" x="540" y="80" text-anchor="middle" font-family="system-ui" font-size="9">Plaintext</text>
  <text class="enc-t" x="300" y="185" text-anchor="middle" font-family="system-ui" font-size="10">Round data enters, gets encrypted (squares), decrypted back to rounds</text>
</svg>

---

## Document Size Notes

WKWebView can handle very large HTML documents. Practical limits:

| Resource | Size | Impact |
|----------|------|--------|
| Template (CSS+JS) | ~4MB | Loaded once, cached |
| Single SVG | Up to ~5MB | No issues |
| Total page | Up to ~50MB | Starts to slow |
| Animations | ~50-100 elements | Beyond this, FPS drops |
| Mermaid diagrams | ~20 per page | Each re-renders on reload |

---

*Complex animations: isometric 3D cube, multi-path network routing, radar capability scan, flock formation (9 agents), encryption tunnel. All theme-aware, all copy correctly.*
