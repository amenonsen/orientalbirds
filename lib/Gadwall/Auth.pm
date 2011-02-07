# This controller handles user authentication, and provides login/logout
# actions. The login form can be changed by overriding the built-in data
# template "auth/login.html.ep" with a real file.

package Gadwall::Auth;

use strict;
use warnings;

use base 'Gadwall::Controller';

use Gadwall::Util;

# This bridge function returns 1 only if there is an (already validated)
# session cookie that identifies a user. Otherwise it returns 0, thereby
# denying access to anything protected by the bridge. In the former case
# it stores a User object in the stash. In the latter case, it displays
# a login form.
#
# To require authentication to access /foo, you can do this:
#
# $auth = $r->bridge->to('auth#allow_users');
# $auth->route('/foo')->to(...);

sub allow_users {
    my $self = shift;

    my $user = $self->session('user');
    if ($user) {
        my $u = $self->new_controller('Users')->select_by_key($user);
        if ($u) {
            $self->stash(user => $u);
            return 1;
        }
        $self->app->log->error("Can't load user $user despite valid cookie");
        $self->session(expires => 1);
    }

    my $source = $self->req->url;
    if ($source eq $self->url_for('logout')) {
        $source = "/";
    }

    # Here we should check if this request was made via HTTPS, and if
    # not, redirect to HTTPS before exposing the login form. But how?

    $self->session(token => Gadwall::Util->csrf_token());
    $self->render(
        status => 403,
        template => "auth/login",
        login => "", source => $source,
        template_class => __PACKAGE__
    );

    return 0;
}

# This bridge function, which depends on the above function to have run
# first and set stash('user'), allows users to pass if they have one or
# more of the specified roles. If not, it displays a rude message. For
# anything more complicated, use allow_if and a callback.
#
# $auth->bridge->to('auth#allow_roles', roles => [qw/cook dishwasher/]);
# $auth->bridge->to('auth#allow_roles', roles => "admin");

sub allow_roles {
    my $self = shift;

    my $r = $self->stash('roles');
    my @r = ref $r ? @$r : $r;
    if ($self->stash('user')->has_any_role(@r)) {
        return 1;
    }

    return $self->denied;
}

# This is just a helper function to write authentication bridges. It
# expects stash('cond') to be a callback, to which it passes the user
# object. If the callback returns 1, so does this function. Otherwise,
# it displays a rude error message (which is the convenient part).
#
# $auth->bridge->to('auth#allow_if', cond => sub { ... });

sub allow_if {
    my $self = shift;

    if (my $allow = $self->stash('cond')->($self->stash('user'))) {
        return 1;
    }

    return $self->denied;
}

# This function takes a username and password and, if the password is
# valid for the named user, issues a signed cookie that will pass the
# check above. If not, it displays the login form and an error. This
# action itself must be reachable without authentication to avoid an
# infinite loop.
#
# $r->route('/login')->via('post')->to('auth#login')

sub login {
    my $self = shift;

    my ($login, $passwd);
    if ($self->req->method eq 'POST') {
        $login = $self->param("__login");
        $passwd = $self->param("__passwd");
    }
    my $source = $self->param("__source") || '/';

    if ($login && $passwd) {
        my $u = $self->new_controller('Users')->select_one(
            "select * from users where ".
            "coalesce(login,email)=? and is_active", $login
        );
        if ($u && $u->has_password($passwd)) {
            $self->app->log->info("Login: " . $u->{email});
            $self->session(user => $u->{user_id});
            $self->session(token => Gadwall::Util->csrf_token());
            $self->redirect_to($source)->render_text(
                "Redirecting to $source", format => 'txt'
            );
            return;
        }
    }

    $self->render(
        login => $login, source => $source,
        errmsg => $self->message('badlogin'),
        template_class => __PACKAGE__
    );
}

# This function allows a user to act as another user. For obvious
# reasons, it should be exposed through an admin-only route.

sub su {
    my $self = shift;

    my @v;
    my $query = "select * from users where ";
    if ($self->req->method eq 'POST') {
        foreach my $p (qw(user_id login email username)) {
            if (my $v = $self->param($p)) {
                if ($p eq 'username') {
                    $query .= "login=? or email=?";
                    push @v, $v;
                }
                else {
                    $query .= "$p=?";
                }
                push @v, $v;
                last;
            }
        }
    }

    unless (@v) {
        return $self->denied;
    }

    my $u = $self->new_controller('Users')->select_one($query, @v);
    if ($u) {
        $self->app->log->info(
            "su: ". $self->stash('user')->{email} ." to ". $u->{email}
        );
        $self->session(suser => $self->session('user'));
        $self->session(user => $u->{user_id});
    }
    else {
        $self->flash(errmsg => $self->message('badsu'));
    }

    $self->redirect_to('/')->render_text(
        "Redirecting to /", format => 'txt'
    );
}

# This function revokes the cookie issued by login.

sub logout {
    my $self = shift;

    my $u = $self->stash('user');
    $self->app->log->info("Logout: " . $u->{email});

    if ($self->session('suser')) {
        $self->session(user => delete $self->session->{suser});
        $self->redirect_to('/')->render_text(
            "Redirecting to /", format => 'txt'
        );
        return;
    }

    $self->session(expires => 1);
    $self->render(
        template => "auth/login",
        login => "", source => "/",
        errmsg => $self->message('loggedout'),
        template_class => __PACKAGE__
    );
}

sub messages {
    my $self = shift;
    return (
        $self->SUPER::messages(),
        badsu => "Sorry, you can't act as that user",
        badlogin => "Incorrect username or password",
        loggedout => "You have been logged out",
    );
}

1;

__DATA__

@@ auth/login.html.ep
% layout 'default', title => "Login";
<%= form_for login => (method => 'post', class => 'login') => begin %>
  <%= hidden_field '__token' => session 'token' %>
  <%= hidden_field '__source' => stash 'source' %>
  <label for="__login">Login:</label><br>
  <%= text_field '__login', value => stash 'login' %><br>
  <label for="__passwd">Password:</label><br>
  <%= password_field '__passwd' %><br>
  <%= submit_button 'Login', class => 'submit' %>
<% end %>
% if (stash 'errmsg') {
<p id=msg class=error>
<%= stash 'errmsg' %>
</p>
% }
