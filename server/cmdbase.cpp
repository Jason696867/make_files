/**------------------------------------------------------------------
 *  Medtronic MITG R&D
 *  5920 Longbow Drive, Boulder, CO
 *  Copyright (c) 2015 Medtronic
 *  All Rights Reserved.
 *
 *  @file  common/cmdbase.cpp
 *
 *  @brief   Command base class to support validate
 *  @details     Validates DBus arguments, number of, type, range
 *  -------------------------------------------------------------------*/
#include <stdarg.h>
#include <QStringList>
#include <QString>

#include "../common/common.h"
#include "../common/cmdbase.h"
#include "../common/exceptionbase.h"
#include "../common/utilities.h"

extern QString g_appName;

CmdBase::CmdBase(QObject *parent) :
    QObject(parent)
{
}

// TODO Uppercase method now that it's public static.
/**
 * @details The first %s in the format string is the class:method. All others refer to arguments
 */
void CmdBase::validateArgs(QString format, QString cmdAndArgs, ...)
{
    // args is the cmdAndArgs string of the DBus request
    va_list vaContext;

    va_start(vaContext, cmdAndArgs);

    QStringList formatArgs = format.split(","); // Expecting something like: "%s,%[0:1]i"
    QStringList cmdAndArgsList = cmdAndArgs.split(","); // Expecting cmdAndArgs DBus string

    QString error = QString("Format number of args(%1) doesn't match args passed(%2) Format: %3, args: %4\n")
                    .arg(formatArgs.size())
                    .arg(cmdAndArgsList.size())
                    .arg(format)
                    .arg(cmdAndArgs);

    GUARD_WITH_POST(formatArgs.size() != cmdAndArgsList.size(), va_end(vaContext);
                    , error);

    for (int32_t i = 0; i < formatArgs.size(); i++)
    {
        QString formatArg = formatArgs.at(i).trimmed();

        error = QString("Bad Format string, no starting percent sign: %1 (i=%2) args: %3")
                .arg(format)
                .arg(i)
                .arg(cmdAndArgs);
        GUARD_WITH_POST(!formatArg.startsWith("%"), va_end(vaContext);
                        , error);

        // remove '%'
        formatArg = formatArg.right(formatArg.length() - 1);


        QStringList vals;
        bool checkRange = false;
        int32_t intLow = 0;
        int32_t intHigh = 0;

        if (formatArg.startsWith("["))   // range [lo,hi] inclusive
        {
            formatArg = formatArg.right(formatArg.length() - 1);

            error = QString("Bad Format string, no ending ] on range: %1 (i=%2) args: %3")
                    .arg(format)
                    .arg(i)
                    .arg(cmdAndArgs);
            GUARD_WITH_POST(formatArg.indexOf("]") < 0, va_end(vaContext);
                            , error);


            QString sRange = formatArg.left(formatArg.indexOf("]"));
            vals = sRange.split(":");

            error = QString("Bad Format string, no low,hi values in range: %1 (i=%2) args: %3")
                    .arg(format)
                    .arg(i)
                    .arg(cmdAndArgs);
            GUARD_WITH_POST(vals.size() != 2, va_end(vaContext);
                            , error);

            intLow = vals.at(0).toInt();
            intHigh = vals.at(1).toInt();
            checkRange = true;
        }

        if      (formatArg.endsWith("s"))   // string
        {
            QString* nextVAStringArg = va_arg(vaContext, QString*);
            *nextVAStringArg = cmdAndArgsList.at(i);
        }
        else if (formatArg.endsWith("i"))   // int
        {
            int32_t* nextVAIntArg = va_arg(vaContext, int32_t*);
            *nextVAIntArg = cmdAndArgsList.at(i).toInt();

            error = QString("Int arg out of range: %1 (i=%2) args: %3")
                    .arg(format)
                    .arg(i)
                    .arg(cmdAndArgs);
            GUARD_WITH_POST((checkRange && ((*nextVAIntArg < intLow) || (*nextVAIntArg > intHigh))), va_end(vaContext);
                            , error);
        }
    }

    va_end(vaContext);
}
