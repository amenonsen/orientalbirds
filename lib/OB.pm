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
    my $id = qr/[1-9][0-9]*/;
    my $auth = $app->plugin('login');
    my $secure = $r->find('secure');

    $secure->get('/login')->to(template => 'auth/login');

    my $p = $r->bridge->to('auth#detect_users');

    $p->get('/')->to(template => 'index');
    $p->get('/upload')->to('upload#index');
    $p->get('/upload/corrections')->to('upload#corrections');
    $p->post('/upload')->to('upload#upload');

    $r->get('/data/species')->to('data#species');
    $r->get('/data/locations')->to('data#locations');
    $r->get('/data/tags')->to('data#tags');

    my $id = qr/[1-9][0-9]*/;
    $p->get('/contributors')->to('contributors#index');
    $p->get('/contributors/form')->to('contributors#form');
    $p->post('/contributors/save')->to('contributors#save');
    $p->route('/contributors/:contributor_id', contributor_id => $id)
        ->via('get')->to('contributors#profile');

    my $exhibits = $p->route('/exhibits');
    my $exhibit = $exhibits->bridge(
        '/:exhibit_id', exhibit_id => $id
    )->to('exhibits#exhibit');
    $exhibit->get->to('exhibits#show');

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
