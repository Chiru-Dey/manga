/*
 * Copyright (C) Contributors to the Suwayomi project
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import MoreVert from '@mui/icons-material/MoreVert';
import { IconButton, IconButtonProps } from '@mui/material';
import { PopupState } from 'material-ui-popup-state/hooks';
import { bindToggle } from 'material-ui-popup-state';
import { forwardRef } from 'react';

type Props = {
    popupState: PopupState;
    visible: boolean;
} & IconButtonProps;

export const ThumbnailOptionButton = forwardRef<HTMLButtonElement, Props>(
    ({ popupState, visible, ...props }, ref) => {
        return (
            <IconButton
                ref={ref}
                {...bindToggle(popupState)}
                {...props}
                sx={{
                    position: 'absolute',
                    top: (theme) => theme.spacing(0.5),
                    right: (theme) => theme.spacing(0.5),
                    color: 'white',
                    visibility: visible ? 'visible' : 'hidden',
                    pointerEvents: visible ? 'all' : 'none',
                    ...props.sx,
                }}
                className="manga-option-button"
            >
                <MoreVert />
            </IconButton>
        );
    },
);