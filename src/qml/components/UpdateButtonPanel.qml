// SPDX-FileCopyrightText: 2026 dodo-store authors
//
// SPDX-License-Identifier: LGPL-3.0-or-later

import QtQuick 2.15
import org.deepin.dtk 1.0 as D
import org.deepin.dtk.private 1.0 as P
import org.deepin.dtk.style 1.0 as DS

// Reuses DTK's native ButtonPanel, changing only its palette for update actions.
// The panel retains DTK borders, shadows, corner radius and interaction states.
P.ButtonPanel {
    id: control
    property bool green: true

    D.Palette {
        id: greenBackground1
        normal.common: "#35a85b"
        hovered.common: "#43b96a"
        pressed.common: "#278849"
        disabled.common: "#9bbda5"
    }
    D.Palette {
        id: greenBackground2
        normal.common: "#2d984f"
        hovered.common: "#369f59"
        pressed.common: "#237d43"
        disabled.common: "#91ae99"
    }
    D.Palette {
        id: greenInsideBorder
        normal.common: "#59bd78"
        hovered.common: "#70cc8b"
        pressed.common: "#237a43"
        disabled.common: "#a9c1af"
    }
    D.Palette {
        id: greenOutsideBorder
        normal.common: "#267c43"
        hovered.common: "#2d8d4d"
        pressed.common: "#1d6637"
        disabled.common: "#879d8d"
    }
    D.Palette {
        id: greenDropShadow
        normal.common: "#40206b39"
        hovered.common: "#50206b39"
        pressed.common: "#30206b39"
        disabled.common: "#20206b39"
    }
    D.Palette {
        id: greenInnerShadow1
        normal.common: "#245b35"
        hovered.common: "#2b7040"
        pressed.common: "#17482a"
        disabled.common: "#718a78"
    }
    D.Palette {
        id: greenInnerShadow2
        normal.common: "#3a9a58"
        hovered.common: "#48aa67"
        pressed.common: "#267d45"
        disabled.common: "#91ad98"
    }

    color1: green ? greenBackground1
                  : (button.highlighted ? DS.Style.highlightedButton.background1 : DS.Style.button.background1)
    color2: green ? greenBackground2
                  : (button.highlighted ? DS.Style.highlightedButton.background2 : DS.Style.button.background2)
    insideBorderColor: green ? greenInsideBorder
                             : (button.highlighted ? DS.Style.highlightedButton.border : DS.Style.button.insideBorder)
    outsideBorderColor: green ? greenOutsideBorder : DS.Style.button.outsideBorder
    dropShadowColor: green ? greenDropShadow
                           : (button.highlighted ? DS.Style.highlightedButton.dropShadow : DS.Style.button.dropShadow)
    innerShadowColor1: green ? greenInnerShadow1
                             : (button.highlighted ? DS.Style.highlightedButton.innerShadow1 : DS.Style.button.innerShadow1)
    innerShadowColor2: green ? greenInnerShadow2
                             : (button.highlighted ? DS.Style.highlightedButton.innerShadow2 : DS.Style.button.innerShadow2)
}
