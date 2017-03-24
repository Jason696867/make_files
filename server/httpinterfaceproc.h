/**------------------------------------------------------------------
 *  Medtronic MITG R&D
 *  5920 Longbow Drive, Boulder, CO
 *  Copyright (c) 2015 Medtronic
 *  All Rights Reserved.
 *
 *  @file  common/httpinterfaceproc.h
 *
 *  @brief   interface class for processing commands
 *  -------------------------------------------------------------------*/
#ifndef HTTPINTERFACEPROC_H
#define HTTPINTERFACEPROC_H

#include <QObject>
#include <QString>

/**
 * @brief interface class for processing commands
 */
class HTTPInterfaceProc : public QObject
{
    Q_OBJECT
public:

    /**
     * @brief HTTPInterfaceProc constructor
     */
    explicit HTTPInterfaceProc(QObject* parent);

    virtual ~HTTPInterfaceProc();

    //TODO: return void here and have processCmd call RespHeaders()
    /**
     * @brief processCmd interface for processing commands
     * @param[in] path HTTP path including params
     * @param[in] reqBody If POST than body of POST
     * @param[out] headers headers of response
     * @param[out] body body of response
     * @param[in] aRequestComplete to enable multiple calls to processCmd for a single request
     */
    virtual void processCmd(QString path, QByteArray* reqBody, QByteArray* headers, QByteArray* body,
                            bool aRequestComplete = true ) = 0;

public slots:

    /**
     * @brief Accept timer timed out
     */
    virtual void timesUp(){
    }
};

#endif // HTTPINTERFACEPROC_H
