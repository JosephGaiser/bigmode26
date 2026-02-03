# Juice Features GDD - Egg Transport Game

## Overview
This document outlines "juice" features to enhance the impact and player agency during egg drop/damage moments in the Foddian-style vertical climbing game.

---

## 1. Bullet Time / Time Dilation

### 1.1 Egg Damage Slowdown
**When:** Egg takes damage or is about to crack

**Implementation:**
- **Trigger Conditions:**
  - Egg health reaches critical threshold (< 30%)
  - Egg collides with hazard/obstacle
  - Egg begins to fall from significant height

- **Time Scale:**
  - Slow time to 0.2-0.3 (70-80% slowdown)
  - Duration: 0.8-1.2 seconds
  - Smooth ease-in/ease-out curves

- **Visual Enhancements:**
  - Motion blur on falling egg
  - Slight chromatic aberration at screen edges
  - Vignette effect pulsing
  - Particle effects (crack particles) slowed proportionally

### 1.2 Clutch Catch Slowdown
**When:** Player successfully grabs falling egg at high speed

**Implementation:**
- **Trigger Conditions:**
  - Egg velocity > threshold (e.g., 800 units/sec)
  - Player grabs egg within 0.5 seconds of it entering "danger zone"

- **Time Scale:**
  - Brief 0.15-0.25 second slowdown to 0.4
  - Quick snap back to normal speed
  - Feels "heroic" and precise

- **Audio:** Satisfying "whoosh" or "catch" sound pitch-shifted down during slowmo

---

## 2. Screen Shake / Impact Feedback

### 2.1 Egg Crack Impact Shake
**When:** Egg takes damage

**Implementation:**
- **Shake Intensity:** Scaled by damage amount
  - Minor crack: 2-4 pixels, 0.15s duration
  - Moderate crack: 6-10 pixels, 0.25s duration
  - Critical crack: 12-20 pixels, 0.4s duration

- **Shake Pattern:**
  - Random directional shake (not just horizontal)
  - Decay curve: starts intense, smoothly reduces
  - Frequency: 30-60 Hz for impact feel

### 2.2 Multi-Stage Crack Feedback
**When:** Egg health crosses damage thresholds

**Implementation:**
- **Visual Stages:**
  - Intact → hairline cracks (>66% health)
  - Hairline → visible cracks (33-66% health)
  - Visible → deep cracks (<33% health)

- **Each Stage Triggers:**
  - Screen shake (increasing intensity)
  - Crack sound effect (pitch decreases with more damage)
  - Particle burst (shell fragments)
  - Brief red/orange screen flash

### 2.3 Hand Injury Shake
**When:** Hand enters hazard zone (already implemented in `hand.gd:322`)

**Enhancement Suggestions:**
- Add camera shake to existing blood particles and audio
- Shake intensity: 5-8 pixels, 0.2s duration
- Rapid shake frequency (60+ Hz) for "sharp pain" feel

---

## 3. Clutch Catch Mechanics

### 3.1 Last-Second Grab Window
**Mechanic:** Extended grab range during critical moments

**Implementation:**
- **Trigger Conditions:**
  - Egg velocity exceeds "freefall threshold"
  - Egg is within detection radius (300-500 units from hand)
  - Player is not currently holding anything

- **Grab Range Boost:**
  - Normal grab range: current `grab_area_2d` radius
  - Emergency range: 1.5-2.0x normal radius
  - Visual indicator: subtle glow or outline on egg when in emergency range

### 3.2 Dive Catch Mechanic
**Mechanic:** Boost hand speed toward falling egg

**Implementation:**
- **Activation:**
  - Double-tap/hold sprint key (e.g., Shift)
  - Only available when egg is falling

- **Effect:**
  - `hand.speed` multiplied by 1.8-2.5x for 0.3-0.5 seconds
  - Trail/streak effect behind hand
  - Slight camera anticipation toward target

- **Cooldown:** 2-3 seconds after use
- **Risk/Reward:** Less control during dive, but faster reach

### 3.3 Perfect Catch Feedback
**Mechanic:** Extra reward for skillful catches

**Implementation:**
- **Perfect Catch Criteria:**
  - Grab egg within 0.2s of entering danger threshold
  - Egg velocity > 700 units/sec
  - Clean catch (no collision with obstacles during grab)

