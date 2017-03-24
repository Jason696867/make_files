/**------------------------------------------------------------------
 *  Medtronic MITG R&D
 *  5920 Longbow Drive, Boulder, CO
 *  Copyright (c) 2015 Medtronic
 *  All Rights Reserved.
 *
 *  @file  common/cmdbase.h
 *
 *  @brief   Validate number of args, arg types, and ranges
 *  @details     Validate number of args, arg types, and ranges
 *  -------------------------------------------------------------------*/
#ifndef CMDBASE_H
#define CMDBASE_H

#include <QObject>

/**
 * @brief Validation support for command arguments
 */
class CmdBase : public QObject
{
    Q_OBJECT
public:
    /**
     * @brief Contructor for class,
     */
    explicit CmdBase(QObject *parent = 0);

    /**
     * @brief Validate Arguments in DBus command
     * @param[in] format %s QString, %i int, %f float, %d double, %[-1,10]i check range
     *            NOTE: the first %s is the class:method. All others refer to arguments
     *
     * @param[in] cmdAndArgs arg to be validated
     * @throws Fmt number of args(%d) doesn't match args passed(%d) fmt: %s, args: %s
     * @throws Bad fmt string, no starting %: %s (i=%d) args: %s
     * @throws Bad fmt string, no ending ] on range: %s (i=%d) args: %s
     * @throws Bad fmt string, no low,hi values in range: %s (i=%d) args: %s
     * @throws Int arg out of range: %s (i=%d) args: %s
     */
    static void validateArgs(QString format,
                             QString cmdAndArgs,
                             ...);

signals:

public slots:
};

#endif // CMDBASE_H
