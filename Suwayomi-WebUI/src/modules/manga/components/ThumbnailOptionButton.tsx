/*
 * Copyright (C) Contributors to the Suwayomi project
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import { forwardRef, ForwardedRef } from 'react';
import Button from '@mui/material/Button';
import MoreVertIcon from '@mui/icons-material/MoreVert';
import { useTranslation } from 'react-i18next';
import { PopupState, bindTrigger } from 'material-ui-popup-state/hooks';
import { CustomTooltip } from '@/modules/core/components/CustomTooltip.tsx';
import { MUIUtil } from '@/lib/mui/MUI.util.ts';

export interface ThumbnailOptionButtonProps {
    popupState: PopupState;
}

export const ThumbnailOptionButton = forwardRef(
    ({ popupState }: ThumbnailOptionButtonProps, ref: ForwardedRef<HTMLButtonElement>) => {
        const { t } = useTranslation();
        const bindTriggerProps = bindTrigger(popupState);

        const preventDefaultAction = (e: React.BaseSyntheticEvent) => {
            e.stopPropagation();
            e.preventDefault();
        };

        return (
            <CustomTooltip title={t('global.button.options')}>
                <Button
                    ref={ref}
                    {...MUIUtil.preventRippleProp(bindTriggerProps, { onClick: preventDefaultAction })}
                    className="manga-option-button"
                    size="small"
                    variant="contained"
                    sx={{
                        position: 'absolute',
                        right: 1,
                        top: 1,
                        zIndex: 1,
                        minWidth: 'unset',
                        paddingX: 0,
                        paddingY: '2.5px',
                        visibility: popupState.isOpen ? 'visible' : 'hidden',
                        pointerEvents: 'none',
                        '&:hover': {
                            backgroundColor: (theme) => theme.palette.primary.dark,
                        },
                        transition: (theme) => theme.transitions.create(
                            ['background-color', 'transform', 'visibility'],
                            { duration: 200 }
                        ),
                        '&:active': {
                            transform: 'scale(0.95)',
                        },
                        '@media not (pointer: fine)': {
                            visibility: 'hidden',
                            width: 0,
                            height: 0,
                            p: 0,
                            m: 0,
                        },
                    }}
                >
                    <MoreVertIcon fontSize="small" />
                </Button>
            </CustomTooltip>
        );
    }
);
