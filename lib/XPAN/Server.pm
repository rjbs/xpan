package XPAN::Server;
use parent 'Catalyst';
use Catalyst;

__PACKAGE__->config( name => 'foo' );

# Start the application
__PACKAGE__->setup();

1;
