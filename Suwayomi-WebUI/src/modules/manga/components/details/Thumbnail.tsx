/*
 * Copyright (C) Contributors to the Suwayomi project
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import { bindMenu, usePopupState } from 'material-ui-popup-state/hooks';
import { Vibrant } from 'node-vibrant/browser';
import { useLongPress } from 'use-long-press';
import { SpinnerImage } from '@/modules/core/components/SpinnerImage.tsx';
import { MANGA_COVER_ASPECT_RATIO } from '@/modules/manga/Manga.constants.ts';
import { MangaIdInfo, MangaThumbnailInfo } from '@/modules/manga/Manga.types.ts';
import { Mangas } from '@/modules/manga/services/Mangas.ts';
import { ThumbnailOptionButton } from '@/modules/manga/components/ThumbnailOptionButton.tsx';
import { TAppThemeContext, useAppThemeContext } from '@/modules/theme/contexts/AppThemeContext.tsx';

import { useMemo, useLayoutEffect, useState, useRef } from 'react';
import { Stack, Menu } from '@mui/material';
import { useTheme } from '@mui/material/styles';
import { MangaActionMenuItems } from '@/modules/manga/components/MangaActionMenuItems.tsx';
import { FastAverageColor } from 'fast-average-color';

export const Thumbnail = ({
    manga,
    mangaDynamicColorSchemes,
}: {
    manga: Partial<MangaThumbnailInfo & MangaIdInfo>;
    mangaDynamicColorSchemes: boolean;
}) => {
    const theme = useTheme();
    const { setDynamicColor } = useAppThemeContext();
    const setDynamicColorRef = useRef(setDynamicColor);
    setDynamicColorRef.current = setDynamicColor;

    const thumbnailUrl = useMemo(() => {
        try {
            return Mangas.getThumbnailUrl(manga);
        } catch {
            return '';
        }
    }, [manga]);

    const shouldProcessDynamicColor = mangaDynamicColorSchemes && thumbnailUrl;

    const popupState = usePopupState({ variant: 'popover', popupId: 'manga-thumbnail-options' });
    const [isImageReady, setIsImageReady] = useState(false);
    const [isHovered, setIsHovered] = useState(false);

    const safeMangaForActions = useMemo(() => {
        if (!manga) {
            return {
                id: '',
                title: 'Unknown Manga',
                sourceId: 0,
                downloadCount: 0,
                unreadCount: 0,
                chapters: { totalCount: 0 },
            } as any;
        }
        return manga;
    }, [manga]);

    const longPressEvent = useLongPress(
        () => {
            popupState.open(undefined);
        },
        { threshold: 600 },
    );

    useLayoutEffect(() => {
        let isMounted = true;

        if (!shouldProcessDynamicColor || !thumbnailUrl) {
            setDynamicColorRef.current(null);
            return undefined;
        }

        const img = new Image();
        img.crossOrigin = 'anonymous';
        img.src = thumbnailUrl;

        img.onload = async () => {
            if (!isMounted) return;
            const isLargeImage = img.width > 600 && img.height > 600;
            
            try {
                const palette = await Vibrant.from(img).getPalette();
                const averageColor = await new FastAverageColor().getColor(img, {
                    algorithm: 'dominant',
                    mode: isLargeImage ? 'speed' : 'precision',
                    ignoredColor: [
                        [255, 255, 255, 255, 75],
                        [0, 0, 0, 255, 75],
                    ],
                });

                if (
                    !palette.Vibrant ||
                    !palette.DarkVibrant ||
                    !palette.LightVibrant ||
                    !palette.LightMuted ||
                    !palette.Muted ||
                    !palette.DarkMuted
                ) {
                    // If palette is incomplete, don't set dynamic colors
                    if (isMounted) {
                        setDynamicColorRef.current(null);
                    }
                    return;
                }

                const newColors = {
                    ...palette,
                    average: averageColor,
                } as TAppThemeContext['dynamicColor'];

                if (isMounted) {
                    setDynamicColorRef.current(newColors);
                }
            } catch (error) {
                console.error("Error processing image colors:", error);
                if (isMounted) {
                    setDynamicColorRef.current(null); // Reset on error
                }
            }
        };

        // Handle potential image loading errors
        img.onerror = () => {
            console.error("Failed to load image for color extraction.");
            if (isMounted) {
                setDynamicColorRef.current(null);
            }
        };

        return () => {
            isMounted = false;
            setDynamicColorRef.current(null); // Ensure cleanup
        };
    }, [shouldProcessDynamicColor, thumbnailUrl]);

    if (!thumbnailUrl) return null;

    return (
        <Stack
            {...longPressEvent}
            onMouseEnter={() => setIsHovered(true)}
            onMouseLeave={() => setIsHovered(false)}
            onContextMenu={(e: React.MouseEvent) => {
                e.preventDefault();
                popupState.open(e);
            }}
            sx={{
                position: 'relative',
                borderRadius: 1,
                overflow: 'hidden',
                backgroundColor: 'background.paper',
                width: '150px',
                maxHeight: 'fit-content',
                aspectRatio: MANGA_COVER_ASPECT_RATIO,
                flexShrink: 0,
                flexGrow: 0,
                [theme.breakpoints.up('lg')]: {
                    width: '200px',
                },
                [theme.breakpoints.up('xl')]: {
                    width: '300px',
                },
                cursor: 'pointer',
            }}
            component="div"
            ref={(node) => popupState.setAnchorEl(node)}
        >
            <div
                style={{
                    position: 'absolute',
                    inset: 0,
                    pointerEvents: 'none',
                    background: 'rgba(0,0,0,0.3)',
                    opacity: isHovered ? 1 : 0,
                    transition: 'opacity 200ms',
                    zIndex: 0,
                }}
            />
            <SpinnerImage
                src={thumbnailUrl}
                alt="Manga Thumbnail"
                onLoad={() => setIsImageReady(true)}
                imgStyle={{ width: '100%', height: '100%', objectFit: 'cover', display: 'block' }}
            />
            <ThumbnailOptionButton popupState={popupState} visible={isHovered && isImageReady} />
            <Menu
                {...bindMenu(popupState)}
                id="manga-thumbnail-options-menu"
                anchorOrigin={{ vertical: 'bottom', horizontal: 'right' }}
                transformOrigin={{ vertical: 'top', horizontal: 'right' }}
            >
                <MangaActionMenuItems
                    manga={safeMangaForActions}
                    onClose={() => {
                        popupState.close();
                    }}
                    setHideMenu={(hide) => {
                        if (hide) popupState.close();
                    }}
                />
            </Menu>
        </Stack>
    );
};
