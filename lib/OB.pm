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

    my $auth = $app->plugin('login');
    my $secure = $r->find('secure');

    $secure->get('/login')->to(template => 'auth/login');

    $r->get('/upload')->to('upload#index');
    $r->post('/upload')->to('upload#upload');

    my $id = qr/[1-9][0-9]*/;
    $r->get('/contributors')->to('contributors#index');
    $r->get('/contributors/form')->to('contributors#form');
    $r->post('/contributors/save')->to('contributors#save');
    $r->route('/contributors/:contributor_id', contributor_id => $id)
        ->via('get')->to('contributors#profile');

    my $admin = $auth->allow_roles('admin');

    $admin->get('/users')->to('users#index');
    $admin->get('/users/form')->to('users#form');
    $admin->post('/users/save')->to('users#save');
}

sub production_mode {
    shift->log->path("logs/ob.log");
}

sub development_mode {
    shift->log->path("logs/ob.log");
}

1;
