package suwayomi.tachidesk.manga.model.table

/*
 * Copyright (C) Contributors to the Suwayomi project
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/. */

import eu.kanade.tachiyomi.source.model.SManga
import eu.kanade.tachiyomi.source.model.UpdateStrategy
import org.jetbrains.exposed.dao.id.IntIdTable
import org.jetbrains.exposed.sql.ResultRow
import suwayomi.tachidesk.manga.impl.Manga.getMangaMetaMap
import suwayomi.tachidesk.manga.impl.MangaList.proxyThumbnailUrl
import suwayomi.tachidesk.manga.model.dataclass.MangaDataClass
import suwayomi.tachidesk.manga.model.dataclass.toGenreList
import suwayomi.tachidesk.manga.model.table.MangaStatus.Companion
import suwayomi.tachidesk.manga.model.table.columns.truncatingVarchar

object MangaTable : IntIdTable() {
    val url = varchar("url", 4096)
    val title = truncatingVarchar("title", 512)
    val initialized = bool("initialized").default(false)

    val artist = truncatingVarchar("artist", Integer.MAX_VALUE).nullable()
    val author = truncatingVarchar("author", Integer.MAX_VALUE).nullable()
    val description = truncatingVarchar("description", Integer.MAX_VALUE).nullable()
    val genre = truncatingVarchar("genre", Integer.MAX_VALUE).nullable()

    val status = integer("status").default(SManga.UNKNOWN)
    val thumbnail_url = varchar("thumbnail_url", 4096).nullable()
    val thumbnailUrlLastFetched = long("thumbnail_url_last_fetched").default(0)

    val inLibrary = bool("in_library").default(false)
    val inLibraryAt = long("in_library_at").default(0)

    // the [source] field name is used by some ancestor of IntIdTable
    val sourceReference = long("source")

    /** the real url of a manga used for the "open in WebView" feature */
    val realUrl = varchar("real_url", 4096).nullable()

    val lastFetchedAt = long("last_fetched_at").default(0)
    val chaptersLastFetchedAt = long("chapters_last_fetched_at").default(0)

    val updateStrategy = varchar("update_strategy", 256).default(UpdateStrategy.ALWAYS_UPDATE.name)
}

fun MangaTable.toDataClass(
    mangaEntry: ResultRow,
    includeMangaMeta: Boolean = true,
) = MangaDataClass(
    id = mangaEntry[this.id].value,
    sourceId = mangaEntry[sourceReference].toString(),
    url = mangaEntry[url],
    title = mangaEntry[title],
    thumbnailUrl = proxyThumbnailUrl(mangaEntry[this.id].value),
    thumbnailUrlLastFetched = mangaEntry[thumbnailUrlLastFetched],
    initialized = mangaEntry[initialized],
    artist = mangaEntry[artist],
    author = mangaEntry[author],
    description = mangaEntry[description],
    genre = mangaEntry[genre].toGenreList(),
    status = Companion.valueOf(mangaEntry[status]).name,
    inLibrary = mangaEntry[inLibrary],
    inLibraryAt = mangaEntry[inLibraryAt],
    meta =
        if (includeMangaMeta) {
            getMangaMetaMap(mangaEntry[id].value)
        } else {
            emptyMap()
        },
    realUrl = mangaEntry[realUrl],
    lastFetchedAt = mangaEntry[lastFetchedAt],
    chaptersLastFetchedAt = mangaEntry[chaptersLastFetchedAt],
    updateStrategy = UpdateStrategy.valueOf(mangaEntry[updateStrategy]),
)

enum class MangaStatus(
    val value: Int,
) {
    UNKNOWN(0),
    ONGOING(1),
    COMPLETED(2),
    LICENSED(3),
    PUBLISHING_FINISHED(4),
    CANCELLED(5),
    ON_HIATUS(6),
    ;

    companion object {
        fun valueOf(value: Int): MangaStatus = entries.find { it.value == value } ?: UNKNOWN
    }
}
