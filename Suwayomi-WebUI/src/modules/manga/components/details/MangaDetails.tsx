/*
 * Copyright (C) Contributors to the Suwayomi project
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import FavoriteIcon from '@mui/icons-material/Favorite';
import FavoriteBorderIcon from '@mui/icons-material/FavoriteBorder';
import { styled } from '@mui/material/styles';
import { ComponentProps, ReactNode, useEffect, useState } from 'react';
import { useTranslation } from 'react-i18next';
import PopupState, { bindMenu } from 'material-ui-popup-state';
import { useLongPress } from 'use-long-press';
import { t as translate } from 'i18next';
import Link from '@mui/material/Link';
import Typography from '@mui/material/Typography';
import LaunchIcon from '@mui/icons-material/Launch';
import Stack from '@mui/material/Stack';
import IconButton from '@mui/material/IconButton';
import ContentCopyIcon from '@mui/icons-material/ContentCopy';
import { CustomTooltip } from '@/modules/core/components/CustomTooltip.tsx';
import { makeToast } from '@/modules/core/utils/Toast.ts';
import { Mangas } from '@/modules/manga/services/Mangas.ts';
import { SpinnerImage } from '@/modules/core/components/SpinnerImage.tsx';
import { CustomButton } from '@/modules/core/components/buttons/CustomButton.tsx';
import { TrackMangaButton } from '@/modules/manga/components/TrackMangaButton.tsx';
import { useManageMangaLibraryState } from '@/modules/manga/hooks/useManageMangaLibraryState.tsx';
import { Metadata as BaseMetadata } from '@/modules/core/components/texts/Metadata.tsx';
import { defaultPromiseErrorHandler } from '@/lib/DefaultPromiseErrorHandler.ts';
import { MangaType, SourceType } from '@/lib/graphql/generated/graphql.ts';
import { useMetadataServerSettings } from '@/modules/settings/services/ServerSettingsMetadata.ts';
import { MANGA_STATUS_TO_TRANSLATION } from '@/modules/manga/Manga.constants.ts';
import {
    MangaArtistInfo,
    MangaAuthorInfo,
    MangaDescriptionInfo,
    MangaGenreInfo,
    MangaIdInfo,
    MangaInLibraryInfo,
    MangaLocationState,
    MangaSourceIdInfo,
    MangaStatusInfo,
    MangaThumbnailInfo,
    MangaTitleInfo,
    MangaTrackRecordInfo,
} from '@/modules/manga/Manga.types.ts';
import { applyStyles } from '@/modules/core/utils/ApplyStyles.ts';
import { CustomButtonIcon } from '@/modules/core/components/buttons/CustomButtonIcon.tsx';
import { Sources } from '@/modules/source/services/Sources.ts';
import { SourceIdInfo } from '@/modules/source/Source.types.ts';
import { Thumbnail } from '@/modules/manga/components/details/Thumbnail.tsx';
import { DescriptionGenre } from '@/modules/manga/components/details/DescriptionGenre.tsx';
import { SearchLink } from '@/modules/manga/components/details/SearchLink.tsx';
import { Menu } from '@/modules/core/components/menu/Menu.tsx';
import {
    ListItemIcon,
    ListItemText,
    MenuItem as MuiMenuItem,
    Modal,
} from '@mui/material';
import OpenInFullIcon from '@mui/icons-material/OpenInFull';

const DetailsWrapper = styled('div')(({ theme }) => ({
    display: 'flex',
    flexDirection: 'column',
    gap: theme.spacing(2),
    padding: theme.spacing(1),
    [theme.breakpoints.up('md')]: {
        flexBasis: '40%',
        height: 'calc(100vh - 64px)',
        overflowY: 'auto',
    },
}));

const TopContentWrapper = ({
    url,
    mangaThumbnailBackdrop,
    children,
}: {
    url: string;
    mangaThumbnailBackdrop: boolean;
    children: ReactNode;
}) => (
    <Stack
        sx={{
            position: 'relative',
        }}
    >
        {mangaThumbnailBackdrop && (
            <>
                <SpinnerImage
                    spinnerStyle={{ display: 'none' }}
                    imgStyle={{
                        position: 'absolute',
                        top: 0,
                        left: 0,
                        width: '100%',
                        height: '100%',
                        objectFit: 'cover',
                    }}
                    src={url}
                    alt="Manga Thumbnail"
                />
                <Stack
                    sx={{
                        '&::before': (theme) =>
                            applyStyles(mangaThumbnailBackdrop, {
                                position: 'absolute',
                                display: 'inline-block',
                                content: '""',
                                top: 0,
                                left: 0,
                                width: '100%',
                                height: '100%',
                                background: `linear-gradient(to top, ${theme.palette.background.default}, transparent 100%, transparent 1px),linear-gradient(to right, ${theme.palette.background.default}, transparent 50%, transparent 1px),linear-gradient(to bottom, ${theme.palette.background.default}, transparent 50%, transparent 1px),linear-gradient(to left, ${theme.palette.background.default}, transparent 50%, transparent 1px)`,
                                backdropFilter: 'blur(4.5px) brightness(0.75)',
                            }),
                    }}
                />
            </>
        )}
        {children}
    </Stack>
);

const ThumbnailMetadataWrapper = styled('div')(({ theme }) => ({
    display: 'flex',
    paddingBottom: theme.spacing(1),
}));

const MetadataContainer = styled('div')(({ theme }) => ({
    zIndex: 1,
    marginLeft: theme.spacing(1),
}));

const Metadata = (props: ComponentProps<typeof BaseMetadata>) => <BaseMetadata {...props} />;

const MangaButtonsContainer = styled('div')(({ theme }) => ({
    display: 'flex',
    gap: theme.spacing(1),
}));

const OpenSourceButton = ({ url }: { url?: string | null }) => {
    const { t } = useTranslation();

    return (
        <CustomTooltip title={t('global.button.open_site')} disabled={!url}>
            <CustomButtonIcon
                size="medium"
                disabled={!url}
                component={Link}
                href={url ?? undefined}
                target="_blank"
                rel="noreferrer"
                variant="outlined"
            >
                <LaunchIcon />
            </CustomButtonIcon>
        </CustomTooltip>
    );
};

function getSourceName(source?: Pick<SourceType, 'id' | 'displayName'> | null): string {
    if (!source) {
        return translate('global.label.unknown');
    }

    if (Sources.isLocalSource(source)) {
        return translate('source.local_source.title');
    }

    return source.displayName ?? source.id;
}

const valuesToJoinedSearchLinks = (
    values: string[] | undefined,
    sourceId: SourceIdInfo['id'] | undefined,
    mode: MangaLocationState['mode'],
) =>
    values
        ?.map((value) => <SearchLink key={value} query={value} sourceId={sourceId} mode={mode} />)
        .reduce((acc, valueLink) => (
            <>
                {acc}, {valueLink}
            </>
        ));

export const MangaDetails = ({
    manga,
    mode,
}: {
    manga: Pick<MangaType, 'realUrl'> &
        MangaIdInfo &
        MangaTitleInfo &
        MangaStatusInfo &
        MangaInLibraryInfo &
        MangaAuthorInfo &
        MangaArtistInfo &
        MangaDescriptionInfo &
        MangaGenreInfo &
        MangaThumbnailInfo &
        MangaSourceIdInfo &
        MangaTrackRecordInfo & {
            source?: Pick<SourceType, 'id' | 'displayName'> | null;
        };
    mode: MangaLocationState['mode'];
}) => {
    const { t } = useTranslation();

    const {
        settings: { mangaThumbnailBackdrop, mangaDynamicColorSchemes },
    } = useMetadataServerSettings();

    const [isModalOpen, setIsModalOpen] = useState(false);

    const longPressEvent = useLongPress(null);

    useEffect(() => {
        if (!manga.source) {
            makeToast(translate('source.error.label.source_not_found'), 'error');
        }
    }, [manga.source]);

    const { CategorySelectComponent, updateLibraryState } = useManageMangaLibraryState(manga);

    const copyTitle = async () => {
        try {
            await navigator.clipboard.writeText(manga.title);
            makeToast(t('global.label.copied_clipboard'), 'info');
        } catch (e) {
            defaultPromiseErrorHandler('MangaDetails::copyTitleLongPress')(e);
        }
    };

    return (
        <>
            <DetailsWrapper>
                <TopContentWrapper url={Mangas.getThumbnailUrl(manga)} mangaThumbnailBackdrop={mangaThumbnailBackdrop}>
                    <PopupState variant="popover" popupId="thumbnail-action-menu">
                        {(popupState) => (
                            <>
                                <ThumbnailMetadataWrapper>
                                    <Thumbnail
                                        manga={manga}
                                        mangaDynamicColorSchemes={mangaDynamicColorSchemes}
                                        popupState={popupState}
                                       longPressEvent={longPressEvent}
                                    />
                                    <MetadataContainer>
                                        <Stack sx={{ flexDirection: 'row', gap: 1, alignItems: 'flex-start', mb: 1 }}>
                                            <SearchLink
                                                query={manga.title}
                                                sourceId={manga.sourceId}
                                                mode="source.global-search"
                                            >
                                                <Typography variant="h5" component="h2" sx={{ wordBreak: 'break-word' }}>
                                                    {manga.title}
                                                </Typography>
                                            </SearchLink>
                                            <CustomTooltip title={t('global.button.copy')}>
                                                <IconButton onClick={copyTitle} color="inherit">
                                                    <ContentCopyIcon fontSize="small" />
                                                </IconButton>
                                            </CustomTooltip>
                                        </Stack>
                                                    {manga.author && (
                                                        <Metadata
                                                            title={t('manga.label.author')}
                                                            value={valuesToJoinedSearchLinks(
                                                                Mangas.getAuthors(manga),
                                                                manga.source?.id,
                                                                mode,
                                                            )}
                                                        />
                                                    )}
                                                    {manga.artist && (
                                                        <Metadata
                                                            title={t('manga.label.artist')}
                                                            value={valuesToJoinedSearchLinks(
                                                                Mangas.getArtists(manga),
                                                                manga.source?.id,
                                                                mode,
                                                            )}
                                                        />
                                                    )}
                                                    <Metadata
                                                        title={t('manga.label.status')}
                                                        value={t(MANGA_STATUS_TO_TRANSLATION[manga.status])}
                                                    />
                                                    <Metadata title={t('source.title_one')} value={getSourceName(manga.source)} />
                                                </MetadataContainer>
                                            </ThumbnailMetadataWrapper>
                                            <Menu {...bindMenu(popupState)}>
                                                {() => (
                                                    <MuiMenuItem
                                                        onClick={() => {
                                                            popupState.close();
                                                            setIsModalOpen(true);
                                                        }}
                                                    >
                                                        <ListItemIcon>
                                                            <OpenInFullIcon fontSize="small" />
                                                        </ListItemIcon>
                                                        <ListItemText>Expand</ListItemText>
                                                    </MuiMenuItem>
                                                )}
                                            </Menu>
                                        </>
                                    )}
                                </PopupState>
                            </TopContentWrapper>
                            <MangaButtonsContainer>
                                <CustomButton
                                    size="medium"
                                    onClick={updateLibraryState}
                            variant={manga.inLibrary ? 'contained' : 'outlined'}
                        >
                            {manga.inLibrary ? <FavoriteIcon /> : <FavoriteBorderIcon />}
                            {manga.inLibrary ? t('manga.button.in_library') : t('manga.button.add_to_library')}
                        </CustomButton>
                        <TrackMangaButton manga={manga} />
                        <OpenSourceButton url={manga.realUrl} />
                    </MangaButtonsContainer>
                <DescriptionGenre manga={manga} mode={mode} />
            </DetailsWrapper>
            {CategorySelectComponent}
            <Modal open={isModalOpen} onClose={() => setIsModalOpen(false)} sx={{ outline: 0 }}>
                <Stack
                    onClick={() => setIsModalOpen(false)}
                    sx={{ height: '100vh', p: 2, outline: 0, justifyContent: 'center', alignItems: 'center' }}
                >
                    <SpinnerImage
                        src={Mangas.getThumbnailUrl(manga)}
                        alt="Manga Thumbnail"
                        imgStyle={{ height: '100%', width: '100%', objectFit: 'contain' }}
                    />
                </Stack>
            </Modal>
        </>
    );
};
