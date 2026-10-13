// SPDX-FileCopyrightText: 2026 dodo-store authors
//
// SPDX-License-Identifier: LGPL-3.0-or-later

#include "appfilterproxymodel.h"
#include "applistmodel.h"

AppFilterProxyModel::AppFilterProxyModel(QObject *parent)
    : QSortFilterProxyModel(parent)
{
    setFilterCaseSensitivity(Qt::CaseInsensitive);
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

    if (filterRegularExpression().pattern().isEmpty())
        return true;

    const QString name = idx.data(AppListModel::NameRole).toString();
    const QString summary = idx.data(AppListModel::SummaryRole).toString();
    return name.contains(filterRegularExpression())
           || summary.contains(filterRegularExpression());
}
