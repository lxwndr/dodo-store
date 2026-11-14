// SPDX-FileCopyrightText: 2026 dodo-store authors
//
// SPDX-License-Identifier: LGPL-3.0-or-later

#include "appstreampoolbridge.h"
#include "../models/appitem.h"

#include <QDebug>
#include <QHash>
#include <QUrl>
#include <QDateTime>
#include <QLocale>
#include <QIcon>
#include <QPixmap>
#include <QBuffer>
#include <algorithm>

#include <AppStreamQt/component.h>
#include <AppStreamQt/developer.h>
#include <AppStreamQt/icon.h>
#include <AppStreamQt/screenshot.h>
#include <AppStreamQt/image.h>
#include <AppStreamQt/release.h>
#include <AppStreamQt/release-list.h>

#include <QRegularExpression>

namespace {

// AppStream category ids are not localized by libappstream, so map the common
// ones to Chinese for the detail page. Unknown ids fall through verbatim.
QString localizedCategory(const QStringList &ids)
{
    static const QHash<QString, QString> map = {
        {QStringLiteral("AudioVideo"), QStringLiteral("影音娱乐")},
        {QStringLiteral("Audio"), QStringLiteral("音频")},
        {QStringLiteral("Video"), QStringLiteral("视频")},
        {QStringLiteral("Development"), QStringLiteral("开发工具")},
        {QStringLiteral("Education"), QStringLiteral("教育")},
        {QStringLiteral("Game"), QStringLiteral("游戏")},
        {QStringLiteral("Graphics"), QStringLiteral("图形图像")},
        {QStringLiteral("Network"), QStringLiteral("网络")},
        {QStringLiteral("Office"), QStringLiteral("办公")},
        {QStringLiteral("Science"), QStringLiteral("科学")},
        {QStringLiteral("Settings"), QStringLiteral("设置")},
        {QStringLiteral("System"), QStringLiteral("系统")},
        {QStringLiteral("Utility"), QStringLiteral("实用工具")},
        {QStringLiteral("InstantMessaging"), QStringLiteral("即时通讯")},
        {QStringLiteral("IRCClient"), QStringLiteral("IRC 客户端")},
        {QStringLiteral("FeedReader"), QStringLiteral("新闻阅读")},
        {QStringLiteral("WebBrowser"), QStringLiteral("网络浏览器")},
        {QStringLiteral("Email"), QStringLiteral("邮件")},
        {QStringLiteral("ContactManagement"), QStringLiteral("联系人管理")},
        {QStringLiteral("Calendar"), QStringLiteral("日历")},
        {QStringLiteral("Database"), QStringLiteral("数据库")},
        {QStringLiteral("FileManager"), QStringLiteral("文件管理")},
        {QStringLiteral("TerminalEmulator"), QStringLiteral("终端")},
        {QStringLiteral("TextEditor"), QStringLiteral("文本编辑器")},
        {QStringLiteral("IDE"), QStringLiteral("集成开发环境")},
        {QStringLiteral("Photography"), QStringLiteral("摄影")},
        {QStringLiteral("Player"), QStringLiteral("媒体播放器")},
        {QStringLiteral("Recorder"), QStringLiteral("录音")},
        {QStringLiteral("ScreenSaver"), QStringLiteral("屏保")},
        {QStringLiteral("Security"), QStringLiteral("安全")},
        {QStringLiteral("Accessibility"), QStringLiteral("无障碍")},
        {QStringLiteral("Amusement"), QStringLiteral("娱乐")},
        {QStringLiteral("Music"), QStringLiteral("音乐")},
        {QStringLiteral("Finance"), QStringLiteral("金融")},
        {QStringLiteral("Math"), QStringLiteral("数学")},
        {QStringLiteral("Engineering"), QStringLiteral("工程")},
        {QStringLiteral("Languages"), QStringLiteral("语言")},
        {QStringLiteral("Art"), QStringLiteral("艺术")},
        {QStringLiteral("Sports"), QStringLiteral("体育")},
        {QStringLiteral("PackageManager"), QStringLiteral("软件包管理")},
        {QStringLiteral("Emulator"), QStringLiteral("模拟器")},
        {QStringLiteral("Monitor"), QStringLiteral("系统监视")},
        {QStringLiteral("RemoteAccess"), QStringLiteral("远程访问")},
        {QStringLiteral("FileTools"), QStringLiteral("文件工具")},
        {QStringLiteral("Archiving"), QStringLiteral("压缩归档")},
        {QStringLiteral("Compression"), QStringLiteral("压缩工具")},
        {QStringLiteral("Maps"), QStringLiteral("地图")},
        {QStringLiteral("Weather"), QStringLiteral("天气")},
        {QStringLiteral("News"), QStringLiteral("新闻")},
        {QStringLiteral("P2P"), QStringLiteral("点对点")},
        {QStringLiteral("Chat"), QStringLiteral("聊天")},
    };
    for (const QString &id : ids) {
        const auto it = map.constFind(id);
        if (it != map.constEnd())
            return it.value();
    }
    // Nothing mapped: prefer a human-ish fallback (id is CamelCase).
    return ids.isEmpty() ? QString() : ids.first();
}

// AppStream descriptions and release notes are rich text. Convert them
// to readable plain text while preserving paragraph and list boundaries.
QString plainText(const QString &rich)
{
    QString text = rich;
    text.replace(QRegularExpression(QStringLiteral("<br\\s*/?>"),
                                    QRegularExpression::CaseInsensitiveOption),
                 QStringLiteral("\n"));
    text.replace(QRegularExpression(QStringLiteral("<li\\b[^>]*>"),
                                    QRegularExpression::CaseInsensitiveOption),
                 QStringLiteral("\n• "));
    text.replace(QRegularExpression(QStringLiteral("</(p|li|div|h[1-6])>"),
                                    QRegularExpression::CaseInsensitiveOption),
                 QStringLiteral("\n\n"));
    text.remove(QRegularExpression(QStringLiteral("<[^>]*>")));
    text.replace(QStringLiteral("&nbsp;"), QStringLiteral(" "));
    text.replace(QStringLiteral("&#160;"), QStringLiteral(" "));
    text.replace(QStringLiteral("&amp;"), QStringLiteral("&"));
    text.replace(QStringLiteral("&lt;"), QStringLiteral("<"));
    text.replace(QStringLiteral("&gt;"), QStringLiteral(">"));
    text.replace(QStringLiteral("&#39;"), QStringLiteral("'"));
    text.replace(QStringLiteral("&apos;"), QStringLiteral("'"));
    text.replace(QStringLiteral("&quot;"), QStringLiteral("\""));
    text.replace(QRegularExpression(QStringLiteral("[\\t \\x{00A0}]+")),
                 QStringLiteral(" "));
    text.replace(QRegularExpression(QStringLiteral(" *\\n *")), QStringLiteral("\n"));
    text.replace(QRegularExpression(QStringLiteral("\\n{3,}")), QStringLiteral("\n\n"));
    return text.trimmed();
}

} // namespace

