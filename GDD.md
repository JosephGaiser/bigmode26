# Game Design Document: The Long Reach (Working Title)

## 1. Executive Summary
A surreal, narrative-driven physics puzzler where you control a disembodied arm searching for connection. The game is a "short and sweet" experience focused on tactile interaction and environmental storytelling, culminating in a meeting between two hands.

## 2. Narrative & Progression Loop
1.  **Awakening:** The arm starts in a cluttered, lonely environment.
2.  **Puzzle Interactions:** The player must manipulate objects to unlock new areas or items.
    *   *Example:* Using the **Soap** to make a surface or object slippery enough to reach or slide a **Knife**.
    *   *Example:* Using the **Knife** to cut through a cord or obstacle to reach the **Boombox**.
3.  **Discovery:** Each solved puzzle brings the arm closer to its goal.
4.  **The Meeting:** Finding another arm at the end of the journey.
5.  **The Ending:** The two hands "kiss" (touch/intertwine), followed by credits.

## 3. Key Mechanics

### 3.1. The Hand (Player Controller)
*   **Movement:** Follows the mouse cursor with physics-based smoothing.
*   **Grabbing:** Click and hold to grab physics objects.
*   **Rotation (Articulation):** Hold a modifier key and move the mouse to rotate objects, essential for solving orientation-based puzzles.

### 3.2. Puzzle Systems
*   **Tool Interaction:** Objects like the **Knife** are not just for slicing food but for modifying the environment (cutting ropes, prying things open).
*   **Physical Properties:** Mechanics like **Slippiness** (Soap) are used as puzzle solutions rather than just hazards.
*   **Object Combinations:** Placing or using certain items near others to trigger narrative beats or environmental changes (e.g., turning on the Boombox to change the mood/music).

### 3.3. The "Slick" Mechanic (Slippiness)
*   **Soap:** Used to reduce friction on objects or surfaces, allowing them to be moved or interacted with in ways otherwise impossible.
*   **Grip Multiplier:** Slippery objects require careful handling, adding a layer of "clumsy" charm to the puzzles.

## 4. Setting & Theme
*   **Setting:** A surreal, dream-like space filled with everyday objects that feel monumental.
*   **Art Style:** Stylized 2D/3D hybrid with CRT/Dither effects, creating a nostalgic, slightly hazy vibe.
*   **Tone:** Bittersweet, tactile, and romantic. Focus on the feeling of reaching for something.

## 5. Puzzle Flow (Examples)
*   **The Soap & The Knife:** The Knife is stuck or out of reach; the Soap's bubbles/slipperiness is used to lubricate a mechanism or slide the knife out.
*   **The Knife & The Boombox:** Cutting a ribbon or tape that keeps the Boombox silent or trapped.
*   **The Final Reach:** Moving through the final obstacle to reach the other arm.

## 6. Technical Overview (Godot 4.x)
*   **Entities:**
    *   `Hand`: CharacterBody2D with Area2D for grabbing.
    *   `Interactable`: Component attached to RigidBody2Ds to handle signals and custom puzzle logic.
    *   `Puzzle Objects`: Specialized scripts (like `soap.gd`, `knife.gd`) that trigger events when certain conditions are met.
*   **Shaders:** CRT and Dither palette shaders for a retro, "found footage" aesthetic.
