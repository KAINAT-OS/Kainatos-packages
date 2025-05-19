#include "kio_mydisks.h"

MyDisksSlave::MyDisksSlave(const QByteArray &pool, const QByteArray &app)
    : ForwardingSlaveBase("mydisks", pool, app) {}

QUrl MyDisksSlave::rewriteUrl(const QUrl &url) {
    QString path = url.path();
    return QUrl::fromLocalFile(QDir::homePath() + "/.disks" + path);
}
