package Namespace;
use Moo::Role;
use namespace::clean;

requires 'is_valid';
requires 'next_valid';

1;
