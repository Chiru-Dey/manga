/*
 * Copyright (C) Contributors to the Suwayomi project
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import { useState, useLayoutEffect } from 'react';
import Stack from '@mui/material/Stack';
import MenuItem from '@mui/material/MenuItem';
import Modal from '@mui/material/Modal';
import PopupState from 'material-ui-popup-state';
import { bindHover, bindMenu } from 'material-ui-popup-state/hooks';
import { Vibrant } from 'node-vibrant/browser';
import { FastAverageColor } from 'fast-average-color';
import { Menu } from '@/modules/core/components/menu/Menu.tsx';
import { Mangas } from '@/modules/manga/services/Mangas.ts';
import { SpinnerImage } from '@/modules/core/components/SpinnerImage.tsx';
import { MANGA_COVER_ASPECT_RATIO } from '@/modules/manga/Manga.constants.ts';
import { MangaThumbnailInfo } from '@/modules/manga/Manga.types.ts';
import { TAppThemeContext, useAppThemeContext } from '@/modules/theme/contexts/AppThemeContext.tsx';

export const Thumbnail = ({
    manga,
    mangaDynamicColorSchemes,
}: {
    manga: Partial<MangaThumbnailInfo>;
    mangaDynamicColorSchemes: boolean;
}) => {
    const { setDynamicColor } = useAppThemeContext();
    const [isModalOpen, setIsModalOpen] = useState(false); // State for controlling the modal's open/close status

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
        <PopupState variant="popover" popupId="manga-thumbnail-menu">
            {(popupState) => (
                <>
                    {/* The modal component */}
                    <Modal
                        open={isModalOpen}
                        onClose={() => setIsModalOpen(false)}
                        sx={{ height: '100vh', p: 2, outline: 0, justifyContent: 'center', alignItems: 'center' }}
                    >
                        <SpinnerImage
                            src={Mangas.getThumbnailUrl(manga)}
                            alt="Manga Thumbnail"
                            imgStyle={{ height: '100%', width: '100%', objectFit: 'contain' }}
                        />
                    </Modal>

                    {/* Thumbnail Stack with Menu Trigger */}
                    <Stack
                        {...bindHover(popupState)} // Hover to open menu
                        onClick={() => setIsModalOpen(true)} // Click to open modal
                        sx={{
                            position: 'relative',
                            borderRadius: 1,
                            overflow: 'hidden',
                            backgroundColor: 'background.paper',
                            width: '150px',
                            maxHeight: 'fit-content',
                            aspectRatio: MANGA_COVER_ASPECT_RATIO,
                            cursor: 'pointer',
                        }}
                    >
                        <SpinnerImage
                            src={Mangas.getThumbnailUrl(manga)}
                            alt="Manga Thumbnail"
                            imgStyle={{ height: '100%', width: '100%', objectFit: 'contain' }}
                        />
                    </Stack>

                    {/* Menu Component */}
                    <Menu
                        {...bindMenu(popupState)}
                        disablePortal
                        anchorOrigin={{ horizontal: 'right', vertical: 'bottom' }}
                        transformOrigin={{ horizontal: 'right', vertical: 'top' }}
                    >
                        {(onClose) => (
                            <>
                                <MenuItem
                                    onClick={() => {
                                        setIsModalOpen(true); // Open the modal when "Expand" is clicked
                                        onClose(); // Close the menu
                                    }}
                                >
                                    Expand
                                </MenuItem>
                                <MenuItem
                                    onClick={() => {
                                        // TODO: Implement Change Thumbnail functionality
                                        onClose(); // Close the menu
                                    }}
                                >
                                    Change Thumbnail
                                </MenuItem>
                                <MenuItem
                                    onClick={() => {
                                        // TODO: Implement Reset Thumbnail functionality
                                        onClose(); // Close the menu
                                    }}
                                >
                                    Reset Thumbnail
                                </MenuItem>
                            </>
                        )}
                    </Menu>
                </>
            )}
        </PopupState>
    );
};
