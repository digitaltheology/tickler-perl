tickler-perl
============

A simple tickler file implemented in Perl, based on the [todo.txt project](https://github.com/ginatrapani/todo.txt-cli) by Gina Trapani.

The data is held in a simple text file, **tickler.txt**, with a simple format, containing an item one-per-line.

**tickler.pl** can add, delete, reschedule (defer) or list current tickling items (or all items) based on command switches at its invocation.

For usage, type:

    tickler.pl -h

The data file is held at a location of the user's choice, based on a config file (**.tickler**) held in the user's home directory.

**tickler.pl** is reasonably well-documented code, so anyone with a basic Perl knowledge should be able to amend it to suit their purposes.

The format of each line of the data file, **tickler.txt**, is as follows:

    YYMMDD DD/MM/YY Text of the item to be tickled

The second field (DD/MM/YY) reflects my location (UK). However, this may be amended in **.tickler**, the configuration file, to reflect the input of other users. (eg. MM/DD/YY or YY/MM/DD).

The format of the config file is also simple, for example:

    # === EDIT FILE LOCATIONS BELOW ===

    # Your tickler.txt directory

    TICKLER_DIR="/home/myhomedirectory/Dropbox/todo"
    TODO_DIR="/home/myhomedirectory/Dropbox/todo"
    DATE_FORMAT="dd/mm/yy"

I hope you have fun playing with this. It suits my workflow as it is, but you may wish to change/amend it to suit your purposes. I also use:

    tickler.pl -ls
    
through Conky (Linux) and Geektool (OS X) to provide a continuous update of what's possibly tickling on my desktops. Integrating it with Dropbox allows usage across a range of computers and OSs.

Have fun!
Paul

