#!/usr/bin/perl
#
# tickler.pl - runs a tickler file system, as suggested by David Allen, in his book _Getting things done: how to achieve
# stress-free productivity_
#
# Copyright 2007, Paul Roberts <digitaltheology@gmail.com>
#
#  This program is free software: you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published by
#  the Free Software Foundation, either version 3 of the License, or
#  (at your option) any later version.
#
#  This program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
#
#  You should have received a copy of the GNU General Public License
#  along with this program, in the file entitled COPYING.  If not, see <http://www.gnu.org/licenses/>.


my $tickler_version = "version 0.2";

use POSIX qw(strftime);
use Tie::File;
use strict;

my $homedir;
my $dottickler;
my $entrydate;
my $logdate;
my $caldate;
my $ticklerfilename;
my $todofilename;
my $the_entry;
my $the_dated_entry;
my $initial_cmd;
my $defer_value;
my $defer_unit;
my $deferred_time;
my $defer_day;
my $defer_month;
my $defer_year;
my $now_logdate;
my $entry_date;
my $linecounter;
my $delete_line_number;
my $file_length;
my $todo_line_number;
my $todo_insert_text;
my $defer_line_number;
my $defer_text;

my $date_format;
my $date_delimiter;
my $date_field1;
my $date_field2;
my $date_field3;


my @cfgfile;
my @cfgloctag;
my @ticklerfile;
my @todofile;


$homedir = `echo ~`;
chop($homedir);
$dottickler = $homedir . "/\.tickler";


environ_check();

				# Look at the first parameter, check its command status (and that it is a command).
$initial_cmd = $ARGV[0];

				# Evaluate the command in the first parameter and execute
command_check();

				# To be frank, you should never be returning here, there are 'exits' elsewhere.
exit 0;


############## SUBROUTINES #################



