/*
 * Copyright (C) Contributors to the Suwayomi project
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import IconButton from '@mui/material/IconButton';
import { usePopupState, bindTrigger, bindMenu } from 'material-ui-popup-state/hooks';
import MoreVertIcon from '@mui/icons-material/MoreVert';
import { useTheme } from '@mui/material/styles';

export interface ThumbnailOptionButtonProps {
    popupState: ReturnType<typeof usePopupState>;
}

export const ThumbnailOptionButton = ({ popupState }: ThumbnailOptionButtonProps) => {
    const theme = useTheme();

    return (
        <IconButton
            {...bindTrigger(popupState)}
            {...bindMenu(popupState)}
            sx={{
                position: 'absolute',
                right: 8,
                top: 8,
                zIndex: 1,
                width: 24,
                height: 48,
                borderRadius: 2,
                backgroundColor: theme.palette.background.paper,
                color: theme.palette.text.primary,
                '&:hover': { backgroundColor: theme.palette.action.hover },
            }}
        >
            <MoreVertIcon />
        </IconButton>
    );
};
