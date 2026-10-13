// SPDX-FileCopyrightText: 2026 dodo-store authors
//
// SPDX-License-Identifier: LGPL-3.0-or-later

#include "appfilterproxymodel.h"
#include "applistmodel.h"

AppFilterProxyModel::AppFilterProxyModel(QObject *parent)
    : QSortFilterProxyModel(parent)
{
    setFilterCaseSensitivity(Qt::CaseInsensitive);
    connect(this, &QAbstractItemModel::rowsInserted, this, &AppFilterProxyModel::countChanged);
    connect(this, &QAbstractItemModel::rowsRemoved, this, &AppFilterProxyModel::countChanged);
    connect(this, &QAbstractItemModel::modelReset, this, &AppFilterProxyModel::countChanged);
}

int AppFilterProxyModel::count() const
{
    return rowCount();
}

QString AppFilterProxyModel::filterText() const
{
    return m_filterText;
}

void AppFilterProxyModel::setFilterText(const QString &text)
{
    if (m_filterText == text)
        return;
    m_filterText = text;
    setFilterFixedString(text);
    if (!m_appIdFilter.isEmpty())
        sort(0, Qt::AscendingOrder);
    Q_EMIT filterTextChanged();
}

bool AppFilterProxyModel::hideRuntimes() const
{
    return m_hideRuntimes;
}

void AppFilterProxyModel::setHideRuntimes(bool hide)
{
    if (m_hideRuntimes == hide)
        return;
    m_hideRuntimes = hide;
    invalidateFilter();
    Q_EMIT hideRuntimesChanged();
}

bool AppFilterProxyModel::showRuntimesOnly() const
{
    return m_showRuntimesOnly;
}

void AppFilterProxyModel::setShowRuntimesOnly(bool show)
{
    if (m_showRuntimesOnly == show)
        return;
    m_showRuntimesOnly = show;
    invalidateFilter();
    Q_EMIT showRuntimesOnlyChanged();
}

QStringList AppFilterProxyModel::appIdFilter() const
{
    return m_appIdFilter;
}

void AppFilterProxyModel::setAppIdFilter(const QStringList &appIds)
{
    if (m_appIdFilter == appIds)
        return;
    m_appIdFilter = appIds;
    invalidateFilter();
    if (m_appIdFilter.isEmpty())
        sort(-1);
    else
        sort(0, Qt::AscendingOrder);
    Q_EMIT appIdFilterChanged();
}

bool AppFilterProxyModel::filterAcceptsRow(int sourceRow, const QModelIndex &sourceParent) const
{
    const QModelIndex idx = sourceModel()->index(sourceRow, 0, sourceParent);
    const bool isRuntime = idx.data(AppListModel::IsRuntimeRole).toBool();

    // Keep runtimes in the backend model for dependency tracking and updates,
    // but control which user-facing section displays them.
    if (m_hideRuntimes && isRuntime)
        return false;
    if (m_showRuntimesOnly && !isRuntime)
        return false;

    // The landing page shows a curated set; entering a query searches the full catalog.
    if (m_filterText.trimmed().isEmpty() && !m_appIdFilter.isEmpty()) {
        const QString appId = idx.data(AppListModel::AppIdRole).toString();
        if (!m_appIdFilter.contains(appId))
            return false;
    }

    if (filterRegularExpression().pattern().isEmpty())
        return true;

    const QString name = idx.data(AppListModel::NameRole).toString();
    const QString summary = idx.data(AppListModel::SummaryRole).toString();
    return name.contains(filterRegularExpression())
           || summary.contains(filterRegularExpression());
}


bool AppFilterProxyModel::lessThan(const QModelIndex &sourceLeft,
                                   const QModelIndex &sourceRight) const
{
    if (m_filterText.trimmed().isEmpty() && !m_appIdFilter.isEmpty()) {
        const QString leftId = sourceLeft.data(AppListModel::AppIdRole).toString();
        const QString rightId = sourceRight.data(AppListModel::AppIdRole).toString();
        const int leftRank = m_appIdFilter.indexOf(leftId);
        const int rightRank = m_appIdFilter.indexOf(rightId);
        if (leftRank != rightRank)
            return leftRank < rightRank;
    }

    const QString leftName = sourceLeft.data(AppListModel::NameRole).toString();
    const QString rightName = sourceRight.data(AppListModel::NameRole).toString();
    const int result = QString::compare(leftName, rightName, Qt::CaseInsensitive);
    if (result != 0)
        return result < 0;
    return QString::compare(sourceLeft.data(AppListModel::AppIdRole).toString(),
                            sourceRight.data(AppListModel::AppIdRole).toString(),
                            Qt::CaseInsensitive) < 0;
}
