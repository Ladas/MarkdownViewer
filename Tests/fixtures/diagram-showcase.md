# Diagram & Visualization Showcase

> Comprehensive demo of all diagram types and visual styles supported by MarkdownViewer.

---

## 1. Mermaid Diagram Types

### 1.1 Flowchart (with styling)

```mermaid
flowchart TD
    A[Start] --> B{Decision}
    B -->|Yes| C[Process A]
    B -->|No| D[Process B]
    C --> E[Merge]
    D --> E
    E --> F{Another\nDecision}
    F -->|Path 1| G[Result 1]
    F -->|Path 2| H[Result 2]
    F -->|Path 3| I[Result 3]
    G & H & I --> J((End))

    style A fill:#2e7d32,color:#fff,stroke:#4caf50
    style J fill:#c62828,color:#fff,stroke:#ef5350
    style B fill:#1565c0,color:#fff,stroke:#42a5f5
    style F fill:#1565c0,color:#fff,stroke:#42a5f5
```

### 1.2 Flowchart — Subgraphs

```mermaid
flowchart LR
    subgraph Frontend["Frontend Layer"]
        UI[React UI] --> API[API Gateway]
    end
    subgraph Backend["Backend Services"]
        Auth[Auth Service]
        Users[User Service]
        Orders[Order Service]
    end
    subgraph Data["Data Layer"]
        DB[(PostgreSQL)]
        Cache[(Redis)]
        Queue[RabbitMQ]
    end

    API --> Auth & Users & Orders
    Auth --> DB
    Users --> DB & Cache
    Orders --> DB & Queue

    style Frontend fill:#e3f2fd,stroke:#1565c0
    style Backend fill:#e8f5e9,stroke:#2e7d32
    style Data fill:#fff3e0,stroke:#e65100
```

### 1.3 Sequence Diagram

```mermaid
sequenceDiagram
    actor User
    participant App as MarkdownViewer
    participant WK as WKWebView
    participant JS as JavaScript
    participant Mermaid

    User->>App: Open .md file
    App->>App: Read file content
    App->>WK: loadHTMLString(rendered)
    activate WK
    WK->>JS: Parse markdown (marked.js)
    JS->>JS: Sanitize (DOMPurify)
    JS->>Mermaid: Initialize & render
    activate Mermaid
    Mermaid-->>WK: SVG diagrams
    deactivate Mermaid
    WK-->>App: Page loaded
    deactivate WK
    App-->>User: Display rendered document

    Note over User,Mermaid: File watcher polls every 0.5s for changes
```

### 1.4 State Diagram

```mermaid
stateDiagram-v2
    [*] --> Idle

    state "Agent Pool" as pool {
        Idle --> Assigned: Task received
        Assigned --> Running: Resources allocated
        Running --> Success: Completed
        Running --> Failed: Error
        Running --> Blocked: Waiting
        Blocked --> Running: Unblocked
        Success --> Idle: Released
        Failed --> Retry: Attempts left
        Retry --> Running: Retry
        Failed --> Dead: Max retries
    }

    Dead --> [*]
    Success --> [*]
```

### 1.5 Class Diagram

```mermaid
classDiagram
    class Agent {
        +String id
        +String model
        +Tool[] tools
        +run(prompt) Result
        +assess_confidence() float
    }
    class Orchestrator {
        +decompose(task) SubTask[]
        +assign(subtask) Agent
        +aggregate(results) Response
    }
    class Tool {
        <<interface>>
        +name() String
        +execute(input) Output
    }
    class WebSearch {
        +search(query) Results
    }
    class FileRead {
        +read(path) String
    }

    Agent "1" --> "*" Tool : uses
    Orchestrator "1" --> "*" Agent : manages
    WebSearch ..|> Tool
    FileRead ..|> Tool
```

### 1.6 Entity Relationship

