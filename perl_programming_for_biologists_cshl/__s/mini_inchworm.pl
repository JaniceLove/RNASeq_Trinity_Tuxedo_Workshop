#!/usr/bin/env perl

use strict;
use warnings;

my $usage = "\n\n\tusage: $0 kmer_counts.txt min_contig_length=100\n\n";

my $kmer_counts_file = $ARGV[0] or die $usage;
my $MIN_CONTIG_LENGTH = $ARGV[1] || 100;

my $VERBOSE = 0; # print lots of messages to track run along the way.

my $KMER_SIZE = 25;

my %KMER_COUNTS = &parse_KMER_COUNTS($kmer_counts_file);


my $contig_counter = 0;

my @sorted_kmers_desc = reverse sort {$KMER_COUNTS{$a}<=>$KMER_COUNTS{$b}} keys %KMER_COUNTS;

while (@sorted_kmers_desc) {
    
    my $seed_kmer = shift @sorted_kmers_desc; # remove kmer at index [0], then shift indices to left.


    if ($KMER_COUNTS{$seed_kmer} > 0) {
        my $contig = &build_contig($seed_kmer);

        if (length($contig) >=  $MIN_CONTIG_LENGTH) {
            $contig_counter++;
            print "Contig [$contig_counter]: $contig\n";
        }
        
        &remove_contig_kmers($contig);
        
    }
        
}

exit(0);
    

####
sub build_contig {
    my ($seed_kmer) = @_;

    ##############################################################
    ## Greedily extend contig using the highest scoring extension.
    ##############################################################
    

    # start the contig as the seed kmer itself
    my $contig = $seed_kmer;

    my %seen_kmer;
    
    my $have_extension_flag = 1;
    while ($have_extension_flag) {

        # get the prefix for the next kmer (it's the k-1 last characters of the seed:
        my $next_kmer_prefix = substr($contig, -1 * ($KMER_SIZE-1));
                
        
        my $best_kmer_count = 0;
        my $best_char = "";

        foreach my $nuc_char ('G', 'A', 'T', 'C') {
        
            # contruct the next possible kmer based on the above nucleotide character extension
            my $next_kmer_candidate = $next_kmer_prefix . $nuc_char;

            # get the count for that next kmer candidate
            my $count = $KMER_COUNTS{$next_kmer_candidate};
            print STDERR "$next_kmer_candidate => $count\n" if ($count && $VERBOSE);
            
            # check - is it the best extension so far?
            if (defined($count) && $count > $best_kmer_count) {
                $best_char = $nuc_char;
                $best_kmer_count = $count;
            }
        }
        
        # if we have an extesion, add it to our contig and grow it by one base.
        if ($best_kmer_count > 0) {
            $contig .= $best_char;
            $have_extension_flag = 1;
            my $next_kmer_candidate = $next_kmer_prefix . $best_char;

            if ($seen_kmer{$next_kmer_candidate}) {
                # must be a cycle. stop here.
                $have_extension_flag = 0;
            }
            else {
                $seen_kmer{$next_kmer_candidate} = 1;
            }
        }
        else {
            # no extension possible, should stop. hint - examine while loop condition.
            $have_extension_flag = 0;
        }
    }
        
    return($contig);

}


####
sub remove_contig_kmers {
    my ($contig) = @_;

    print STDERR "-removing kmers from contig: $contig\n" if $VERBOSE;
    
    for (my $i = 0; $i <= length($contig) - $KMER_SIZE; $i++) {

        my $kmer = substr($contig, $i, $KMER_SIZE);
        
        $KMER_COUNTS{$kmer} = 0;
    }

    return;
}
    

####
sub parse_KMER_COUNTS {
    my ($kmers_file) = @_;

    print STDERR "-parsing kmer counts from file: $kmers_file\n" if $VERBOSE;
    
    my $count;
    my %kmer_counts;
    
    open (my $fh, $kmers_file) or die "Error, cannot open file $kmers_file";
    while (<$fh>) {
        chomp;
        my ($count, $kmer) = split(/\t/);
        $kmer_counts{$kmer} = $count;
    }
    close $fh;


    return(%kmer_counts);
    
}
