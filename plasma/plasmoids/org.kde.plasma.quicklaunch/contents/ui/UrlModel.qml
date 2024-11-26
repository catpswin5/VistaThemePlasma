/*
 *  SPDX-FileCopyrightText: 2015 David Rosca <nowrep@gmail.com>
 *
 *  SPDX-License-Identifier: GPL-2.0-only OR GPL-3.0-only OR LicenseRef-KDE-Accepted-GPL
 */

import QtQuick 2.2

ListModel {
    id: listModel

    property int dropMarkerIndex : -1

    signal urlsChanged()

    function urls()
    {
        var out = [];
        for (var i = 0; i < listModel.count; ++i) {
            out.push(get(i).url);
        }
        return out;
    }

    function setUrls(urls)
    {
        clear();
        insertUrls(0, urls);

        urlsChanged();
    }

    function appendUrl(url)
    {
        append({ url: url });

        urlsChanged();
    }

    function insertUrl(index, url)
    {
        insert(index, { url: url });

        urlsChanged();
    }

    function insertUrls(index, urls)
    {
        for (var i = 0; i < urls.length; ++i) {
            insert(index + i, { url: urls[i] });
        }

        if (urls.length) {
            urlsChanged();
        }
    }

    function changeUrl(index, url)
    {
        // Force reloading delegate data
        set(index, { url: "quicklaunch:empty" });
        set(index, { url: url });

        urlsChanged();
    }

    function moveUrl(from, to)
    {
        if (from == -1 || to == -1 || from == to) {
            return false;
        }

        move(from, to, 1);

        urlsChanged();
        return true;
    }

    function removeUrl(index)
    {
        remove(index, 1);

        urlsChanged();
    }

    // Drop marker is internally represented as "quicklaunch:drop" url
    function showDropMarker(index)
    {
        if (index == -1) {
            index = dropMarkerIndex == -1 ? count : count - 1;
        }

        if (dropMarkerIndex != -1) {
            move(dropMarkerIndex, index, 1);
            dropMarkerIndex = index;
        } else {
            insert(index, { url: "quicklaunch:drop" });
            dropMarkerIndex = index;
        }
    }

    function clearDropMarker()
    {
        if (dropMarkerIndex != -1) {
            remove(dropMarkerIndex, 1);
            dropMarkerIndex = -1;
        }
    }
}
