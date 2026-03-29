# Send Control Icon Guidelines

This file defines production-ready constraints for:
1. macOS menu bar icon (status item)
2. macOS app icon (App Store / distribution)

## 1) Menu Bar Icon (Status Item)

Use this for the icon shown in the top menu bar.

### Required rules
- Monochrome only (no color fills for production).
- Export as PDF vector (single-page).
- Must work as template image (`isTemplate = true`).
- No text labels inside the icon.
- Keep visual center balanced in a square canvas.

### Canvas and safe area
- Artboard: `18 x 18 pt`.
- Keep all strokes inside a `14 x 14 pt` live area centered on canvas.
- Recommended padding: `2 pt` each side.

### Stroke and geometry
- Stroke width: `1.75 pt` to `2.0 pt`.
- Line caps and joins: round.
- Minimum gap between shapes: `1.5 pt`.
- Avoid tiny decorative details below `1.2 pt`.

### States
- Do not make separate ON/OFF icon files unless necessary.
- Prefer same icon with menu title showing ON/OFF state.

### Export checklist
- PDF vector, no raster effects.
- No clipping masks.
- No transparency gradients.
- Bounds exactly match artboard.

## 2) macOS App Icon (for bundle / App Store)

Use this for app identity and App Store listing.

### Required rules
- Full-color icon allowed.
- Keep one master at `1024 x 1024 px`.
- No transparent background for final icon.
- Avoid text unless absolutely necessary.

### Visual structure
- Keep key shape inside ~80% central area.
- Use clear silhouette that remains recognizable at 16px.
- Strong contrast between foreground and background.

### Typical output sizes
Prepare PNG files for these common sizes:
- `16, 32, 64, 128, 256, 512, 1024`

(Each as square PNG. Add @2x variants as needed by asset workflow.)

## 3) Suggested workflow

1. Design menu bar icon from `templates/icons/menubar_template_18pt.svg`.
2. Export to PDF vector (template icon source).
3. Design app icon from `templates/icons/app_icon_template_1024.svg`.
4. Export required PNG sizes.
5. Integrate into Xcode assets.

## 4) Quality gate before release

- Menu bar icon legible in both light and dark menu bar.
- App icon remains identifiable at 16px.
- No Apple trademarked symbols copied from system icons.
- No third-party logo resemblance.
