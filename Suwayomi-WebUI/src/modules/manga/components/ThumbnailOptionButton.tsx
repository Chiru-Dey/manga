/*
 * Copyright (C) Contributors to the Suwayomi project
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import IconButton from '@mui/material/IconButton';
import { usePopupState, bindTrigger } from 'material-ui-popup-state/hooks';
import MoreVertIcon from '@mui/icons-material/MoreVert';

export interface ThumbnailOptionButtonProps {
    popupState: ReturnType<typeof usePopupState>;
}

export const ThumbnailOptionButton = ({ popupState }: ThumbnailOptionButtonProps) => (
    <IconButton
        {...bindTrigger(popupState)}
        sx={{
            position: 'absolute',
            right: 8,
            top: 8,
            zIndex: 1,
            backgroundColor: 'rgba(0,0,0,0.6)',
            color: 'white',
            '&:hover': { backgroundColor: 'rgba(0,0,0,0.8)' },
        }}
    >
        <MoreVertIcon />
    </IconButton>
);
