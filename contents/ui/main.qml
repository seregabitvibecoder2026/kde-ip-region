import QtQuick
import QtQuick.Layouts
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.plasmoid
import org.kde.plasma.components as PlasmaComponents
import org.kde.kirigami as Kirigami

PlasmoidItem {
    id: root

    preferredRepresentation: compactRepresentation
    Plasmoid.backgroundHints: PlasmaCore.Types.DefaultBackground | PlasmaCore.Types.ConfigurableBackground

    // ---- state ----
    property string country: ""      // "DE"
    property string ip: ""
    property string city: ""
    property string org: ""
    property bool loading: false
    property bool failed: false
    property string lastChecked: ""

    readonly property int cfgInterval: Math.max(5, Plasmoid.configuration.updateInterval)
    readonly property int fontPx: Plasmoid.configuration.fontSize > 0 ? Plasmoid.configuration.fontSize : -1

    // ---- geo providers (tried in order until one works) ----
    readonly property var providers: [
        { url: "https://ipinfo.io/json", parse: function (j) {
            return { cc: j.country, ip: j.ip, city: j.city, org: j.org };
        } },
        { url: "https://ipwho.is/", parse: function (j) {
            return j.success === false ? null
                 : { cc: j.country_code, ip: j.ip, city: j.city, org: j.connection ? j.connection.isp : "" };
        } },
        { url: "https://api.country.is/", parse: function (j) {
            return { cc: j.country, ip: j.ip, city: "", org: "" };
        } }
        // HTTPS only on purpose: a plain-HTTP answer could be spoofed on the
        // network and show a fake country while the VPN is actually down.
    ]

    property var _xhr: null
    property int _providerIdx: 0

    function flagEmoji(cc) {
        if (!cc || cc.length !== 2) return "";
        var base = 0x1F1E6 - 65;
        return String.fromCodePoint(base + cc.charCodeAt(0), base + cc.charCodeAt(1));
    }

    function refresh() {
        if (loading) return;
        loading = true;
        _providerIdx = 0;
        tryProvider();
    }

    function tryProvider() {
        if (_providerIdx >= providers.length) {
            loading = false;
            failed = true;
            lastChecked = Qt.formatTime(new Date(), "hh:mm:ss");
            return;
        }
        var p = providers[_providerIdx];
        var xhr = new XMLHttpRequest();
        _xhr = xhr;
        xhr.onreadystatechange = function () {
            if (xhr.readyState !== XMLHttpRequest.DONE || xhr !== root._xhr) return;
            requestTimeout.stop();
            var res = null;
            if (xhr.status === 200) {
                try { res = p.parse(JSON.parse(xhr.responseText)); } catch (e) { res = null; }
            }
            if (res && res.cc && /^[A-Za-z]{2}$/.test(res.cc)) {
                root.country = res.cc.toUpperCase();
                root.ip = res.ip || "";
                root.city = res.city || "";
                root.org = res.org || "";
                root.failed = false;
                root.loading = false;
                root._xhr = null;
                root.lastChecked = Qt.formatTime(new Date(), "hh:mm:ss");
            } else {
                root._providerIdx++;
                root.tryProvider();
            }
        };
        xhr.open("GET", p.url);
        xhr.setRequestHeader("Accept", "application/json");
        xhr.send();
        requestTimeout.restart();
    }

    Timer {
        id: requestTimeout
        interval: 5000
        onTriggered: {
            if (!root._xhr) return;
            var x = root._xhr;
            root._xhr = null;   // ignore late answer
            x.abort();
            root._providerIdx++;
            root.tryProvider();
        }
    }

    Timer {
        interval: root.cfgInterval * 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root.refresh()
    }

    // ---- tooltip ----
    toolTipMainText: failed && !country ? i18n("IP region: unknown")
                                        : (flagEmoji(country) + "  " + country + (city ? " · " + city : ""))
    toolTipSubText: {
        var lines = [];
        if (ip) lines.push("IP: " + ip);
        if (org) lines.push(org);
        if (failed) lines.push(i18n("Last check failed"));
        if (lastChecked) lines.push(i18n("Checked: %1", lastChecked));
        lines.push(i18n("Click to refresh"));
        return lines.join("\n");
    }

    // ---- panel view, styled like KVitals ----
    compactRepresentation: Item {
        id: compact

        readonly property color textColor: Kirigami.Theme.textColor
        property bool _themeReady: false
        Timer { interval: 0; running: true; onTriggered: compact._themeReady = true }

        implicitWidth: row.implicitWidth
        implicitHeight: row.implicitHeight
        Layout.minimumWidth: row.implicitWidth
        Layout.preferredWidth: row.implicitWidth

        TapHandler {
            onTapped: { root.failed = false; root.refresh(); }
        }

        RowLayout {
            id: row
            anchors.centerIn: parent
            spacing: Kirigami.Units.smallSpacing

            Kirigami.Icon {
                visible: Plasmoid.configuration.showIcon
                source: Qt.resolvedUrl("../icons/globe-symbolic.svg")
                isMask: compact._themeReady
                color: compact._themeReady ? compact.textColor : Qt.rgba(0, 0, 0, 0)
                implicitWidth: Plasmoid.configuration.iconSize
                implicitHeight: Plasmoid.configuration.iconSize
                Layout.alignment: Qt.AlignVCenter
                opacity: root.loading && !root.country ? 0.5 : 1
            }

            PlasmaComponents.Label {
                // reserve width for two monospace chars so the panel doesn't jump
                Layout.preferredWidth: Math.max(implicitWidth, metrics.width)
                Layout.alignment: Qt.AlignVCenter
                horizontalAlignment: Text.AlignHCenter
                text: root.country || (root.loading ? "··" : "--")
                font.pixelSize: root.fontPx
                font.family: Plasmoid.configuration.fontFamily
                font.bold: Plasmoid.configuration.fontBold
                color: compact.textColor
                opacity: root.failed ? 0.5 : 1

                TextMetrics {
                    id: metrics
                    text: "WW"
                    font.pixelSize: root.fontPx
                    font.family: Plasmoid.configuration.fontFamily
                    font.bold: Plasmoid.configuration.fontBold
                }
            }
        }
    }

    fullRepresentation: Item {}
}
