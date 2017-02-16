#!/usr/bin/env python3
#
# Medtronic MITG R&D
# 5920 Longbow Drive, Boulder, CO
# Copyright (c) 2016 Medtronic
# All Rights Reserved.
#
# @file  bin/generate_launch_config.py
#
# Generate the applauncher XML configuration on stdout.

import os.path
import sys


def begin_xml():
    """
    Begin the XML output.
    """

    print('<?xml version="1.0" encoding="UTF-8"?>')
    print('<applications>')


def end_xml():
    """
    End the XML output.
    """

    print('</applications>')


def print_application_xml(bin_path, application_name):
    """
    Add an application and its hash code.

    """

    filepath = os.path.join(bin_path, application_name)

    if not os.path.isfile(filepath):
        sys.exit('ERROR: file not found: {filepath}'.format(
            filepath=filepath))

    if application_name == 'test':
        app_type = 'test'
    else:
        app_type = 'application'

    print("""  <application>
    <appName>{app}</appName>
    <path>{app}</path>
    <type>{app_type}</type>
  </application>
""".format(app=application_name, app_type=app_type))

def main(args):
    # The location of the application binaries is passed
    # as first command-line parameter.
    bin_path = args[1]

    applications = [
        arg
        for arg in args[2:]
    ]

    begin_xml()
    for app in applications:
        print_application_xml(bin_path, app)
    end_xml()


if __name__ == '__main__':
    main(sys.argv)
