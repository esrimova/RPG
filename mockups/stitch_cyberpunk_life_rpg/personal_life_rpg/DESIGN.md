---
name: Personal Life RPG
colors:
  surface: '#111318'
  surface-dim: '#111318'
  surface-bright: '#37393e'
  surface-container-lowest: '#0c0e12'
  surface-container-low: '#1a1c20'
  surface-container: '#1e2024'
  surface-container-high: '#282a2e'
  surface-container-highest: '#333539'
  on-surface: '#e2e2e8'
  on-surface-variant: '#b9cacb'
  inverse-surface: '#e2e2e8'
  inverse-on-surface: '#2f3035'
  outline: '#849495'
  outline-variant: '#3b494b'
  surface-tint: '#00dbe9'
  primary: '#dbfcff'
  on-primary: '#00363a'
  primary-container: '#00f0ff'
  on-primary-container: '#006970'
  inverse-primary: '#006970'
  secondary: '#ffffff'
  on-secondary: '#373100'
  secondary-container: '#fde400'
  on-secondary-container: '#716500'
  tertiary: '#fdf2ff'
  on-tertiary: '#490080'
  tertiary-container: '#eacfff'
  on-tertiary-container: '#842bd2'
  error: '#ffb4ab'
  on-error: '#690005'
  error-container: '#93000a'
  on-error-container: '#ffdad6'
  primary-fixed: '#7df4ff'
  primary-fixed-dim: '#00dbe9'
  on-primary-fixed: '#002022'
  on-primary-fixed-variant: '#004f54'
  secondary-fixed: '#fde400'
  secondary-fixed-dim: '#dec800'
  on-secondary-fixed: '#201c00'
  on-secondary-fixed-variant: '#504700'
  tertiary-fixed: '#f0dbff'
  tertiary-fixed-dim: '#ddb7ff'
  on-tertiary-fixed: '#2c0051'
  on-tertiary-fixed-variant: '#6900b3'
  background: '#111318'
  on-background: '#e2e2e8'
  surface-variant: '#333539'
typography:
  display-lg:
    fontFamily: Space Grotesk
    fontSize: 40px
    fontWeight: '700'
    lineHeight: 44px
    letterSpacing: -0.03em
  display-lg-mobile:
    fontFamily: Space Grotesk
    fontSize: 32px
    fontWeight: '700'
    lineHeight: 36px
    letterSpacing: -0.02em
  headline-lg:
    fontFamily: Space Grotesk
    fontSize: 28px
    fontWeight: '600'
    lineHeight: 32px
    letterSpacing: -0.02em
  headline-md:
    fontFamily: Space Grotesk
    fontSize: 22px
    fontWeight: '600'
    lineHeight: 28px
    letterSpacing: -0.01em
  headline-sm:
    fontFamily: Space Grotesk
    fontSize: 18px
    fontWeight: '600'
    lineHeight: 24px
    letterSpacing: 0em
  body-lg:
    fontFamily: Chivo
    fontSize: 16px
    fontWeight: '400'
    lineHeight: 24px
    letterSpacing: 0em
  body-md:
    fontFamily: Chivo
    fontSize: 14px
    fontWeight: '400'
    lineHeight: 20px
    letterSpacing: 0.01em
  body-sm:
    fontFamily: Chivo
    fontSize: 12px
    fontWeight: '400'
    lineHeight: 16px
    letterSpacing: 0.01em
  label-lg:
    fontFamily: JetBrains Mono
    fontSize: 14px
    fontWeight: '600'
    lineHeight: 18px
    letterSpacing: 0.05em
  label-md:
    fontFamily: JetBrains Mono
    fontSize: 12px
    fontWeight: '500'
    lineHeight: 16px
    letterSpacing: 0.06em
  label-sm:
    fontFamily: JetBrains Mono
    fontSize: 10px
    fontWeight: '500'
    lineHeight: 14px
    letterSpacing: 0.08em
  hud-metric:
    fontFamily: JetBrains Mono
    fontSize: 20px
    fontWeight: '700'
    lineHeight: 22px
    letterSpacing: 0.02em
spacing:
  gutter: 0.75rem
  margin: 1rem
  space-xs: 0.25rem
  space-sm: 0.5rem
  space-md: 0.75rem
  space-lg: 1.25rem
  space-xl: 1.75rem
---

## Brand & Style

The design system establishes a high-octane, electric cyberpunk aesthetic engineered for a gamified personal management interface on mobile Android devices. Combining the high-density utility of futuristic military flight decks with tactile, high-voltage sci-fi hardware, it turns mundane human routines into mission-critical power management.

