/*
 * Copyright (C) Contributors to the Suwayomi project
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import MoreVert from '@mui/icons-material/MoreVert';
import { Button, ButtonProps } from '@mui/material';
import { PopupState } from 'material-ui-popup-state/hooks';
import { bindToggle } from 'material-ui-popup-state';
import { forwardRef } from 'react';

type Props = {
    popupState: PopupState;
} & ButtonProps;

export const ThumbnailOptionButton = forwardRef<HTMLButtonElement, Props>(
    ({ popupState, ...props }, ref) => {
        return (
            <Button
                ref={ref}
                {...bindToggle(popupState)}
                {...props}
                variant="contained"
                sx={{
                    position: 'absolute',
                    top: (theme) => theme.spacing(0.5),
                    right: (theme) => theme.spacing(0.5),
                    visibility: 'hidden',
                    pointerEvents: 'none',
                    minWidth: 'unset',
                    paddingX: '0',
                    paddingY: '2.5px',
                    ...props.sx,
                }}
                className="manga-option-button"
            >
                <MoreVert />
            </Button>
        );
    },
);