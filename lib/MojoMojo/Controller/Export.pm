package MojoMojo::Controller::Export;

use strict;
use base 'Catalyst::Controller';

use Archive::Zip;
use DateTime;

my $model = '$c->model("DBIC::Page")';

=head1 NAME

MojoMojo::Controller::Export - Export / Import related controller

=head1 SYNOPSIS


=head1 DESCRIPTION

MojoMojo has an extensive export system. You can download all the 
nodes of the wiki either as preformatted HTML, for offline reading
or in a raw format suitable for reimporting into another MojoMojo
installation. either way, MojoMojo will create and send you a zip 
file with a directory containing all the files. the filename of the
directory will contain a timestamp showing when the archive was made.

=head1 ACTIONS

=over 4

=item export_raw 

This action will give you a zip file containing the raw wiki source
for all the nodes of the wiki.

=cut

sub export_raw : Global {
    my ( $self, $c ) = @_;
    my $prefix =
          $c->fixw( $c->pref('name') ) . "-"
        . $c->stash->{page}->path
        . "-export-"
        . DateTime->now->ymd('-') . '-'
        . DateTime->now->hour;
    $prefix =~ s|/|_|g;
    unless ( $c->res->{body} = $c->cache->get($prefix) ) {
        $c->forward('/page/list');
        my $pages   = $c->stash->{pages};
        my $archive = Archive::Zip->new();
        $archive->addDirectory("$prefix/");
        foreach my $page (@$pages) {
            next unless $page->content;
            $archive->addString( $page->content->body,
                $prefix . $page->path . ( $page->path eq '/' ? '' : '/' ) . 'index' );
        }
        my $fh = IO::Scalar->new( \$c->res->{body} );
        $archive->writeToFileHandle($fh);
        $c->cache->set( $prefix, $c->res->body );
    }
    $c->res->headers->header( "Content-Type"        => 'archive/zip' );
    $c->res->headers->header( "Content-Disposition" => "attachment; filename=$prefix.zip" );
}

=item export_html (/.export_html)

This action will give you a zip file containing HTML formatted 
versions of all the nodes of the wiki.

=cut

sub export_html : Global {
    my ( $self, $c ) = @_;
    my $prefix =
          $c->fixw( $c->pref('name') ) . "."
        . $c->stash->{page}->name
        . "-html-"
        . DateTime->now->ymd('-') . '-'
        . DateTime->now->hour;
    $prefix =~ s|/|_|g;
    unless ( $c->res->{body} = $c->cache->get($prefix) ) {
        $c->forward('/page/list');
        my $pages   = $c->stash->{pages};
        my $archive = Archive::Zip->new();
        $archive->addDirectory("$prefix/");
        foreach my $page (@$pages) {
            $c->log->debug( 'Rendering ' . $page->path );
            $archive->addString(
                $c->subreq( '/print', { path => $page->path } ),
                $prefix . $page->path . "/index.html"
            );
        }
        my $fh = IO::Scalar->new( \$c->res->{body} );
        $archive->writeToFileHandle($fh);
        $c->cache->set( $prefix, $c->res->body );
    }
    $c->res->headers->header( "Content-Type"        => 'archive/zip' );
    $c->res->headers->header( "Content-Disposition" => "attachment; filename=$prefix.zip" );
}

=back

=head1 AUTHOR

Marcus Ramberg C<marcus@thefeed.no>

=head1 LICENSE

This library is free software . You can redistribute it and/or modify 
it under the same terms as perl itself.  

=cut

1;
