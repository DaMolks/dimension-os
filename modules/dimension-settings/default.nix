{ config, lib, pkgs, ... }:

let
  cfg = config.dimension.dimensionSettings;

  appScript = pkgs.writeText "dimension-settings-app.py" ''
    import sys
    import json
    import os
    import urllib.request
    import urllib.error
    from pathlib import Path

    from PyQt6.QtWidgets import (
        QApplication, QMainWindow, QTabWidget, QWidget,
        QVBoxLayout, QHBoxLayout, QLabel, QPushButton,
        QTableWidget, QTableWidgetItem, QHeaderView,
        QMessageBox,
    )
    from PyQt6.QtCore import QTimer
    from PyQt6.QtGui import QColor

    HUB_URL = os.environ.get("DIMENSION_HUB_URL", "http://127.0.0.1:8787")
    TOKEN_FILE = os.environ.get(
        "DIMENSION_HUB_TOKEN_FILE",
        "/etc/dimension/secrets/hub-dev-token",
    )

    def load_token():
        try:
            p = Path(TOKEN_FILE)
            if p.exists():
                t = p.read_text().strip()
                return t if t else None
        except Exception:
            pass
        return None

    def hub_request(path, method="GET", body=None):
        token = load_token()
        url = HUB_URL.rstrip("/") + path
        data = json.dumps(body).encode() if body else None
        headers = {"Content-Type": "application/json"}
        if token:
            headers["Authorization"] = "Bearer " + token
        req = urllib.request.Request(url, data=data, headers=headers, method=method)
        try:
            with urllib.request.urlopen(req, timeout=3) as resp:
                return json.loads(resp.read().decode())
        except urllib.error.HTTPError as e:
            raise RuntimeError("HTTP " + str(e.code) + ": " + e.reason)
        except Exception as e:
            raise RuntimeError(str(e))

    BG       = "#000F1F"
    BG2      = "#0D1F35"
    ACCENT   = "#0078D7"
    TEXT     = "#E8F0F8"
    TEXT_DIM = "#7C91A8"
    POS      = "#73D293"
    NEG      = "#FF626F"
    WARN     = "#FFC252"

    STYLE = (
        "QMainWindow, QWidget { background-color: " + BG + "; color: " + TEXT + "; font-size: 13px; }"
        "QTabWidget::pane { border: 1px solid " + BG2 + "; background-color: " + BG + "; }"
        "QTabBar::tab { background-color: " + BG2 + "; color: " + TEXT_DIM + "; padding: 8px 20px; border: none; margin-right: 2px; }"
        "QTabBar::tab:selected { background-color: " + BG + "; color: " + TEXT + "; border-bottom: 2px solid " + ACCENT + "; }"
        "QPushButton { background-color: " + ACCENT + "; color: white; border: none; padding: 5px 14px; border-radius: 3px; }"
        "QPushButton:hover { background-color: #0090FF; }"
        "QPushButton:disabled { background-color: #1A2A3D; color: " + TEXT_DIM + "; }"
        "QPushButton#reject { background-color: #8B1A24; }"
        "QPushButton#reject:hover { background-color: " + NEG + "; }"
        "QTableWidget { background-color: " + BG2 + "; color: " + TEXT + "; gridline-color: #1A2A3D; border: none; selection-background-color: #0A3060; }"
        "QHeaderView::section { background-color: " + BG + "; color: " + TEXT_DIM + "; padding: 6px; border: none; border-bottom: 1px solid #1A2A3D; }"
        "QLabel#status-ok { color: " + POS + "; font-weight: bold; }"
        "QLabel#status-err { color: " + NEG + "; font-weight: bold; }"
        "QLabel#section { color: " + TEXT_DIM + "; font-size: 11px; }"
        "QLabel#info-value { color: " + TEXT + "; font-size: 15px; font-weight: bold; }"
    )


    class HubTab(QWidget):
        def __init__(self):
            super().__init__()
            layout = QVBoxLayout(self)
            layout.setContentsMargins(20, 20, 20, 20)
            layout.setSpacing(16)

            row = QHBoxLayout()
            row.addWidget(QLabel("Hub status:"))
            self.status_label = QLabel("Checking...")
            row.addWidget(self.status_label)
            row.addStretch()
            btn = QPushButton("Refresh")
            btn.clicked.connect(self.refresh)
            row.addWidget(btn)
            layout.addLayout(row)

            sec = QLabel("NODES")
            sec.setObjectName("section")
            layout.addWidget(sec)

            self.table = QTableWidget(0, 4)
            self.table.setHorizontalHeaderLabels(["Hostname", "Status", "Last Seen", "Actions"])
            h = self.table.horizontalHeader()
            h.setSectionResizeMode(0, QHeaderView.ResizeMode.Stretch)
            h.setSectionResizeMode(1, QHeaderView.ResizeMode.ResizeToContents)
            h.setSectionResizeMode(2, QHeaderView.ResizeMode.ResizeToContents)
            h.setSectionResizeMode(3, QHeaderView.ResizeMode.Fixed)
            self.table.setColumnWidth(3, 180)
            self.table.verticalHeader().setVisible(False)
            self.table.setEditTriggers(QTableWidget.EditTrigger.NoEditTriggers)
            layout.addWidget(self.table)
            self._nodes = []
            QTimer.singleShot(0, self.refresh)

        def refresh(self):
            try:
                urllib.request.urlopen(HUB_URL + "/ping", timeout=2)
                self.status_label.setText("Connected  ✓")
                self.status_label.setObjectName("status-ok")
            except Exception as e:
                self.status_label.setText("Unreachable  ✗  (" + str(e) + ")")
                self.status_label.setObjectName("status-err")
            self.status_label.style().unpolish(self.status_label)
            self.status_label.style().polish(self.status_label)
            try:
                nodes = hub_request("/nodes")
                self._nodes = nodes if isinstance(nodes, list) else []
            except Exception:
                self._nodes = []
            self._render()

        def _render(self):
            self.table.setRowCount(0)
            for node in self._nodes:
                row = self.table.rowCount()
                self.table.insertRow(row)
                self.table.setItem(row, 0, QTableWidgetItem(node.get("hostname", "")))
                status = node.get("status", "approved")
                item = QTableWidgetItem(status)
                if status == "pending":
                    item.setForeground(QColor(WARN))
                elif status == "approved":
                    item.setForeground(QColor(POS))
                else:
                    item.setForeground(QColor(NEG))
                self.table.setItem(row, 1, item)
                self.table.setItem(row, 2, QTableWidgetItem(node.get("last_seen", "")))
                node_id = node.get("node_id", "")
                cell = QWidget()
                cell_layout = QHBoxLayout(cell)
                cell_layout.setContentsMargins(4, 2, 4, 2)
                cell_layout.setSpacing(6)
                if status == "pending":
                    a = QPushButton("Approve")
                    a.clicked.connect(lambda _, nid=node_id: self._act("approve", nid))
                    r = QPushButton("Reject")
                    r.setObjectName("reject")
                    r.clicked.connect(lambda _, nid=node_id: self._act("reject", nid))
                    cell_layout.addWidget(a)
                    cell_layout.addWidget(r)
                else:
                    lbl = QLabel("—")
                    cell_layout.addWidget(lbl)
                self.table.setCellWidget(row, 3, cell)

        def _act(self, action, node_id):
            try:
                hub_request("/nodes/" + action, method="POST", body={"node_id": node_id})
            except Exception as e:
                QMessageBox.warning(self, "Error", str(e))
            self.refresh()


    class WireGuardTab(QWidget):
        def __init__(self):
            super().__init__()
            layout = QVBoxLayout(self)
            layout.setContentsMargins(20, 20, 20, 20)
            layout.setSpacing(16)
            header = QHBoxLayout()
            sec = QLabel("APPROVED PEERS")
            sec.setObjectName("section")
            header.addWidget(sec)
            header.addStretch()
            btn = QPushButton("Refresh")
            btn.clicked.connect(self.refresh)
            header.addWidget(btn)
            layout.addLayout(header)
            self.table = QTableWidget(0, 3)
            self.table.setHorizontalHeaderLabels(["Hostname", "WireGuard Public Key", "Last Seen"])
            h = self.table.horizontalHeader()
            h.setSectionResizeMode(0, QHeaderView.ResizeMode.ResizeToContents)
            h.setSectionResizeMode(1, QHeaderView.ResizeMode.Stretch)
            h.setSectionResizeMode(2, QHeaderView.ResizeMode.ResizeToContents)
            self.table.verticalHeader().setVisible(False)
            self.table.setEditTriggers(QTableWidget.EditTrigger.NoEditTriggers)
            layout.addWidget(self.table)
            QTimer.singleShot(0, self.refresh)

        def refresh(self):
            try:
                peers = hub_request("/wireguard/peers")
                peers = peers if isinstance(peers, list) else []
            except Exception:
                peers = []
            self.table.setRowCount(0)
            for peer in peers:
                row = self.table.rowCount()
                self.table.insertRow(row)
                self.table.setItem(row, 0, QTableWidgetItem(peer.get("hostname", "")))
                self.table.setItem(row, 1, QTableWidgetItem(peer.get("wg_pubkey", "")))
                self.table.setItem(row, 2, QTableWidgetItem(peer.get("last_seen", "")))


    class SystemTab(QWidget):
        def __init__(self):
            super().__init__()
            layout = QVBoxLayout(self)
            layout.setContentsMargins(20, 20, 20, 20)
            layout.setSpacing(12)
            self._row(layout, "HOSTNAME", self._hostname())
            self._row(layout, "EDITION", self._edition())
            self._row(layout, "UPTIME", self._uptime())
            self._row(layout, "HUB ENDPOINT", HUB_URL)
            layout.addStretch()

        def _row(self, layout, label, value):
            lbl = QLabel(label)
            lbl.setObjectName("section")
            val = QLabel(value)
            val.setObjectName("info-value")
            layout.addWidget(lbl)
            layout.addWidget(val)

        def _hostname(self):
            try:
                return Path("/proc/sys/kernel/hostname").read_text().strip()
            except Exception:
                return "unknown"

        def _edition(self):
            try:
                return Path("/etc/dimension/edition").read_text().strip()
            except Exception:
                return "unknown"

        def _uptime(self):
            try:
                s = float(Path("/proc/uptime").read_text().split()[0])
                h, m = int(s // 3600), int((s % 3600) // 60)
                return str(h) + "h " + str(m) + "m"
            except Exception:
                return "unknown"


    class MainWindow(QMainWindow):
        def __init__(self):
            super().__init__()
            self.setWindowTitle("Dimension Settings")
            self.resize(820, 560)
            tabs = QTabWidget()
            tabs.addTab(HubTab(), "Hub")
            tabs.addTab(WireGuardTab(), "WireGuard")
            tabs.addTab(SystemTab(), "System")
            self.setCentralWidget(tabs)


    app = QApplication(sys.argv)
    app.setApplicationName("Dimension Settings")
    app.setStyleSheet(STYLE)
    MainWindow().show()
    sys.exit(app.exec())
  '';

  appPython = pkgs.python3.withPackages (ps: [ ps.pyqt6 ]);
in
{
  options.dimension.dimensionSettings.enable =
    lib.mkEnableOption "Dimension Settings native app (PyQt6)";

  config = lib.mkIf cfg.enable {
    dimension.apps._settingsPackage =
      pkgs.writeShellScriptBin "dimension-settings" ''
        exec ${appPython}/bin/python3 ${appScript}
      '';

    environment.etc."dimension/edition".text =
      lib.mkDefault config.dimension.edition;
  };
}
