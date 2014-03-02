#!/usr/bin/perl

#
#
# 	VCAP-Labs
# 	Version 0.1 Alpha 20140226
#
# 	Feedback and bug reports:
#	Email: hannu@balk.fi
# 	Twitter: twitter.com/hannub
#
#	VCAP-Labs is licensed under MIT license.
#
#	Copyright (c) 2014 Hannu Balk
#
#	The above copyright notice and this permission notice shall be included in all
#	copies or substantial portions of the Software.
#
#	THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
#	IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
#	FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
#	COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
#	IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
#	CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
#	
#

use lib "/usr/lib/perl5/site_perl/5.10.0/";
use strict;
use warnings;
use Term::ReadKey;
use autodie;
#use Path::Class;

while(1)
{
	displayMenu();
	menuLogic();
}

sub displayMenu
{
	clrscr();
	print "\n\nVCAP-Labs\n";
	print "Enviroment level 510\n";
	print "\n(C) Hannu Balk 2014\n";
	open FILE, "LICENSE" or die $!;
	while(<FILE>){print $_;}
	print "\n\nPlease make a selection:\n";
	print "\t(1) Lab 1\n";
	print "\t(2) Lab 2\n";
	print "\t(H) Help\n";
	print "\t(Q) Quit\n";
	print "\n\t-> ";
}

sub clrscr
{
	print "\033[2J";    #clear the screen
	print "\033[0;0H"; #jump to 0,0
}

sub menuLogic
{
        ReadMode 4; 
	my $c = ReadKey(0);
	ReadMode 1;
	print "\n";
	my $s = 0;
	$c = lc($c);
	if($c eq "q"){$s = 1;cleanup();}
	if($c eq "h"){$s = 1;displayHelp();}
	if($c eq "1"){$s = 1;startLab("lab1");}
	if($c eq "2"){$s = 1;startLab("lab2");}
	if($s == 0)
	{
		print "\nInvalid selection.";
		pressEnter();
	}
}

sub displayHelp()
{
	clrscr();
	print "Help\n";

	pressEnter();
};

sub cleanup
{
	clrscr();
	exit 0;
}

sub getConfirm
{
	ReadMode 4;
	my $gc = ReadKey(0);
	ReadMode 1;
	if($gc eq "\n") { return 1;}
	if(lc($gc) eq "y") {return 1;}
	if(lc($gc) eq "n") {return 0;}
	return getConfirm();
}

sub pressEnter
{
	print "\n\nPress ENTER to continue\n\n";
	ReadMode 4;<>; ReadMode 1;
}

sub createConfig
{
	print "\nCreate new configuration [Y\\n]: ";
	my $c = getConfirm();
	if($c eq 0) {return;}
	pressEnter();
}

sub startLab
{
	clrscr();
	my $n = shift();
	do("./labs/".$n.".pl");
	pressEnter();
}
