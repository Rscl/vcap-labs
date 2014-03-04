#!/usr/bin/perl
use strict;
use warnings;
use VMware::VIRuntime;
use Data::Dumper;
use Term::ReadKey;

my $vm_name = "VCAP Labs L1VM1";
my $vm_cpu_count = 1; # Set vm to use one vCPU
my $vm_mem_size = 256; # Set vm mem size to 256 Mb
my $vm_disk_size = 512; # VM disk size

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

printf "\nUsing following settings:\nServer url: $url\n";

my $vim = Vim->new(service_url => $url);
$vim->login(user_name => $username, password => $password);
#$vim->save_session(".lab1.session");

my $datacenter_views =$vim->find_entity_views (view_type => 'Datacenter');
my $datacenter = @$datacenter_views[0];
print "Using datacenter: " . $datacenter->name  ."\n";

my $host_views = $vim->find_entity_views(view_type => 'HostSystem');
my $host_index = 0;
foreach my $host(@$host_views)
{
	print "[$host_index] " . $host->name . "\n";
	$host_index++;
}

if($host_index eq 0)
{
	die "Lab requires least one host";
}
my $host;
if($host_index eq 1)
{
	# Connected directly to ESXi host
	$host = @$host_views[0];
}
if($host_index gt 1)
{
	# Ask user which host to use in lab
	$host = @$host_views[getNumeric(text=>"Please select host: ")];
}

# Select Datastore
print "Host system details:\n";
print "Host contains following datastore(s):\n";
print "Name\t\tType\t\tCapacity\n";
my $ds_mor = $host->datastore;
my $datastores = $vim->get_views(mo_ref_array => $ds_mor);
my $datastore_count=-1;
my $ds_selected_index=-1;
my $ds_selected_size=-1;
my $ds_selected_name=undef;
foreach(@$datastores)
{
	$datastore_count++;
	if($_->summary->freeSpace>$ds_selected_size)
	{
		$ds_selected_index=$datastore_count;
		$ds_selected_size = $_->summary->freeSpace;
		$ds_selected_name = $_->summary->name;
	}
	#print $_->summary->name . "\t\t" . $_->summary->type . "\t\t". $_->summary->freeSpace ."\n";
	
}
if($datastore_count < 0)
{
	die "No datastore(s) found.\n";
}
$datastore_count=-1;
foreach(@$datastores)
{
	$datastore_count++;
	if($datastore_count == $ds_selected_index){
		print "*". $_->summary->name . "\t\t" . $_->summary->type . "\t\t". $_->summary->freeSpace ."\n";}
		else{
		print $_->summary->name . "\t\t" . $_->summary->type . "\t\t". $_->summary->freeSpace ."\n";}
}
my $ds = @$datastores[$ds_selected_index];
if($ds->summary->freeSpace-$vm_disk_size*1024*1024<1*1024*1024*1024)
{ die "Datastore free space size too low.\n";}
print "\n\nUsing datastore '". $ds->summary->name ."' with ". $ds->summary->type ." type\n";# (free space after VM is ". ($ds->summary->freeSpace-$vm_disk_size*1024*1024)/1024/1024 ."Mb\n";

### CONFIRM ###
print "\n\nARE YOU SURE?\n\nThis script will maim and brake your system and it is your job to fix it!\nType 'yes' to continue\n\n";
my $confirm = <>;chomp($confirm);if(lc($confirm) ne "yes") {die "User aborted.";}

printf "Creating VM...";
my @vm_devices;
my $vm_path = "[".$ds->summary->name."]";
my $controller_vm_dev_conf_spec = create_conf_spec(); print "*";
my $disk_vm_dev_conf_spec = create_virtual_disk(fileName=>$vm_path, size=>100000); print "*";
my %net_settings = get_network(network_name => "VM Network", poweron => 0, host_view=>$host, vim=>$vim); print "*";
if($net_settings{'error'} eq 0) {
      push(@vm_devices, $net_settings{'network_conf'}); print "*";
   } elsif ($net_settings{'error'} eq 1) {
      Util::trace(0, "Failed\nError creating VM '$vm_name': "
                    . "Network VM Network not found\n");
      die;
   }

push(@vm_devices, $controller_vm_dev_conf_spec); print "*";
push(@vm_devices, $disk_vm_dev_conf_spec); print "*";
my $files = VirtualMachineFileInfo->new(logDirectory => undef,
                                           snapshotDirectory => undef,
                                           suspendDirectory => undef,
                                           vmPathName => $vm_path); print "*";
 my $vm_config_spec = VirtualMachineConfigSpec->new(
                                             name => $vm_name,
                                             memoryMB => $vm_mem_size,
                                             files => $files,
                                             numCPUs => $vm_cpu_count,
                                             guestId => "rhel6_64Guest",
                                             deviceChange => \@vm_devices); print "*";
