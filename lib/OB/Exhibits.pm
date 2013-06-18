package OB::Exhibits;

use Mojo::Base 'Gadwall::Controller';

sub index {}

sub exhibit {
    my $self = shift;

    my $dbh = $self->db;
    my $eid = $self->stash('exhibit_id');

    my $exhibit = $dbh->selectrow_hashref(<<"    SQL", {}, $eid);
        select *
            from exhibits e
                join observations o using (observation_id)
                join contributors c using (contributor_id)
                left join species s on (e.species_id=s.species_id)
            where exhibit_id = \$1
    SQL

    unless ($exhibit) {
        $self->render_not_found;
        return 0;
    }

    my $files = $dbh->selectall_arrayref(<<"    SQL", {Slice => {}}, $eid);
        select *
            from exhibit_files f
                join file_metadata using (file_id)
            where exhibit_id = \$1
            order by slno asc
    SQL

    $exhibit->{files} = $files;
    $self->stash(exhibit => $exhibit);

    return 1;
}

sub show {
    my $self = shift;

    $self->render('exhibits/exhibit');
}

1;
