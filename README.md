# Hyprland Dotfiles

My personal Hyprland desktop configuration for **Arch Linux**. I use it for everyday work, university, and programming—including learning OpenGL. This is a work in progress, shaped around the way I use my machine rather than a universal desktop setup.

<p align="center">
  <strong>Arch Linux · Hyprland · Lua · Waybar · Matugen</strong>
</p>

## Showcase

<p align="center">
  <strong>Hyprland desktop in action</strong>
</p>

https://github.com/user-attachments/assets/2b16facf-8c12-4ebc-93fa-440a60e79197

<p align="center">
  <sub>
    <a href="assets/screenshots/2026-10-17_15-19-29.mp4">View the MP4 in the repository</a>
  </sub>
</p>

The recording is stored in the repository and linked here. GitHub does not render repository-relative MP4 files as inline players in a README; the link opens the video file. For an inline player, upload the MP4 in the GitHub README editor and use the generated `github.com/user-attachments/assets/...` URL on its own line.

## Screenshots

The showcase recording and existing screenshots are stored in [`assets/screenshots/`](assets/screenshots/). The first slot below is intentionally empty: place the desktop image you want to feature in `resources/`, then replace `your-desktop-image.png` with its filename.

<table>
  <tr>
    <td align="center" width="50%">
      <strong>Desktop screenshot</strong><br>
      <em>Screenshot coming soon</em><br>
      <sub>Add your image to <code>resources/</code> and enable the example below.</sub><br><br>
      <!-- Uncomment after adding your image to resources/:
      <a href="resources/your-desktop-image.png"><img src="resources/your-desktop-image.png" alt="Hyprland desktop" width="100%"></a>
      -->
    </td>
    <td align="center" width="50%">
      <strong>Desktop · Alternate view</strong><br>
      <em>A second view of the session</em><br><br>
      <a href="assets/screenshots/2026-10-17_16-33-16.png"><img src="assets/screenshots/2026-10-17_16-33-16.png" alt="Hyprland desktop screenshot from 16:33:16" width="100%"></a>
    </td>
  </tr>
  <tr>
    <td align="center" width="50%">
      <strong>Another view</strong><br>
      <em>Additional desktop screenshot</em><br><br>
      <a href="assets/screenshots/another.png"><img src="assets/screenshots/another.png" alt="Additional Hyprland screenshot" width="100%"></a>
    </td>
    <td align="center" width="50%">
      <strong>Application launcher</strong><br>
      <em>Launching applications with Wofi</em><br><br>
      <a href="assets/screenshots/launcher.png"><img src="assets/screenshots/launcher.png" alt="Wofi application launcher" width="100%"></a>
    </td>
  </tr>
</table>

<details>
  <summary>Earlier screenshots</summary>

  <p align="center">
    <strong>Earlier desktop view</strong><br><br>
    <img src="https://github.com/user-attachments/assets/36930857-24f0-476c-9ea8-59176b2719c3" alt="Earlier Hyprland desktop screenshot" width="100%">
  </p>
  <p align="center">
    <strong>Earlier tiled-window layout</strong><br><br>
    <img src="https://github.com/user-attachments/assets/d5b19a94-2b60-426d-b26f-5307ae73a397" alt="Earlier tiled Hyprland windows" width="100%">
  </p>
  <p align="center">
    <strong>Earlier development workflow</strong><br><br>
    <img src="https://github.com/user-attachments/assets/1f07eba8-4921-43b8-a76e-2ea0cdbb3b0a" alt="Earlier desktop while learning OpenGL" width="100%">
  </p>
</details>

## Features

### Modular Lua configuration

Hyprland settings are split into small modules that are loaded by `.config/hypr/hyprland.lua`:

| Module | Responsibility |
|---|---|
| `monitors.lua` | Monitor mode, position, and scale |
| `programs.lua` | Commands used by application-launcher keybindings |
| `autostart-env.lua` | Startup commands and Wayland/session environment variables |
| `permissions.lua` | Hyprland permission enforcement and explicit screencopy/plugin permissions |
| `lookandfeel.lua` | Colors, gaps, layout, blur, shadows, opacity, and animations |
| `input.lua` | Keyboard layouts, mouse/touchpad behavior, and workspace swipe gesture |
| `misc.lua` | Miscellaneous compositor options |
| `keybinds.lua` | Application, window, workspace, media, and capture shortcuts |
| `submaps.lua` | Temporary resize mode |
| `windowsandworkspaces.lua` | Window rules and workspace-related behavior |
| `switches.lua` | Laptop lid-switch behavior |

This separation keeps individual settings easier to locate and change without turning one file into a giant configuration block.

Matugen templates live in `.config/matugen/templates/`. The shared GTK
