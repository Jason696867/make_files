/**
 * Medtronic MITG R&D
 * 5920 Longbow Drive, Boulder, CO
 * Copyright (c) 2016 Medtronic
 * All Rights Reserved.
 *
 * @file    common/httpserver.cpp
 *
 * @brief    General HTTP Server.
 */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <errno.h>
#include <unistd.h>
#include <fcntl.h>
#include <sys/ioctl.h>

#include <QTcpSocket>

#include "../common/common.h"
#include "../common/exceptionbase.h"
#include "../common/fileio.h"

#include "httpserver.h"

int32_t HTTPServer::s_nextId = 0;

const QHash<int32_t, QString> HTTPServer::s_httpCodeToString
{
    {
        HTTP_200_OK, "200 ok"
    },
    {
        HTTP_400_BAD_REQUEST, "400 Bad Request"
    },
    {
        HTTP_404_NOT_FOUND, "404 Not Found"
    },
    {
        HTTP_405_METHOD_NOT_ALLOWED, "405 Method Not Allowed"
    },
    {
        HTTP_413_REQUEST_TOO_BIG, "413 Request Entity too Large"
    },
    {
        HTTP_500_SERVER_ERROR, "500 Internal Server Error"
    }
};

HTTPServer::HTTPServer(HTTPInterfaceProc* procClass, int32_t port, QObject *parent) :
    QObject(parent)
    , m_port(port)
    , m_procClass(procClass)
    , m_mimeHash {{
        "html", "text/html"
    },
    {
        "js", "application/javascript"
    },
    {
        "css", "text/css"
    },
    {
        "ico", "image/x-icon"
    }}

{
    // Setup the worker thread
    (void)connect(&m_thread,
                  SIGNAL(started()),
                  this,
                  SLOT(runLinux()));

    moveToThread(&m_thread);
    m_thread.start();
}


/**
 * @detail
 */
void HTTPServer::runLinux()
{
    int32_t sockfd;
    socklen_t clilen;
    struct sockaddr_in serv_addr, cli_addr;

    //qDebug() << "runLinux()";

    sockfd = socket(AF_INET, SOCK_STREAM, 0);
    if (sockfd < 0)
    {
        throw EXCEPTION_DEBUG("ERROR opening socket, errno: " + QString::number(errno));
    }

    //allow reuse of port
    int32_t yes = 1;
    if (setsockopt(sockfd, SOL_SOCKET, SO_REUSEADDR, &yes, sizeof(int32_t)) == -1)
    {
        qDebug() << "ERROR setsockopt() SO_REUSEADDR, errno: " << strerror(errno);
        return;
    }

    bzero((char *) &serv_addr, sizeof(serv_addr));
    serv_addr.sin_family = AF_INET;
    serv_addr.sin_addr.s_addr = INADDR_ANY;
    serv_addr.sin_port = htons(m_port);
    if (bind(sockfd, (struct sockaddr *) &serv_addr, sizeof(serv_addr)) < 0)
    {
        throw EXCEPTION_DEBUG("ERROR on binding, errno: " + QString::number(errno));
    }

    qDebug() << "runLinux() start listening(" << m_port << ")...";

    forever {
        listen(sockfd, 5);

        clilen = sizeof(cli_addr);
        int32_t socket = accept(sockfd,
                                (struct sockaddr *) &cli_addr,
                                &clilen);

        //qDebug() << "runLinux() Got Connection...";

        if (socket < 0)
        {
            throw EXCEPTION_DEBUG("ERROR on accept, errno: " + QString::number(errno));
        }
        int32_t flags;
        flags = fcntl(socket, F_GETFL, 0);
        fcntl(socket, F_SETFL, flags | O_NONBLOCK);

        struct timeval timeout;
        timeout.tv_sec = 200;
        timeout.tv_usec = 0;

        setsockopt (socket, SOL_SOCKET, SO_RCVTIMEO, (char *)&timeout, sizeof(timeout));
        setsockopt (socket, SOL_SOCKET, SO_SNDTIMEO, (char *)&timeout, sizeof(timeout));

        runConnection(socket);
    }
    close(sockfd);
}

/**
 * @detail
 */
void HTTPServer::writeClose(int32_t socket, QByteArray &body, QByteArray &ba)
{
    ba.append(body);

    //qDebug() << "Write to socket: \n" << ba.data();

    int32_t offset = 0;
    do
    {
        int32_t len = write(socket, ba.mid(offset).data(), ba.mid(offset).length());
        offset += len;
    }
    while (offset < ba.length());


    if (offset < ba.length())
    {
        qDebug() << "ERROR: Socket write len(" << offset << ") != ba.length(" << ba.length() << ")";
    }
    close(socket);
    //qDebug() << "----Disconnected";
}

