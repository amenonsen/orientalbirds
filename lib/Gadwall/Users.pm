package Gadwall::Users;

use Mojo::Base 'Gadwall::Table';

use Gadwall::Util qw(bcrypt mail);

sub columns {
    my $self = shift;
    return (
        login => {},
        email => {
            required => 1,
        },
        password => {
            fields => [qw/pass1 pass2/],
            required => 1,
            validate => sub {
                my (%p) = @_;
                return unless $p{pass1};
                return unless $p{pass1} eq $p{pass2};
                return (password => bcrypt($p{pass1}));
            },
            error => "Please enter the same password twice"
        },
        roles => {
            fields => qr/^is_[a-z]+$/,
            validate => sub {
                my (%set) = @_;

                my $i = 30;
                my @roles = (0)x31;
                my $class = $self->class_name($self->rowclass);
                foreach my $r ($class->role_names()) {
                    if ($set{"is_$r"}) {
                        $roles[$i] = 1;
                    }
                    $i--;
                }

                return (roles => join "", @roles);
            }
        }
    );
}

sub query_columns { qw(* roles::int) }

# Takes the current password and (two copies of) a new password and
# changes the user's password. Expects the router to set user_id in
# the stash. Users should have access to only their own password.
#
# $auth->route('/users/:user_id/password')->to('users#password');

sub password {
    my $self = shift;

    my $u = $self->stash('user');
    my $id = $self->stash($self->primary_key);
    my $passwd = $self->param('password');

    unless (($u->has_role("admin") && $u->{user_id} != $id) ||
            ($passwd && $u->has_password($passwd)))
    {
        return $self->json_error("Incorrect password");
    }

    my %set = $self->_validate(
        { $self->columns }, {
            pass1 => $self->param('pass1'),
            pass2 => $self->param('pass2')
        }
    );

    unless (%set && $self->_update($id, %set)) {
        return $self->json_error;
    }

    $self->log->info(
        "Password changed by $u->{email}".
        $u->{user_id} ne $id ? " (for user $id)" : ""
    );
    return $self->json_ok("Password changed");
}

# This action initiates the password reset process.
#
# In response to a GET, it returns a form to accept an email address and
# POST to itself. If the POSTed address belongs to a user, it sends them
# a "reset password" link by email (which is handled below).
#
# $r->route('/forgot-password')->via(qw/get post/)->to('users#forgot_password')

sub forgot_password {
    my $self = shift;

    my $email;
    if ($self->req->method eq 'POST') {
        $email = $self->param('email');
    }

    unless ($email) {
        $self->render(
            template => "users/password/select-email",
            template_class => __PACKAGE__
        );
        return;
    }

    my $user = $self->select_one({email => $email});

    if ($user) {
        my $url = $self->new_controller('Confirm')->generate_url(
            "/reset-password", $user->{user_id}
        );

        if ($url) {
            my $host = $self->canonical_url->host;
            my $from = $self->stash('config')->{"owner-email"};
            my $to = $user->{email};
            mail(
                from => $from, to => $to,
                subject => "Reset your password at $host",
                text => $self->render_partial(
                    template => "users/password/reset-mail",
                    from => $from, to => $to, host => $host, url => $url,
                    template_class => __PACKAGE__, format => 'txt'
                )
            );

            $self->log->info(
                "Sent password reset link to $user->{email}"
            );
        }
    }

    # We always claim to have sent the reset link, because we don't want
    # to leak any information about valid email addresses. It's true for
    # valid users, and we don't care about anyone else.

    $self->render(
        template => "users/password/sent-reset", format => 'html',
        template_class => __PACKAGE__
    );
}

# This action handles people clicking on their password reset links. It
# first displays a password reset form and then accepts its submission.
# It should be made available by GET and POST through a confirm#by_url
# bridge (which ensures that the link was generated by us). It expects
# the bridge to set user_id in the stash.

sub reset_password {
    my $self = shift;

    my $uid = $self->stash('user_id');
    my %set;

    if ($self->req->method eq 'POST') {
        %set = $self->_validate(
            { $self->columns }, {
                pass1 => $self->param("pass1"),
                pass2 => $self->param("pass2")
            }
        );
    }

    unless (%set && $self->_update($uid, %set)) {
        my %params;
        unless (%set) {
            # Unless there's a database error, keep regenerating the
            # token to allow the user one more access to this URL.
            my $url = $self->new_controller('Confirm')->generate_url(
                "/reset-password", $uid
            );
            $params{t} = $url->query->param('t') if $url;
        }
        $self->render(
            template => "users/password/select-new",
            template_class => __PACKAGE__,
            %params
        );
        return;
    }

    my $user = $self->select_by_key($uid);
    $self->log->info(
        "Password reset by $user->{email}"
    );

    $self->render(
        template => "users/password/reset",
        template_class => __PACKAGE__
    );
}

1;

__DATA__

@@ users/password/select-email.html.ep
% layout 'minimal', title => "Reset forgotten password";
<%= post_form forgot_password => begin %>
<label for=email>Enter your email address:</label><br>
<%= text_field 'email' %><br>
<%= submit_button 'Forgot password' %>
<% end %>

@@ users/password/reset-mail.txt.ep
To reset your password at <%= $host %>, visit:

<%= $url %>

This link is valid for one hour.

--
Administrator
<%= $from %>

@@ users/password/sent-reset.html.ep
% layout 'minimal', title => "Reset forgotten password";
<p class=msg>
A link to reset your password has been sent to your email address.
Please click on it to continue.

@@ users/password/select-new.html.ep
% layout 'minimal', title => "Reset forgotten password";
<%= post_form reset_password => begin %>
Enter new password (twice):<br>
<%= hidden_field t => $t || "" %>
<%= password_field 'pass1' %><br>
<%= password_field 'pass2' %><br>
<%= submit_button 'Reset password' %>
<% end %>

@@ users/password/reset.html.ep
% layout 'minimal', title => "Password reset";
<p class=msg>
Your password has been reset. <a href="/">Return to the main page</a>.
