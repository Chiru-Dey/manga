/*
 * Copyright (C) Contributors to the Suwayomi project
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import MoreVert from '@mui/icons-material/MoreVert';
import { Button, ButtonProps } from '@mui/material';
import { forwardRef } from 'react';

type Props = ButtonProps;

export const ThumbnailOptionButton = forwardRef<HTMLButtonElement, Props>(
    (props, ref) => {
        return (
            <Button
                ref={ref}
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