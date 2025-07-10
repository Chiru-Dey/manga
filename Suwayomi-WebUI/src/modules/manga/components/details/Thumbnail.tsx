/*
 * Copyright (C) Contributors to the Suwayomi project
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import { useTheme } from '@mui/material/styles';
import { useLayoutEffect, useState } from 'react';
import Stack from '@mui/material/Stack';
import Modal from '@mui/material/Modal';
import { bindMenu, bindTrigger, usePopupState } from 'material-ui-popup-state/hooks';
import Menu from '@mui/material/Menu';
import MenuItem from '@mui/material/MenuItem';
import { Vibrant } from 'node-vibrant/browser';
import { FastAverageColor } from 'fast-average-color';
import { useLongPress } from 'use-long-press';
import { Mangas } from '@/modules/manga/services/Mangas.ts';
import { SpinnerImage } from '@/modules/core/components/SpinnerImage.tsx';
import { MANGA_COVER_ASPECT_RATIO } from '@/modules/manga/Manga.constants.ts';
import { MangaIdInfo, MangaThumbnailInfo } from '@/modules/manga/Manga.types.ts';
import { TAppThemeContext, useAppThemeContext } from '@/modules/theme/contexts/AppThemeContext.tsx';
import { ThumbnailOptionButton } from '@/modules/manga/components/ThumbnailOptionButton.tsx';

export const Thumbnail = ({
    manga,
    mangaDynamicColorSchemes,
}: {
    manga: Partial<MangaThumbnailInfo & MangaIdInfo>;
    mangaDynamicColorSchemes: boolean;
}) => {
    const theme = useTheme();
    const { setDynamicColor } = useAppThemeContext();

    const popupState = usePopupState({ variant: 'popover', popupId: 'manga-thumbnail-options' });
    const [isModalOpen, setIsModalOpen] = useState(false);

    const [isImageReady, setIsImageReady] = useState(false);
    const [isHovered, setIsHovered] = useState(false);

    const longPressEvent = useLongPress(
        (event) => {
            popupState.open(event);
        },
        {
            threshold: 600,
        },
    );

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
                    src={Mangas.getThumbnailUrl(manga)}
                    alt="Manga Thumbnail"
                    onLoad={() => setIsImageReady(true)}
                    imgStyle={{ width: '100%', height: '100%', objectFit: 'cover' }}
                />
                {isImageReady && (
                    <Stack
                        sx={{
                            position: 'absolute',
                            top: 0,
                            bottom: 0,
                            width: '100%',
                            justifyContent: 'center',
                            alignItems: 'center',
                            opacity: 0,
                            '&:hover': {
                                background: 'rgba(0, 0, 0, 0.4)',
                                cursor: 'pointer',
                                opacity: 1,
                            },
                        }}
                    />
                )}
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
                        src={Mangas.getThumbnailUrl(manga)}
                        alt="Manga Thumbnail"
                        imgStyle={{ height: '100%', width: '100%', objectFit: 'contain' }}
                    />
                </Stack>
            </Modal>
        </>
    );
};
