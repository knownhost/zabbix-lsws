#!/usr/bin/perl
#
# Get latest LiteSpeed Web Server stats
#
use strict;
use warnings;
use English '-no_match_vars';
use Getopt::Long qw(:config auto_version auto_help);
use Socket;
use Sys::Hostname;

# Set defaults
my $reportFile  = "/tmp/lshttpd/.rtreport";
my $sender      = "zabbix_sender";
my $server      = "localhost";
my $port        = "10051";
my $host        = hostname();
my $tmpFile     = "/tmp/zabbix_lshttpd_stats.txt";
my $verbose     = 0;

# Get command line options
my $result = GetOptions(
    "reportfile=s"          =>      \$reportFile,
    "tmpfile=s"             =>      \$tmpFile,
    "sender=s"              =>      \$sender,
    "server=s"              =>      \$server,
    "host=s"                =>      \$host,
    "verbose!"              =>      \$verbose
);

if (! -e "$reportFile") {
    print "$reportFile not found";
    exit 1;
}

open(REPORT, $reportFile);
my @report = <REPORT>;
close(REPORT);

my $version     = $1 if ($report[get_line("VERSION:")] =~ /VERSION:\ (.*)\n?/g);
my $uptime      = $1 if ($report[get_line("UPTIME:")] =~ /UPTIME:\ (\d\d:\d\d:\d\d)/g);
my $bps         = $report[get_line("BPS_IN:")];
my $conn        = $report[get_line("MAXCONN:")];
my $req_rate    = $report[get_line("REQ_RATE \\[\\]:")];
#my $php         = $report[get_line("EXTAPP \\[LSAPI\\] \\[\\] \\[lsphp5\\]:")];

my $bps_in      = $1 if ($bps =~ /BPS_IN:\ (\d+)/g);
my $bps_out     = $1 if ($bps =~ /BPS_OUT:\ (\d+)/g);
my $ssl_bps_in  = $1 if ($bps =~ /SSL_BPS_IN:\ (\d+)/g);
my $ssl_bps_out = $1 if ($bps =~ /SSL_BPS_OUT:\ (\d+)/g);
my $total_bps_in = $bps_in + $ssl_bps_in;
my $total_bps_out = $bps_out + $ssl_bps_out;

my $maxconn     = $1 if ($conn =~ /MAXCONN:\ (\d+)/g);
my $maxssl_conn = $1 if ($conn =~ /MAXSSL_CONN:\ (\d+)/g);
my $plainconn   = $1 if ($conn =~ /PLAINCONN:\ (\d+)/g);
my $availconn   = $1 if ($conn =~ /AVAILCONN:\ (\d+)/g);
my $idleconn    = $1 if ($conn =~ /IDLECONN:\ (\d+)/g);
my $sslconn     = $1 if ($conn =~ /SSLCONN:\ (\d+)/g);
my $totalconn   = $plainconn + $sslconn;
my $availssl    = $1 if ($conn =~ /AVAILSSL:\ (\d+)/g);

my $req_processing      = $1 if ($req_rate =~ /REQ_PROCESSING:\ (\d+)/g);
my $req_per_sec         = $1 if ($req_rate =~ /REQ_PER_SEC:\ (\d+)/g);
my $tot_reqs            = $1 if ($req_rate =~ /TOT_REQS:\ (\d+)/g);

my $pub_cache_hits_per_sec = $1 if ($req_rate =~ /PUB_CACHE_HITS_PER_SEC:\ (\d+)/g);
my $total_pub_cache_hits = $1 if ($req_rate =~ /TOTAL_PUB_CACHE_HITS:\ (\d+)/g);
my $total_static_hits   = $1 if ($req_rate =~ /TOTAL_STATIC_HITS:\ (\d+)/g);

#my $php_cmaxconn       = $1 if ($php =~ /CMAXCONN:\ (\d+)/g);
#my $php_emaxconn       = $1 if ($php =~ /EMAXCONN:\ (\d+)/g);
#my $php_pool_size      = $1 if ($php =~ /POOL_SIZE:\ (\d+)/g);
#my $php_inuse_conn     = $1 if ($php =~ /INUSE_CONN:\ (\d+)/g);
#my $php_idle_conn      = $1 if ($php =~ /IDLE_CONN:\ (\d+)/g);
#my $php_waitque_depth  = $1 if ($php =~ /WAITQUE_DEPTH:\ (\d+)/g);
#my $php_req_per_sec    = $1 if ($php =~ /REQ_PER_SEC:\ (\d+)/g);
#my $php_tot_reqs       = $1 if ($php =~ /TOT_REQS:\ (\d+)/g);

unlink($tmpFile);
open(TMPFILE, ">>" . $tmpFile);
print TMPFILE "$host lsws.version $version\n";
print TMPFILE "$host lsws.uptime $uptime\n";
print TMPFILE "$host lsws.bps_in $bps_in\n";
print TMPFILE "$host lsws.bps_out $bps_out\n";
print TMPFILE "$host lsws.ssl_bps_in $ssl_bps_in\n";
print TMPFILE "$host lsws.ssl_bps_out $ssl_bps_out\n";
print TMPFILE "$host lsws.total_bps_in $total_bps_in\n";
print TMPFILE "$host lsws.total_bps_out $total_bps_out\n";
print TMPFILE "$host lsws.maxconn $maxconn\n";
print TMPFILE "$host lsws.maxssl_conn $maxssl_conn\n";
print TMPFILE "$host lsws.plainconn $plainconn\n";
print TMPFILE "$host lsws.availconn $availconn\n";
print TMPFILE "$host lsws.idleconn $idleconn\n";
print TMPFILE "$host lsws.sslconn $sslconn\n";
print TMPFILE "$host lsws.totalconn $totalconn\n";
print TMPFILE "$host lsws.availssl $availssl\n";
print TMPFILE "$host lsws.req_processing $req_processing\n";
print TMPFILE "$host lsws.req_per_sec $req_per_sec\n";
print TMPFILE "$host lsws.tot_reqs $tot_reqs\n";
#print TMPFILE "$host lsws.php_cmaxconn $php_cmaxconn\n";
#print TMPFILE "$host lsws.php_emaxconn $php_emaxconn\n";
#print TMPFILE "$host lsws.php_pool_size $php_pool_size\n";
#print TMPFILE "$host lsws.php_inuse_conn $php_inuse_conn\n";
#print TMPFILE "$host lsws.php_idle_conn $php_idle_conn\n";
#print TMPFILE "$host lsws.php_waitque_depth $php_waitque_depth\n";
#print TMPFILE "$host lsws.php_req_per_sec $php_req_per_sec\n";
#print TMPFILE "$host lsws.php_tot_reqs $php_tot_reqs\n";
print TMPFILE "$host lsws.pub_cache_hits_per_sec $pub_cache_hits_per_sec\n";
print TMPFILE "$host lsws.total_pub_cache_hits $total_pub_cache_hits\n";
print TMPFILE "$host lsws.total_static_hits $total_static_hits\n";
close(TMPFILE);

my $vv = ($verbose) ? " -vv" : "";
system("$sender --zabbix-server '$server' --port '$port' -i '$tmpFile'$vv");

#unlink($tmpFile);

exit 0;

sub get_line
{
    my $needle = $_[0];
    my $i = 0;
    foreach (@report) {
        if ($_ =~ m/$needle/) {
            return $i;
        }
        $i++;
    }
    return 0;
}