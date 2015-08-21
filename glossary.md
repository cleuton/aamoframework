# Introduction #

AAMO has some concepts which allows the programmer to abstract from any particular implementation.


# Screen #

An AAMO application is made of screens. A screen is what the user see in the device at some point.

A screen is composed by Controls and Scripts.

AAMO screens are defined in XML files. The first screen (id 01) is defined in the "ui.xml" file, and is mandatory. Other screens are defined in xml files named according to the rule:

"ui`_<screen id>`.xml"

And they must be in the same folder as the "ui.xml" file.


# Control #

A control is the unity of user interaction, like a TextBox, Label, Button etc.

You can assign controls to screens in the XML file.

AAMO have definitions for some common controls, but allows you to add more controls by defining them in a configuration file.

A control may have some scripts attached to common events.

# Script #

A script is a piece of Lua code, inside a file with ".lua" extension. Scripts are attached to Screen and Control events.

To attach a script to an event, you inform its name (without extension) in the XML file.

AAMO will support "library" scripts in future implementations. Library scripts are utilitary functions, not attached to events, that can be invoked from the Event Scripts or other Library Scripts.