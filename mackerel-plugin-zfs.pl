#!/usr/bin/env perl

use strict;
use warnings;

# graph settings
if(exists $ENV{MACKEREL_AGENT_PLUGIN_META} && $ENV{MACKEREL_AGENT_PLUGIN_META} == 1){
    require JSON;

    print "# mackerel-agent-plugin\n";
    print JSON::encode_json({
        "graphs" => {
            "zfs.capacity" => {
                "label" => "zpool capacity",
                "unit" => "bytes",
                "metrics" => [
                    {"name" => "tank_alloc",
                     "label" => "tank (alloc)"},
                    {"name" => "tank_free",
                     "label" => "tank (free)"},
                ],
            },
            "zfs.iops" => {
                "label" => "zpool operations",
                "unit" => "iops",
                "metrics" => [
                    {"name" => "tank_read",
                     "label" => "tank read"},
                    {"name" => "tank_write",
                     "label" => "tank write"},
                ],
            },
            "zfs.bandwidth" => {
                "label" => "zpool bandwidth",
                "unit" => "bytes/sec",
                "metrics" => [
                    {"name" => "tank_read",
                     "label" => "tank read"},
                    {"name" => "tank_write",
                     "label" => "tank write"},
                ],
            },
        }
    }), "\n";
    exit 0;
}

my $epochtime = `date +%s`;
chomp($epochtime);

# iostat
my $result;

my $time = 5;
$result = `zpool iostat $time 2 | tail -n 1`;

if($result =~ m/^\s*([A-z]+)\s*([0-9\.]+[tgmk]?)\s*([0-9\.]+[tgmk]?)\s*([0-9\.]+[tgmk]?)\s*([0-9\.]+[tgmk]?)\s*([0-9\.]+[tgmk]?)\s*([0-9\.]+[tgmk]?)/i){
    my ($pool, $alloc, $free, $iopsr, $iopsw, $bandr, $bandw) = ($1, $2, $3, $4, $5, $6, $7);

    printf("%s\t%s\t%s\n", "zfs.capacity.${pool}_alloc", convertFormat($alloc), $epochtime);
    printf("%s\t%s\t%s\n", "zfs.capacity.${pool}_free", convertFormat($free), $epochtime);

    printf("%s\t%s\t%s\n", "zfs.iops.${pool}_read", convertFormat($iopsr), $epochtime);
    printf("%s\t%s\t%s\n", "zfs.iops.${pool}_write", convertFormat($iopsw), $epochtime);

    printf("%s\t%s\t%s\n", "zfs.bandwidth.${pool}_read", convertFormat($bandr), $epochtime);
    printf("%s\t%s\t%s\n", "zfs.bandwidth.${pool}_write", convertFormat($bandw), $epochtime);

}

sub convertFormat{
    my ($original) = @_;
    my $ret = "";
    if($original =~ /^([0-9\.]+)([tgmk]?)$/i){
        $ret = $1;
        return $ret if($2 eq "");
        $ret *= 1024;
        return $ret if($2 =~ /k/i);
        $ret *= 1024;
        return $ret if($2 =~ /m/i);
        $ret *= 1024;
        return $ret if($2 =~ /g/i);
        $ret *= 1024;
        return $ret if($2 =~ /t/i);
    }
    return $ret;
}