AppStreamPoolBridge::AppStreamPoolBridge(QObject *parent)
    : QObject(parent)
{
    // Only flatpak appstream metadata is relevant for this store.
    m_pool.setFlags(AppStream::Pool::FlagLoadFlatpak);
    m_pool.setLocale(QLocale::system().name());
}

void AppStreamPoolBridge::startLoading()
{
    if (m_loaded)
        return;
    connect(&m_pool, &AppStream::Pool::loadFinished, this, [this](bool success) {
        m_loaded = success;
        Q_EMIT loadFinished(success);
    });
    m_pool.loadAsync();
}

bool AppStreamPoolBridge::loaded() const
{
    return m_loaded;
}

QStringList AppStreamPoolBridge::appIdsInCategory(const QString &category) const
{
    QStringList ids;
    if (!m_loaded || category.isEmpty())
        return ids;

    const AppStream::ComponentBox box =
        m_pool.componentsByCategories(QStringList{category});
    ids.reserve(box.size());
    for (const auto &comp : box) {
        const QString id = comp.id();
        if (!id.isEmpty())
            ids.append(id);
    }
    return ids;
}

bool AppStreamPoolBridge::enrichSearchMetadata(AppItem *item)
{
    if (!m_loaded || !item)
        return false;

    // Avoid repeating AppStream lookups for items whose searchable metadata
    // has already been populated.
    if (item->name() != item->appId() && !item->summary().isEmpty())
        return false;

    const QString appId = item->appId();
    AppStream::ComponentBox box = m_pool.componentsById(appId);
    if (box.size() == 0)
        box = m_pool.componentsById(appId + QStringLiteral(".desktop"));
    if (box.size() == 0 && appId.endsWith(QStringLiteral(".desktop")))
        box = m_pool.componentsById(appId.chopped(8));
    if (box.size() == 0)
        return false;

    const AppStream::Component comp = *box.begin();
    const QString name = comp.name();
    const QString summary = comp.summary();
    if (!name.isEmpty() && name != appId)
        item->setName(name);
    if (!summary.isEmpty())
        item->setSummary(summary);
    return !name.isEmpty() || !summary.isEmpty();
}

