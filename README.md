# WindFlow Twistie: Temperature-Bound Generative Canvas
# by Damian Vincent Dobrowolski [DVD]
WindFlow-Twistie is a high-performance generative installation engineered for continuous 30 FPS exhibition on a dedicated Raspberry Pi 5 using Processing’s P2D hardware-accelerated rendering pipeline. Replacing discrete particles with a continuous, organic vector field that mimics swaying grass, the simulation maps real-time atmospheric telemetry directly to visual mechanics: Perlin noise turbulence is dynamically computed from live gust-to-sustained wind ratios, while temperature-polarized HSB gradients ripple across the matrix in direct response to sensory wind chill and heat index deviations.

## Overview
The piece anchors a live fluid vector field to local weather metrics. Instead of arbitrary aesthetic values, every visual asset—from flow turbulence to color palette ranges—is mathematically bound to the tension between actual physical conditions and human sensory perception.

## Core Visual Mechanics

### 1. Temperature-Polarized Gradients & Color Walls
* **Base Anchor:** The underlying matrix color maps linearly across the HSB spectrum based on the ambient temperature (bounded between a crisp $-10^\circ\text{F}$ at $260^\circ$ Deep Indigo and a searing $100^\circ\text{F}$ at $0^\circ$ Fiery Red).
* **The Deception Direction:** Rather than random color oscillations, a tracking vector (`feelsDir`) determines whether the wind chill or heat index is deceiving the senses. The gradient waves ripple *strictly* in the direction of that deviation. 
* **Extreme Weather Unlock:** To maintain structural visual movement during intense Midwestern winters, a dynamic `backSway` parameter smoothly unlocks two-way color shifting below $30^\circ\text{F}$, introducing fractured pockets of Icy Cyan (~$210^\circ$) into the frozen Indigo mat.
* **Color Clamping:** Built a physical boundary at $0^\circ / 360^\circ$ (Red) using strict constraints, preventing hot-weather color shifts from wrapping backward into the purples and retaining accurate thermal representation.

### 2. Kinetic Turbulence Modeling
* **Gust Ratio Control:** The spatial resolution and complexity of the Perlin noise field (`noiseIncr`) is driven by the dynamic fraction of wind gusts to sustained wind speed (`windGusts / windSpeed`), recalculating fluid curls frame-by-frame.
* **Order of Execution Safeguards:** Mathematical divisions are heavily guarded with ternary structures to cleanly handle completely still days ($0.0\text{ mph}$), substituting a safe baseline ratio ($1.0$) to eliminate `NaN` math anomalies and prevent frame drops.

### 3. Screen Topology & UI Elements
* **Dynamic Legend System:** A real-time data terminal overlays weather metrics using a clean, geometric sans-serif typeface (`Jost`), pulled to a high-visibility text layout scaled specifically for large display TVs. 
* **Collision Avoidance:** The legend dynamically repositions itself into the screen quadrant towards which the wind is blowing. To ensure elements never crash, the signature box reads the live location of the legend and automatically flees to the opposite bottom corner.
* **The Kinetic Screen Saver:** A randomized HSB word-matrix floats across the canvas mimicking the classic bouncing screen saver. The bounce engine computes dynamic string width tracking, applying positional constraints on impact to prevent localized edge-clipping when shifting between strings of different lengths (e.g., `"mog"` vs. `"obey"`).
* **Feathered Confetti Finales:** Corner-strike events trigger a high-capacity particle explosion ($300$ active nodes). Particle geometry is rendered via independent matrix transformations (`pushMatrix`/`popMatrix`) maintaining low-gravity floating trajectories and slow alpha-decay curves for a highly cinematic termination.

## Hardware Optimization (Raspberry Pi 5)
The sketch utilizes Processing’s `P2D` hardware-accelerated rendering pipeline. To maintain a locked 60 FPS profile on single-board computer architecture, the complex underlying resolution is strictly pinned to fixed grid targets (`targetCols = 60`), isolating fluid calculations from execution overhead.

## Directory Structure
```text
windFlow_grass/
├── windFlow_grass.pde  # Main execution loop, dynamic UI drawing, and HSB rendering
├── windData.pde        # API lifecycle, data ingestion, and coordinate system transformation
├── data/
│   └── Jost-VariableFont_wght.ttf  # Local geometric UI font asset
└── README.md