/**
 * @details
 */
int32_t HTTPServer::waitForReadReady(int32_t socket)
{
    fd_set read_flags; // the flag sets to be used
    struct timeval waitd;          // the max wait time for an event
    int32_t sel;                      // holds return value for select();

    waitd.tv_sec = 3;
    waitd.tv_usec = 0;
    FD_ZERO(&read_flags);
    FD_SET(socket, &read_flags);

    //qDebug() << "Wait for read ready....";
    sel = select(socket + 1, &read_flags, NULL, NULL, &waitd);
    if (sel == -1)
    {
        qDebug() << "Select() ERROR: " << strerror(errno);
        return -1;
    }
    else if (sel)
    {
        int32_t bytesAvailable = 0;
        ioctl(socket, FIONREAD, &bytesAvailable);
        return bytesAvailable;
    }
    else
    {
        qDebug() << "Select returned Timeout.";
        return 0;
    }
}

/**
 * @details
 */
void HTTPServer::getRequestBody(int32_t socket,
                                int32_t len,
                                QByteArray *reqBody,
                                QString path,
                                QByteArray &headers,
                                QByteArray &body)
{
    if (len > 0)
    {
        qDebug() << "Content-Length: " << len;
    }
    int32_t byteCount = 0;

    forever {
        int32_t n = 0;
        int32_t bytesAvailable = 0;

        if (len > 0)
        {
            //qDebug() << "Waiting...";
            bytesAvailable = waitForReadReady(socket);
        }

        if (bytesAvailable == -1)
        {
            //qDebug() << "Select was interrupted, so try again";
            continue;
        }

        if ((bytesAvailable == 0) || (len <= 0))
        {
            //qDebug() << "No bytes left, Done reading.";
            if (m_procClass)
            {
                reqBody->clear();
                m_procClass->processCmd(path, reqBody, &headers, &body, true);
            }

            return;
        }

        char* buf = new char[bytesAvailable];
        //qDebug() << bytesAvailable << " bytes ready";

        n = recv(socket, buf, bytesAvailable, MSG_DONTWAIT);
        //qDebug() << "Read " << n << " bytes";

        if (n < 0)
        {
            qDebug() << "ERROR: recv(): " << strerror(errno);
            delete[] buf;
            return;
        }
        byteCount += n;

        if (m_procClass)
        {
            reqBody->clear();
            reqBody->append(buf, n);
            m_procClass->processCmd(path, reqBody, &headers, &body, byteCount >= len);
            if (byteCount >= len)
            {
                break;
            }
        }

        delete[] buf;
        //qDebug() << "byteCount: " << byteCount;
    }
}

/**
 * @detail
 */
int32_t HTTPServer::endOfHeaders(char* buf)
{
    int32_t pos = -1;

    for (int i = 4; buf[i]; i++)
    {
        if (strncmp(&buf[i - 4], "\r\n\r\n", 4) == 0)
        {
            pos = i;
            //qDebug() << "Found \\r\\n\\r\\n at: " << pos;
            break;
        }
    }

    return pos;
}

/**
 * @detail
 */
bool HTTPServer::readHeaders(int32_t socket, char* buf, int32_t bufSize)
{
    QByteArray headers;
    QString mimeType = "text/plain";
    QByteArray body;

    // Read request headers
    // ..Read until \r\n\r\n
    char* bufPos = buf;
    int32_t pos = -1;
    int32_t available = waitForReadReady(socket);

    //qDebug() << "runConnection() available bytes: " << available;

    if (!available)
    {
        return false;
    }

    while (available > 0)
    {
        int32_t len = 0;
        len = recv(socket, bufPos, bufSize - (bufPos - buf), MSG_PEEK);
        bufPos[len] = 0;
        pos = endOfHeaders(buf);
        //qDebug() << "Read Headers: len: " << len << "\n" << bufPos;

        if (pos == -1)
        {
            bufPos += len;
            available = waitForReadReady(socket);
        }
        else
        {
            break;
        }
    }

    if ((pos == -1) && (strlen(buf) < 20))
    {
        qDebug() << "ERROR: Couldn't find \\r\\n\\r\\n, Throwing message away buf:\n" << buf;
        body.append("<html><body><h1>Error: Illegal request, couldn't find double ret, lf</h1></body></html>");
        RespHeaders(HTTP_500_SERVER_ERROR, body.length(), mimeType, &headers);
        writeClose(socket, body, headers);
        return false;
    }
    else if (pos == -1)
    {
        pos = strlen(buf);
    }

    int32_t len = recv(socket, buf, pos, 0);
    buf[len] = 0;
    //qDebug() << "Read Headers: len: " << len << "\n" << buf;

    return true;
}

