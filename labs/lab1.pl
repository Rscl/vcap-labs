#!/usr/bin/perl
use strict;
use warnings;
use VMware::VIRuntime;
use Term::ReadKey;


print "\nLab 1\n";
print "Level: Very easy\n";
print "Requirements:\n\t1 ESXi 5.1 host\n";
print "\nDescription:\nTest lab. No real content (yet).\n\n";

print "Enviroment configuration:\n\n";
print "vCenter server: "; 
my $server = <>;
chomp($server);
print "Username: ";
my $username = <>;
chomp($username);
print "Password: ";
ReadMode 4;
my $password = <>;
chomp($password);
ReadMode 1;
print "\n";
my $url = "https://$server/sdk/vimService";

printf "Using following settings:\nServer url: $url\nUsername: $username\nPassword: <masked>\n";

my $vim = Vim->new(service_url => $url);
$vim->login(user_name => $username, password => $password);
#$vim->save_session(".lab1.session");

#Fetch VM's
print "List of VM's:\n";
my $vm_views = $vim->find_entity_views(view_type => 'VirtualMachine');
foreach my $vm (@$vm_views) {
	#print $vm . " - " . $vm->name . "\n";
	printVM($vm);	
}
$vim->logout();

sub printVM
{
	my $vm = shift;
	print $vm->name . "\n";
	print $vm . "\n";
}