bool AppStreamPoolBridge::hasComponent(const QString &appId) const
{
    return m_loaded && !appId.isEmpty() && m_pool.componentsById(appId).size() > 0;
}

QStringList AppStreamPoolBridge::recentlyUpdatedAppIds(int limit) const
{
    if (!m_loaded || limit <= 0)
        return {};

    struct Entry {
        QString id;
        qint64 timestamp = 0;
    };

    QList<Entry> entries;
    const AppStream::ComponentBox box = m_pool.components();
    entries.reserve(box.size());
    for (const auto &comp : box) {
        if (comp.kind() != AppStream::Component::KindDesktopApp)
            continue;

        const QList<AppStream::Release> releases = comp.releasesPlain().entries();
        qint64 newest = 0;
        for (const auto &release : releases) {
            const QDateTime timestamp = release.timestamp();
            if (timestamp.isValid())
                newest = qMax(newest, timestamp.toSecsSinceEpoch());
        }
        if (newest > 0)
            entries.append({comp.id(), newest});
    }

    std::sort(entries.begin(), entries.end(), [](const Entry &a, const Entry &b) {
        return a.timestamp > b.timestamp;
    });

    QStringList ids;
    ids.reserve(qMin(limit, entries.size()));
    for (const Entry &entry : entries) {
        if (ids.size() >= limit)
            break;
        ids.append(entry.id);
    }
    return ids;
}