/**
 * @detail
 */
int32_t HTTPServer::getContentLength(int32_t socket, QStringList &headerLines)
{
    QByteArray body;
    QByteArray headers;
    QString mimeType = "text/plain";

    // ..Find Content-Length header and get size of body
    int32_t contentLen = -1;

    for (QString header : headerLines)
    {
        header = header.trimmed();
        if (header.startsWith("content-length", Qt::CaseInsensitive))
        {
            QStringList parts = header.split(":");
            if (parts.length() != 2)
            {
                body.append(
                    "<html><body><h1>Error: Illegal request, Content-Length malformed</h1></body></html>");
                RespHeaders(HTTP_500_SERVER_ERROR, body.length(), mimeType, &headers);
                writeClose(socket, body, headers);
                return 0;
            }

            contentLen = parts[1].trimmed().toInt();
            break;
        }
    }

    return contentLen;
}

/**
 * @detail
 */
void HTTPServer::runConnection(int32_t socket)
{
    QByteArray headers;
    QString mimeType = "text/plain";
    QByteArray body;
    QByteArray reqBody;

    // Set socket for big request bodies
    int optval = 1;

    if (setsockopt(socket, SOL_SOCKET, SO_KEEPALIVE, &optval, sizeof(optval)) < 0)
    {
        qDebug() << "ERROR: Cannot set keepalive on socket!";
    }

    int flags = fcntl(socket, F_GETFL, 0);
    if (flags >= 0)
    {
        if (fcntl(socket, F_SETFL, flags & ~O_NONBLOCK))
        {
            qDebug() << "ERROR: Cannot set non-blocking on socket!";
        }
    }
    else
    {
        qDebug() << "ERROR: Cannot set non-blocking on socket! Cannot set flags.";
    }


    // Read request headers
    char buf[8000];
    if (!readHeaders(socket, buf, sizeof(buf)))
    {
        return;
    }

    QString rawHeaders(buf);
    QStringList headerLines = rawHeaders.split("\r\n");
    int32_t contentLen = getContentLength(socket, headerLines);
    //qDebug() << "Request: " << headerLines[0];

    headers.append(rawHeaders);
    headers.append("\r\n\r\n");

    // GET /index.html HTTP/1.1
    // GET /path HTTP/1.1
    // POST /run HTTP/1.1
    QStringList parts = headerLines[0].split(" ");
    QString path = parts[1];

    // Check for a file request
    path = (path.startsWith("/")) ? path.right(path.length() - 1) : path; // remove '/' in front
    QStringList pathParts = path.split(".");

    if (pathParts.size() > 1)
    {
        // Path has an extension like .html, .js etc.
        QString ext = pathParts[pathParts.size() - 1];
        if (m_mimeHash.contains(ext.toLower()))
        {
            mimeType = m_mimeHash[ext.toLower()];
        }

        getFile(path, mimeType, &headers);
    }
    else
    {
        headers.clear();
        getRequestBody(socket, contentLen, &reqBody, path, headers, body);
    }
    writeClose(socket, body, headers);
}

/**
 * @detail
 */
void HTTPServer::getFile(QString path, QString mimeType, QByteArray* ba)
{
    QFile file("assets/pages/" + path);

    if (!file.open(QIODevice::ReadOnly))
    {
        RespHeaders(HTTP_404_NOT_FOUND, 0, "text/html", ba);
        qDebug() << "getFile(" << path << ") Error: Open failed";
        return;
    }

    QByteArray contents = file.readAll();
    file.close();

    qDebug() << "getFile(" << path << ") len=" << contents.size();

    RespHeaders(HTTP_200_OK, contents.size(), mimeType, ba);
    ba->append(contents);
}

/**
 * @brief central place to put response headers
 * (I would use detail, but Doxygen didn't like it)
 */
void HTTPServer::RespHeaders(HTTP_RETURN_CODES code, int32_t len, QString mimeType, QByteArray* ba)
{
#ifdef DEBUG
    QString strCode = s_httpCodeToString[code];
#else
    QString strCode = s_httpCodeToString[(code != HTTP_200_OK) ? HTTP_500_SERVER_ERROR : HTTP_200_OK];
#endif

    ba->clear();
    ba->append("HTTP/1.1 " + strCode + "\r\n");

    ba->append("Content-Length: " + QString::number(len) + "\r\n");

    ba->append("Content-Type: " + mimeType + "\r\n");

    ba->append("\r\n");
}
