package OB::Auth;

use Mojo::Base 'Gadwall::Auth';

sub detect_users {
    my $self = shift;

    # XXX
    # We should work harder to ensure that session cookies are not sent
    # over plaintext connections.
    return 1 unless $self->req->is_secure;

    my $user = $self->session('user');
    if ($user) {
        my $u = $self->table('Users')->select_by_key($user);
        if ($u) {
            $self->stash(user => $u);
            return 1;
        }
        $self->log->error("Can't load user $user despite valid cookie");
        $self->session(expires => 1);
    }

    return 1;
}

1;