bool AppStreamPoolBridge::enrich(AppItem *item)
{
    if (!m_loaded || !item)
        return false;

    const QString appId = item->appId();

    // AppStream component IDs do not always match the Flatpak ref ID exactly.
    // Desktop applications are commonly published with a ".desktop" suffix.
    AppStream::ComponentBox box = m_pool.componentsById(appId);
    if (box.size() == 0)
        box = m_pool.componentsById(appId + QStringLiteral(".desktop"));
    if (box.size() == 0 && appId.endsWith(QStringLiteral(".desktop")))
        box = m_pool.componentsById(appId.chopped(8));
    if (box.size() == 0) {
        qDebug() << "AppStream metadata not found for Flatpak app:" << appId;
        return false;
    }

    const AppStream::Component comp = *box.begin();

    bool changed = false;

    const QString name = comp.name();
    if (!name.isEmpty() && name != appId) {
        item->setName(name);
        changed = true;
    }
    const QString summary = comp.summary();
    if (!summary.isEmpty()) {
        item->setSummary(summary);
        changed = true;
    }
    const QString description = plainText(comp.description());
    if (!description.isEmpty()) {
        item->setDescription(description);
        changed = true;
    }
    const QString license = comp.projectLicense();
    if (!license.isEmpty()) {
        item->setLicense(license);
        changed = true;
    }

    const QString developer = comp.developer().name();
    if (!developer.isEmpty()) {
        item->setDeveloper(developer);
        changed = true;
    }

    const QString homepage = comp.url(AppStream::Component::UrlKindHomepage).toString();
    if (!homepage.isEmpty()) {
        item->setHomepage(homepage);
        changed = true;
    }

    const QString category = localizedCategory(comp.categories());
    if (!category.isEmpty()) {
        item->setCategory(category);
        changed = true;
    }

    // "What's new": newest release entry that actually carries a description.
    // The same list doubles as a version fallback for remote refs, which do
    // not carry a version of their own.
    const QList<AppStream::Release> releases = comp.releasesPlain().entries();
    bool haveNotes = false;
    bool haveVersion = !item->version().isEmpty();
    for (const auto &release : releases) {
        if (!haveNotes) {
            const QString notes = plainText(release.description());
            if (!notes.isEmpty()) {
                item->setReleaseNotes(notes);
                haveNotes = true;
                changed = true;
            }
        }
        if (!haveVersion) {
            const QString relVersion = release.version();
            if (!relVersion.isEmpty()) {
                item->setVersion(relVersion);
                haveVersion = true;
                changed = true;
            }
        }
        if (haveNotes && haveVersion)
            break;
    }

    // Prefer a cached local icon, then a remote URL. AppStream::Icon::url()
    // returns an empty (but technically valid) QUrl for stock/unnamed icons;
    // accepting that value used to overwrite the installed app's icon with
    // an empty source.
    const QList<AppStream::Icon> icons = comp.icons();
    QUrl selectedIcon;
    QString stockIconName;
    for (const auto &icon : icons) {
        if (icon.kind() == AppStream::Icon::KindStock) {
            if (stockIconName.isEmpty())
                stockIconName = icon.name();
            continue;
        }

        const QUrl url = icon.url();
        if (url.isEmpty() || !url.isValid())
            continue;
        if (icon.kind() == AppStream::Icon::KindCached
            || icon.kind() == AppStream::Icon::KindLocal) {
            selectedIcon = url;
            break;
        }
        if (selectedIcon.isEmpty())
            selectedIcon = url;
    }

    // Stock icons have a theme name instead of a file/URL. Resolve them with
    // the active desktop icon theme and pass the resulting image to QML.
    if (selectedIcon.isEmpty() && !stockIconName.isEmpty()) {
        const QIcon themedIcon = QIcon::fromTheme(stockIconName);
        if (!themedIcon.isNull()) {
            const QPixmap pixmap = themedIcon.pixmap(128, 128);
            QByteArray imageData;
            QBuffer buffer(&imageData);
            if (buffer.open(QIODevice::WriteOnly) && pixmap.save(&buffer, "PNG")) {
                selectedIcon = QUrl(QStringLiteral("data:image/png;base64,")
                                    + QString::fromLatin1(imageData.toBase64()));
            }
        }
    }

    if (!selectedIcon.isEmpty() && item->iconUrl() != selectedIcon) {
        item->setIcon(selectedIcon);
        changed = true;
    }

    // Screenshots: keep one URL per screenshot, preferring the full-size
    // source image and falling back to the thumbnail.
    const QList<AppStream::Screenshot> shots = comp.screenshotsAll();
    if (!shots.isEmpty()) {
        QList<QUrl> urls;
        for (const auto &shot : shots) {
            QUrl chosen;
            QUrl thumbnail;
            for (const auto &img : shot.imagesAll()) {
                const QUrl u = img.url();
                if (u.isEmpty() || !u.isValid())
                    continue;
                if (img.kind() == AppStream::Image::KindThumbnail) {
                    if (thumbnail.isEmpty())
                        thumbnail = u;
                } else if (img.kind() == AppStream::Image::KindSource) {
                    if (chosen.isEmpty())
                        chosen = u;
                }
            }
            if (chosen.isEmpty())
                chosen = thumbnail;
            if (!chosen.isEmpty())
                urls.append(chosen);
        }
        if (!urls.isEmpty()) {
            item->setScreenshots(urls);
            changed = true;
        }
    }

    return changed;
}