# Subroutine environ_check: checks the install environment is correct. Opens the tickler file tied to @ticklerfile
#
#
#
sub environ_check {

	# a) Is .tickler in existence? If so, tie it to the array @cfgfile.

	if (-e $dottickler && -r _) {
		tie @cfgfile, 'Tie::File', $dottickler or die "Sorry, could not open $dottickler for some reason, stopped";
	} else {
		die "Sorry, the .tickler config file does not exist in the user's directory, or is unreadable by this process, stopped";
	}

	# b) Locate the line TICKLER_DIR giving location of tickler file
	foreach (@cfgfile) {
		if (/^TICKLER_DIR\b\w*=\w*/) {
			@cfgloctag = split(/"/);
			$ticklerfilename = $cfgloctag[1] . "/tickler.txt";			# Assign full pathname of journal.txt file
		}
	}
	
	# c) Check the sanity of the TICKLER_DIR directive
	unless (@cfgloctag) {
		die "Sorry, the location of your tickler file could not be read from $dottickler, stopped";
	}

	# d) Check the ticker file exists, if not, offer to create it.  (Die if this is refused.) Open/Create the tickler file, die if this fails.
	unless (-e $ticklerfilename) {
		print "No file called 'tickler.txt' exists in " . $cfgloctag[1] . " - Do you want me to create one? (y/n)";
		if (<STDIN> =~ /^y/i) {
			tie @ticklerfile, 'Tie::File', $ticklerfilename or die "Sorry, I'm having problems creating tickler.txt - check you have permissions set correctly, stopped";
			print "Tickler file 'tickler.txt' has been created.\n";
		} else {
			die "I cannot proceed without a valid tickler.txt file. Stopped";
		}
	} else {
		tie @ticklerfile, 'Tie::File', $ticklerfilename or die "Sorry, I'm having problems accessing tickler.txt - check you have permissions set correctly, stopped";
	}

	# e) Locate the line TODO_DIR giving location of todo file
	foreach (@cfgfile) {
		if (/^TODO_DIR\b\w*=\w*/) {
			@cfgloctag = split(/"/);
			$todofilename = $cfgloctag[1] . "/todo.txt";			# Assign full pathname of journal.txt file
		}
	}

	# f) Check the sanity of the TODO_DIR directive
	unless (@cfgloctag) {
		die "Sorry, the location of your tickler file could not be read from $dottickler, stopped";
	}


	# g) Check the todo file exists, if not, offer to create it.  (Die if this is refused.) Open/Create the todo file, die if this fails.
	unless (-e $todofilename) {
		print "No file called 'todo.txt' exists in " . $cfgloctag[1] . " - Do you want me to create one? (y/n)";
		if (<STDIN> =~ /^y/i) {
			tie @todofile, 'Tie::File', $todofilename or die "Sorry, I'm having problems creating todo.txt - check you have permissions set correctly, stopped";
			print "Todo file 'todo.txt' has been created.\n";
		} else {
			die "I cannot proceed without a valid todo.txt file. Stopped";
		}
	} else {
		tie @todofile, 'Tie::File', $todofilename or die "Sorry, I'm having problems accessing todo.txt - check you have permissions set correctly, stopped";
	}

	# h) Locate the line DATE_FORMAT giving format of date string to be used in commands and file reporting
	foreach (@cfgfile) {
		if (/^DATE_FORMAT\b\w*=\w*/) {
			@cfgloctag = split(/"/);
			$date_format = $cfgloctag[1];			# Assign date format string
		}
	}

	# i) Work out the date delimiter

	$date_delimiter = substr($date_format, 2, 1);


}




# Subroutine command_check: checks the first parameter from the command line, then executes the appropriate subroutine
#
#
#
sub command_check {

	unless (defined $initial_cmd) {			# No parameter: run tickle_report (output the due tickles)
		help_user();
		exit 0;
	}

	if ($initial_cmd =~ /^-h/) {
		help_user();
		exit 0;
	}

	if ($initial_cmd =~ /^ls$|^list$/) {
		tickle_report();
		exit 0;
	}

	if ($initial_cmd =~ /add$/) {
		add_tickler();
		exit 0;
	}

	if ($initial_cmd =~ /^del|^rm/) {
		tickle_delete();
		exit 0;
	}

	if ($initial_cmd =~ /^todo/) {
		tickle_todo();
		exit 0;
	}

	if ($initial_cmd =~ /^defer/) {
		tickle_defer();
		exit 0;
	}

	if ($initial_cmd =~ /^listall$/) {
		tickle_full_list();
		exit 0;
	}

	if ($initial_cmd =~ /^-[Vv]$/) {
		print "\n tickler.pl " . $tickler_version . "\n\n";
		exit 0;
	}

							# Otherwise, the command must be wrong.
	print "Illegal command '" . $initial_cmd . "'. Usage: tickler.pl action [deferral_value] [deferral_unit] [message]\n";
	exit 1;
}

# Subroutine add_tickler: the main ADD process
#
#
#
sub add_tickler {					

					#Look at the second parameter. For the 'add' command, it should either be a numeric defer value, or a raw date.
	shift @ARGV;
	$defer_value = $ARGV[0];

					# Check to see if user wishes to enter the raw deferral date
	if ($defer_value =~ /[\d]+($date_delimiter)[\d]+/) {
		rawdate_process();
	}

					# Otherwise, user is using relative deferral method
	unless (defined $logdate) {
		relativedate_process();
	}

					#Shift @ARGV to get the tickler entry to be in the tickler (ie. the last parameter in the 'add' command).
	shift @ARGV;

					# Parse the rest of the command line for the text of the tickler entry.
					# (This will only work once the real commands have been 'shifted' off @ARGV)
	foreach (@ARGV) {
		$the_entry .= $_ . " ";
	}

	chop($the_entry);		# Removes a redundant space at the end.

					# A quick sanity check on the tickler entry
	unless ($the_entry =~ /[\w]/) {
		print "Sorry, the tickler entry you gave looks a bit odd.  I won't add it.  It needs at least one alphanumeric character to look OK to me.\n";
		exit 1;
	}



	$the_dated_entry = $logdate . " " . $entrydate . " " . $the_entry;		# Prepend numerical date serial and plain language date to the entry

	push(@ticklerfile,$the_dated_entry);					# Write prepended entry into the tickler file
}


# Subroutine rawdate_process: process direct date deferral contained in $defer_value, setting value of $logdate.
#
#
#
sub rawdate_process {

	split(/$date_delimiter/,$defer_value,3);	# Break out the day/month/year values

	$date_field1 = $_[0];
	$date_field2 = $_[1];
	$date_field3 = $_[2];

	SWITCH_RAWDATE: {				# Do international date format check from .tickler
		
		if ($date_format =~ /^[dD]+($date_delimiter)[mM]+($date_delimiter)[yY]+/) {	# Common European Format: dd/mm/yy
			$defer_day = $date_field1;
			$defer_month = $date_field2;
			$defer_year = $date_field3;
			last SWITCH_RAWDATE;
		}
	
		if ($date_format =~ /^[mM]+($date_delimiter)[dD]+($date_delimiter)[yY]+/) {	# Common American Format: mm/dd/yy
			$defer_month = $date_field1;
			$defer_day = $date_field2;
			$defer_year = $date_field3;
			last SWITCH_RAWDATE;
		}
	
		if ($date_format =~ /^[yY]+($date_delimiter)[dD]+($date_delimiter)[yY]+/) {	# Common Japanese Format: yy/mm/dd
			$defer_year = $date_field1;
			$defer_month = $date_field2;
			$defer_day = $date_field3;
			last SWITCH_RAWDATE;
		}
	
		print "Sorry, but I do not understand the date format set in your .tickler file.\n";
		exit 1;	
	
	}

	unless (($defer_day =~ /^[0-9]{1,2}$/) && ($defer_month =~ /^[0-9]{1,2}$/)) {	# Check that both day and month contain between 1 and 2 digits
		print "Sorry, but the date specified is incorrect in some way.\n";
		exit 1;
	} 

	unless ($defer_year =~ /\d{2,4}/) {		# This catches lazy Europeans and American doing dd/mm or mm/dd format.
	
		if ($defer_month <= (strftime "%m", localtime)) {

				if ($defer_day < (strftime "%d", localtime)) {
					$defer_year = (strftime "%Y", localtime) + 1;
				}
			}
		else {
			$defer_year = strftime "%Y", localtime;
		} 

	}

	if ((length($defer_year) == 3) || length($defer_year) > 4) {	# If the year value is 3 digit, 5 digits or longer in length, then it's an error
		print "Sorry, but I'm unclear about the year you have specified.\n";
		exit 1;
	}

	if ($defer_year < 100) {		# If the year is a two-digit shorthand, add the millennium (
		$defer_year = $defer_year + 2000;
	}

	if (length($defer_month) < 2) {		# Add a leading zero if month is a single digit
		$defer_month = "0" . $defer_month;
	}

	if (length($defer_day) < 2) {		# Add a leading zero if day is a single digit
		$defer_day = "0" . $defer_day;
	}

	if (($defer_day < 1) || ($defer_month < 1) || ($defer_year < 1)) { 	# More sanity checking: day, month or year value is zero or negative
		print "Sorry, but the value given in this date is incorrect.\n";
		exit 1;
	}

	SWITCH_RAWDATE3: {		# Basic day values sanity checking based on month: 30 days hath September, etc...

		if (($defer_month == 9)||($defer_month == 4)||($defer_month == 6)||($defer_month == 11)) {
			unless ($defer_day <= 30) {
				print "Sorry, but you entered an impossible day for that month.\n";
				exit 1;
			}
			last SWITCH_RAWDATE3;
		}

		if (($defer_month == 1)||($defer_month == 3)||($defer_month == 5)||($defer_month == 7)||($defer_month == 8)||($defer_month == 10)||($defer_month == 12)) {
			unless ($defer_day <= 31) {
				print "Sorry, but you entered an impossible day for that month.\n";
				exit 1;
			}
			last SWITCH_RAWDATE3;
		}

		if ($defer_month == 2) {
			unless ($defer_day <= 29) {
				print "Sorry, but you entered an impossible day for that month.\n";
				exit 1;
			}
			last SWITCH_RAWDATE3;
		}

		if ($defer_month > 12) {
			print "Sorry, but you entered an impossible month number.\n";
			exit 1;
			}
			last SWITCH_RAWDATE3;

	}

	$logdate = $defer_year . $defer_month . $defer_day;			# Construct $logdate: a date-related sortable tag

	SWITCH_RAWDATE2: {					# Construct $entrydate: a human-readable date, based on local DATE_FORMAT
		
		if ($date_format =~ /^[dD]+($date_delimiter)[mM]+($date_delimiter)[yY]+/) {	# Common European Format: dd/mm/yy
			$entrydate = $defer_day . $date_delimiter . $defer_month . $date_delimiter . $defer_year;	# a human-readable entry date
			last SWITCH_RAWDATE2;
		}
	
		if ($date_format =~ /^[mM]+($date_delimiter)[dD]+($date_delimiter)[yY]+/) {	# Common American Format: mm/dd/yy
			$entrydate = $defer_month . $date_delimiter . $defer_day . $date_delimiter . $defer_year;	# a 
			last SWITCH_RAWDATE2;
		}
	
		if ($date_format =~ /^[yY]+($date_delimiter)[mM]+($date_delimiter)[Dd]+/) {	# Common Japanese Format: yy/mm/dd
			$entrydate = $defer_year . $date_delimiter . $defer_month . $date_delimiter . $defer_day;	# a 
			last SWITCH_RAWDATE2;
		}
	
		print "Sorry, but I do not understand the date format set in your .tickler file.\n";
		exit 1;	
	
	}



}


# Subroutine relativedate_process: process direct date deferral contained in $defer_value, setting value of $logdate.
#
# WARNING: This subroutine shifts the @ARGV array in search of the $defer_unit.
#
sub relativedate_process {

	unless ($defer_value =~ /(\d){1,3}/) {
		print "Non-numeric or missing deferral value.\n";
		exit 1;
	} 

	shift @ARGV;
	$defer_unit = $ARGV[0];

	unless ($defer_unit =~ /day|week|month|year/) {
		print "Incorrect or missing deferral value. Usage: tickler action [deferral_value] [deferral_unit] [message]\n";
		exit 1;
	}

	if ($defer_unit =~ /day/) {		# Plural "days" will also match
		$deferred_time = (time) + ($defer_value * 24 * 60 * 60);
	}

	if ($defer_unit =~ /week/) {		# Plural "weeks" will also match
		$deferred_time = (time) + ($defer_value * 7 * 24 * 60 * 60);
	}

	if ($defer_unit =~ /month/) {		# Plural "months" will also match
		$deferred_time = (time) + ($defer_value * 30 * 24 * 60 * 60);	#I know, this is a bug! But it's an easy kludge for now!
	}

	if ($defer_unit =~ /year/) {		# Plural "years" will also match
		$deferred_time = (time) + ($defer_value * 365 * 24 * 60 * 60);		#I know, this is a bug! But it's an easy kludge for now!
	}	

	$logdate = strftime "%Y%m%d", localtime($deferred_time);			# Construct $logdate: a date-related sortable tag, increments naturally by seconds


	SWITCH_RELATIVEDATE: {		# Construct $entrydate: a human-readable date, based on local DATE_FORMAT

		if ($date_format =~ /^[dD]+($date_delimiter)[mM]+($date_delimiter)[yY]+/) {	# Common European Format: dd/mm/yy
			$entrydate = strftime "%d$date_delimiter%m$date_delimiter%Y", localtime($deferred_time);			# a human-readable entry date
			last SWITCH_RELATIVEDATE;
		}
	
		if ($date_format =~ /^[mM]+($date_delimiter)[dD]+($date_delimiter)[yY]+/) {	# Common American Format: mm/dd/yy
			$entrydate = strftime "%m$date_delimiter%d$date_delimiter%Y", localtime($deferred_time);			# a human-readable entry date
			last SWITCH_RELATIVEDATE;
		}
	
		if ($date_format =~ /^[yY]+($date_delimiter)[mM]+($date_delimiter)[Dd]+/) {	# Common Japanese Format: yy/mm/dd
			$entrydate = strftime "%Y$date_delimiter%m$date_delimiter%d", localtime($deferred_time);			# a human-readable entry date
			last SWITCH_RELATIVEDATE;
		}
	
	}


}

sub tickle_report {											# Reports tickles with dates today and earlier

	$now_logdate = strftime "%Y%m%d", localtime(time); 						# Current date in logdate format
	$linecounter = 0;

	foreach (@ticklerfile) {

		++$linecounter;							# Keep track of the lines in the file

		($entry_date) = (/([\d]+)/);					# Match the first field in the line (logdate)
	
		if ($entry_date <= $now_logdate) {
			print $linecounter . " ";
			print $' . "\n";
		}
	}
}

sub tickle_full_list {								# Reports tickles with dates today and earlier

	$linecounter = 0;

	foreach (@ticklerfile) {

		++$linecounter;							# Keep track of the lines in the file
		print $linecounter . " ";
		print $_ . "\n";

	}
}


sub tickle_delete {											# Deletes the specified line-number of tickle file

	shift @ARGV;
	$delete_line_number = $ARGV[0];

	unless ($delete_line_number =~ /[\d]+/) {	# Line number sanity check 1: is it a number?
		print "Incorrect value given for line number to be deleted.\n";
		exit 1;
	}

	if ($delete_line_number > @ticklerfile) {	# Line number sanity check 2: is it too big?
		print "Incorrect value given for line number to be deleted.\n";
		exit 1;
	}

	splice @ticklerfile,($delete_line_number - 1),1;

}

sub tickle_todo {

	shift @ARGV;
	$todo_line_number = $ARGV[0];

	unless ($todo_line_number =~ /[\d]+/) {		# Line number sanity check 1: is it a number?
		print "Incorrect value given for line number to be converted to a todo.\n";
		exit 1;
	}

	if ($todo_line_number > @ticklerfile) {		# Line number sanity check 2: is it too big?
		print "Incorrect value given for line number to be converted to a todo.\n";
		exit 1;
	}

	$todo_insert_text = $ticklerfile[$todo_line_number - 1];	# Get the required line from @ticklerfile
	$todo_insert_text =~ /^[\d]+ [\d]+($date_delimiter)[\d]+($date_delimiter)[\d]+ /;	# Match the two date fields
	$todo_insert_text = $';						# Re-write, minus the date fields
	push @todofile,$todo_insert_text;				# Write the required line to the end of todo.txt
	splice @ticklerfile,($todo_line_number - 1),1;			# Delete the line from tickler.txt

}

sub tickle_defer {					# Defers LINENUMBER according to the same pattern as ADD

	shift @ARGV;
	$defer_line_number = $ARGV[0];


	unless ($defer_line_number =~ /[\d]+/) {	# Line number sanity check 1: is it a number?
		print "Incorrect value given for line number to be deferred.\n";
		exit 1;
	}

	if ($defer_line_number > @ticklerfile) {	# Line number sanity check 2: is it too big?
		print "Incorrect value given for line number to be deferred.\n";
		exit 1;
	}

					#Look at the third parameter. For the 'defer' command, it should either be a numeric defer value, or a raw date.
	shift @ARGV;
	$defer_value = $ARGV[0];



					# Check to see if user wishes to enter the raw deferral date
	if ($defer_value =~ /[\d]+($date_delimiter)[\d]+/) {
		rawdate_process();
	}

					# Otherwise, user is using relative deferral method
	unless (defined $logdate) {
		relativedate_process();
	}

	$defer_text = $ticklerfile[$defer_line_number - 1];	# Get the required line from @ticklerfile
	$defer_text =~ /^[\d]+ [\d]+($date_delimiter)[\d]+($date_delimiter)[\d]+ /;		# Match the two date fields
	$defer_text = $';					# Re-write, minus the date fields

	$defer_text = $logdate . " " . $entrydate . " " . $defer_text;			# Prepend numerical date serial and plain language date to the entry

	$ticklerfile[($defer_line_number - 1)] = $defer_text;

}


sub help_user {

	print "\ntickle.pl has the following commands:\n
	add <absolute-date> <message> - adds <message> to the tickle file, to tickle at <absolute-date>\n
	add <number> <days|weeks|months|years> <message> - adds message to the tickle file, to tickle at <number> days, weeks, months or years\n
	defer <line-number> <absolute-date> - Defer message at line <line-number> to <absolute-date>\n
	defer <line-number> <number> <days|weeks|months|years> - Defer message at line <line-number> by <number> days|weeks|months|years (from today)\n
	listall - lists all messages in the tickler file - including those still deferred\n
	ls - list the messages currently tickling - ie. due today or earlier\n
	todo <line-number> - move the message at line <line-number> to the todo.txt list\n
	Note: The format of absolute dates are specified by the variable DATE_FORMAT in the .tickler file.\n
"

}
