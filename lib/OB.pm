package OB;

use Mojo::Base 'Gadwall';

sub config_defaults {
    my $app = shift;

    return (
        $app->SUPER::config_defaults(),
        "db-name" => "orientalbirds"
    );
}

sub startup {
    my $app = shift;

    $app->gadwall_setup();

    my $r = $app->routes;

    $r->get('/')->to(template => 'index');

    $r->any(
        '/' => sub {
            shift->render_text("Hello world!", format => 'txt')
        }
    );
}

1;