### Personality & Emotional Resonance
- **Overclocked & High-Voltage:** Interfaces hum with active energy. Visual weight communicates kinetic charge, system readiness, and relentless momentum.
- **Precision HUD Instrumentation:** Data is dense, structured, and hyper-legible. The user is positioned not merely as an app user, but as an augmented operator managing real-time biometric and experiential wattage.
- **Tactile Cyber-Hardware:** Elements evoke physical gunmetal casing, chamfered alloy plates, neon micro-circuitry, and neon phosphor discharge.

### Design Movement
- **High-Contrast Neon-Industrial Cyberpunk:** Grounded pitch-black substrates paired with piercing luminescence, brushed gunmetal structural plates, micro-chamfered geometric trims, and directional electric accents.

## Colors

The palette simulates an electrified tactical dashboard against an abyss-grade void. Emissive neon accents are strictly metered to indicate states, stat categories, and power levels, preventing visual fatigue across high-density readouts.

### Palette Architecture
- **Pitch Voids & Structural Chassis (Neutrals):**
  - Core Deep Canvas: `#0A0C10` (Primary void backing)
  - Surface Substrate: `#12151E` (Base card and container fill)
  - Elevated Plate / Gunmetal: `#1B202E` (Component interactive fills)
  - Brushed Metallic Trim: `#2E374D` (Frame edges, inactive dividers, and passive grid lines)
  - Muted Alloy Text: `#8D98AF` (De-prioritized telemetry, metadata, metric labels)
  - Peak Phosphor White: `#F0F4FC` (Primary readout text, active value triggers)

- **Power Rails (Accents):**
  - **Electric Cyan (`#00F0FF`):** System telemetry, agility, intellect, active navigational focus, core XP bars.
  - **High-Voltage Yellow (`#FFE600`):** Kinetic stamina, daily streaks, warning thresholds, high-priority quest objectives, active power surge indicators.
  - **Electric Violet (`#A855F7`):** Willpower, psychic/focus attributes, legendary milestones, augmentations, and deep unlock statuses.
  - **Overload Crimson (`#FF0055`):** Failure states, energy depletion alerts, critical system cooldowns.

### Application Rules
- Maintain pure dark canvas integrity: avoid large flooded blocks of accent color. Apply saturated neons predominantly to 1px–1.5px structural vector borders, indicator pips, glow matrices, and numerical data readouts.
- Metallic brushed finishes must be simulated via directional linear gradients (e.g., `linear-gradient(135deg, #1B202E 0%, #12151E 50%, #262D40 100%)`) with 1px top-left highlight borders.

## Typography

The typographic hierarchy balances mechanical display power with ultra-dense data readouts.

- **Headlines (`Space Grotesk`):** Delivers aggressive, geometric futurism for level milestones, quest designations, and HUD quadrant titles. Always styled with slight optical tightening.
- **Body (`Chivo`):** High-clarity neo-grotesque engineered for rapid readability in log entries, inventory descriptions, and mission debriefs under dark mode contrast conditions.
- **Telemetry & Labels (`JetBrains Mono`):** Applied to coordinates, attribute readouts (HP, MP, Wattage, XP), status chips, and timestamp stamps. Render labels in uppercase (`text-transform: uppercase`) with widened tracking to evoke real-time machine readouts.

## Layout & Spacing

The layout operates on a compact 4-column fluid mobile grid anchored to an 8pt master grid (with strict 4pt micro-steps for compact data rows). Space is treated as premium operational territory; dead air is minimized in favor of segmented structural chassis and telemetry panels.

### Structural Parameters
- **Android Safe Zones:** Hardware top bar status and system navigation pill are framed with hairline gunmetal separators (`#2E374D`).
- **Margins & Gutters:** Mobile canvas margins are tightly bounded at `1rem` (16px), with internal grid gutters at `0.75rem` (12px) to maximize horizontal data density.
- **Section Rhythm:** Modular telemetry pods stack with `space-md` gaps. Sub-items inside stat clusters use `space-xs` and `space-sm` for immediate tactical grouping.
- **Reflow Architecture:** On small Android viewports (<360px), multi-column HUD clusters reflow from dual-gauge splits into single-column interlocking stacked meters.

## Elevation & Depth

Depth in this system is driven by electromagnetic radiation, metallic beveling, and surface layering, not diffused natural ambient drop shadows.

