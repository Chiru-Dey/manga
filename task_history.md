# Task History: Fix 3-dot Button and Context Menu for Manga Cards

## Initial Problem Statement
The user reported several issues with the 3-dot button and its associated context menu on manga cards in the `Suwayomi-WebUI` project:
*   The 3-dot button was always visible instead of appearing only on hover.
*   Incorrect positioning and styling of the 3-dot button.
*   A redundant two-step "Expand" action, where clicking "Expand" in the context menu first closed that menu and then opened a full-screen modal.
*   The context menu was mispositioned.

## Files Analyzed
*   [`Suwayomi-WebUI/src/modules/manga/components/ThumbnailOptionButton.tsx`](Suwayomi-WebUI/src/modules/manga/components/ThumbnailOptionButton.tsx)
*   [`Suwayomi-WebUI/src/modules/manga/components/details/Thumbnail.tsx`](Suwayomi-WebUI/src/modules/manga/components/details/Thumbnail.tsx)
*   [`Suwayomi-WebUI/package.json`](Suwayomi-WebUI/package.json) (for dependencies context)

## Implemented Changes (as of current state)
### `Suwayomi-WebUI/src/modules/manga/components/ThumbnailOptionButton.tsx`
*   **Removed Unused Imports:** `Menu`, `MenuItem`, `bindMenu`, `MangaIdInfo`, `MangaThumbnailInfo` were removed as they are no longer necessary for this component's new role.
*   **Updated `ThumbnailOptionButtonProps` Interface:** The `manga` prop was removed from the interface, as the component no longer needs access to the manga object directly.
*   **Styling and Positioning:**
    *   Changed the `position` from `bottom: 8` to `top: 8` in the `sx` prop to correct the button's vertical alignment.
    *   Adjusted `backgroundColor` and `color` for better visibility and hover effects.
*   **Component Simplification:** The `Menu` and `MenuItem` components within `ThumbnailOptionButton` were removed. The responsibility for opening the full-screen modal directly from a context menu has been shifted to the `Thumbnail.tsx` component.
*   **Functional Component Refactor:** The component was refactored to directly return the `IconButton`, simplifying its structure by removing the unnecessary React Fragment (`<>`).

### `Suwayomi-WebUI/src/modules/manga/components/details/Thumbnail.tsx`
*   **Hover State Management:**
    *   Introduced a new state variable: `const [isHovered, setIsHovered] = useState(false);` to track the hover state of the manga card.
    *   Added `onMouseEnter={() => setIsHovered(true)}` and `onMouseLeave={() => setIsHovered(false)}` event handlers to the main `Stack` component, making the 3-dot button visible only on hover.
*   **Direct Full-screen Modal Trigger:**
    *   Modified the `onContextMenu` handler (and the `longPressEvent` binding implicitly) to directly call `popupState.open()` instead of `thumbnailMenuPopupState.open()`, thus eliminating the redundant two-step "Expand" action.
*   **Removed Redundant Context Menu State:** The `thumbnailMenuPopupState` (e.g., `const thumbnailMenuPopupState = usePopupState(...)`) and its associated `Menu` and `MenuItem` components were removed, as the direct `popupState` is now used for the context menu.
*   **Conditional Rendering of `ThumbnailOptionButton`:** The `ThumbnailOptionButton` is now rendered conditionally based on `isImageReady` AND `isHovered`, ensuring it only appears when the image is loaded and the user hovers over the card. The `manga` prop was also removed from this component call.

## Next Steps
*   Verify implemented changes in the browser.