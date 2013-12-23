/*
 * Copyright (c) 2012-2013 Dickson Leong.
 * All rights reserved.
 *
 * This file is part of GagBook.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *
 *     * Redistributions of source code must retain the above copyright
 *       notice, this list of conditions and the following disclaimer.
 *     * Redistributions in binary form must reproduce the above copyright
 *       notice, this list of conditions and the following disclaimer in the
 *       documentation and/or other materials provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
 * ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 * WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR
 * ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
 * LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
 * ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 * SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#include "gagmodel.h"

#include <QtCore/QUrl>

#include "gagbookmanager.h"
#include "appsettings.h"
#include "networkmanager.h"
#include "ninegagrequest.h"
#include "infinigagrequest.h"
#include "gagimagedownloader.h"

GagModel::GagModel(QObject *parent) :
    QAbstractListModel(parent), m_busy(false), m_progress(0), m_manager(0), m_section(HotSection),
    m_request(0), m_imageDownloader(0), m_manualImageDownloader(0), m_downloadingIndex(-1)
{
    QHash<int, QByteArray> roles;
    roles[TitleRole] = "title";
    roles[UrlRole] = "url";
    roles[ImageUrlRole] = "imageUrl";
    roles[ImageHeightRole] = "imageHeight";
    roles[VotesCountRole] = "votesCount";
    roles[CommentsCountRole] = "commentsCount";
    roles[IsVideoRole] = "isVideo";
    roles[IsNSFWRole] = "isNSFW";
    roles[IsGIFRole] = "isGIF";
    roles[IsDownloadingRole] = "isDownloading";
    setRoleNames(roles);
}

void GagModel::classBegin()
{
}

void GagModel::componentComplete()
{
    refresh(RefreshAll);
}

int GagModel::rowCount(const QModelIndex &parent) const
{
    Q_UNUSED(parent)
    return m_gagList.count();
}

QVariant GagModel::data(const QModelIndex &index, int role) const
{
    Q_ASSERT(index.row() < m_gagList.count());

    const GagObject &gag = m_gagList.at(index.row());

    switch (role) {
    case TitleRole:
        return gag.title();
    case UrlRole:
        return gag.url();
    case ImageUrlRole:
        // should use QUrl::isLocalFile() but it is introduced in Qt 4.8
        if (gag.imageUrl().scheme() != "file")
            return QUrl();
        return gag.imageUrl();
    case ImageHeightRole:
        return gag.imageHeight();
    case VotesCountRole:
        return gag.votesCount();
    case CommentsCountRole:
        return gag.commentsCount();
    case IsVideoRole:
        return gag.isVideo();
    case IsNSFWRole:
        return gag.isNSFW();
    case IsGIFRole:
        return gag.isGIF();
    case IsDownloadingRole:
        return index.row() == m_downloadingIndex;
    default:
        qWarning("GagModel::data(): Invalid role");
        return QVariant();
    }
}

bool GagModel::isBusy() const
{
    return m_busy;
}

qreal GagModel::progress() const
{
    return m_progress;
}

GagBookManager *GagModel::manager() const
{
    return m_manager;
}

void GagModel::setManager(GagBookManager *manager)
{
    m_manager = manager;
}

GagModel::Section GagModel::section() const
{
    return m_section;
}

void GagModel::setSection(GagModel::Section section)
{
    if (m_section != section) {
        m_section = section;
        emit sectionChanged();
    }
}

void GagModel::refresh(RefreshType refreshType)
{
    if (m_request != 0) {
        m_request->disconnect();
        m_request->deleteLater();
        m_request = 0;
    }

    if (m_imageDownloader != 0) {
        m_imageDownloader->disconnect();
        m_imageDownloader->deleteLater();
        m_imageDownloader = 0;
    }

    switch (m_manager->settings()->source()) {
    default:
        qWarning("GagModel::refresh(): Invalid source, default source will be used");
        // fallthrough
    case AppSettings::NineGagSource:
        m_request = new NineGagRequest(manager()->networkManager(), m_section, this);
        break;
    case AppSettings::InfiniGagSource:
        m_request = new InfiniGagRequest(manager()->networkManager(), m_section, this);
        break;
    }

    if (!m_gagList.isEmpty()) {
        if (refreshType == RefreshAll) {
            beginRemoveRows(QModelIndex(), 0, m_gagList.count() - 1);
            m_gagList.clear();
            endRemoveRows();
        } else {
            m_request->setLastId(m_gagList.last().id());
        }
    }
    connect(m_request, SIGNAL(success(QList<GagObject>)), this, SLOT(onSuccess(QList<GagObject>)));
    connect(m_request, SIGNAL(failure(QString)), this, SLOT(onFailure(QString)));

    m_request->send();

    m_busy = true;
    emit busyChanged();

    if (m_progress != 0) {
        m_progress = 0;
        emit progressChanged();
    }
}

void GagModel::stopRefresh()
{
    if (m_request != 0) {
        m_request->disconnect();
        m_request->deleteLater();
        m_request = 0;
    }
    if (m_imageDownloader != 0)
        m_imageDownloader->stop();

    if (m_busy != false) {
        m_busy = false;
        emit busyChanged();
    }
}

void GagModel::downloadImage(int i)
{
    if (m_manualImageDownloader != 0) {
        m_manualImageDownloader->disconnect();
        m_manualImageDownloader->deleteLater();
        m_manualImageDownloader = 0;

        if (m_downloadingIndex != -1) {
            QModelIndex modelIndex = index(m_downloadingIndex);
            m_downloadingIndex = -1;
            emit dataChanged(modelIndex, modelIndex);
        }
    }

    QList<GagObject> gags;
    gags.append(m_gagList.at(i));

    m_manualImageDownloader = new GagImageDownloader(manager()->networkManager(), this);
    connect(m_manualImageDownloader, SIGNAL(finished(QList<GagObject>)),
            SLOT(onManualDownloadFinished(QList<GagObject>)));
    m_manualImageDownloader->start(gags, true);

    m_downloadingIndex = i;
    emit dataChanged(index(i), index(i));
}

void GagModel::onSuccess(const QList<GagObject> &gagList)
{
    bool downloadGIF;
    switch (m_manager->settings()->gifDownloadMode()) {
    case AppSettings::GifDownloadOn:
        downloadGIF = true;
        break;
    case AppSettings::GifDownloadOnWiFiOnly:
        if (m_manager->networkManager()->isMobileData())
            downloadGIF = false;
        else
            downloadGIF = true;
        break;
    case AppSettings::GifDownloadOff:
        downloadGIF = false;
        break;
    default:
        qWarning("GagModel::onSuccess(): Invalid gifDownloadMode, default mode will be used");
        downloadGIF = true;
        break;
    }

    m_imageDownloader = new GagImageDownloader(manager()->networkManager(), this);
    connect(m_imageDownloader, SIGNAL(finished(QList<GagObject>)), SLOT(onDownloadFinished(QList<GagObject>)));
    connect(m_imageDownloader, SIGNAL(downloadProgress(int,int)), SLOT(onImageDownloadProgress(int,int)));
    m_imageDownloader->start(gagList, downloadGIF);

    m_request->deleteLater();
    m_request = 0;
}

void GagModel::onFailure(const QString &errorMessage)
{
    emit refreshFailure(errorMessage);
    m_request->deleteLater();
    m_request = 0;
    m_busy = false;
    emit busyChanged();
}

void GagModel::onImageDownloadProgress(int imagesDownloaded, int imagesTotal)
{
    qreal progress;
    if (imagesTotal > 0)
        progress = qreal(imagesDownloaded) / qreal(imagesTotal);
    else
        progress = 1;

    if (m_progress != progress) {
        m_progress = progress;
        emit progressChanged();
    }
}

void GagModel::onDownloadFinished(const QList<GagObject> &gagList)
{
    beginInsertRows(QModelIndex(), m_gagList.count(), m_gagList.count() + gagList.count() - 1);
    m_gagList.reserve(m_gagList.count() + gagList.count());
    m_gagList.append(gagList);
    endInsertRows();

    m_imageDownloader->deleteLater();
    m_imageDownloader = 0;
    m_busy = false;
    emit busyChanged();
}

void GagModel::onManualDownloadFinished(const QList<GagObject> &gagList)
{
    Q_UNUSED(gagList);

    m_manualImageDownloader->deleteLater();
    m_manualImageDownloader = 0;

    QModelIndex modelIndex = index(m_downloadingIndex);
    m_downloadingIndex = -1;
    emit dataChanged(modelIndex, modelIndex);
}