- **Rewards:**
  - Particle burst (sparkles/stars)
  - Screen flash (gold/white)
  - Audio: triumphant sound effect
  - Brief time dilation (0.3s at 0.3 scale)
  - Optional: small health restoration (+5-10%)

### 3.4 Wall Bounce Recovery
**Mechanic:** Opportunity to catch egg after wall collision

**Implementation:**
- **Trigger:** Egg bounces off wall at high speed
- **Effect:**
  - 0.5s window of reduced gravity on egg (30-50% normal)
  - Allows player to reposition for grab
  - Visual: egg glows/shimmers during window

- **Audio:** "Boing" sound with reverb tail

---

## 4. Progressive Tension System

### 4.1 Danger Proximity Indicators
**Visual Feedback:** As egg approaches hazards

**Implementation:**
- **Distance Thresholds:**
  - Far (>200 units): No indicator
  - Medium (100-200): Subtle pulsing vignette
  - Close (50-100): Faster pulse, slight red tint
  - Critical (<50): Intense pulse, chromatic aberration

- **Audio:** Low-frequency heartbeat sound increases in tempo

### 4.2 Altitude Loss Feedback
**When:** Player loses significant vertical progress

**Implementation:**
- **Trigger:** Drop > 500 units within 2 seconds
- **Effects:**
  - Whooshing wind audio (pitch scales with fall speed)
  - Screen darkens slightly at edges
  - Optional: brief "ghost" trail showing last stable position

---

## 5. Technical Implementation Notes

### 5.1 Time Dilation System
**Location:** Global autoload script or camera controller

```gdscript
# Example structure
var time_stack: Array[Dictionary] = []

func apply_time_dilation(scale: float, duration: float, priority: int = 0):
    # Higher priority effects override lower
    # Stack allows multiple systems to request slowmo
```

### 5.2 Camera Shake System
**Location:** Extend current camera setup

```gdscript
# Add to camera script
var trauma: float = 0.0  # 0-1 value
func add_trauma(amount: float):
    trauma = min(trauma + amount, 1.0)
```

### 5.3 Integration Points

**In `hand.gd`:**
- `_on_vulnerable_area_2d_area_entered()` (line 322): Add camera shake
- `_try_grab()` (line 164): Check for clutch catch conditions
- `_apply_hold_force()` (line 267): Monitor egg velocity for triggers

**In egg script:**
- Health/damage system: Trigger time dilation and shake
- Collision detection: Check for high-speed impacts
- Add `get_danger_level()` method for proximity checks

---

## 6. Tuning Parameters

### Recommended Settings
| Feature | Parameter | Value Range | Default |
|---------|-----------|-------------|---------|
| Damage Slowmo | Time Scale | 0.2-0.4 | 0.25 |
| Damage Slowmo | Duration | 0.6-1.5s | 1.0s |
| Clutch Slowmo | Time Scale | 0.3-0.5 | 0.4 |
| Clutch Slowmo | Duration | 0.1-0.3s | 0.2s |
| Screen Shake | Minor Trauma | 0.1-0.3 | 0.2 |
| Screen Shake | Major Trauma | 0.5-0.8 | 0.6 |
| Emergency Grab | Range Multiplier | 1.5-2.5x | 2.0x |
| Dive Catch | Speed Multiplier | 1.8-2.5x | 2.2x |
| Dive Catch | Cooldown | 1.5-3.0s | 2.0s |

---

## 7. Priority Implementation Order

1. **High Priority (Core Juice):**
   - Camera shake on egg damage
   - Basic time dilation on critical damage
   - Extended grab range for falling egg

2. **Medium Priority (Clutch Mechanics):**
   - Clutch catch detection and feedback
   - Perfect catch rewards
   - Dive catch mechanic

3. **Low Priority (Polish):**
   - Progressive danger indicators
   - Wall bounce recovery window
   - Multi-stage crack visual progression

---

## 8. Playtesting Focus Areas

- **Does slowmo give enough time to react?** Adjust duration/scale
- **Is screen shake too intense/not enough?** Test on different displays
- **Do clutch mechanics feel satisfying or "cheap"?** Balance risk/reward
- **Does juice distract or enhance core gameplay?** May need toggles

---

*Document Version: 1.0*
*Date: 2026-02-02*