### Depth Mechanics
- **Ground Floor (Base Canvas):** `#0A0C10` matte texture with optional micro-grid or scanline pattern (0.03 opacity).
- **Chassis Level 1 (Panels & Cards):** `#12151E` background bounded by a 1px solid border of `#2E374D`. Subtle top-lit highlight via a 1px inner border (`inset 0 1px 0 rgba(255, 255, 255, 0.08)`).
- **Chassis Level 2 (Floating Modals & Interactive HUD Blades):** `#1B202E` with beveled edges and dynamic electric back-glows.
- **Neon Radiation (Electrified State):** When an element activates or surges, standard drop shadows are replaced by dual-layered chromatic glows:
  - Cyan Surge: `0 0 8px rgba(0, 240, 255, 0.45), 0 0 20px rgba(0, 240, 255, 0.15)`
  - Voltage Flare: `0 0 8px rgba(255, 230, 0, 0.5), 0 0 22px rgba(255, 230, 0, 0.2)`
  - Void Pulse: `0 0 10px rgba(168, 85, 247, 0.45), 0 0 24px rgba(168, 85, 247, 0.15)`
- **Chrome Edge Highlights:** Active interactive edges use linear gradient borders running from pure accent color fading into muted gunmetal (`#2E374D`).

## Shapes

The visual geometry is defined by zero-radius precision and angular hardware chamfers. Curvature is eradicated to reflect military avionics, hardened cybernetic plating, and high-voltage circuit architecture.

### Corner Treatments
- **Standard Geometry:** Hard 90-degree right angles (`roundedness: 0`).
- **Chamfered / Cut Corners:** Major action pods, primary buttons, and floating HUD widgets utilize a 45-degree corner clip (`clip-path: polygon(...)`) ranging from 4px to 10px on either the top-right or alternating opposing corners (top-right and bottom-left).
- **Lightning Notch Motifs:** Section headers and dynamic progress gauges feature a 60-degree diagonal strike accent cut, echoing mechanical lightning conduits.

## Components

### Buttons
- **Primary Power Trigger:** Chamfered top-right corner, brushed gunmetal gradient background (`#1B202E` to `#12151E`), framed with a 1.5px `#00F0FF` border. Typography is `JetBrains Mono` bold uppercase in `#00F0FF`. On press/active, the button floods with solid `#00F0FF`, text inverts to `#0A0C10`, and emits a concentrated cyan photon glow.
- **High-Voltage Alert Action (Quest Complete / Overdrive):** Background filled with `#FFE600`, text in pitch black `#0A0C10`, bordered with an outer 2px offset outline. Accompanied by a leading chevron or lightning pip icon.
- **Sub-tier / Utility Buttons:** Hard-angled rectangular frames, `#2E374D` borders, muted text (`#8D98AF`), brightening to Peak White (`#F0F4FC`) on touch.

### Cards & Chassis Panels
- Base containers built with `#12151E` fill. 
- Perimeter features 1px `#2E374D` borders, with the top-left and bottom-right corners reinforced by 4px tactical tick-marks or corner brackets in `#00F0FF` or `#FFE600`.
- Includes a dedicated header strip: a slim, darker horizontal bar with a monospace module code (e.g., `// MOD.01_LIFE_FORCE`) alongside status indicators.

### Progress & Power Gauges (HUD XP & Stat Bars)
- Segmented linear tracks divided into discrete visual micro-cells (e.g., 10 or 20 blocks).
- Empty cells: `#1B202E` with a 1px border. Filled cells: Solid neon fill (`#00F0FF`, `#FFE600`, or `#A855F7`) with an internal horizontal luminescence flare.
- Integrated digital readout floating right aligned above the track using `hud-metric` typography.

### Chips & Badges
- Ultra-compact, pill-free polygonal tags.
- Bounded by a 1px wireframe border colored to match the associated attribute rail (Cyan for Speed/Mind, Yellow for Stamina/Power, Violet for Will/Spirit).
- Micro-pip indicators: A 4px filled square or diamond glyph precedes the label text.

### Input Fields
- Dark inset trays with background `#0A0C10` set inside an elevated `#12151E` shell.
- Underline-dominant focus indicator: Baseline border shifts from `#2E374D` to `#00F0FF` with a localized bottom-edge neon bloom on activation.
- Monospaced placeholder text in `#8D98AF` styled like a system prompt (e.g., `INPUT_COMMAND_`).

### Checkboxes & Quest Toggles
- Square, non-rounded boxes (18px × 18px) framed in `#2E374D`.
- When checked: Frame snaps to `#FFE600`, internal area fills with `#FFE600` at 15% opacity, and displays a sharp angular checkmark or solid voltage bolt glyph in `#FFE600`.

### Additional Specialized Components
- **HUD Biometric Matrix:** Segmented radial or multi-axis polygonal radar chart displaying RPG attributes, traced in `#00F0FF` wireframes with point markers rendered as glowing `#FFE600` coordinates.
- **Overdrive Floating Action Pod:** Bottom-docked Android quick-action launcher hovering above the canvas with an open chamfered silhouette, framed in electric violet glow with real-time streak multipliers.