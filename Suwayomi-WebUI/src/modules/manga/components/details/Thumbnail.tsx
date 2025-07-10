/*
 * Copyright (C) Contributors to the Suwayomi project
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import { useTheme } from '@mui/material/styles';
import { useLayoutEffect, useState, useMemo, useRef, MouseEvent } from 'react';
import {
    Stack,
    Modal,
    CardActionArea,
    Menu as MuiMenu,
    MenuItem as MuiMenuItem,
    ListItemIcon,
    ListItemText,
} from '@mui/material';
import OpenInFullIcon from '@mui/icons-material/OpenInFull';
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
    const optionButtonRef = useRef<HTMLButtonElement>(null);

    const [isModalOpen, setIsModalOpen] = useState(false);
    const [anchorEl, setAnchorEl] = useState<null | HTMLElement>(null);
    const isMenuOpen = Boolean(anchorEl);

    const thumbnailUrl = useMemo(() => {
        try {
            return Mangas.getThumbnailUrl(manga);
        } catch {
            return '';
        }
    }, [manga]);

    const handleMenuClick = (event: MouseEvent<HTMLElement>) => {
        event.preventDefault();
        event.stopPropagation();
        setAnchorEl(event.currentTarget);
    };

    const longPressEvent = useLongPress(
        () => {
            if (optionButtonRef.current) {
                handleMenuClick({
                    currentTarget: optionButtonRef.current,
                } as unknown as MouseEvent<HTMLElement>);
            }
        },
        { threshold: 600 },
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

    const handleMenuClose = () => {
        setAnchorEl(null);
    };

    const handleExpandClick = () => {
        setIsModalOpen(true);
        handleMenuClose();
    };

    if (!thumbnailUrl) return null;

    return (
        <>
            <Stack
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
                        '&:hover .manga-option-button': {
                            visibility: 'visible',
                            pointerEvents: 'all',
                        },
                        '&:hover .hover-overlay': {
                            opacity: 1,
                        },
                    },
                }}
            >
                <CardActionArea
                    {...longPressEvent}
                    onContextMenu={(e: MouseEvent<HTMLElement>) => {
                        e.preventDefault();
                    }}
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
                <ThumbnailOptionButton
                    ref={optionButtonRef}
                    onClick={handleMenuClick}
                    sx={{
                        visibility: isMenuOpen ? 'visible' : 'hidden',
                        pointerEvents: isMenuOpen ? 'all' : 'none',
                    }}
                />
                <MuiMenu anchorEl={anchorEl} open={isMenuOpen} onClose={handleMenuClose}>
                    <MuiMenuItem onClick={handleExpandClick}>
                        <ListItemIcon>
                            <OpenInFullIcon fontSize="small" />
                        </ListItemIcon>
                        <ListItemText>Expand</ListItemText>
                    </MuiMenuItem>
                </MuiMenu>
            </Stack>
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
