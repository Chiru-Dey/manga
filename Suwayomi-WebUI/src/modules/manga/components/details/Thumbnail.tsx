/*
 * Copyright (C) Contributors to the Suwayomi project
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import React, { useLayoutEffect, useState, useMemo } from 'react';
import Modal from '@mui/material/Modal';
import Menu from '@mui/material/Menu';
import MenuItem from '@mui/material/MenuItem';
import Stack from '@mui/material/Stack';
import { useTheme } from '@mui/material/styles';
import { FastAverageColor } from 'fast-average-color';
import { bindMenu, usePopupState } from 'material-ui-popup-state/hooks';
import { Vibrant } from 'node-vibrant/browser';
import { useLongPress } from 'use-long-press';
import { SpinnerImage } from '@/modules/core/components/SpinnerImage.tsx';
import { MANGA_COVER_ASPECT_RATIO } from '@/modules/manga/Manga.constants.ts';
import { MangaIdInfo, MangaThumbnailInfo } from '@/modules/manga/Manga.types.ts';
import { Mangas } from '@/modules/manga/services/Mangas.ts';
import { ThumbnailOptionButton } from '@/modules/manga/components/ThumbnailOptionButton.tsx';
import { TAppThemeContext, useAppThemeContext } from '@/modules/theme/contexts/AppThemeContext.tsx';

export const Thumbnail = ({
    manga,
    mangaDynamicColorSchemes,
}: {
    manga: Partial<MangaThumbnailInfo & MangaIdInfo>;
    mangaDynamicColorSchemes: boolean;
}) => {
    const theme = useTheme();
    const { setDynamicColor } = useAppThemeContext();

    const thumbnailUrl = useMemo(() => {
        try {
            return Mangas.getThumbnailUrl(manga);
        } catch {
            return '';
        }
    }, [manga]);

    const shouldProcessDynamicColor = mangaDynamicColorSchemes && thumbnailUrl;

    const popupState = usePopupState({ variant: 'popover', popupId: 'manga-thumbnail-options' });
    const [isModalOpen, setIsModalOpen] = useState(false);
    const [isImageReady, setIsImageReady] = useState(false);
    const [isHovered, setIsHovered] = useState(false);

    const longPressEvent = useLongPress(
        (event) => {
            popupState.open(event);
        },
        { threshold: 600 },
    );

    const processImageColors = async (image: HTMLImageElement) => {
        const isLargeImage = image.width > 600 && image.height > 600;
        const [palette, averageColor] = await Promise.all([
            Vibrant.from(image).getPalette(),
            new FastAverageColor().getColor(image, {
                algorithm: 'dominant',
                mode: isLargeImage ? 'speed' : 'precision',
                ignoredColor: [
                    [255, 255, 255, 255, 75],
                    [0, 0, 0, 255, 75],
                ],
            }),
        ]);

        if (
            !palette.Vibrant ||
            !palette.DarkVibrant ||
            !palette.LightVibrant ||
            !palette.LightMuted ||
            !palette.Muted ||
            !palette.DarkMuted
        ) {
            return null;
        }

        return {
            ...palette,
            average: averageColor,
        } as TAppThemeContext['dynamicColor'];
    };

    useLayoutEffect(() => {
        let isMounted = true;

        if (!shouldProcessDynamicColor || !thumbnailUrl) {
            setDynamicColor(null);
            return undefined;
        }

        const img = new Image();
        img.crossOrigin = 'anonymous';
        img.src = thumbnailUrl;

        img.onload = async () => {
            if (!isMounted) return;
            const colors = await processImageColors(img);
            if (isMounted && colors) {
                setDynamicColor(colors);
            }
        };

        return () => {
            isMounted = false;
            setDynamicColor(null);
        };
    }, [shouldProcessDynamicColor, thumbnailUrl, setDynamicColor]);

    if (!thumbnailUrl) return null;

    return (
        <>
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
                }}
            >
                <SpinnerImage
                    src={thumbnailUrl}
                    alt="Manga Thumbnail"
                    onLoad={() => setIsImageReady(true)}
                    imgStyle={{ width: '100%', height: '100%', objectFit: 'cover' }}
                />
                {isImageReady && isHovered && <ThumbnailOptionButton popupState={popupState} />}
            </Stack>
            <Menu {...bindMenu(popupState)}>
                <MenuItem
                    onClick={() => {
                        setIsModalOpen(true);
                        popupState.close();
                    }}
                >
                    Expand
                </MenuItem>
            </Menu>
            <Modal open={isModalOpen} onClose={() => setIsModalOpen(false)} sx={{ outline: 0 }}>
                <Stack
                    onClick={() => setIsModalOpen(false)}
                    sx={{ height: '100vh', p: 2, outline: 0, justifyContent: 'center', alignItems: 'center' }}
                >
                    <SpinnerImage
                        src={thumbnailUrl}
                        alt="Manga Thumbnail"
                        imgStyle={{ height: '100%', width: '100%', objectFit: 'contain' }}
                    />
                </Stack>
            </Modal>
        </>
    );
};