my $vm_folder_view = $vim->get_view(mo_ref => $datacenter->vmFolder); print "*";
my $comp_res_view = $vim->get_view(mo_ref => $host->parent); print "*";
eval {
		print "\nDebug: Creating VM....\n";
      $vm_folder_view->CreateVM(config => $vm_config_spec,
                             pool => $comp_res_view->resourcePool);
      Util::trace(0, "Done\nSuccessfully created virtual machine: "
                       ."'$vm_name' under host ". $host->name ."\n");
    };
    if ($@) {
       Util::trace(0, "\nError creating VM '$vm_name': ");
	   print Dumper($@);
       if (ref($@) eq 'SoapFault') {
          if (ref($@->detail) eq 'PlatformConfigFault') {
             Util::trace(0, "Invalid VM configuration: "
                            . ${$@->detail}{'text'} . "\n");
          }
          elsif (ref($@->detail) eq 'InvalidDeviceSpec') {
             Util::trace(0, "Invalid Device configuration: "
                            . ${$@->detail}{'property'} . "\n");
          }
           elsif (ref($@->detail) eq 'DatacenterMismatch') {
             Util::trace(0, "DatacenterMismatch, the input arguments had entities "
                          . "that did not belong to the same datacenter\n");
          }
           elsif (ref($@->detail) eq 'HostNotConnected') {
             Util::trace(0, "Unable to communicate with the remote host,"
                         . " since it is disconnected\n");
          }
          elsif (ref($@->detail) eq 'InvalidState') {
             Util::trace(0, "The operation is not allowed in the current state\n");
          }
          elsif (ref($@->detail) eq 'DuplicateName') {
             Util::trace(0, "Virtual machine already exists.\n");
          }
          else {
             Util::trace(0, "\n" . $@ . "\n");
          }
       }
       else {
          Util::trace(0, "\n" . $@ . "\n");
       }
   }
	
$vim->logout();
print "\nLogged out. Thank you.\n";


sub create_conf_spec
{
	my $controller = VirtualBusLogicController->new(key=>0, device=>[0], busNumber=>0, sharedBus => VirtualSCSISharing->new('noSharing'));
	my $controller_vm_dev_conf_spec = VirtualDeviceConfigSpec->new(device=>$controller, operation=>VirtualDeviceConfigSpecOperation->new('add'));
	return $controller_vm_dev_conf_spec;
}

sub create_virtual_disk
{
	my %args = @_;
	my $path = $args{fileName};
	my $size = $args{size};
	print "\nDebug: " . $path. "\n";
	my $disk_backing_info = VirtualDiskFlatVer2BackingInfo->new(diskMode=>'persistent', fileName=>$path);
	my $disk = VirtualDisk->new(backing=>$disk_backing_info, controllerKey => 0, key => 0, unitNumber => 0, capacityInKB=>$size*1024);
	my $disk_vm_dev_conf_spec = VirtualDeviceConfigSpec->new(device=>$disk, fileOperation=>VirtualDeviceConfigSpecFileOperation->new('create'), operation=>VirtualDeviceConfigSpecOperation->new('add'));
	return $disk_vm_dev_conf_spec;
}

sub get_network {
   my %args = @_;
   my $network_name = $args{network_name};
   my $poweron = $args{poweron};
   my $host_view = $args{host_view};
   my $vim = $args{vim};
   my $network = undef;
   my $unit_num = 1;  # 1 since 0 is used by disk

   if($network_name) {
      my $network_list = $vim->get_views(mo_ref_array => $host_view->network);
      foreach (@$network_list) {
         if($network_name eq $_->name) {
            $network = $_;
            my $nic_backing_info =
               VirtualEthernetCardNetworkBackingInfo->new(deviceName => $network_name,
                                                          network => $network);

            my $vd_connect_info =
               VirtualDeviceConnectInfo->new(allowGuestControl => 1,
                                             connected => 0,
                                             startConnected => $poweron);

            my $nic = VirtualPCNet32->new(backing => $nic_backing_info,
                                          key => 0,
                                          unitNumber => $unit_num,
                                          addressType => 'generated',
                                          connectable => $vd_connect_info);

            my $nic_vm_dev_conf_spec =
               VirtualDeviceConfigSpec->new(device => $nic,
                     operation => VirtualDeviceConfigSpecOperation->new('add'));

            return (error => 0, network_conf => $nic_vm_dev_conf_spec);
         }
      }
	if (!defined($network)) {
      # no network found
       return (error => 1);
      }
   }
    # default network will be used
    return (error => 2);
}


sub getNumeric
{
	my %args = @_;
	my $text = $args{text};
	ReadMode 1;
	print $text;
	my $val = <>;
	chomp($val);
	return $val;
}

sub printVM
{
	my $vm = shift;
	print $vm->name . "\n";
	print "Last boot: ".$vm->summary->runtime->bootTime . "\n";
}
