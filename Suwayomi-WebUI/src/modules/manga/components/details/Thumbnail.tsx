/*
 * Copyright (C) Contributors to the Suwayomi project
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import { useTheme } from '@mui/material/styles';
import { useLayoutEffect, useMemo, useRef } from 'react';
import { Stack, CardActionArea } from '@mui/material';
import { Vibrant } from 'node-vibrant/browser';
import { FastAverageColor } from 'fast-average-color';
import { LongPressCallback } from 'use-long-press';
import { ThumbnailOptionButton } from '@/modules/manga/components/ThumbnailOptionButton.tsx';
import { PopupState } from 'material-ui-popup-state/hooks';

import { Mangas } from '@/modules/manga/services/Mangas.ts';
import { SpinnerImage } from '@/modules/core/components/SpinnerImage.tsx';
import { MANGA_COVER_ASPECT_RATIO } from '@/modules/manga/Manga.constants.ts';
import { MangaIdInfo, MangaThumbnailInfo } from '@/modules/manga/Manga.types.ts';
import { TAppThemeContext, useAppThemeContext } from '@/modules/theme/contexts/AppThemeContext.tsx';

export const Thumbnail = ({
    manga,
    mangaDynamicColorSchemes,
    popupState,
    longPressEvent,
}: {
    manga: Partial<MangaThumbnailInfo & MangaIdInfo>;
    mangaDynamicColorSchemes: boolean;
    popupState: PopupState;
    longPressEvent: (callback: LongPressCallback | null, options?: import("use-long-press").LongPressOptions) => import("react").DOMAttributes<Element>;
}) => {
    const theme = useTheme();
    const { setDynamicColor } = useAppThemeContext();
    const anchorRef = useRef<HTMLDivElement>(null);
    const optionButtonRef = useRef<HTMLButtonElement>(null);

    const thumbnailUrl = useMemo(() => {
        try {
            return Mangas.getThumbnailUrl(manga);
        } catch {
            return '';
        }
    }, [manga]);

    useLayoutEffect(() => {
        if (!mangaDynamicColorSchemes) {
            return () => {};
        }

        const img = new Image();
        img.crossOrigin = 'anonymous';
        img.src = Mangas.getThumbnailUrl(manga);

        img.onload = () => {
            const isLargeImage = img.width > 600 && img.height > 600;

            Promise.all([
                Vibrant.from(img).getPalette(),
                new FastAverageColor().getColor(img, {
                    algorithm: 'dominant',
                    mode: isLargeImage ? 'speed' : 'precision',
                    ignoredColor: [
                        [255, 255, 255, 255, 75],
                        [0, 0, 0, 255, 75],
                    ],
                }),
            ]).then(([palette, averageColor]) => {
                if (
                    !palette.Vibrant ||
                    !palette.DarkVibrant ||
                    !palette.LightVibrant ||
                    !palette.LightMuted ||
                    !palette.Muted ||
                    !palette.DarkMuted
                ) {
                    return;
                }

                setDynamicColor({
                    ...palette,
                    average: averageColor,
                } as TAppThemeContext['dynamicColor']);
            });
        };

        return () => {
            setDynamicColor(null);
        };
    }, []);

    if (!thumbnailUrl) return null;

    return (
        <Stack
            ref={anchorRef}
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
                '@media (hover: hover) and (pointer: fine)': {
                    '&:hover .hover-overlay': {
                        opacity: 1,
                    },
                },
            }}
        >
            <CardActionArea
                {...longPressEvent(() => popupState.open(optionButtonRef.current))}
                disableRipple={popupState.isOpen}
                sx={{
                    height: '100%',
                    width: '100%',
                }}
            >
                <div
                    className="hover-overlay"
                    style={{
                        position: 'absolute',
                        inset: 0,
                        pointerEvents: 'none',
                        background: 'rgba(0,0,0,0.3)',
                        opacity: 0,
                        transition: 'opacity 200ms',
                        zIndex: 0,
                    }}
                />
                <SpinnerImage
                    src={thumbnailUrl}
                    alt="Manga Thumbnail"
                    imgStyle={{ width: '100%', height: '100%', objectFit: 'cover', display: 'block' }}
                />
            </CardActionArea>
            <ThumbnailOptionButton ref={optionButtonRef} popupState={popupState} />
        </Stack>
    );
};
