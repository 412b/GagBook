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
 *     * Neither the name of GagBook nor the names of its contributors may be
 *       used to endorse or promote products derived from this software without
 *       specific prior written permission.
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

import QtQuick 1.1
import com.nokia.meego 1.0
import GagBook 1.0

Page {
    id: mainPage

    tools: ToolBarLayout {
        ToolIcon {
            platformIconId: "toolbar-back-dimmed"
            enabled: false
        }
        ToolIcon {
            platformIconId: "toolbar-list"
            onClicked: dialogManager.createSectionDialog()
        }
        ToolIcon {
            platformIconId: "toolbar-refresh" + (enabled ? "" : "-dimmed")
            enabled: !gagManager.busy
            onClicked: gagManager.refresh(GagManager.RefreshAll)
        }
        ToolIcon {
            platformIconId: "toolbar-view-menu"
            onClicked: mainMenu.open()
        }
    }

    Menu {
        id: mainMenu

        MenuLayout {
            MenuItem {
                text: "Back to top"
                onClicked: gagListView.positionViewAtBeginning()
            }
            MenuItem {
                text: "Settings"
                onClicked: pageStack.push(Qt.resolvedUrl("SettingsPage.qml"))
            }
            MenuItem {
                text: "About GagBook"
                onClicked: pageStack.push(Qt.resolvedUrl("AboutPage.qml"))
            }
        }
    }

    ListView {
        id: gagListView
        anchors.fill: parent
        model: gagManager.model
        orientation: ListView.Vertical
        delegate: GagDelegate {}
        header: PageHeader { text: sectionModel.get(settings.selectedSection).text; busy: gagManager.busy }
        footer: Item {
            width: ListView.view.width
            height: loadingIndicatorLoader.height + 2 * constant.paddingMedium
            visible: ListView.view.count > 0 && gagManager.busy

            Loader {
                id: loadingIndicatorLoader
                anchors.centerIn: parent
                sourceComponent: parent.visible ? loadingIndicator : undefined
            }

            Component {
                id: loadingIndicator

                Row {
                    width: childrenRect.width
                    height: footerBusyIndicator.height
                    spacing: constant.paddingMedium

                    BusyIndicator { id: footerBusyIndicator; running: true }

                    Text {
                        id: loadingText
                        anchors.verticalCenter: parent.verticalCenter
                        font.pixelSize: constant.fontSizeMedium
                        color: constant.colorLight
                        text: "Loading..."
                    }
                }
            }
        }

        onAtYEndChanged: if (atYEnd && !gagManager.busy && count > 0) gagManager.refresh(GagManager.RefreshOlder)
    }

    QtObject {
        id: dialogManager

        property Component __sectionDialogComponent: null
        property Component __openLinkDialogComponent: null

        function createSectionDialog() {
            if (!__sectionDialogComponent) __sectionDialogComponent = Qt.createComponent("SectionDialog.qml")
            var dialog = __sectionDialogComponent.createObject(mainPage)
            if (!dialog) {
                console.log("Error creating object: " + __sectionDialogComponent.errorString())
                return
            }
            dialog.accepted.connect(function() {
                settings.selectedSection = dialog.selectedIndex;
                gagManager.refresh(GagManager.RefreshAll);
            })
        }

        function createOpenLinkDialog(link) {
            if (!__openLinkDialogComponent) __openLinkDialogComponent = Qt.createComponent("OpenLinkDialog.qml")
            var dialog = __openLinkDialogComponent.createObject(mainPage, { link: link })
            if (!dialog) console.log("Error creating object: " + __openLinkDialogComponent.errorString())
        }

    }
}
