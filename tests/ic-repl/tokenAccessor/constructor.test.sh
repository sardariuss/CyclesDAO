#!/usr/local/bin/ic-repl

load "../common/install.sh";

identity default;

// Create the token accessor
let token_accessor = installTokenAccessor(default);

// Test the members are correctly initialized
call token_accessor.getToken();
assert _ == (null : opt record{});
call token_accessor.getAdmin();
assert _ == default;
call token_accessor.getMinters();
assert _ == vec{default;};
call token_accessor.getMintRegister();
assert _ == vec{};