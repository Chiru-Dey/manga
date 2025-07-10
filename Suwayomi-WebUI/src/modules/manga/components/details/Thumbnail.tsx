/*
 * Copyright (C) Contributors to the Suwayomi project
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import { useTheme } from '@mui/material/styles';
import { useLayoutEffect, useState, useMemo, useRef } from 'react';
import { Stack, Modal, CardActionArea } from '@mui/material';
import OpenInFullIcon from '@mui/icons-material/OpenInFull';
import PopupState, { bindMenu } from 'material-ui-popup-state';
import { Vibrant } from 'node-vibrant/browser';
import { FastAverageColor } from 'fast-average-color';
import { useLongPress } from 'use-long-press';

import { Mangas } from '@/modules/manga/services/Mangas.ts';
import { SpinnerImage } from '@/modules/core/components/SpinnerImage.tsx';
import { MANGA_COVER_ASPECT_RATIO } from '@/modules/manga/Manga.constants.ts';
import { MangaIdInfo, MangaThumbnailInfo } from '@/modules/manga/Manga.types.ts';
import { TAppThemeContext, useAppThemeContext } from '@/modules/theme/contexts/AppThemeContext.tsx';
import { ThumbnailOptionButton } from '@/modules/manga/components/ThumbnailOptionButton.tsx';
import { Menu } from '@/modules/core/components/menu/Menu.tsx';
import { MenuItem } from '@/modules/core/components/menu/MenuItem.tsx';

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

    const [isImageReady, setIsImageReady] = useState(false);
    const [isModalOpen, setIsModalOpen] = useState(false);

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
        <>
            <PopupState variant="popover" popupId="manga-thumbnail-options">
                {(popupState) => {
                    const longPressEvent = useLongPress(
                        () => {
                            popupState.open(optionButtonRef.current);
                        },
                        { threshold: 600 },
                    );

                    return (
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
                                onContextMenu={(e) => e.preventDefault()}
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
                                    onLoad={() => setIsImageReady(true)}
                                    imgStyle={{ width: '100%', height: '100%', objectFit: 'cover', display: 'block' }}
                                />
                            </CardActionArea>
                            <ThumbnailOptionButton
                                ref={optionButtonRef}
                                popupState={popupState}
                                sx={{
                                    visibility: popupState.isOpen || !isImageReady ? 'hidden' : 'visible',
                                    pointerEvents: popupState.isOpen || !isImageReady ? 'none' : 'all',
                                }}
                                onClick={(e) => {
                                    e.preventDefault();
                                    e.stopPropagation();
                                }}
                            />
                            <Menu {...bindMenu(popupState)}>
                                {(onClose) => (
                                    <MenuItem
                                        onClick={() => {
                                            setIsModalOpen(true);
                                            onClose();
                                        }}
                                        Icon={OpenInFullIcon}
                                        title="Expand"
                                    />
                                )}
                            </Menu>
                        </Stack>
                    );
                }}
            </PopupState>
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
