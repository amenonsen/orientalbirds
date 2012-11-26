package OB::Data;

use Mojo::Base 'Gadwall::Controller';

sub species {
    my $self = shift;
    my $term = $self->param('term');

    my @species = (
        { species_id => 1, genus => "Acrocephalus" , species => "orinus" , common_name => "Hume's Reed Warbler" },
        { species_id => 2, genus => "Acrocephalus" , species => "dumetorum" , common_name => "Blyth's Reed Warbler" },
        { species_id => 3, genus => "Acrocephalus" , species => "stentoreus" , common_name => "Clamorous Reed Warbler" },
        { species_id => 4, genus => "Acrocephalus" , species => "scirpaceus" , common_name => "European Reed Warbler" },
        { species_id => 5, genus => "Phylloscopus" , species => "xanthoschistos" , common_name => "Grey-hooded Warbler" },
        { species_id => 6, genus => "Phylloscopus" , species => "chloronotus" , common_name => "Lemon-rumped Warbler" },
        { species_id => 7, genus => "Phylloscopus" , species => "griseolus" , common_name => "Sulphur-bellied Warbler" },
        { species_id => 8, genus => "Phylloscopus" , species => "sindianus" , common_name => "Mountain Chiffchaff" },
        { species_id => 9, genus => "Anthus" , species => "richardi" , common_name => "Richard's Pipit" },
        { species_id => 10, genus => "Anthus" , species => "godlewskii" , common_name => "Blyth's Pipit" },
    );

    my @matches = grep {
        $_->{common_name} =~ /$term/i ||
        $_->{genus}." ".$_->{species} =~ /$term/i
    } @species;

    $self->render(json => {
        matches => [
            map {{
                label => $_->{common_name} ." (". $_->{genus} ." ". $_->{species} .")",
                value => $_->{species_id}
            }} @matches
        ]
    });
}

sub locations {
    my $self = shift;
    my $term = $self->param('term');

    my @locations = (
        { location_id => 1, location_name => "Kaeng Krachan, Petchaburi, Thailand" },
        { location_id => 2, location_name => "Pak Thale, Petchaburi, Thailand" },
        { location_id => 3, location_name => "Laempakbia, Petchaburi, Thailand" },
        { location_id => 4, location_name => "Tal Chhapar, Rajasthan, India" },
        { location_id => 5, location_name => "Sat Tal, Uttarakhand, India" },
        { location_id => 6, location_name => "Sultanpur, Haryana, India" },
        { location_id => 7, location_name => "Okhla Bird Sanctuary, Delhi, India" },
        { location_id => 8, location_name => "Thattekad, Kerala, India" },
        { location_id => 9, location_name => "Fraser's Hill, Malaysia" },
        { location_id => 10, location_name => "Beidaihe, China" },
    );

    my @matches = grep {
        $_->{location_name} =~ /$term/i
    } @locations;

    $self->render(json => {
        matches => [
            map {{
                label => $_->{location_name},
                value => $_->{location_id}
            }} @matches
        ]
    });
}

1;