```mermaid
erDiagram
    USER ||--o{ SESSION : creates
    USER ||--o{ REVIEW_NOTE : authors
    SESSION ||--o{ MESSAGE : contains
    SESSION ||--|| FILE : targets
    FILE ||--o{ REVIEW_NOTE : has
    REVIEW_NOTE ||--o{ RESOLUTION : tracked_by

    USER {
        string id PK
        string name
        string email
    }
    SESSION {
        string id PK
        string user_id FK
        string file_path
        datetime created
    }
    FILE {
        string path PK
        string content
        datetime modified
    }
    REVIEW_NOTE {
        int index PK
        string content
        string status
    }
```

### 1.7 Gantt Chart

```mermaid
gantt
    title Project Timeline
    dateFormat YYYY-MM-DD
    axisFormat %b %d

    section Research
    Literature Review     :done, r1, 2025-01-01, 30d
    Prototype Design      :done, r2, after r1, 20d
    Experiments           :active, r3, after r2, 45d

    section Development
    Core Framework        :done, d1, 2025-02-01, 60d
    Agent Communication   :active, d2, after d1, 40d
    Orchestrator          :d3, after d2, 30d
    UI Dashboard          :d4, after d3, 25d

    section Testing
    Unit Tests            :t1, after d2, 20d
    Integration Tests     :t2, after d3, 15d
    Performance Tests     :t3, after d4, 20d

    section Release
    Beta Release          :milestone, m1, after t2, 0d
    GA Release            :milestone, m2, after t3, 0d
```

### 1.8 Pie Chart

```mermaid
pie title Token Usage by Agent Type
    "Code Agent" : 35
    "Research Agent" : 25
    "Analysis Agent" : 20
    "Writing Agent" : 12
    "Security Agent" : 8
```

### 1.9 Mindmap

```mermaid
mindmap
    root((AI Agent<br/>Architecture))
        Perception
            NLP
            Vision
            Audio
            Multimodal
        Reasoning
            Chain of Thought
            Tree of Thought
            ReAct
            Reflexion
        Memory
            Short-term
                Context Window
                Scratchpad
            Long-term
                Vector DB
                Knowledge Graph
        Action
            Tool Use
            Code Execution
            API Calls
            File Operations
        Communication
            Natural Language
            Structured Messages
            Stigmergy
```

### 1.10 XY Chart

```mermaid
xychart-beta
    title "Agent Performance by Swarm Size"
    x-axis "Agents" [1, 5, 10, 25, 50, 100, 250, 500]
    y-axis "Score (%)" 0 --> 100
    line "SWE-bench" [33, 42, 49, 55, 62, 68, 70, 71]
    line "HumanEval" [72, 82, 88, 92, 96, 97, 98, 98]
    line "GPQA" [40, 48, 54, 60, 67, 72, 75, 78]
```

### 1.11 User Journey

```mermaid
journey
    title Developer Using MarkdownViewer
    section Open Document
        Launch app: 5: Developer
        Open .md file: 5: Developer
        View rendered: 5: Developer
    section Review
        Add review note: 4: Developer
        Voice dictation: 3: Developer
        Toggle TOC: 5: Developer
    section Share
        Copy for GDocs: 3: Developer
        Export HTML: 4: Developer
        Copy for Agent: 5: Developer
    section Iterate
        Claude addresses notes: 5: Claude
        Auto-reload preview: 5: App
        Resolved notes tracked: 4: App
```

### 1.12 Quadrant Chart

```mermaid
quadrantChart
    title Agent Framework Comparison
    x-axis "Simple" --> "Complex"
    y-axis "Low Capability" --> "High Capability"
    quadrant-1 "Best for Production"
    quadrant-2 "Promising"
    quadrant-3 "Niche Use"
    quadrant-4 "Overengineered"
    "Legion (ours)": [0.75, 0.85]
    "AutoGen": [0.55, 0.60]
    "MetaGPT": [0.65, 0.55]
    "LangChain": [0.70, 0.50]
    "CAMEL": [0.30, 0.40]
    "Single Agent": [0.15, 0.45]
    "CrewAI": [0.45, 0.55]
```

### 1.13 Timeline

