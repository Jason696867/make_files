/**------------------------------------------------------------------
 *  Medtronic MITG R&D
 *  5920 Longbow Drive, Boulder, CO
 *  Copyright (c) 2015 Medtronic
 *  All Rights Reserved.
 *
 *  @file  common/httpserver.h
 *
 *  @brief   General HTTP Server.
 * Add your application server as a parameter to the constructor
 *  -------------------------------------------------------------------*/
#ifndef HTTPSERVER_H
#define HTTPSERVER_H

#include <QString>

#include <QObject>
#include <QThread>
#include <QTcpServer>
#include <QNetworkSession>

#include "../common/httpinterfaceproc.h"

/**
 * @brief The HTTP_RETURN_CODES enum Used to convert return code to string for HTTP response
 * Also, support DEBUG (all codes) and Production (200 and 500 only)
 */
enum HTTP_RETURN_CODES {
    HTTP_200_OK = 200,
    HTTP_400_BAD_REQUEST = 400,
    HTTP_404_NOT_FOUND = 404,
    HTTP_405_METHOD_NOT_ALLOWED = 405,
    HTTP_413_REQUEST_TOO_BIG = 413,
    HTTP_500_SERVER_ERROR = 500,
};

/**
 * @brief General HTTP Server
 */
class HTTPServer : public QObject
{
    Q_OBJECT
public:
    /**
     * @brief Default Constructor.
     * Add your application server as a parameter to the constructor
     *
     * @param[in] procClass interface class for handling commands
     * @param[in] port port to listen on
     * @param[in] parent standard parent object
     */
    HTTPServer(HTTPInterfaceProc* procClass, int32_t port, QObject *parent = 0);

    /**
     * @brief Gets the html file and support files
     * @param[in] code HTTP response code and text
     * @param[in] len length of body of response
     * @param[in] mimeType Content-Type argument
     * @param[out] ba text of response headers
     */
    static void RespHeaders(HTTP_RETURN_CODES code, int32_t len, QString mimeType, QByteArray* ba);

    /** Convert enum HTTP_RETURN_CODES to strings */
    const static QHash<int32_t, QString> s_httpCodeToString;

private slots:
    /**
     * @brief runLinux When the worker thread for the server is started, this method is the where the thread starts.
     */
    void runLinux();

    /**
     * @brief runConnection When a client connects to the server
     * this method is where the processing is done.
     * @param[in] socket accept socket from server so that we have out own
     * socket for the request/response sequence
     */
    void runConnection(int32_t socket);

    /**
     * @brief readHeaders read headers from request
     * @param[in] socket request socket
     * @param[out] buf fill with headers
     * @param[in] bufSize Size of buffer
     *
     * @return success or not
     */
    bool readHeaders(int32_t socket, char* buf, int32_t bufSize);

    /**
     * @brief getContentLength return content length or -1
     * @param[in] socket request socket
     * @param[in] headerLines headers lines
     * @return content length or -1
     */
    int32_t getContentLength(int32_t socket, QStringList &headerLines);

    /**
     * @brief endOfHeaders return the number of bytes for the headers
     *
     * @param buf buffer holding request
     *
     * @return number of bytes for the headers or -1
     */
    int32_t endOfHeaders(char* buf);

private:

    /**
     * @brief writeClose write out response and close socket
     * @param[in] socket accept socket from server so that we have out own
     * socket for the request/response sequence
     * @param[in] body body of response
     * @param[out] ba complete response
     */
    void writeClose(int32_t socket, QByteArray &body, QByteArray &ba);

    /**
     * @brief Gets the html file and support files
     * @param[in] path HTTP path including params
     * @param[in] mimeType Content-Type argument
     * @param[out] ba complete response
     */
    void getFile(QString path, QString mimeType, QByteArray* ba);

    /**
     * @brief getRequestBody gets the request body if any
     *
     * @param[in] socket accept socket from server so that we have out own
     * @param[in] len length of body
     * @param[out] reqBody results go here
     */
    void getRequestBody(int32_t socket, int32_t len, QByteArray *reqBody, QString path, QByteArray &headers,
                        QByteArray &body);

    /**
     * @brief waitForReadReady wait 3 secs for read ready on socket
     * @param socket accept socket from server so that we have out own
     * @return ready = true, NOT ready = false
     */
    int32_t waitForReadReady(int32_t socket);

private:
    /** port the server is listening on */
    int32_t m_port;

    /** Server object */
    QTcpServer* m_tcpServer;

    /** Session object */
    QNetworkSession* m_session;

    /** Stored interface class for processing commands */
    HTTPInterfaceProc* m_procClass;

    /** makes each memID unque */
    static int32_t s_nextId;

    /** Thread for all common procesing */
    QThread m_thread;

    /** Thread list for processing requests */
    QList<QThread*> m_processThreads;

    /** Socket for new connection */
    int32_t m_newSocket;

    /** Hash table of extensions to mime type */
    QHash<QString, QString> m_mimeHash;
};

#endif // HTTPSERVER_H
