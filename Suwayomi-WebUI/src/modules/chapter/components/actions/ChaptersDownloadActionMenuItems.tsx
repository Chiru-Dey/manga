/*
 * Copyright (C) Contributors to the Suwayomi project
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import MenuItem from '@mui/material/MenuItem';
import { useTranslation } from 'react-i18next';
import gql from 'graphql-tag';
import { useMetadataServerSettings } from '@/modules/settings/services/ServerSettingsMetadata.ts';
import { Mangas } from '@/modules/manga/services/Mangas.ts';
import { defaultPromiseErrorHandler } from '@/lib/DefaultPromiseErrorHandler.ts';
import {
    ChapterOrderBy,
    GetChaptersMangaQuery,
    GetChaptersMangaQueryVariables,
    MangaType,
    SortOrder,
} from '@/lib/graphql/generated/graphql.ts';
import { TranslationKey } from '@/Base.types.ts';
import { MANGA_META_FIELDS } from '@/lib/graphql/fragments/MangaFragments.ts';
import { getMangaMetadata } from '@/modules/manga/services/MangaMetadata.ts';
import { requestManager } from '@/lib/requests/RequestManager.ts';
import { GET_CHAPTERS_MANGA } from '@/lib/graphql/queries/ChapterQuery.ts';
import { filterChapters } from '@/modules/chapter/utils/ChapterList.util.tsx';
import { Chapters } from '@/modules/chapter/services/Chapters.ts';
import { makeToast } from '@/modules/core/utils/Toast.ts';
import { CHAPTER_ACTION_TO_TRANSLATION } from '@/modules/chapter/Chapter.constants.ts';
import { getErrorMessage } from '@/lib/HelperFunctions.ts';

const DOWNLOAD_OPTIONS: {
    title: TranslationKey;
    getCount: (downloadAheadLimit: number) => number | undefined;
    onlyUnread?: boolean;
}[] = [
    { title: 'chapter.action.download.add.label.next', getCount: () => 1 },
    { title: 'chapter.action.download.add.label.next', getCount: () => 5 },
    { title: 'chapter.action.download.add.label.next', getCount: () => 10 },
    { title: 'chapter.action.download.add.label.next', getCount: () => 25 },
    {
        title: 'chapter.action.download.add.label.ahead',
        getCount: (downloadAheadLimit) => downloadAheadLimit,
        onlyUnread: true,
    },
    { title: 'chapter.action.download.add.label.unread', getCount: () => undefined, onlyUnread: true },
    { title: 'chapter.action.download.add.label.all', getCount: () => undefined, onlyUnread: false },
];

const handleDownload = async (
    mangaIds: MangaType['id'][],
    onlyUnread: boolean,
    size: number | undefined,
    downloadAhead: boolean,
): Promise<void> => {
    const isMultiMangaManga = mangaIds.length > 1;
    if (isMultiMangaManga) {
        Mangas.performAction('download', mangaIds, {
            downloadAhead,
            onlyUnread,
            size,
        }).catch(defaultPromiseErrorHandler('ChaptersDownloadActionMenuItems::handleSelect:multiMangaMode'));
        return;
    }

    const mangaId = mangaIds[0];
    const manga = Mangas.getFromCache(
        mangaId,
        gql`
            ${MANGA_META_FIELDS}
            fragment MangaInLibraryState on MangaType {
                id
                meta {
                    ...MANGA_META_FIELDS
                }
            }
        `,
        'MangaInLibraryState',
    )!;
    const meta = getMangaMetadata(manga);
    const chapters = await requestManager.getChapters<GetChaptersMangaQuery, GetChaptersMangaQueryVariables>(
        GET_CHAPTERS_MANGA,
        {
            condition: { mangaId: Number(mangaId) },
            order: [{ by: ChapterOrderBy.SourceOrder, byType: SortOrder.Desc }],
        },
    ).response;

    const filteredChapters = filterChapters(chapters.data.chapters.nodes, meta);
    const chaptersToDownload = filteredChapters
        .filter((chapter) => {
            if (onlyUnread && chapter.isRead) {
                return false;
            }

            return !chapter.isDownloaded;
        })
        .slice(0, size);

    if (!chaptersToDownload.length) {
        return;
    }

    Chapters.performAction('download', Chapters.getIds(chaptersToDownload), {}).catch(
        defaultPromiseErrorHandler('ChaptersDownloadActionMenuItems::handleSelect::singleMangaMode'),
    );
};

export const ChaptersDownloadActionMenuItems = ({
    mangaIds,
    closeMenu,
}: {
    mangaIds: MangaType['id'][];
    closeMenu: () => void;
}) => {
    const { t } = useTranslation();

    const {
        settings: { downloadAheadLimit },
    } = useMetadataServerSettings();

    const handleSelect = (size?: number, onlyUnread: boolean = true, downloadAhead: boolean = false) => {
        handleDownload(mangaIds, onlyUnread, size, downloadAhead).catch((e) =>
            makeToast(
                t(CHAPTER_ACTION_TO_TRANSLATION.download.error, {
                    count: size,
                }),
                'error',
                getErrorMessage(e),
            ),
        );

        closeMenu?.();
    };

    return (
        <>
            {DOWNLOAD_OPTIONS.map(({ title, getCount, onlyUnread }) => (
                <MenuItem
                    key={t(title, { count: getCount(downloadAheadLimit) })}
                    onClick={() => handleSelect(getCount(downloadAheadLimit), onlyUnread)}
                >
                    {t(title, { count: getCount(downloadAheadLimit) })}
                </MenuItem>
            ))}
        </>
    );
};
