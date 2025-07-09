/*
 * Copyright (C) Contributors to the Suwayomi project
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import IconButton from '@mui/material/IconButton';
import Menu from '@mui/material/Menu';
import MenuItem from '@mui/material/MenuItem';
import { usePopupState, bindTrigger, bindMenu } from 'material-ui-popup-state/hooks';
import MoreVertIcon from '@mui/icons-material/MoreVert';
import { MangaIdInfo, MangaThumbnailInfo } from '@/modules/manga/Manga.types.ts';

export interface ThumbnailOptionButtonProps {
    popupState: ReturnType<typeof usePopupState>;
    manga: Partial<MangaThumbnailInfo & MangaIdInfo>;
}

export const ThumbnailOptionButton = ({ popupState, manga }: ThumbnailOptionButtonProps) => {
    const menuPopupState = usePopupState({ variant: 'popover', popupId: `thumbnail-context-menu-${manga.id}` });

    return (
        <>
            <IconButton
                {...bindTrigger(menuPopupState)}
                sx={{
                    position: 'absolute',
                    right: 8,
                    bottom: 8,
                    zIndex: 1,
                    backgroundColor: 'rgba(0,0,0,0.5)',
                    color: 'white',
                    '&:hover': { backgroundColor: 'rgba(0,0,0,0.7)' },
                }}
            >
                <MoreVertIcon />
            </IconButton>
            <Menu {...bindMenu(menuPopupState)}>
                <MenuItem
                    onClick={() => {
                        menuPopupState.close();
                        popupState.open();
                    }}
                >
                    Expand
                </MenuItem>
            </Menu>
        </>
    );
};
