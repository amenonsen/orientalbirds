# This plugin adds /login and /logout routes, and returns a bridge that
# allows only authenticated users through. It's a convenient wrapper for
# the Gadwall::Auth controller.

package Mojolicious::Plugin::Login;

use Mojo::Base 'Mojolicious::Plugin';

sub register {
    my ($self, $app, $opts) = @_;

    $app->hook(
        after_static_dispatch => sub {
            my ($c) = @_;

            return if $c->res->code;
            return unless $c->req->method eq 'POST';

            my $ctoken = $c->session('token');
            my $ptoken = $c->param('__token');
            return if $ctoken && $ptoken && $ctoken eq $ptoken;

            my @err;
            push @err, "no cookie token" unless $ctoken;
            push @err, "no form token" unless $ptoken;
            unless (@err || $ctoken eq $ptoken) {
                push @err, "tokens don't match";
            }

            $c->app->log->error(
                "CSRF: POST ". $c->req->url->path .
                " from ". $c->tx->remote_address .
                " (". ($c->req->headers->user_agent||"no user-agent") .
                ", ". ($c->req->headers->referrer||"no referrer") ."): ".
                join(", ", @err)
            );
            $c->render(
                status => 403, format => 'txt', text => "Permission denied"
            );
        }
    );

    my $r = $app->routes;
    $r->route('/login')->via('post')->to('auth#login')->name('login');

    if ($opts->{reset_passwords}) {
        my $secure = $r->bridge('/passwords')->to('auth#allow_secure');
        $secure->route('/forgot')->via(qw/get post/)->to(
            'users#forgot_password'
        )->name('forgot_password');
        my $confirm = $secure->bridge->to('confirm#by_url');
        $confirm->route('/reset')->via(qw/get post/)->to(
            'users#reset_password'
        )->name('reset_password');
    }

    my $auth = $r->bridge->to('auth#allow_users')->name('auth');
    $auth->route('/logout')->to('auth#logout')->name('logout');

    $auth->add_shortcut(allow_roles => sub {
        return shift->bridge->to('auth#allow_roles', roles => @_);
    });
    $auth->add_shortcut(allow_if => sub {
        return shift->bridge->to('auth#allow_if', cond => @_);
    });

    return $auth;
}

1;
