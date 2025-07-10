# Task History: Manga Thumbnail Context Menu

This document details the process of implementing a context menu for the manga thumbnail on the manga details page, including debugging and refining the functionality to match the library's manga card behavior.

## 1. Initial Request & Error Resolution

*   **Objective**: Replace the simple click-to-fullscreen functionality on the manga thumbnail with a context menu.
*   **Behavior to Mirror**: The context menu should be triggered by a long-press on the thumbnail or a click on a new three-dot options button, mimicking the behavior of the `MangaGridCard` component in the library.
*   **Initial Bug**: The first implementation attempt resulted in a "Maximum update depth exceeded" React error. This was caused by a Rules of Hooks violation related to the `material-ui-popup-state` library.
*   **Resolution**: The component was refactored to remove the `material-ui-popup-state` dependency and manage the menu's state using standard React hooks (`useState`), which resolved the infinite loop.

## 2. Iterative Debugging: Button Visibility

After fixing the initial crash, a series of UI bugs appeared related to the visibility of the three-dot options button.

*   **Problem**: The options button would disappear when the menu was opened, because its visibility was tied only to the parent's `:hover` state. When the menu appeared, the hover was lost, the button vanished, and the menu's anchor became invalid. This also caused the long-press to fail intermittently.
*   **Solution**: The button's visibility logic was corrected. It was made dependent on two conditions: the CSS `:hover` state *and* the menu's open state (`isMenuOpen`). This required modifying both `ThumbnailOptionButton.tsx` (to remove its internal visibility styles) and `Thumbnail.tsx` (to add the conditional visibility logic), ensuring the button remained a stable anchor when the menu was active.

## 3. Final Refinement: Long-Press & Ripple Animation

Even with the visibility fixed, the long-press behavior was still incorrect.

*   **Problem 1 (Long-Press)**: The long-press was not triggering the menu correctly. The menu would only appear on mouse release, not after the specified duration. Furthermore, the menu was incorrectly anchored to the thumbnail itself, not the three-dot button.
*   **Problem 2 (Ripple Animation)**: The ripple effect on the thumbnail continued for the entire duration of the long-press, which did not match the subtle, shorter animation of the reference component.
*   **Problem 3 (Click Behavior)**: A regular (short) click on the thumbnail was incorrectly opening the menu.

### Root Cause & Definitive Solution

A deep comparison with the reference `MangaGridCard.tsx` component revealed the root cause: an architectural conflict between the `use-long-press` library and Material-UI's `CardActionArea`.

*   **The Fix**:
    1.  **Event Handler Isolation**: The `CardActionArea` was wrapped in a `div`, and the `use-long-press` event listeners were moved to this new wrapper. This isolated the library's event handling from the `CardActionArea`'s internal logic.
    2.  **Programmatic Click**: The `useLongPress` callback was changed to programmatically dispatch a `click` event on the three-dot button (`optionButtonRef.current?.click()`). This ensures the menu is always triggered by and anchored to the correct element.
    3.  **Ripple Control**: A new state variable (`isLongPressing`) was introduced. Using the `onStart` and `onCancel` callbacks from `use-long-press`, this state is used to conditionally disable the `CardActionArea`'s ripple effect (`disableRipple={isLongPressing}`) during a long-press.
    4.  **Removed Incorrect Click**: The `onClick` handler was removed from the thumbnail area, so a short click no longer has any effect.

This final, comprehensive refactor was intended to resolve all outstanding issues. However, the long-press functionality still fails to trigger the context menu, indicating a deeper, unresolved issue in the event handling logic. The task is ongoing.