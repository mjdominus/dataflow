#!/usr/bin/perl

use Test::More;

subtest add_wire => sub {
    subtest interface_interface => sub {
        pass();
    };

    subtest interface_node => sub {
        pass();
    };

    subtest node_interface => sub {
        pass();
    };

    subtest node_node => sub {
        pass();
    };

    subtest interface_network => sub {
        pass();
    };

    subtest network_interface => sub {
        pass();
    };

    subtest node_network => sub {
        pass();
    };

    subtest node_node => sub {
        pass();
    };

    subtest network_network => sub {
        pass();
    };
};

done_testing();