```mermaid
timeline
    title AI Agent Milestones
    2023 : Generative Agents (Stanford)
         : AutoGen (Microsoft)
         : MetaGPT
    2024 : Claude Computer Use
         : OpenAI Swarm
         : Agent Protocol
    2025 : Claude Agent SDK
         : Production Agent Frameworks
         : Enterprise Sandboxing
    2026 : Legion Agent v1
         : 1000-Agent Swarms
         : AGI Approximation Tests
```

---

## 2. Animated SVG Visualizations

### 2.1 Neural Network Pulse

<svg width="600" height="250" xmlns="http://www.w3.org/2000/svg">
  <style>
    @media (prefers-color-scheme: dark) { .nn-bg{fill:#0d1117} .nn-n{fill:#1f6feb} .nn-l{stroke:#30363d} .nn-t{fill:#8b949e} .nn-sig{fill:#3fb950} }
    @media (prefers-color-scheme: light) { .nn-bg{fill:#f8f9fa} .nn-n{fill:#0969da} .nn-l{stroke:#d0d7de} .nn-t{fill:#57606a} .nn-sig{fill:#1a7f37} }
  </style>
  <rect class="nn-bg" width="600" height="250" rx="10"/>
  <text class="nn-t" x="300" y="22" text-anchor="middle" font-family="system-ui" font-size="12" font-weight="600">Neural Network — Signal Propagation</text>
  <!-- Layer labels -->
  <text class="nn-t" x="80" y="235" text-anchor="middle" font-family="system-ui" font-size="9">Input</text>
  <text class="nn-t" x="220" y="235" text-anchor="middle" font-family="system-ui" font-size="9">Hidden 1</text>
  <text class="nn-t" x="380" y="235" text-anchor="middle" font-family="system-ui" font-size="9">Hidden 2</text>
  <text class="nn-t" x="520" y="235" text-anchor="middle" font-family="system-ui" font-size="9">Output</text>
  <!-- Connections (drawn first, behind nodes) -->
  <g opacity="0.2">
    <!-- Input to Hidden 1 -->
    <line class="nn-l" x1="80" y1="60" x2="220" y2="50" stroke-width="1"/>
    <line class="nn-l" x1="80" y1="60" x2="220" y2="110" stroke-width="1"/>
    <line class="nn-l" x1="80" y1="60" x2="220" y2="170" stroke-width="1"/>
    <line class="nn-l" x1="80" y1="120" x2="220" y2="50" stroke-width="1"/>
    <line class="nn-l" x1="80" y1="120" x2="220" y2="110" stroke-width="1"/>
    <line class="nn-l" x1="80" y1="120" x2="220" y2="170" stroke-width="1"/>
    <line class="nn-l" x1="80" y1="180" x2="220" y2="50" stroke-width="1"/>
    <line class="nn-l" x1="80" y1="180" x2="220" y2="110" stroke-width="1"/>
    <line class="nn-l" x1="80" y1="180" x2="220" y2="170" stroke-width="1"/>
    <!-- Hidden 1 to Hidden 2 -->
    <line class="nn-l" x1="220" y1="50" x2="380" y2="70" stroke-width="1"/>
    <line class="nn-l" x1="220" y1="50" x2="380" y2="140" stroke-width="1"/>
    <line class="nn-l" x1="220" y1="110" x2="380" y2="70" stroke-width="1"/>
    <line class="nn-l" x1="220" y1="110" x2="380" y2="140" stroke-width="1"/>
    <line class="nn-l" x1="220" y1="170" x2="380" y2="70" stroke-width="1"/>
    <line class="nn-l" x1="220" y1="170" x2="380" y2="140" stroke-width="1"/>
    <!-- Hidden 2 to Output -->
    <line class="nn-l" x1="380" y1="70" x2="520" y2="110" stroke-width="1"/>
    <line class="nn-l" x1="380" y1="140" x2="520" y2="110" stroke-width="1"/>
  </g>
  <!-- Input neurons -->
  <circle class="nn-n" cx="80" cy="60" r="10"><animate attributeName="r" values="10;13;10" dur="2s" repeatCount="indefinite"/></circle>
  <circle class="nn-n" cx="80" cy="120" r="10"><animate attributeName="r" values="10;13;10" dur="2s" begin="0.2s" repeatCount="indefinite"/></circle>
  <circle class="nn-n" cx="80" cy="180" r="10"><animate attributeName="r" values="10;13;10" dur="2s" begin="0.4s" repeatCount="indefinite"/></circle>
  <!-- Hidden 1 neurons -->
  <circle class="nn-n" cx="220" cy="50" r="10"><animate attributeName="r" values="10;13;10" dur="2s" begin="0.6s" repeatCount="indefinite"/></circle>
  <circle class="nn-n" cx="220" cy="110" r="10"><animate attributeName="r" values="10;13;10" dur="2s" begin="0.8s" repeatCount="indefinite"/></circle>
  <circle class="nn-n" cx="220" cy="170" r="10"><animate attributeName="r" values="10;13;10" dur="2s" begin="1.0s" repeatCount="indefinite"/></circle>
  <!-- Hidden 2 neurons -->
  <circle class="nn-n" cx="380" cy="70" r="10"><animate attributeName="r" values="10;13;10" dur="2s" begin="1.2s" repeatCount="indefinite"/></circle>
  <circle class="nn-n" cx="380" cy="140" r="10"><animate attributeName="r" values="10;13;10" dur="2s" begin="1.4s" repeatCount="indefinite"/></circle>
  <!-- Output neuron -->
  <circle class="nn-sig" cx="520" cy="110" r="14"><animate attributeName="r" values="14;18;14" dur="2s" begin="1.6s" repeatCount="indefinite"/></circle>
  <text x="520" y="114" text-anchor="middle" fill="white" font-family="system-ui" font-size="8" font-weight="600">OUT</text>
  <!-- Signal propagation dots -->
  <circle class="nn-sig" r="3"><animateMotion dur="2s" repeatCount="indefinite" path="M80,60 L220,110"/></circle>
  <circle class="nn-sig" r="3"><animateMotion dur="2s" begin="0.5s" repeatCount="indefinite" path="M80,120 L220,50"/></circle>
  <circle class="nn-sig" r="3"><animateMotion dur="2s" begin="1s" repeatCount="indefinite" path="M220,110 L380,70"/></circle>
  <circle class="nn-sig" r="3"><animateMotion dur="2s" begin="1.5s" repeatCount="indefinite" path="M380,70 L520,110"/></circle>
</svg>

### 2.2 Orbiting Agent Swarm

<svg width="400" height="400" xmlns="http://www.w3.org/2000/svg">
  <style>
    @media (prefers-color-scheme: dark) { .orb-bg{fill:#0d1117} .orb-c{fill:#1f6feb} .orb-ring{stroke:#30363d} .orb-t{fill:#8b949e} .orb-a1{fill:#3fb950} .orb-a2{fill:#f9a825} .orb-a3{fill:#da3633} .orb-a4{fill:#a371f7} }
    @media (prefers-color-scheme: light) { .orb-bg{fill:#f6f8fa} .orb-c{fill:#0969da} .orb-ring{stroke:#d0d7de} .orb-t{fill:#57606a} .orb-a1{fill:#1a7f37} .orb-a2{fill:#bf8700} .orb-a3{fill:#cf222e} .orb-a4{fill:#8250df} }
  </style>
  <rect class="orb-bg" width="400" height="400" rx="10"/>
  <!-- Orbit rings -->
  <circle class="orb-ring" cx="200" cy="200" r="60" fill="none" stroke-width="1" stroke-dasharray="4,4"/>
  <circle class="orb-ring" cx="200" cy="200" r="110" fill="none" stroke-width="1" stroke-dasharray="4,4"/>
  <circle class="orb-ring" cx="200" cy="200" r="160" fill="none" stroke-width="1" stroke-dasharray="4,4"/>
  <!-- Central hub -->
  <circle class="orb-c" cx="200" cy="200" r="25"/>
  <circle class="orb-c" cx="200" cy="200" r="30" opacity="0.2">
    <animate attributeName="r" values="30;38;30" dur="3s" repeatCount="indefinite"/>
    <animate attributeName="opacity" values="0.2;0.05;0.2" dur="3s" repeatCount="indefinite"/>
  </circle>
  <text x="200" y="204" text-anchor="middle" fill="white" font-family="system-ui" font-size="9" font-weight="700">CORE</text>
  <!-- Inner orbit agents (fast) -->
  <circle class="orb-a1" r="10">
    <animateMotion dur="4s" repeatCount="indefinite" path="M200,200 m-60,0 a60,60 0 1,1 120,0 a60,60 0 1,1 -120,0"/>
  </circle>
  <circle class="orb-a2" r="10">
    <animateMotion dur="4s" begin="2s" repeatCount="indefinite" path="M200,200 m-60,0 a60,60 0 1,1 120,0 a60,60 0 1,1 -120,0"/>
  </circle>
  <!-- Middle orbit agents (medium) -->
  <circle class="orb-a3" r="12">
    <animateMotion dur="7s" repeatCount="indefinite" path="M200,200 m-110,0 a110,110 0 1,1 220,0 a110,110 0 1,1 -220,0"/>
  </circle>
  <circle class="orb-a1" r="12">
    <animateMotion dur="7s" begin="2.3s" repeatCount="indefinite" path="M200,200 m-110,0 a110,110 0 1,1 220,0 a110,110 0 1,1 -220,0"/>
  </circle>
  <circle class="orb-a4" r="12">
    <animateMotion dur="7s" begin="4.6s" repeatCount="indefinite" path="M200,200 m-110,0 a110,110 0 1,1 220,0 a110,110 0 1,1 -220,0"/>
  </circle>
  <!-- Outer orbit agents (slow) -->
  <circle class="orb-a2" r="8">
    <animateMotion dur="11s" repeatCount="indefinite" path="M200,200 m-160,0 a160,160 0 1,1 320,0 a160,160 0 1,1 -320,0"/>
  </circle>
  <circle class="orb-a3" r="8">
    <animateMotion dur="11s" begin="2.75s" repeatCount="indefinite" path="M200,200 m-160,0 a160,160 0 1,1 320,0 a160,160 0 1,1 -320,0"/>
  </circle>
  <circle class="orb-a4" r="8">
    <animateMotion dur="11s" begin="5.5s" repeatCount="indefinite" path="M200,200 m-160,0 a160,160 0 1,1 320,0 a160,160 0 1,1 -320,0"/>
  </circle>
  <circle class="orb-a1" r="8">
    <animateMotion dur="11s" begin="8.25s" repeatCount="indefinite" path="M200,200 m-160,0 a160,160 0 1,1 320,0 a160,160 0 1,1 -320,0"/>
  </circle>
  <text class="orb-t" x="200" y="385" text-anchor="middle" font-family="system-ui" font-size="10">Agent Swarm — 3 orbital layers, 9 agents</text>
</svg>

### 2.3 Heartbeat Monitor

<svg width="600" height="150" xmlns="http://www.w3.org/2000/svg">
  <style>
    @media (prefers-color-scheme: dark) { .hb-bg{fill:#0d1117} .hb-grid{stroke:#21262d} .hb-line{stroke:#3fb950} .hb-dot{fill:#3fb950} .hb-t{fill:#8b949e} }
    @media (prefers-color-scheme: light) { .hb-bg{fill:#f8f9fa} .hb-grid{stroke:#eaeef2} .hb-line{stroke:#1a7f37} .hb-dot{fill:#1a7f37} .hb-t{fill:#57606a} }
  </style>
  <rect class="hb-bg" width="600" height="150" rx="8"/>
  <!-- Grid -->
  <g class="hb-grid" stroke-width="0.5">
    <line x1="0" y1="37" x2="600" y2="37"/><line x1="0" y1="75" x2="600" y2="75"/><line x1="0" y1="112" x2="600" y2="112"/>
  </g>
  <text class="hb-t" x="10" y="15" font-family="system-ui" font-size="10" font-weight="600">System Health Monitor</text>
  <text class="hb-t" x="530" y="15" font-family="system-ui" font-size="9">LIVE</text>
  <circle class="hb-dot" cx="520" cy="12" r="3"><animate attributeName="opacity" values="1;0.3;1" dur="1s" repeatCount="indefinite"/></circle>
  <!-- ECG-style path -->
  <path class="hb-line" fill="none" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"
    d="M0,75 L40,75 L50,75 L55,60 L60,90 L65,30 L70,120 L75,50 L80,75 L120,75 L160,75 L170,75 L175,60 L180,90 L185,30 L190,120 L195,50 L200,75 L240,75 L280,75 L290,75 L295,60 L300,90 L305,30 L310,120 L315,50 L320,75 L360,75 L400,75 L410,75 L415,60 L420,90 L425,30 L430,120 L435,50 L440,75 L480,75 L520,75 L530,75 L535,60 L540,90 L545,30 L550,120 L555,50 L560,75 L600,75">
    <animate attributeName="stroke-dasharray" values="0,2000;2000,0" dur="4s" repeatCount="indefinite"/>
  </path>
  <text class="hb-t" x="10" y="140" font-family="system-ui" font-size="9">72 BPM — All agents healthy — Latency: 34ms avg</text>
</svg>

### 2.4 Data Flow Waterfall

<svg width="500" height="300" xmlns="http://www.w3.org/2000/svg">
  <style>
    @media (prefers-color-scheme: dark) { .wf-bg{fill:#0d1117} .wf-box{fill:#21262d;stroke:#30363d} .wf-t{fill:#e6edf3} .wf-st{fill:#8b949e} .wf-d1{fill:#1f6feb} .wf-d2{fill:#3fb950} .wf-d3{fill:#f9a825} .wf-arrow{stroke:#484f58;fill:#484f58} }
    @media (prefers-color-scheme: light) { .wf-bg{fill:#ffffff} .wf-box{fill:#f6f8fa;stroke:#d0d7de} .wf-t{fill:#1f2328} .wf-st{fill:#57606a} .wf-d1{fill:#0969da} .wf-d2{fill:#1a7f37} .wf-d3{fill:#bf8700} .wf-arrow{stroke:#8c959f;fill:#8c959f} }
  </style>
  <rect class="wf-bg" width="500" height="300" rx="10"/>
  <text class="wf-t" x="250" y="25" text-anchor="middle" font-family="system-ui" font-size="13" font-weight="600">Data Processing Waterfall</text>
  <!-- Stage 1: Ingest -->
  <rect class="wf-box" x="30" y="45" width="140" height="50" rx="8" stroke-width="1"/>
  <text class="wf-t" x="100" y="67" text-anchor="middle" font-family="system-ui" font-size="11" font-weight="600">Ingest</text>
  <text class="wf-st" x="100" y="82" text-anchor="middle" font-family="system-ui" font-size="9">Raw data streams</text>
  <!-- Arrow 1 -->
  <line class="wf-arrow" x1="170" y1="70" x2="180" y2="70" stroke-width="1.5"/>
  <line class="wf-arrow" x1="180" y1="70" x2="200" y2="130" stroke-width="1.5"/>
  <!-- Data drops -->
  <circle class="wf-d1" r="4"><animateMotion dur="2s" repeatCount="indefinite" path="M100,95 C100,110 200,110 200,130"/></circle>
  <circle class="wf-d1" r="4"><animateMotion dur="2s" begin="0.5s" repeatCount="indefinite" path="M100,95 C120,115 180,115 200,130"/></circle>
  <circle class="wf-d1" r="4"><animateMotion dur="2s" begin="1s" repeatCount="indefinite" path="M100,95 C80,120 220,120 200,130"/></circle>
  <!-- Stage 2: Transform -->
  <rect class="wf-box" x="180" y="120" width="140" height="50" rx="8" stroke-width="1"/>
  <text class="wf-t" x="250" y="142" text-anchor="middle" font-family="system-ui" font-size="11" font-weight="600">Transform</text>
  <text class="wf-st" x="250" y="157" text-anchor="middle" font-family="system-ui" font-size="9">Clean, normalize, enrich</text>
  <!-- Arrow 2 -->
  <line class="wf-arrow" x1="320" y1="145" x2="330" y2="145" stroke-width="1.5"/>
  <line class="wf-arrow" x1="330" y1="145" x2="350" y2="205" stroke-width="1.5"/>
  <!-- Data drops -->
  <circle class="wf-d2" r="4"><animateMotion dur="2s" begin="0.7s" repeatCount="indefinite" path="M250,170 C250,185 350,185 350,205"/></circle>
  <circle class="wf-d2" r="4"><animateMotion dur="2s" begin="1.2s" repeatCount="indefinite" path="M250,170 C270,190 330,190 350,205"/></circle>
  <!-- Stage 3: Analyze -->
  <rect class="wf-box" x="330" y="195" width="140" height="50" rx="8" stroke-width="1"/>
  <text class="wf-t" x="400" y="217" text-anchor="middle" font-family="system-ui" font-size="11" font-weight="600">Analyze</text>
  <text class="wf-st" x="400" y="232" text-anchor="middle" font-family="system-ui" font-size="9">ML inference + scoring</text>
  <!-- Result indicator -->
  <circle class="wf-d3" cx="400" cy="270" r="8">
    <animate attributeName="r" values="8;12;8" dur="1.5s" repeatCount="indefinite"/>
    <animate attributeName="opacity" values="1;0.5;1" dur="1.5s" repeatCount="indefinite"/>
  </circle>
  <text class="wf-st" x="400" y="290" text-anchor="middle" font-family="system-ui" font-size="9">Output ready</text>
</svg>

---

## 3. Complex Mermaid Patterns

### 3.1 C4 Architecture (Context)

```mermaid
flowchart TB
    User["fa:fa-user Developer"]
    MV["fa:fa-eye MarkdownViewer\n(macOS App)"]
    Claude["fa:fa-robot Claude Code\n(CLI)"]
    Git["fa:fa-code-branch Git\n(Version Control)"]
    GDocs["fa:fa-file-alt Google Docs\n(Sharing)"]

    User -->|Opens .md files| MV
    User -->|Writes code| Claude
    Claude -->|Generates docs| Git
    MV -->|Review notes| Git
    MV -->|Copy HTML| GDocs
    Claude -->|Reads review notes| Git
    User -->|Shares| GDocs

    style MV fill:#1565c0,color:#fff,stroke:#42a5f5
    style Claude fill:#6f42c1,color:#fff,stroke:#a371f7
    style Git fill:#24292f,color:#fff,stroke:#57606a
    style GDocs fill:#2e7d32,color:#fff,stroke:#4caf50
```

### 3.2 Decision Tree

```mermaid
flowchart TD
    Q1{"Is the task\nwell-defined?"}
    Q2{"Does it need\nmultiple skills?"}
    Q3{"Is latency\ncritical?"}
    Q4{"Budget\nconstraint?"}

    A1["Single Agent\n(1 model call)"]
    A2["Chain of Thought\n(multi-step)"]
    A3["Star Topology\n(fast decisions)"]
    A4["Mesh Topology\n(creative tasks)"]
    A5["Tree Topology\n(hierarchical)"]

    Q1 -->|No| Q2
    Q1 -->|Yes| A1
    Q2 -->|No| A2
    Q2 -->|Yes| Q3
    Q3 -->|Yes| A3
    Q3 -->|No| Q4
    Q4 -->|Low| A4
    Q4 -->|High| A5

    style Q1 fill:#1565c0,color:#fff
    style Q2 fill:#1565c0,color:#fff
    style Q3 fill:#e65100,color:#fff
    style Q4 fill:#e65100,color:#fff
    style A1 fill:#2e7d32,color:#fff
    style A2 fill:#2e7d32,color:#fff
    style A3 fill:#2e7d32,color:#fff
    style A4 fill:#2e7d32,color:#fff
    style A5 fill:#2e7d32,color:#fff
```

---

*Showcase covers: 13 mermaid diagram types (flowchart, subgraphs, sequence, state, class, ER, gantt, pie, mindmap, xychart, journey, quadrant, timeline) + 4 animated SVGs (neural network, orbital swarm, heartbeat monitor, data waterfall) + complex patterns (C4, decision tree).*
