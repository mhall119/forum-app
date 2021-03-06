/*************************************************************************
** Forum Browser
**
** Copyright (c) 2014 Niklas Wenzel <nikwen.developer@gmail.com>
**
** $QT_BEGIN_LICENSE:GPL$
** This program is free software; you can redistribute it and/or modify
** it under the terms of the GNU General Public License as published by
** the Free Software Foundation; either version 2 of the License, or
** (at your option) any later version.
**
** This program is distributed in the hope that it will be useful,
** but WITHOUT ANY WARRANTY; without even the implied warranty of
** MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
** General Public License for more details.
**
** You should have received a copy of the GNU General Public License
** along with this program; see the file COPYING. If not, write to
** the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
** Boston, MA 02110-1301, USA.
**
**
** $QT_END_LICENSE$
**
*************************************************************************/

import QtQuick 2.2
import Ubuntu.Components 1.1
import U1db 1.0 as U1db
import Ubuntu.Components.ListItems 1.0 as ListItem

Page {
    id: forumsListPage
    title: i18n.tr("My Forums")

    head.actions: [
        Action {
            id: addAction
            text: i18n.tr("Add Forum")
            iconName: "add"
            onTriggered: pageStack.push(Qt.resolvedUrl("AddForumPage.qml"))
        },
        Action {
            id: aboutAction
            text: i18n.tr("About")
            iconName: "info"
            onTriggered: pageStack.push(Qt.resolvedUrl("AboutPage.qml"))
        }

    ]

    U1db.Index {
        database: db
        id: by_forum
        expression: ["name", "url"]
    }
    U1db.Query {
        id: forums
        index: by_forum
        query: ["*", "*"]
    }

    ListView {
        id: listView
        model: sortedList
        clip: true

        anchors {
            top: parent.top
            left: parent.left
            right: parent.right
            bottom: poweredByTapatalkItem.top
        }


        property var sortedList: sort(forums.results)

        delegate: ListItem.Standard {
            text: model.modelData.name

            progression: true
            removable: true
            confirmRemoval: true

            onItemRemoved: {
                db.deleteDoc(forums.documents[listView.mapSortedIndexToUnsorted(index)])
            }

            property Component component

            onClicked: {
                var prefix = model.modelData.url.indexOf("http://") === 0 || model.modelData.url.indexOf("https://") === 0
                var apiSource = (!prefix?"http://":"") + model.modelData.url + "/mobiquo/mobiquo.php"
                var currentForumUrl = model.modelData.url
                backend.newSession(currentForumUrl, apiSource)

                pushPage()
            }

            function pushPage() {
                component = Qt.createComponent("viewing/SubForumPage.qml");

                if (component.status === Component.Ready) {
                    finishCreation();
                } else {
                    console.log(component.errorString())
                    component.statusChanged.connect(finishCreation);
                }
            }

            function finishCreation() {
                var page = component.createObject(mainView, {"current_forum": 0, "title": text})
                if (page === null) console.log(component.errorString())
                pageStack.push(page)
                page.loadingSpinnerRunning = true
            }

            onPressAndHold: {
                pageStack.push(Qt.resolvedUrl("AddForumPage.qml"), {"docId": forums.documents[listView.mapSortedIndexToUnsorted(index)]})
            }
        }

        function mapSortedIndexToUnsorted(index) {
            //name is unique so we can search for it
            var searchFor = sortedList[index].name
            for (var i = 0; i < forums.results.length; i++) {
                if (forums.results[i].name === searchFor) {
                    return i
                }
            }
        }

        function sort(list) {
            //Selection sort

            for (var i = 0; i < list.length; i++) {
                var minIndex = i
                for (var j = i; j < list.length; j++) {
                    if (list[j].name.toLowerCase() < list[minIndex].name.toLowerCase()) { //Case insensitive
                        minIndex = j
                    }
                }
                var temp = list[i]
                list[i] = list[minIndex]
                list[minIndex] = temp
            }

            return list
        }
    }

    Label {
        id: addForumLabel
        text: i18n.tr("Swipe up from the bottom to add a forum")
        visible: listView.count === 0
        elide: Text.ElideRight
        wrapMode: Text.WordWrap
        horizontalAlignment: Text.AlignHCenter
        fontSize: "large"
        anchors {
            verticalCenter: listView.verticalCenter
            left: parent.left
            right: parent.right
            margins: units.gu(2)
        }
    }

    ListItem.Empty {
        id: poweredByTapatalkItem
        anchors.bottom: parent.bottom
        width: parent.width
        divider.visible: false

        onClicked: Qt.openUrlExternally("https://tapatalk.com")

        ListItem.ThinDivider {
            anchors {
                top: parent.top
                rightMargin: 0
                leftMargin: 0
            }
            width: parent.width
        }

        Label {
            text: i18n.tr("Powered by Tapatalk")
            anchors.centerIn: parent
        }
    }

}
