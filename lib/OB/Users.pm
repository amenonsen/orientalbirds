package OB::Users;

use Mojo::Base 'Gadwall::Users';

sub index {
    my $self = shift;

    my $t = $self->table;
    my $rows = $t->for_display($t->rows);

    $self->render('users/index', users => $rows);
}

sub form {
    my $self = shift;

    my $user = {};
    my $uid = $self->param('user_id');
    if ($uid) {
        $user = $self->table->select_by_key($uid);
        return $self->render_not_found unless $user;
    }

    $self->render('users/form', u => $user);
}

sub save {
}

1;
